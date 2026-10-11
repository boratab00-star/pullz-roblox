--[[
    =========================================================================
    BLOXBURG STYLEZ HAIRDRESSER AUTOMATION
    =========================================================================
    - Dedicat 100% pentru Stylez Hair Studio (Fără linii inutile de cod)
    - Detectează fiecare client și comanda cerută (Stil & Culoare)
    - Poziționare laterală în First Person pentru vizibilitate completă
    - Motor automat de finalizare comenzi (Network + GUI Auto-Click)
    - Interfață UI modernă, compactă și elegantă (Dark Glassmorphism)
    =========================================================================
--]]

-- Curățare instanță anterioară
if getgenv().BloxburgHairdresserLoaded then
    pcall(function()
        if getgenv().BloxburgHairdresserUnload then
            getgenv().BloxburgHairdresserUnload()
        end
    end)
end
getgenv().BloxburgHairdresserLoaded = true

-- Servicii Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait(0.05) LocalPlayer = Players.LocalPlayer until LocalPlayer
end
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera", 5)

-- Configurare și Stare
local Config = {
    Active = false,
    Delay = 0.8,
    FirstPerson = true,
    SideOffset = 2.4 -- Distanță laterală față de scaun
}

local State = {
    CurrentStation = nil,
    CurrentCustomer = nil,
    CurrentStyle = nil,
    CurrentColor = nil,
    TotalServed = 0,
    ServedOrders = {},
    Connections = {},
    ScreenGui = nil,
    LastCheck = 0,
    LastLogTime = 0,
    OriginalCameraMode = LocalPlayer.CameraMode
}

-- Anti-Stack / Script integrity safety hook (pcall protected)
pcall(function()
    if getgc and hookfunction and debug and debug.getinfo then
        for _, value in pairs(getgc()) do
            if typeof(value) == "function" and not (iscclosure and iscclosure(value)) then
                local info = debug.getinfo(value)
                if info and info.name == "i" then
                    hookfunction(value, function() end)
                end
            end
        end
    end
end)

-- =========================================================================
-- INTERFAȚĂ GRAFICĂ (UI COMPACT, ELEGANT & MODERN - DARK GLASSMORPHISM)
-- =========================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxburgHairdresser_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local guiParented = false
if gethui then
    pcall(function()
        ScreenGui.Parent = gethui()
        if ScreenGui.Parent then guiParented = true end
    end)
end
if not guiParented and syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
        if ScreenGui.Parent then guiParented = true end
    end)
end
if not guiParented then
    pcall(function()
        ScreenGui.Parent = CoreGui
        if ScreenGui.Parent then guiParented = true end
    end)
end
if not guiParented then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui
end
State.ScreenGui = ScreenGui

-- Fereastra Principală
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 360)
MainFrame.Position = UDim2.new(0.04, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 60)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Bară de Titlu (Draggable)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 10)
TitleBarCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✂️ Stylez Hair Studio"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Status Badge (Pill)
local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0, 56, 0, 20)
StatusBadge.Position = UDim2.new(1, -95, 0.5, -10)
StatusBadge.BackgroundColor3 = Color3.fromRGB(45, 30, 35)
StatusBadge.BorderSizePixel = 0
StatusBadge.Parent = TitleBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(1, 0)
BadgeCorner.Parent = StatusBadge

local BadgeText = Instance.new("TextLabel")
BadgeText.Size = UDim2.new(1, 0, 1, 0)
BadgeText.BackgroundTransparency = 1
BadgeText.Text = "OPRIT"
BadgeText.TextColor3 = Color3.fromRGB(255, 90, 90)
BadgeText.Font = Enum.Font.GothamBold
BadgeText.TextSize = 10
BadgeText.Parent = StatusBadge

-- Buton Închidere UI
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

-- Drag Logic pe TitleBar
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Container Conținut
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -54)
Content.Position = UDim2.new(0, 10, 0, 48)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Card Info Client Curent (Detectează și afișează fiecare client!)
local ClientCard = Instance.new("Frame")
ClientCard.Size = UDim2.new(1, 0, 0, 105)
ClientCard.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
ClientCard.BorderSizePixel = 0
ClientCard.Parent = Content

local ClientCardCorner = Instance.new("UICorner")
ClientCardCorner.CornerRadius = UDim.new(0, 8)
ClientCardCorner.Parent = ClientCard

local ClientCardStroke = Instance.new("UIStroke")
ClientCardStroke.Color = Color3.fromRGB(40, 40, 52)
ClientCardStroke.Thickness = 1
ClientCardStroke.Parent = ClientCard

local RowClient = Instance.new("TextLabel")
RowClient.Size = UDim2.new(1, -16, 0, 22)
RowClient.Position = UDim2.new(0, 10, 0, 8)
RowClient.BackgroundTransparency = 1
RowClient.Text = "👤 Client: Niciun client la scaun"
RowClient.TextColor3 = Color3.fromRGB(220, 220, 230)
RowClient.Font = Enum.Font.GothamMedium
RowClient.TextSize = 11
RowClient.TextXAlignment = Enum.TextXAlignment.Left
RowClient.Parent = ClientCard

local RowStyle = Instance.new("TextLabel")
RowStyle.Size = UDim2.new(1, -16, 0, 22)
RowStyle.Position = UDim2.new(0, 10, 0, 30)
RowStyle.BackgroundTransparency = 1
RowStyle.Text = "💇 Stil cerut: -"
RowStyle.TextColor3 = Color3.fromRGB(140, 190, 255)
RowStyle.Font = Enum.Font.GothamMedium
RowStyle.TextSize = 11
RowStyle.TextXAlignment = Enum.TextXAlignment.Left
RowStyle.Parent = ClientCard

local RowColor = Instance.new("TextLabel")
RowColor.Size = UDim2.new(1, -16, 0, 22)
RowColor.Position = UDim2.new(0, 10, 0, 52)
RowColor.BackgroundTransparency = 1
RowColor.Text = "🎨 Culoare cerută: -"
RowColor.TextColor3 = Color3.fromRGB(255, 180, 120)
RowColor.Font = Enum.Font.GothamMedium
RowColor.TextSize = 11
RowColor.TextXAlignment = Enum.TextXAlignment.Left
RowColor.Parent = ClientCard

local RowStatus = Instance.new("TextLabel")
RowStatus.Size = UDim2.new(1, -16, 0, 22)
RowStatus.Position = UDim2.new(0, 10, 0, 75)
RowStatus.BackgroundTransparency = 1
RowStatus.Text = "⚡ Status: În așteptare (Activează Start)"
RowStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
RowStatus.Font = Enum.Font.Gotham
RowStatus.TextSize = 10
RowStatus.TextXAlignment = Enum.TextXAlignment.Left
RowStatus.Parent = ClientCard

-- Buton Principal START / STOP
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 38)
ToggleBtn.Position = UDim2.new(0, 0, 0, 116)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ToggleBtn.Text = "🚀 PORNEȘTE AUTO HAIRDRESSER"
ToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- Buton Poziționare la Scaun (Lateral + First Person)
local PosBtn = Instance.new("TextButton")
PosBtn.Size = UDim2.new(0.48, 0, 0, 32)
PosBtn.Position = UDim2.new(0, 0, 0, 162)
PosBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
PosBtn.Text = "📍 La Scaun (Lateral)"
PosBtn.TextColor3 = Color3.fromRGB(180, 200, 240)
PosBtn.Font = Enum.Font.GothamMedium
PosBtn.TextSize = 10
PosBtn.BorderSizePixel = 0
PosBtn.Parent = Content

local PosCorner = Instance.new("UICorner")
PosCorner.CornerRadius = UDim.new(0, 6)
PosCorner.Parent = PosBtn

-- Buton Click DONE Manual (Pentru siguranță și test rapid)
local DoneBtn = Instance.new("TextButton")
DoneBtn.Size = UDim2.new(0.48, 0, 0, 32)
DoneBtn.Position = UDim2.new(0.52, 0, 0, 162)
DoneBtn.BackgroundColor3 = Color3.fromRGB(26, 40, 32)
DoneBtn.Text = "✂️ Click DONE Acum"
DoneBtn.TextColor3 = Color3.fromRGB(120, 240, 160)
DoneBtn.Font = Enum.Font.GothamBold
DoneBtn.TextSize = 10
DoneBtn.BorderSizePixel = 0
DoneBtn.Parent = Content

local DoneCorner = Instance.new("UICorner")
DoneCorner.CornerRadius = UDim.new(0, 6)
DoneCorner.Parent = DoneBtn

-- Slider Viteză / Delay
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, 0, 0, 44)
SliderFrame.Position = UDim2.new(0, 0, 0, 202)
SliderFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
SliderFrame.BorderSizePixel = 0
SliderFrame.Parent = Content

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 6)
SliderCorner.Parent = SliderFrame

local SliderTitle = Instance.new("TextLabel")
SliderTitle.Size = UDim2.new(0.7, 0, 0, 18)
SliderTitle.Position = UDim2.new(0, 10, 0, 4)
SliderTitle.BackgroundTransparency = 1
SliderTitle.Text = "⏱️ Viteză Servire (Delay)"
SliderTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
SliderTitle.Font = Enum.Font.GothamMedium
SliderTitle.TextSize = 10
SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
SliderTitle.Parent = SliderFrame

local SliderValText = Instance.new("TextLabel")
SliderValText.Size = UDim2.new(0.25, 0, 0, 18)
SliderValText.Position = UDim2.new(0.72, 0, 0, 4)
SliderValText.BackgroundTransparency = 1
SliderValText.Text = "0.8s"
SliderValText.TextColor3 = Color3.fromRGB(120, 220, 160)
SliderValText.Font = Enum.Font.GothamBold
SliderValText.TextSize = 10
SliderValText.TextXAlignment = Enum.TextXAlignment.Right
SliderValText.Parent = SliderFrame

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(1, -20, 0, 8)
SliderBar.Position = UDim2.new(0, 10, 0, 26)
SliderBar.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
SliderBar.BorderSizePixel = 0
SliderBar.Parent = SliderFrame

local SliderBarCorner = Instance.new("UICorner")
SliderBarCorner.CornerRadius = UDim.new(1, 0)
SliderBarCorner.Parent = SliderBar

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((Config.Delay - 0.2) / (2.5 - 0.2), 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBar

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

-- Logică Slider Drag
local sliderDragging = false
SliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        local x = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.2 + (x * (2.5 - 0.2))) * 10) / 10
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.1fs", Config.Delay)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local x = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.2 + (x * (2.5 - 0.2))) * 10) / 10
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.1fs", Config.Delay)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

-- Card Statistici Jos
local StatsCard = Instance.new("Frame")
StatsCard.Size = UDim2.new(1, 0, 0, 36)
StatsCard.Position = UDim2.new(0, 0, 0, 254)
StatsCard.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
StatsCard.BorderSizePixel = 0
StatsCard.Parent = Content

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 6)
StatsCorner.Parent = StatsCard

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, -16, 1, 0)
StatsText.Position = UDim2.new(0, 8, 0, 0)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Clienți Serviți: 0  |  Bani Estimați: $0"
StatsText.TextColor3 = Color3.fromRGB(170, 220, 180)
StatsText.Font = Enum.Font.GothamMedium
StatsText.TextSize = 10
StatsText.TextXAlignment = Enum.TextXAlignment.Center
StatsText.Parent = StatsCard

-- Helper Actualizare UI
local function updateUIStatus(clientName, style, color, status, statusColor)
    pcall(function()
        if clientName then RowClient.Text = "👤 Client: " .. tostring(clientName) end
        if style ~= nil then RowStyle.Text = "💇 Stil cerut: #" .. tostring(style) else RowStyle.Text = "💇 Stil cerut: -" end
        if color ~= nil then RowColor.Text = "🎨 Culoare cerută: #" .. tostring(color) else RowColor.Text = "🎨 Culoare cerută: -" end
        if status then
            RowStatus.Text = "⚡ " .. tostring(status)
            if statusColor then RowStatus.TextColor3 = statusColor end
        end
        StatsText.Text = string.format("Clienți Serviți: %d  |  Bani Estimați: $%d", State.TotalServed, State.TotalServed * 75)
    end)
end

-- =========================================================================
-- MOTORUL DE POZIȚIONARE ȘI HAIRDRESSER WORKSTATIONS
-- =========================================================================

-- Găsire toate posturile de lucru din salon
local function findWorkstations()
    local list = {}

    -- 1. Ierarhie oficială Bloxburg
    pcall(function()
        local loc = Workspace:FindFirstChild("Environment")
        if loc then loc = loc:FindFirstChild("Locations") end
        if loc then loc = loc:FindFirstChild("StylezHairStudio") end
        if loc then
            local ws = loc:FindFirstChild("HairdresserWorkstations") or loc:FindFirstChild("Workstations") or loc
            for _, child in ipairs(ws:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    if child:FindFirstChild("Chair") or child:FindFirstChild("Seat") or child.PrimaryPart then
                        table.insert(list, child)
                    end
                end
            end
        end
    end)
    if #list > 0 then return list end

    -- 2. Scanare directă după folder
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "HairdresserWorkstations" then
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Model") or child:IsA("Folder") then
                        table.insert(list, child)
                    end
                end
            end
        end
    end)
    if #list > 0 then return list end

    -- 3. Scanare dinamică după modele cu Chair & Mirror
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local on = obj.Name:lower()
                if (on:find("hairdresser") or on:find("stylez")) and (obj:FindFirstChild("Chair") or obj:FindFirstChild("Seat")) then
                    table.insert(list, obj)
                end
            end
        end
    end)

    return list
end

-- Obține cel mai apropiat scaun / post de lucru
local function getNearestStation()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local stations = findWorkstations()
    local best, bestDist = nil, math.huge

    for _, st in ipairs(stations) do
        local part = st:FindFirstChild("Chair") or st:FindFirstChild("Seat") or st.PrimaryPart or st:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = st
            end
        end
    end

    return best, bestDist
end

-- Asigură pontarea la job
local function ensureJob()
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local stats = rep:FindFirstChild("Stats")
        local pStats = stats and stats:FindFirstChild(LocalPlayer.Name)
        local curJob = (pStats and pStats:FindFirstChild("Job") and pStats.Job.Value) or ""
        if curJob ~= "StylezHairdresser" then
            local modules = rep:FindFirstChild("Modules")
            local ds = modules and modules:FindFirstChild("DataService")
            if ds then
                pcall(function()
                    local req = require(ds)
                    if req and req.FireServer then
                        req.FireServer("ToWork", { Type = "ToWork", Name = "StylezHairdresser" })
                    end
                end)
            end
        end
    end)
end

-- Poziționare inteligentă LATERALĂ în First Person (nu blochează scaunul!)
local function positionAtStation(station)
    if not station then
        station = getNearestStation()
    end
    if not station then
        local all = findWorkstations()
        station = all[1]
    end
    if not station then return false end

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return false end

    ensureJob()
    State.CurrentStation = station

    -- Poziționare în lateral (RightVector * 2.4 studs), puțin în față, privind spre scaun/oglindă
    local sidePos = chair.Position + (chair.CFrame.RightVector * Config.SideOffset) + (chair.CFrame.LookVector * 0.4) + Vector3.new(0, 0.6, 0)
    local lookTarget = chair.Position + Vector3.new(0, 1.2, 0)
    hrp.CFrame = CFrame.new(sidePos, lookTarget)

    -- Activare First Person pentru vizibilitate optimă a butoanelor
    if Config.FirstPerson then
        pcall(function()
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 0.5
        end)
    end

    return true
end

-- =========================================================================
-- MOTORUL DE DETECȚIE CLIENȚI (DETECTEAZĂ FIECARE CLIENT ÎN TIMP REAL!)
-- =========================================================================

local function getSpawnedCharactersFolder()
    local gameFolder = Workspace:FindFirstChild("_game")
    if gameFolder and gameFolder:FindFirstChild("SpawnedCharacters") then
        return gameFolder.SpawnedCharacters
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "SpawnedCharacters" or (obj.Name == "_game" and obj:FindFirstChild("SpawnedCharacters")) then
            return obj:FindFirstChild("SpawnedCharacters") or obj
        end
    end
    return Workspace:FindFirstChild("SpawnedCharacters", true)
end

-- Verifică clientul așezat la scaunul postului curent
local function getCustomerSeatedAtStation(station)
    if not station then return nil, nil end
    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return nil, nil end

    local scFolder = getSpawnedCharactersFolder()
    if not scFolder then return nil, nil end

    local closestCustomer = nil
    local minDistance = 4.5 -- Doar clienții așezați fix la scaun

    for _, char in ipairs(scFolder:GetChildren()) do
        local cName = char.Name:lower()
        if cName:find("stylez") or cName:find("customer") or cName:find("hair") or char.Name == "StylezHairStudioCustomer" then
            local root = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root then
                local dist = (root.Position - chair.Position).Magnitude
                if dist < minDistance then
                    -- Verifică dacă stă jos (Air floor sau Sit sau altitudine de scaun)
                    local isSeated = (hum and (hum.Sit or hum.FloorMaterial == Enum.Material.Air)) or (math.abs(root.Position.Y - chair.Position.Y) < 2.0)
                    if isSeated then
                        minDistance = dist
                        closestCustomer = char
                    end
                end
            end
        end
    end

    return closestCustomer, chair
end

-- =========================================================================
-- MOTORUL DE FINALIZARE COMENZI (DONE CLICKER + NETWORK FALLBACK)
-- =========================================================================

-- Clicker cu suport multiplu pe butoane GUI din PlayerGui
local function executeDoneClick()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end

    local clicked = false

    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("GuiButton") and desc.Visible and desc.AbsoluteSize.X > 15 and desc.AbsoluteSize.Y > 15 then
            local bName = desc.Name:lower()
            local bText = (desc:IsA("TextButton") and desc.Text:lower()) or ""
            for _, c in ipairs(desc:GetChildren()) do
                if c:IsA("TextLabel") and c.Text then bText = bText .. " " .. c.Text:lower() end
            end

            -- Căutare buton Done / Finish / Gata / Confirm
            local isDone = bName:find("done") or bText:find("done") or
                           bName:find("finish") or bText:find("finish") or
                           bName:find("gata") or bText:find("gata") or
                           bName:find("confirm") or bText:find("confirm") or
                           bName:find("submit") or bText:find("submit")

            -- Buton verde de acțiune principală
            if not isDone and desc.BackgroundColor3 then
                local col = desc.BackgroundColor3
                if col.G > 0.55 and col.G > (col.R * 1.3) and col.G > (col.B * 1.3) then
                    if not (bName:find("arrow") or bText:find("<") or bText:find(">")) then
                        isDone = true
                    end
                end
            end

            if isDone then
                local pos = desc.AbsolutePosition + (desc.AbsoluteSize / 2)
                local x = math.floor(pos.X)
                local y = math.floor(pos.Y)

                -- 1. firesignal
                pcall(function()
                    if firesignal then
                        firesignal(desc.MouseButton1Down)
                        firesignal(desc.MouseButton1Click)
                        firesignal(desc.MouseButton1Up)
                        firesignal(desc.Activated)
                    end
                end)

                -- 2. VirtualInputManager Hardware click
                pcall(function()
                    if VirtualInputManager then
                        VirtualInputManager:SendMouseMoveEvent(x, y, game)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait(0.03)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end
                end)

                -- 3. VirtualUser fallback
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(x, y))
                end)

                clicked = true
            end
        end
    end

    return clicked
end

-- Trimitere payload JobCompleted către server (DataService fallback)
local function sendJobCompletedNetwork(station, styleVal, colorVal)
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local modules = rep:FindFirstChild("Modules")
        local dsModule = (modules and modules:FindFirstChild("DataService")) or rep:FindFirstChild("DataService", true)

        if dsModule then
            local ds = require(dsModule)
            if ds then
                local payload = {
                    Type = "JobCompleted",
                    Workstation = station,
                    Order = { styleVal, colorVal }
                }

                -- 1. Upvalue getRemote if available
                if debug and debug.getupvalue and ds.FireServer then
                    local fn = debug.getupvalue(ds.FireServer, 5)
                    if typeof(fn) == "function" then
                        local rem = fn("JobCompleted")
                        if rem and typeof(rem) == "Instance" then
                            rem:FireServer(payload)
                            return
                        end
                    end
                end

                -- 2. Direct ds.FireServer
                if ds.FireServer then
                    pcall(function() ds.FireServer("JobCompleted", payload) end)
                    pcall(function() ds:FireServer("JobCompleted", payload) end)
                end
            end
        end
    end)
end

-- =========================================================================
-- BUCLE PRINCIPALE DE AUTOMATIZARE
-- =========================================================================

-- Verificare și Procesare Client
local isRunningStep = false
local function processHairStep()
    if not Config.Active or isRunningStep then return end
    isRunningStep = true

    local char = LocalPlayer.Character
    if not char then isRunningStep = false return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then isRunningStep = false return end

    -- Găsește sau actualizează postul
    local station = State.CurrentStation
    if not station or not station.Parent then
        station = getNearestStation()
        if station then State.CurrentStation = station end
    end

    if not station then
        updateUIStatus(nil, nil, nil, "Caut un post de lucru în salon...", Color3.fromRGB(200, 200, 220))
        isRunningStep = false
        return
    end

    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then isRunningStep = false return end

    -- Păstrează poziția laterală optimă lângă scaun (nu în spate!)
    local distToChair = (hrp.Position - chair.Position).Magnitude
    if distToChair > 5.0 then
        positionAtStation(station)
        task.wait(0.2)
    end

    -- Caută clientul așezat la scaun
    local customer = getCustomerSeatedAtStation(station)

    if customer and customer.Parent then
        local order = customer:FindFirstChild("Order")
        local styleObj = order and order:FindFirstChild("Style")
        local colorObj = order and order:FindFirstChild("Color")
        local styleVal = styleObj and styleObj.Value
        local colorVal = colorObj and colorObj.Value

        -- Cheie unică pentru comanda acestui client
        local orderKey = tostring(customer) .. "_" .. tostring(styleVal) .. "_" .. tostring(colorVal)

        -- Verifică dacă această comandă a fost deja procesată
        if not State.ServedOrders[orderKey] and styleVal ~= nil and colorVal ~= nil then
            State.CurrentCustomer = customer
            State.CurrentStyle = styleVal
            State.CurrentColor = colorVal

            updateUIStatus(customer.Name, styleVal, colorVal, "Client nou la scaun! Pregătesc comanda...", Color3.fromRGB(100, 220, 255))

            -- Așteaptă delay-ul configurat pentru un ritm natural
            local delaySec = math.clamp(Config.Delay or 0.8, 0.2, 3.0)
            task.wait(delaySec)

            -- Marchează comanda ca finalizată
            State.ServedOrders[orderKey] = true
            State.TotalServed = State.TotalServed + 1

            -- Finalizează comanda prin click pe ecran și rețea
            executeDoneClick()
            sendJobCompletedNetwork(station, styleVal, colorVal)
            task.wait(0.1)
            executeDoneClick()

            updateUIStatus(customer.Name, styleVal, colorVal, "🎉 Comandă finalizată! Aștept următorul client...", Color3.fromRGB(120, 255, 160))
            task.wait(0.6)
        else
            -- Clientul curent este deja servit, așteaptă să plece și să vină următorul
            if State.ServedOrders[orderKey] then
                updateUIStatus(customer.Name, styleVal, colorVal, "Aștept ca noul client să se așeze...", Color3.fromRGB(200, 200, 220))
            end
        end
    else
        -- Niciun client nu stă în scaun acum
        State.CurrentCustomer = nil
        updateUIStatus("Niciun client la scaun", "-", "-", "Aștept ca un client să se așeze pe scaun...", Color3.fromRGB(180, 180, 190))

        -- Curățare comenzi vechi care nu mai sunt la scaun
        for k, _ in pairs(State.ServedOrders) do
            State.ServedOrders[k] = nil
        end
    end

    isRunningStep = false
end

-- Buclă de fundal pentru Auto Hairdresser
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(0.15)
        if Config.Active and getgenv().BloxburgHairdresserLoaded then
            pcall(processHairStep)
        end
    end
end))

-- =========================================================================
-- EVENIMENTE BUTOANE UI
-- =========================================================================

-- Buton Toggle START / STOP
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Active = not Config.Active

    if Config.Active then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 75)
        ToggleBtn.Text = "🛑 OPREȘTE AUTO HAIRDRESSER"
        StatusBadge.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
        BadgeText.TextColor3 = Color3.fromRGB(80, 255, 140)
        BadgeText.Text = "ACTIV"

        -- Poziționează automat la cel mai apropiat scaun
        positionAtStation()
        updateUIStatus(nil, nil, nil, "Auto Hairdresser ACTIVAT! Detectez clienții...", Color3.fromRGB(100, 255, 150))
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        ToggleBtn.Text = "🚀 PORNEȘTE AUTO HAIRDRESSER"
        StatusBadge.BackgroundColor3 = Color3.fromRGB(45, 30, 35)
        BadgeText.TextColor3 = Color3.fromRGB(255, 90, 90)
        BadgeText.Text = "OPRIT"

        -- Restaurează camera normală dacă este oprit
        pcall(function()
            LocalPlayer.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 128
        end)

        updateUIStatus(nil, nil, nil, "Auto Hairdresser OPRIT.", Color3.fromRGB(255, 120, 120))
    end
end)

-- Buton Poziționare la Scaun
PosBtn.MouseButton1Click:Connect(function()
    local ok = positionAtStation()
    if ok then
        updateUIStatus(nil, nil, nil, "Poziționat lateral la scaun în First Person! ✅", Color3.fromRGB(120, 220, 255))
    else
        updateUIStatus(nil, nil, nil, "Nu am găsit un scaun liber în apropiere!", Color3.fromRGB(255, 160, 80))
    end
end)

-- Buton Click DONE Manual
DoneBtn.MouseButton1Click:Connect(function()
    local clicked = executeDoneClick()
    if State.CurrentStation and State.CurrentStyle and State.CurrentColor then
        sendJobCompletedNetwork(State.CurrentStation, State.CurrentStyle, State.CurrentColor)
    end
    if clicked then
        updateUIStatus(nil, nil, nil, "Butonul Done a fost apăsat cu succes! ✂️", Color3.fromRGB(120, 255, 160))
    else
        updateUIStatus(nil, nil, nil, "Am simulat Done pe ecran și rețea! ✂️", Color3.fromRGB(255, 220, 100))
    end
end)

-- Buton Închidere / Descărcare Script
local function unloadScript()
    Config.Active = false

    -- Restaurează setările camerei
    pcall(function()
        LocalPlayer.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 128
    end)

    -- Șterge ScreenGui
    if State.ScreenGui and State.ScreenGui.Parent then
        State.ScreenGui:Destroy()
    end

    getgenv().BloxburgHairdresserLoaded = nil
    getgenv().BloxburgHairdresserUnload = nil
end

CloseBtn.MouseButton1Click:Connect(unloadScript)
getgenv().BloxburgHairdresserUnload = unloadScript

print("[Stylez Hairdresser] Script încărcat cu succes! UI compact pregătit. ✂️")
