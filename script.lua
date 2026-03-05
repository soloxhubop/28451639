local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- right side path
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-483.57, -5.10, 18.74),
    Vector3.new(-475.00, -6.99, 26.43),
    Vector3.new(-474.67, -6.94, 105.48),
}
-- left side path
local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-484.62, -5.10, 100.37),
    Vector3.new(-475.08, -7.00, 93.29),
    Vector3.new(-474.22, -6.96, 16.18),
}


local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false
local AUTO_START_DELAY = 0.7

local function isCountdownNumber(text)
    local num = tonumber(text)
    if num and num >= 1 and num <= 5 then
        return true, num
    end
    return false
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if patrolMode == "right" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    elseif patrolMode == "left" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    end
    return 0
end

local function getCurrentWaypoints()
    if patrolMode == "right" then
        return rightWaypoints
    elseif patrolMode == "left" then
        return leftWaypoints
    end
    return {}
end

local function startMovement(mode)
    patrolMode = mode
    currentWaypoint = 1
    if mode == "right" then
        rightBtn.Text = "STOP Right"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("AutoRight movement started")
    else
        leftBtn.Text = "STOP Left"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("AutoLeft movement started")
    end
end

local function updateWalking()
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local currentVel = root.AssemblyLinearVelocity

    if floating then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}

        local raycastResult = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), raycastParams)

        if raycastResult then
            local groundY = raycastResult.Position.Y
            local targetY = groundY + 8
            local currentY = root.Position.Y
            local yDifference = targetY - currentY

            if math.abs(yDifference) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    yDifference * 15,
                    currentVel.Z
                )
            else
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    0,
                    currentVel.Z
                )
            end
        end
    end

    if patrolMode ~= "none" then
        local waypoints = getCurrentWaypoints()
        local targetPos = waypoints[currentWaypoint]
        local currentPos = root.Position

        local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
        local currentXZ = Vector3.new(currentPos.X, 0, currentPos.Z)
        local distanceXZ = (targetXZ - currentXZ).Magnitude

        if distanceXZ > 3 then
            local moveDirection = (targetXZ - currentXZ).Unit
            local currentSpeed = getCurrentSpeed()

            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * currentSpeed,
                root.AssemblyLinearVelocity.Y,
                moveDirection.Z * currentSpeed
            )
        else
            if currentWaypoint == #waypoints then
                local completedMode = patrolMode
                patrolMode = "none"
                currentWaypoint = 1
                waitingForCountdownLeft = false
                waitingForCountdownRight = false

                rightBtn.Text = "AutoRight"
                leftBtn.Text = "AutoLeft"
                TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()

                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

                print("Path completed - auto stopped")
            else
                currentWaypoint = currentWaypoint + 1
                local speed = getCurrentSpeed()
                local modeText = (patrolMode == "right") and "AutoRight" or "AutoLeft"
                local speedText = (speed == 60) and "60" or "30"
                print("heading to " .. modeText .. " spot " .. currentWaypoint .. " @ " .. speedText)
            end
        end
    end
end

-- ========== MODERN GUI WITH RAINBOW OUTLINE ==========
local sg = Instance.new("ScreenGui")
sg.Name = "MeloskaAutoDuel"
sg.Parent = player:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true

-- Shadow (modern depth effect)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 230, 0, 170)  -- slightly larger than MainFrame
Shadow.Position = UDim2.new(0.5, -115, 0.5, -85)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"  -- blurred circle gradient
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.7
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Parent = sg

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BackgroundTransparency = 0.1   -- slight transparency for modern look
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = sg

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)   -- more rounded
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2.5
UIStroke.Transparency = 0
UIStroke.Parent = MainFrame

-- Rainbow stroke updater
local hue = 0
local rainbowConnection
rainbowConnection = RunService.Heartbeat:Connect(function()
    hue = (hue + 0.005) % 1
    UIStroke.Color = Color3.fromHSV(hue, 1, 1)
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "AutoDuel"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamSemibold
Title.Parent = MainFrame

local CreditText = Instance.new("TextLabel")
CreditText.Size = UDim2.new(1, 0, 0, 15)
CreditText.Position = UDim2.new(0, 0, 0, 28)
CreditText.BackgroundTransparency = 1
CreditText.Text = ""
CreditText.TextColor3 = Color3.fromRGB(170, 170, 170)
CreditText.TextSize = 11
CreditText.Font = Enum.Font.Gotham
CreditText.Parent = MainFrame

-- Button hover effects
local function addHoverEffects(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
    end)
end

-- Right button
rightBtn = Instance.new("TextButton")
rightBtn.Size = UDim2.new(0.85, 0, 0, 32)
rightBtn.Position = UDim2.new(0.075, 0, 0, 48)
rightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
rightBtn.Text = "AutoRight"
rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rightBtn.TextSize = 12
rightBtn.Font = Enum.Font.GothamBold
rightBtn.BorderSizePixel = 0
rightBtn.AutoButtonColor = false
rightBtn.Parent = MainFrame

local rightBtnCorner = Instance.new("UICorner")
rightBtnCorner.CornerRadius = UDim.new(0, 8)
rightBtnCorner.Parent = rightBtn

addHoverEffects(rightBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))

-- Left button
leftBtn = Instance.new("TextButton")
leftBtn.Size = UDim2.new(0.85, 0, 0, 32)
leftBtn.Position = UDim2.new(0.075, 0, 0, 85)
leftBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
leftBtn.Text = "AutoLeft"
leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leftBtn.TextSize = 12
leftBtn.Font = Enum.Font.GothamBold
leftBtn.BorderSizePixel = 0
leftBtn.AutoButtonColor = false
leftBtn.Parent = MainFrame

local leftBtnCorner = Instance.new("UICorner")
leftBtnCorner.CornerRadius = UDim.new(0, 8)
leftBtnCorner.Parent = leftBtn

addHoverEffects(leftBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))

-- Float button
floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0.85, 0, 0, 32)
floatBtn.Position = UDim2.new(0.075, 0, 0, 122)
floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
floatBtn.Text = "Float OFF"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.TextSize = 12
floatBtn.Font = Enum.Font.GothamBold
floatBtn.BorderSizePixel = 0
floatBtn.AutoButtonColor = false
floatBtn.Parent = MainFrame

local floatBtnCorner = Instance.new("UICorner")
floatBtnCorner.CornerRadius = UDim.new(0, 8)
floatBtnCorner.Parent = floatBtn

addHoverEffects(floatBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))

-- ========== ORIGINAL FUNCTIONALITY (unchanged) ==========
rightBtn.MouseButton1Click:Connect(function()
    if patrolMode == "right" or waitingForCountdownRight then
        patrolMode = "none"
        currentWaypoint = 1
        waitingForCountdownRight = false
        rightBtn.Text = "AutoRight"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        leftBtn.Text = "AutoLeft"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()

        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
        print("AutoRight stopped")
    else
        local success, label = pcall(function()
            return player.PlayerGui
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
                :FindFirstChild("Timer")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
                :FindFirstChild("Label")
        end)

        if success and label and isTimerInCountdown(label) then
            waitingForCountdownRight = true
            rightBtn.Text = "Waiting..."
            TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 200, 50)}):Play()
            leftBtn.Text = "AutoLeft"
            TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            print("AutoRight waiting for countdown")
        else
            startMovement("right")
        end
    end
end)

leftBtn.MouseButton1Click:Connect(function()
    if patrolMode == "left" or waitingForCountdownLeft then
        patrolMode = "none"
        currentWaypoint = 1
        waitingForCountdownLeft = false
        leftBtn.Text = "AutoLeft"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        rightBtn.Text = "AutoRight"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()

        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
        print("AutoLeft stopped")
    else
        local success, label = pcall(function()
            return player.PlayerGui
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
                :FindFirstChild("Timer")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
                :FindFirstChild("Label")
        end)

        if success and label and isTimerInCountdown(label) then
            waitingForCountdownLeft = true
            leftBtn.Text = "Waiting..."
            TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 200, 50)}):Play()
            rightBtn.Text = "AutoRight"
            TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            print("AutoLeft waiting for countdown")
        else
            startMovement("left")
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    floating = not floating

    if floating then
        floatBtn.Text = "Float ON"
        floatBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        print("Float ON")
    else
        floatBtn.Text = "Float OFF"
        floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
        end
        print("Float OFF")
    end
end)

heartbeatConn = RunService.Heartbeat:Connect(updateWalking)

player.CharacterAdded:Connect(function()
    task.wait(1)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    floating = false

    rightBtn.Text = "AutoRight"
    leftBtn.Text = "AutoLeft"
    floatBtn.Text = "Float OFF"
    TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

sg.Destroying:Connect(function()
    if heartbeatConn then
        heartbeatConn:Disconnect()
    end
    if rainbowConnection then
        rainbowConnection:Disconnect()
    end
end)

local function onTextChanged(label)
    local text = label.Text
    local ok, number = isCountdownNumber(text)

    if ok then
        print("Countdown detected:", number)

        if number == 1 then
            if waitingForCountdownLeft then
                print("Countdown finished! Starting auto left in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownLeft = false
                startMovement("left")
            end

            if waitingForCountdownRight then
                print("Countdown finished! Starting auto right in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownRight = false
                startMovement("right")
            end
        end
    end
end

spawn(function()
    local success, label = pcall(function()
        return player.PlayerGui
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
            :FindFirstChild("Timer")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
            :FindFirstChild("Label")
    end)

    if success and label then
        print("Timer label found! Countdown detection enabled.")
        onTextChanged(label)
        label:GetPropertyChangedSignal("Text"):Connect(function()
            onTextChanged(label)
        end)
    else
        print("Timer label not found. Auto movements will start immediately.")
    end
end)
--REPORT THIS INTO .gg/coolhub IF THIS WAS LEAKED TO YOU


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function getInternalTable()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return nil end
    
    local SynchronizerModule = Packages:FindFirstChild("Synchronizer")
    if not SynchronizerModule then return nil end
    
    local success, synchronizer = pcall(require, SynchronizerModule)
    if not success or not synchronizer then return nil end
    
    local GetMethod = synchronizer.Get
    if type(GetMethod) ~= "function" then
        return nil
    end
    
    for i = 1, 5 do
        local success, upvalue = pcall(getupvalue, GetMethod, i)
        if success and type(upvalue) == "table" then
            if upvalue.___private or upvalue.___channels or upvalue.___data then
                return upvalue
            end
            
            for k, v in pairs(upvalue) do
                if type(k) == "string" and k:match("^Plot_") or type(v) == "table" then
                    return upvalue
                end
            end
        end
    end
    
    local success, env = pcall(getfenv, GetMethod)
    if success and env and env.self then
        return env.self
    end
    
    return nil
end

local SynchronizerInternal = {
    _cache = {},
    _dataTable = nil
}

task.spawn(function()
    local attempts = 0
    while attempts < 10 and not SynchronizerInternal._dataTable do
        SynchronizerInternal._dataTable = getInternalTable()
        if not SynchronizerInternal._dataTable then
            task.wait(1)
            attempts = attempts + 1
        end
    end
end)

local function stealthGet(plotName)
    if not plotName or type(plotName) ~= "string" then
        return nil
    end
    
    if SynchronizerInternal._cache[plotName] == false then
        return nil
    end
    
    if SynchronizerInternal._dataTable then
        local keys = {
            plotName,
            "Plot_" .. plotName,
            "Plot" .. plotName,
            plotName .. "_Channel",
            "Channel_" .. plotName
        }
        
        for _, key in ipairs(keys) do
            if SynchronizerInternal._dataTable[key] then
                SynchronizerInternal._cache[plotName] = SynchronizerInternal._dataTable[key]
                return SynchronizerInternal._dataTable[key]
            end
        end
        
        for k, v in pairs(SynchronizerInternal._dataTable) do
            if type(k) == "string" and (k == plotName or k:find(plotName, 1, true)) then
                if type(v) == "table" then
                    SynchronizerInternal._cache[plotName] = v
                    return v
                end
            end
        end
    end
    
    SynchronizerInternal._cache[plotName] = false
    return nil
end

local function stealthGetProperty(channel, property)
    if not channel or type(channel) ~= "table" then
        return nil
    end
    
    if channel[property] then
        return channel[property]
    end
    
    if type(channel.Get) == "function" then
        local success, result = pcall(channel.Get, channel, property)
        if success then
            return result
        end
    end
    
    local altNames = {
        Owner = {"owner", "Owner", "plotOwner", "PlotOwner"},
        AnimalList = {"animalList", "AnimalList", "animals", "Animals", "pets"}
    }
    
    if altNames[property] then
        for _, alt in ipairs(altNames[property]) do
            if channel[alt] then
                return channel[alt]
            end
        end
    end
    
    return nil
end

local autoStealEnabled = true
local selectedTargetIndex = 1
local currentStealProgress = 0
local isCurrentlyStealing = false

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Datas = ReplicatedStorage:WaitForChild("Datas")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = ReplicatedStorage:WaitForChild("Utils")

local AnimalsData, AnimalsShared, NumberUtils
task.spawn(function()
    for i = 1, 10 do
        local success1, data = pcall(require, Datas:WaitForChild("Animals"))
        local success2, shared = pcall(require, Shared:WaitForChild("Animals"))
        local success3, utils = pcall(require, Utils:WaitForChild("NumberUtils"))
        
        if success1 and data then
            AnimalsData = data
        end
        if success2 and shared then
            AnimalsShared = shared
        end
        if success3 and utils then
            NumberUtils = utils
        end
        
        if AnimalsData and AnimalsShared and NumberUtils then
            break
        end
        task.wait(0.5)
    end
end)

local allAnimalsCache = {}
local InternalStealCache = {}
local PromptMemoryCache = {}

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then
        return false
    end
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return false
    end
    
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then
        return false
    end
    
    local channel = stealthGet(plot.Name)
    if channel then
        local owner = stealthGetProperty(channel, "Owner")
        if owner then
            if typeof(owner) == "Instance" and owner:IsA("Player") then
                return owner.UserId == LocalPlayer.UserId
            elseif typeof(owner) == "table" and owner.UserId then
                return owner.UserId == LocalPlayer.UserId
            elseif typeof(owner) == "Instance" then
                return owner == LocalPlayer
            end
        end
    end
    
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then
            return yourBase.Enabled == true
        end
    end
    
    return false
end

local function get_top_3_pets()
    local topPets = {}
    
    for _, animalData in ipairs(allAnimalsCache) do
        if not isMyBaseAnimal(animalData) then
            table.insert(topPets, {
                petName = animalData.name or "Unknown",
                mpsText = animalData.genText or "$0/s",
                mpsValue = animalData.genValue or 0,
                owner = animalData.owner or "Unknown",
                plot = animalData.plot or "Unknown",
                slot = animalData.slot or "1",
                uid = animalData.uid or "",
                mutation = animalData.mutation or "None",
                animalData = animalData
            })
        end
        
        if #topPets >= 3 then
            break
        end
    end
    
    return topPets
end

local function findProximityPromptForAnimal(animalData)
    if not animalData then return nil end
    
    local cachedPrompt = PromptMemoryCache[animalData.uid]
    if cachedPrompt and cachedPrompt.Parent then
        return cachedPrompt
    end
    
    local plot = workspace.Plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    
    local base = podium:FindFirstChild("Base")
    if not base then return nil end
    
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return nil end
    
    local attach = spawn:FindFirstChild("PromptAttachment")
    if not attach then return nil end
    
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            PromptMemoryCache[animalData.uid] = p
            return p
        end
    end
    
    return nil
end

local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    
    local data = {
        holdCallbacks = {},
        triggerCallbacks = {},
        ready = true,
    }
    
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function" then
                table.insert(data.holdCallbacks, conn.Function)
            end
        end
    end
    
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function" then
                table.insert(data.triggerCallbacks, conn.Function)
            end
        end
    end
    
    if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then
        InternalStealCache[prompt] = data
    end
end

local function runCallbackList(list)
    for _, fn in ipairs(list) do
        task.spawn(fn)
    end
end

local function executeInternalStealAsync(prompt)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    
    data.ready = false
    
    -- ÃÂÃÂ°Ã‘â€¡ÃÂ¸ÃÂ½ÃÂ°ÃÂµÃÂ¼ ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘Â ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸
    isCurrentlyStealing = true
    local startTime = tick()
    local stealDuration = 1.42 -- Ãâ€ÃÂ»ÃÂ¸Ã‘â€šÃÂµÃÂ»Ã‘Å’ÃÂ½ÃÂ¾Ã‘ÂÃ‘â€šÃ‘Å’ ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸
    
    task.spawn(function()
        if #data.holdCallbacks > 0 then
            runCallbackList(data.holdCallbacks)
        end
        
        -- ÃÂÃÂ½ÃÂ¸ÃÂ¼ÃÂ°Ã‘â€ ÃÂ¸Ã‘Â ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ° ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸
        while tick() - startTime < stealDuration do
            local progress = (tick() - startTime) / stealDuration
            currentStealProgress = math.clamp(progress * 100, 0, 100)
            task.wait(0.05)
        end
        
        if #data.triggerCallbacks > 0 then
            runCallbackList(data.triggerCallbacks)
        end
        
        task.wait()
        data.ready = true
        
        -- Ãâ€”ÃÂ°ÃÂ²ÃÂµÃ‘â‚¬Ã‘Ë†ÃÂ°ÃÂµÃÂ¼ ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘Â
        isCurrentlyStealing = false
        currentStealProgress = 0
    end)
    
    return true
end

local function attemptSteal(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    
    buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then
        return false
    end
    
    return executeInternalStealAsync(prompt)
end

local function prebuildStealCallbacks()
    for uid, prompt in pairs(PromptMemoryCache) do
        if prompt and prompt.Parent then
            buildStealCallbacks(prompt)
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if autoStealEnabled then
            prebuildStealCallbacks()
        end
    end
end)

local plotChannels = {}
local lastAnimalData = {}
local scannerConnections = {}

local function getAnimalHash(animalList)
    if not animalList then return "" end
    local hash = ""
    for slot, data in pairs(animalList) do
        if type(data) == "table" then
            hash = hash .. tostring(slot) .. tostring(data.Index) .. tostring(data.Mutation)
        end
    end
    return hash
end

local function scanSinglePlot(plot)
    pcall(function()        
        local plotUID = plot.Name
        local channel = stealthGet(plotUID)
        if not channel then return end
        
        local animalList = stealthGetProperty(channel, "AnimalList")
        local currentHash = getAnimalHash(animalList)
        if lastAnimalData[plotUID] == currentHash then
            return
        end
        lastAnimalData[plotUID] = currentHash
        
        for i = #allAnimalsCache, 1, -1 do
            if allAnimalsCache[i].plot == plot.Name then
                table.remove(allAnimalsCache, i)
            end
        end
        
        local owner = stealthGetProperty(channel, "Owner")
        if not owner or not Players:FindFirstChild(owner.Name) then
            for i = #allAnimalsCache, 1, -1 do
                if allAnimalsCache[i].plot == plot.Name then
                    table.remove(allAnimalsCache, i)
                end
            end
            return
        end
        
        local ownerName = owner and owner.Name or "Unknown"
        if not animalList then return end
        
        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table" then
                local animalName = animalData.Index
                local animalInfo = AnimalsData[animalName]
                if not animalInfo then continue end
                
                local mutation = animalData.Mutation or "None"
                local traits = (animalData.Traits and #animalData.Traits > 0) and table.concat(animalData.Traits, ", ") or "None"
                
                local genValue = AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
                local genText = "$" .. NumberUtils:ToString(genValue) .. "/s"
                
                table.insert(allAnimalsCache, {
                    name = animalInfo.DisplayName or animalName,
                    genText = genText,
                    genValue = genValue,
                    mutation = mutation,
                    traits = traits,
                    owner = ownerName,
                    plot = plot.Name,
                    slot = tostring(slot),
                    uid = plot.Name .. "_" .. tostring(slot),
                })
            end
        end
        
        table.sort(allAnimalsCache, function(a, b)
            return a.genValue > b.genValue
        end)
    end)
end

local function setupPlotListener(plot)
    if plotChannels[plot.Name] then return end
    
    local channel
    local retries = 0
    local maxRetries = 3
    
    while not channel and retries < maxRetries do
        channel = stealthGet(plot.Name)
        if channel then
            break
        else
            retries = retries + 1
            if retries < maxRetries then
                task.wait(0.3)
            end
        end
    end
    
    if not channel then return end
    plotChannels[plot.Name] = true
    
    scanSinglePlot(plot)
    
    local c1 = plot.DescendantAdded:Connect(function()
        task.wait(0.05)
        scanSinglePlot(plot)
    end)
    table.insert(scannerConnections, c1)
    
    local c2 = plot.DescendantRemoving:Connect(function()
        task.wait(0.05)
        scanSinglePlot(plot)
    end)
    table.insert(scannerConnections, c2)
    
    local c3 = task.spawn(function()
        while plot.Parent and plotChannels[plot.Name] do
            task.wait(3)
            scanSinglePlot(plot)
        end
    end)
    table.insert(scannerConnections, c3)
end

local function initializePlotScanner()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        for i = 1, 30 do
            plots = workspace:FindFirstChild("Plots")
            if plots then break end
            task.wait(0.5)
        end
        if not plots then
            return
        end
    end
    
    for _, plot in ipairs(plots:GetChildren()) do
        task.spawn(setupPlotListener, plot)
    end
    
    local newPlotConnection = plots.ChildAdded:Connect(function(plot)
        task.wait(0.2)
        task.spawn(setupPlotListener, plot)
    end)
    table.insert(scannerConnections, newPlotConnection)
    
    local removedPlotConnection = plots.ChildRemoved:Connect(function(plot)
        plotChannels[plot.Name] = nil
        lastAnimalData[plot.Name] = nil
        
        for i = #allAnimalsCache, 1, -1 do
            if allAnimalsCache[i].plot == plot.Name then
                table.remove(allAnimalsCache, i)
            end
        end
    end)
    table.insert(scannerConnections, removedPlotConnection)
end

-- GUI Ã‘ÂÃÂ»ÃÂµÃÂ¼ÃÂµÃÂ½Ã‘â€šÃ‘â€¹
local screenGui, frame, statusLabel, targetLabel, petButtons, toggleButton, stealStatusLabel, progressBar, progressFill, progressText

-- ÃÅ“ÃÂ¾ÃÂ±ÃÂ¸ÃÂ»Ã‘Å’ÃÂ½Ã‘â€¹ÃÂ¹ GUI (Ã‘Æ’ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ½Ã‘â€¹ÃÂ¹)
local function createMobileGUI()
    -- ÃÅ¸Ã‘â‚¬ÃÂ¾ÃÂ²ÃÂµÃ‘â‚¬Ã‘ÂÃÂµÃÂ¼, Ã‘ÂÃ‘Æ’Ã‘â€°ÃÂµÃ‘ÂÃ‘â€šÃÂ²Ã‘Æ’ÃÂµÃ‘â€š ÃÂ»ÃÂ¸ PlayerGui
    if not PlayerGui then
        warn("PlayerGui ÃÂ½ÃÂµ ÃÂ½ÃÂ°ÃÂ¹ÃÂ´ÃÂµÃÂ½! ÃÅ¾ÃÂ¶ÃÂ¸ÃÂ´ÃÂ°ÃÂ½ÃÂ¸ÃÂµ...")
        for i = 1, 30 do
            PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if PlayerGui then break end
            task.wait(0.5)
        end
        if not PlayerGui then
            warn("PlayerGui Ã‘â€šÃÂ°ÃÂº ÃÂ¸ ÃÂ½ÃÂµ ÃÂ±Ã‘â€¹ÃÂ» ÃÂ½ÃÂ°ÃÂ¹ÃÂ´ÃÂµÃÂ½!")
            return false
        end
    end
    
    -- ÃÂ£ÃÂ´ÃÂ°ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘ÂÃ‘â€šÃÂ°Ã‘â‚¬Ã‘â€¹ÃÂ¹ GUI ÃÂµÃ‘ÂÃÂ»ÃÂ¸ Ã‘ÂÃ‘Æ’Ã‘â€°ÃÂµÃ‘ÂÃ‘â€šÃÂ²Ã‘Æ’ÃÂµÃ‘â€š
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    
    -- ÃÂ¡ÃÂ¾ÃÂ·ÃÂ´ÃÂ°ÃÂµÃÂ¼ ScreenGui Ã‘Â ÃÂ¿Ã‘â‚¬ÃÂ°ÃÂ²ÃÂ¸ÃÂ»Ã‘Å’ÃÂ½Ã‘â€¹ÃÂ¼ÃÂ¸ ÃÂ½ÃÂ°Ã‘ÂÃ‘â€šÃ‘â‚¬ÃÂ¾ÃÂ¹ÃÂºÃÂ°ÃÂ¼ÃÂ¸ ÃÂ´ÃÂ»Ã‘Â ÃÂ¼ÃÂ¾ÃÂ±ÃÂ¸ÃÂ»Ã‘Å’ÃÂ½Ã‘â€¹Ã‘â€¦ Ã‘Æ’Ã‘ÂÃ‘â€šÃ‘â‚¬ÃÂ¾ÃÂ¹Ã‘ÂÃ‘â€šÃÂ²
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoStealUI_Mobile"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    screenGui.IgnoreGuiInset = true
    
    -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ½Ã‘â€¹ÃÂµ Ã‘â‚¬ÃÂ°ÃÂ·ÃÂ¼ÃÂµÃ‘â‚¬Ã‘â€¹ ÃÂ´ÃÂ»Ã‘Â ÃÂ¼ÃÂ¾ÃÂ±ÃÂ¸ÃÂ»Ã‘Å’ÃÂ½Ã‘â€¹Ã‘â€¦ Ã‘Æ’Ã‘ÂÃ‘â€šÃ‘â‚¬ÃÂ¾ÃÂ¹Ã‘ÂÃ‘â€šÃÂ²
    local isMobile = UserInputService.TouchEnabled
    local frameWidth = isMobile and 250 or 230 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    local frameHeight = isMobile and 210 or 190 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    frame.Position = UDim2.new(0.5, -frameWidth/2, 0.05, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 100
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ Ã‘Æ’ÃÂ³ÃÂ¾ÃÂ»
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 0, 255)
    stroke.Thickness = 1.5 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ° Ã‘â€šÃÂ¾ÃÂ»Ã‘â€°ÃÂ¸ÃÂ½ÃÂ°
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- ÃÅ¸ÃÂµÃ‘â‚¬ÃÂµÃ‘â€šÃÂ°Ã‘ÂÃÂºÃÂ¸ÃÂ²ÃÂ°ÃÂ½ÃÂ¸ÃÂµ Ã‘â€šÃÂ¾ÃÂ»Ã‘Å’ÃÂºÃÂ¾ ÃÂ½ÃÂ° ÃÅ¸ÃÅ¡
    if not isMobile then
        local dragging = false
        local dragInput, mousePos, framePos

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                frame.Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            end
        end)
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 20) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    titleLabel.Position = UDim2.new(0, 5, 0, 3) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾ ÃÂ²ÃÂ²ÃÂµÃ‘â‚¬Ã‘â€¦
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Titanz Auto Steal"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = isMobile and 12 or 14 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 101
    titleLabel.Parent = frame

    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    titleGradient.Parent = titleLabel

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 60, 0, 18) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    statusLabel.Position = UDim2.new(1, -65, 0, 4) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ON"
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = isMobile and 10 or 12 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.ZIndex = 101
    statusLabel.Parent = frame

    targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -10, 0, 18) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    targetLabel.Position = UDim2.new(0, 5, 0, 28) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Current: Searching..."
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = isMobile and 9 or 11 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    targetLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
    targetLabel.ZIndex = 101
    targetLabel.Parent = frame

    -- ÃÂ¡Ã‘â€šÃÂ°Ã‘â€šÃ‘Æ’Ã‘Â ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸
    stealStatusLabel = Instance.new("TextLabel")
    stealStatusLabel.Size = UDim2.new(1, -10, 0, 16) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    stealStatusLabel.Position = UDim2.new(0, 5, 0, 50) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
    stealStatusLabel.BackgroundTransparency = 1
    stealStatusLabel.Text = "Steal: Ready"
    stealStatusLabel.Font = Enum.Font.GothamBold
    stealStatusLabel.TextSize = isMobile and 8 or 10 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    stealStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    stealStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    stealStatusLabel.ZIndex = 101
    stealStatusLabel.Parent = frame

    -- ÃÅ¸ÃÂ¾ÃÂ»ÃÂ¾Ã‘ÂÃÂºÃÂ° ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ° ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸ (Ã‘Æ’ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ½ÃÂ°Ã‘Â)
    progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, -20, 0, 10) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ° ÃÂ²Ã‘â€¹Ã‘ÂÃÂ¾Ã‘â€šÃÂ°
    progressBar.Position = UDim2.new(0, 10, 0, 70) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 101
    progressBar.Parent = frame
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 5) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ Ã‘Æ’ÃÂ³ÃÂ¾ÃÂ»
    progressBarCorner.Parent = progressBar
    
    progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 102
    progressFill.Parent = progressBar
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 5)
    progressFillCorner.Parent = progressFill
    
    progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0%"
    progressText.Font = Enum.Font.GothamBold
    progressText.TextSize = isMobile and 7 or 9 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.ZIndex = 103
    progressText.Parent = progressBar

    local top3Label = Instance.new("TextLabel")
    top3Label.Size = UDim2.new(1, -10, 0, 16) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    top3Label.Position = UDim2.new(0, 5, 0, 85) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
    top3Label.BackgroundTransparency = 1
    top3Label.Text = "Select:"
    top3Label.Font = Enum.Font.GothamBold
    top3Label.TextSize = isMobile and 8 or 10 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    top3Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    top3Label.TextXAlignment = Enum.TextXAlignment.Left
    top3Label.ZIndex = 101
    top3Label.Parent = frame
    
    petButtons = {}
    
    local buttonHeight = isMobile and 24 or 22 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    local buttonSpacing = isMobile and 28 or 26 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    local startY = 105 -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾

    for i = 1, 3 do
        local petButton = Instance.new("TextButton")
        petButton.Size = UDim2.new(0, frameWidth - 20, 0, buttonHeight)
        petButton.Position = UDim2.new(0, 10, 0, startY + (i - 1) * buttonSpacing)
        petButton.BackgroundColor3 = Color3.fromRGB(15, 0, 15)
        petButton.BackgroundTransparency = 0.15
        petButton.BorderSizePixel = 0
        petButton.Text = string.format("#%d: ...", i) -- ÃÂ£ÃÂºÃÂ¾Ã‘â‚¬ÃÂ¾Ã‘â€¡ÃÂµÃÂ½ÃÂ¾
        petButton.Font = Enum.Font.Gotham
        petButton.TextSize = isMobile and 8 or 10 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
        petButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        petButton.AutoButtonColor = false
        petButton.TextXAlignment = Enum.TextXAlignment.Left
        petButton.ZIndex = 101
        petButton.Parent = frame
        
        local petCorner = Instance.new("UICorner")
        petCorner.CornerRadius = UDim.new(0, 4) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ Ã‘Æ’ÃÂ³ÃÂ¾ÃÂ»
        petCorner.Parent = petButton
        
        local petStroke = Instance.new("UIStroke")
        petStroke.Color = Color3.fromRGB(100, 100, 100)
        petStroke.Thickness = 1 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ° Ã‘â€šÃÂ¾ÃÂ»Ã‘â€°ÃÂ¸ÃÂ½ÃÂ°
        petStroke.Transparency = 0.7
        petStroke.Parent = petButton
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 3) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ ÃÂ¾Ã‘â€šÃ‘ÂÃ‘â€šÃ‘Æ’ÃÂ¿
        padding.Parent = petButton
        
        petButtons[i] = {
            button = petButton,
            stroke = petStroke,
            index = i
        }
        
        -- ÃÂ¢ÃÂ¾ÃÂ»Ã‘Å’ÃÂºÃÂ¾ ÃÂ´ÃÂ»Ã‘Â ÃÅ¸ÃÅ¡ ÃÂ´ÃÂ¾ÃÂ±ÃÂ°ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘ÂÃ‘â€žÃ‘â€žÃÂµÃÂºÃ‘â€šÃ‘â€¹ ÃÂ¿Ã‘â‚¬ÃÂ¸ ÃÂ½ÃÂ°ÃÂ²ÃÂµÃÂ´ÃÂµÃÂ½ÃÂ¸ÃÂ¸
        if not isMobile then
            petButton.MouseEnter:Connect(function()
                if selectedTargetIndex ~= i then
                    petButton.BackgroundTransparency = 0.05
                    petStroke.Transparency = 0.5
                end
            end)
            
            petButton.MouseLeave:Connect(function()
                if selectedTargetIndex ~= i then
                    petButton.BackgroundTransparency = 0.15
                    petStroke.Transparency = 0.7
                end
            end)
        end
        
        petButton.MouseButton1Click:Connect(function()
            selectedTargetIndex = i
            
            -- ÃÅ¾ÃÂ±ÃÂ½ÃÂ¾ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘ÂÃ‘â€šÃÂ¸ÃÂ»ÃÂ¸ ÃÂºÃÂ½ÃÂ¾ÃÂ¿ÃÂ¾ÃÂº
            for j, btn in ipairs(petButtons) do
                if j == selectedTargetIndex then
                    btn.button.TextColor3 = Color3.fromRGB(100, 255, 100)
                    btn.stroke.Color = Color3.fromRGB(100, 255, 100)
                    btn.stroke.Transparency = 0.3
                else
                    btn.button.TextColor3 = Color3.fromRGB(200, 200, 200)
                    btn.stroke.Color = Color3.fromRGB(100, 100, 100)
                    btn.stroke.Transparency = 0.7
                end
            end
            
            local topPets = get_top_3_pets()
            if topPets[selectedTargetIndex] then
                local currentPet = topPets[selectedTargetIndex]
                targetLabel.Text = string.format("Current: %s", currentPet.petName) -- ÃÂ£ÃÂºÃÂ¾Ã‘â‚¬ÃÂ¾Ã‘â€¡ÃÂµÃÂ½ÃÂ¾
            else
                targetLabel.Text = "Current: None"
            end
        end)
    end

    toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, frameWidth - 20, 0, 28) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    toggleButton.Position = UDim2.new(0, 10, 0, startY + 3 * buttonSpacing)
    toggleButton.BackgroundColor3 = Color3.fromRGB(15, 0, 15)
    toggleButton.BackgroundTransparency = 0.15
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "Disable"
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = isMobile and 10 or 12 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
    toggleButton.TextColor3 = Color3.fromRGB(230, 175, 255)
    toggleButton.AutoButtonColor = false
    toggleButton.ZIndex = 101
    toggleButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ Ã‘Æ’ÃÂ³ÃÂ¾ÃÂ»
    buttonCorner.Parent = toggleButton

    local buttonGradient = Instance.new("UIGradient")
    buttonGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 255))
    }
    buttonGradient.Parent = toggleButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(180, 0, 255)
    buttonStroke.Thickness = 1 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ° Ã‘â€šÃÂ¾ÃÂ»Ã‘â€°ÃÂ¸ÃÂ½ÃÂ°
    buttonStroke.Transparency = 0.5
    buttonStroke.Parent = toggleButton
    
    -- ÃËœÃÂ½ÃÂ¸Ã‘â€ ÃÂ¸ÃÂ°ÃÂ»ÃÂ¸ÃÂ·ÃÂ°Ã‘â€ ÃÂ¸Ã‘Â Ã‘ÂÃ‘â€šÃÂ¸ÃÂ»ÃÂµÃÂ¹ ÃÂºÃÂ½ÃÂ¾ÃÂ¿ÃÂ¾ÃÂº
    for i, btn in ipairs(petButtons) do
        if i == selectedTargetIndex then
            btn.button.TextColor3 = Color3.fromRGB(100, 255, 100)
            btn.stroke.Color = Color3.fromRGB(100, 255, 100)
            btn.stroke.Transparency = 0.3
        else
            btn.button.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.stroke.Color = Color3.fromRGB(100, 100, 100)
            btn.stroke.Transparency = 0.7
        end
    end
    
    -- Ãâ€ÃÂ¾ÃÂ±ÃÂ°ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘â‚¬ÃÂ¾ÃÂ´ÃÂ¸Ã‘â€šÃÂµÃÂ»Ã‘Â ÃÂ² ÃÂºÃÂ¾ÃÂ½Ã‘â€ ÃÂµ
    screenGui.Parent = PlayerGui
    
    -- Ãâ€ÃÂ»Ã‘Â ÃÂ¼ÃÂ¾ÃÂ±ÃÂ¸ÃÂ»Ã‘Å’ÃÂ½Ã‘â€¹Ã‘â€¦ Ã‘Æ’Ã‘ÂÃ‘â€šÃ‘â‚¬ÃÂ¾ÃÂ¹Ã‘ÂÃ‘â€šÃÂ² ÃÂ´ÃÂ¾ÃÂ±ÃÂ°ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ ÃÂºÃÂ½ÃÂ¾ÃÂ¿ÃÂºÃ‘Æ’ Ã‘ÂÃÂºÃ‘â‚¬Ã‘â€¹Ã‘â€šÃÂ¸Ã‘Â/ÃÂ¿ÃÂ¾ÃÂºÃÂ°ÃÂ·ÃÂ°
    if isMobile then
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 25, 0, 25) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
        closeButton.Position = UDim2.new(1, -30, 0, 2) -- ÃÂ¡ÃÂ¼ÃÂµÃ‘â€°ÃÂµÃÂ½ÃÂ¾
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        closeButton.BackgroundTransparency = 0.3
        closeButton.BorderSizePixel = 0
        closeButton.Text = "X"
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 12 -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ÃÂ¾
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.ZIndex = 101
        closeButton.Parent = frame
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 4) -- ÃÂ£ÃÂ¼ÃÂµÃÂ½Ã‘Å’Ã‘Ë†ÃÂµÃÂ½ Ã‘Æ’ÃÂ³ÃÂ¾ÃÂ»
        closeCorner.Parent = closeButton
        
        closeButton.MouseButton1Click:Connect(function()
            frame.Visible = not frame.Visible
            closeButton.Text = frame.Visible and "X" or "O"
        end)
    end
    
    return true
end

local function updateUI(enabled, topPets)
    -- Ãâ€”ÃÂ°Ã‘â€°ÃÂ¸Ã‘â€šÃÂ° ÃÂ¾Ã‘â€š nil ÃÂ·ÃÂ½ÃÂ°Ã‘â€¡ÃÂµÃÂ½ÃÂ¸ÃÂ¹
    if not statusLabel or not targetLabel or not toggleButton then
        return
    end
    
    autoStealEnabled = enabled
    
    if enabled then
        statusLabel.Text = "ON"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        if frame and frame:FindFirstChild("UIStroke") then
            frame.UIStroke.Color = Color3.fromRGB(100, 255, 100)
            frame.UIStroke.Transparency = 0.3
        end
        
        toggleButton.Text = "Disable"
        
        if topPets and type(topPets) == "table" and petButtons then
            for i = 1, 3 do
                if petButtons[i] and petButtons[i].button then
                    if topPets[i] then
                        local pet = topPets[i]
                        -- ÃÂ£ÃÂºÃÂ¾Ã‘â‚¬ÃÂ¾Ã‘â€¡ÃÂµÃÂ½ÃÂ½Ã‘â€¹ÃÂ¹ Ã‘â€žÃÂ¾Ã‘â‚¬ÃÂ¼ÃÂ°Ã‘â€š
                        petButtons[i].button.Text = string.format("#%d: %s", i, pet.petName or "?")
                    else
                        petButtons[i].button.Text = string.format("#%d: No", i)
                    end
                end
            end
            
            if topPets[selectedTargetIndex] then
                local currentPet = topPets[selectedTargetIndex]
                targetLabel.Text = string.format("Current: %s", currentPet.petName or "?")
            else
                targetLabel.Text = "Current: None"
            end
        else
            targetLabel.Text = "Current: Searching..."
            if petButtons then
                for i = 1, 3 do
                    if petButtons[i] and petButtons[i].button then
                        petButtons[i].button.Text = string.format("#%d: ...", i)
                    end
                end
            end
        end
        
        if petButtons then
            for i, btn in ipairs(petButtons) do
                if i == selectedTargetIndex and btn.button and btn.stroke then
                    btn.button.TextColor3 = Color3.fromRGB(100, 255, 100)
                    btn.stroke.Color = Color3.fromRGB(100, 255, 100)
                    btn.stroke.Transparency = 0.3
                elseif btn.button and btn.stroke then
                    btn.button.TextColor3 = Color3.fromRGB(200, 200, 200)
                    btn.stroke.Color = Color3.fromRGB(100, 100, 100)
                    btn.stroke.Transparency = 0.7
                end
            end
        end
    else
        statusLabel.Text = "OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        if frame and frame:FindFirstChild("UIStroke") then
            frame.UIStroke.Color = Color3.fromRGB(180, 0, 255)
            frame.UIStroke.Transparency = 0.5
        end
        
        toggleButton.Text = "Enable"
        targetLabel.Text = "Current: Off"
        
        if petButtons then
            for i = 1, 3 do
                if petButtons[i] and petButtons[i].button then
                    petButtons[i].button.Text = string.format("#%d: Off", i)
                    petButtons[i].button.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
        end
    end
end

local function updateStealStatus()
    if not stealStatusLabel or not progressFill or not progressText then
        return
    end
    
    if isCurrentlyStealing then
        stealStatusLabel.Text = "Steal: In Progress"
        stealStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        -- ÃÅ¾ÃÂ±ÃÂ½ÃÂ¾ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ ÃÂ¿ÃÂ¾ÃÂ»ÃÂ¾Ã‘ÂÃÂºÃ‘Æ’ ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ°
        local fillWidth = math.clamp(currentStealProgress, 0, 100)
        progressFill.Size = UDim2.new(fillWidth / 100, 0, 1, 0)
        progressText.Text = string.format("%.0f%%", fillWidth)
        
        -- ÃÅ“ÃÂµÃÂ½Ã‘ÂÃÂµÃÂ¼ Ã‘â€ ÃÂ²ÃÂµÃ‘â€š ÃÂ² ÃÂ·ÃÂ°ÃÂ²ÃÂ¸Ã‘ÂÃÂ¸ÃÂ¼ÃÂ¾Ã‘ÂÃ‘â€šÃÂ¸ ÃÂ¾Ã‘â€š ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ°
        if fillWidth < 30 then
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- ÃÅ¡Ã‘â‚¬ÃÂ°Ã‘ÂÃÂ½Ã‘â€¹ÃÂ¹
        elseif fillWidth < 70 then
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Ãâ€“ÃÂµÃÂ»Ã‘â€šÃ‘â€¹ÃÂ¹
        else
            progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Ãâ€”ÃÂµÃÂ»ÃÂµÃÂ½Ã‘â€¹ÃÂ¹
        end
    else
        stealStatusLabel.Text = "Steal: Ready"
        stealStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- ÃÂ¡ÃÂ±Ã‘â‚¬ÃÂ°Ã‘ÂÃ‘â€¹ÃÂ²ÃÂ°ÃÂµÃÂ¼ ÃÂ¿ÃÂ¾ÃÂ»ÃÂ¾Ã‘ÂÃÂºÃ‘Æ’ ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ°
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressText.Text = "0%"
        progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    end
end

local stealConnection = nil

local function autoStealLoop()
    if stealConnection then
        stealConnection:Disconnect()
    end
    
    stealConnection = RunService.Heartbeat:Connect(function()
        if not autoStealEnabled then
            return
        end
        
        local topPets = get_top_3_pets()
        
        local targetAnimal = nil
        if topPets[selectedTargetIndex] then
            targetAnimal = topPets[selectedTargetIndex].animalData
        end
        
        if not targetAnimal or isMyBaseAnimal(targetAnimal) then
            return
        end
        
        local prompt = PromptMemoryCache[targetAnimal.uid]
        if not prompt or not prompt.Parent then
            prompt = findProximityPromptForAnimal(targetAnimal)
        end
        
        if prompt then
            attemptSteal(prompt)
        end
        
        -- ÃÅ¾ÃÂ±ÃÂ½ÃÂ¾ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘ÂÃ‘â€šÃÂ°Ã‘â€šÃ‘Æ’Ã‘Â ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸ ÃÂºÃÂ°ÃÂ¶ÃÂ´Ã‘â€¹ÃÂ¹ ÃÂºÃÂ°ÃÂ´Ã‘â‚¬
        updateStealStatus()
    end)
end

-- ÃÅ¾Ã‘ÂÃÂ½ÃÂ¾ÃÂ²ÃÂ½ÃÂ¾ÃÂ¹ ÃÂ¿ÃÂ¾Ã‘â€šÃÂ¾ÃÂº ÃÂ¸ÃÂ½ÃÂ¸Ã‘â€ ÃÂ¸ÃÂ°ÃÂ»ÃÂ¸ÃÂ·ÃÂ°Ã‘â€ ÃÂ¸ÃÂ¸
task.spawn(function()
    -- Ãâ€“ÃÂ´ÃÂµÃÂ¼ ÃÂ·ÃÂ°ÃÂ³Ã‘â‚¬Ã‘Æ’ÃÂ·ÃÂºÃÂ¸ ÃÂ½ÃÂµÃÂ¾ÃÂ±Ã‘â€¦ÃÂ¾ÃÂ´ÃÂ¸ÃÂ¼Ã‘â€¹Ã‘â€¦ ÃÂ¼ÃÂ¾ÃÂ´Ã‘Æ’ÃÂ»ÃÂµÃÂ¹
    print("ÃÅ¾ÃÂ¶ÃÂ¸ÃÂ´ÃÂ°ÃÂ½ÃÂ¸ÃÂµ ÃÂ·ÃÂ°ÃÂ³Ã‘â‚¬Ã‘Æ’ÃÂ·ÃÂºÃÂ¸ ÃÂ¼ÃÂ¾ÃÂ´Ã‘Æ’ÃÂ»ÃÂµÃÂ¹...")
    while not AnimalsData or not AnimalsShared or not NumberUtils do
        task.wait(0.5)
    end
    
    print("ÃÅ“ÃÂ¾ÃÂ´Ã‘Æ’ÃÂ»ÃÂ¸ ÃÂ·ÃÂ°ÃÂ³Ã‘â‚¬Ã‘Æ’ÃÂ¶ÃÂµÃÂ½Ã‘â€¹, Ã‘ÂÃÂ¾ÃÂ·ÃÂ´ÃÂ°ÃÂµÃÂ¼ GUI...")
    
    -- Ãâ€“ÃÂ´ÃÂµÃÂ¼ ÃÂ½ÃÂµÃÂ¼ÃÂ½ÃÂ¾ÃÂ³ÃÂ¾ ÃÂ¿ÃÂµÃ‘â‚¬ÃÂµÃÂ´ Ã‘ÂÃÂ¾ÃÂ·ÃÂ´ÃÂ°ÃÂ½ÃÂ¸ÃÂµÃÂ¼ GUI
    task.wait(2)
    
    -- ÃÂ¡ÃÂ¾ÃÂ·ÃÂ´ÃÂ°ÃÂµÃÂ¼ GUI
    local guiCreated = createMobileGUI()
    if not guiCreated then
        warn("ÃÂÃÂµ Ã‘Æ’ÃÂ´ÃÂ°ÃÂ»ÃÂ¾Ã‘ÂÃ‘Å’ Ã‘ÂÃÂ¾ÃÂ·ÃÂ´ÃÂ°Ã‘â€šÃ‘Å’ GUI!")
        return
    end
    
    print("GUI Ã‘ÂÃÂ¾ÃÂ·ÃÂ´ÃÂ°ÃÂ½ Ã‘Æ’Ã‘ÂÃÂ¿ÃÂµÃ‘Ë†ÃÂ½ÃÂ¾!")
    
    -- ÃÂÃÂ°Ã‘ÂÃ‘â€šÃ‘â‚¬ÃÂ¾ÃÂ¹ÃÂºÃÂ° ÃÂºÃÂ½ÃÂ¾ÃÂ¿ÃÂºÃÂ¸ toggle
    if toggleButton then
        local isMobile = UserInputService.TouchEnabled
        
        if not isMobile then
            toggleButton.MouseEnter:Connect(function()
                toggleButton.BackgroundTransparency = 0.05
                if toggleButton:FindFirstChild("UIStroke") then
                    toggleButton.UIStroke.Transparency = 0.3
                end
            end)

            toggleButton.MouseLeave:Connect(function()
                toggleButton.BackgroundTransparency = 0.15
                if toggleButton:FindFirstChild("UIStroke") then
                    toggleButton.UIStroke.Transparency = 0.5
                end
            end)
        end

        toggleButton.MouseButton1Click:Connect(function()
            autoStealEnabled = not autoStealEnabled
            
            if autoStealEnabled then
                local topPets = get_top_3_pets()
                updateUI(true, topPets)
                autoStealLoop()
            else
                updateUI(false)
                -- ÃÂ¡ÃÂ±Ã‘â‚¬ÃÂ°Ã‘ÂÃ‘â€¹ÃÂ²ÃÂ°ÃÂµÃÂ¼ Ã‘ÂÃ‘â€šÃÂ°Ã‘â€šÃ‘Æ’Ã‘Â ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸ ÃÂ¿Ã‘â‚¬ÃÂ¸ ÃÂ²Ã‘â€¹ÃÂºÃÂ»Ã‘Å½Ã‘â€¡ÃÂµÃÂ½ÃÂ¸ÃÂ¸
                isCurrentlyStealing = false
                currentStealProgress = 0
                updateStealStatus()
            end
        end)
    end
    
    -- ÃËœÃÂ½ÃÂ¸Ã‘â€ ÃÂ¸ÃÂ°ÃÂ»ÃÂ¸ÃÂ·ÃÂ°Ã‘â€ ÃÂ¸Ã‘Â Ã‘ÂÃÂºÃÂ°ÃÂ½ÃÂµÃ‘â‚¬ÃÂ°
    print("ÃËœÃÂ½ÃÂ¸Ã‘â€ ÃÂ¸ÃÂ°ÃÂ»ÃÂ¸ÃÂ·ÃÂ°Ã‘â€ ÃÂ¸Ã‘Â Ã‘ÂÃÂºÃÂ°ÃÂ½ÃÂµÃ‘â‚¬ÃÂ°...")
    initializePlotScanner()
    
    -- Ãâ€”ÃÂ°ÃÂ¿Ã‘Æ’Ã‘ÂÃÂº ÃÂ°ÃÂ²Ã‘â€šÃÂ¾-ÃÂºÃ‘â‚¬ÃÂ°ÃÂ¶ÃÂ¸
    task.wait(1)
    autoStealLoop()
    
    -- ÃÅ¸ÃÂµÃ‘â‚¬ÃÂ²ÃÂ¾ÃÂ½ÃÂ°Ã‘â€¡ÃÂ°ÃÂ»Ã‘Å’ÃÂ½ÃÂ¾ÃÂµ ÃÂ¾ÃÂ±ÃÂ½ÃÂ¾ÃÂ²ÃÂ»ÃÂµÃÂ½ÃÂ¸ÃÂµ UI
    local topPets = get_top_3_pets()
    updateUI(true, topPets)
    
    print("Auto Steal ÃÂ³ÃÂ¾Ã‘â€šÃÂ¾ÃÂ² ÃÂº Ã‘â‚¬ÃÂ°ÃÂ±ÃÂ¾Ã‘â€šÃÂµ!")
    
    -- ÃÅ¾ÃÂ±ÃÂ½ÃÂ¾ÃÂ²ÃÂ»ÃÂµÃÂ½ÃÂ¸ÃÂµ UI ÃÂºÃÂ°ÃÂ¶ÃÂ´Ã‘â€¹ÃÂµ 0.1 Ã‘ÂÃÂµÃÂºÃ‘Æ’ÃÂ½ÃÂ´Ã‘â€¹ ÃÂ´ÃÂ»Ã‘Â ÃÂ¿ÃÂ»ÃÂ°ÃÂ²ÃÂ½ÃÂ¾ÃÂ¹ ÃÂ°ÃÂ½ÃÂ¸ÃÂ¼ÃÂ°Ã‘â€ ÃÂ¸ÃÂ¸ ÃÂ¿Ã‘â‚¬ÃÂ¾ÃÂ³Ã‘â‚¬ÃÂµÃ‘ÂÃ‘ÂÃÂ°
    while task.wait(0.1) do
        if autoStealEnabled then
            local topPets = get_top_3_pets()
            updateUI(true, topPets)
            updateStealStatus()
        end
    end
end)

print("Auto steal loaded by titanz (Mini Mobile UI by Skyme)")
