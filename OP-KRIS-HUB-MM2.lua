-- KRIS HUB v3 - MM2 (Obsidian UI)
-- ESP + Shoot Button que SE MUEVE SOLO encima del Murderer + Grab/Steal Gun

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "KRIS HUB",
    Footer = "MM2 - Auto Moving Shoot Button",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = { Main = Window:AddTab("Main"), Settings = Window:AddTab("UI Settings") }

-- ==================== ESP ====================
local ESPEnabled = false
local highlights = {}
local roleColors = { Murderer = Color3.fromRGB(255,0,0), Sheriff = Color3.fromRGB(0,140,255), Innocent = Color3.fromRGB(0,255,0) }

local function createESP(plr)
    if not plr.Character or highlights[plr] then return end
    local hl = Instance.new("Highlight")
    hl.Parent = plr.Character
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    highlights[plr] = hl

    local bill = Instance.new("BillboardGui", plr.Character.Head)
    bill.Name = "RoleESP"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0,200,0,50)
    bill.StudsOffset = Vector3.new(0,3,0)
    local txt = Instance.new("TextLabel", bill)
    txt.BackgroundTransparency = 1
    txt.Size = UDim2.new(1,0,1,0)
    txt.TextScaled = true
    txt.Font = Enum.Font.GothamBold
    txt.TextColor3 = Color3.new(1,1,1)
    txt.TextStrokeTransparency = 0
end

local function updateESP()
    while ESPEnabled do
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= game.Players.LocalPlayer and plr.Character then
                createESP(plr)
                local knife = plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife")
                local gun   = plr.Backpack:FindFirstChild("Gun")   or plr.Character:FindFirstChild("Gun")
                local role = knife and "Murderer" or gun and "Sheriff" or "Innocent"
                highlights[plr].FillColor = roleColors[role]
                highlights[plr].OutlineColor = roleColors[role]
                if plr.Character.Head:FindFirstChild("RoleESP") then
                    plr.Character.Head.RoleESP.TextLabel.Text = role
                end
            end
        end
        task.wait(0.7)
    end
end

-- ==================== AUTO-MOVING SHOOT BUTTON ====================
local shootGui = nil
local movingButton = nil

local function createMovingShootButton()
    if shootGui then shootGui:Destroy() end

    shootGui = Instance.new("ScreenGui")
    shootGui.Parent = game:GetService("CoreGui")
    shootGui.Name = "KrisMovingShoot"

    movingButton = Instance.new("TextButton")
    movingButton.Size = UDim2.new(0, 110, 0, 110)
    movingButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
    movingButton.BorderSizePixel = 3
    movingButton.BorderColor3 = Color3.new(1,1,1)
    movingButton.Text = "SHOOT"
    movingButton.TextColor3 = Color3.new(1,1,1)
    movingButton.Font = Enum.Font.GothamBold
    movingButton.TextScaled = true
    movingButton.BackgroundTransparency = 0.3
    movingButton.Parent = shootGui
    movingButton.Active = true
    movingButton.Draggable = true  -- también lo puedes mover tú si quieres

    -- Pulsar = disparar al Murderer
    movingButton.MouseButton1Click:Connect(function()
        local murderer = nil
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= game.Players.LocalPlayer then
                if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
                    murderer = plr
                    break
                end
            end
        end

        if not murderer or not murderer.Character then
            Library:Notify("Murderer no encontrado", 2)
            return
        end

        local myGun = game.Players.LocalPlayer.Backpack:FindFirstChild("Gun") or (game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Gun"))
        if not myGun then
            Library:Notify("¡No tienes pistola!", 2)
            return
        end

        game.Players.LocalPlayer.Character.Humanoid:EquipTool(myGun)
        task.wait(0.05)
        myGun:Activate()
        Library:Notify("Disparado a "..murderer.Name, 2)
    end)

    -- ¡¡EL BOTÓN SE MUEVE SOLO ENCIMA DEL MURDERER!!
    task.spawn(function()
        while shootGui and shootGui.Parent do
            local murderer = nil
            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr ~= game.Players.LocalPlayer and plr.Character and (plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife")) then
                    murderer = plr
                    break
                end
            end

            if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
                local headPos = murderer.Character.Head.Position
                local screenPos, onScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(headPos)
                if onScreen then
                    movingButton.Position = UDim2.new(0, screenPos.X - 55, 0, screenPos.Y - 100)
                end
            end
            task.wait()
        end
    end)
end

-- ==================== UI ====================
local Left = Tabs.Main:AddLeftGroupbox("Visuals")
Left:AddToggle("esp", {Text = "Enable ESP", Callback = function(v)
    ESPEnabled = v
    if v then task.spawn(updateESP) end
end})

local Right = Tabs.Main:AddRightGroupbox("Combat")

Right:AddButton({
    Text = "Shoot Button (Auto-Move)",
    Func = function()
        if shootGui then
            shootGui:Destroy()
            shootGui = nil
            movingButton = nil
        else
            createMovingShootButton()
            Library:Notify("Botón de disparo activado - ¡se mueve solo encima del Murderer!", 5)
        end
    end
})

-- Grab / Steal Gun (mejorado)
Right:AddButton({
    Text = "Grab / Steal Gun",
    Func = function()
        local lp = game.Players.LocalPlayer
        -- 1. Pistola en el suelo
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "GunDrop" or (obj:IsA("Tool") and obj.Name == "Gun") then
                if obj:FindFirstChild("Handle") then
                    firetouchinterest(lp.Character.HumanoidRootPart, obj.Handle, 0)
                    task.wait()
                    firetouchinterest(lp.Character.HumanoidRootPart, obj.Handle, 1)
                    Library:Notify("Pistola recogida del suelo", 3)
                    return
                end
            end
        end

        -- 2. Robar al Sheriff
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= lp then
                local gun = plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun"))
                if gun then
                    lp.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                    task.wait(0.3)
                    gun.Parent = lp.Backpack
                    lp.Character.Humanoid:EquipTool(gun)
                    Library:Notify("Pistola robada a "..plr.Name.."!", 4)
                    return
                end
            end
        end
        Library:Notify("No hay pistola disponible", 3)
    end
})

-- UI Settings (mínimo)
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="RightShift", NoUI=true})
MenuGroup:AddButton("Unload", function() Library:Unload() end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("KRISHUB")
SaveManager:SetFolder("KRISHUB/mm2")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("KRIS HUB cargado - ¡El botón rojo se mueve solo encima del Murderer!", 7)
