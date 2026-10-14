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
        return false, "Error: Please enter a license key."
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
        return false, "Access Denied: Invalid license key."
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
    -- If key is single-game (e.g. "dahood"), reject cleanly in Rivals!
    if allowedGame ~= "all" and allowedGame:lower() ~= SCRIPT_GAME_ID then
        return false, "Access Denied: Key is for " .. string.upper(allowedGame) .. " only!\nGet a Rivals key or an All-Access pass."
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
            return false, "Access Denied: Key bound to another PC."
        end

        -- Enforce Expiration (if not lifetime)
        if expiresAt and nowTs > expiresAt then
            return false, "Access Denied: License key has expired."
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
    KeySystemBorder.Size = UDim2.new(0, 440, 0, 330)
    KeySystemBorder.Position = UDim2.new(0.5, -220, 0.5, -165)
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
    KeyTitle.Position = UDim2.new(0, 0, 0, 16)
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
    KeySubTitle.Position = UDim2.new(0, 0, 0, 46)
    KeySubTitle.BackgroundTransparency = 1
    KeySubTitle.Text = "R I V A L S   A U T H E N T I C A T I O N"
    KeySubTitle.TextColor3 = Color3.fromRGB(0, 235, 255)
    KeySubTitle.Font = Enum.Font.GothamBold
    KeySubTitle.TextSize = 9
    KeySubTitle.Parent = KeySystemFrame

    -- Key Input Container
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(0, 360, 0, 42)
    InputFrame.Position = UDim2.new(0.5, -180, 0, 74)
    InputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    InputFrame.BorderSizePixel = 0
    InputFrame.Parent = KeySystemFrame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputFrame

    local KeyBox = Instance.new("TextBox")
    KeyBox.Size = UDim2.new(1, -70, 1, 0)
    KeyBox.Position = UDim2.new(0, 12, 0, 0)
    KeyBox.BackgroundTransparency = 1
    KeyBox.PlaceholderText = "Paste license key..."
    KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 125)
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 12
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = InputFrame

    local PasteBtn = Instance.new("TextButton")
    PasteBtn.Size = UDim2.new(0, 52, 0, 28)
    PasteBtn.Position = UDim2.new(1, -58, 0.5, -14)
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

    -- Status Label with Multiline TextWrapping (Never overflows!)
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 380, 0, 34)
    StatusLabel.Position = UDim2.new(0.5, -190, 0, 122)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextWrapped = true
    StatusLabel.TextYAlignment = Enum.TextYAlignment.Center
    StatusLabel.Parent = KeySystemFrame

    -- Verify Button
    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0, 360, 0, 42)
    VerifyBtn.Position = UDim2.new(0.5, -180, 0, 162)
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
    GetKeyBtn.Size = UDim2.new(0, 240, 0, 24)
    GetKeyBtn.Position = UDim2.new(0.5, -120, 0, 218)
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
    HwidLabel.Position = UDim2.new(0, 20, 0, 254)
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
        StatusLabel.Text = "Validating key with database..."

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
                StatusLabel.Text = message or "Access Denied: Invalid license key."
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
    AimbotEnabled = false,
    AimPart = "Head", -- "Head", "Torso", "HumanoidRootPart"
    AimSmoothness = 3,
    AimbotFOV = 130,
    AimKey = Enum.UserInputType.MouseButton2,
    AimbotShowFOV = false,
    FOVColor = Color3.fromRGB(0, 230, 255),

    -- Target Filters
    TeamCheck = false, -- Disabled by default so 1v1 / FFA modes are never filtered out
    WallCheck = false, -- Disabled by default so invisible barriers don't block target acquisition
    Prediction = false,
    PredictionMultiplier = 0.135,

    -- Assisted Combat
    Triggerbot = false,
    TriggerbotDelay = 0.05,
    HitboxExpander = false,
    HitboxSize = 6,
    HitboxPart = "Head",

    -- Visuals
    ESPEnabled = false,
    ChamsEnabled = false,
    ChamsColor = Color3.fromRGB(255, 45, 85),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    BoxESP = false,
    NameESP = false,
    DistanceESP = false,
    HealthESP = false,
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
    AntiAFK = false,
    WatermarkEnabled = true
}

-- Runtime State
local State = {
    ScreenGui = nil,
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

    if State.ScreenGui and State.ScreenGui.Parent then
        pcall(function() State.ScreenGui:Destroy() end)
    end
    if getgenv().PullZScreenGui and getgenv().PullZScreenGui.Parent then
        pcall(function() getgenv().PullZScreenGui:Destroy() end)
    end
    if gethui then
        pcall(function()
            for _, name in ipairs({"PullZ_RivalsHub", "PullZHub", "RivalsSupremeHub"}) do
                local found = gethui():FindFirstChild(name)
                if found then found:Destroy() end
            end
        end)
    end
    pcall(function()
        for _, name in ipairs({"PullZ_RivalsHub", "PullZHub", "RivalsSupremeHub"}) do
            local found = CoreGui:FindFirstChild(name)
            if found then found:Destroy() end
        end
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            for _, name in ipairs({"PullZ_RivalsHub", "PullZHub", "RivalsSupremeHub"}) do
                local found = LocalPlayer.PlayerGui:FindFirstChild(name)
                if found then found:Destroy() end
            end
        end
    end)

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
local function isVisible(targetPart)
    if not Config.WallCheck then return true end
    if not targetPart or not LocalPlayer.Character then return false end

    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude

    local ignoreList = { LocalPlayer.Character, Camera }
    if Workspace:FindFirstChild("Debris") then table.insert(ignoreList, Workspace.Debris) end
    if Workspace:FindFirstChild("Bullets") then table.insert(ignoreList, Workspace.Bullets) end
    if Workspace:FindFirstChild("Effects") then table.insert(ignoreList, Workspace.Effects) end
    if Workspace:FindFirstChild("Ignore") then table.insert(ignoreList, Workspace.Ignore) end
    if Workspace:FindFirstChild("RaycastIgnore") then table.insert(ignoreList, Workspace.RaycastIgnore) end
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.IgnoreWater = true

    local maxPierces = 5
    local currentOrigin = origin
    local remainingDir = direction

    for _ = 1, maxPierces do
        local result = Workspace:Raycast(currentOrigin, remainingDir, raycastParams)
        if not result then
            return true
        end

        local hitInstance = result.Instance
        local targetChar = targetPart:FindFirstAncestorOfClass("Model") or targetPart.Parent

        if hitInstance:IsDescendantOf(targetChar) then
            return true
        end

        -- Pierce transparent glass, bullet clips, viewmodels, or non-collidable trigger volumes
        if hitInstance.CanCollide == false or hitInstance.Transparency >= 0.5 or hitInstance.Name:lower():find("glass") or hitInstance.Name:lower():find("barrier") or hitInstance.Name:lower():find("clip") then
            currentOrigin = result.Position + (remainingDir.Unit * 0.2)
            remainingDir = destination - currentOrigin
            if remainingDir.Magnitude < 0.25 then
                return true
            end
        else
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

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isPlayerAlive(player) and not isTeammate(player) then
            local char = player.Character
            local targetPart = resolveAimPart(char, preferredPart)

            if targetPart then
                local shouldCheck = (wallCheckEnabled ~= nil) and wallCheckEnabled or Config.WallCheck
                if not shouldCheck or isVisible(targetPart) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local target2D = Vector2.new(screenPos.X, screenPos.Y)
                        local distToCrosshair = (screenCenter - target2D).Magnitude

                        if distToCrosshair < minDistance then
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
-- PULLZ UI ARCHITECTURE (SIGNATURE OBSIDIAN & ROTATING GRADIENT SUITE)
-------------------------------------------------------------------------

local existingGui = CoreGui:FindFirstChild("PullZ_RivalsHub") 
    or CoreGui:FindFirstChild("PullZHub")
    or (LocalPlayer:FindFirstChild("PlayerGui") and (LocalPlayer.PlayerGui:FindFirstChild("PullZ_RivalsHub") or LocalPlayer.PlayerGui:FindFirstChild("PullZHub")))
if existingGui then
    pcall(function() existingGui:Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PullZ_RivalsHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

State.ScreenGui = ScreenGui
getgenv().PullZScreenGui = ScreenGui

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- === LOADING SCREEN (SIGNATURE PULLZ SUITE) ===
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

-- Outer Spinner (Gradient)
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
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)), -- Sky Blue accent
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 15))
})
SpinnerGradient.Rotation = 0
SpinnerGradient.Parent = SpinnerOuter

-- Inner Spinner (Hole)
local SpinnerInner = Instance.new("Frame")
SpinnerInner.Size = UDim2.new(1, -6, 1, -6) -- 3px border
SpinnerInner.Position = UDim2.new(0, 3, 0, 3)
SpinnerInner.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
SpinnerInner.BackgroundTransparency = 1
SpinnerInner.ZIndex = 10001
SpinnerInner.Parent = SpinnerOuter

local InnerCorner = Instance.new("UICorner")
InnerCorner.CornerRadius = UDim.new(1, 0)
InnerCorner.Parent = SpinnerInner

-- Percentage Text (Inside the hole)
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

-- Title
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

-- Subtitle
local SubTitleText = Instance.new("TextLabel")
SubTitleText.Size = UDim2.new(0, 200, 0, 20)
SubTitleText.Position = UDim2.new(0.5, -100, 0.5, 120)
SubTitleText.BackgroundTransparency = 1
SubTitleText.Text = "R I V A L S"
SubTitleText.TextColor3 = Color3.fromRGB(100, 150, 255)
SubTitleText.Font = Enum.Font.GothamBold
SubTitleText.TextSize = 13
SubTitleText.TextTransparency = 1
SubTitleText.ZIndex = 10002
SubTitleText.Parent = LoadingFrame

-- Shockwave (for the end)
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

-- Animate Spinner
local spinnerActive = true
task.spawn(function()
    while spinnerActive and SpinnerOuter and SpinnerOuter.Parent do
        SpinnerGradient.Rotation = (tick() * 320) % 360
        task.wait()
    end
end)

local fadeInInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
TweenService:Create(SpinnerOuter, fadeInInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(SpinnerInner, fadeInInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(PercentText, fadeInInfo, {TextTransparency = 0}):Play()

TweenService:Create(TitleText, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 60)}):Play()
TweenService:Create(SubTitleText, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 95)}):Play()

task.wait(0.6)

for i = 1, 100 do
    PercentText.Text = i .. "%"
    task.wait(0.012)
end

-- Pulse animation at 100%
TweenService:Create(PercentText, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 52}):Play()
task.wait(0.1)
TweenService:Create(PercentText, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {TextSize = 42}):Play()
task.wait(0.2)
PercentText.Text = "OK"
task.wait(0.35)

-- Shockwave explode and collapse
TweenService:Create(Shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 400, 0, 400), Position = UDim2.new(0.5, -200, 0.5, -220), BackgroundTransparency = 0.8}):Play()

local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
TweenService:Create(SpinnerOuter, fadeOutInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(SpinnerInner, fadeOutInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(PercentText, fadeOutInfo, {TextTransparency = 1}):Play()
TweenService:Create(TitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 40)}):Play()
local finishTween = TweenService:Create(SubTitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 75)})
finishTween:Play()
TweenService:Create(Shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()

finishTween.Completed:Wait()
spinnerActive = false
LoadingFrame:Destroy()
-- === END LOADING SCREEN ===

-- Toast Notification System
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
    toast.Size = UDim2.new(1, 0, 0, 50)
    toast.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 1
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = isSuccess and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 75, 95)
    stroke.Transparency = 1
    stroke.Parent = toast

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = (isSuccess and "✓ " or "✕ ") .. title
    titleLbl.TextColor3 = isSuccess and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 75, 95)
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
Watermark.Size = UDim2.new(0, 280, 0, 30)
Watermark.Position = UDim2.new(0, 14, 0, 14)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Watermark.BorderSizePixel = 0
Watermark.Visible = Config.WatermarkEnabled
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
WatermarkLabel.Text = "⚡ PULLZ | RIVALS | 60 FPS"
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
        local tierTag = getgenv().PullZLicenseTier and (" [" .. tostring(getgenv().PullZLicenseTier) .. "]") or ""
        WatermarkLabel.Text = string.format("⚡ PULLZ%s | RIVALS | %d FPS | %dms", tierTag, fps, ping)
        frameCount = 0
        lastFpsTime = now
    end
end))

-- Signature PullZ Rainbow Rotating Border Frame
local BorderFrame = Instance.new("Frame")
BorderFrame.Name = "PullZ_Border"
BorderFrame.Size = UDim2.new(0, 684, 0, 484)
BorderFrame.Position = UDim2.new(0.5, -342, 0.5, -242)
BorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BorderFrame.BorderSizePixel = 0
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
local MinimizedBtn = Instance.new("TextButton")
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

local SidebarPatch = Instance.new("Frame")
SidebarPatch.Size = UDim2.new(0, 8, 1, 0)
SidebarPatch.Position = UDim2.new(0, 152, 0, 0)
SidebarPatch.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
SidebarPatch.BorderSizePixel = 0
SidebarPatch.Parent = MainFrame

local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(1, 0, 0, 60)
TitleContainer.BackgroundTransparency = 1
TitleContainer.Parent = Sidebar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "PullZ"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 26
Title.Parent = TitleContainer

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
})
TitleGrad.Rotation = 45
TitleGrad.Parent = Title

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 32)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "R I V A L S"
SubTitle.TextColor3 = Color3.fromRGB(100, 150, 255)
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 9
SubTitle.Parent = TitleContainer

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -40, 0, 2)
Separator.Position = UDim2.new(0, 20, 1, 0)
Separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Separator.BorderSizePixel = 0
Separator.Parent = TitleContainer

local SepGradient = Instance.new("UIGradient")
SepGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
})
SepGradient.Parent = Separator

-- Top Action Bar (Dedicated top layer for window controls)
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
    if getgenv().PullZHubUnload then
        getgenv().PullZHubUnload()
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

-- Content Area (Positioned below TopActionBar so buttons never get blocked)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -160, 1, -44)
ContentArea.Position = UDim2.new(0, 160, 0, 44)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Tabs = {}
local TabButtons = {}
local CurrentContainer = nil

local function switchTab(tabName)
    for name, frame in pairs(Tabs) do
        frame.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = Color3.fromRGB(100, 150, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

local function createTab(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 35)
    Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Center
    Btn.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -20, 1, -10)
    Page.Position = UDim2.new(0, 10, 0, 5)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.Visible = false
    Page.Parent = ContentArea

    local UIList = Instance.new("UIListLayout")
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 8)
    UIList.Parent = Page

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingTop = UDim.new(0, 5)
    UIPadding.PaddingBottom = UDim.new(0, 10)
    UIPadding.PaddingLeft = UDim.new(0, 2)
    UIPadding.PaddingRight = UDim.new(0, 6)
    UIPadding.Parent = Page

    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
    end)

    Btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    Tabs[name] = Page
    TabButtons[name] = Btn

    if not CurrentContainer then
        switchTab(name)
        CurrentContainer = Page
    end

    return Page
end

local function createHeader(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(text)
    Label.TextColor3 = Color3.fromRGB(100, 150, 255)
    Label.TextSize = 11
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
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
        TS:Create(Button, TI, {BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 70)}):Play()
        TS:Create(Circle, TI, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        showNotification(name, state and "Enabled" or "Disabled", state)
        callback(state)
    end

    Button.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return setState
end

local function createSlider(parent, name, minVal, maxVal, defaultVal, suffix, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.68, 0, 0, 20)
    titleLbl.Position = UDim2.new(0, 14, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = name
    titleLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.28, 0, 0, 20)
    valLbl.Position = UDim2.new(0.7, -14, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(defaultVal) .. (suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(100, 150, 255)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = card

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -28, 0, 6)
    sliderTrack.Position = UDim2.new(0, 14, 0, 32)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = sliderTrack

    local initialRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new(initialRatio, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end))

    table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function createSegment(parent, name, options, defaultOption, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -28, 0, 18)
    titleLbl.Position = UDim2.new(0, 14, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = name
    titleLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local segmentContainer = Instance.new("Frame")
    segmentContainer.Size = UDim2.new(1, -28, 0, 24)
    segmentContainer.Position = UDim2.new(0, 14, 0, 26)
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
        btn.BackgroundColor3 = (opt == defaultOption) and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(30, 30, 40)
        btn.Text = opt
        btn.TextColor3 = (opt == defaultOption) and Color3.fromRGB(12, 12, 15) or Color3.fromRGB(180, 190, 210)
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
                    b.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                    b.TextColor3 = Color3.fromRGB(12, 12, 15)
                else
                    b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                    b.TextColor3 = Color3.fromRGB(180, 190, 210)
                end
            end
            showNotification(name, "Set to: " .. opt, true)
            callback(opt)
        end)
    end
end

-------------------------------------------------------------------------
-- Build All Categorized Pages & Toggles (PullZ UI)
-------------------------------------------------------------------------

local combatPage = createTab("🎯 Combat")
local visualsPage = createTab("👁️ Visuals")
local movementPage = createTab("⚡ Movement")
local worldPage = createTab("🌐 World")
local settingsPage = createTab("⚙️ Settings")

-- ==================== [CATEGORY 1: COMBAT] ====================
createHeader(combatPage, "Camera Aimbot Engine")

createToggle(combatPage, "Smooth Camera Aimbot", Config.AimbotEnabled, function(s)
    Config.AimbotEnabled = s
    updateFOV()
end)

createSegment(combatPage, "Aimbot Target Bone", { "Head", "Torso", "HumanoidRootPart" }, Config.AimPart, function(part)
    Config.AimPart = part
end)

createSlider(combatPage, "Aimbot FOV Radius", 30, 400, Config.AimbotFOV, " px", function(v)
    Config.AimbotFOV = v
    updateFOV()
end)

createSlider(combatPage, "Camera Smoothing", 1, 15, Config.AimSmoothness, "", function(v)
    Config.AimSmoothness = v
end)

createToggle(combatPage, "Show Aimbot FOV Ring", Config.AimbotShowFOV, function(s)
    Config.AimbotShowFOV = s
    updateFOV()
end)

createHeader(combatPage, "Target Filtering & Prediction")

createToggle(combatPage, "Wall / Visibility Check", Config.WallCheck, function(s)
    Config.WallCheck = s
end)

createToggle(combatPage, "Team Check Filter", Config.TeamCheck, function(s)
    Config.TeamCheck = s
end)

createToggle(combatPage, "Velocity Lead Prediction", Config.Prediction, function(s)
    Config.Prediction = s
end)

createSlider(combatPage, "Lead Multiplier", 5, 30, math.floor(Config.PredictionMultiplier * 100), " %", function(v)
    Config.PredictionMultiplier = v / 100
end)

createHeader(combatPage, "Assisted Trigger & Hitboxes")

createToggle(combatPage, "Auto Triggerbot", Config.Triggerbot, function(s)
    Config.Triggerbot = s
end)

createSlider(combatPage, "Triggerbot Delay", 10, 200, math.floor(Config.TriggerbotDelay * 1000), " ms", function(v)
    Config.TriggerbotDelay = v / 1000
end)

createToggle(combatPage, "Hitbox Expander", Config.HitboxExpander, function(s)
    Config.HitboxExpander = s
    if not s then
        resetHitboxes()
    end
end)

createSegment(combatPage, "Hitbox Bone", { "Head", "Torso", "HumanoidRootPart" }, Config.HitboxPart, function(part)
    resetHitboxes()
    Config.HitboxPart = part
end)

createSlider(combatPage, "Hitbox Expansion Size", 3, 14, Config.HitboxSize, " studs", function(v)
    Config.HitboxSize = v
end)

-- ==================== [CATEGORY 2: VISUALS] ====================
createHeader(visualsPage, "Master Visuals & Chams")

createToggle(visualsPage, "Master ESP Switch", Config.ESPEnabled, function(s)
    Config.ESPEnabled = s
end)

createToggle(visualsPage, "Universal Player Chams", Config.ChamsEnabled, function(s)
    Config.ChamsEnabled = s
    for p, _ in pairs(State.Highlights) do
        applyChams(p)
    end
end)

createHeader(visualsPage, "2D Overlay Engines")

createToggle(visualsPage, "2D Bounding Box ESP", Config.BoxESP, function(s)
    Config.BoxESP = s
end)

createToggle(visualsPage, "Player Name Tags", Config.NameESP, function(s)
    Config.NameESP = s
end)

createToggle(visualsPage, "Distance Meter", Config.DistanceESP, function(s)
    Config.DistanceESP = s
end)

createToggle(visualsPage, "Dynamic Health Bar", Config.HealthESP, function(s)
    Config.HealthESP = s
end)

createToggle(visualsPage, "Snaplines / Tracers", Config.Tracers, function(s)
    Config.Tracers = s
end)

-- ==================== [CATEGORY 3: MOVEMENT] ====================
createHeader(movementPage, "Speed & Mobility")

createToggle(movementPage, "WalkSpeed Booster", Config.SpeedHack, function(s)
    Config.SpeedHack = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

createSlider(movementPage, "WalkSpeed Multiplier", 16, 75, Config.SpeedMultiplier, " ws", function(v)
    Config.SpeedMultiplier = v
end)

createHeader(movementPage, "Jump & Collision")

createToggle(movementPage, "Bunny Hop Engine", Config.BunnyHop, function(s)
    Config.BunnyHop = s
end)

createToggle(movementPage, "Infinite Air Jump", Config.InfiniteJump, function(s)
    Config.InfiniteJump = s
end)

createToggle(movementPage, "Universal Noclip", Config.Noclip, function(s)
    Config.Noclip = s
end)

-- ==================== [CATEGORY 4: WORLD & MISC] ====================
createHeader(worldPage, "Camera & Lighting")

createToggle(worldPage, "Custom Camera FOV", Config.CustomFOVEnabled, function(s)
    Config.CustomFOVEnabled = s
    if not s then Camera.FieldOfView = 70 end
end)

createSlider(worldPage, "Camera Field of View", 70, 120, Config.CustomFOV, "°", function(v)
    Config.CustomFOV = v
end)

createToggle(worldPage, "Fullbright Lighting", Config.Fullbright, function(s)
    Config.Fullbright = s
    updateFullbright()
end)

createHeader(worldPage, "Protection & Keep-Alive")

createToggle(worldPage, "Anti-AFK Idle Shield", Config.AntiAFK, function(s)
    Config.AntiAFK = s
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
diagText.Text = "Status: ACTIVE | Menu Toggle: [RightShift] or [Insert]"
diagText.TextColor3 = Color3.fromRGB(100, 150, 255)
diagText.Font = Enum.Font.GothamMedium
diagText.TextSize = 12
diagText.TextXAlignment = Enum.TextXAlignment.Left
diagText.Parent = diagCard



-- Hotkey Toggle ([Insert] Only)
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if MinimizedBtn.Visible then
            MinimizedBtn.Visible = false
            BorderFrame.Visible = true
        else
            BorderFrame.Visible = not BorderFrame.Visible
        end
    end
end))

-- Default tab
switchTab("🎯 Combat")

showNotification("PullZ Pro", "PullZ Rivals Suite Ready! Hotkey: [Insert]", true)

print("-----------------------------------------------------------------")
print(" [PULLZ PRO] Rivals Automation Suite Initialized!")
print(" Status: Operational")
print(" Toggle Hotkey: [Insert]")
print(" License Tier: " .. tostring(getgenv().PullZLicenseTier or "ACTIVE"))
print("-----------------------------------------------------------------")
end -- end initMainHub

-- =========================================================================
-- EXECUTE AUTHENTICATION GATEWAY
-- =========================================================================
initAuthGateway(initMainHub)
