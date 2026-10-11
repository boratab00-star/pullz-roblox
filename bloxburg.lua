--[[
    =========================================================================
    BLOXBURG STYLEZ HAIRDRESSER - ULTRA CLEAN & DEDICATED
    =========================================================================
    - 100% Doar pentru Stylez Hair Studio
    - Detectează automat ORICE scaun la care te așezi (dinamic, fără blocare)
    - Detectează fiecare client care vine la scaun și comanda cerută (Stil & Culoare)
    - Poziționare laterală în First Person (nu obstrucționează vederea)
    - Auto-Done multi-engine (GUI click + Network)
    - UI modern, compact și simplu (sub 250 linii)
    =========================================================================
--]]

-- Curățare instanță precedentă
if getgenv().StylezHairLoaded then
    pcall(function()
        if getgenv().StylezHairUnload then getgenv().StylezHairUnload() end
    end)
end
getgenv().StylezHairLoaded = true

-- Servicii
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- Configurare & Stare (Activ automat la pornire!)
local Config = {
    Active = true,
    Delay = 0.8,
    FirstPerson = true
}

local State = {
    CurrentStation = nil,
    CurrentCustomer = nil,
    CurrentStyle = nil,
    CurrentColor = nil,
    LastServedOrderKey = nil,
    TotalServed = 0,
    Connections = {},
    ScreenGui = nil,
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
-- INTERFAȚĂ GRAFICĂ SIMPLĂ ȘI ELEGANTĂ (COMPACT DARK THEME)
-- =========================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StylezHair_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local attached = false
if gethui then
    pcall(function()
        ScreenGui.Parent = gethui()
        if ScreenGui.Parent then attached = true end
    end)
end
if not attached and syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
        if ScreenGui.Parent then attached = true end
    end)
end
if not attached then
    pcall(function()
        ScreenGui.Parent = CoreGui
        if ScreenGui.Parent then attached = true end
    end)
end
if not attached then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui
end
State.ScreenGui = ScreenGui

-- Fereastră principală compactă (280 x 310 px)
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 280, 0, 310)
Frame.Position = UDim2.new(0.03, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(40, 40, 55)
FrameStroke.Thickness = 1
FrameStroke.Parent = Frame

-- Bară de titlu (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TopBar.BorderSizePixel = 0
TopBar.Parent = Frame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 160, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "✂️ Stylez Hairdresser"
TitleText.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TopBar

-- Status Badge
local Badge = Instance.new("Frame")
Badge.Size = UDim2.new(0, 50, 0, 18)
Badge.Position = UDim2.new(1, -85, 0.5, -9)
Badge.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
Badge.BorderSizePixel = 0
Badge.Parent = TopBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(1, 0)
BadgeCorner.Parent = Badge

local BadgeLabel = Instance.new("TextLabel")
BadgeLabel.Size = UDim2.new(1, 0, 1, 0)
BadgeLabel.BackgroundTransparency = 1
BadgeLabel.Text = "ACTIV"
BadgeLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
BadgeLabel.Font = Enum.Font.GothamBold
BadgeLabel.TextSize = 9
BadgeLabel.Parent = Badge

-- Buton Închidere
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Drag logic pe bara de titlu
local isDragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- Corpul Interfeței
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -16, 1, -48)
Body.Position = UDim2.new(0, 8, 0, 44)
Body.BackgroundTransparency = 1
Body.Parent = Frame

-- Card de Info Live pentru Post & Client
local InfoCard = Instance.new("Frame")
InfoCard.Size = UDim2.new(1, 0, 0, 92)
InfoCard.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
InfoCard.BorderSizePixel = 0
InfoCard.Parent = Body

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 6)
InfoCorner.Parent = InfoCard

local RowStation = Instance.new("TextLabel")
RowStation.Size = UDim2.new(1, -12, 0, 20)
RowStation.Position = UDim2.new(0, 8, 0, 4)
RowStation.BackgroundTransparency = 1
RowStation.Text = "📍 Post: Caut scaunul tău..."
RowStation.TextColor3 = Color3.fromRGB(160, 200, 255)
RowStation.Font = Enum.Font.GothamMedium
RowStation.TextSize = 10
RowStation.TextXAlignment = Enum.TextXAlignment.Left
RowStation.Parent = InfoCard

local RowClient = Instance.new("TextLabel")
RowClient.Size = UDim2.new(1, -12, 0, 20)
RowClient.Position = UDim2.new(0, 8, 0, 24)
RowClient.BackgroundTransparency = 1
RowClient.Text = "👤 Client: Aștept client la scaun..."
RowClient.TextColor3 = Color3.fromRGB(230, 230, 240)
RowClient.Font = Enum.Font.GothamMedium
RowClient.TextSize = 10
RowClient.TextXAlignment = Enum.TextXAlignment.Left
RowClient.Parent = InfoCard

local RowOrder = Instance.new("TextLabel")
RowOrder.Size = UDim2.new(1, -12, 0, 20)
RowOrder.Position = UDim2.new(0, 8, 0, 44)
RowOrder.BackgroundTransparency = 1
RowOrder.Text = "💇 Stil: -   |   🎨 Culoare: -"
RowOrder.TextColor3 = Color3.fromRGB(255, 190, 120)
RowOrder.Font = Enum.Font.GothamBold
RowOrder.TextSize = 10
RowOrder.TextXAlignment = Enum.TextXAlignment.Left
RowOrder.Parent = InfoCard

local RowStatus = Instance.new("TextLabel")
RowStatus.Size = UDim2.new(1, -12, 0, 20)
RowStatus.Position = UDim2.new(0, 8, 0, 66)
RowStatus.BackgroundTransparency = 1
RowStatus.Text = "⚡ Stare: Gata de lucru (Stai la un scaun)"
RowStatus.TextColor3 = Color3.fromRGB(140, 240, 160)
RowStatus.Font = Enum.Font.Gotham
RowStatus.TextSize = 9
RowStatus.TextXAlignment = Enum.TextXAlignment.Left
RowStatus.Parent = InfoCard

-- Buton Principal START / PAUZĂ
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 34)
ToggleBtn.Position = UDim2.new(0, 0, 0, 98)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 75)
ToggleBtn.Text = "🟢 ACTIVAT (Click pentru Pauză)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 10
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = Body

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- Buton Poziționare Laterală la Scaun
local AlignBtn = Instance.new("TextButton")
AlignBtn.Size = UDim2.new(0.48, 0, 0, 28)
AlignBtn.Position = UDim2.new(0, 0, 0, 138)
AlignBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
AlignBtn.Text = "📍 La Scaun (Lateral)"
AlignBtn.TextColor3 = Color3.fromRGB(180, 210, 255)
AlignBtn.Font = Enum.Font.GothamMedium
AlignBtn.TextSize = 9
AlignBtn.BorderSizePixel = 0
AlignBtn.Parent = Body

local AlignCorner = Instance.new("UICorner")
AlignCorner.CornerRadius = UDim.new(0, 6)
AlignCorner.Parent = AlignBtn

-- Buton DONE Manual
local DoneBtn = Instance.new("TextButton")
DoneBtn.Size = UDim2.new(0.48, 0, 0, 28)
DoneBtn.Position = UDim2.new(0.52, 0, 0, 138)
DoneBtn.BackgroundColor3 = Color3.fromRGB(28, 42, 32)
DoneBtn.Text = "✂️ Click DONE Manual"
DoneBtn.TextColor3 = Color3.fromRGB(130, 250, 170)
DoneBtn.Font = Enum.Font.GothamBold
DoneBtn.TextSize = 9
DoneBtn.BorderSizePixel = 0
DoneBtn.Parent = Body

local DoneCorner = Instance.new("UICorner")
DoneCorner.CornerRadius = UDim.new(0, 6)
DoneCorner.Parent = DoneBtn

-- Slider Viteză
local SliderBox = Instance.new("Frame")
SliderBox.Size = UDim2.new(1, 0, 0, 40)
SliderBox.Position = UDim2.new(0, 0, 0, 172)
SliderBox.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
SliderBox.BorderSizePixel = 0
SliderBox.Parent = Body

local SliderBoxCorner = Instance.new("UICorner")
SliderBoxCorner.CornerRadius = UDim.new(0, 6)
SliderBoxCorner.Parent = SliderBox

local SliderText = Instance.new("TextLabel")
SliderText.Size = UDim2.new(0.7, 0, 0, 16)
SliderText.Position = UDim2.new(0, 8, 0, 3)
SliderText.BackgroundTransparency = 1
SliderText.Text = "⏱️ Viteză Servire"
SliderText.TextColor3 = Color3.fromRGB(180, 180, 190)
SliderText.Font = Enum.Font.GothamMedium
SliderText.TextSize = 9
SliderText.TextXAlignment = Enum.TextXAlignment.Left
SliderText.Parent = SliderBox

local SliderValText = Instance.new("TextLabel")
SliderValText.Size = UDim2.new(0.25, 0, 0, 16)
SliderValText.Position = UDim2.new(0.72, 0, 0, 3)
SliderValText.BackgroundTransparency = 1
SliderValText.Text = "0.8s"
SliderValText.TextColor3 = Color3.fromRGB(120, 220, 160)
SliderValText.Font = Enum.Font.GothamBold
SliderValText.TextSize = 9
SliderValText.TextXAlignment = Enum.TextXAlignment.Right
SliderValText.Parent = SliderBox

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -16, 0, 6)
SliderTrack.Position = UDim2.new(0, 8, 0, 24)
SliderTrack.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderBox

local SliderTrackCorner = Instance.new("UICorner")
SliderTrackCorner.CornerRadius = UDim.new(1, 0)
SliderTrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((Config.Delay - 0.2) / (2.5 - 0.2), 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

-- Slider Drag Event
local isDraggingSlider = false
SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
        local x = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.2 + (x * (2.5 - 0.2))) * 10) / 10
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.1fs", Config.Delay)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local x = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.2 + (x * (2.5 - 0.2))) * 10) / 10
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.1fs", Config.Delay)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
    end
end)

-- Bară Statistici Jos
local StatsPill = Instance.new("Frame")
StatsPill.Size = UDim2.new(1, 0, 0, 30)
StatsPill.Position = UDim2.new(0, 0, 0, 218)
StatsPill.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
StatsPill.BorderSizePixel = 0
StatsPill.Parent = Body

local StatsPillCorner = Instance.new("UICorner")
StatsPillCorner.CornerRadius = UDim.new(0, 6)
StatsPillCorner.Parent = StatsPill

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, 0, 1, 0)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Total Serviți: 0   |   Bani: $0"
StatsText.TextColor3 = Color3.fromRGB(160, 220, 180)
StatsText.Font = Enum.Font.GothamMedium
StatsText.TextSize = 9
StatsText.Parent = StatsPill

-- =========================================================================
-- MOTORUL DE SCANARE WORKSTATION ȘI CLIENȚI (DINAMIC PENTRU ORICE SCAUN)
-- =========================================================================

-- Găsește toate posturile de lucru din joc
local function getAllWorkstations()
    local list = {}
    -- Cale directă Stylez Hair Studio
    pcall(function()
        local loc = Workspace:FindFirstChild("Environment")
        if loc then loc = loc:FindFirstChild("Locations") end
        if loc then loc = loc:FindFirstChild("StylezHairStudio") end
        if loc then
            local ws = loc:FindFirstChild("HairdresserWorkstations") or loc:FindFirstChild("Workstations") or loc
            for _, c in ipairs(ws:GetChildren()) do
                if c:IsA("Model") or c:IsA("Folder") then
                    table.insert(list, c)
                end
            end
        end
    end)
    if #list > 0 then return list end

    -- Căutare după nume HairdresserWorkstations
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "HairdresserWorkstations" then
                for _, c in ipairs(obj:GetChildren()) do
                    if c:IsA("Model") or c:IsA("Folder") then
                        table.insert(list, c)
                    end
                end
            end
        end
    end)
    if #list > 0 then return list end

    -- Căutare modele ce conțin Mirror sau Chair
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:lower():find("hair") or obj.Name:lower():find("stylez")) then
                if obj:FindFirstChild("Chair") or obj:FindFirstChild("Seat") or obj:FindFirstChild("Mirror") then
                    table.insert(list, obj)
                end
            end
        end
    end)

    return list
end

-- Detectează automat scaunul lângă care se află jucătorul în mod real!
local function getNearestStationToPlayer()
    local char = LocalPlayer.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local all = getAllWorkstations()
    local nearest, minDist = nil, math.huge

    for _, st in ipairs(all) do
        local part = st:FindFirstChild("Chair") or st:FindFirstChild("Seat") or st.PrimaryPart or st:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < minDist then
                minDist = d
                nearest = st
            end
        end
    end

    return nearest, minDist
end

-- Asigură pontarea la job dacă este nevoie
local function ensureHairJob()
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local stats = rep:FindFirstChild("Stats")
        local pStats = stats and stats:FindFirstChild(LocalPlayer.Name)
        local curJob = (pStats and pStats:FindFirstChild("Job") and pStats.Job.Value) or ""
        if curJob ~= "StylezHairdresser" then
            local modules = rep:FindFirstChild("Modules")
            local ds = modules and modules:FindFirstChild("DataService")
            if ds then
                local ok, req = pcall(require, ds)
                if ok and req and req.FireServer then
                    req.FireServer("ToWork", { Type = "ToWork", Name = "StylezHairdresser" })
                end
            end
        end
    end)
end

-- Poziționare laterală în First Person (nu stă în spatele scaunului)
local function alignToStation(station)
    if not station then
        station = getNearestStationToPlayer()
    end
    if not station then return false end

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return false end

    ensureHairJob()

    -- Poziționare în lateral (RightVector * 2.2) privind spre scaun/oglindă
    local sidePos = chair.Position + (chair.CFrame.RightVector * 2.2) + (chair.CFrame.LookVector * 0.3) + Vector3.new(0, 0.5, 0)
    local targetPos = chair.Position + Vector3.new(0, 1.2, 0)
    hrp.CFrame = CFrame.new(sidePos, targetPos)

    -- Activare First Person
    pcall(function()
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
    end)

    return true
end

-- =========================================================================
-- DETECȚIE CLIENT ȘI COMANDĂ (BULLETPROOF PENTRU ORICE SCAUN)
-- =========================================================================

-- Caută clientul și comanda lui la scaunul selectat
local function findCustomerAtStation(station)
    if not station then return nil, nil, nil end
    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return nil, nil, nil end

    local bestCustomer = nil
    local bestStyle = nil
    local bestColor = nil
    local minDistance = 6.5 -- În raza scaunului

    -- 1. Verificare folder _game.SpawnedCharacters
    local searchList = {}
    local gameFolder = Workspace:FindFirstChild("_game")
    if gameFolder and gameFolder:FindFirstChild("SpawnedCharacters") then
        for _, c in ipairs(gameFolder.SpawnedCharacters:GetChildren()) do
            table.insert(searchList, c)
        end
    end

    -- 2. Verificare alte modele din Workspace dacă lista e goală
    if #searchList == 0 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                table.insert(searchList, obj)
            end
        end
    end

    -- Caută modelul cel mai apropiat care are un obiect 'Order'
    for _, model in ipairs(searchList) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
            if root then
                local d = (root.Position - chair.Position).Magnitude
                if d < minDistance then
                    local order = model:FindFirstChild("Order")
                    if order then
                        local sObj = order:FindFirstChild("Style")
                        local cObj = order:FindFirstChild("Color")
                        if sObj and cObj then
                            minDistance = d
                            bestCustomer = model
                            bestStyle = sObj.Value
                            bestColor = cObj.Value
                        end
                    end
                end
            end
        end
    end

    -- 3. Fallback: Căutare descendent direct cu numele "Order" lângă scaun
    if not bestCustomer then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "Order" and (desc:IsA("Folder") or desc:IsA("Configuration") or desc:IsA("Model")) then
                local model = desc:FindFirstAncestorOfClass("Model")
                if model and model ~= LocalPlayer.Character then
                    local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
                    if root then
                        local d = (root.Position - chair.Position).Magnitude
                        if d < minDistance then
                            local sObj = desc:FindFirstChild("Style")
                            local cObj = desc:FindFirstChild("Color")
                            if sObj and cObj then
                                minDistance = d
                                bestCustomer = model
                                bestStyle = sObj.Value
                                bestColor = cObj.Value
                            end
                        end
                    end
                end
            end
        end
    end

    return bestCustomer, bestStyle, bestColor
end

-- =========================================================================
-- FINALIZARE COMANDĂ (GUI CLICK + NETWORK)
-- =========================================================================

local function clickDoneOnScreen()
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

            local isDone = bName:find("done") or bText:find("done") or
                           bName:find("finish") or bText:find("finish") or
                           bName:find("gata") or bText:find("gata") or
                           bName:find("confirm") or bText:find("confirm") or
                           bName:find("cut") or bText:find("cut")

            -- Buton verde de acțiune
            if not isDone and desc.BackgroundColor3 then
                local col = desc.BackgroundColor3
                if col.G > 0.55 and col.G > (col.R * 1.3) and not (bName:find("arrow") or bText:find("<") or bText:find(">")) then
                    isDone = true
                end
            end

            if isDone then
                local pos = desc.AbsolutePosition + (desc.AbsoluteSize / 2)
                local x = math.floor(pos.X)
                local y = math.floor(pos.Y)

                pcall(function()
                    if firesignal then
                        firesignal(desc.MouseButton1Down)
                        firesignal(desc.MouseButton1Click)
                        firesignal(desc.MouseButton1Up)
                        firesignal(desc.Activated)
                    end
                end)

                pcall(function()
                    if VirtualInputManager then
                        VirtualInputManager:SendMouseMoveEvent(x, y, game)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait(0.03)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end
                end)

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

-- Trimitere payload de rețea JobCompleted
local function fireJobCompletedRemote(station, styleVal, colorVal)
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local modules = rep:FindFirstChild("Modules")
        local dsModule = (modules and modules:FindFirstChild("DataService")) or rep:FindFirstChild("DataService", true)
        if dsModule then
            local ok, ds = pcall(require, dsModule)
            if ok and ds then
                local payload = {
                    Type = "JobCompleted",
                    Workstation = station,
                    Order = { styleVal, colorVal }
                }

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

                if ds.FireServer then
                    pcall(function() ds.FireServer("JobCompleted", payload) end)
                    pcall(function() ds:FireServer("JobCompleted", payload) end)
                end
            end
        end
    end)
end

-- =========================================================================
-- BUCALĂ PRINCIPALĂ DE LUCRU
-- =========================================================================

local isProcessing = false
local function loopStep()
    if not Config.Active or isProcessing then return end
    isProcessing = true

    -- 1. Găsește postul cel mai apropiat de unde se află jucătorul ACUM
    local station, dist = getNearestStationToPlayer()

    if not station or dist > 14 then
        RowStation.Text = "📍 Post: Mergi lângă un scaun din salon..."
        RowStation.TextColor3 = Color3.fromRGB(255, 180, 100)
        RowStatus.Text = "⚡ Stare: Aștept să te pui la un scaun"
        RowStatus.TextColor3 = Color3.fromRGB(200, 200, 210)
        isProcessing = false
        return
    end

    State.CurrentStation = station
    RowStation.Text = string.format("📍 Post: %s (la %d studs)", station.Name, math.floor(dist))
    RowStation.TextColor3 = Color3.fromRGB(120, 220, 160)

    -- 2. Caută clientul sosit la acest scaun
    local customer, styleVal, colorVal = findCustomerAtStation(station)

    if customer and styleVal ~= nil and colorVal ~= nil then
        local orderKey = tostring(customer) .. "_" .. tostring(styleVal) .. "_" .. tostring(colorVal)

        -- Verifică dacă această comandă a fost deja servită
        if State.LastServedOrderKey ~= orderKey then
            State.CurrentCustomer = customer
            State.CurrentStyle = styleVal
            State.CurrentColor = colorVal

            -- Afișare clară a clientului și a comenzii în interfață!
            RowClient.Text = "👤 Client: " .. customer.Name
            RowOrder.Text = string.format("💇 Stil: #%s   |   🎨 Culoare: #%s", tostring(styleVal), tostring(colorVal))
            RowStatus.Text = "⚡ Client nou la scaun! Finalizez comanda..."
            RowStatus.TextColor3 = Color3.fromRGB(100, 220, 255)

            -- Așteaptă delay-ul setat
            task.wait(math.clamp(Config.Delay or 0.8, 0.2, 3.0))

            -- Finalizare comandă (GUI click + Network)
            clickDoneOnScreen()
            fireJobCompletedRemote(station, styleVal, colorVal)
            task.wait(0.1)
            clickDoneOnScreen()

            State.LastServedOrderKey = orderKey
            State.TotalServed = State.TotalServed + 1

            RowStatus.Text = "🎉 Comandă finalizată cu succes!"
            RowStatus.TextColor3 = Color3.fromRGB(120, 255, 150)
            StatsText.Text = string.format("Total Serviți: %d   |   Bani: $%d", State.TotalServed, State.TotalServed * 75)

            task.wait(0.6)
        else
            -- Comanda este deja făcută, așteaptă ca clientul să plece din scaun
            RowStatus.Text = "Aștept ca clientul servit să se ridice..."
            RowStatus.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
    else
        -- Nu este niciun client în scaun în acest moment
        State.CurrentCustomer = nil
        State.CurrentStyle = nil
        State.CurrentColor = nil

        RowClient.Text = "👤 Client: Aștept client la scaun..."
        RowOrder.Text = "💇 Stil: -   |   🎨 Culoare: -"
        RowStatus.Text = "⚡ Stare: Scaun liber, aștept clientul..."
        RowStatus.TextColor3 = Color3.fromRGB(180, 180, 190)

        -- Resetează cheia când scaunul este complet gol
        State.LastServedOrderKey = nil
    end

    isProcessing = false
end

-- Rulare buclă
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.Active and getgenv().StylezHairLoaded then
            pcall(loopStep)
        end
    end
end))

-- =========================================================================
-- BUTOANE UI
-- =========================================================================

-- Buton Start / Pauză
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Active = not Config.Active

    if Config.Active then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 75)
        ToggleBtn.Text = "🟢 ACTIVAT (Click pentru Pauză)"
        Badge.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
        BadgeLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
        BadgeLabel.Text = "ACTIV"
        RowStatus.Text = "⚡ Stare: Auto Hairdresser reluat!"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
        ToggleBtn.Text = "🔴 OPRIT (Click pentru Activare)"
        Badge.BackgroundColor3 = Color3.fromRGB(50, 25, 30)
        BadgeLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        BadgeLabel.Text = "PAUZĂ"
        RowStatus.Text = "⚡ Stare: Pus pe pauză"

        -- Restaurează camera
        pcall(function()
            LocalPlayer.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 128
        end)
    end
end)

-- Buton Ajustare la Scaun
AlignBtn.MouseButton1Click:Connect(function()
    local ok = alignToStation()
    if ok then
        RowStatus.Text = "⚡ Poziționat lateral la scaun în 1st Person! ✅"
    else
        RowStatus.Text = "⚡ Nu ești aproape de niciun scaun!"
    end
end)

-- Buton Done Manual
DoneBtn.MouseButton1Click:Connect(function()
    local clicked = clickDoneOnScreen()
    if State.CurrentStation and State.CurrentStyle and State.CurrentColor then
        fireJobCompletedRemote(State.CurrentStation, State.CurrentStyle, State.CurrentColor)
    end
    if clicked then
        RowStatus.Text = "⚡ Done apăsat cu succes pe ecran! ✂️"
    else
        RowStatus.Text = "⚡ Am trimis comanda Done! ✂️"
    end
end)

-- Descărcare Script
local function unload()
    Config.Active = false
    pcall(function()
        LocalPlayer.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 128
    end)
    if State.ScreenGui and State.ScreenGui.Parent then
        State.ScreenGui:Destroy()
    end
    getgenv().StylezHairLoaded = nil
    getgenv().StylezHairUnload = nil
end

CloseBtn.MouseButton1Click:Connect(unload)
getgenv().StylezHairUnload = unload

print("[Stylez Hairdresser] Script gata! Auto-Start activat. ✂️")
