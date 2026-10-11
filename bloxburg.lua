--[[
    =========================================================================
    BLOXBURG STYLEZ HAIRDRESSER - BULLETPROOF CONTINUOUS AUTO-FARM
    =========================================================================
    - Detectează continuu toți clienții (Client 1, Client 2, Client 3...)
    - Filtru geometric 2D pe planul orizontal (XZ < 3.0 studs) pentru scaun
    - Memorează postul curent (nu sare între scaune vecine din salon)
    - Căutare butoane pe SurfaceGui (Oglindă salon) și PlayerGui
    - Declanșare click triplă (firesignal + VirtualInputManager + VirtualUser)
    - Învățare automată a poziției Done dacă dai click manual
    - Poziționare laterală în First Person (nu stă în spatele scaunului)
    - UI compact, modern și simplu (280x340 px)
    =========================================================================
--]]

-- Curățare instanță anterioară
if getgenv().StylezHairLoaded then
    pcall(function()
        if getgenv().StylezHairUnload then getgenv().StylezHairUnload() end
    end)
end
getgenv().StylezHairLoaded = true

-- Servicii Roblox
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

-- Configurare & Stare (ACTIV din prima secundă)
local Config = {
    Active = true,
    Delay = 0.8
}

local State = {
    CurrentStation = nil,
    CurrentCustomer = nil,
    LastServedCustomerInstance = nil,
    LastCustomerLeaving = false,
    DoneClickPos = nil,
    DoneButton = nil,
    TotalServed = 0,
    TotalEarned = 0,
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
-- INTERFAȚĂ GRAFICĂ COMPACTĂ ȘI MODERNĂ (280 x 340 px)
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

-- Fereastră principală compactă
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 280, 0, 340)
Frame.Position = UDim2.new(0.03, 0, 0.22, 0)
Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(45, 45, 60)
FrameStroke.Thickness = 1
FrameStroke.Parent = Frame

-- Bară de titlu (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
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
TitleText.Text = "✂️ Stylez Hair Studio"
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
Body.Size = UDim2.new(1, -16, 1, -44)
Body.Position = UDim2.new(0, 8, 0, 40)
Body.BackgroundTransparency = 1
Body.Parent = Frame

-- Card de Info Live pentru Post & Client
local InfoCard = Instance.new("Frame")
InfoCard.Size = UDim2.new(1, 0, 0, 94)
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
RowStatus.Size = UDim2.new(1, -12, 0, 24)
RowStatus.Position = UDim2.new(0, 8, 0, 66)
RowStatus.BackgroundTransparency = 1
RowStatus.Text = "⚡ Stare: Gata de lucru (Stai la un scaun)"
RowStatus.TextColor3 = Color3.fromRGB(140, 240, 160)
RowStatus.Font = Enum.Font.Gotham
RowStatus.TextSize = 9
RowStatus.TextWrapped = true
RowStatus.TextXAlignment = Enum.TextXAlignment.Left
RowStatus.Parent = InfoCard

-- Buton Principal START / PAUZĂ
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 32)
ToggleBtn.Position = UDim2.new(0, 0, 0, 100)
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

-- Butoane Acțiuni Rapide
local AlignBtn = Instance.new("TextButton")
AlignBtn.Size = UDim2.new(0.48, 0, 0, 28)
AlignBtn.Position = UDim2.new(0, 0, 0, 136)
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

local DoneBtn = Instance.new("TextButton")
DoneBtn.Size = UDim2.new(0.48, 0, 0, 28)
DoneBtn.Position = UDim2.new(0.52, 0, 0, 136)
DoneBtn.BackgroundColor3 = Color3.fromRGB(28, 55, 36)
DoneBtn.Text = "✂️ Click DONE Acum"
DoneBtn.TextColor3 = Color3.fromRGB(130, 250, 170)
DoneBtn.Font = Enum.Font.GothamBold
DoneBtn.TextSize = 9
DoneBtn.BorderSizePixel = 0
DoneBtn.Parent = Body

local DoneCorner = Instance.new("UICorner")
DoneCorner.CornerRadius = UDim.new(0, 6)
DoneCorner.Parent = DoneBtn

-- Rând Butoane Săgeți pentru Schimbat Rapid Stil & Culoare
local ArrowRow = Instance.new("Frame")
ArrowRow.Size = UDim2.new(1, 0, 0, 28)
ArrowRow.Position = UDim2.new(0, 0, 0, 168)
ArrowRow.BackgroundTransparency = 1
ArrowRow.Parent = Body

local StylePrevBtn = Instance.new("TextButton")
StylePrevBtn.Size = UDim2.new(0.23, 0, 1, 0)
StylePrevBtn.Position = UDim2.new(0, 0, 0, 0)
StylePrevBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StylePrevBtn.Text = "◀ Stil"
StylePrevBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
StylePrevBtn.Font = Enum.Font.GothamMedium
StylePrevBtn.TextSize = 9
StylePrevBtn.BorderSizePixel = 0
StylePrevBtn.Parent = ArrowRow

local SPCorner = Instance.new("UICorner")
SPCorner.CornerRadius = UDim.new(0, 4)
SPCorner.Parent = StylePrevBtn

local StyleNextBtn = Instance.new("TextButton")
StyleNextBtn.Size = UDim2.new(0.23, 0, 1, 0)
StyleNextBtn.Position = UDim2.new(0.25, 0, 0, 0)
StyleNextBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StyleNextBtn.Text = "Stil ▶"
StyleNextBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
StyleNextBtn.Font = Enum.Font.GothamMedium
StyleNextBtn.TextSize = 9
StyleNextBtn.BorderSizePixel = 0
StyleNextBtn.Parent = ArrowRow

local SNCorner = Instance.new("UICorner")
SNCorner.CornerRadius = UDim.new(0, 4)
SNCorner.Parent = StyleNextBtn

local ColorPrevBtn = Instance.new("TextButton")
ColorPrevBtn.Size = UDim2.new(0.23, 0, 1, 0)
ColorPrevBtn.Position = UDim2.new(0.52, 0, 0, 0)
ColorPrevBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ColorPrevBtn.Text = "◀ Culoare"
ColorPrevBtn.TextColor3 = Color3.fromRGB(255, 210, 170)
ColorPrevBtn.Font = Enum.Font.GothamMedium
ColorPrevBtn.TextSize = 8
ColorPrevBtn.BorderSizePixel = 0
ColorPrevBtn.Parent = ArrowRow

local CPCorner = Instance.new("UICorner")
CPCorner.CornerRadius = UDim.new(0, 4)
CPCorner.Parent = ColorPrevBtn

local ColorNextBtn = Instance.new("TextButton")
ColorNextBtn.Size = UDim2.new(0.23, 0, 1, 0)
ColorNextBtn.Position = UDim2.new(0.77, 0, 0, 0)
ColorNextBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ColorNextBtn.Text = "Culoare ▶"
ColorNextBtn.TextColor3 = Color3.fromRGB(255, 210, 170)
ColorNextBtn.Font = Enum.Font.GothamMedium
ColorNextBtn.TextSize = 8
ColorNextBtn.BorderSizePixel = 0
ColorNextBtn.Parent = ArrowRow

local CNCorner = Instance.new("UICorner")
CNCorner.CornerRadius = UDim.new(0, 4)
CNCorner.Parent = ColorNextBtn

-- Slider Viteză Servire
local SliderBox = Instance.new("Frame")
SliderBox.Size = UDim2.new(1, 0, 0, 36)
SliderBox.Position = UDim2.new(0, 0, 0, 200)
SliderBox.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
SliderBox.BorderSizePixel = 0
SliderBox.Parent = Body

local SliderBoxCorner = Instance.new("UICorner")
SliderBoxCorner.CornerRadius = UDim.new(0, 6)
SliderBoxCorner.Parent = SliderBox

local SliderText = Instance.new("TextLabel")
SliderText.Size = UDim2.new(0.7, 0, 0, 16)
SliderText.Position = UDim2.new(0, 8, 0, 2)
SliderText.BackgroundTransparency = 1
SliderText.Text = "⏱️ Viteză Servire (Delay)"
SliderText.TextColor3 = Color3.fromRGB(180, 180, 190)
SliderText.Font = Enum.Font.GothamMedium
SliderText.TextSize = 9
SliderText.TextXAlignment = Enum.TextXAlignment.Left
SliderText.Parent = SliderBox

local SliderValText = Instance.new("TextLabel")
SliderValText.Size = UDim2.new(0.25, 0, 0, 16)
SliderValText.Position = UDim2.new(0.72, 0, 0, 2)
SliderValText.BackgroundTransparency = 1
SliderValText.Text = "0.8s"
SliderValText.TextColor3 = Color3.fromRGB(120, 220, 160)
SliderValText.Font = Enum.Font.GothamBold
SliderValText.TextSize = 9
SliderValText.TextXAlignment = Enum.TextXAlignment.Right
SliderValText.Parent = SliderBox

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -16, 0, 6)
SliderTrack.Position = UDim2.new(0, 8, 0, 22)
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

-- Slider Drag
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
StatsPill.Size = UDim2.new(1, 0, 0, 26)
StatsPill.Position = UDim2.new(0, 0, 0, 240)
StatsPill.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
StatsPill.BorderSizePixel = 0
StatsPill.Parent = Body

local StatsPillCorner = Instance.new("UICorner")
StatsPillCorner.CornerRadius = UDim.new(0, 6)
StatsPillCorner.Parent = StatsPill

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, 0, 1, 0)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Total Serviți: 0   |   Bani Estimați: $0"
StatsText.TextColor3 = Color3.fromRGB(160, 220, 180)
StatsText.Font = Enum.Font.GothamMedium
StatsText.TextSize = 9
StatsText.Parent = StatsPill

-- =========================================================================
-- MOTOR DE SCANARE POST DE LUCRU CU PERSISTENȚĂ (HYSTERESIS)
-- =========================================================================

local function getAllWorkstations()
    local list = {}
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

-- Returnează postul curent, menținându-l stabil (evită săritul la alte scaune)
local function getMyStation()
    local char = LocalPlayer.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    -- 1. Verifică dacă postul actual este încă în rază (< 14 studs)
    if State.CurrentStation and State.CurrentStation.Parent then
        local stPart = State.CurrentStation:FindFirstChild("Chair") or State.CurrentStation:FindFirstChild("Seat") or State.CurrentStation.PrimaryPart or State.CurrentStation:FindFirstChildWhichIsA("BasePart")
        if stPart then
            local d = (stPart.Position - hrp.Position).Magnitude
            if d < 14 then
                return State.CurrentStation, d
            end
        end
    end

    -- 2. Căutare post cel mai apropiat
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

    if nearest and minDist < 14 then
        State.CurrentStation = nearest
        return nearest, minDist
    end

    return nil, minDist
end

-- Asigură pontarea la job
local function ensureJobClockIn()
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

-- Poziționare laterală în First Person
local function alignToStation(station)
    if not station then station = getMyStation() end
    if not station then return false end

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return false end

    ensureJobClockIn()

    -- Poziționare laterală (RightVector * 2.2) privind spre scaun/oglindă
    local sidePos = chair.Position + (chair.CFrame.RightVector * 2.2) + (chair.CFrame.LookVector * 0.3) + Vector3.new(0, 0.5, 0)
    local targetPos = chair.Position + Vector3.new(0, 1.2, 0)
    hrp.CFrame = CFrame.new(sidePos, targetPos)

    pcall(function()
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
    end)

    return true
end

-- =========================================================================
-- DETECȚIE CLIENT STRICT PE PLANUL ORIZONTAL AL SCAUNULUI (XZ < 3.0 studs)
-- =========================================================================

local function getAllPotentialCharacters(station)
    local list = {}
    local seen = {}

    local function addModel(m)
        if m and m:IsA("Model") and m ~= LocalPlayer.Character and not seen[m] then
            seen[m] = true
            table.insert(list, m)
        end
    end

    -- 1. Verifică toate folderele SpawnedCharacters din Workspace
    pcall(function()
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "SpawnedCharacters" or desc.Name == "Characters" or desc.Name == "NPCs" then
                for _, child in ipairs(desc:GetChildren()) do
                    addModel(child)
                end
            end
        end
    end)

    -- 2. Copiii din stația de lucru
    if station then
        for _, child in ipairs(station:GetChildren()) do
            addModel(child)
        end
    end

    -- 3. Copiii direcți Workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        addModel(obj)
    end

    return list
end

local function getCustomerInChair(station)
    if not station then return nil, nil, nil end
    local chair = station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return nil, nil, nil end

    local bestCustomer = nil
    local bestStyle = nil
    local bestColor = nil
    local minHorizDist = 3.0 -- Limită orizontală strictă (exclude scaunele vecine la 7+ studs)

    local chairPos = chair.Position
    local candidates = getAllPotentialCharacters(station)

    for _, model in ipairs(candidates) do
        local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
        if root then
            local rootPos = root.Position
            -- Distanță 2D pe planul XZ (ignoră diferențele de înălțime ale avatarului)
            local dx = rootPos.X - chairPos.X
            local dz = rootPos.Z - chairPos.Z
            local horizDist = math.sqrt((dx * dx) + (dz * dz))
            local vertDist = math.abs(rootPos.Y - chairPos.Y)

            -- Orice client așezat pe scaun are horizDist < 3.0 și vertDist < 5.0
            if horizDist < minHorizDist and vertDist < 5.0 then
                -- Caută folderul Order
                local order = model:FindFirstChild("Order") or model:FindFirstChildWhichIsA("Configuration") or model:FindFirstChild("ClientOrder")
                if not order then
                    for _, child in ipairs(model:GetChildren()) do
                        if child.Name:lower():find("order") then
                            order = child
                            break
                        end
                    end
                end

                if order then
                    local sObj = order:FindFirstChild("Style") or order:FindFirstChild("HairStyle") or order:FindFirstChild("Hair")
                    local cObj = order:FindFirstChild("Color") or order:FindFirstChild("HairColor")
                    if sObj and cObj then
                        minHorizDist = horizDist
                        bestCustomer = model
                        bestStyle = sObj.Value
                        bestColor = cObj.Value
                    end
                end
            end
        end
    end

    return bestCustomer, bestStyle, bestColor
end

-- =========================================================================
-- MOTOR DE BUTOANE (SURFACEGUI PE OGLINDĂ & PLAYERGUI)
-- =========================================================================

local function scanHairButtons(station)
    local result = {
        Done = nil,
        StylePrev = nil,
        StyleNext = nil,
        ColorPrev = nil,
        ColorNext = nil,
        AllButtons = {}
    }

    local sources = {}
    if station then table.insert(sources, station) end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then table.insert(sources, pg) end

    for _, root in ipairs(sources) do
        for _, btn in ipairs(root:GetDescendants()) do
            if btn:IsA("GuiButton") and not btn:IsDescendantOf(ScreenGui) then
                table.insert(result.AllButtons, btn)

                local name = btn.Name:lower()
                local text = (btn:IsA("TextButton") and btn.Text:lower()) or ""
                for _, c in ipairs(btn:GetChildren()) do
                    if c:IsA("TextLabel") and c.Text then text = text .. " " .. c.Text:lower() end
                end

                -- Buton Done
                local isDone = name:find("done") or text:find("done") or
                               name:find("finish") or text:find("finish") or
                               name:find("confirm") or text:find("confirm") or
                               name:find("cut") or text:find("gata") or
                               name:find("submit") or name:find("ok")

                if not isDone and btn.BackgroundColor3 then
                    local col = btn.BackgroundColor3
                    if col.G > 0.55 and col.G > (col.R * 1.3) and not (name:find("arrow") or text:find("<") or text:find(">")) then
                        isDone = true
                    end
                end

                if isDone and not result.Done then
                    result.Done = btn
                end

                -- Săgeți Stil
                if name:find("style") or (btn.Parent and btn.Parent.Name:lower():find("style")) then
                    if name:find("left") or name:find("prev") or text:find("<") or text:find("◀") then
                        result.StylePrev = btn
                    elseif name:find("right") or name:find("next") or text:find(">") or text:find("▶") then
                        result.StyleNext = btn
                    end
                end

                -- Săgeți Culoare
                if name:find("color") or (btn.Parent and btn.Parent.Name:lower():find("color")) then
                    if name:find("left") or name:find("prev") or text:find("<") or text:find("◀") then
                        result.ColorPrev = btn
                    elseif name:find("right") or name:find("next") or text:find(">") or text:find("▶") then
                        result.ColorNext = btn
                    end
                end
            end
        end
    end

    -- Fallback dacă butonul Done nu are nume specific
    if not result.Done and #result.AllButtons > 0 then
        for _, btn in ipairs(result.AllButtons) do
            local bn = btn.Name:lower()
            if not (bn:find("arrow") or bn:find("left") or bn:find("right") or bn:find("<") or bn:find(">")) then
                result.Done = btn
                break
            end
        end
    end

    return result
end

-- Declanșează click sigur pe un buton GUI
local function clickButton(btn)
    if not btn then return false end
    local clicked = false

    pcall(function()
        if firesignal then
            if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) clicked = true end
            if btn.Activated then firesignal(btn.Activated) clicked = true end
            if btn.MouseButton1Down then
                firesignal(btn.MouseButton1Down)
                task.wait(0.02)
                firesignal(btn.MouseButton1Up)
                clicked = true
            end
        end
    end)

    pcall(function()
        if VirtualInputManager and btn.AbsolutePosition and btn.AbsoluteSize then
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            if pos.X > 0 and pos.Y > 0 then
                VirtualInputManager:SendMouseMoveEvent(pos.X, pos.Y, game)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.03)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                clicked = true
            end
        end
    end)

    return clicked
end

-- Ascultător GLOBAL de click: Reține coordonata exactă când dai click manual pe Done!
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local x = input.Position.X
        local y = input.Position.Y

        -- Ignoră click-ul pe propria noastră fereastră UI
        if Frame and Frame.Visible then
            local p = Frame.AbsolutePosition
            local s = Frame.AbsoluteSize
            if x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y then
                return
            end
        end

        -- Salvează coordonata de click pentru DONE
        State.DoneClickPos = Vector2.new(x, y)
        RowStatus.Text = string.format("🎯 DONE salvat la ecran: (%d, %d)! Preiau complet...", math.floor(x), math.floor(y))
        RowStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
        print(string.format("[Stylez] Coordonate Done salvate: X=%d, Y=%d", math.floor(x), math.floor(y)))
    end
end)

-- Trimitere payload de rețea JobCompleted (Strat backup)
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

-- Executare completă DONE
local function executeDone(station, styleVal, colorVal)
    local buttons = scanHairButtons(station)

    -- 1. Click pe butonul Done găsit pe SurfaceGui sau PlayerGui
    if buttons.Done then
        clickButton(buttons.Done)
    end

    -- 2. Click pe coordonatele înregistrate sau poziția butonului
    local clickPos = State.DoneClickPos
    if not clickPos and buttons.Done and buttons.Done.AbsolutePosition then
        clickPos = buttons.Done.AbsolutePosition + (buttons.Done.AbsoluteSize / 2)
    end

    if clickPos then
        local x = math.floor(clickPos.X)
        local y = math.floor(clickPos.Y)
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
        pcall(function()
            if mouse1click then mouse1click() end
        end)
    end

    -- 3. Rețea JobCompleted ca backup
    fireJobCompletedRemote(station, styleVal, colorVal)
end

-- =========================================================================
-- BUCALĂ PRINCIPALĂ DE AUTOMATIZARE (DETECTEAZĂ FIECARE CLIENT CONSECUTIV)
-- =========================================================================

local isWorkingLoop = false
local function loopStep()
    if not Config.Active or isWorkingLoop then return end
    isWorkingLoop = true

    -- Garantare eliberare lock la final
    local function finishStep()
        isWorkingLoop = false
    end

    -- 1. Verifică postul de lucru al jucătorului
    local station, dist = getMyStation()

    if not station or dist > 14 then
        RowStation.Text = "📍 Post: Mergi lângă un scaun din salon..."
        RowStation.TextColor3 = Color3.fromRGB(255, 180, 100)
        RowStatus.Text = "⚡ Stare: Aștept să te așezi lângă un scaun"
        RowStatus.TextColor3 = Color3.fromRGB(200, 200, 210)
        finishStep()
        return
    end

    RowStation.Text = string.format("📍 Post: %s (la %d studs)", station.Name, math.floor(dist))
    RowStation.TextColor3 = Color3.fromRGB(120, 220, 160)

    -- 2. Detectează STRICT clientul de la acest scaun (XZ < 3.0 studs)
    local customer, styleVal, colorVal = getCustomerInChair(station)

    if customer and styleVal ~= nil and colorVal ~= nil then
        State.CurrentCustomer = customer
        RowClient.Text = "👤 Client: " .. customer.Name
        RowOrder.Text = string.format("💇 Stil: #%s   |   🎨 Culoare: #%s", tostring(styleVal), tostring(colorVal))

        -- Verifică dacă acest client este nou (nu a fost încă servit)
        if customer ~= State.LastServedCustomerInstance then
            RowStatus.Text = "⚡ Client nou la scaun! Servesc..."
            RowStatus.TextColor3 = Color3.fromRGB(100, 220, 255)

            -- Așteaptă delay-ul setat
            task.wait(math.clamp(Config.Delay or 0.8, 0.2, 2.5))

            -- Execută acțiunea de DONE
            executeDone(station, styleVal, colorVal)
            task.wait(0.15)
            executeDone(station, styleVal, colorVal)

            -- Marchează clientul ca servit
            State.LastServedCustomerInstance = customer
            State.TotalServed = State.TotalServed + 1
            State.TotalEarned = State.TotalServed * 75

            RowStatus.Text = "🎉 DONE trimis! Aștept ca clientul să plece..."
            RowStatus.TextColor3 = Color3.fromRGB(120, 255, 150)
            StatsText.Text = string.format("Total Serviți: %d   |   Bani Estimați: $%d", State.TotalServed, State.TotalEarned)

            task.wait(0.4)
        else
            RowStatus.Text = "⏳ Aștept ca clientul servit să se ridice..."
            RowStatus.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
    else
        -- Scaunul este gol (Clientul precedent a plecat sau încă vine)
        State.CurrentCustomer = nil
        RowClient.Text = "👤 Client: Aștept următorul client..."
        RowOrder.Text = "💇 Stil: -   |   🎨 Culoare: -"
        RowStatus.Text = "⚡ Stare: Scaun liber, vine următorul client..."
        RowStatus.TextColor3 = Color3.fromRGB(180, 180, 190)

        -- Resetează instanța pentru a detecta instant CLIENTUL URMĂTOR!
        State.LastServedCustomerInstance = nil
    end

    finishStep()
end

-- Buclă de rulare continuă
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

-- Toggle Activ / Pauză
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Active = not Config.Active

    if Config.Active then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 75)
        ToggleBtn.Text = "🟢 ACTIVAT (Click pentru Pauză)"
        Badge.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
        BadgeLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
        BadgeLabel.Text = "ACTIV"
        RowStatus.Text = "⚡ Stare: Auto Hairdresser activat!"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
        ToggleBtn.Text = "🔴 OPRIT (Click pentru Activare)"
        Badge.BackgroundColor3 = Color3.fromRGB(50, 25, 30)
        BadgeLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        BadgeLabel.Text = "PAUZĂ"
        RowStatus.Text = "⚡ Stare: Pus pe pauză"

        pcall(function()
            LocalPlayer.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 128
        end)
    end
end)

-- Buton Ajustare Laterală la Scaun
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
    local st = State.CurrentStation or getMyStation()
    local s, c = 1, 1
    if State.CurrentCustomer then
        local order = State.CurrentCustomer:FindFirstChild("Order")
        if order then
            local sObj = order:FindFirstChild("Style")
            local cObj = order:FindFirstChild("Color")
            if sObj then s = sObj.Value end
            if cObj then c = cObj.Value end
        end
    end
    executeDone(st, s, c)
    RowStatus.Text = "⚡ Click Done trimis manual! ✂️"
end)

-- Butoane Săgeți pentru Schimbare Manuală pe Oglindă
StylePrevBtn.MouseButton1Click:Connect(function()
    local btns = scanHairButtons(State.CurrentStation)
    if btns.StylePrev then clickButton(btns.StylePrev) end
end)
StyleNextBtn.MouseButton1Click:Connect(function()
    local btns = scanHairButtons(State.CurrentStation)
    if btns.StyleNext then clickButton(btns.StyleNext) end
end)
ColorPrevBtn.MouseButton1Click:Connect(function()
    local btns = scanHairButtons(State.CurrentStation)
    if btns.ColorPrev then clickButton(btns.ColorPrev) end
end)
ColorNextBtn.MouseButton1Click:Connect(function()
    local btns = scanHairButtons(State.CurrentStation)
    if btns.ColorNext then clickButton(btns.ColorNext) end
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

print("[Stylez Hairdresser] Script încărcat cu succes! Detecție continuă activă. ✂️")
