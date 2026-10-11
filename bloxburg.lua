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
    DeliverySpeed = 65,
    MopedBoost = true,
    MopedSpeed = 95,
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
    FlyBodyGyro = nil
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

-- ==================== [CATEGORY 1: AUTO JOBS] ====================
createHeader(jobsPage, "Pizza Delivery Automation")

createToggle(jobsPage, "Auto Pizza Delivery Worker", Config.AutoDelivery, function(s)
    Config.AutoDelivery = s
end)

createToggle(jobsPage, "Delivery Moped Turbo (95 MPH)", Config.MopedBoost, function(s)
    Config.MopedBoost = s
end)

createSlider(jobsPage, "Delivery Glide Speed", 30, 150, Config.DeliverySpeed, function(val)
    Config.DeliverySpeed = val
end)

createButton(jobsPage, "Teleport to Pizza Planet (Conveyor)", function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local stationPos = getPizzaDeliveryStation()
            hrp.CFrame = CFrame.new(stationPos + Vector3.new(0, 2.5, 0))
            task.wait(0.2)
            pcall(function()
                for _, prompt in pairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local pPos = prompt.Parent and prompt.Parent:GetPivot().Position
                        if pPos and (pPos - stationPos).Magnitude < 15 then
                            triggerPrompt(prompt)
                        end
                    end
                end
                for _, part in pairs(Workspace:GetPartBoundsInRadius(stationPos, 15)) do
                    interactWithObject(part)
                end
            end)
        end
    end)
end)

createButton(jobsPage, "Teleport to Active Customer (Deliver)", function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local customer, prompt = getActiveDeliveryCustomer()
        if hrp and customer then
            local targetPos = nil
            if customer.FindFirstChild and (customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head")) then
                local custRoot = customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head")
                targetPos = custRoot.Position + (custRoot.CFrame.LookVector * 3.5) + Vector3.new(0, 1.5, 0)
            elseif customer.Position then
                targetPos = customer.Position + Vector3.new(0, 1.5, 0)
            else
                targetPos = customer:GetPivot().Position + Vector3.new(0, 1.5, 0)
            end

            if targetPos then
                hrp.CFrame = CFrame.new(targetPos)
                task.wait(0.25)
                if prompt then
                    triggerPrompt(prompt)
                end
                interactWithObject(customer)
            end
        end
    end)
end)

createButton(jobsPage, "📍 Set Conveyor Here (My Current Spot)", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        State.SavedConveyorPos = hrp.Position
        pcall(function()
            local notif = Instance.new("Message", Workspace)
            notif.Text = "Pizza Conveyor Spot Saved!"
            task.delay(2, function() notif:Destroy() end)
        end)
    end
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
    -- Check if player already saved position
    if State.SavedConveyorPos then
        return State.SavedConveyorPos
    end

    -- 1. Search for ProximityPrompt on Conveyor / Pizza Boxes
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local act = prompt.ActionText:lower()
            local objt = prompt.ObjectText:lower()
            local p = prompt.Parent
            local pn = p and p.Name:lower() or ""

            if (act:find("take") or act:find("grab") or act:find("pick") or act:find("get")) and
               (objt:find("pizza") or objt:find("box") or pn:find("box") or pn:find("conveyor") or pn:find("dispenser")) then
                if not pn:find("dough") and not pn:find("sauce") and not pn:find("cheese") and not pn:find("bake") and not pn:find("oven") and not pn:find("table") then
                    local pos = p:GetPivot().Position
                    State.SavedConveyorPos = pos
                    return pos
                end
            end
        end
    end

    -- 2. Search for Conveyor Belt / Box Dispenser models
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local p = obj.Parent
            local pn = p and p.Name:lower() or ""

            if n:find("conveyor") or n:find("dispenser") or n:find("boxstack") or n:find("pizzaboxstack") or (n:find("boxes") and (pn:find("pizza") or pn:find("delivery") or pn:find("planet"))) then
                if not n:find("table") and not pn:find("table") and not n:find("bake") and not pn:find("bake") and not n:find("dough") then
                    local pos = obj:GetPivot().Position
                    State.SavedConveyorPos = pos
                    return pos
                end
            end
        end
    end

    -- 3. Search for pizza boxes on conveyor (parts/models named pizzabox / box)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local p = obj.Parent
            local pn = p and p.Name:lower() or ""

            if (n:find("pizzabox") or n == "pizza box" or (n:find("box") and pn:find("conveyor"))) then
                if not n:find("table") and not pn:find("table") and not pn:find("bake") and not pn:find("dough") and not pn:find("oven") then
                    local pos = obj:GetPivot().Position
                    State.SavedConveyorPos = pos
                    return pos
                end
            end
        end
    end

    -- 4. Geolocation based on Mopeds outside Pizza Planet
    local mopedSeat = findNearestMoped()
    if mopedSeat then
        for _, part in pairs(Workspace:GetPartBoundsInRadius(mopedSeat.Position, 90)) do
            local n = part.Name:lower()
            local pn = part.Parent and part.Parent.Name:lower() or ""
            if (n:find("conveyor") or n:find("box") or pn:find("conveyor") or pn:find("box")) and not n:find("table") and not pn:find("table") and not n:find("bake") then
                local pos = part:GetPivot().Position
                State.SavedConveyorPos = pos
                return pos
            end
        end
    end

    -- 5. Fallback if player character is inside Pizza Planet near mopeds
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrpPos = char.HumanoidRootPart.Position
        if mopedSeat and (hrpPos - mopedSeat.Position).Magnitude < 90 then
            State.SavedConveyorPos = hrpPos
            return hrpPos
        end
    end

    return Vector3.new(1172, 14, 258)
end

local function getPizzaShelfPosition()
    return getPizzaDeliveryStation()
end

local function getActiveDeliveryCustomer()
    local char = LocalPlayer.Character

    -- 1. Check ALL ProximityPrompts in Workspace for Give/Deliver
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local act = prompt.ActionText:lower()
            local objt = prompt.ObjectText:lower()

            if (act:find("give") or act:find("deliver") or act:find("hand") or act:find("drop")) or
               (objt:find("pizza") or objt:find("customer") or objt:find("order") or objt:find("resident") or objt:find("client")) then
                local model = prompt:FindFirstAncestorOfClass("Model")
                if model and model ~= char then
                    if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") then
                        return model, prompt
                    end
                end
            end
        end
    end

    -- 2. Find Navigation Arrow / Marker in Workspace
    local arrowObj = nil
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if (n:find("arrow") or n:find("orderarrow") or n:find("deliverymarker") or n == "marker" or n == "order" or n:find("target")) then
                if not obj:IsDescendantOf(char) then
                    arrowObj = obj
                    break
                end
            end
        end
    end

    if arrowObj then
        local arrowPos = arrowObj:GetPivot().Position
        local closestNpc = nil
        local closestDist = math.huge

        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= char and obj:FindFirstChildOfClass("Humanoid") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
                if root then
                    local d = (root.Position - arrowPos).Magnitude
                    if d < 25 and d < closestDist then
                        closestDist = d
                        closestNpc = obj
                    end
                end
            end
        end

        if closestNpc then
            return closestNpc, nil
        end

        -- Stand-in customer at arrow position
        local targetPos = arrowPos - Vector3.new(0, 4, 0)
        local virtualCustomer = {
            Position = targetPos,
            CFrame = CFrame.new(targetPos),
            GetPivot = function() return CFrame.new(targetPos) end,
            FindFirstChild = function(_, name)
                if name == "HumanoidRootPart" or name == "Head" then
                    return { Position = targetPos, CFrame = CFrame.new(targetPos), LookVector = Vector3.new(0, 0, 1) }
                end
                return nil
            end,
            GetDescendants = function() return {} end
        }
        return virtualCustomer, nil
    end

    -- 3. BillboardGui / Order GUI on NPC Head
    for _, gui in pairs(Workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") and not gui:IsDescendantOf(char) then
            local model = gui:FindFirstAncestorOfClass("Model")
            if model and model ~= char and model:FindFirstChildOfClass("Humanoid") then
                return model, nil
            end
        end
    end

    -- 4. Check Beams connected to target
    for _, beam in pairs(Workspace:GetDescendants()) do
        if beam:IsA("Beam") then
            local att1 = beam.Attachment1
            if att1 and att1.Parent then
                local model = att1.Parent:FindFirstAncestorOfClass("Model")
                if model and model ~= char and model:FindFirstChildOfClass("Humanoid") then
                    return model, nil
                end
            end
        end
    end

    return nil, nil
end

local function findNearestMoped()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closestSeat = nil
    local closestDist = math.huge
    local shelfPos = Vector3.new(1172, 14, 258)
    local parkingPos = Vector3.new(1148, 14, 265)

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") then
            local model = obj:FindFirstAncestorOfClass("Model")
            local n = model and model.Name:lower() or obj.Name:lower()
            local dToShelf = (obj.Position - shelfPos).Magnitude
            local dToPark = (obj.Position - parkingPos).Magnitude
            local dToHrp = (obj.Position - hrp.Position).Magnitude

            local isFree = (obj.Occupant == nil or (char:FindFirstChildOfClass("Humanoid") and obj.Occupant == char:FindFirstChildOfClass("Humanoid")))
            if isFree then
                if n:find("moped") or n:find("scooter") or n:find("pizza") or n:find("delivery") or dToShelf < 260 or dToPark < 260 then
                    if dToHrp < closestDist then
                        closestDist = dToHrp
                        closestSeat = obj
                    end
                end
            end
        end
    end

    -- Fallback: Any unoccupied VehicleSeat near the player
    if not closestSeat then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat") and obj.Occupant == nil then
                local d = (obj.Position - hrp.Position).Magnitude
                if d < 120 then
                    closestSeat = obj
                    break
                end
            end
        end
    end

    return closestSeat
end

local function hasPizzaBox()
    local char = LocalPlayer.Character
    if not char then return false, nil end

    -- Check character tools
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return true, item
        end
    end

    -- Check backpack tools
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                return true, item
            end
        end
    end

    -- Check welded objects / models in character
    for _, item in pairs(char:GetChildren()) do
        local n = item.Name:lower()
        if (n:find("pizza") or n:find("box")) and (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Accessory")) then
            return true, item
        end
    end

    -- Check if active customer arrow is present
    if getActiveDeliveryCustomer() ~= nil then
        return true, nil
    end

    return false, nil
end

local function smoothGlideTo(targetPos, speed)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = nil
    local isVehicle = false

    if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
        local seat = humanoid.SeatPart
        local mopedModel = seat:FindFirstAncestorOfClass("Model")
        rootPart = (mopedModel and mopedModel.PrimaryPart) or seat
        isVehicle = true
    else
        rootPart = character:FindFirstChild("HumanoidRootPart")
    end

    if not rootPart then return end

    speed = speed or (isVehicle and (Config.MopedSpeed or 95) or Config.DeliverySpeed or 65)
    local currentPos = rootPart.Position
    local dist = (targetPos - currentPos).Magnitude
    if dist < 2.5 then return end

    local duration = math.clamp(dist / speed, 0.2, 10)

    local bodyVel = rootPart:FindFirstChild("PullZ_GlideVel")
    if not bodyVel then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "PullZ_GlideVel"
        bodyVel.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        bodyVel.Parent = rootPart
    end

    local startTime = tick()
    while tick() - startTime < duration and Config.AutoDelivery and character and character.Parent do
        local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
        local nextPos = currentPos:Lerp(targetPos, alpha)

        local lookTarget = Vector3.new(targetPos.X, nextPos.Y, targetPos.Z)
        if (lookTarget - nextPos).Magnitude > 0.1 then
            rootPart.CFrame = CFrame.new(nextPos, lookTarget)
        else
            rootPart.CFrame = CFrame.new(nextPos)
        end

        local dir = (targetPos - rootPart.Position)
        if dir.Magnitude > 0 then
            bodyVel.Velocity = dir.Unit * speed
        end
        RunService.Heartbeat:Wait()
    end

    if bodyVel then pcall(function() bodyVel:Destroy() end) end
    rootPart.CFrame = CFrame.new(targetPos)
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0.1)
        prompt:InputHoldEnd()
    end)
end

local function interactWithObject(target)
    if not target then return end
    pcall(function()
        if target:IsA("ProximityPrompt") then
            triggerPrompt(target)
            return
        end
        for _, prompt in pairs(target:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                triggerPrompt(prompt)
            end
            if prompt:IsA("ClickDetector") and fireclickdetector then
                fireclickdetector(prompt)
            end
        end
    end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end

local function mountMoped(mopedSeat)
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or not mopedSeat then return false end

    if humanoid.SeatPart == mopedSeat then
        return true
    end

    -- Walk/glide directly to moped seat
    smoothGlideTo(mopedSeat.Position + Vector3.new(0, 2, 0), Config.DeliverySpeed)
    task.wait(0.15)

    -- Teleport above seat and sit
    hrp.CFrame = mopedSeat.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.1)
    pcall(function()
        mopedSeat:Sit(humanoid)
    end)
    task.wait(0.25)

    -- If not seated, interact with vehicle model prompts
    if not humanoid.SeatPart then
        local model = mopedSeat:FindFirstAncestorOfClass("Model")
        interactWithObject(model or mopedSeat)
        task.wait(0.2)
    end

    -- Touch interest backup
    if not humanoid.SeatPart and firetouchinterest then
        pcall(function()
            firetouchinterest(hrp, mopedSeat, 0)
            task.wait(0.05)
            firetouchinterest(hrp, mopedSeat, 1)
        end)
        task.wait(0.2)
    end

    return humanoid.SeatPart ~= nil
end

local function runPizzaDeliveryStep()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    local hasPizza, pizzaTool = hasPizzaBox()
    local conveyorPos = getPizzaDeliveryStation()
    local parkingPos = Vector3.new(1148, 14, 265)

    -- STAGE 1: We do not have pizza -> Go to Pizza Planet conveyor, dismount moped, take box
    if not hasPizza then
        -- If currently riding moped, drive to the parking lot in front of Pizza Planet
        if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
            smoothGlideTo(parkingPos + Vector3.new(0, 1.5, 0), Config.MopedSpeed or 95)
            task.wait(0.2)
            -- Hop off moped so it stays parked outside
            humanoid.Jump = true
            task.wait(0.35)
        end

        -- Walk/glide inside Pizza Planet directly to the conveyor belt (the one in the photo!)
        smoothGlideTo(conveyorPos + Vector3.new(0, 2.5, 0), Config.DeliverySpeed)
        task.wait(0.25)

        -- Interact with conveyor / boxes to take pizza box
        pcall(function()
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local pPos = prompt.Parent and prompt.Parent:GetPivot().Position
                    if pPos and (pPos - conveyorPos).Magnitude < 16 then
                        triggerPrompt(prompt)
                    end
                end
            end
            for _, part in pairs(Workspace:GetPartBoundsInRadius(conveyorPos, 16)) do
                interactWithObject(part)
                if part.Parent then interactWithObject(part.Parent) end
            end
        end)
        task.wait(Config.WorkDelay or 0.5)

    -- STAGE 2: We have pizza -> Go out to moped, mount it, and ride to customer!
    else
        -- Equip pizza if in backpack
        if pizzaTool and pizzaTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
            humanoid:EquipTool(pizzaTool)
            task.wait(0.15)
        end

        -- Check if mounted on moped; if not, go out to moped and climb on
        local isMounted = (humanoid.SeatPart ~= nil and humanoid.SeatPart:IsA("VehicleSeat"))
        if not isMounted then
            local mopedSeat = findNearestMoped()
            if mopedSeat then
                mountMoped(mopedSeat)
                task.wait(0.3)
            end
        end

        -- Ride moped directly to active customer
        local customer, custPrompt = getActiveDeliveryCustomer()
        if customer then
            local targetPos = nil
            if customer.FindFirstChild and (customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head")) then
                local custRoot = customer:FindFirstChild("HumanoidRootPart") or customer:FindFirstChild("Head")
                targetPos = custRoot.Position + (custRoot.CFrame.LookVector * 3.5) + Vector3.new(0, 1.5, 0)
            elseif customer.Position then
                targetPos = customer.Position + Vector3.new(0, 1.5, 0)
            else
                targetPos = customer:GetPivot().Position + Vector3.new(0, 1.5, 0)
            end

            if targetPos then
                smoothGlideTo(targetPos, Config.DeliverySpeed)
                task.wait(0.3)
                if custPrompt then
                    triggerPrompt(custPrompt)
                end
                interactWithObject(customer)
                task.wait(Config.WorkDelay or 0.6)
            end
        else
            task.wait(0.6)
        end
    end
end

-- Pizza Delivery Background Worker Loop
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoDelivery and getgenv().PullZBloxburgLoaded then
            pcall(runPizzaDeliveryStep)
        end
    end
end))

-- Delivery Moped Turbo Boost Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if Config.MopedBoost and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
            local seat = humanoid.SeatPart
            seat.MaxSpeed = Config.MopedSpeed or 95
            seat.Torque = 2.5
            seat.TurnSpeed = 2.5
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
