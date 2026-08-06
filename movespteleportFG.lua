-- ability arena

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ability arena",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "uhhhh",
    ConfigurationSaving = { Enabled = false, FolderName = "ability arena", FileName = "Main" }
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local ESP_Enabled = false
local InfiniteJumpEnabled = false
local TWEEN_SPEED = 150
local LOBBY_Y_THRESHOLD = 90

local AutoFollowEnabled = false
local KeybindEnabled = true
local CustomKeybind = Enum.KeyCode.Q
local KeybindConnection = nil

local CurrentTarget = nil
local CurrentTween = nil
local LastTargetSwitchTime = 0

local function CreateHighlight(char)
    if not char or char:FindFirstChild("ESP_Highlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillColor = Color3.fromRGB(255, 80, 80)
    highlight.Adornee = char
    highlight.Parent = char
end

local function getLobbyFloors()
    local floors = {}
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then
        local children = lobby:GetChildren()
        floors[1] = children[137]
        floors[2] = children[112]
        floors[3] = children[132]
    end
    return floors
end

local function isInLobby(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local rootPart = char.HumanoidRootPart
    local rootPos = rootPart.Position
    
    if rootPos.Y > LOBBY_Y_THRESHOLD then  
        return true
    end
    
    local targetFloors = getLobbyFloors()
    if #targetFloors > 0 then
        local extents = char:GetBoundingBox()
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Include
        overlapParams.FilterDescendantsInstances = targetFloors
        
        local partsOverlapping = workspace:GetPartBoundsInBox(rootPart.CFrame - Vector3.new(0, 3, 0), Vector3.new(4, 2, 4), overlapParams)
        if #partsOverlapping > 0 then
            return true 
        end
    end
    
    return false
end

local function stopTween()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
end

local function getNextTarget()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myRoot = myChar.HumanoidRootPart

    local best = nil
    local bestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            if isInLobby(char) then continue end 
            
            local dist = (hrp.Position - myRoot.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = char
            end
        end
    end
    return best
end

-- Fungsi untuk handle keybind
local function onKeybindPressed(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CustomKeybind then
        AutoFollowEnabled = not AutoFollowEnabled
        if not AutoFollowEnabled then
            CurrentTarget = nil
            stopTween()
        end
    end
end

-- Fungsi untuk update koneksi keybind
local function updateKeybindConnection()
    if KeybindConnection then
        KeybindConnection:Disconnect()
        KeybindConnection = nil
    end
    
    if KeybindEnabled then
        KeybindConnection = UserInputService.InputBegan:Connect(onKeybindPressed)
    end
end

-- Setup awal keybind
updateKeybindConnection()

-- ============ HEARTBEAT CONNECTIONS ============

RunService.Heartbeat:Connect(function()
    -- Auto Follow
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") or not myChar:FindFirstChild("Humanoid") then return end
    local myRoot = myChar.HumanoidRootPart
    local myHum = myChar.Humanoid

    if not AutoFollowEnabled then
        stopTween()
        CurrentTarget = nil
        return
    end

    if CurrentTarget then
        if isInLobby(CurrentTarget) or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
            CurrentTarget = nil
            stopTween()
            myHum:Move(Vector3.new(0,0,0))
        end
    end

    if not CurrentTarget then
        if tick() - LastTargetSwitchTime > 0.1 then
            CurrentTarget = getNextTarget()
            LastTargetSwitchTime = tick()
        end
    end

    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetRoot = CurrentTarget.HumanoidRootPart
        local dist = (targetRoot.Position - myRoot.Position).Magnitude
        
        if dist > 5 then
            local duration = dist / TWEEN_SPEED
            stopTween() 
            
            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
            CurrentTween = TweenService:Create(myRoot, tweenInfo, {
                CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 1.5, 0)) 
            })
            CurrentTween:Play()
        elseif dist > 0 and dist <= 5 then
            stopTween()
            myHum:MoveTo(targetRoot.Position)
        else
            stopTween()
            myHum:MoveTo(myRoot.Position)
        end
    else
        stopTween()
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============ UI TABS ============

local PlayerTab = Window:CreateTab("Player", 4483362458)

local ESP_Toggle = PlayerTab:CreateToggle({
    Name = "Player ESP (Highlight)",
    CurrentValue = false,
    Callback = function(Value)
        ESP_Enabled = Value
        
        -- Hapus semua highlight yang ada
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hl = char:FindFirstChild("ESP_Highlight")
                    if hl then 
                        hl:Destroy() 
                    end
                end
            end
        end

        -- Jika diaktifkan, buat highlight untuk player yang sudah ada
        if Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    CreateHighlight(plr.Character)
                end
            end
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end
})

local AutoFollow_Toggle = PlayerTab:CreateToggle({
    Name = "Auto Follow (good for afk autofarming)",
    CurrentValue = false,
    Callback = function(Value)
        AutoFollowEnabled = Value
        if not Value then
            CurrentTarget = nil
            stopTween()
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Enable Keybind (Q)",
    CurrentValue = true,
    Callback = function(Value)
        KeybindEnabled = Value
        updateKeybindConnection()
    end
})

PlayerTab:CreateKeybind({
    Name = "Auto Follow Keybind",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Callback = function(Keybind)
        if Keybind then
            CustomKeybind = Keybind
            -- Update koneksi agar keybind baru langsung aktif
            updateKeybindConnection()
        end
    end
})

-- ============ PLAYER CONNECTIONS ============

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if ESP_Enabled then
            CreateHighlight(char)
        end
    end)
end)

-- Jangan buat highlight di awal, hanya setup listener
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if ESP_Enabled then
                CreateHighlight(char)
            end
        end)
        -- HAPUS: jangan buat highlight di awal
    end
end

-- ============ NOTIFICATION ============

Rayfield:Notify({
    Title = "ability arena",
    Content = "Successfully Loaded",
    Duration = 6
})
