--[[
    =========================================================================
    PULLZ PRO (ROBLOX) - WELCOME TO BLOXBURG AUTOMATION SUITE
    =========================================================================
    Signature PullZ UI Suite | High-Performance Obsidian Theme
    Categorized Features:
    - 💼 AUTO JOBS & FARMING:
        * Pizza Delivery Assist (Delivery route navigation & speed)
        * Pizza Baker Automation (Auto dough, toppings, oven)
        * Hairdresser / Stylez Station (Auto hair selection)
        * Blox Burger Cashier (Instant order taking)
        * Clean & Restock Janitor (Auto stain & garbage clear)
        * Anti-Faint Protection (Prevents collapsing on zero energy)
        * Job Action Delay Slider
    - 🏠 HOUSE & PLOT:
        * Auto-Pay Bills (Electricity & water protection)
        * Auto-Water Plants & Gardening
        * Auto-Clean Dirty Dishes & Plot Messes
        * Teleport to My Plot / Town Center
    - ⚡ MOVEMENT:
        * WalkSpeed Multiplier (Slider 16 - 120)
        * Sprint Boost Mode (Hold Shift)
        * Infinite Jump (Continuous Mid-Air Air-Hop)
        * Universal Noclip (Walk through walls & locked doors)
        * Smooth Flight Mode (E/Q altitude controls)
    - 👁️ VISUALS & WORLD:
        * Fullbright Lighting Engine (Boost ambient & remove fog)
        * Lock Daytime (ClockTime 14:00)
        * Player ESP & Highlight Shader
        * Plot Owner Tags
    - ⚙️ SETTINGS:
        * Live FPS & Network Ping HUD Pill
        * Window Minimize & Collapse Mode
        * Keybind Toggle (Default: Insert or on-screen button)
        * Instant Clean Hub Self-Destruct / Unload
    =========================================================================
--]]

-- Clean up any prior running instance
if getgenv().PullZBloxburgLoaded then
    pcall(function()
        if getgenv().PullZBloxburgUnload then getgenv().PullZBloxburgUnload() end
    end)
end
getgenv().PullZBloxburgLoaded = true

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat
        task.wait(0.05)
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera", 5)
local Mouse = nil
pcall(function() Mouse = LocalPlayer:GetMouse() end)

-- Configuration Store
local Config = {
    -- Auto Jobs & Work
    AutoDelivery = false,
    DeliverySpeed = 22,
    MopedBoost = false,
    MopedSpeed = 38,
    AutoBaker = false,
    AutoHairdresser = false,
    AutoCashier = false,
    AutoJanitor = false,
    AntiFaint = false,
    WorkDelay = 0.5,

    -- House & Plot
    AutoPayBills = false,
    AutoWaterPlants = false,
    AutoCleanPlot = false,

    -- Movement
    SpeedHack = false,
    SpeedMultiplier = 24,
    SprintBoost = false,
    InfiniteJump = false,
    Noclip = false,
    FlyEnabled = false,
    FlySpeed = 30,

    -- World & Visuals
    Fullbright = false,
    ForceDaytime = false,
    PlayerESP = false,
    PlotESP = false,

    -- Settings
    WatermarkEnabled = true
}

-- Runtime State
local State = {
    ScreenGui = nil,
    Connections = {},
    Highlights = {},
    DrawingObjects = {},
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd
    },
    Flying = false,
    FlyBodyVelocity = nil,
    FlyBodyGyro = nil,
    SavedPizzaSpot = nil,
    SavedPizzaCFrame = nil,
    SavedPizzaPrompt = nil,
    SavedMopedSpot = nil,
    SavedMopedSeat = nil,
    SavedConveyorPos = nil,
    LastCustomerSearch = 0,
    CachedCustomer = nil,
    CachedPrompt = nil,
    LearnedCustomerName = nil,
    LearnedCustomerParent = nil,
    LearnedMopedName = nil,
    LearnedArrowName = nil,
    CachedNPCs = nil,
    LastNPCSearch = 0,
    CachedArrowPos = nil,
    CachedArrowObj = nil,
    LastArrowSearch = 0
}

-- ScreenGui Setup (Multi-Executor Compatibility)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PullZ_Bloxburg_" .. tostring(math.random(10000, 99999))
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
        local pg = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui
        ScreenGui.Parent = pg
        if ScreenGui.Parent then attached = true end
    end)
end
if not attached then
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
end

State.ScreenGui = ScreenGui
getgenv().PullZScreenGui = ScreenGui

-- Forward declarations for lexical scoping across closures
local BorderFrame = nil
local Watermark = nil
local MinimizedBtn = nil

-- =========================================================================
-- SIGNATURE PULLZ LOADING SCREEN
-- =========================================================================
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 260, 0, 280)
LoadingFrame.Position = UDim2.new(0.5, -130, 0.5, -140)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15) -- Obsidian Dark
LoadingFrame.BackgroundTransparency = 1
LoadingFrame.ZIndex = 9999
LoadingFrame.Parent = ScreenGui

local LoadingFrameCorner = Instance.new("UICorner")
LoadingFrameCorner.CornerRadius = UDim.new(0, 12)
LoadingFrameCorner.Parent = LoadingFrame

local SpinnerOuter = Instance.new("Frame")
SpinnerOuter.Size = UDim2.new(0, 160, 0, 160)
SpinnerOuter.Position = UDim2.new(0.5, -80, 0.5, -100)
SpinnerOuter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpinnerOuter.BackgroundTransparency = 1
SpinnerOuter.ZIndex = 10000
SpinnerOuter.Parent = LoadingFrame

local OuterCorner = Instance.new("UICorner")
OuterCorner.CornerRadius = UDim.new(1, 0)
OuterCorner.Parent = SpinnerOuter

local SpinnerGradient = Instance.new("UIGradient")
SpinnerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 12, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 15))
})
SpinnerGradient.Rotation = 0
SpinnerGradient.Parent = SpinnerOuter

local SpinnerInner = Instance.new("Frame")
SpinnerInner.Size = UDim2.new(1, -6, 1, -6)
SpinnerInner.Position = UDim2.new(0, 3, 0, 3)
SpinnerInner.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
SpinnerInner.BackgroundTransparency = 1
SpinnerInner.ZIndex = 10001
SpinnerInner.Parent = SpinnerOuter

local InnerCorner = Instance.new("UICorner")
InnerCorner.CornerRadius = UDim.new(1, 0)
InnerCorner.Parent = SpinnerInner

local PercentText = Instance.new("TextLabel")
PercentText.Size = UDim2.new(1, 0, 1, 0)
PercentText.BackgroundTransparency = 1
PercentText.Text = "0%"
PercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
PercentText.Font = Enum.Font.Gotham
PercentText.TextSize = 42
PercentText.TextTransparency = 1
PercentText.ZIndex = 10002
PercentText.Parent = SpinnerInner

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 200, 0, 40)
TitleText.Position = UDim2.new(0.5, -100, 0.5, 90)
TitleText.BackgroundTransparency = 1
TitleText.Text = "PullZ"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextSize = 34
TitleText.TextTransparency = 1
TitleText.ZIndex = 10002
TitleText.Parent = LoadingFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
})
TitleGradient.Rotation = 45
TitleGradient.Parent = TitleText

local SubTitleText = Instance.new("TextLabel")
SubTitleText.Size = UDim2.new(0, 200, 0, 20)
SubTitleText.Position = UDim2.new(0.5, -100, 0.5, 120)
SubTitleText.BackgroundTransparency = 1
SubTitleText.Text = "B L O X B U R G"
SubTitleText.TextColor3 = Color3.fromRGB(100, 150, 255)
SubTitleText.Font = Enum.Font.GothamBold
SubTitleText.TextSize = 13
SubTitleText.TextTransparency = 1
SubTitleText.ZIndex = 10002
SubTitleText.Parent = LoadingFrame

local Shockwave = Instance.new("Frame")
Shockwave.Size = UDim2.new(0, 160, 0, 160)
Shockwave.Position = UDim2.new(0.5, -80, 0.5, -100)
Shockwave.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
Shockwave.BackgroundTransparency = 1
Shockwave.ZIndex = 9999
Shockwave.Parent = LoadingFrame

local ShockwaveCorner = Instance.new("UICorner")
ShockwaveCorner.CornerRadius = UDim.new(1, 0)
ShockwaveCorner.Parent = Shockwave

-- Animate Loading Screen in background (Fail-Safe Non-Blocking)
task.spawn(function()
    local spinnerActive = true
    task.spawn(function()
        while spinnerActive and SpinnerOuter and SpinnerOuter.Parent do
            SpinnerGradient.Rotation = (tick() * 320) % 360
            task.wait()
        end
    end)

    local fadeInInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    pcall(function()
        TweenService:Create(SpinnerOuter, fadeInInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(SpinnerInner, fadeInInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(PercentText, fadeInInfo, {TextTransparency = 0}):Play()
        TweenService:Create(TitleText, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 60)}):Play()
        TweenService:Create(SubTitleText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 95)}):Play()
    end)

    for i = 1, 100 do
        PercentText.Text = i .. "%"
        task.wait(0.008)
    end

    PercentText.Text = "OK"
    task.wait(0.25)

    pcall(function()
        local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        TweenService:Create(SpinnerOuter, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(SpinnerInner, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(PercentText, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(TitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 40)}):Play()
        TweenService:Create(SubTitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 75)}):Play()
        TweenService:Create(Shockwave, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 350), Position = UDim2.new(0.5, -175, 0.5, -175), BackgroundTransparency = 1}):Play()
    end)

    task.wait(0.4)
    spinnerActive = false
    pcall(function() LoadingFrame:Destroy() end)

    if BorderFrame and BorderFrame.Parent then
        BorderFrame.Visible = true
    end
    if Watermark and Watermark.Parent and Config.WatermarkEnabled then
        Watermark.Visible = true
    end
end)

-- =========================================================================
-- HUD & WATERMARK PILL
-- =========================================================================
Watermark = Instance.new("Frame")
Watermark.Name = "WatermarkHUD"
Watermark.Size = UDim2.new(0, 240, 0, 30)
Watermark.Position = UDim2.new(0, 14, 0, 14)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Watermark.BorderSizePixel = 0
Watermark.Visible = false -- Kept hidden until loading screen completes
Watermark.Parent = ScreenGui

local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0, 8)
WatermarkCorner.Parent = Watermark

local WatermarkStroke = Instance.new("UIStroke")
WatermarkStroke.Thickness = 1
WatermarkStroke.Color = Color3.fromRGB(100, 150, 255)
WatermarkStroke.Transparency = 0.4
WatermarkStroke.Parent = Watermark

local WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Size = UDim2.new(1, -12, 1, 0)
WatermarkLabel.Position = UDim2.new(0, 10, 0, 0)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.Text = "⚡ PULLZ | BLOXBURG | 60 FPS"
WatermarkLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
WatermarkLabel.Font = Enum.Font.GothamMedium
WatermarkLabel.TextSize = 11
WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
WatermarkLabel.Parent = Watermark

local frameCount = 0
local lastFpsTime = tick()
table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFpsTime >= 0.5 then
        local fps = math.floor(frameCount / (now - lastFpsTime))
        local ping = 40
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        WatermarkLabel.Text = string.format("⚡ PULLZ | BLOXBURG | %d FPS | %dms", fps, ping)
        frameCount = 0
        lastFpsTime = now
    end
end))

-- =========================================================================
-- SIGNATURE PULLZ MAIN WINDOW & ROTATING BORDER
-- =========================================================================
BorderFrame = Instance.new("Frame")
BorderFrame.Name = "PullZ_Border"
BorderFrame.Size = UDim2.new(0, 684, 0, 484)
BorderFrame.Position = UDim2.new(0.5, -342, 0.5, -242)
BorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BorderFrame.BorderSizePixel = 0
BorderFrame.Visible = false -- Kept hidden until loading screen completes
BorderFrame.Active = true
BorderFrame.Draggable = true
BorderFrame.Parent = ScreenGui

local BorderCorner = Instance.new("UICorner")
BorderCorner.CornerRadius = UDim.new(0, 10)
BorderCorner.Parent = BorderFrame

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255))
})
StrokeGradient.Parent = BorderFrame

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, -4, 1, -4)
MainFrame.Position = UDim2.new(0, 2, 0, 2)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15) -- Obsidian Dark
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = BorderFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Minimized Pill Button
MinimizedBtn = Instance.new("TextButton")
MinimizedBtn.Name = "PullZ_Minimized"
MinimizedBtn.Size = UDim2.new(0, 110, 0, 44)
MinimizedBtn.Position = UDim2.new(0.5, -55, 0, 10)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinimizedBtn.Text = ""
MinimizedBtn.Visible = false
MinimizedBtn.Active = true
MinimizedBtn.Draggable = true
MinimizedBtn.Parent = ScreenGui

local MinContainerCorner = Instance.new("UICorner")
MinContainerCorner.CornerRadius = UDim.new(0, 10)
MinContainerCorner.Parent = MinimizedBtn

local MinContainerGradient = Instance.new("UIGradient")
MinContainerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255))
})
MinContainerGradient.Parent = MinimizedBtn

local MinInner = Instance.new("Frame")
MinInner.Size = UDim2.new(1, -4, 1, -4)
MinInner.Position = UDim2.new(0, 2, 0, 2)
MinInner.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MinInner.BorderSizePixel = 0
MinInner.Parent = MinimizedBtn

local MinInnerCorner = Instance.new("UICorner")
MinInnerCorner.CornerRadius = UDim.new(0, 8)
MinInnerCorner.Parent = MinInner

local MinText = Instance.new("TextLabel")
MinText.Size = UDim2.new(1, 0, 1, 0)
MinText.BackgroundTransparency = 1
MinText.Text = "PullZ"
MinText.TextColor3 = Color3.fromRGB(255, 255, 255)
MinText.Font = Enum.Font.GothamBlack
MinText.TextSize = 20
MinText.Parent = MinInner

local MinTextGradient = Instance.new("UIGradient")
MinTextGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
})
MinTextGradient.Rotation = 45
MinTextGradient.Parent = MinText

-- Border & Minimized Gradient Rotation Loop
task.spawn(function()
    local rot = 0
    while BorderFrame and BorderFrame.Parent do
        rot = (rot + 1) % 360
        if StrokeGradient then StrokeGradient.Rotation = rot end
        if MinContainerGradient then MinContainerGradient.Rotation = rot end
        task.wait(0.02)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, -20, 0, 26)
LogoText.Position = UDim2.new(0, 14, 0, 16)
LogoText.BackgroundTransparency = 1
LogoText.Text = "PullZ Hub"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 20
LogoText.TextXAlignment = Enum.TextXAlignment.Left
LogoText.Parent = Sidebar

local LogoGradient = Instance.new("UIGradient")
LogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
})
LogoGradient.Rotation = 45
LogoGradient.Parent = LogoText

local SubLogoText = Instance.new("TextLabel")
SubLogoText.Size = UDim2.new(1, -20, 0, 14)
SubLogoText.Position = UDim2.new(0, 14, 0, 42)
SubLogoText.BackgroundTransparency = 1
SubLogoText.Text = "BLOXBURG AUTOMATION"
SubLogoText.TextColor3 = Color3.fromRGB(100, 150, 255)
SubLogoText.Font = Enum.Font.GothamBold
SubLogoText.TextSize = 8
SubLogoText.TextXAlignment = Enum.TextXAlignment.Left
SubLogoText.Parent = Sidebar

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(0, 1, 1, 0)
Separator.Position = UDim2.new(0, 160, 0, 0)
Separator.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
Separator.BorderSizePixel = 0
Separator.Parent = MainFrame

local SepGradient = Instance.new("UIGradient")
SepGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
})
SepGradient.Parent = Separator

-- Dedicated Top Action Bar (ZIndex = 500)
local TopActionBar = Instance.new("Frame")
TopActionBar.Name = "TopActionBar"
TopActionBar.Size = UDim2.new(1, -160, 0, 40)
TopActionBar.Position = UDim2.new(0, 160, 0, 0)
TopActionBar.BackgroundTransparency = 1
TopActionBar.ZIndex = 500
TopActionBar.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -36, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = true
CloseBtn.Active = true
CloseBtn.ZIndex = 501
CloseBtn.Parent = TopActionBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -68, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.AutoButtonColor = true
MinimizeBtn.Active = true
MinimizeBtn.ZIndex = 501
MinimizeBtn.Parent = TopActionBar

local MinCorner2 = Instance.new("UICorner")
MinCorner2.CornerRadius = UDim.new(0, 6)
MinCorner2.Parent = MinimizeBtn

local function handleClose()
    pcall(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)
    if getgenv().PullZBloxburgUnload then
        getgenv().PullZBloxburgUnload()
    end
end

CloseBtn.MouseButton1Click:Connect(handleClose)
CloseBtn.MouseButton1Down:Connect(handleClose)
CloseBtn.Activated:Connect(handleClose)

local function handleMinimize()
    BorderFrame.Visible = false
    MinimizedBtn.Visible = true
end

MinimizeBtn.MouseButton1Click:Connect(handleMinimize)
MinimizeBtn.MouseButton1Down:Connect(handleMinimize)
MinimizeBtn.Activated:Connect(handleMinimize)

local dragStart = nil
MinimizedBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
    end
end)

MinimizedBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStart and (input.Position - dragStart).Magnitude < 10 then
            MinimizedBtn.Visible = false
            BorderFrame.Visible = true
        end
    end
end)

local TabList = Instance.new("UIListLayout")
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 5)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Parent = Sidebar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 75)
TabPadding.Parent = Sidebar

-- Content Area (Starts at Y = 44)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -160, 1, -44)
ContentArea.Position = UDim2.new(0, 160, 0, 44)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Tabs = {}
local TabButtons = {}

local function switchTab(tabName)
    for name, frame in pairs(Tabs) do
        frame.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            btn.TextColor3 = Color3.fromRGB(12, 12, 15)
        else
            btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
            btn.TextColor3 = Color3.fromRGB(160, 165, 180)
        end
    end
end

local function createTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 140, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(160, 165, 180)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.AutoButtonColor = false
    button.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -20, 1, -20)
    container.Position = UDim2.new(0, 10, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
    container.Visible = false
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 4)
    pad.Parent = container

    Tabs[name] = container
    TabButtons[name] = button

    button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    return container
end

-- =========================================================================
-- UI COMPONENT FACTORY
-- =========================================================================
local function createHeader(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = string.upper(text)
    label.TextColor3 = Color3.fromRGB(100, 150, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createToggle(parent, name, defaultConfig, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(210, 210, 220)
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 42, 0, 20)
    Button.Position = UDim2.new(1, -55, 0.5, -10)
    Button.BackgroundColor3 = defaultConfig and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 70)
    Button.Text = ""
    Button.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = Button

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = defaultConfig and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = Button

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local state = defaultConfig
    local TS = TweenService
    local TI = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function setState(newState)
        state = newState
        if state then
            TS:Create(Button, TI, {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}):Play()
            TS:Create(Circle, TI, {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TS:Create(Button, TI, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
            TS:Create(Circle, TI, {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        pcall(callback, state)
    end

    Button.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return {
        Frame = Frame,
        Set = setState
    }
end

local function createSlider(parent, name, min, max, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 52)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 0, 20)
    Label.Position = UDim2.new(0, 14, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(210, 210, 220)
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0, 60, 0, 20)
    ValLabel.Position = UDim2.new(1, -74, 0, 8)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(defaultVal)
    ValLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    ValLabel.TextSize = 12
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -28, 0, 6)
    SliderBar.Position = UDim2.new(0, 14, 0, 36)
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    local ratio = math.clamp((defaultVal - min) / (max - min), 0, 1)
    FillBar.Size = UDim2.new(ratio, 0, 1, 0)
    FillBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    FillBar.BorderSizePixel = 0
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local dragging = false
    local function updateFromInput(input)
        local posX = input.Position.X - SliderBar.AbsolutePosition.X
        local r = math.clamp(posX / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * r)
        FillBar.Size = UDim2.new(r, 0, 1, 0)
        ValLabel.Text = tostring(val)
        pcall(callback, val)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    return Frame
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(100, 150, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(36, 44, 62)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 32, 44)}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- =========================================================================
-- CREATE BLOXBURG CATEGORY PAGES
-- =========================================================================
local jobsPage = createTab("💼 Auto Jobs")
local housePage = createTab("🏠 House & Plot")
local movementPage = createTab("⚡ Movement")
local visualsPage = createTab("👁️ Visuals")
local settingsPage = createTab("⚙️ Settings")

-- Forward Declarations for Delivery Engine
local simulatePressE, triggerPrompt, triggerNearbyPrompts, interactWithObject
local getActiveDeliveryCustomer, findNearestMoped, hasPizzaBox, smoothGlideTo, mountMoped, runPizzaDeliveryStep
local isRealPlayer, learnDeliveryRunNow, debugLog

-- ==================== [CATEGORY 1: AUTO JOBS] ====================
createHeader(jobsPage, "🍕 Pizza Delivery Automation")

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 42)
statusCard.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
statusCard.BorderSizePixel = 0
statusCard.Parent = jobsPage

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusCard

local spotStatusLabel = Instance.new("TextLabel")
spotStatusLabel.Size = UDim2.new(1, -20, 1, 0)
spotStatusLabel.Position = UDim2.new(0, 12, 0, 0)
spotStatusLabel.BackgroundTransparency = 1
spotStatusLabel.Text = "📍 Loc Cutie: NESETAT (Du-te la bandă și apasă Pasul 1)"
spotStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
spotStatusLabel.Font = Enum.Font.GothamMedium
spotStatusLabel.TextSize = 11
spotStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
spotStatusLabel.Parent = statusCard

-- Live Debug Logger (Outputs to F9 Console + In-Game Status UI)
debugLog = function(tag, message, color)
    local timeStr = os.date("%H:%M:%S")
    local line = string.format("[PullZ Bloxburg][%s][%s] %s", timeStr, tag, message)
    print(line)
    if spotStatusLabel then
        pcall(function()
            spotStatusLabel.Text = string.format("[%s] %s", tag, message)
            if color then
                spotStatusLabel.TextColor3 = color
            else
                spotStatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            end
        end)
    end
end

-- Button: Open Developer Console (F9)
createButton(jobsPage, "📜 Deschide Consola F9 (Live Debugger)", function()
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("DevConsoleVisible", true)
    end)
    debugLog("DEBUGGER", "Consola F9 deschisă! Urmărește aici fiecare pas în timp real. 🚀", Color3.fromRGB(100, 255, 150))
end)

-- PASUL 1: Setează Poziția Cutii Pizza
createButton(jobsPage, "📍 PASUL 1: Setează Poziția Cutii Pizza (Unde ești acum)", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        State.SavedPizzaSpot = hrp.Position
        State.SavedPizzaCFrame = hrp.CFrame
        State.SavedConveyorPos = hrp.Position
        State.SavedPizzaPrompt = nil

        -- Instant local check without scanning whole workspace
        pcall(function()
            local nearby = Workspace:GetPartBoundsInRadius(hrp.Position, 16)
            for _, part in ipairs(nearby) do
                for _, p in ipairs(part:GetChildren()) do
                    if p:IsA("ProximityPrompt") then
                        State.SavedPizzaPrompt = p
                        break
                    end
                end
                if State.SavedPizzaPrompt then break end
            end
        end)

        spotStatusLabel.Text = string.format("📍 Loc Cutie: SALVAT ✅ (X: %d, Y: %d, Z: %d)", math.floor(hrp.Position.X), math.floor(hrp.Position.Y), math.floor(hrp.Position.Z))
        spotStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        pcall(function()
            local msg = Instance.new("Message", Workspace)
            msg.Text = "✅ Locatia cutiilor a fost salvata! Acum poti apasa Start."
            task.delay(2.5, function() msg:Destroy() end)
        end)
    end
end)

-- PASUL 2: Setează Poziția Moped (Opțional)
createButton(jobsPage, "🛵 PASUL 2: Setează Poziția Moped (Lângă moped)", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then
        State.SavedMopedSpot = hrp.Position
        State.SavedMopedSeat = nil

        if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
            State.SavedMopedSeat = hum.SeatPart
        else
            pcall(function()
                local nearby = Workspace:GetPartBoundsInRadius(hrp.Position, 30)
                for _, part in ipairs(nearby) do
                    if part:IsA("VehicleSeat") then
                        State.SavedMopedSeat = part
                        break
                    end
                end
            end)
        end

        spotStatusLabel.Text = string.format("🛵 Moped: SALVAT ✅ (X: %d, Y: %d, Z: %d)", math.floor(hrp.Position.X), math.floor(hrp.Position.Y), math.floor(hrp.Position.Z))
        spotStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)

        pcall(function()
            local msg = Instance.new("Message", Workspace)
            msg.Text = "🛵 Locatia mopedului a fost salvata!"
            task.delay(2, function() msg:Destroy() end)
        end)
    end
end)

-- PASUL 2.5: Învață Cursa (Apasă când ai pizza în mână sau ești lângă client)
createButton(jobsPage, "🎯 PASUL 2.5: Învață Cursa (Apasă când ai pizza / la client)", function()
    local ok, msg = false, "Necunoscut"
    if learnDeliveryRunNow then
        ok, msg = learnDeliveryRunNow()
    end
    if ok then
        spotStatusLabel.Text = "🎉 " .. tostring(msg)
        spotStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        pcall(function()
            local m = Instance.new("Message", Workspace)
            m.Text = "✅ " .. tostring(msg) .. "\nAcum poți porni PASUL 3: Start Auto Delivery!"
            task.delay(3, function() m:Destroy() end)
        end)
    else
        spotStatusLabel.Text = "⚠️ " .. tostring(msg)
        spotStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
    end
end)

createButton(jobsPage, "🔄 Resetează Cursa Învățată (Curăță Cache)", function()
    State.LearnedCustomerName = nil
    State.LearnedCustomerParent = nil
    State.CachedCustomer = nil
    State.CachedPrompt = nil
    spotStatusLabel.Text = "🔄 Cache resetat! Poți învăța o nouă cursă."
    spotStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

-- PASUL 3: Start Auto Pizza Delivery Worker
createToggle(jobsPage, "▶️ PASUL 3: Start Auto Pizza Delivery", Config.AutoDelivery, function(s)
    Config.AutoDelivery = s
    if s and not State.SavedPizzaSpot then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            State.SavedPizzaSpot = hrp.Position
            State.SavedConveyorPos = hrp.Position
            spotStatusLabel.Text = string.format("📍 Loc Cutie: SALVAT Automat ✅ (X: %d, Z: %d)", math.floor(hrp.Position.X), math.floor(hrp.Position.Z))
            spotStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        end
    end
end)

createToggle(jobsPage, "Delivery Moped Turbo (Safe 38 MPH)", Config.MopedBoost, function(s)
    Config.MopedBoost = s
end)

createSlider(jobsPage, "Delivery Safe Speed", 16, 42, Config.DeliverySpeed, function(val)
    Config.DeliverySpeed = math.clamp(val, 16, 38)
end)

createButton(jobsPage, "Teleport to Saved Pizza Spot", function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and State.SavedPizzaSpot then
            hrp.CFrame = CFrame.new(State.SavedPizzaSpot + Vector3.new(0, 2.5, 0))
        end
    end)
end)

createButton(jobsPage, "Teleport to Active Customer (Deliver)", function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local customer, prompt = getActiveDeliveryCustomer()
        if hrp and customer then
            local custHrp = customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head") or customer.PrimaryPart or (customer:IsA("BasePart") and customer)
            local custPos = custHrp and custHrp.Position
            if custPos and custPos.Y > 5 then
                local deliverPos = custPos + Vector3.new(0, 1.5, 0)
                if custHrp:IsA("BasePart") then
                    deliverPos = custPos + (custHrp.CFrame.LookVector * 3.5) + Vector3.new(0, 1.5, 0)
                end
                hrp.CFrame = CFrame.new(deliverPos)
                task.wait(0.2)
                simulatePressE(0.4)
                if prompt then
                    triggerPrompt(prompt)
                end
                triggerNearbyPrompts(custPos, 10)
                simulatePressE(0.2)
                State.HasPizza = false
                State.CachedCustomer = nil
                spotStatusLabel.Text = "✅ Teleportat & Livrat la client!"
                spotStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
            end
        else
            spotStatusLabel.Text = "⚠️ Niciun client găsit (ia mai întâi o pizza de la bandă)"
            spotStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
        end
    end)
end)

createHeader(jobsPage, "Other Jobs & Automations")

createToggle(jobsPage, "Auto Pizza Baker (Dough & Oven)", Config.AutoBaker, function(s)
    Config.AutoBaker = s
end)

createToggle(jobsPage, "Auto Hairdresser / Stylez Station", Config.AutoHairdresser, function(s)
    Config.AutoHairdresser = s
end)

createToggle(jobsPage, "Auto Blox Burger Cashier", Config.AutoCashier, function(s)
    Config.AutoCashier = s
end)

createToggle(jobsPage, "Auto Janitor (Clean & Trash)", Config.AutoJanitor, function(s)
    Config.AutoJanitor = s
end)

createHeader(jobsPage, "Work Safety & Protections")

createToggle(jobsPage, "Anti-Faint (Zero Energy Shield)", Config.AntiFaint, function(s)
    Config.AntiFaint = s
end)

createSlider(jobsPage, "Work Action Delay (Seconds)", 0.1, 2.0, Config.WorkDelay, function(val)
    Config.WorkDelay = val
end)

-- ==================== [CATEGORY 2: HOUSE & PLOT] ====================
createHeader(housePage, "Plot Management")

createToggle(housePage, "Auto Pay Bills", Config.AutoPayBills, function(s)
    Config.AutoPayBills = s
end)

createToggle(housePage, "Auto Water Plants & Garden", Config.AutoWaterPlants, function(s)
    Config.AutoWaterPlants = s
end)

createToggle(housePage, "Auto Clean Plot & Dirty Dishes", Config.AutoCleanPlot, function(s)
    Config.AutoCleanPlot = s
end)

createHeader(housePage, "Quick Navigation")

createButton(housePage, "Teleport to My Plot", function()
    pcall(function()
        local plots = Workspace:FindFirstChild("Plots")
        if plots and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, plot in pairs(plots:GetChildren()) do
                local owner = plot:FindFirstChild("Owner")
                if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0)
                    return
                end
            end
        end
    end)
end)

createButton(housePage, "Teleport to Town Center", function()
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 15, 0)
        end
    end)
end)

-- ==================== [CATEGORY 3: MOVEMENT] ====================
createHeader(movementPage, "Speed & Agility")

createToggle(movementPage, "Speed Booster", Config.SpeedHack, function(s)
    Config.SpeedHack = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

createSlider(movementPage, "Speed Multiplier", 16, 120, Config.SpeedMultiplier, function(val)
    Config.SpeedMultiplier = val
end)

createToggle(movementPage, "Sprint Boost (Hold Shift)", Config.SprintBoost, function(s)
    Config.SprintBoost = s
end)

createToggle(movementPage, "Infinite Mid-Air Jump", Config.InfiniteJump, function(s)
    Config.InfiniteJump = s
end)

createToggle(movementPage, "Universal Noclip (Walk Through Walls)", Config.Noclip, function(s)
    Config.Noclip = s
end)

createHeader(movementPage, "Flight Mode")

createToggle(movementPage, "Flight Mode (E / Q Altitude)", Config.FlyEnabled, function(s)
    Config.FlyEnabled = s
    if not s then
        if State.FlyBodyVelocity then State.FlyBodyVelocity:Destroy() State.FlyBodyVelocity = nil end
        if State.FlyBodyGyro then State.FlyBodyGyro:Destroy() State.FlyBodyGyro = nil end
    end
end)

createSlider(movementPage, "Flight Speed", 15, 100, Config.FlySpeed, function(val)
    Config.FlySpeed = val
end)

-- ==================== [CATEGORY 4: VISUALS & WORLD] ====================
createHeader(visualsPage, "Lighting & Ambiance")

createToggle(visualsPage, "Fullbright (Enhanced Interior Vision)", Config.Fullbright, function(s)
    Config.Fullbright = s
    if s then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e5
    else
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.FogEnd = State.OriginalLighting.FogEnd
    end
end)

createToggle(visualsPage, "Lock Daytime (Always 14:00)", Config.ForceDaytime, function(s)
    Config.ForceDaytime = s
    if not s then
        Lighting.ClockTime = State.OriginalLighting.ClockTime
    end
end)

createHeader(visualsPage, "Town ESP")

createToggle(visualsPage, "Player ESP Highlights", Config.PlayerESP, function(s)
    Config.PlayerESP = s
    if not s then
        for _, hl in pairs(State.Highlights) do
            pcall(function() hl:Destroy() end)
        end
        State.Highlights = {}
    end
end)

createToggle(visualsPage, "Plot Owner Tags", Config.PlotESP, function(s)
    Config.PlotESP = s
end)

-- ==================== [CATEGORY 5: SETTINGS & SYSTEM] ====================
createHeader(settingsPage, "HUD & Watermark")

createToggle(settingsPage, "Watermark HUD Pill", Config.WatermarkEnabled, function(s)
    Config.WatermarkEnabled = s
    Watermark.Visible = s
end)

createHeader(settingsPage, "Keybinds & Diagnostics")

local diagCard = Instance.new("Frame")
diagCard.Size = UDim2.new(1, 0, 0, 48)
diagCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
diagCard.BorderSizePixel = 0
diagCard.Parent = settingsPage

local diagCorner = Instance.new("UICorner")
diagCorner.CornerRadius = UDim.new(0, 6)
diagCorner.Parent = diagCard

local diagText = Instance.new("TextLabel")
diagText.Size = UDim2.new(1, -24, 1, 0)
diagText.Position = UDim2.new(0, 12, 0, 0)
diagText.BackgroundTransparency = 1
diagText.Text = "Status: ACTIVE | Menu Toggle: [Insert] or Minimized Pill"
diagText.TextColor3 = Color3.fromRGB(100, 150, 255)
diagText.Font = Enum.Font.GothamMedium
diagText.TextSize = 11
diagText.TextXAlignment = Enum.TextXAlignment.Left
diagText.Parent = diagCard

-- Select First Tab
switchTab("💼 Auto Jobs")

-- Reveal Fail-Safe (Guarantees menu and watermark are shown even if tween or wait lags)
task.delay(1.5, function()
    if BorderFrame and BorderFrame.Parent and not BorderFrame.Visible and (not MinimizedBtn or not MinimizedBtn.Visible) then
        BorderFrame.Visible = true
    end
    if Watermark and Watermark.Parent and Config.WatermarkEnabled and not Watermark.Visible then
        Watermark.Visible = true
    end
end)

-- =========================================================================
-- RUNTIME ENGINE LOOPS
-- =========================================================================

-- Pizza Delivery Helper Functions
local function getPizzaDeliveryStation()
    if State.SavedPizzaSpot then
        return State.SavedPizzaSpot
    end
    if State.SavedConveyorPos then
        return State.SavedConveyorPos
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position
    end
    return Vector3.new(0, 15, 0)
end

local function getPizzaShelfPosition()
    return getPizzaDeliveryStation()
end

-- Direct Keyboard E Simulation (Compatible with all executors & Roblox engines)
simulatePressE = function(holdTime)
    holdTime = holdTime or 0.3
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(holdTime)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
    pcall(function()
        if keypress and keyrelease then
            keypress(0x45)
            task.wait(holdTime)
            keyrelease(0x45)
        end
    end)
end

-- Fast ProximityPrompt trigger without blocking thread
triggerPrompt = function(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
            fireproximityprompt(prompt, 1)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.15)
        prompt:InputHoldEnd()
    end)
end

-- Trigger any nearby prompts in local radius (No whole-workspace descendant scans)
triggerNearbyPrompts = function(centerPos, maxDist)
    maxDist = maxDist or 12
    pcall(function()
        local parts = Workspace:GetPartBoundsInRadius(centerPos, maxDist)
        for _, part in ipairs(parts) do
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    triggerPrompt(child)
                elseif child:IsA("ClickDetector") and fireclickdetector then
                    pcall(function() fireclickdetector(child) end)
                end
            end
        end
    end)
end

-- Interact with object: triggers immediate prompts & presses E cleanly
interactWithObject = function(target)
    if not target then return end
    pcall(function()
        if target:IsA("ProximityPrompt") then
            triggerPrompt(target)
            return
        end
        for _, child in ipairs(target:GetChildren()) do
            if child:IsA("ProximityPrompt") then
                triggerPrompt(child)
            elseif child:IsA("ClickDetector") and fireclickdetector then
                pcall(function() fireclickdetector(child) end)
            end
        end
    end)
    simulatePressE(0.25)
end

-- Strict Check: Is this a real player character or descendant of a player?
isRealPlayer = function(instance)
    if not instance then return false end
    if instance == LocalPlayer.Character then return true end
    if Players:GetPlayerFromCharacter(instance) then return true end
    if instance.Parent and Players:GetPlayerFromCharacter(instance.Parent) then return true end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and (instance == plr.Character or instance:IsDescendantOf(plr.Character)) then
            return true
        end
    end
    return false
end

-- Ultra-Fast Active Customer Finder (Direct Arrow Locator + GUI Indicator)
local function findArrowInPlayerGui()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pgui then return nil, nil end

    for _, desc in ipairs(pgui:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Adornee then
            local ad = desc.Adornee
            -- NEVER match real players!
            if not isRealPlayer(ad) then
                local dn = desc.Name:lower()
                local isArrow = dn:find("arrow") or dn:find("marker") or dn:find("target") or dn:find("delivery") or dn:find("order") or dn:find("waypoint") or dn:find("pointer")
                if not isArrow then
                    for _, c in ipairs(desc:GetChildren()) do
                        local cn = c.Name:lower()
                        if cn:find("arrow") or cn:find("pointer") or cn:find("marker") or cn:find("waypoint") then
                            isArrow = true
                            break
                        end
                    end
                end
                if isArrow then
                    local p = (ad:IsA("BasePart") and ad.Position) or (ad:IsA("Model") and ad:GetPivot().Position)
                    if p and p.Y > 5 then
                        return p, ad
                    end
                end
            end
        end

        if desc:IsA("ObjectValue") and desc.Value then
            local val = desc.Value
            if (val:IsA("Model") or val:IsA("BasePart")) and not isRealPlayer(val) then
                local vn = desc.Name:lower()
                local valn = val.Name:lower()
                if vn:find("target") or vn:find("customer") or vn:find("arrow") or vn:find("order") or valn:find("customer") then
                    return val:GetPivot().Position, val
                end
            end
        end

        if desc:IsA("Vector3Value") and (desc.Name:lower():find("target") or desc.Name:lower():find("customer") or desc.Name:lower():find("dest")) then
            if desc.Value.Y > 5 then
                return desc.Value, nil
            end
        end
    end
    return nil, nil
end

local function getArrowPosition()
    local now = tick()
    if State.CachedArrowPos and (now - (State.LastArrowSearch or 0) < 0.6) then
        return State.CachedArrowPos, State.CachedArrowObj
    end
    State.LastArrowSearch = now

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0, 0, 0)

    -- 1. Check PlayerGui for Arrow or BillboardGui Adornee
    local pguiPos, pguiObj = findArrowInPlayerGui()
    if pguiPos and not isRealPlayer(pguiObj) then
        State.CachedArrowPos = pguiPos
        State.CachedArrowObj = pguiObj
        return pguiPos, pguiObj
    end

    -- 2. Check Camera for 3D Arrow
    if Camera then
        for _, obj in ipairs(Camera:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("arrow") or n:find("pointer") or n:find("indicator") or n:find("waypoint") or n:find("target") then
                if (obj:IsA("BasePart") or obj:IsA("Model")) and not isRealPlayer(obj) then
                    local p = obj:GetPivot().Position
                    if p.Y > 5 and (p - myPos).Magnitude > 4 then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj
                        return p, obj
                    end
                end
            end
        end
    end

    -- 3. Check Character for 3D Arrow
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("arrow") or n:find("pointer")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local p = obj:GetPivot().Position
                if p.Y > 5 and (p - myPos).Magnitude > 4 then
                    State.CachedArrowPos = p
                    State.CachedArrowObj = obj
                    return p, obj
                end
            end
        end
    end

    -- 4. Fast scan Workspace folders (depth 3, skipping heavy non-job folders)
    local foundPos, foundObj = nil, nil
    local function searchArrow(parent, depth)
        if not parent or depth <= 0 or foundPos then return end
        for _, child in ipairs(parent:GetChildren()) do
            if not isRealPlayer(child) then
                local cn = child.Name:lower()
                if cn:find("arrow") or cn:find("target") or cn:find("waypoint") or cn:find("orderarrow") or cn:find("deliveryarrow") then
                    if child:IsA("BasePart") or child:IsA("Model") then
                        local p = child:GetPivot().Position
                        if p.Y > 5 and (p - myPos).Magnitude > 4 then
                            foundPos = p
                            foundObj = child
                            return
                        end
                    end
                elseif child:IsA("Folder") or child:IsA("Model") then
                    if not (cn:find("terrain") or cn:find("road") or cn:find("tree") or cn:find("plot") or cn:find("house") or cn:find("building") or cn:find("prop")) then
                        searchArrow(child, depth - 1)
                    end
                end
            end
        end
    end
    searchArrow(Workspace, 3)

    if foundPos then
        State.CachedArrowPos = foundPos
        State.CachedArrowObj = foundObj
    end

    return foundPos, foundObj
end

local function getAllNPCs()
    local now = tick()
    if State.CachedNPCs and (now - (State.LastNPCSearch or 0) < 2.5) then
        return State.CachedNPCs
    end
    State.LastNPCSearch = now

    local char = LocalPlayer.Character
    local npcs = {}
    local function searchNPCs(parent, depth)
        if not parent or depth <= 0 then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") and child ~= char and child:FindFirstChildOfClass("Humanoid") then
                if not isRealPlayer(child) then
                    table.insert(npcs, child)
                end
            elseif child:IsA("Folder") or child:IsA("Model") then
                if not isRealPlayer(child) then
                    local cn = child.Name:lower()
                    if not (cn:find("terrain") or cn:find("road") or cn:find("tree") or cn:find("plot") or cn:find("house") or cn:find("building") or cn:find("prop") or cn:find("furniture") or cn:find("decor")) then
                        searchNPCs(child, depth - 1)
                    end
                end
            end
        end
    end
    searchNPCs(Workspace, 3)
    State.CachedNPCs = npcs
    return npcs
end

getActiveDeliveryCustomer = function()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    local now = tick()
    if State.CachedCustomer and State.CachedCustomer.Parent and not isRealPlayer(State.CachedCustomer) and (now - (State.LastCustomerSearch or 0) < 1.0) then
        local cHead = State.CachedCustomer:FindFirstChild("Head") or State.CachedCustomer:FindFirstChild("HumanoidRootPart") or (State.CachedCustomer:IsA("BasePart") and State.CachedCustomer)
        if cHead and cHead.Position.Y > 5 then
            return State.CachedCustomer, State.CachedPrompt
        end
    end
    State.LastCustomerSearch = now

    -- 1. Try finding Delivery Arrow position
    local arrowPos, arrowObj = getArrowPosition()
    if arrowObj and isRealPlayer(arrowObj) then
        arrowPos, arrowObj = nil, nil
    end

    -- 2. Find all NPCs in Workspace (Strictly excluding real players)
    local npcs = getAllNPCs()

    -- Strategy 0: If customer was learned previously, prioritize matching it!
    if State.LearnedCustomerName then
        local candidates = {}
        if State.LearnedCustomerParent and State.LearnedCustomerParent.Parent then
            for _, child in ipairs(State.LearnedCustomerParent:GetChildren()) do
                if child.Name == State.LearnedCustomerName and child:IsA("Model") and not isRealPlayer(child) then
                    table.insert(candidates, child)
                end
            end
        end
        if #candidates == 0 then
            for _, npc in ipairs(npcs) do
                if npc.Name == State.LearnedCustomerName and not isRealPlayer(npc) then
                    table.insert(candidates, npc)
                end
            end
        end

        if #candidates > 0 then
            if arrowPos then
                local bestCust, bestDist = nil, math.huge
                for _, c in ipairs(candidates) do
                    local d = (c:GetPivot().Position - arrowPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestCust = c
                    end
                end
                if bestCust and bestDist < 50 then
                    local prompt = bestCust:FindFirstChildWhichIsA("ProximityPrompt", true)
                    State.CachedCustomer = bestCust
                    State.CachedPrompt = prompt
                    return bestCust, prompt
                end
            elseif #candidates == 1 then
                local c = candidates[1]
                local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                State.CachedCustomer = c
                State.CachedPrompt = prompt
                return c, prompt
            end
        end
    end

    -- Strategy A: Find NPC closest to arrow position (MUST BE within 35 studs of arrow, not a player)
    if arrowPos then
        local closestNpc = nil
        local closestDist = math.huge
        for _, npc in ipairs(npcs) do
            if not isRealPlayer(npc) then
                local nPos = npc:GetPivot().Position
                local d = (Vector3.new(nPos.X, 0, nPos.Z) - Vector3.new(arrowPos.X, 0, arrowPos.Z)).Magnitude
                if d < 35 and d < closestDist then
                    closestDist = d
                    closestNpc = npc
                end
            end
        end
        if closestNpc then
            local prompt = closestNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
            State.CachedCustomer = closestNpc
            State.CachedPrompt = prompt
            return closestNpc, prompt
        end

        -- If no NPC was within 35 studs of arrow, the arrow itself is the delivery target (if not a player)
        if arrowObj and not isRealPlayer(arrowObj) then
            local arrowModel = (arrowObj:IsA("Model") and arrowObj) or (arrowObj.Parent and arrowObj.Parent:IsA("Model") and arrowObj.Parent) or arrowObj
            if arrowModel and not isRealPlayer(arrowModel) then
                State.CachedCustomer = arrowModel
                return arrowModel, nil
            end
        end
    end

    -- Strategy B: Check NPCs with explicit Delivery indicator (BillboardGui / Arrow on head / Prompt)
    for _, npc in ipairs(npcs) do
        if not isRealPlayer(npc) then
            local nPos = npc:GetPivot().Position
            if nPos.Y > 5 then
                local head = npc:FindFirstChild("Head")
                local hasIndicator = false
                if head and (head:FindFirstChildOfClass("BillboardGui") or head:FindFirstChild("Arrow")) then
                    hasIndicator = true
                end
                for _, c in ipairs(npc:GetChildren()) do
                    local cn = c.Name:lower()
                    if cn:find("arrow") or cn:find("order") or cn:find("delivery") or c:IsA("BillboardGui") then
                        hasIndicator = true
                        break
                    end
                end

                local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    local act = prompt.ActionText:lower()
                    local objt = prompt.ObjectText:lower()
                    if act:find("give") or act:find("deliver") or act:find("hand") or act:find("pizza") or
                       objt:find("customer") or objt:find("pizza") or objt:find("order") then
                        State.CachedCustomer = npc
                        State.CachedPrompt = prompt
                        return npc, prompt
                    end
                end

                if hasIndicator then
                    State.CachedCustomer = npc
                    State.CachedPrompt = prompt
                    return npc, prompt
                end
            end
        end
    end

    -- NO RANDOM GUESSING: If neither arrow nor customer indicator is found, wait for arrow to appear!
    return nil, nil
end

-- Learning Engine: Learns customer model, moped, and delivery target during manual or guided run
learnDeliveryRunNow = function()
    local char = LocalPlayer.Character
    if not char then return false, "Caracterul nu a fost găsit" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return false, "HumanoidRootPart nu a fost găsit" end

    -- 1. Check if seated on Moped
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        State.SavedMopedSeat = hum.SeatPart
        State.SavedMopedSpot = hrp.Position
        State.LearnedMopedName = hum.SeatPart.Parent and hum.SeatPart.Parent.Name or hum.SeatPart.Name
    end

    -- 2. Check Delivery Arrow
    local arrowPos, arrowObj = getArrowPosition()
    if arrowObj and not isRealPlayer(arrowObj) then
        State.LearnedArrowName = arrowObj.Name
    end

    -- 3. Check nearest NPC within 40 studs (MUST NOT BE A REAL PLAYER)
    local npcs = getAllNPCs()
    local closestNpc, closestDist = nil, 40
    for _, npc in ipairs(npcs) do
        if not isRealPlayer(npc) then
            local nPos = npc:GetPivot().Position
            local d = (nPos - hrp.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closestNpc = npc
            end
        end
    end

    -- If no NPC near player, but an arrow exists, check NPC near arrow
    if not closestNpc and arrowPos then
        for _, npc in ipairs(npcs) do
            if not isRealPlayer(npc) then
                local d = (npc:GetPivot().Position - arrowPos).Magnitude
                if d < 35 then
                    closestNpc = npc
                    break
                end
            end
        end
    end

    if closestNpc then
        State.LearnedCustomerName = closestNpc.Name
        State.LearnedCustomerParent = closestNpc.Parent
        local prompt = closestNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
        State.CachedCustomer = closestNpc
        State.CachedPrompt = prompt

        -- If standing right at the customer, auto-deliver right now!
        if closestDist < 18 then
            simulatePressE(0.4)
            if prompt then triggerPrompt(prompt) end
            triggerNearbyPrompts(closestNpc:GetPivot().Position, 10)
            State.HasPizza = false
        end

        local pName = closestNpc.Parent and closestNpc.Parent.Name or "Workspace"
        return true, string.format("Client Salvat: '%s' în [%s]", closestNpc.Name, pName)
    elseif arrowPos then
        local dist = math.floor((arrowPos - hrp.Position).Magnitude)
        return true, string.format("Săgeată Salvată la %d studs distanță!", dist)
    else
        return false, "Niciun client/săgeată în 40 studs. Mergi la client și apasă din nou!"
    end
end

-- Fast Nearest Moped Locator
findNearestMoped = function()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- 1. Check cached seat
    if State.SavedMopedSeat and State.SavedMopedSeat.Parent and State.SavedMopedSeat:IsA("VehicleSeat") then
        if State.SavedMopedSeat.Occupant == nil or (humanoid and State.SavedMopedSeat.Occupant == humanoid) then
            return State.SavedMopedSeat
        end
    end

    -- 2. Check parts in radius around character or SavedMopedSpot
    local checkSpots = {hrp.Position}
    if State.SavedMopedSpot then table.insert(checkSpots, State.SavedMopedSpot) end
    for _, spot in ipairs(checkSpots) do
        local nearby = Workspace:GetPartBoundsInRadius(spot, 35)
        for _, part in ipairs(nearby) do
            if part:IsA("VehicleSeat") and (part.Occupant == nil or part.Occupant == humanoid) then
                State.SavedMopedSeat = part
                return part
            end
        end
    end

    -- 3. Depth-4 search for VehicleSeat
    local function searchSeat(parent, depth)
        if not parent or depth <= 0 then return nil end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("VehicleSeat") and (child.Occupant == nil or child.Occupant == humanoid) then
                return child
            elseif child:IsA("Model") or child:IsA("Folder") then
                local cn = child.Name:lower()
                if cn:find("moped") or cn:find("scooter") or cn:find("delivery") or cn:find("vehicle") or cn:find("pizza") then
                    local s = child:FindFirstChildWhichIsA("VehicleSeat", true)
                    if s and (s.Occupant == nil or s.Occupant == humanoid) then
                        return s
                    end
                elseif not (cn:find("terrain") or cn:find("road") or cn:find("plot") or cn:find("house")) then
                    local s = searchSeat(child, depth - 1)
                    if s then return s end
                end
            end
        end
        return nil
    end

    local seat = searchSeat(Workspace, 4)
    if seat then
        State.SavedMopedSeat = seat
        return seat
    end

    return nil
end

-- Ultra-Fast Pizza Box Detection (Comprehensive)
hasPizzaBox = function()
    local char = LocalPlayer.Character
    if not char then return false, nil end

    -- 1. Flag override
    if State.HasPizza then
        return true, nil
    end

    -- 2. Check tools in Character
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return true, item
        end
    end

    -- 3. Check Backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                return true, item
            end
        end
    end

    -- 4. Check for any held model/part that is NOT a default body part or accessory
    local defaultBodyParts = {
        ["humanoidrootpart"] = true, ["head"] = true, ["uppertorso"] = true, ["lowertorso"] = true,
        ["leftupperarm"] = true, ["leftlowerarm"] = true, ["lefthand"] = true,
        ["rightupperarm"] = true, ["rightlowerarm"] = true, ["righthand"] = true,
        ["leftupperleg"] = true, ["leftlowerleg"] = true, ["leftfoot"] = true,
        ["rightupperleg"] = true, ["rightlowerleg"] = true, ["rightfoot"] = true,
        ["torso"] = true, ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true
    }

    for _, item in ipairs(char:GetChildren()) do
        local n = item.Name:lower()
        if not defaultBodyParts[n] and not item:IsA("Accessory") and not item:IsA("Humanoid") and not item:IsA("LocalScript") and not item:IsA("Script") and not item:IsA("Shirt") and not item:IsA("Pants") and not item:IsA("BodyColors") and not item:IsA("Highlight") and not item:IsA("Folder") then
            if item:IsA("Model") or item:IsA("BasePart") then
                return true, item
            end
        end
    end

    local hands = {char:FindFirstChild("RightHand"), char:FindFirstChild("Right Arm"), char:FindFirstChild("UpperTorso")}
    for _, h in ipairs(hands) do
        if h then
            for _, c in ipairs(h:GetChildren()) do
                if c:IsA("BasePart") or c:IsA("Model") then
                    return true, c
                end
            end
        end
    end

    return false, nil
end

-- Smooth Safe Glide Function (Smooth Kinematic Glide - Zero Physics Conflict, Zero Lag, Zero Kicks)
smoothGlideTo = function(targetPos, speed)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Anti-Void Safety: Target height must be valid
    if targetPos.Y < 5 then return end

    local isVehicle = false
    local seat = humanoid and humanoid.SeatPart
    local mopedModel = nil
    local rootPart = hrp

    if seat and seat:IsA("VehicleSeat") then
        isVehicle = true
        mopedModel = seat:FindFirstAncestorOfClass("Model")
        rootPart = seat
    end

    -- Safe speed clamp: Moped 36-38 max, on foot 20-24 max (Eliminates server kicks!)
    local maxSafe = isVehicle and 38 or 24
    speed = math.clamp(speed or (isVehicle and (Config.MopedSpeed or 38) or (Config.DeliverySpeed or 22)), 14, maxSafe)

    local currentPos = rootPart.Position
    local dist = (targetPos - currentPos).Magnitude
    if dist < 2.5 then return end

    local duration = math.clamp(dist / speed, 0.25, 12)

    -- Temporary No-Collision on vehicle parts during glide to prevent physics solver lag/explosions
    local noclipParts = {}
    if isVehicle and mopedModel then
        pcall(function()
            for _, p in ipairs(mopedModel:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                    table.insert(noclipParts, p)
                end
            end
        end)
    end

    local startTime = tick()
    while tick() - startTime < duration and Config.AutoDelivery and character and character.Parent do
        local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
        local nextPos = currentPos:Lerp(targetPos, alpha)

        local lookTarget = Vector3.new(targetPos.X, nextPos.Y, targetPos.Z)
        local targetCFrame
        if (lookTarget - nextPos).Magnitude > 0.1 then
            targetCFrame = CFrame.new(nextPos, lookTarget)
        else
            targetCFrame = CFrame.new(nextPos)
        end

        if isVehicle then
            -- Zero out assembly velocity to eliminate physics oscillation
            if seat.AssemblyLinearVelocity then seat.AssemblyLinearVelocity = Vector3.zero end
            if seat.AssemblyAngularVelocity then seat.AssemblyAngularVelocity = Vector3.zero end

            if mopedModel and mopedModel.PrimaryPart then
                mopedModel:PivotTo(targetCFrame)
            else
                seat.CFrame = targetCFrame
            end
        else
            if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.zero end
            hrp.CFrame = targetCFrame
        end

        RunService.Heartbeat:Wait()
    end

    -- Restore collisions on vehicle parts
    if #noclipParts > 0 then
        pcall(function()
            for _, p in ipairs(noclipParts) do
                if p and p.Parent then
                    p.CanCollide = true
                end
            end
        end)
    end

    -- Final snap to target
    if isVehicle then
        if mopedModel and mopedModel.PrimaryPart then
            mopedModel:PivotTo(CFrame.new(targetPos))
        else
            seat.CFrame = CFrame.new(targetPos)
        end
    else
        hrp.CFrame = CFrame.new(targetPos)
    end
end

-- Mount Moped Helper
mountMoped = function(mopedSeat)
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or not mopedSeat then return false end

    if humanoid.SeatPart == mopedSeat then
        return true
    end

    debugLog("MOPED", "Merg lângă scaunul mopedului...")
    smoothGlideTo(mopedSeat.Position + Vector3.new(0, 2, 0), Config.DeliverySpeed)
    task.wait(0.1)

    -- Sit on seat
    debugLog("MOPED", "Urc pe moped (Seat:Sit)...")
    hrp.CFrame = mopedSeat.CFrame + Vector3.new(0, 0.5, 0)
    pcall(function()
        mopedSeat:Sit(humanoid)
    end)
    task.wait(0.2)

    -- If not seated, simulate press E to drive
    if not humanoid.SeatPart then
        simulatePressE(0.35)
        task.wait(0.2)
    end

    -- Touch interest backup
    if not humanoid.SeatPart and firetouchinterest then
        pcall(function()
            firetouchinterest(hrp, mopedSeat, 0)
            task.wait(0.05)
            firetouchinterest(hrp, mopedSeat, 1)
        end)
        task.wait(0.15)
    end

    local seated = humanoid.SeatPart ~= nil
    if seated then
        debugLog("MOPED", "Urcat pe moped cu succes! ✅", Color3.fromRGB(100, 255, 150))
    else
        debugLog("MOPED", "⚠️ Nu s-a putut urca pe moped, reîncerc...", Color3.fromRGB(255, 180, 80))
    end

    return seated
end

-- Core Pizza Delivery Automation Step
runPizzaDeliveryStep = function()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    local hasPizza, pizzaTool = hasPizzaBox()
    local isMounted = (humanoid.SeatPart ~= nil and humanoid.SeatPart:IsA("VehicleSeat"))

    local boxSpot = State.SavedPizzaSpot or State.SavedConveyorPos or hrp.Position
    local mopedSpot = State.SavedMopedSpot or (boxSpot + Vector3.new(-30, 0, 15))

    -- STAGE 1: We do NOT have pizza -> Go to saved pizza spot, press E to take pizza box
    if not hasPizza then
        debugLog("PASUL 1", "Nu ai pizza! Merg la banda de pizza...", Color3.fromRGB(255, 180, 80))

        -- If currently riding moped, drive to moped spot outside and dismount
        if isMounted then
            debugLog("MOPED", "Cobor de pe moped pentru a merge la cutii...")
            smoothGlideTo(mopedSpot + Vector3.new(0, 1.5, 0), Config.MopedSpeed or 38)
            task.wait(0.15)
            humanoid.Jump = true
            task.wait(0.25)
        end

        -- Walk/glide directly to saved pizza conveyor spot
        smoothGlideTo(boxSpot + Vector3.new(0, 1.5, 0), Config.DeliverySpeed or 22)

        -- Align rotation to face conveyor exactly as saved
        if State.SavedPizzaCFrame then
            hrp.CFrame = State.SavedPizzaCFrame
        end
        task.wait(0.1)

        -- PRESS [E] TO TAKE PIZZA BOX (Simulate keypress E)
        debugLog("PASUL 1", "Apăs [E] la banda de pizza...")
        simulatePressE(0.35)

        if State.SavedPizzaPrompt and State.SavedPizzaPrompt.Parent then
            triggerPrompt(State.SavedPizzaPrompt)
        end
        triggerNearbyPrompts(boxSpot, 10)

        -- Click center of screen where the conveyor box is positioned
        pcall(function()
            VirtualUser:CaptureController()
            local vp = Camera.ViewportSize
            VirtualUser:ClickButton1(Vector2.new(vp.X / 2, vp.Y / 2))
        end)

        task.wait(0.2)
        simulatePressE(0.2)
        task.wait(0.3)

        if hasPizzaBox() then
            State.HasPizza = true
            debugLog("PASUL 1", "Cutie de pizza luată cu succes! ✅", Color3.fromRGB(100, 255, 150))
        else
            debugLog("PASUL 1", "Aștept cutia să apară pe bandă...", Color3.fromRGB(255, 200, 100))
        end

        task.wait(Config.WorkDelay or 0.3)

    -- STAGE 2: We HAVE pizza -> Go out to moped, mount, and ride to customer!
    else
        debugLog("PASUL 2", "Ai pizza! Mă pregătesc de plecare la client...", Color3.fromRGB(100, 200, 255))

        -- Equip pizza if in backpack
        if pizzaTool and pizzaTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
            humanoid:EquipTool(pizzaTool)
            task.wait(0.1)
        end

        -- Check if mounted on moped; if not, MOVE OUTSIDE TO MOPED SPOT FIRST!
        isMounted = (humanoid.SeatPart ~= nil and humanoid.SeatPart:IsA("VehicleSeat"))
        if not isMounted then
            debugLog("MOPED", "Merg afară spre moped...")
            smoothGlideTo(mopedSpot + Vector3.new(0, 1.5, 0), Config.DeliverySpeed or 22)
            task.wait(0.15)

            debugLog("MOPED", "Urc pe moped...")
            local mopedSeat = findNearestMoped()
            if mopedSeat then
                mountMoped(mopedSeat)
                task.wait(0.25)
            else
                simulatePressE(0.35)
                task.wait(0.2)
            end
        end

        isMounted = (humanoid.SeatPart ~= nil and humanoid.SeatPart:IsA("VehicleSeat"))
        if isMounted then
            debugLog("MOPED", "Urcat pe moped cu succes! ✅", Color3.fromRGB(100, 255, 150))
        end

        -- Find active delivery customer
        debugLog("CLIENT", "Caut clientul / săgeata de livrare...")
        local customer, custPrompt = getActiveDeliveryCustomer()
        if customer then
            local custHrp = customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head") or customer.PrimaryPart or (customer:IsA("BasePart") and customer)
            local custPos = custHrp and custHrp.Position
            if custPos and custPos.Y > 5 then
                local deliverPos = custPos + Vector3.new(0, 1.5, 0)
                if custHrp:IsA("BasePart") then
                    deliverPos = custPos + (custHrp.CFrame.LookVector * 3.5) + Vector3.new(0, 1.5, 0)
                end

                local distToCust = (custPos - hrp.Position).Magnitude
                local speed = isMounted and (Config.MopedSpeed or 38) or (Config.DeliverySpeed or 22)
                debugLog("NAVIGARE", string.format("Glisez spre client '%s' la %d MPH (Distanță: %d studs)...", customer.Name, speed, math.floor(distToCust)), Color3.fromRGB(100, 200, 255))

                smoothGlideTo(deliverPos, speed)
                task.wait(0.25)

                -- Press [E] to deliver pizza to customer!
                debugLog("LIVRARE", "Am ajuns la client! Apăs [E] pentru predare...", Color3.fromRGB(255, 200, 100))
                simulatePressE(0.4)
                if custPrompt then
                    triggerPrompt(custPrompt)
                end
                triggerNearbyPrompts(custPos, 10)
                simulatePressE(0.25)

                task.wait(Config.WorkDelay or 0.5)
                State.HasPizza = false
                State.CachedCustomer = nil
                debugLog("LIVRARE", "🎉 Pizza livrată cu succes! Încep următoarea cursă! 🚀", Color3.fromRGB(100, 255, 150))
            end
        else
            debugLog("AȘTEPTARE", "⚠️ Săgeata sau clientul nu a apărut încă. Aștept 0.5s...", Color3.fromRGB(255, 180, 80))
            task.wait(0.5)
        end
    end
end

-- Pizza Delivery Background Worker Loop (Protected with Re-entrancy Guard & Error Logging)
local isRunningDeliveryStep = false
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoDelivery and getgenv().PullZBloxburgLoaded and not isRunningDeliveryStep then
            isRunningDeliveryStep = true
            local ok, err = pcall(runPizzaDeliveryStep)
            if not ok then
                debugLog("EROARE", tostring(err), Color3.fromRGB(255, 80, 80))
            end
            isRunningDeliveryStep = false
        end
    end
end))

-- Delivery Moped Turbo Boost Loop (Safe Cap: 38 MPH)
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if Config.MopedBoost and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
            local seat = humanoid.SeatPart
            seat.MaxSpeed = math.clamp(Config.MopedSpeed or 38, 20, 42)
            seat.Torque = 1.5
            seat.TurnSpeed = 1.8
        end
    end
end))

-- Movement & Walkspeed Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if Config.SpeedHack then
            humanoid.WalkSpeed = Config.SpeedMultiplier
        elseif Config.SprintBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            humanoid.WalkSpeed = 32
        end

        if Config.ForceDaytime then
            Lighting.ClockTime = 14
        end
    end)
end))

-- Noclip Collision Disabler Loop
table.insert(State.Connections, RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        pcall(function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
end))

-- Infinite Mid-Air Jump
table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        pcall(function()
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end))

-- Flight Engine Loop
table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    if Config.FlyEnabled and LocalPlayer.Character then
        pcall(function()
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if not State.FlyBodyVelocity then
                State.FlyBodyVelocity = Instance.new("BodyVelocity")
                State.FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                State.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                State.FlyBodyVelocity.Parent = hrp

                State.FlyBodyGyro = Instance.new("BodyGyro")
                State.FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                State.FlyBodyGyro.CFrame = hrp.CFrame
                State.FlyBodyGyro.Parent = hrp
            end

            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end

            if moveDir.Magnitude > 0 then
                State.FlyBodyVelocity.Velocity = moveDir.Unit * Config.FlySpeed
            else
                State.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            State.FlyBodyGyro.CFrame = Camera.CFrame
        end)
    end
end))

-- Player ESP Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if Config.PlayerESP then
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not State.Highlights[player] or not State.Highlights[player].Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "PullZ_Bloxburg_ESP"
                        hl.FillColor = Color3.fromRGB(100, 150, 255)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Adornee = player.Character
                        hl.Parent = player.Character
                        State.Highlights[player] = hl
                    end
                end
            end
        end)
    end
end))

-- Anti-AFK Idle Keep-Alive Loop
table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end))

-- Menu Toggle Keybind ([Insert] Only, Shift Removed)
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        BorderFrame.Visible = not BorderFrame.Visible
        if MinimizedBtn.Visible then
            MinimizedBtn.Visible = false
        end
    end
end))

-- =========================================================================
-- CLEAN UNLOAD & SELF-DESTRUCT
-- =========================================================================
local function PullZBloxburgUnload()
    -- Disconnect runtime events
    for _, conn in pairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}

    -- Restore Lighting
    pcall(function()
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        Lighting.FogEnd = State.OriginalLighting.FogEnd
    end)

    -- Clean Flight Bodies
    pcall(function()
        if State.FlyBodyVelocity then State.FlyBodyVelocity:Destroy() end
        if State.FlyBodyGyro then State.FlyBodyGyro:Destroy() end
    end)

    -- Clean ESP Highlights
    for _, hl in pairs(State.Highlights) do
        pcall(function() hl:Destroy() end)
    end
    State.Highlights = {}

    -- Restore Walkspeed
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end)

    -- Destroy ScreenGui across all containers
    pcall(function()
        if State.ScreenGui and State.ScreenGui.Parent then
            State.ScreenGui:Destroy()
        end
    end)
    pcall(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)

    local containers = {}
    pcall(function() if gethui then table.insert(containers, gethui()) end end)
    pcall(function() table.insert(containers, CoreGui) end)
    pcall(function() if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then table.insert(containers, LocalPlayer.PlayerGui) end end)

    for _, container in ipairs(containers) do
        pcall(function()
            for _, child in ipairs(container:GetChildren()) do
                if child.Name:match("^PullZ_Bloxburg_") or child.Name:match("^PullZ_") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end

    getgenv().PullZBloxburgLoaded = nil
    getgenv().PullZBloxburgUnload = nil
    getgenv().PullZScreenGui = nil
end

getgenv().PullZBloxburgUnload = PullZBloxburgUnload
