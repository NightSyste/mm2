print("Build by Maxi - MM2 Ultimate GOD Edition")

-- ==========================================
-- SERVICES
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- MAIN SCRIPT START
-- ==========================================
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/NightSyste/orion.lua/refs/heads/main/night.lua'))()

-- GLOBAL VARIABLES
local GunESPEnabled = false

local esp_enabled, lines_enabled, names_enabled = false, false, false
local esp_highlights, esp_tracers, esp_names = {}, {}, {}
local murder_color, sheriff_color, innocent_color = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 255, 0)

local autofarm_enabled, autofarm_speed, noclip_connection = false, 35, nil
local flyEnabled, flySpeed, bodyVelocity, bodyGyro = false, 150, nil, nil
local targetName, SelectedPlayer, Flinging, AntiFlingEnabled = "", nil, false, false

local isInvisible, ghostChar, syncConnection, rainbowConnection = false, nil, nil, nil
local ghostSettings = {speed = 16, transparency = 0.5, rainbow = false, rainbowSpeed = 1}

-- HELPER FUNCTIONS
local function GetMurderer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and (plr.Character:FindFirstChild("Knife") or (plr:FindFirstChild("Backpack") and plr.Backpack:FindFirstChild("Knife"))) then
            return plr
        end
    end
    return nil
end

local function GetGunDrop()
    return Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Gun")
end

-- ==========================================
-- ORION WINDOW SETUP
-- ==========================================
local Window = OrionLib:MakeWindow({Name = "MM2 Ultimate GOD Edition by Maxi", SaveConfig = true, ConfigFolder = "MM2Ultimate", IntroText = "Welcome Maxi"})

local MurdTab = Window:MakeTab({Name = "Murderer", Icon = "rbxassetid://4483345998"})
local ESPTab = Window:MakeTab({Name = "ESP Visuals", Icon = "rbxassetid://4483345998"})
local FarmTab = Window:MakeTab({Name = "Autofarm", Icon = "rbxassetid://4483345998"})
local PlayerTab = Window:MakeTab({Name = "Player", Icon = "rbxassetid://4483345998"})
local TeleportTab = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483362458"})
local CombatTab = Window:MakeTab({Name = "Combat & Fling", Icon = "rbxassetid://4483362458"})

-- ==========================================
-- MURDERER TAB
-- ==========================================
MurdTab:AddButton({
    Name = "Kill All (Teleport Kill)",
    Callback = function()
        local tool = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
        if not tool then return end
        LocalPlayer.Character.Humanoid:EquipTool(tool)
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                task.wait(0.2)
                firetouchinterest(plr.Character.HumanoidRootPart, tool.Handle, 0)
                firetouchinterest(plr.Character.HumanoidRootPart, tool.Handle, 1)
            end
        end
    end
})

-- ==========================================
-- ESP SYSTEM
-- ==========================================
local function get_role(plr)
    if not plr or not plr.Character then return "Innocent" end
    local char, backpack = plr.Character, plr:FindFirstChild("Backpack")
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer"
    elseif char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function create_tracer() local l = Drawing.new("Line") l.Thickness = 1 l.Transparency = 1 return l end
local function create_name_tag() local t = Drawing.new("Text") t.Size = 18 t.Center = true t.Outline = true t.Visible = false return t end

local function clean_player_esp(name)
    if esp_highlights[name] then esp_highlights[name]:Destroy() esp_highlights[name] = nil end
    if esp_tracers[name] then esp_tracers[name].Visible = false esp_tracers[name]:Remove() esp_tracers[name] = nil end
    if esp_names[name] then esp_names[name].Visible = false esp_names[name]:Remove() esp_names[name] = nil end
end

RunService.RenderStepped:Connect(function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local role = get_role(plr)
            local color = (role == "Murderer" and murder_color) or (role == "Sheriff" and sheriff_color) or innocent_color

            -- Highlights
            if esp_enabled then
                if not esp_highlights[plr.Name] then
                    local hl = Instance.new("Highlight") hl.Name = plr.Name hl.Parent = CoreGui esp_highlights[plr.Name] = hl
                end
                esp_highlights[plr.Name].Adornee = plr.Character
                esp_highlights[plr.Name].FillColor = color
                esp_highlights[plr.Name].Enabled = true
            else
                if esp_highlights[plr.Name] then esp_highlights[plr.Name].Enabled = false end
            end

            -- Tracers
            if lines_enabled then
                if not esp_tracers[plr.Name] then esp_tracers[plr.Name] = create_tracer() end
                local tracer, camera = esp_tracers[plr.Name], Workspace.CurrentCamera
                local hrpPos, onScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScreen then
                    tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    tracer.Color = color tracer.Visible = true
                else tracer.Visible = false end
            else if esp_tracers[plr.Name] then esp_tracers[plr.Name].Visible = false end end

            -- Names
            if names_enabled then
                if not esp_names[plr.Name] then esp_names[plr.Name] = create_name_tag() end
                local tag, camera = esp_names[plr.Name], Workspace.CurrentCamera
                local hrpPos, onScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
                if onScreen then
                    tag.Position = Vector2.new(hrpPos.X, hrpPos.Y)
                    tag.Text = plr.Name .. " [" .. role .. "]"
                    tag.Color = color tag.Visible = true
                else tag.Visible = false end
            else if esp_names[plr.Name] then esp_names[plr.Name].Visible = false end end
        else
            clean_player_esp(plr.Name)
        end
    end
end)
Players.PlayerRemoving:Connect(function(plr) clean_player_esp(plr.Name) end)

local gunHighlight = Instance.new("Highlight")
gunHighlight.FillColor = Color3.fromRGB(255, 255, 0)
gunHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)

RunService.RenderStepped:Connect(function()
    local drop = GetGunDrop()
    if GunESPEnabled and drop then
        gunHighlight.Parent = drop
        gunHighlight.Enabled = true
    else
        gunHighlight.Enabled = false
    end
end)

ESPTab:AddToggle({Name = "Enable Player Highlights", Default = false, Callback = function(v) esp_enabled = v end})
ESPTab:AddToggle({Name = "Enable Lines (Tracers)", Default = false, Callback = function(v) lines_enabled = v end})
ESPTab:AddToggle({Name = "Enable Names", Default = false, Callback = function(v) names_enabled = v end})
ESPTab:AddToggle({Name = "Gun ESP (Dropped Gun)", Default = false, Callback = function(v) GunESPEnabled = v end})

-- ==========================================
-- SMART AUTOFARM SYSTEM
-- ==========================================
local function GetActiveMap()
    for _, v in pairs(Workspace:GetChildren()) do if v:FindFirstChild("CoinContainer") then return v end end
    return nil
end

local function is_backpack_full()
    local roundStats = LocalPlayer:FindFirstChild("RoundStats")
    return roundStats and roundStats:FindFirstChild("Coins") and roundStats.Coins.Value >= 40
end

local function is_alive()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char:FindFirstChild("HumanoidRootPart")
end

local function TweenToTarget(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local tween = TweenService:Create(hrp, TweenInfo.new(distance / autofarm_speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    return true
end

task.spawn(function()
    while task.wait(0.1) do
        if autofarm_enabled then
            if is_alive() then
                local currentMap = GetActiveMap()
                if currentMap and not is_backpack_full() then
                    if not noclip_connection then
                        noclip_connection = RunService.Stepped:Connect(function()
                            if LocalPlayer.Character then
                                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                                    if v:IsA("BasePart") then v.CanCollide = false end
                                end
                            end
                        end)
                    end
                    local container = currentMap:FindFirstChild("CoinContainer")
                    if container then
                        for _, coin in pairs(container:GetChildren()) do
                            if not autofarm_enabled or not is_alive() or is_backpack_full() or not GetActiveMap() then break end
                            if coin:IsA("BasePart") and coin.Name ~= "Collected" then
                                TweenToTarget(coin.CFrame)
                                task.wait(0.15)
                            end
                        end
                    end
                else
                    if noclip_connection then noclip_connection:Disconnect() noclip_connection = nil end
                    task.wait(1)
                end
            else
                if noclip_connection then noclip_connection:Disconnect() noclip_connection = nil end
                task.wait(1)
            end
        else
            if noclip_connection then noclip_connection:Disconnect() noclip_connection = nil end
        end
    end
end)

FarmTab:AddToggle({Name = "Smart Auto Collect Coins", Default = false, Callback = function(v) autofarm_enabled = v end})
FarmTab:AddSlider({Name = "Autofarm Speed", Min = 10, Max = 100, Default = 35, Increment = 5, ValueName = "Speed", Callback = function(v) autofarm_speed = v end})

-- ==========================================
-- PLAYER SYSTEM (FLY & GHOST)
-- ==========================================
local function toggleFly(Value)
    flyEnabled = Value
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    if flyEnabled then
        if rootPart:FindFirstChild("BodyVelocity") then rootPart.BodyVelocity:Destroy() end
        if rootPart:FindFirstChild("BodyGyro") then rootPart.BodyGyro:Destroy() end
        char.Humanoid.PlatformStand = true
        bodyVelocity = Instance.new("BodyVelocity") bodyVelocity.Velocity = Vector3.new(0, 0, 0) bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000) bodyVelocity.Parent = rootPart
        bodyGyro = Instance.new("BodyGyro") bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000) bodyGyro.P = 10000 bodyGyro.D = 500 bodyGyro.Parent = rootPart
    else
        char.Humanoid.PlatformStand = false
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end
UserInputService.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.F then toggleFly(not flyEnabled) end end)

task.spawn(function()
    while task.wait(0.03) do
        if flyEnabled and is_alive() and bodyVelocity and bodyGyro then
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            local direction, cam = Vector3.new(0, 0, 0), Workspace.CurrentCamera
            bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + cam.CFrame.LookVector)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction + Vector3.new(0, -1, 0) end
            if direction.Magnitude > 0 then direction = direction.Unit end
            bodyVelocity.Velocity = direction * flySpeed
        end
    end
end)

local function UpdateRainbow()
    local hue = 0
    rainbowConnection = RunService.Heartbeat:Connect(function(dt)
        if ghostChar and ghostSettings.rainbow then
            hue = (hue + dt * (ghostSettings.rainbowSpeed / 5)) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            for _, v in pairs(ghostChar:GetDescendants()) do if v:IsA("BasePart") then v.Color = color end end
        end
    end)
end

local function ToggleInvis(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if state then
        isInvisible = true char.Archivable = true
        ghostChar = char:Clone() ghostChar.Parent = Workspace
        for _, v in pairs(ghostChar:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = ghostSettings.transparency if v:IsA("BasePart") then v.CanCollide = false end
            elseif v:IsA("LocalScript") or v:IsA("Script") then if v.Name ~= "Animate" then v:Destroy() end end
        end
        ghostChar.Humanoid.WalkSpeed = ghostSettings.speed
        Workspace.CurrentCamera.CameraSubject = ghostChar.Humanoid
        UpdateRainbow()
        syncConnection = RunService.RenderStepped:Connect(function()
            if isInvisible and ghostChar and ghostChar:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                char.HumanoidRootPart.CFrame = CFrame.new(ghostChar.HumanoidRootPart.Position.X, 50000, ghostChar.HumanoidRootPart.Position.Z)
                ghostChar.Humanoid:Move(char.Humanoid.MoveDirection, false)
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then ghostChar.Humanoid.Jump = true end
            end
        end)
    else
        isInvisible = false
        if syncConnection then syncConnection:Disconnect() end
        if rainbowConnection then rainbowConnection:Disconnect() end
        if ghostChar and ghostChar:FindFirstChild("HumanoidRootPart") then
            local ghostPos = ghostChar.HumanoidRootPart.CFrame
            ghostChar:Destroy() ghostChar = nil
            if char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = ghostPos end
        end
        Workspace.CurrentCamera.CameraSubject = char:FindFirstChild("Humanoid")
    end
end

PlayerTab:AddToggle({Name = "Fly Mode (Key: F)", Default = false, Callback = function(v) toggleFly(v) end})
PlayerTab:AddToggle({Name = "Ghost Mode (Key: X)", Default = false, Callback = function(v) ToggleInvis(v) end})
PlayerTab:AddBind({Name = "Ghost Keybind", Default = Enum.KeyCode.X, Hold = false, Callback = function() ToggleInvis(not isInvisible) end})
PlayerTab:AddSlider({Name = "Ghost Speed", Min = 16, Max = 250, Default = 16, Callback = function(v) ghostSettings.speed = v if ghostChar then ghostChar.Humanoid.WalkSpeed = v end end})
PlayerTab:AddToggle({Name = "Rainbow Ghost", Default = false, Callback = function(v) ghostSettings.rainbow = v end})

-- ==========================================
-- TELEPORT SYSTEM
-- ==========================================
local function GetTeleportPlayerNames()
    local names = {} for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end return names
end

local PlayerDropdown = TeleportTab:AddDropdown({Name = "Spieler wählen", Default = "", Options = GetTeleportPlayerNames(), Callback = function(Option) targetName = Option end})
TeleportTab:AddButton({Name = "Liste aktualisieren", Callback = function() PlayerDropdown:Refresh(GetTeleportPlayerNames(), true) end})
TeleportTab:AddButton({
    Name = "Teleport JETZT",
    Callback = function()
        if targetName ~= "" then
            local target = Players:FindFirstChild(targetName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and is_alive() then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                OrionLib:MakeNotification({Name = "Teleport", Content = "Zu " .. targetName .. " teleportiert", Time = 2})
            end
        end
    end
})

-- ==========================================
-- COMBAT & FLING SYSTEM
-- ==========================================
RunService.Heartbeat:Connect(function()
    if AntiFlingEnabled and LocalPlayer and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.Velocity = Vector3.new(0, 0, 0) v.RotVelocity = Vector3.new(0, 0, 0) end
        end
    end
end)

local PlayerDropdownFling = CombatTab:AddDropdown({Name = "Ziel auswählen", Default = "", Options = GetTeleportPlayerNames(), Callback = function(Option) SelectedPlayer = Option end})
CombatTab:AddButton({Name = "Liste aktualisieren", Callback = function() PlayerDropdownFling:Refresh(GetTeleportPlayerNames(), true) end})

CombatTab:AddButton({
    Name = "INSTANT VOID (FLING)",
    Callback = function()
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and is_alive() then
            Flinging = true
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            local oldPos = hrp.CFrame
            
            local velocity = Instance.new("BodyAngularVelocity")
            velocity.MaxTorque = Vector3.new(1, 1, 1) * math.huge
            velocity.P = math.huge
            velocity.AngularVelocity = Vector3.new(0, 999999, 0)
            velocity.Parent = hrp

            local noclipLoopFling = RunService.Stepped:Connect(function()
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end)

            while Flinging and target.Character and target.Character:FindFirstChild("HumanoidRootPart") do
                RunService.Heartbeat:Wait()
                if targetHrp.Position.Y < -50 or target.Character.Humanoid.Health <= 0 then
                    Flinging = false break
                end
                hrp.CFrame = targetHrp.CFrame
                hrp.Velocity = Vector3.new(999999, 999999, 999999)
            end

            Flinging = false
            noclipLoopFling:Disconnect()
            velocity:Destroy()
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.CFrame = oldPos
            OrionLib:MakeNotification({Name = "Fling beendet", Content = "Ziel wurde eliminiert oder ist aus der Map.", Time = 3})
        end
    end
})

CombatTab:AddButton({Name = "STOP FLING", Callback = function() Flinging = false end})
CombatTab:AddToggle({Name = "Anti-Fling Aktivieren", Default = false, Callback = function(v) AntiFlingEnabled = v end})

OrionLib:Init()
