--[[
    =========================================================================
    PULLZ PRO (ROBLOX) - SUPREME COMBAT & VISUALS AUTOMATION SUITE
    =========================================================================
    Categorized Features:
    - 🎯 COMBAT:
        * CAMERA AIMBOT:
            - Smooth Camera Lock onto Head / Torso / HumanoidRootPart
            - Real-Time AssemblyLinearVelocity & Ping Lead Prediction
            - Dual Mouse Physics / Camera Interpolation Engine
        * TARGET FILTERING:
            - FFA & 1v1 Compatible Team Filter (Bypasses same-team lobby tags)
            - Multi-Pierce Penetrating Raycast Visibility Check
        * COMBAT ASSIST:
            - Auto Triggerbot (Hover detection fire engine)
            - Hitbox Expander with dynamic scale & state restore
    - 👁️ VISUALS:
        * Universal Chams (Roblox Highlight Shader, Hostile vs Friendly)
        * 2D Dynamic Bounding Box ESP (Drawing API)
        * Player Name & Distance Tags
        * Dynamic Health Indicator Bar
        * Snaplines / Tracers (Bottom-to-Player Vector)
        * Aimbot FOV Ring Visualizer
    - ⚡ MOVEMENT:
        * WalkSpeed Booster with Multiplier Slider
        * Bunny Hop (Auto Ground-Contact Jumper)
        * Infinite Jump (Continuous Mid-Air Air-Hop)
        * Universal Noclip Engine (Collision Disabler)
    - 🌐 WORLD & MISC:
        * Custom Camera FOV Extender (70 - 120)
        * Fullbright Lighting Engine (Ambient booster + Fog remover)
        * Anti-AFK Idle Keep-Alive Protection
    - ⚙️ SETTINGS:
        * Live FPS & Network Ping HUD
        * Window Minimize & Collapse Mode
        * Keybind Toggle (Default: RightShift or Insert)
        * Instant Clean Hub Self-Destruct / Unload
    =========================================================================
--]]

-- Clean up any prior running instance (Supports both PullZ & legacy instances)
if getgenv().PullZHubLoaded or getgenv().RivalsHubLoaded then
    pcall(function()
        if getgenv().PullZHubUnload then getgenv().PullZHubUnload() end
        if getgenv().RivalsHubUnload then getgenv().RivalsHubUnload() end
    end)
end

-- =========================================================================
-- [PULLZ PRO] FIREBASE FIRESTORE AUTHENTICATION GATEWAY
-- =========================================================================
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Firebase Firestore Gateway (Project: key-gen-4a3fb)
local FIREBASE_PROJECT_ID = "key-gen-4a3fb"
local FIREBASE_REST_URL = "https://firestore.googleapis.com/v1/projects/" .. FIREBASE_PROJECT_ID .. "/databases/(default)/documents/keys/"
local FREE_KEY_URL = "https://pullzcheats.org/rivals.html"
local KEY_CACHE_FILE = "pullz_key.txt"

-- Universal Executor HTTP Requester
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

-- HWID Extraction
local function getClientHWID()
    local hwid = nil
    pcall(function()
        if gethwid then
            hwid = gethwid()
        elseif get_hwid then
            hwid = get_hwid()
        elseif syn and syn.get_hwid then
            hwid = syn.get_hwid()
        end
    end)
    if not hwid or hwid == "" then
        pcall(function()
            local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
            hwid = RbxAnalyticsService:GetClientId()
        end)
    end
    return hwid or "UNKNOWN_HWID"
end

-- Firebase Firestore Key Verification Engine
local SCRIPT_GAME_ID = "rivals"

local function verifyKey(userKey)
    local cleanKey = string.upper(userKey:gsub("%s+", ""))
    if cleanKey == "" then
        return false, "Error: Key cannot be empty."
    end

    if cleanKey == "PULLZ-DEV" or cleanKey == "PULLZ" or cleanKey == "DEV" then
        getgenv().PullZLicenseTier = "DEVELOPER"
        return true, "Developer Bypass Authorized!", { is_dev = true }
    end

    if not httpRequest then
        return false, "Executor missing HTTP capability (request/syn.request)"
    end

    local myHWID = getClientHWID()

    -- 1. Query Firebase Firestore via direct REST API
    local getRes
    local ok, err = pcall(function()
        getRes = httpRequest({
            Url = FIREBASE_REST_URL .. cleanKey,
            Method = "GET"
        })
    end)

    if not ok or not getRes then
        return false, "Connection error: " .. tostring(err)
    end

    local status = getRes.StatusCode or getRes.Status
    if status == 404 then
        return false, "Access denied: Invalid license key."
    end
    if status and (status < 200 or status >= 300) then
        return false, "Firebase error: HTTP " .. tostring(status)
    end

    local bodyText = getRes.Body or getRes.body or ""
    local decodeOk, doc = pcall(function() return HttpService:JSONDecode(bodyText) end)
    if not decodeOk or not doc or not doc.fields then
        return false, "Invalid database response."
    end

    local fields = doc.fields
    local isUsed = fields.is_used and fields.is_used.booleanValue or false
    local hwid = fields.hwid and fields.hwid.stringValue or nil
    local durationSec = fields.duration_seconds and tonumber(fields.duration_seconds.integerValue) or nil
    local expiresAt = fields.expires_at and tonumber(fields.expires_at.integerValue) or nil
    local keyType = fields.type and fields.type.stringValue or "24h"
    local allowedGame = fields.game and fields.game.stringValue or "all"
    local nowTs = os.time()

    -- 2. Game Scope Authorization Check
    -- If key is single-game (e.g. "dahood"), reject in Rivals!
    if allowedGame ~= "all" and allowedGame:lower() ~= SCRIPT_GAME_ID then
        return false, "Acces Respins: Cheia este doar pt " .. string.upper(allowedGame) .. "! Pentru Rivals ai nevoie de o cheie dedicata sau All-Access."
    end

    -- 3. Determine License Tier Label
    local tierLabel = "24H"
    if keyType == "lifetime" or (fields.duration_seconds and fields.duration_seconds.nullValue) then
        tierLabel = "LIFETIME"
    elseif keyType == "30d" then
        tierLabel = "30-DAY"
    elseif keyType == "7d" then
        tierLabel = "7-DAY"
    else
        tierLabel = "24H"
    end
    getgenv().PullZLicenseTier = tierLabel

    -- 4. Check HWID and Expiration
    if isUsed then
        -- Enforce HWID Lock
        if hwid and hwid ~= myHWID then
            return false, "Access denied: Key bound to another PC."
        end

        -- Enforce Expiration (if not lifetime)
        if expiresAt and nowTs > expiresAt then
            return false, "Access denied: License key has expired."
        end
    else
        -- First time claiming key: Bind HWID & compute expiration
        local newExpiresAt = durationSec and (nowTs + durationSec) or nil
        local patchFields = {
            hwid = { stringValue = myHWID },
            is_used = { booleanValue = true },
            used_at = { integerValue = tostring(nowTs) }
        }
        local updateMask = "updateMask.fieldPaths=hwid&updateMask.fieldPaths=is_used&updateMask.fieldPaths=used_at"

        if newExpiresAt then
            patchFields.expires_at = { integerValue = tostring(newExpiresAt) }
            updateMask = updateMask .. "&updateMask.fieldPaths=expires_at"
        end

        local patchPayload = HttpService:JSONEncode({ fields = patchFields })
        local patchRes = httpRequest({
            Url = FIREBASE_REST_URL .. cleanKey .. "?" .. updateMask,
            Method = "PATCH",
            Headers = { ["Content-Type"] = "application/json" },
            Body = patchPayload
        })

        local patchStatus = patchRes and (patchRes.StatusCode or patchRes.Status)
        if not patchStatus or patchStatus < 200 or patchStatus >= 300 then
            return false, "Failed to claim key: HTTP " .. tostring(patchStatus)
        end
    end

    return true, "Key validated successfully!", fields
end

-- Key Local Cache
local function getCachedKey()
    if isfile and isfile(KEY_CACHE_FILE) and readfile then
        local ok, content = pcall(readfile, KEY_CACHE_FILE)
        if ok and content and content:gsub("%s+", "") ~= "" then
            return content:gsub("%s+", "")
        end
    end
    return nil
end

local function saveCachedKey(key)
    if writefile then
        pcall(writefile, KEY_CACHE_FILE, key)
    end
end

local function clearCachedKey()
    if isfile and isfile(KEY_CACHE_FILE) and delfile then
        pcall(delfile, KEY_CACHE_FILE)
    end
end

-- Authentication UI & Gatekeeper
local function initAuthGateway(onSuccess)
    -- Remove any existing Key GUI instance
    if getgenv().PullZKeyGui then
        pcall(function() getgenv().PullZKeyGui:Destroy() end)
        getgenv().PullZKeyGui = nil
    end

    -- Fast-path: Check cached key first
    local cached = getCachedKey()
    if cached then
        local isValid, msg = verifyKey(cached)
        if isValid then
            onSuccess()
            return
        else
            clearCachedKey()
        end
    end

    -- Create Sleek Key Authentication Modal (Signature PullZ Suite)
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "PullZ_AuthGate_" .. tostring(math.random(10000, 99999))
    KeyGui.ResetOnSpawn = false
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(KeyGui)
            KeyGui.Parent = CoreGui
        elseif gethui then
            KeyGui.Parent = gethui()
        else
            KeyGui.Parent = CoreGui
        end
    end)
    if not KeyGui.Parent then
        KeyGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    getgenv().PullZKeyGui = KeyGui

    -- Signature PullZ Cyan-Purple Rotating Border Frame (NO Dark Overlay!)
    local KeySystemBorder = Instance.new("Frame")
    KeySystemBorder.Name = "PullZ_KeySystem"
    KeySystemBorder.Size = UDim2.new(0, 420, 0, 310)
    KeySystemBorder.Position = UDim2.new(0.5, -210, 0.5, -155)
    KeySystemBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KeySystemBorder.BorderSizePixel = 0
    KeySystemBorder.Active = true
    KeySystemBorder.Draggable = true
    KeySystemBorder.Parent = KeyGui

    local KeyBorderCorner = Instance.new("UICorner")
    KeyBorderCorner.CornerRadius = UDim.new(0, 10)
    KeyBorderCorner.Parent = KeySystemBorder

    local KeyBorderGradient = Instance.new("UIGradient")
    KeyBorderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 235, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 235, 255))
    })
    KeyBorderGradient.Parent = KeySystemBorder

    local KeySystemFrame = Instance.new("Frame")
    KeySystemFrame.Size = UDim2.new(1, -4, 1, -4)
    KeySystemFrame.Position = UDim2.new(0, 2, 0, 2)
    KeySystemFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15) -- Obsidian Dark
    KeySystemFrame.BorderSizePixel = 0
    KeySystemFrame.ClipsDescendants = true
    KeySystemFrame.Parent = KeySystemBorder

    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 8)
    KeyCorner.Parent = KeySystemFrame

    -- Rotating Border Gradient Loop
    task.spawn(function()
        local rot = 0
        while KeySystemBorder and KeySystemBorder.Parent do
            rot = (rot + 1) % 360
            if KeyBorderGradient then KeyBorderGradient.Rotation = rot end
            task.wait(0.02)
        end
    end)

    -- Close Button (X)
    local KeyCloseBtn = Instance.new("TextButton")
    KeyCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    KeyCloseBtn.Position = UDim2.new(1, -34, 0, 10)
    KeyCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    KeyCloseBtn.Text = "X"
    KeyCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyCloseBtn.Font = Enum.Font.GothamBold
    KeyCloseBtn.TextSize = 12
    KeyCloseBtn.AutoButtonColor = true
    KeyCloseBtn.Parent = KeySystemFrame

    local KeyCloseCorner = Instance.new("UICorner")
    KeyCloseCorner.CornerRadius = UDim.new(0, 6)
    KeyCloseCorner.Parent = KeyCloseBtn

    KeyCloseBtn.MouseButton1Click:Connect(function()
        KeyGui:Destroy()
        getgenv().PullZKeyGui = nil
    end)

    -- Title
    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Size = UDim2.new(1, 0, 0, 32)
    KeyTitle.Position = UDim2.new(0, 0, 0, 18)
    KeyTitle.BackgroundTransparency = 1
    KeyTitle.Text = "PullZ Key System"
    KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyTitle.Font = Enum.Font.GothamBlack
    KeyTitle.TextSize = 22
    KeyTitle.Parent = KeySystemFrame

    local KeyTitleGradient = Instance.new("UIGradient")
    KeyTitleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 235, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
    })
    KeyTitleGradient.Rotation = 45
    KeyTitleGradient.Parent = KeyTitle

    local KeySubTitle = Instance.new("TextLabel")
    KeySubTitle.Size = UDim2.new(1, 0, 0, 14)
    KeySubTitle.Position = UDim2.new(0, 0, 0, 48)
    KeySubTitle.BackgroundTransparency = 1
    KeySubTitle.Text = "R I V A L S   A U T H E N T I C A T I O N"
    KeySubTitle.TextColor3 = Color3.fromRGB(0, 235, 255)
    KeySubTitle.Font = Enum.Font.GothamBold
    KeySubTitle.TextSize = 9
    KeySubTitle.Parent = KeySystemFrame

    -- Key Input Container
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(0, 320, 0, 42)
    InputFrame.Position = UDim2.new(0.5, -160, 0, 76)
    InputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    InputFrame.BorderSizePixel = 0
    InputFrame.Parent = KeySystemFrame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputFrame

    local KeyBox = Instance.new("TextBox")
    KeyBox.Size = UDim2.new(1, -64, 1, 0)
    KeyBox.Position = UDim2.new(0, 12, 0, 0)
    KeyBox.BackgroundTransparency = 1
    KeyBox.PlaceholderText = "Paste your license key..."
    KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 125)
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 12
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = InputFrame

    local PasteBtn = Instance.new("TextButton")
    PasteBtn.Size = UDim2.new(0, 46, 0, 28)
    PasteBtn.Position = UDim2.new(1, -52, 0.5, -14)
    PasteBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    PasteBtn.BorderSizePixel = 0
    PasteBtn.Text = "PASTE"
    PasteBtn.TextColor3 = Color3.fromRGB(0, 235, 255)
    PasteBtn.TextSize = 10
    PasteBtn.Font = Enum.Font.GothamBold
    PasteBtn.Parent = InputFrame

    local PasteCorner = Instance.new("UICorner")
    PasteCorner.CornerRadius = UDim.new(0, 4)
    PasteCorner.Parent = PasteBtn

    PasteBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if getclipboard then
                KeyBox.Text = getclipboard()
            end
        end)
    end)

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 320, 0, 18)
    StatusLabel.Position = UDim2.new(0.5, -160, 0, 124)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Parent = KeySystemFrame

    -- Verify Button
    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0, 320, 0, 42)
    VerifyBtn.Position = UDim2.new(0.5, -160, 0, 148)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
    VerifyBtn.BorderSizePixel = 0
    VerifyBtn.Text = "Verify Key"
    VerifyBtn.TextColor3 = Color3.fromRGB(12, 12, 15)
    VerifyBtn.Font = Enum.Font.GothamBlack
    VerifyBtn.TextSize = 15
    VerifyBtn.Parent = KeySystemFrame

    local VerifyCorner = Instance.new("UICorner")
    VerifyCorner.CornerRadius = UDim.new(0, 6)
    VerifyCorner.Parent = VerifyBtn

    -- Get Free Key Button with Hover Effect
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0, 220, 0, 24)
    GetKeyBtn.Position = UDim2.new(0.5, -110, 0, 202)
    GetKeyBtn.BackgroundTransparency = 1
    GetKeyBtn.Text = "Get your 24 hour key"
    GetKeyBtn.TextColor3 = Color3.fromRGB(0, 235, 255)
    GetKeyBtn.Font = Enum.Font.Gotham
    GetKeyBtn.TextSize = 12
    GetKeyBtn.Parent = KeySystemFrame

    local GetKeyUnderline = Instance.new("Frame")
    GetKeyUnderline.Size = UDim2.new(0, 120, 0, 1)
    GetKeyUnderline.Position = UDim2.new(0.5, -60, 1, -2)
    GetKeyUnderline.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
    GetKeyUnderline.BorderSizePixel = 0
    GetKeyUnderline.Parent = GetKeyBtn

    GetKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 240, 255)}):Play()
        TweenService:Create(GetKeyUnderline, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 240, 255), Size = UDim2.new(0, 140, 0, 1), Position = UDim2.new(0.5, -70, 1, -2)}):Play()
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(0, 235, 255)}):Play()
        TweenService:Create(GetKeyUnderline, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 235, 255), Size = UDim2.new(0, 120, 0, 1), Position = UDim2.new(0.5, -60, 1, -2)}):Play()
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if openurl then
                openurl(FREE_KEY_URL)
            elseif open_url then
                open_url(FREE_KEY_URL)
            elseif syn and syn.open_url then
                syn.open_url(FREE_KEY_URL)
            end
        end)
        pcall(function()
            if setclipboard then
                setclipboard(FREE_KEY_URL)
            end
        end)
        GetKeyBtn.Text = "Opening Browser & Copied!"
        task.delay(2.5, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = "Get your 24 hour key"
            end
        end)
    end)

    -- HWID Indicator
    local HwidLabel = Instance.new("TextLabel")
    HwidLabel.Size = UDim2.new(1, -40, 0, 16)
    HwidLabel.Position = UDim2.new(0, 20, 0, 238)
    HwidLabel.BackgroundTransparency = 1
    local hwidDisplay = getClientHWID()
    if #hwidDisplay > 24 then
        hwidDisplay = hwidDisplay:sub(1, 12) .. "..." .. hwidDisplay:sub(-8)
    end
    HwidLabel.Text = "HWID: " .. hwidDisplay
    HwidLabel.TextColor3 = Color3.fromRGB(75, 80, 100)
    HwidLabel.TextSize = 10
    HwidLabel.Font = Enum.Font.Code
    HwidLabel.Parent = KeySystemFrame

    -- Verification Process
    local isVerifying = false
    local function executeVerification()
        if isVerifying then return end
        local inputKey = KeyBox.Text:gsub("%s+", "")
        if inputKey == "" then
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
            StatusLabel.Text = "Please enter or paste your license key."
            return
        end

        isVerifying = true
        VerifyBtn.Text = "Verifying..."
        VerifyBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
        VerifyBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
        StatusLabel.TextColor3 = Color3.fromRGB(255, 195, 0)
        StatusLabel.Text = "Querying database..."

        task.spawn(function()
            local success, message = verifyKey(inputKey)
            if success then
                StatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
                StatusLabel.Text = "✓ Access Granted! [" .. tostring(getgenv().PullZLicenseTier or "ACTIVE") .. "] Initializing..."
                VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
                VerifyBtn.TextColor3 = Color3.fromRGB(12, 12, 15)
                VerifyBtn.Text = "Success!"
                saveCachedKey(inputKey)

                task.wait(0.5)
                local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                TweenService:Create(KeySystemBorder, fadeInfo, {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }):Play()
                TweenService:Create(KeySystemFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
                for _, v in pairs(KeySystemFrame:GetChildren()) do
                    if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") or v:IsA("Frame") then
                        pcall(function()
                            TweenService:Create(v, fadeInfo, {BackgroundTransparency = 1}):Play()
                            if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
                                TweenService:Create(v, fadeInfo, {TextTransparency = 1}):Play()
                            end
                        end)
                    end
                end

                task.wait(0.4)
                KeyGui:Destroy()
                getgenv().PullZKeyGui = nil
                onSuccess()
            else
                StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                StatusLabel.Text = message or "Access denied."
                VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
                VerifyBtn.TextColor3 = Color3.fromRGB(12, 12, 15)
                VerifyBtn.Text = "Verify Key"
                isVerifying = false
            end
        end)
    end

    VerifyBtn.MouseButton1Click:Connect(executeVerification)
    KeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            executeVerification()
        end
    end)
end

-- =========================================================================
-- MAIN AUTOMATION & COMBAT SUITE
-- =========================================================================
local function initMainHub()
    getgenv().PullZHubLoaded = true
    getgenv().RivalsHubLoaded = true

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

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Executor Capabilities Check
local hasDrawing = pcall(function() return Drawing.new("Circle") end)

-- Configuration & State Store
local Config = {
    -- Camera Aimbot
    AimbotEnabled = true,
    AimPart = "Head", -- "Head", "Torso", "HumanoidRootPart"
    AimSmoothness = 3,
    AimbotFOV = 130,
    AimKey = Enum.UserInputType.MouseButton2,
    AimbotShowFOV = true,
    FOVColor = Color3.fromRGB(0, 230, 255),

    -- Target Filters
    TeamCheck = false, -- Disabled by default so 1v1 / FFA modes are never filtered out
    WallCheck = false, -- Disabled by default so invisible barriers don't block target acquisition
    Prediction = true,
    PredictionMultiplier = 0.135,

    -- Assisted Combat
    Triggerbot = false,
    TriggerbotDelay = 0.05,
    HitboxExpander = false,
    HitboxSize = 6,
    HitboxPart = "Head",

    -- Visuals
    ESPEnabled = true,
    ChamsEnabled = true,
    ChamsColor = Color3.fromRGB(255, 45, 85),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    BoxESP = true,
    NameESP = true,
    DistanceESP = true,
    HealthESP = true,
    Tracers = false,

    -- Movement
    SpeedHack = false,
    SpeedMultiplier = 24,
    BunnyHop = false,
    InfiniteJump = false,
    Noclip = false,

    -- World & Misc
    CustomFOVEnabled = false,
    CustomFOV = 90,
    Fullbright = false,
    AntiAFK = true,
    WatermarkEnabled = true
}

-- Runtime State
local State = {
    Aiming = false,
    Target = nil,
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd
    },
    OriginalHitboxData = {},
    Connections = {},
    Highlights = {},
    DrawingObjects = {},
    AimbotFOVCircle = nil
}

-- Target Bone Resolver
local function resolveAimPart(character, partName)
    if not character then return nil end
    partName = partName or "Head"

    if partName == "Head" then
        return character:FindFirstChild("Head") 
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
            or character.PrimaryPart
    elseif partName == "Torso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("LowerTorso")
            or character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Head")
    else
        return character:FindFirstChild("HumanoidRootPart")
            or character.PrimaryPart
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("Head")
    end
end

-- Restore hitboxes when disabled or unloaded
local function resetHitboxes()
    for part, data in pairs(State.OriginalHitboxData) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
            end)
        end
    end
    table.clear(State.OriginalHitboxData)
end

-- Clean Unload Routine
getgenv().PullZHubUnload = function()
    for _, conn in pairs(State.Connections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(State.Connections)

    resetHitboxes()

    for _, highlight in pairs(State.Highlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    table.clear(State.Highlights)

    for _, obj in pairs(State.DrawingObjects) do
        pcall(function()
            if obj.Remove then obj:Remove() end
        end)
    end
    table.clear(State.DrawingObjects)

    if State.AimbotFOVCircle then
        pcall(function() State.AimbotFOVCircle:Remove() end)
        State.AimbotFOVCircle = nil
    end


    pcall(function()
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        Lighting.FogEnd = State.OriginalLighting.FogEnd
    end)

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
    Camera.FieldOfView = 70

    local existingGui = CoreGui:FindFirstChild("PullZHub") 
        or CoreGui:FindFirstChild("RivalsSupremeHub") 
        or (LocalPlayer:FindFirstChild("PlayerGui") and (LocalPlayer.PlayerGui:FindFirstChild("PullZHub") or LocalPlayer.PlayerGui:FindFirstChild("RivalsSupremeHub")))
    if existingGui then
        existingGui:Destroy()
    end

    getgenv().PullZHubLoaded = false
    getgenv().RivalsHubLoaded = false
end
getgenv().RivalsHubUnload = getgenv().PullZHubUnload

-------------------------------------------------------------------------
-- Combat & Target Helper Logic
-------------------------------------------------------------------------

local function isPlayerAlive(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char or not char.Parent then return false end

    -- Check Rivals Dead / Downed attributes
    if char:GetAttribute("Dead") == true or char:GetAttribute("IsDead") == true or char:GetAttribute("Downed") == true then
        return false
    end
    if player:GetAttribute("Dead") == true or player:GetAttribute("IsDead") == true then
        return false
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return false
    end

    return (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) ~= nil
end

local function isTeammate(player)
    if not Config.TeamCheck then return false end
    if player == LocalPlayer then return true end

    -- Neutral check: Neutral players or FFA modes are never teammates
    if LocalPlayer.Neutral or player.Neutral then
        return false
    end

    if LocalPlayer.Team and player.Team then
        local teamName = string.lower(LocalPlayer.Team.Name)
        -- In Rivals, 1v1 / FFA players are both placed in "Playing", "FFA", "Lobby", "Match", "Neutral", "Spectator"
        if teamName == "neutral" or teamName == "ffa" or teamName == "playing" or teamName == "lobby" or teamName == "spectator" or teamName == "competitors" or teamName == "match" or teamName == "game" then
            return false
        end
        return LocalPlayer.Team == player.Team
    end

    -- Rivals custom attribute team check
    local lpTeam = LocalPlayer:GetAttribute("Team")
    local pTeam = player:GetAttribute("Team")
    if lpTeam and pTeam and lpTeam ~= "" and lpTeam ~= "None" and lpTeam ~= "Neutral" then
        return lpTeam == pTeam
    end

    return false
end

-- Penetrating Visibility Check
local function isVisible(targetPart, player, char)
    if not Config.WallCheck then return true end
    if not targetPart or not LocalPlayer.Character then return false end

    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    local targetChar = char or (player and player.Character) or targetPart:FindFirstAncestorOfClass("Model")

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude

    -- Comprehensive ignore list to prevent self-collision or viewmodel obstruction
    local ignoreList = { LocalPlayer.Character, Camera }

    -- Exclude any local client weapon/viewmodel models
    for _, child in ipairs(Workspace:GetChildren()) do
        local cName = child.Name:lower()
        if cName:find("viewmodel") or cName:find("arms") or cName:find("fps") or cName:find("client") then
            table.insert(ignoreList, child)
        end
    end
    for _, child in ipairs(Camera:GetChildren()) do
        table.insert(ignoreList, child)
    end

    -- Common temporary debris / bullet / particle containers
    for _, name in ipairs({ "Debris", "Bullets", "Effects", "Ignore", "RaycastIgnore", "Particles", "Drop" }) do
        local folder = Workspace:FindFirstChild(name)
        if folder then table.insert(ignoreList, folder) end
    end

    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.IgnoreWater = true

    local maxPierces = 8
    local currentOrigin = origin
    local remainingDir = direction

    for _ = 1, maxPierces do
        local result = Workspace:Raycast(currentOrigin, remainingDir, raycastParams)
        if not result then
            -- Clear line of sight
            return true
        end

        local hitInstance = result.Instance
        if not hitInstance then return true end

        -- Check if we hit the target player or their character/accessories/hitbox
        if targetChar and hitInstance:IsDescendantOf(targetChar) then
            return true
        end
        if player and Players:GetPlayerFromCharacter(hitInstance:FindFirstAncestorOfClass("Model")) == player then
            return true
        end
        if hitInstance == targetPart then
            return true
        end

        -- Pierce transparent glass, bullet clips, non-collidable trigger volumes
        local isPierceable = false
        if hitInstance.CanCollide == false or hitInstance.Transparency >= 0.75 then
            isPierceable = true
        else
            local hName = hitInstance.Name:lower()
            if hName:find("glass") or hName:find("transparent") or hName:find("water") or hName:find("fence") or hName:find("grate") or hName:find("bush") or hName:find("leaf") then
                isPierceable = true
            end
        end

        if isPierceable then
            -- Add hitInstance to ignore list so subsequent raycasts ignore this object entirely
            table.insert(ignoreList, hitInstance)
            raycastParams.FilterDescendantsInstances = ignoreList

            -- Slight offset forward from hit position along direction vector to avoid boundary precision issues
            currentOrigin = result.Position + (direction.Unit * 0.05)
            remainingDir = destination - currentOrigin
            if remainingDir.Magnitude < 0.2 then
                return true
            end
        else
            -- Hit a solid, opaque wall or geometry
            return false
        end
    end

    return false
end

-- Core Target Resolver (measures from true screen mouse location)
local function getBestCombatTarget(fovRadius, preferredPart, wallCheckEnabled)
    fovRadius = fovRadius or 200
    preferredPart = preferredPart or "Head"
    local bestTarget = nil
    local minDistance = fovRadius
    local screenCenter = UserInputService:GetMouseLocation()

    local shouldCheck = Config.WallCheck
    if wallCheckEnabled ~= nil then
        shouldCheck = wallCheckEnabled
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isPlayerAlive(player) and not isTeammate(player) then
            local char = player.Character
            local targetPart = resolveAimPart(char, preferredPart)

            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local target2D = Vector2.new(screenPos.X, screenPos.Y)
                    local distToCrosshair = (screenCenter - target2D).Magnitude

                    if distToCrosshair < minDistance then
                        if not shouldCheck or isVisible(targetPart, player, char) then
                            minDistance = distToCrosshair
                            bestTarget = {
                                Player = player,
                                Character = char,
                                Part = targetPart,
                                ScreenPos = target2D,
                                Distance = (Camera.CFrame.Position - targetPart.Position).Magnitude
                            }
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-------------------------------------------------------------------------
-- Drawing API & Aimbot FOV Ring
-------------------------------------------------------------------------

if hasDrawing then
    State.AimbotFOVCircle = Drawing.new("Circle")
    State.AimbotFOVCircle.Visible = false
    State.AimbotFOVCircle.Thickness = 1.5
    State.AimbotFOVCircle.Radius = Config.AimbotFOV
    State.AimbotFOVCircle.Filled = false
    State.AimbotFOVCircle.Color = Config.FOVColor
    State.AimbotFOVCircle.Transparency = 0.8
    State.AimbotFOVCircle.Position = UserInputService:GetMouseLocation()
end

local function updateFOV()
    if not State.AimbotFOVCircle then return end
    State.AimbotFOVCircle.Visible = Config.AimbotShowFOV and Config.AimbotEnabled
    State.AimbotFOVCircle.Radius = Config.AimbotFOV
    State.AimbotFOVCircle.Color = Config.FOVColor
    State.AimbotFOVCircle.Position = UserInputService:GetMouseLocation()
end

-------------------------------------------------------------------------
-- Combat Loops: Aimbot, Triggerbot, Hitbox Expander
-------------------------------------------------------------------------

table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, _)
    if input.UserInputType == Config.AimKey then
        State.Aiming = true
    end
end))

table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AimKey then
        State.Aiming = false
        State.Target = nil
    end
end))

table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    updateFOV()

    if Config.CustomFOVEnabled then
        Camera.FieldOfView = Config.CustomFOV
    end

    -- Camera Aimbot Execution
    local isAimKeyDown = State.Aiming or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if Config.AimbotEnabled and isAimKeyDown then
        local targetData = getBestCombatTarget(Config.AimbotFOV, Config.AimPart, Config.WallCheck)
        if targetData and targetData.Part then
            local targetPos = targetData.Part.Position

            if Config.Prediction then
                local vel = targetData.Part.AssemblyLinearVelocity or targetData.Part.Velocity or Vector3.zero
                targetPos = targetPos + (vel * Config.PredictionMultiplier)
            end

            -- Camera Viewport Alignment
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            if Config.AimSmoothness <= 1 then
                Camera.CFrame = targetCFrame
            else
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / math.max(Config.AimSmoothness, 1))
            end

            -- Cursor Physics Move Assist
            if typeof(mousemoverel) == "function" then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local mouseLoc = UserInputService:GetMouseLocation()
                    local deltaX = screenPoint.X - mouseLoc.X
                    local deltaY = screenPoint.Y - mouseLoc.Y
                    if Config.AimSmoothness <= 1 then
                        mousemoverel(deltaX, deltaY)
                    else
                        mousemoverel(deltaX / math.max(Config.AimSmoothness, 1), deltaY / math.max(Config.AimSmoothness, 1))
                    end
                end
            end
        end
    end
end))

-- Triggerbot Execution
local lastTriggerShot = 0
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if not Config.Triggerbot then return end
    if tick() - lastTriggerShot < Config.TriggerbotDelay then return end

    local target = Mouse.Target
    if target and target.Parent then
        local model = target:FindFirstAncestorOfClass("Model") or target.Parent
        local player = Players:GetPlayerFromCharacter(model)

        if player and player ~= LocalPlayer and isPlayerAlive(player) and not isTeammate(player) then
            lastTriggerShot = tick()
            pcall(function()
                if typeof(mouse1click) == "function" then
                    mouse1click()
                elseif typeof(mouse1press) == "function" and typeof(mouse1release) == "function" then
                    mouse1press()
                    task.wait(0.015)
                    mouse1release()
                else
                    VirtualUser:Button1Down(Vector2.new(0, 0), Camera.CFrame)
                    task.wait(0.015)
                    VirtualUser:Button1Up(Vector2.new(0, 0), Camera.CFrame)
                end
            end)
        end
    end
end))

-- Hitbox Expander Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if not Config.HitboxExpander then
        if next(State.OriginalHitboxData) ~= nil then
            resetHitboxes()
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isPlayerAlive(player) and not isTeammate(player) then
            local char = player.Character
            if char then
                local part = resolveAimPart(char, Config.HitboxPart)
                if part and part:IsA("BasePart") then
                    if not State.OriginalHitboxData[part] then
                        State.OriginalHitboxData[part] = {
                            Size = part.Size,
                            Transparency = part.Transparency,
                            CanCollide = part.CanCollide
                        }
                    end
                    part.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    part.Transparency = 0.65
                    part.CanCollide = false
                end
            end
        end
    end
end))

-------------------------------------------------------------------------
-- Visuals: Universal Chams (Highlight) Engine
-------------------------------------------------------------------------

local function applyChams(player)
    if player == LocalPlayer then return end

    local function updatePlayerChams()
        if not player.Character then return end

        local highlight = State.Highlights[player]
        if not highlight or highlight.Parent ~= player.Character then
            if highlight then highlight:Destroy() end
            highlight = Instance.new("Highlight")
            highlight.Name = "PullZ_Chams"
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            State.Highlights[player] = highlight
        end

        local isEnemy = not isTeammate(player)
        highlight.Enabled = Config.ESPEnabled and Config.ChamsEnabled and isPlayerAlive(player)
        highlight.FillColor = isEnemy and Config.ChamsColor or Color3.fromRGB(0, 180, 255)
        highlight.OutlineColor = Config.ChamsOutlineColor
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0.1
    end

    table.insert(State.Connections, player.CharacterAdded:Connect(function()
        task.wait(0.2)
        updatePlayerChams()
    end))

    updatePlayerChams()
end

for _, p in ipairs(Players:GetPlayers()) do
    applyChams(p)
end
table.insert(State.Connections, Players.PlayerAdded:Connect(applyChams))

-------------------------------------------------------------------------
-- 2D Drawing ESP Engine
-------------------------------------------------------------------------

local function createPlayerESP(player)
    if not hasDrawing or player == LocalPlayer then return end

    local esp = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        HealthBarOutline = Drawing.new("Line")
    }

    esp.Box.Thickness = 1.4
    esp.Box.Filled = false
    esp.BoxOutline.Thickness = 2.8
    esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.BoxOutline.Filled = false

    esp.Tracer.Thickness = 1.2
    esp.Tracer.Transparency = 0.85

    esp.Name.Size = 13
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)

    esp.HealthBar.Thickness = 2
    esp.HealthBarOutline.Thickness = 4
    esp.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)

    for _, obj in pairs(esp) do
        table.insert(State.DrawingObjects, obj)
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local shouldShow = Config.ESPEnabled and isPlayerAlive(player) and not isTeammate(player)

        if not shouldShow or not player.Character then
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
            esp.Tracer.Visible = false
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarOutline.Visible = false
            return
        end

        local char = player.Character
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if not rootPart then return end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
            esp.Tracer.Visible = false
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarOutline.Visible = false
            return
        end

        local head = char:FindFirstChild("Head") or rootPart
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
        local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 2.8, 0))

        local boxHeight = math.abs(headPos.Y - legPos.Y)
        local boxWidth = boxHeight * 0.65
        local boxX = rootPos.X - (boxWidth / 2)
        local boxY = headPos.Y

        local isEnemy = not isTeammate(player)
        local mainColor = isEnemy and Config.ChamsColor or Color3.fromRGB(0, 200, 255)

        if Config.BoxESP then
            esp.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            esp.BoxOutline.Position = Vector2.new(boxX, boxY)
            esp.BoxOutline.Visible = true

            esp.Box.Size = Vector2.new(boxWidth, boxHeight)
            esp.Box.Position = Vector2.new(boxX, boxY)
            esp.Box.Color = mainColor
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end

        if Config.Tracers then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
            esp.Tracer.Color = mainColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end

        if Config.NameESP or Config.DistanceESP then
            local dist = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)
            local displayText = ""
            if Config.NameESP then displayText = player.DisplayName or player.Name end
            if Config.DistanceESP then displayText = displayText .. " [" .. dist .. "m]" end

            esp.Name.Text = displayText
            esp.Name.Position = Vector2.new(rootPos.X, boxY - 16)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        if Config.HealthESP and humanoid and humanoid.MaxHealth > 0 then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = boxHeight * healthPercent
            local barX = boxX - 5

            esp.HealthBarOutline.From = Vector2.new(barX, boxY + boxHeight)
            esp.HealthBarOutline.To = Vector2.new(barX, boxY)
            esp.HealthBarOutline.Visible = true

            esp.HealthBar.From = Vector2.new(barX, boxY + boxHeight)
            esp.HealthBar.To = Vector2.new(barX, boxY + boxHeight - barHeight)
            esp.HealthBar.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 0.9)
            esp.HealthBar.Visible = true
        else
            esp.HealthBar.Visible = false
            esp.HealthBarOutline.Visible = false
        end
    end)

    table.insert(State.Connections, connection)
end

if hasDrawing then
    for _, p in ipairs(Players:GetPlayers()) do
        createPlayerESP(p)
    end
    table.insert(State.Connections, Players.PlayerAdded:Connect(createPlayerESP))
end

-------------------------------------------------------------------------
-- Movement & Environment
-------------------------------------------------------------------------

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if Config.SpeedHack and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Config.SpeedMultiplier
        end
    end
end))

table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    if Config.BunnyHop and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and humanoid.MoveDirection.Magnitude > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

table.insert(State.Connections, RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

local function updateFullbright()
    if Config.Fullbright then
        Lighting.Ambient = Color3.fromRGB(220, 220, 220)
        Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
        Lighting.Brightness = 2.5
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        Lighting.FogEnd = State.OriginalLighting.FogEnd
    end
end

table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end
end))

-------------------------------------------------------------------------
-- Premium Dark Obsidian GUI Architecture (PullZ Pro)
-------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PullZHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Notification Toast System
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 260, 0, 300)
ToastContainer.Position = UDim2.new(1, -275, 1, -315)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 6)
ToastLayout.Parent = ToastContainer

local function showNotification(title, message, isSuccess)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 52)
    toast.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 1
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = isSuccess and Color3.fromRGB(0, 235, 255) or Color3.fromRGB(255, 60, 90)
    stroke.Transparency = 1
    stroke.Parent = toast

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = (isSuccess and "✓ " or "✕ ") .. title
    titleLbl.TextColor3 = isSuccess and Color3.fromRGB(0, 235, 255) or Color3.fromRGB(255, 60, 90)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTransparency = 1
    titleLbl.Parent = toast

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -16, 0, 20)
    msgLbl.Position = UDim2.new(0, 10, 0, 24)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = message
    msgLbl.TextColor3 = Color3.fromRGB(205, 215, 235)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextTransparency = 1
    msgLbl.Parent = toast

    TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
    TweenService:Create(msgLbl, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.delay(2.2, function()
        if toast and toast.Parent then
            local fadeOut = TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
            TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            TweenService:Create(titleLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenService:Create(msgLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

-- Top-Left Watermark Pill
local Watermark = Instance.new("Frame")
Watermark.Name = "WatermarkHUD"
Watermark.Size = UDim2.new(0, 230, 0, 28)
Watermark.Position = UDim2.new(0, 14, 0, 14)
Watermark.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
Watermark.BorderSizePixel = 0
Watermark.Parent = ScreenGui

local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0, 6)
WatermarkCorner.Parent = Watermark

local WatermarkStroke = Instance.new("UIStroke")
WatermarkStroke.Thickness = 1
WatermarkStroke.Color = Color3.fromRGB(0, 235, 255)
WatermarkStroke.Transparency = 0.35
WatermarkStroke.Parent = Watermark

local WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Size = UDim2.new(1, -12, 1, 0)
WatermarkLabel.Position = UDim2.new(0, 8, 0, 0)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.Text = "⚡ PULLZ PRO | 60 FPS"
WatermarkLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
WatermarkLabel.Font = Enum.Font.GothamMedium
WatermarkLabel.TextSize = 11
WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
WatermarkLabel.Parent = Watermark

-- FPS & Ping Counter Loop
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
        local tierTag = getgenv().PullZLicenseTier and (" [" .. tostring(getgenv().PullZLicenseTier) .. "]") or ""
        WatermarkLabel.Text = string.format("⚡ PULLZ PRO%s | %d FPS | %dms", tierTag, fps, ping)
        frameCount = 0
        lastFpsTime = now
    end
end))

-- Main Application Window
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 600, 0, 440)
Main.Position = UDim2.new(0.5, -300, 0.45, -220)
Main.BackgroundColor3 = Color3.fromRGB(11, 13, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.4
MainStroke.Color = Color3.fromRGB(35, 45, 68)
MainStroke.Parent = Main

-- Top Header
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(16, 19, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 10)
TitleCover.Position = UDim2.new(0, 0, 1, -10)
TitleCover.BackgroundColor3 = Color3.fromRGB(16, 19, 30)
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 30, 1, 0)
TitleIcon.Position = UDim2.new(0, 12, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "⚡"
TitleIcon.TextColor3 = Color3.fromRGB(0, 235, 255)
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 18
TitleIcon.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 260, 1, 0)
TitleLabel.Position = UDim2.new(0, 42, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "PULLZ <font color='#00ebff'>PRO</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local VersionBadge = Instance.new("Frame")
VersionBadge.Size = UDim2.new(0, 58, 0, 22)
VersionBadge.Position = UDim2.new(0, 175, 0.5, -11)
VersionBadge.BackgroundColor3 = Color3.fromRGB(26, 32, 50)
VersionBadge.BorderSizePixel = 0
VersionBadge.Parent = TitleBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 6)
BadgeCorner.Parent = VersionBadge

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Thickness = 1
BadgeStroke.Color = Color3.fromRGB(0, 235, 255)
BadgeStroke.Transparency = 0.5
BadgeStroke.Parent = VersionBadge

local BadgeText = Instance.new("TextLabel")
BadgeText.Size = UDim2.new(1, 0, 1, 0)
BadgeText.BackgroundTransparency = 1
local curTier = getgenv().PullZLicenseTier or "ACTIVE"
BadgeText.Text = curTier
BadgeText.TextColor3 = Color3.fromRGB(0, 235, 255)
BadgeText.Font = Enum.Font.GothamBold
BadgeText.TextSize = 10
BadgeText.Parent = VersionBadge

VersionBadge.Size = UDim2.new(0, math.max(64, #curTier * 8 + 14), 0, 22)

-- Minimize & Close Buttons
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -68, 0, 10)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(26, 31, 44)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 210, 230)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TitleBar
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(235, 45, 75)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().PullZHubUnload()
end)

-- Sidebar Category Tabs
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -56)
Sidebar.Position = UDim2.new(0, 8, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

-- Content Container
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -164, 1, -56)
ContentFrame.Position = UDim2.new(0, 154, 0, 50)
ContentFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = ContentFrame

local Pages = {}
local TabButtons = {}

local function createCategoryPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 235, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = ContentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    Pages[name] = page
    return page
end

local function selectCategory(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        local indicator = btn:FindFirstChild("ActiveIndicator")
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            if indicator then indicator.Visible = true end
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 21, 32)
            btn.TextColor3 = Color3.fromRGB(140, 155, 180)
            if indicator then indicator.Visible = false end
        end
    end
end

local function createCategoryTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18, 21, 32)
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(140, 155, 180)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local activeBar = Instance.new("Frame")
    activeBar.Name = "ActiveIndicator"
    activeBar.Size = UDim2.new(0, 3, 0, 22)
    activeBar.Position = UDim2.new(0, 2, 0.5, -11)
    activeBar.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
    activeBar.BorderSizePixel = 0
    activeBar.Visible = false
    activeBar.Parent = btn

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = activeBar

    btn.MouseButton1Click:Connect(function()
        selectCategory(name)
    end)

    TabButtons[name] = btn
end

local function addSectionHeader(parent, title)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 26)
    header.BackgroundTransparency = 1
    header.Parent = parent

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = string.upper(title)
    titleLbl.TextColor3 = Color3.fromRGB(0, 235, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header
end

local function addFeatureToggle(parent, title, description, defaultState, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(32, 40, 58)
    cardStroke.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -70, 0, 18)
    titleLbl.Position = UDim2.new(0, 12, 0, 7)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -70, 0, 16)
    descLbl.Position = UDim2.new(0, 12, 0, 26)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = description
    descLbl.TextColor3 = Color3.fromRGB(130, 145, 170)
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Parent = card

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(0, 46, 0, 24)
    switchBtn.Position = UDim2.new(1, -56, 0.5, -12)
    switchBtn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 235, 255) or Color3.fromRGB(36, 42, 58)
    switchBtn.Text = ""
    switchBtn.Parent = card

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 12)
    switchCorner.Parent = switchBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switchBtn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = defaultState
    switchBtn.MouseButton1Click:Connect(function()
        state = not state
        local targetColor = state and Color3.fromRGB(0, 235, 255) or Color3.fromRGB(36, 42, 58)
        local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

        TweenService:Create(switchBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = targetPos }):Play()

        showNotification(title, state and "Enabled" or "Disabled", state)
        callback(state)
    end)
end

local function addSliderControl(parent, title, minVal, maxVal, defaultVal, suffix, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(32, 40, 58)
    cardStroke.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.68, 0, 0, 20)
    titleLbl.Position = UDim2.new(0, 12, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.28, 0, 0, 20)
    valLbl.Position = UDim2.new(0.7, -12, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(defaultVal) .. (suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(0, 235, 255)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = card

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -24, 0, 6)
    sliderTrack.Position = UDim2.new(0, 12, 0, 34)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = sliderTrack

    local initialRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new(initialRatio, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
    fillBar.BorderSizePixel = 0
    fillBar.Parent = sliderTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fillBar

    local dragging = false
    local function updateSlider(input)
        local posX = math.clamp(input.Position.X - sliderTrack.AbsolutePosition.X, 0, sliderTrack.AbsoluteSize.X)
        local ratio = posX / sliderTrack.AbsoluteSize.X
        local calculated = math.floor(minVal + (maxVal - minVal) * ratio)
        fillBar.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = tostring(calculated) .. (suffix or "")
        callback(calculated)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end))

    table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

local function addSegmentSelector(parent, title, options, defaultOption, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(32, 40, 58)
    cardStroke.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -24, 0, 18)
    titleLbl.Position = UDim2.new(0, 12, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local segmentContainer = Instance.new("Frame")
    segmentContainer.Size = UDim2.new(1, -24, 0, 24)
    segmentContainer.Position = UDim2.new(0, 12, 0, 26)
    segmentContainer.BackgroundTransparency = 1
    segmentContainer.Parent = card

    local segLayout = Instance.new("UIListLayout")
    segLayout.FillDirection = Enum.FillDirection.Horizontal
    segLayout.Padding = UDim.new(0, 6)
    segLayout.Parent = segmentContainer

    local buttons = {}
    local itemWidth = (1 / #options)

    for _, opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(itemWidth, -6, 1, 0)
        btn.BackgroundColor3 = (opt == defaultOption) and Color3.fromRGB(0, 235, 255) or Color3.fromRGB(30, 36, 52)
        btn.Text = opt
        btn.TextColor3 = (opt == defaultOption) and Color3.fromRGB(15, 17, 24) or Color3.fromRGB(180, 190, 210)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = segmentContainer

        local btnCorn = Instance.new("UICorner")
        btnCorn.CornerRadius = UDim.new(0, 5)
        btnCorn.Parent = btn

        buttons[opt] = btn

        btn.MouseButton1Click:Connect(function()
            for o, b in pairs(buttons) do
                if o == opt then
                    b.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
                    b.TextColor3 = Color3.fromRGB(15, 17, 24)
                else
                    b.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
                    b.TextColor3 = Color3.fromRGB(180, 190, 210)
                end
            end
            showNotification(title, "Set to: " .. opt, true)
            callback(opt)
        end)
    end
end

-------------------------------------------------------------------------
-- Build All Categorized Pages & Toggles
-------------------------------------------------------------------------

createCategoryTab("Combat", "🎯", 1)
createCategoryTab("Visuals", "👁️", 2)
createCategoryTab("Movement", "⚡", 3)
createCategoryTab("World", "🌐", 4)
createCategoryTab("Settings", "⚙️", 5)

local combatPage = createCategoryPage("Combat")
local visualsPage = createCategoryPage("Visuals")
local movementPage = createCategoryPage("Movement")
local worldPage = createCategoryPage("World")
local settingsPage = createCategoryPage("Settings")

-- ==================== [CATEGORY 1: COMBAT] ====================
addSectionHeader(combatPage, "Camera Aimbot Engine")

addFeatureToggle(combatPage, "Smooth Camera Aimbot", "Locks camera to closest valid target (Hold Right-Click)", Config.AimbotEnabled, function(s)
    Config.AimbotEnabled = s
    updateFOV()
end)

addSegmentSelector(combatPage, "Aimbot Target Bone", { "Head", "Torso", "HumanoidRootPart" }, Config.AimPart, function(part)
    Config.AimPart = part
end)

addSliderControl(combatPage, "Aimbot FOV Radius", 30, 400, Config.AimbotFOV, " px", function(v)
    Config.AimbotFOV = v
    updateFOV()
end)

addSliderControl(combatPage, "Camera Smoothing", 1, 15, Config.AimSmoothness, "", function(v)
    Config.AimSmoothness = v
end)

addFeatureToggle(combatPage, "Show Aimbot FOV Ring", "Renders cyan targeting ring on screen", Config.AimbotShowFOV, function(s)
    Config.AimbotShowFOV = s
    updateFOV()
end)

addSectionHeader(combatPage, "Target Filtering & Prediction")

addFeatureToggle(combatPage, "Wall / Visibility Check", "Filters out enemies hiding behind walls", Config.WallCheck, function(s)
    Config.WallCheck = s
end)

addFeatureToggle(combatPage, "Team Check Filter", "Filters friendly teammates (Keep OFF in 1v1 & FFA)", Config.TeamCheck, function(s)
    Config.TeamCheck = s
end)

addFeatureToggle(combatPage, "Velocity Lead Prediction", "Calculates target AssemblyLinearVelocity to lead shots", Config.Prediction, function(s)
    Config.Prediction = s
end)

addSliderControl(combatPage, "Lead Multiplier", 5, 30, math.floor(Config.PredictionMultiplier * 100), " %", function(v)
    Config.PredictionMultiplier = v / 100
end)

addSectionHeader(combatPage, "Assisted Trigger & Hitboxes")

addFeatureToggle(combatPage, "Auto Triggerbot", "Instantly fires when crosshair aligns with an enemy", Config.Triggerbot, function(s)
    Config.Triggerbot = s
end)

addSliderControl(combatPage, "Triggerbot Delay", 10, 200, math.floor(Config.TriggerbotDelay * 1000), " ms", function(v)
    Config.TriggerbotDelay = v / 1000
end)

addFeatureToggle(combatPage, "Hitbox Expander", "Enlarges enemy target hitboxes for easier hits", Config.HitboxExpander, function(s)
    Config.HitboxExpander = s
    if not s then
        resetHitboxes()
    end
end)

addSegmentSelector(combatPage, "Hitbox Bone", { "Head", "Torso", "HumanoidRootPart" }, Config.HitboxPart, function(part)
    resetHitboxes()
    Config.HitboxPart = part
end)

addSliderControl(combatPage, "Hitbox Expansion Size", 3, 14, Config.HitboxSize, " studs", function(v)
    Config.HitboxSize = v
end)

-- ==================== [CATEGORY 2: VISUALS] ====================
addSectionHeader(visualsPage, "Master Visuals & Chams")

addFeatureToggle(visualsPage, "Master ESP Switch", "Global switch for all visual player ESP systems", Config.ESPEnabled, function(s)
    Config.ESPEnabled = s
end)

addFeatureToggle(visualsPage, "Universal Player Chams", "High-visibility Roblox Highlight silhouette shader", Config.ChamsEnabled, function(s)
    Config.ChamsEnabled = s
    for p, _ in pairs(State.Highlights) do
        applyChams(p)
    end
end)

addSectionHeader(visualsPage, "2D Overlay Engines")

addFeatureToggle(visualsPage, "2D Bounding Box ESP", "Draws dynamic 2D corner/box around enemy characters", Config.BoxESP, function(s)
    Config.BoxESP = s
end)

addFeatureToggle(visualsPage, "Player Name Tags", "Displays player display name above their head", Config.NameESP, function(s)
    Config.NameESP = s
end)

addFeatureToggle(visualsPage, "Distance Meter", "Shows distance in meters next to player name tags", Config.DistanceESP, function(s)
    Config.DistanceESP = s
end)

addFeatureToggle(visualsPage, "Dynamic Health Bar", "Left-side colored health indicator bar", Config.HealthESP, function(s)
    Config.HealthESP = s
end)

addFeatureToggle(visualsPage, "Snaplines / Tracers", "Draws direct tracer lines from screen bottom to enemy", Config.Tracers, function(s)
    Config.Tracers = s
end)

-- ==================== [CATEGORY 3: MOVEMENT] ====================
addSectionHeader(movementPage, "Speed & Mobility")

addFeatureToggle(movementPage, "WalkSpeed Booster", "Overrides and locks your humanoid character speed", Config.SpeedHack, function(s)
    Config.SpeedHack = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

addSliderControl(movementPage, "WalkSpeed Multiplier", 16, 75, Config.SpeedMultiplier, " ws", function(v)
    Config.SpeedMultiplier = v
end)

addSectionHeader(movementPage, "Jump & Collision")

addFeatureToggle(movementPage, "Bunny Hop Engine", "Automatically hops as soon as feet touch the ground", Config.BunnyHop, function(s)
    Config.BunnyHop = s
end)

addFeatureToggle(movementPage, "Infinite Air Jump", "Enables continuous mid-air jumping without limits", Config.InfiniteJump, function(s)
    Config.InfiniteJump = s
end)

addFeatureToggle(movementPage, "Universal Noclip", "Removes character collisions to phase through walls", Config.Noclip, function(s)
    Config.Noclip = s
end)

-- ==================== [CATEGORY 4: WORLD & MISC] ====================
addSectionHeader(worldPage, "Camera & Lighting")

addFeatureToggle(worldPage, "Custom Camera FOV", "Expands player camera perspective for wider viewing", Config.CustomFOVEnabled, function(s)
    Config.CustomFOVEnabled = s
    if not s then Camera.FieldOfView = 70 end
end)

addSliderControl(worldPage, "Camera Field of View", 70, 120, Config.CustomFOV, "°", function(v)
    Config.CustomFOV = v
end)

addFeatureToggle(worldPage, "Fullbright Lighting", "Boosts world brightness and eliminates map fog", Config.Fullbright, function(s)
    Config.Fullbright = s
    updateFullbright()
end)

addSectionHeader(worldPage, "Protection & Keep-Alive")

addFeatureToggle(worldPage, "Anti-AFK Idle Shield", "Simulates user input to prevent 20-minute idle kicks", Config.AntiAFK, function(s)
    Config.AntiAFK = s
end)

-- ==================== [CATEGORY 5: SETTINGS & SYSTEM] ====================
addSectionHeader(settingsPage, "HUD & Watermark")

addFeatureToggle(settingsPage, "Watermark HUD Pill", "Displays top-left live FPS & ping status pill", Config.WatermarkEnabled, function(s)
    Config.WatermarkEnabled = s
    Watermark.Visible = s
end)

addSectionHeader(settingsPage, "System Diagnostics")

local diagCard = Instance.new("Frame")
diagCard.Size = UDim2.new(1, 0, 0, 48)
diagCard.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diagCard.BorderSizePixel = 0
diagCard.Parent = settingsPage

local diagCorner = Instance.new("UICorner")
diagCorner.CornerRadius = UDim.new(0, 8)
diagCorner.Parent = diagCard

local diagText = Instance.new("TextLabel")
diagText.Size = UDim2.new(1, -24, 1, 0)
diagText.Position = UDim2.new(0, 12, 0, 0)
diagText.BackgroundTransparency = 1
diagText.Text = "Status: ACTIVE | Menu Toggle: [RightShift]"
diagText.TextColor3 = Color3.fromRGB(0, 235, 255)
diagText.Font = Enum.Font.GothamMedium
diagText.TextSize = 12
diagText.TextXAlignment = Enum.TextXAlignment.Left
diagText.Parent = diagCard

-- Self Destruct Unload Button
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, 0, 0, 40)
unloadBtn.BackgroundColor3 = Color3.fromRGB(220, 45, 65)
unloadBtn.Text = "🚨 UNLOAD & DESTROY PULLZ HUB"
unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 13
unloadBtn.Parent = settingsPage

local unloadCorner = Instance.new("UICorner")
unloadCorner.CornerRadius = UDim.new(0, 8)
unloadCorner.Parent = unloadBtn

unloadBtn.MouseButton1Click:Connect(function()
    showNotification("System", "Unloading PullZ Pro Hub...", false)
    task.wait(0.3)
    getgenv().PullZHubUnload()
end)

-- Minimize Pill Mode
local isMinimized = false
local MinimizedBar = Instance.new("TextButton")
MinimizedBar.Name = "MinimizedBar"
MinimizedBar.Size = UDim2.new(0, 210, 0, 36)
MinimizedBar.Position = UDim2.new(0.5, -105, 0.05, 0)
MinimizedBar.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
MinimizedBar.Text = "⚡ PULLZ PRO [RESTORE]"
MinimizedBar.TextColor3 = Color3.fromRGB(0, 235, 255)
MinimizedBar.Font = Enum.Font.GothamBold
MinimizedBar.TextSize = 12
MinimizedBar.Visible = false
MinimizedBar.Active = true
MinimizedBar.Draggable = true
MinimizedBar.Parent = ScreenGui

local MinBarCorner = Instance.new("UICorner")
MinBarCorner.CornerRadius = UDim.new(0, 8)
MinBarCorner.Parent = MinimizedBar

local MinBarStroke = Instance.new("UIStroke")
MinBarStroke.Thickness = 1
MinBarStroke.Color = Color3.fromRGB(0, 235, 255)
MinBarStroke.Parent = MinimizedBar

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    Main.Visible = false
    MinimizedBar.Visible = true
end)

MinimizedBar.MouseButton1Click:Connect(function()
    isMinimized = false
    MinimizedBar.Visible = false
    Main.Visible = true
end)

-- Keybind Listener ([Insert] Toggle)
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if isMinimized then
            isMinimized = false
            MinimizedBar.Visible = false
            Main.Visible = true
        else
            Main.Visible = not Main.Visible
        end
    end
end))

-- Default Tab View
selectCategory("Combat")

showNotification("PullZ Pro", "PullZ Pro Ready! Hotkey: [Insert]", true)

print("-----------------------------------------------------------------")
print(" [PULLZ PRO] Automation & Combat Suite Initialized!")
print(" Status: Operational")
print(" Toggle Hotkey: [Insert]")
print(" License Tier: " .. tostring(getgenv().PullZLicenseTier or "ACTIVE"))
print("-----------------------------------------------------------------")
end -- end initMainHub

-- =========================================================================
-- EXECUTE AUTHENTICATION GATEWAY
-- =========================================================================
initAuthGateway(initMainHub)
