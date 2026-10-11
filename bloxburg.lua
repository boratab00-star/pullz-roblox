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
    HairdresserDelay = 0.8,
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
    AutoPizzaSpot = nil,
    AutoPizzaPrompt = nil,
    AutoMopedSpot = nil,
    AutoMopedSeat = nil,
    HasPizza = false,
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
    CurrentHairWorkstation = nil,
    HairServedCount = 0,
    CapturedHairRemote = nil,
    CapturedHairArgs = nil,
    CapturedHairStation = nil,
    IsHairLearned = false,
    HairLearningMode = false,
    CapturedDoneButton = nil,
    CapturedDonePos = nil,
    LearnedClickPos = nil,
    LastHairLogTime = 0,
    LastHairServiceTime = 0
}

-- Metamethod Hook for Hairdresser Network Capture
pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                local sName = tostring(self.Name):lower()
                local isHairCandidate = false

                if sName:find("hair") or sName:find("stylez") or sName:find("job") or sName:find("work") or sName:find("station") or sName:find("order") then
                    isHairCandidate = true
                end

                for _, a in ipairs(args) do
                    local as = tostring(a):lower()
                    if as:find("hair") or as:find("order") or as:find("finish") or as:find("done") or as:find("station") then
                        isHairCandidate = true
                    end
                    if type(a) == "table" then
                        for k, v in pairs(a) do
                            local ks = tostring(k):lower()
                            local vs = tostring(v):lower()
                            if ks:find("order") or vs:find("order") or ks:find("hair") or vs:find("hair") or ks:find("done") or vs:find("finish") or ks:find("station") then
                                isHairCandidate = true
                            end
                        end
                    end
                end

                if State.HairLearningMode then
                    print(string.format("[LEARN REMOTE] %s pe '%s' (%s)", method, self.Name, self.ClassName))
                    if isHairCandidate or self.Parent == game:GetService("ReplicatedStorage") then
                        State.CapturedHairRemote = self
                        State.CapturedHairArgs = args
                        print("[PullZ Hairdresser] ✅ Remote capturat: " .. tostring(self:GetFullName()))
                    end
                elseif isHairCandidate then
                    State.CapturedHairRemote = self
                    State.CapturedHairArgs = args
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

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

-- Forward Declarations for Delivery Engine & Hairdresser
local simulatePressE, triggerPrompt, triggerNearbyPrompts, interactWithObject
local findDeliveryTarget, getActiveDeliveryCustomer, findNearestMoped, hasPizzaBox, smoothGlideTo, mountMoped, runPizzaDeliveryStep, findConveyorPromptAndPos
local isRealPlayer, debugLog, hairDebugLog
local runHairdresserStep, findHairdresserWorkstations, getNearestHairWorkstation, teleportToStylez, scanHairdresserDebug, scanMirrorGuiNow, startHairLearning

-- ==================== [CATEGORY 1: AUTO JOBS] ====================
createHeader(jobsPage, "💇 Hairdresser Auto Farm (Stylez Studio - 100% Auto)")

-- Hairdresser Status Card (Real-Time Live Status)
local hairStatusCard = Instance.new("Frame")
hairStatusCard.Size = UDim2.new(1, 0, 0, 42)
hairStatusCard.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
hairStatusCard.BorderSizePixel = 0
hairStatusCard.Parent = jobsPage

local hairStatusCorner = Instance.new("UICorner")
hairStatusCorner.CornerRadius = UDim.new(0, 6)
hairStatusCorner.Parent = hairStatusCard

local hairStatusLabel = Instance.new("TextLabel")
hairStatusLabel.Size = UDim2.new(1, -20, 1, 0)
hairStatusLabel.Position = UDim2.new(0, 12, 0, 0)
hairStatusLabel.BackgroundTransparency = 1
hairStatusLabel.Text = "✂️ Status: Oprit (Așază-te la scaun și apasă Sincronizează)"
hairStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
hairStatusLabel.Font = Enum.Font.GothamMedium
hairStatusLabel.TextSize = 11
hairStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
hairStatusLabel.Parent = hairStatusCard

hairDebugLog = function(tag, message, color)
    local timeStr = os.date("%H:%M:%S")
    local line = string.format("[PullZ Hairdresser][%s][%s] %s", timeStr, tag, message)
    print(line)
    if hairStatusLabel then
        pcall(function()
            hairStatusLabel.Text = string.format("[%s] %s", tag, message)
            if color then
                hairStatusLabel.TextColor3 = color
            else
                hairStatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            end
        end)
    end
end

createToggle(jobsPage, "🚀 START / STOP Auto Hairdresser", Config.AutoHairdresser, function(s)
    Config.AutoHairdresser = s
    if s then
        if State.IsHairLearned then
            hairDebugLog("START", "Auto Hairdresser PORNIT! Stație sincronizată, servesc clienții automat. 💇", Color3.fromRGB(100, 255, 150))
        else
            hairDebugLog("START", "Auto Hairdresser PORNIT! Dacă nu preia singur, apasă '🎯 Sincronizează'. 💇", Color3.fromRGB(255, 200, 100))
        end
    else
        hairDebugLog("STOP", "Auto Hairdresser OPRIT. 🛑", Color3.fromRGB(255, 100, 100))
    end
end)

createButton(jobsPage, "🎯 Sincronizează (Fă 1 Cut Manual - Auto-Learn)", function()
    if startHairLearning then
        startHairLearning()
    else
        State.HairLearningMode = true
        State.IsHairLearned = false
        Config.AutoHairdresser = true
        hairDebugLog("ÎNVĂȚARE", "👉 Pune-te la scaun (în First Person), tunde 1 client și apasă Done!", Color3.fromRGB(255, 200, 100))
    end
end)

createButton(jobsPage, "🔍 Scanează GUI Oglindă (F9 Debug - La Scaun)", function()
    if scanMirrorGuiNow then
        scanMirrorGuiNow()
    end
end)

createButton(jobsPage, "📍 Teleport la Stylez Hair Studio (Scaun Liber)", function()
    if teleportToStylez then
        teleportToStylez()
    end
end)

createSlider(jobsPage, "⏱️ Viteza de Servire (Delay Secunde)", 0.2, 2.5, Config.HairdresserDelay or 0.8, function(val)
    Config.HairdresserDelay = val
end)

createHeader(jobsPage, "🍕 Pizza Delivery Automation (Alternativ)")

-- Status Card (Real-Time Live Status)
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
spotStatusLabel.Text = "⚡ Status: Oprit (Apasă START pentru livrare automată)"
spotStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
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

-- 1 SINGLE TOGGLE: START / STOP Auto Pizza Delivery
createToggle(jobsPage, "🚀 START / STOP Auto Pizza Delivery", Config.AutoDelivery, function(s)
    Config.AutoDelivery = s
    if s then
        debugLog("START", "Auto Pizza Delivery PORNIT! Mod complet autonom activat. 🚀", Color3.fromRGB(100, 255, 150))
    else
        debugLog("STOP", "Auto Pizza Delivery OPRIT. 🛑", Color3.fromRGB(255, 100, 100))
    end
end)

createSlider(jobsPage, "⚡ Delivery Safe Speed (MPH)", 16, 38, Config.DeliverySpeed or 38, function(val)
    Config.DeliverySpeed = math.clamp(val, 16, 38)
    Config.MopedSpeed = Config.DeliverySpeed
end)

createButton(jobsPage, "📜 Deschide Consola F9 (Live Debugger)", function()
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("DevConsoleVisible", true)
    end)
    debugLog("DEBUGGER", "Consola F9 deschisă! Urmărește pașii în timp real.", Color3.fromRGB(100, 255, 150))
end)

createButton(jobsPage, "🎯 Test / Scanează Săgeata Acum (Debug F9)", function()
    local pos, obj = getArrowPosition()
    if pos then
        debugLog("DEBUG", string.format("✅ Săgeată detectată la: X: %d, Y: %d, Z: %d (Nume: '%s')", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z), tostring(obj and obj.Name or "Indicator")), Color3.fromRGB(100, 255, 150))
    else
        debugLog("DEBUG", "❌ Nicio săgeată găsită! Afișez candidații în F9...", Color3.fromRGB(255, 100, 100))
        local foundCount = 0
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                local isY = (o.Color.R > 0.65 and o.Color.G > 0.55 and o.Color.B < 0.45) or (o.BrickColor and o.BrickColor.Name:lower():find("yellow"))
                if isY and o.CanCollide == false then
                    foundCount = foundCount + 1
                    if foundCount <= 10 then
                        print(string.format("[DEBUG CANDIDATE] Nume: '%s' | Părinte: '%s' | Pos: %s", o.Name, o.Parent and o.Parent.Name or "nil", tostring(o.Position)))
                    end
                end
            end
        end
    end
end)

createButton(jobsPage, "🔄 Resetează Cache Livrare", function()
    State.AutoPizzaSpot = nil
    State.AutoPizzaPrompt = nil
    State.AutoMopedSeat = nil
    State.AutoMopedSpot = nil
    State.CachedCustomer = nil
    State.CachedPrompt = nil
    State.CachedArrowPos = nil
    State.CachedArrowObj = nil
    State.HasPizza = false
    debugLog("RESET", "Cache resetat complet! Se va re-detecta totul automat.", Color3.fromRGB(255, 200, 100))
end)

createHeader(jobsPage, "Other Jobs & Automations")

createToggle(jobsPage, "Auto Pizza Baker (Dough & Oven)", Config.AutoBaker, function(s)
    Config.AutoBaker = s
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
    if State.AutoPizzaSpot then
        return State.AutoPizzaSpot
    end
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
-- Ultra-Fast Active Customer / Arrow Finder
local function findArrowInPlayerGui()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pgui then return nil, nil end

    for _, desc in ipairs(pgui:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Adornee then
            local ad = desc.Adornee
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
                    if p and p.Y > 3 then
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
                if vn:find("target") or vn:find("customer") or vn:find("arrow") or vn:find("order") or valn:find("customer") or valn:find("arrow") then
                    local p = (val:IsA("BasePart") and val.Position) or val:GetPivot().Position
                    if p and p.Y > 3 then
                        return p, val
                    end
                end
            end
        end

        if desc:IsA("Vector3Value") and desc.Value and desc.Value.Y > 3 then
            local vn = desc.Name:lower()
            if vn:find("target") or vn:find("customer") or vn:find("arrow") or vn:find("dest") or vn:find("order") then
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

    -- Method 1: Check Camera for 3D Arrow
    if Camera then
        for _, obj in ipairs(Camera:GetDescendants()) do
            if not isRealPlayer(obj) then
                local n = obj.Name:lower()
                if n:find("arrow") or n:find("pointer") or n:find("indicator") or n:find("waypoint") or n:find("target") or n:find("marker") or n:find("order") then
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local p = obj:GetPivot().Position
                        if p.Y > 3 then
                            State.CachedArrowPos = p
                            State.CachedArrowObj = obj
                            return p, obj
                        end
                    end
                end
            end
        end
    end

    -- Method 2: Check PlayerGui for Arrow or BillboardGui Adornee
    local pguiPos, pguiObj = findArrowInPlayerGui()
    if pguiPos and not isRealPlayer(pguiObj) then
        State.CachedArrowPos = pguiPos
        State.CachedArrowObj = pguiObj
        return pguiPos, pguiObj
    end

    -- Method 3: Deep Scan Workspace for ANY instance explicitly named Arrow / Target / Marker / Waypoint / Order / Dropoff / Deliver
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not isRealPlayer(obj) and obj ~= char then
            local n = obj.Name:lower()
            local isArrow = n:find("arrow") or n:find("pointer") or n:find("waypoint") or n:find("dropoff") or
                            n:find("orderarrow") or n:find("deliveryarrow") or n:find("marker") or
                            (n:find("target") and not n:find("part") and not n:find("hit"))

            if isArrow then
                if obj:IsA("BasePart") then
                    local p = obj.Position
                    if p.Y > 3 then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj
                        return p, obj
                    end
                elseif obj:IsA("Model") then
                    local p = obj:GetPivot().Position
                    if p.Y > 3 then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj
                        return p, obj
                    end
                elseif obj:IsA("BillboardGui") and obj.Adornee and not isRealPlayer(obj.Adornee) then
                    local p = (obj.Adornee:IsA("BasePart") and obj.Adornee.Position) or (obj.Adornee:IsA("Model") and obj.Adornee:GetPivot().Position)
                    if p and p.Y > 3 then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj.Adornee
                        return p, obj.Adornee
                    end
                end
            end
        end
    end

    -- Method 4: Visual Scan for 3D Yellow Neon Marker in Workspace (Matches the Bloxburg visual arrow!)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isRealPlayer(obj) and obj.Parent ~= char then
            local c = obj.Color
            local isYellow = (c.R > 0.60 and c.G > 0.50 and c.B < 0.50) or (obj.BrickColor and obj.BrickColor.Name:lower():find("yellow"))
            if isYellow and obj.Size.Magnitude > 0.5 then
                local p = obj.Position
                if p.Y > 3 and (p - myPos).Magnitude > 1.5 then
                    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                    if not (parentName:find("lamp") or parentName:find("light") or parentName:find("headlight") or parentName:find("car") or parentName:find("vehicle") or parentName:find("moped")) then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj
                        return p, obj
                    end
                end
            end
        end
    end

    -- Method 5: Scan for NPCs with Delivery Prompt in Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not isRealPlayer(obj) and obj ~= char then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local act = prompt.ActionText:lower()
                local objt = prompt.ObjectText:lower()
                if act:find("give") or act:find("deliver") or act:find("hand") or act:find("pizza") or
                   objt:find("customer") or objt:find("pizza") or objt:find("order") then
                    local p = obj:GetPivot().Position
                    if p.Y > 3 then
                        State.CachedArrowPos = p
                        State.CachedArrowObj = obj
                        return p, obj
                    end
                end
            end
        end
    end

    return nil, nil
end

local function getAllNPCs()
    local now = tick()
    if State.CachedNPCs and (now - (State.LastNPCSearch or 0) < 2.0) then
        return State.CachedNPCs
    end
    State.LastNPCSearch = now

    local char = LocalPlayer.Character
    local npcs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and not isRealPlayer(obj) then
            if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("Head") then
                local p = obj:GetPivot().Position
                if p.Y > 3 then
                    table.insert(npcs, obj)
                end
            end
        end
    end
    State.CachedNPCs = npcs
    return npcs
end

-- Conveyor / Pizza Pick-up Auto-Detection
findConveyorPromptAndPos = function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    -- 1. Scan nearby Workspace for ProximityPrompts related to pizza / taking box
    local nearbyParts = Workspace:GetPartBoundsInRadius(hrp.Position, 120)
    for _, part in ipairs(nearbyParts) do
        for _, p in ipairs(part:GetChildren()) do
            if p:IsA("ProximityPrompt") then
                local act = p.ActionText:lower()
                local objt = p.ObjectText:lower()
                if act:find("take") or act:find("grab") or act:find("pick") or
                   objt:find("pizza") or objt:find("box") or objt:find("order") then
                    return p, part.Position
                end
            end
        end
    end

    -- 2. Scan Workspace for conveyor models/parts
    for _, part in ipairs(nearbyParts) do
        local n = part.Name:lower()
        if (n:find("conveyor") or n:find("shelf") or n:find("station")) and not isRealPlayer(part) then
            local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
            return prompt, part.Position
        end
    end

    return nil, nil
end

-- Unified Active Customer / Delivery Target Finder
findDeliveryTarget = function()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil end
    local myPos = hrp.Position

    local now = tick()
    if State.CachedCustomer and State.CachedCustomer.Parent and not isRealPlayer(State.CachedCustomer) and (now - (State.LastCustomerSearch or 0) < 1.0) then
        local cHead = State.CachedCustomer:FindFirstChild("Head") or State.CachedCustomer:FindFirstChild("HumanoidRootPart") or (State.CachedCustomer:IsA("BasePart") and State.CachedCustomer)
        local cPos = (cHead and cHead.Position) or (State.CachedCustomer:IsA("Model") and State.CachedCustomer:GetPivot().Position)
        if cPos and cPos.Y > 5 then
            return cPos, State.CachedCustomer, State.CachedPrompt
        end
    end
    State.LastCustomerSearch = now

    -- 1. Check for 3D Delivery Arrow or Gui Marker
    local arrowPos, arrowObj = getArrowPosition()
    if arrowObj and isRealPlayer(arrowObj) then
        arrowPos, arrowObj = nil, nil
    end

    -- 2. Check all NPCs in Workspace (Strictly excluding real players)
    local npcs = getAllNPCs()

    -- Strategy A: If arrowPos was found, locate NPC within 40 studs of arrow
    if arrowPos then
        local bestNpc, bestDist = nil, 40
        for _, npc in ipairs(npcs) do
            if not isRealPlayer(npc) then
                local np = npc:GetPivot().Position
                local d = (Vector3.new(np.X, 0, np.Z) - Vector3.new(arrowPos.X, 0, arrowPos.Z)).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestNpc = npc
                end
            end
        end

        if bestNpc then
            local prompt = bestNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
            State.CachedCustomer = bestNpc
            State.CachedPrompt = prompt
            return bestNpc:GetPivot().Position, bestNpc, prompt
        end

        -- If no NPC near arrow, the arrow itself is the delivery target (Never discard it!)
        State.CachedCustomer = arrowObj
        return arrowPos, arrowObj, nil
    end

    -- Strategy B: Check NPCs with explicit Delivery indicator (BillboardGui / Arrow on head / Prompt)
    for _, npc in ipairs(npcs) do
        if not isRealPlayer(npc) then
            local np = npc:GetPivot().Position
            if np.Y > 3 and (np - myPos).Magnitude > 1.5 then
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
                        return np, npc, prompt
                    end
                end

                if hasIndicator then
                    State.CachedCustomer = npc
                    State.CachedPrompt = prompt
                    return np, npc, prompt
                end
            end
        end
    end

    return nil, nil, nil
end

getActiveDeliveryCustomer = function()
    local targetPos, targetObj, prompt = findDeliveryTarget()
    return targetObj, prompt
end

-- Fast Nearest Moped Locator
findNearestMoped = function()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- 1. Check if player is already seated
    if humanoid and humanoid.SeatPart and (humanoid.SeatPart:IsA("VehicleSeat") or humanoid.SeatPart:IsA("Seat")) then
        State.AutoMopedSeat = humanoid.SeatPart
        return humanoid.SeatPart
    end

    -- 2. Check cached seat if still valid and unoccupied
    if State.AutoMopedSeat and State.AutoMopedSeat.Parent and (State.AutoMopedSeat:IsA("VehicleSeat") or State.AutoMopedSeat:IsA("Seat")) then
        if State.AutoMopedSeat.Occupant == nil or State.AutoMopedSeat.Occupant == humanoid then
            return State.AutoMopedSeat
        end
    end

    -- 3. Search in radius around character or conveyor
    local checkSpots = {hrp.Position}
    if State.AutoPizzaSpot then table.insert(checkSpots, State.AutoPizzaSpot) end
    if State.AutoMopedSpot then table.insert(checkSpots, State.AutoMopedSpot) end

    for _, spot in ipairs(checkSpots) do
        local nearby = Workspace:GetPartBoundsInRadius(spot, 60)
        for _, part in ipairs(nearby) do
            if part:IsA("VehicleSeat") and (part.Occupant == nil or part.Occupant == humanoid) then
                State.AutoMopedSeat = part
                State.AutoMopedSpot = part.Position
                return part
            end
        end
    end

    -- 4. Deep search Workspace for VehicleSeat
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
        State.AutoMopedSeat = seat
        State.AutoMopedSpot = seat.Position
        return seat
    end

    return nil
end

-- Ultra-Fast Pizza Box Detection (Accurate - Zero False Positives)
hasPizzaBox = function()
    local char = LocalPlayer.Character
    if not char then return false, nil end

    -- 1. Check tools in Character or Backpack
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if n:find("pizza") or (n:find("box") and not n:find("hitbox") and not n:find("bounding")) or n:find("delivery") or n:find("order") then
                return true, item
            end
        end
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("pizza") or (n:find("box") and not n:find("hitbox") and not n:find("bounding")) or n:find("delivery") or n:find("order") then
                    return true, item
                end
            end
        end
    end

    -- 2. Check held models/parts in character explicitly named pizza or box
    -- CRITICAL FIX: Strictly exclude Hitbox, BoundingBox, Limbs, Welds, and invisible parts!
    for _, item in ipairs(char:GetChildren()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and not item:IsA("Accessory") then
            local n = item.Name:lower()
            local isIgnored = n:find("root") or n:find("torso") or n:find("head") or n:find("arm") or n:find("leg") or
                              n:find("hitbox") or n:find("bounding") or n:find("collider") or n:find("collision") or
                              n:find("weld") or n:find("animate") or n:find("humanoid")
            if not isIgnored then
                if n == "pizza" or n == "pizzabox" or n:find("pizzabox") or (n:find("pizza") and not n:find("dough")) or (n == "box" or n == "order") then
                    if item:IsA("BasePart") and item.Transparency < 1 and item.Size.Magnitude < 8 then
                        return true, item
                    elseif item:IsA("Model") then
                        return true, item
                    end
                end
            end
        end
    end

    -- 3. Check hands / arms specifically for held pizza box
    local hands = {char:FindFirstChild("RightHand"), char:FindFirstChild("Right Arm"), char:FindFirstChild("LeftHand"), char:FindFirstChild("Left Arm")}
    for _, h in ipairs(hands) do
        if h then
            for _, c in ipairs(h:GetChildren()) do
                if (c:IsA("BasePart") or c:IsA("Model")) and not c:IsA("Accessory") then
                    local cn = c.Name:lower()
                    if (cn:find("pizza") or cn:find("box")) and not (cn:find("hitbox") or cn:find("bounding") or cn:find("weld")) then
                        if c:IsA("BasePart") and c.Transparency < 1 and c.Size.Magnitude < 8 then
                            return true, c
                        elseif c:IsA("Model") then
                            return true, c
                        end
                    end
                end
            end
        end
    end

    -- 4. Check State.HasPizza flag (set only upon successful pickup, cleared on delivery)
    if State.HasPizza == true then
        return true, nil
    end

    return false, nil
end

-- Smooth Safe Glide Function (Zero Physics Conflict, Zero Lag, Zero Kicks, Zero Detached Errors)
smoothGlideTo = function(targetPos, speed)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Anti-Void & NaN Safety
    if not targetPos or typeof(targetPos) ~= "Vector3" then return end
    if targetPos.Y < 5 or targetPos.Y ~= targetPos.Y or targetPos.X ~= targetPos.X or targetPos.Z ~= targetPos.Z then return end

    local isVehicle = false
    local seat = humanoid and humanoid.SeatPart
    local mopedModel = nil
    local rootPart = hrp

    if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
        isVehicle = true
        mopedModel = seat:FindFirstAncestorOfClass("Model")
        rootPart = seat
    elseif humanoid and humanoid.Sit then
        -- Find seat near character
        for _, p in ipairs(Workspace:GetPartBoundsInRadius(hrp.Position, 6)) do
            if p:IsA("VehicleSeat") or p:IsA("Seat") then
                isVehicle = true
                seat = p
                mopedModel = p:FindFirstAncestorOfClass("Model")
                rootPart = p
                break
            end
        end
    end

    -- If humanoid is sitting but no seat found, DO NOT move hrp.CFrame directly (causes Detached error!)
    if humanoid and humanoid.Sit and not isVehicle then
        return
    end

    -- Safe speed clamp: Moped 36-38 max, on foot 20-24 max (Eliminates server kicks!)
    local maxSafe = isVehicle and 38 or 24
    speed = math.clamp(speed or (isVehicle and (Config.MopedSpeed or 38) or (Config.DeliverySpeed or 22)), 14, maxSafe)

    local currentPos = rootPart.Position
    local dist = (targetPos - currentPos).Magnitude
    if dist < 2.5 then return end

    local duration = math.clamp(dist / speed, 0.2, 12)

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
        local lookDir = lookTarget - nextPos
        local targetCFrame
        if lookDir.Magnitude > 0.5 then
            targetCFrame = CFrame.new(nextPos, lookTarget)
        else
            targetCFrame = CFrame.new(nextPos)
        end

        if isVehicle and seat then
            if seat.AssemblyLinearVelocity then seat.AssemblyLinearVelocity = Vector3.zero end
            if seat.AssemblyAngularVelocity then seat.AssemblyAngularVelocity = Vector3.zero end

            if mopedModel and mopedModel.PrimaryPart then
                mopedModel:PivotTo(targetCFrame)
            else
                seat.CFrame = targetCFrame
            end
        elseif not humanoid.Sit then
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
    if isVehicle and seat then
        if mopedModel and mopedModel.PrimaryPart then
            mopedModel:PivotTo(CFrame.new(targetPos))
        else
            seat.CFrame = targetCFrame
        end
    elseif not humanoid.Sit then
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

    -- Already seated?
    if humanoid.SeatPart == mopedSeat or humanoid.Sit then
        return true
    end

    debugLog("MOPED", "Merg lângă moped...")
    smoothGlideTo(mopedSeat.Position + Vector3.new(0, 1.2, 0), Config.DeliverySpeed or 22)
    task.wait(0.15)

    -- Trigger ProximityPrompts on moped
    local mopedModel = mopedSeat:FindFirstAncestorOfClass("Model")
    if mopedModel then
        for _, p in ipairs(mopedModel:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                triggerPrompt(p)
            end
        end
    end
    triggerNearbyPrompts(mopedSeat.Position, 8)
    simulatePressE(0.35)
    task.wait(0.2)

    -- Sit via Seat:Sit
    if not humanoid.SeatPart and not humanoid.Sit then
        pcall(function()
            mopedSeat:Sit(humanoid)
        end)
        task.wait(0.2)
    end

    local seated = (humanoid.SeatPart ~= nil) or humanoid.Sit
    if seated then
        debugLog("MOPED", "Urcat pe moped cu succes! ✅", Color3.fromRGB(100, 255, 150))
    else
        debugLog("MOPED", "⚠️ Reîncerc să urc pe moped...", Color3.fromRGB(255, 180, 80))
    end

    return seated
end

-- 100% Autonomous Pizza Delivery Loop
runPizzaDeliveryStep = function()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    local hasPizza, pizzaTool = hasPizzaBox()
    local isMounted = (humanoid.SeatPart ~= nil and (humanoid.SeatPart:IsA("VehicleSeat") or humanoid.SeatPart:IsA("Seat"))) or humanoid.Sit

    -- Auto-detect conveyor location if not set
    if not State.AutoPizzaSpot then
        local foundPrompt, foundPos = findConveyorPromptAndPos()
        if foundPos then
            State.AutoPizzaSpot = foundPos
            State.AutoPizzaPrompt = foundPrompt
            debugLog("AUTO", string.format("Banda de pizza detectată automat la (X: %d, Z: %d) ✅", math.floor(foundPos.X), math.floor(foundPos.Z)), Color3.fromRGB(100, 255, 150))
        else
            -- If player is currently on foot at Pizza Planet, use current position as conveyor anchor
            if not isMounted then
                State.AutoPizzaSpot = hrp.Position
                debugLog("AUTO", "Punctul de preluare pizza setat automat la poziția ta actuală ✅", Color3.fromRGB(100, 255, 150))
            end
        end
    end
    local boxSpot = State.AutoPizzaSpot or State.SavedPizzaSpot or hrp.Position

    -- Auto-detect moped location
    local mopedSeat = findNearestMoped()
    local mopedSpot = (mopedSeat and mopedSeat.Position) or State.AutoMopedSpot or (boxSpot + Vector3.new(-25, 0, 15))

    -- =========================================================================
    -- STAGE 1: Nu ai pizza -> Mergi la bandă și ia cutia de pizza
    -- =========================================================================
    if not hasPizza then
        debugLog("PASUL 1", "Nu ai pizza! Merg la banda de pizza...", Color3.fromRGB(255, 180, 80))

        -- Dacă ești pe moped, condu până afară lângă pizzerie și coboară
        if isMounted then
            debugLog("MOPED", "Cobor de pe moped pentru a intra la bandă...")
            smoothGlideTo(mopedSpot + Vector3.new(0, 1.2, 0), Config.MopedSpeed or 38)
            task.wait(0.15)
            humanoid.Sit = false
            humanoid.Jump = true
            task.wait(0.25)
        end

        -- Mergi pe jos la banda de pizza
        smoothGlideTo(boxSpot + Vector3.new(0, 1.2, 0), Config.DeliverySpeed or 22)
        task.wait(0.1)

        -- Interacționează cu banda de pizza ([E] / ProximityPrompt / Click)
        debugLog("PASUL 1", "Apăs [E] la banda de pizza...")
        if State.AutoPizzaPrompt and State.AutoPizzaPrompt.Parent then
            triggerPrompt(State.AutoPizzaPrompt)
        end
        triggerNearbyPrompts(boxSpot, 10)
        simulatePressE(0.35)

        -- Simulează click în centrul ecranului (pentru cutiile de pe bandă)
        pcall(function()
            VirtualUser:CaptureController()
            local vp = Camera.ViewportSize
            VirtualUser:ClickButton1(Vector2.new(vp.X / 2, vp.Y / 2))
        end)
        task.wait(0.2)
        simulatePressE(0.25)
        task.wait(0.3)

        if hasPizzaBox() then
            State.HasPizza = true
            debugLog("PASUL 1", "Cutie de pizza luată cu succes! ✅", Color3.fromRGB(100, 255, 150))
        else
            debugLog("PASUL 1", "Aștept cutia să fie luată de pe bandă...", Color3.fromRGB(255, 200, 100))
        end

        task.wait(Config.WorkDelay or 0.3)

    -- =========================================================================
    -- STAGE 2: Ai pizza -> Urcă pe moped și livrează la client!
    -- =========================================================================
    else
        debugLog("PASUL 2", "Ai pizza! Mă pregătesc de plecare la client...", Color3.fromRGB(100, 200, 255))

        -- Echipează pizza dacă este în ghiozdan (Backpack)
        if pizzaTool and pizzaTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
            humanoid:EquipTool(pizzaTool)
            task.wait(0.1)
        end

        -- Verifică dacă ești pe moped; dacă nu, urcă pe moped!
        if not humanoid.Sit then
            debugLog("MOPED", "Merg spre moped...")
            mopedSeat = findNearestMoped()
            if mopedSeat then
                mountMoped(mopedSeat)
                task.wait(0.2)
            else
                debugLog("MOPED", "Mopedul nu a fost găsit în apropiere, merg pe jos...")
            end
        end

        isMounted = (humanoid.SeatPart ~= nil and (humanoid.SeatPart:IsA("VehicleSeat") or humanoid.SeatPart:IsA("Seat"))) or humanoid.Sit
        local speed = isMounted and (Config.MopedSpeed or 38) or (Config.DeliverySpeed or 22)

        -- Caută ținta de livrare (client NPC sau săgeată)
        debugLog("CLIENT", "Caut clientul / săgeata de livrare...")
        local targetPos, targetObj, targetPrompt = findDeliveryTarget()

        if targetPos and targetPos.Y > 5 then
            local dist = math.floor((targetPos - hrp.Position).Magnitude)
            local targetName = (targetObj and targetObj.Name) or "Client"
            debugLog("NAVIGARE", string.format("Glisez spre '%s' la %d MPH (Distanță: %d studs)... 🛵", targetName, speed, dist), Color3.fromRGB(100, 200, 255))

            -- Glisează lin până la client
            smoothGlideTo(targetPos + Vector3.new(0, 1.2, 0), speed)
            task.wait(0.25)

            -- Predă pizza clientului ([E] / Prompt)
            debugLog("LIVRARE", "Am ajuns la client! Predau pizza... 📦", Color3.fromRGB(255, 200, 100))
            simulatePressE(0.4)
            if targetPrompt then
                triggerPrompt(targetPrompt)
            end
            triggerNearbyPrompts(targetPos, 12)
            simulatePressE(0.3)

            task.wait(Config.WorkDelay or 0.4)
            State.HasPizza = false
            State.CachedCustomer = nil
            State.CachedArrowPos = nil
            debugLog("LIVRARE", "🎉 Pizza livrată cu succes! Încep următoarea cursă! 🚀", Color3.fromRGB(100, 255, 150))
        else
            debugLog("AȘTEPTARE", "⚠️ Săgeata sau clientul se generează... Aștept 0.5s...", Color3.fromRGB(255, 180, 80))
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

-- =========================================================================
-- HAIRDRESSER / STYLEZ HAIR STUDIO AUTOMATION SUITE
-- =========================================================================

-- Find all Hairdresser Workstations in Workspace
findHairdresserWorkstations = function()
    local stations = {}

    -- 1. Check known Bloxburg hierarchy paths
    pcall(function()
        local loc = Workspace:FindFirstChild("Environment")
        if loc then loc = loc:FindFirstChild("Locations") end
        if loc then loc = loc:FindFirstChild("StylezHairStudio") end
        if loc then
            local wsFolder = loc:FindFirstChild("HairdresserWorkstations") or loc:FindFirstChild("Workstations") or loc
            for _, child in ipairs(wsFolder:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    table.insert(stations, child)
                end
            end
        end
    end)
    if #stations > 0 then return stations end

    -- 2. Check direct Workspace children/descendants
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "HairdresserWorkstations" or obj.Name == "HairWorkstations" then
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Model") or child:IsA("Folder") then
                        table.insert(stations, child)
                    end
                end
            end
        end
    end)
    if #stations > 0 then return stations end

    -- 3. Search for any model named workstation or hairdresser
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local on = obj.Name:lower()
                if (on:find("hairdresser") or on:find("stylez")) and (obj:FindFirstChild("Chair") or obj:FindFirstChild("Seat") or obj:FindFirstChild("Occupied") or obj:FindFirstChild("Mirror")) then
                    table.insert(stations, obj)
                end
            end
        end
    end)

    return stations
end

-- Get nearest Hairdresser Workstation to LocalPlayer
getNearestHairWorkstation = function()
    local char = LocalPlayer.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local stations = findHairdresserWorkstations()
    local closest, closestDist = nil, math.huge

    for _, st in ipairs(stations) do
        local part = st.PrimaryPart or st:FindFirstChild("Chair") or st:FindFirstChild("Seat") or st:FindFirstChild("Mirror") or st:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = st
            end
        end
    end
    return closest, closestDist
end

-- Teleport directly to Stylez Hair Studio workstation
teleportToStylez = function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local station, dist = getNearestHairWorkstation()
    if station then
        local targetPart = station.PrimaryPart or station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            -- Position behind chair facing mirror
            hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 3, 3), targetPart.Position)
            hairDebugLog("STYLEZ", "Teleportat la postul de lucru Stylez! 💇", Color3.fromRGB(100, 255, 150))
            return
        end
    end

    -- Fallback: Search for StylezHairStudio Model pivot
    local found = false
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("stylezhair") or obj.Name == "StylezHairStudio" then
                hrp.CFrame = obj:GetPivot() + Vector3.new(0, 4, 0)
                hairDebugLog("STYLEZ", "Teleportat la Stylez Hair Studio! 💇", Color3.fromRGB(100, 255, 150))
                found = true
                return
            end
        end
    end)

    if not found then
        -- Default Bloxburg town coordinates near salon
        hrp.CFrame = CFrame.new(-115, 14, -110)
        hairDebugLog("STYLEZ", "Teleportat în zona Stylez Hair Studio (Centru)! 💇", Color3.fromRGB(100, 255, 150))
    end
end

-- Debug Scanner for Stylez Hairdresser
scanHairdresserDebug = function()
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("DevConsoleVisible", true)
    end)
    hairDebugLog("SCAN", "Încep scanarea salonului... Detalii în consola F9!", Color3.fromRGB(100, 200, 255))
    print("---------------- [HAIRDRESSER DEBUG SCAN] ----------------")
    local stations = findHairdresserWorkstations()
    print(string.format("[HAIR DEBUG] Posturi de lucru găsite în Workspace: %d", #stations))
    for i, st in ipairs(stations) do
        local occ = st:FindFirstChild("Occupied")
        local occVal = occ and tostring(occ.Value) or "nil"
        local pos = st:GetPivot().Position
        print(string.format("  [%d] Nume: '%s' | Părinte: '%s' | Occupied: %s | Pos: %s", i, st.Name, st.Parent and st.Parent.Name or "nil", occVal, tostring(pos)))
        for _, c in ipairs(st:GetChildren()) do
            print(string.format("     -> Obiect: '%s' (%s)", c.Name, c.ClassName))
        end
    end

    -- Scan PlayerGui
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        print("[HAIR DEBUG] Scanare PlayerGui pentru interfețe Job/Hair:")
        for _, gui in ipairs(pg:GetChildren()) do
            local gName = gui.Name:lower()
            if gName:find("hair") or gName:find("style") or gName:find("job") or gName:find("work") then
                print(string.format("  -> Găsit GUI: '%s' (Visible: %s)", gui.Name, tostring(gui.Enabled or true)))
                for _, el in ipairs(gui:GetDescendants()) do
                    if el:IsA("GuiButton") or el:IsA("TextLabel") then
                        print(string.format("     -> Element: '%s' (%s) Text: '%s'", el.Name, el.ClassName, el:IsA("TextLabel") and el.Text or (el:IsA("TextButton") and el.Text or "")))
                    end
                end
            end
        end
    end
    print("----------------------------------------------------------")
end

-- Helper to verify if a GUI element is rendered and visible on screen
local function isGuiElementOnScreen(obj)
    if not obj or not obj.Parent then return false end
    if not obj.Visible then return false end
    if obj.AbsoluteSize.X < 2 or obj.AbsoluteSize.Y < 2 then return false end

    local sg = obj:FindFirstAncestorOfClass("ScreenGui")
    if sg and not sg.Enabled then return false end

    local p = obj.Parent
    while p and p:IsA("GuiObject") do
        if not p.Visible then return false end
        p = p.Parent
    end

    return true
end

-- Hardware + Virtual + firesignal Multi-Engine Clicker
local function clickGuiButton(btn, optionalPos)
    local absPos = optionalPos or (btn and (btn.AbsolutePosition + (btn.AbsoluteSize / 2))) or Vector2.new(960, 540)
    local x = math.floor(absPos.X)
    local y = math.floor(absPos.Y)

    -- 1. VirtualInputManager (Movere mouse pe buton ÎNAINTE de click!)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseMoveEvent(x, y, game)
        task.wait(0.03)
        vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.04)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    -- 2. firesignal (Direct executor signal firing)
    if btn then
        pcall(function()
            if firesignal then
                firesignal(btn.MouseButton1Down)
                firesignal(btn.MouseButton1Click)
                firesignal(btn.MouseButton1Up)
                firesignal(btn.Activated)
            end
        end)
    end

    -- 3. VirtualUser fallback
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(x, y))
    end)
end

-- Find active Done Button on screen
local function findActiveDoneButton()
    if State.CapturedDoneButton and isGuiElementOnScreen(State.CapturedDoneButton) then
        return State.CapturedDoneButton
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end

    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("GuiButton") and isGuiElementOnScreen(desc) then
            local bName = desc.Name:lower()
            local bText = (desc:IsA("TextButton") and desc.Text:lower()) or ""
            if bName == "done" or bText == "done" or bName:find("done") or bText:find("done") or
               bName:find("finish") or bText:find("finish") or bName:find("gata") or bText:find("gata") or
               bName:find("orderdone") or bText:find("order done") or bName:find("submit") then
                State.CapturedDoneButton = desc
                State.IsHairLearned = true
                return desc
            end
        end
    end

    return nil
end

-- Interactive Manual 1-Cut Auto-Learning Listener
local hairInputConn = nil
local hairButtonConnections = {}

startHairLearning = function()
    State.HairLearningMode = true
    State.IsHairLearned = false
    Config.AutoHairdresser = true
    State.CapturedDoneButton = nil
    State.LearnedClickPos = nil
    State.LastHairServiceTime = tick()

    hairDebugLog("ÎNVĂȚARE", "👉 Tunde 1 client și apasă DONE! Scriptul va captura automat click-ul.", Color3.fromRGB(255, 200, 100))

    if hairInputConn then pcall(function() hairInputConn:Disconnect() end) hairInputConn = nil end
    for _, conn in ipairs(hairButtonConnections) do pcall(function() conn:Disconnect() end) end
    hairButtonConnections = {}

    local function onDoneCaptured(btn, clickPos)
        State.CapturedDoneButton = btn
        State.LearnedClickPos = clickPos
        State.IsHairLearned = true
        State.HairLearningMode = false

        local btnName = btn and btn.Name or "Poziție Ecran"
        hairDebugLog("SINCRONIZAT", string.format("🎉 DONE CAPTURAT cu succes! (%s la %d, %d). Preiau AUTO... ✂️", btnName, math.floor(clickPos.X), math.floor(clickPos.Y)), Color3.fromRGB(100, 255, 150))

        if hairInputConn then pcall(function() hairInputConn:Disconnect() end) hairInputConn = nil end
        for _, conn in ipairs(hairButtonConnections) do pcall(function() conn:Disconnect() end) end
        hairButtonConnections = {}
    end

    -- 1. Global Screen Click Listener (Detectează orice click de mouse pe ecran)
    hairInputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if not State.HairLearningMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mPos = UserInputService:GetMouseLocation()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local targetBtn = nil
            local isDoneClick = false

            if pg then
                local objects = pg:GetGuiObjectsAtPosition(mPos.X, mPos.Y)
                for _, obj in ipairs(objects) do
                    if obj:IsA("GuiButton") then
                        targetBtn = obj
                        local bName = obj.Name:lower()
                        local bText = (obj:IsA("TextButton") and obj.Text:lower()) or ""
                        if bName:find("done") or bText:find("done") or bName:find("finish") or bText:find("finish") or bName:find("gata") or bText:find("gata") or bName:find("order") or bName:find("submit") then
                            isDoneClick = true
                            break
                        end
                    end
                end
            end

            -- Dacă este explicit butonul Done sau text Done:
            if isDoneClick or (targetBtn and (targetBtn.Name:lower():find("done") or (targetBtn:IsA("TextButton") and targetBtn.Text:lower():find("done")))) then
                onDoneCaptured(targetBtn, mPos)
            else
                -- Dacă a apăsat o săgeată de stil sau culoare, doar notificăm fără să oprim modul de învățare
                if targetBtn then
                    hairDebugLog("CLICK", string.format("Ajustat: '%s' (Apasă pe DONE când finalizezi frizura)", targetBtn.Name), Color3.fromRGB(200, 220, 255))
                else
                    -- Click direct pe ecran
                    hairDebugLog("CLICK", string.format("Click la (%d, %d)... Apasă pe DONE!", math.floor(mPos.X), math.floor(mPos.Y)), Color3.fromRGB(200, 220, 255))
                end
            end
        end
    end)

    -- 2. Direct GuiButton Listeners în PlayerGui
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local function hookBtn(btn)
            if not btn:IsA("GuiButton") then return end
            local bName = btn.Name:lower()
            local bText = (btn:IsA("TextButton") and btn.Text:lower()) or ""
            local isDoneCandidate = bName:find("done") or bText:find("done") or bName:find("finish") or bText:find("finish") or bName:find("gata") or bText:find("gata") or bName:find("submit")

            local function onTrigger()
                if State.HairLearningMode then
                    if isDoneCandidate then
                        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
                        onDoneCaptured(btn, pos)
                    else
                        hairDebugLog("CLICK", string.format("Ajustat: '%s' (Apasă pe DONE când finalizezi frizura)", btn.Name), Color3.fromRGB(200, 220, 255))
                    end
                end
            end

            local c1 = btn.MouseButton1Click:Connect(onTrigger)
            local c2 = btn.Activated:Connect(onTrigger)
            table.insert(hairButtonConnections, c1)
            table.insert(hairButtonConnections, c2)
        end

        for _, desc in ipairs(pg:GetDescendants()) do
            hookBtn(desc)
        end

        local cAdd = pg.DescendantAdded:Connect(function(desc)
            if desc:IsA("GuiButton") then
                hookBtn(desc)
            end
        end)
        table.insert(hairButtonConnections, cAdd)
    end
end

-- Comprehensive Diagnostic Scanner for Mirror GUI in F9 Console
scanMirrorGuiNow = function()
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("DevConsoleVisible", true)
    end)
    hairDebugLog("SCAN GUI", "Scanare completă a ecranului în consolă F9...", Color3.fromRGB(100, 200, 255))
    print("================== [HAIRDRESSER DIAGNOSTIC SCAN] ==================")
    print(string.format("[STATUS] IsHairLearned: %s | LearningMode: %s | Total Servit: %d",
        tostring(State.IsHairLearned), tostring(State.HairLearningMode), State.HairServedCount or 0))
    if State.CapturedDoneButton then
        print(string.format("[STATUS] CapturedDoneButton: '%s' (Pe ecran: %s)", State.CapturedDoneButton:GetFullName(), tostring(isGuiElementOnScreen(State.CapturedDoneButton))))
    else
        print("[STATUS] CapturedDoneButton: nil")
    end
    if State.LearnedClickPos then
        print(string.format("[STATUS] LearnedClickPos: (%d, %d)", math.floor(State.LearnedClickPos.X), math.floor(State.LearnedClickPos.Y)))
    else
        print("[STATUS] LearnedClickPos: nil")
    end
    if State.CapturedHairRemote then
        print(string.format("[STATUS] CapturedHairRemote: '%s'", State.CapturedHairRemote:GetFullName()))
    else
        print("[STATUS] CapturedHairRemote: nil")
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        print("[HAIR GUI] PlayerGui nu este accesibil!")
        return
    end

    print("\n--- SCREEN GUIS ---")
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then
            print(string.format("  -> ScreenGui: '%s' (Enabled: %s, DisplayOrder: %d)", g.Name, tostring(g.Enabled), g.DisplayOrder))
        end
    end

    print("\n--- BUTOANE ȘI TEXTE VIZIBILE PE ECRAN ---")
    local foundCount = 0
    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("GuiButton") or obj:IsA("TextLabel") or obj:IsA("ImageLabel")) and isGuiElementOnScreen(obj) then
            foundCount = foundCount + 1
            local textVal = (obj:IsA("TextLabel") and obj.Text) or (obj:IsA("TextButton") and obj.Text) or ""
            local pos = obj.AbsolutePosition
            local sz = obj.AbsoluteSize
            print(string.format("  [%s] '%s' | Părinte: '%s' | Pos: (%d, %d) | Size: (%d, %d) | Text: '%s'",
                obj.ClassName, obj.Name, obj.Parent and obj.Parent.Name or "nil", pos.X, pos.Y, sz.X, sz.Y, textVal))
        end
    end
    print(string.format("[HAIR GUI] Total elemente GUI vizibile pe ecran: %d", foundCount))

    print("\n--- REMOTE-URI REPLICATEDSTORAGE (JOB / WORK / HAIR) ---")
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        for _, r in ipairs(rep:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local rn = r.Name:lower()
                if rn:find("hair") or rn:find("stylez") or rn:find("job") or rn:find("work") or rn:find("station") or rn:find("order") then
                    print(string.format("  -> Remote: '%s' (%s) | Cale: %s", r.Name, r.ClassName, r:GetFullName()))
                end
            end
        end
    end)
    print("====================================================================")
end

-- Core Auto Hairdresser Step Function (Smart 1-Cut Learning & Auto-Repeat)
runHairdresserStep = function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    -- 1. Modul de învățare activ: așteaptă ca utilizatorul să facă 1 cut manual
    if State.HairLearningMode and not State.IsHairLearned then
        if tick() - (State.LastHairLogTime or 0) > 4 then
            State.LastHairLogTime = tick()
            hairDebugLog("MOD ÎNVĂȚARE", "👉 Tunde manual 1 client și apasă DONE pe ecran!", Color3.fromRGB(255, 200, 100))
        end
        return
    end

    -- 2. Cooldown între clienți (Bloxburg are tranziție de 2.0 - 3.0 secunde între clienți când unul pleacă și altul vine)
    local timeSinceLast = tick() - (State.LastHairServiceTime or 0)
    local minDelay = math.clamp(Config.HairdresserDelay or 2.5, 1.5, 5.0)
    if timeSinceLast < minDelay then
        return
    end

    -- 3. Caută butonul Done sau poziția ecran capturată
    local doneBtn = findActiveDoneButton()
    local clickPos = State.LearnedClickPos

    if doneBtn or clickPos then
        hairDebugLog("CLIENT", "Client la oglindă! Finalizez comanda cu Done... ✂️", Color3.fromRGB(100, 200, 255))

        -- Apasă butonul Done pe ecran cu triplu motor de click
        clickGuiButton(doneBtn, clickPos)

        -- Dacă avem Remote-ul capturat prin hookmetamethod, apelează-l și pe el
        if State.CapturedHairRemote then
            pcall(function()
                if State.CapturedHairArgs then
                    State.CapturedHairRemote:FireServer(table.unpack(State.CapturedHairArgs))
                else
                    State.CapturedHairRemote:FireServer()
                end
            end)
        end

        State.LastHairServiceTime = tick()
        State.HairServedCount = (State.HairServedCount or 0) + 1
        hairDebugLog("SUCCES", string.format("🎉 Client servit cu succes! (Total clienți: %d)", State.HairServedCount), Color3.fromRGB(100, 255, 150))

        task.wait(minDelay)
        return
    end

    -- 4. Dacă nu avem nici buton nici poziție capturată:
    if tick() - (State.LastHairLogTime or 0) > 4 then
        State.LastHairLogTime = tick()
        if State.IsHairLearned then
            hairDebugLog("AȘTEPTARE", "Aștept ca următorul client să se așeze pe scaun... ⏳", Color3.fromRGB(200, 200, 220))
        else
            hairDebugLog("AȘTEPTARE", "Așază-te la scaun (în First Person) și apasă '🎯 Sincronizează'!", Color3.fromRGB(255, 200, 100))
        end
    end
end

-- Hairdresser Background Worker Loop
local isRunningHairStep = false
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(Config.HairdresserDelay or 0.8)
        if Config.AutoHairdresser and getgenv().PullZBloxburgLoaded and not isRunningHairStep then
            isRunningHairStep = true
            local ok, err = pcall(runHairdresserStep)
            if not ok then
                hairDebugLog("EROARE", tostring(err), Color3.fromRGB(255, 80, 80))
            end
            isRunningHairStep = false
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
