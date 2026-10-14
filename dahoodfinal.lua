--[[
    =============================================================================
    PULLZ DA HOOD | SUPREME GAMEPLAY AUTOMATION & QUALITY-OF-LIFE SUITE
    =============================================================================
    Categorized Features:
      💰 1. AUTOMATION & FARMING:
         • Auto ATM Farm (Scans, moves safely to intact ATMs, breaks & vacuums cash)
         • Auto Cashier Farm (Targets shop cash registers, breaks & collects)
         • Auto Cash Magnet / Vacuum (Instantly snatches dropped cash across the map)
         • Auto Muscle Grinder (Equips Weights/HeavyWeights & trains automatically)
         • Auto Boxing Bag (Punches gym bags to build strength effortlessly)
      🛡️ 2. DEFENSE & SURVIVAL:
         • Auto Eat / Smart Heal (Monitors HP and eats Taco/Pizza/Chicken/Cranberry)
         • Auto Buy Armor (Visits armor shop when Kevlar/Vest drops below threshold)
         • Auto Stomp (Instant stomp trigger for knocked targets in range)
         • Auto Reload (Automatically refreshes magazine when ammo is depleted)
         • Anti-Ragdoll / Quick Recovery (Bypasses ragdoll/knockdown lockouts)
         • Anti-AFK Idle Keep-Alive (Prevents the 20-minute Roblox disconnection)
      📍 3. PRECISION TELEPORTS:
         • Instant Safe Waypoints: Gym, Bank, Boxing Club, Gun Shops, High Armor,
           Medium Armor, Hospital, Police Station, Taco Shop, Casino & Sky Safe Base
         • Custom Coordinates Saver & Quick Recall Engine
      👁️ 4. VISUALS & ESP:
         • Player Box ESP & Name/Distance/Health Tags
         • Dropped Cash ESP (Shows all money piles and distances on screen)
         • FOV Ring Visualizer & Snaplines
      ⚡ 5. MOVEMENT & WORLD:
         • WalkSpeed & JumpPower Multipliers (Respawn-persistent)
         • Infinite Air-Jump Engine
         • Universal Safe Noclip
         • Fullbright Lighting & Fog Cleaner
      ⚙️ 6. SUITE SETTINGS:
         • Sleek Cyber-Glassmorphism UI (Draggable, Minimizable, Clean Tabs)
         • Toggle Keybind: [Insert] or Minimized Pill
         • Zero-Leak Self-Destruct Unload Handler
    =============================================================================
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- =========================================================================
-- [PULLZ PRO] SUPABASE AUTHENTICATION GATEWAY
-- =========================================================================
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Firebase Firestore Gateway (Project: key-gen-4a3fb)
local FIREBASE_PROJECT_ID = "key-gen-4a3fb"
local FIREBASE_REST_URL = "https://firestore.googleapis.com/v1/projects/" .. FIREBASE_PROJECT_ID .. "/databases/(default)/documents/keys/"
local FREE_KEY_URL = "https://pullzcheats.org/dahood.html"
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
local SCRIPT_GAME_ID = "dahood"

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

    local rawStatus = getRes.StatusCode or getRes.status_code or getRes.Status or getRes.status
    local statusNum = tonumber(rawStatus) or (rawStatus and tonumber(tostring(rawStatus):match("%d+")))
    if statusNum == 404 then
        return false, "Access Denied: Invalid license key."
    end
    if statusNum and (statusNum < 200 or statusNum >= 300) then
        return false, "Access Denied: Invalid key (HTTP " .. tostring(statusNum) .. ")"
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
    -- If key is single-game (e.g. "rivals"), reject in Da Hood!
    if allowedGame ~= "all" and allowedGame:lower() ~= SCRIPT_GAME_ID then
        return false, "Access Denied: Key is for " .. string.upper(allowedGame) .. " only!\nGet a Da Hood key or an All-Access pass."
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

    -- Signature PullZ Rainbow Rotating Border Frame (NO Dark Overlay!)
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255))
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
    })
    KeyTitleGradient.Rotation = 45
    KeyTitleGradient.Parent = KeyTitle

    local KeySubTitle = Instance.new("TextLabel")
    KeySubTitle.Size = UDim2.new(1, 0, 0, 14)
    KeySubTitle.Position = UDim2.new(0, 0, 0, 48)
    KeySubTitle.BackgroundTransparency = 1
    KeySubTitle.Text = "D A   H O O D   A U T H E N T I C A T I O N"
    KeySubTitle.TextColor3 = Color3.fromRGB(100, 150, 255)
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
    PasteBtn.TextColor3 = Color3.fromRGB(100, 150, 255)
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
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(0, 390, 0, 36)
    StatusLabel.Position = UDim2.new(0.5, -195, 0, 120)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextWrapped = true
    StatusLabel.TextYAlignment = Enum.TextYAlignment.Center
    StatusLabel.ZIndex = 10
    StatusLabel.Parent = KeySystemFrame

    -- Verify Button (Signature PullZ Sky Blue)
    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0, 360, 0, 42)
    VerifyBtn.Position = UDim2.new(0.5, -180, 0, 162)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
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
    GetKeyBtn.TextColor3 = Color3.fromRGB(100, 150, 255)
    GetKeyBtn.Font = Enum.Font.Gotham
    GetKeyBtn.TextSize = 12
    GetKeyBtn.Parent = KeySystemFrame

    local GetKeyUnderline = Instance.new("Frame")
    GetKeyUnderline.Size = UDim2.new(0, 120, 0, 1)
    GetKeyUnderline.Position = UDim2.new(0.5, -60, 1, -2)
    GetKeyUnderline.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    GetKeyUnderline.BorderSizePixel = 0
    GetKeyUnderline.Parent = GetKeyBtn

    GetKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 200, 255)}):Play()
        TweenService:Create(GetKeyUnderline, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 200, 255), Size = UDim2.new(0, 140, 0, 1), Position = UDim2.new(0.5, -70, 1, -2)}):Play()
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(100, 150, 255)}):Play()
        TweenService:Create(GetKeyUnderline, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 150, 255), Size = UDim2.new(0, 120, 0, 1), Position = UDim2.new(0.5, -60, 1, -2)}):Play()
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
            local pcallOk, success, message = pcall(function()
                return verifyKey(inputKey)
            end)

            if not pcallOk then
                success = false
                message = "Verification error: " .. tostring(success or "Failed to connect")
            end

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
                StatusLabel.Text = tostring(message or "Access Denied: Invalid license key.")
                VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
                VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                VerifyBtn.Text = "Access Denied!"
                task.wait(1.8)
                if VerifyBtn and VerifyBtn.Parent then
                    VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                    VerifyBtn.TextColor3 = Color3.fromRGB(12, 12, 15)
                    VerifyBtn.Text = "Verify Key"
                end
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
-- [PULLZ PRO] DA HOOD AUTOMATION & UI SUITE
-- =========================================================================
local function initMainHub()


-- Clean previous instance if already running
if getgenv and getgenv().DaHoodSuiteLoaded and getgenv().DaHoodSuiteUnload then
    pcall(function() getgenv().DaHoodSuiteUnload() end)
end
if getgenv then getgenv().DaHoodSuiteLoaded = true end

-- =============================================================================
-- SERVICES & CORE REFERENCES
-- =============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function getGuiContainer()
    local success, container = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if success and container then return container end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- =============================================================================
-- CONFIGURATION & STATE SYSTEM
-- =============================================================================
local State = {
    -- Farming
    AutoATM = false,
    AutoCashier = false,
    AutoCashMagnet = false,
    AutoTPCash = false,
    TPCashDelay = 0.15,
    AutoWeights = false,
    AutoBoxingBag = false,
    FarmRange = 10,

    -- Combat & Gun Assists
    AimbotEnabled = false,
    AimAtHead = true,
    AimPart = "Head",
    AimSmoothness = 3,
    AimbotFOV = 120,
    ShowFOVRing = false,
    AimKey = Enum.UserInputType.MouseButton2,
    Prediction = true,
    PredictionMultiplier = 0.12,
    HitboxExpander = false,
    HitboxSize = 5,
    DownedAntiStomp = false,

    -- Defense & Combat
    AutoEat = false,
    EatThreshold = 65,
    AutoBuyArmor = false,
    AutoStomp = false,
    AutoReload = false,
    AntiRagdoll = false,

    -- Movement & World
    WalkSpeedBoost = false,
    WalkSpeedValue = 24,
    JumpPowerBoost = false,
    JumpPowerValue = 65,
    InfiniteJump = false,
    Noclip = false,
    Fullbright = false,

    -- Visuals
    PlayerESP = false,
    CashESP = false,
    Tracers = false,

    -- System
    AntiAFK = true,
    UIVisible = true,
}

local Connections = {}
local ESPBoxes = {}
local CashESPDrawings = {}

-- Key Da Hood POI Locations
local Locations = {
    ["Hood Fitness (Gym)"]   = Vector3.new(-75.5, 22.8, -633.5),
    ["Bank"]                 = Vector3.new(-402.5, 21.75, -284.5),
    ["Boxing Club"]          = Vector3.new(-235.0, 22.0, -1120.0),
    ["Gun Shop (Uphill)"]    = Vector3.new(481.5, 48.0, -605.5),
    ["Gun Shop (Downhill)"]  = Vector3.new(-582.5, 8.3, -737.5),
    ["High Armor Shop"]      = Vector3.new(-934.5, -28.5, 565.5),
    ["Medium Armor Shop"]    = Vector3.new(-603.5, 8.3, -788.5),
    ["Taco Shop"]            = Vector3.new(585.5, 48.0, -145.5),
    ["Hospital"]             = Vector3.new(115.5, 22.8, -478.5),
    ["Police Station"]       = Vector3.new(-265.5, 21.7, -115.5),
    ["Casino"]               = Vector3.new(-868.5, 21.75, -118.5),
    ["Playground / Park"]    = Vector3.new(-285.5, 22.0, -785.5),
    ["Safe Sky Base"]        = Vector3.new(0.0, 450.0, 0.0),
}

-- =============================================================================
-- DA HOOD ANTI-CHEAT SAFE TRANSPORT ENGINE (NO ANCHOR / NO "STOP." KICK)
-- =============================================================================
local activeTween = nil

-- Universal Seat & Chair Ejection Handler
local function ejectFromSeats(char, hum, hrp)
    if not hum then return end
    hum.Sit = false
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
    if hum.SeatPart then
        pcall(function()
            local seat = hum.SeatPart
            for _, child in ipairs(seat:GetChildren()) do
                if (child:IsA("Weld") or child:IsA("WeldConstraint")) and (child.Part1 == hrp or (child.Part1 and child.Part1:IsDescendantOf(char))) then
                    child:Destroy()
                end
            end
        end)
    end
    if hrp then
        for _, child in ipairs(hrp:GetChildren()) do
            if (child:IsA("Weld") or child:IsA("WeldConstraint")) and string.find(string.lower(child.Name), "seat") then
                pcall(function() child:Destroy() end)
            end
        end
    end
    if char then
        for _, desc in ipairs(char:GetDescendants()) do
            if (desc:IsA("Weld") or desc:IsA("WeldConstraint")) and string.find(string.lower(desc.Name), "seat") then
                pcall(function() desc:Destroy() end)
            end
        end
    end
end

local function safeTeleport(targetPos, customYOffset, customSpeed)
    if not targetPos then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    -- Extract Vector3 safely
    local pos = typeof(targetPos) == "Vector3" and targetPos 
        or (typeof(targetPos) == "CFrame" and targetPos.Position) 
        or (targetPos:IsA("BasePart") and targetPos.Position)
        or (targetPos:IsA("Model") and targetPos:GetPivot().Position)
    if not pos then return false end

    local yOffset = customYOffset or 2.5
    local destinationCF = CFrame.new(pos + Vector3.new(0, yOffset, 0))

    -- Seat / Stun cleanup & disable Seated state during transit
    ejectFromSeats(char, hum, hrp)

    -- Cancel any prior running tween
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end

    local distance = (hrp.Position - destinationCF.Position).Magnitude
    if distance < 3.5 then
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        return true
    end

    -- Zero velocities (NEVER anchor hrp in Da Hood, anchoring triggers the "Stop." server kick)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Da Hood Safe Speed: ~105 studs/sec replicates smoothly under 2 studs/frame, bypassing the delta kick check
    local speed = customSpeed or 105
    local duration = math.clamp(distance / speed, 0.1, 7.0)

    -- Temporary noclip connection & continuous anti-seat guard during flight/transit
    local noclipTransit = true
    local transitConn = RunService.Stepped:Connect(function()
        if noclipTransit and char then
            if hum.Sit or hum.SeatPart then
                ejectFromSeats(char, hum, hrp)
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    activeTween = TweenService:Create(hrp, tweenInfo, { CFrame = destinationCF })
    activeTween:Play()

    activeTween.Completed:Wait()
    activeTween = nil

    noclipTransit = false
    transitConn:Disconnect()

    -- Re-enable Seated state after arrival
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end)

    -- Re-zero velocity after landing
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)

    return true
end

-- =============================================================================
-- COMBAT, INTERACTION & UTILITY HELPERS
-- =============================================================================
local function getCombatTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local combat = char:FindFirstChild("Combat") or char:FindFirstChild("[Combat]")
    if not combat then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            combat = bp:FindFirstChild("Combat") or bp:FindFirstChild("[Combat]")
            if combat then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(combat) end
            end
        end
    end
    return combat
end

local function attackTarget()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = getCombatTool()
    if tool then
        pcall(function() tool:Activate() end)
    else
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2), Camera.CFrame)
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2), Camera.CFrame)
        end)
    end
end

-- Single Cash Interaction Handler (Pure ClickDetector / ProximityPrompt, no firetouchinterest)
local function interactWithCash(cashObj, hrp)
    if not cashObj or not cashObj.Parent then return false end

    local cd = cashObj:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then
        pcall(function() fireclickdetector(cd) end)
    end

    local prompt = cashObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            prompt.Enabled = true
            prompt.HoldDuration = 0
            if fireproximityprompt then fireproximityprompt(prompt) end
        end)
    end

    return true
end

-- Vacuum / Collect Nearby Dropped Cash
local function collectNearbyCash()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ignored = Workspace:FindFirstChild("Ignored")
    local dropFolder = (ignored and ignored:FindFirstChild("Drop")) or Workspace:FindFirstChild("Drop")
    if not dropFolder then return end

    for _, obj in ipairs(dropFolder:GetChildren()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local pName = string.lower(obj.Name)
            if string.find(pName, "money") or string.find(pName, "cash") or string.find(pName, "drop") then
                local partPos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                local dist = (hrp.Position - partPos).Magnitude
                if dist <= 30 then
                    interactWithCash(obj, hrp)
                end
            end
        end
    end
end

-- =============================================================================
-- AUTOMATION ROUTINES (DA HOOD SPECIFIC)
-- =============================================================================

-- 1. ATM Farm Loop
task.spawn(function()
    while true do
        task.wait(0.4)
        if State.AutoATM then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                -- Locate nearest intact ATM
                local nearestATM = nil
                local shortestDist = math.huge

                local function checkModel(model)
                    if not model then return end
                    local mName = string.lower(model.Name)
                    if string.find(mName, "atm") then
                        local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                        local mHum = model:FindFirstChildOfClass("Humanoid")
                        if head and (not mHum or mHum.Health > 0) then
                            local d = (hrp.Position - head.Position).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                nearestATM = head
                            end
                        end
                    end
                end

                for _, obj in ipairs(Workspace:GetChildren()) do
                    checkModel(obj)
                end
                local cashiersFolder = Workspace:FindFirstChild("Cashiers")
                if cashiersFolder then
                    for _, obj in ipairs(cashiersFolder:GetChildren()) do checkModel(obj) end
                end

                if nearestATM then
                    -- Position slightly behind or to the side of the ATM to avoid line of sight
                    local targetCFrame = nearestATM.CFrame * CFrame.new(0, 0, 2.5)
                    if (hrp.Position - targetCFrame.Position).Magnitude > 8 then
                        safeTeleport(targetCFrame.Position, 0)
                        task.wait(0.2)
                    end

                    -- Face ATM and strike
                    hrp.CFrame = CFrame.new(hrp.Position, nearestATM.Position)
                    attackTarget()
                    collectNearbyCash()
                end
            end
        end
    end
end)

-- 2. Cashier Farm Loop
task.spawn(function()
    while true do
        task.wait(0.45)
        if State.AutoCashier and not State.AutoATM then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local nearestCashier = nil
                local shortestDist = math.huge

                local function checkCashier(model)
                    if not model then return end
                    local mName = string.lower(model.Name)
                    if string.find(mName, "cashier") then
                        local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
                        local mHum = model:FindFirstChildOfClass("Humanoid")
                        if head and (not mHum or mHum.Health > 0) then
                            local d = (hrp.Position - head.Position).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                nearestCashier = head
                            end
                        end
                    end
                end

                local cashiersFolder = Workspace:FindFirstChild("Cashiers")
                if cashiersFolder then
                    for _, obj in ipairs(cashiersFolder:GetChildren()) do checkCashier(obj) end
                end
                for _, obj in ipairs(Workspace:GetChildren()) do checkCashier(obj) end

                if nearestCashier then
                    local targetCFrame = nearestCashier.CFrame * CFrame.new(0, 0, 2.8)
                    if (hrp.Position - targetCFrame.Position).Magnitude > 8 then
                        safeTeleport(targetCFrame.Position, 0)
                        task.wait(0.2)
                    end
                    hrp.CFrame = CFrame.new(hrp.Position, nearestCashier.Position)
                    attackTarget()
                    collectNearbyCash()
                end
            end
        end
    end
end)

-- 3. Auto Cash Magnet / Vacuum (Standalone Nearby Vacuum)
task.spawn(function()
    while true do
        task.wait(0.3)
        if State.AutoCashMagnet then
            collectNearbyCash()
        end
    end
end)

-- 4. Auto TP & Collect Dropped Cash (Map-Wide Active Teleport Hunter)
local CashBlacklist = {}
task.spawn(function()
    while true do
        task.wait(State.TPCashDelay or 0.2)
        if State.AutoTPCash then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if hum.Sit or hum.SeatPart then
                    ejectFromSeats(char, hum, hrp)
                    task.wait(0.05)
                end
                -- Clear blacklisted entries older than 8s
                local now = tick()
                for obj, t in pairs(CashBlacklist) do
                    if now - t > 8 then CashBlacklist[obj] = nil end
                end

                local ignored = Workspace:FindFirstChild("Ignored")
                local dropFolder = (ignored and ignored:FindFirstChild("Drop")) or Workspace:FindFirstChild("Drop")
                local candidates = {}

                local function scanFolder(folder)
                    if not folder then return end
                    for _, obj in ipairs(folder:GetChildren()) do
                        if (obj:IsA("BasePart") or obj:IsA("Model")) and not CashBlacklist[obj] then
                            local pName = string.lower(obj.Name)
                            if string.find(pName, "money") or string.find(pName, "cash") or string.find(pName, "drop") then
                                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                                if pos and pos.Y > -200 and pos.Y < 1200 then
                                    local dist = (hrp.Position - pos).Magnitude
                                    table.insert(candidates, { Object = obj, Position = pos, Distance = dist })
                                end
                            end
                        end
                    end
                end

                scanFolder(dropFolder)
                if #candidates == 0 and ignored then
                    scanFolder(ignored)
                end

                if #candidates > 0 and State.AutoTPCash then
                    -- Target closest dropped cash to minimize flight time
                    table.sort(candidates, function(a, b)
                        return a.Distance < b.Distance
                    end)

                    local target = candidates[1]
                    local targetObj = target.Object
                    local targetPos = target.Position

                    -- Safe tween glide directly to the cash drop (+2 studs elevation)
                    local moved = safeTeleport(targetPos + Vector3.new(0, 2.0, 0), 0)
                    if moved and State.AutoTPCash then
                        -- Collect cash immediately
                        local attempts = 0
                        while targetObj and targetObj.Parent and attempts < 3 and State.AutoTPCash do
                            attempts = attempts + 1
                            interactWithCash(targetObj, hrp)
                            task.wait(0.12)
                        end

                        if targetObj and targetObj.Parent then
                            CashBlacklist[targetObj] = tick()
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Auto Muscle Grinder (Weights & HeavyWeights)
task.spawn(function()
    while true do
        task.wait(0.25)
        if State.AutoWeights then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if char and hum and bp then
                local weight = char:FindFirstChild("[HeavyWeights]") or char:FindFirstChild("[Weights]") or char:FindFirstChild("HeavyWeights") or char:FindFirstChild("Weights")
                if not weight then
                    weight = bp:FindFirstChild("[HeavyWeights]") or bp:FindFirstChild("[Weights]") or bp:FindFirstChild("HeavyWeights") or bp:FindFirstChild("Weights")
                    if weight then
                        hum:EquipTool(weight)
                        task.wait(0.15)
                    end
                end

                if weight and weight.Parent == char then
                    pcall(function() weight:Activate() end)
                end
            end
        end
    end
end)

-- 5. Auto Boxing Bag Grinder
task.spawn(function()
    while true do
        task.wait(0.4)
        if State.AutoBoxingBag then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Locate nearest boxing bag
                local nearestBag = nil
                local shortestDist = math.huge
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local dName = string.lower(obj.Name)
                        if string.find(dName, "punch") or string.find(dName, "boxingbag") or string.find(dName, "punchingbag") then
                            local part = obj:IsA("Model") and (obj:FindFirstChild("Hitbox") or obj:FindFirstChildWhichIsA("BasePart")) or obj
                            if part then
                                local d = (hrp.Position - part.Position).Magnitude
                                if d < shortestDist then
                                    shortestDist = d
                                    nearestBag = part
                                end
                            end
                        end
                    end
                end

                if nearestBag then
                    if (hrp.Position - nearestBag.Position).Magnitude > 7 then
                        safeTeleport(nearestBag.Position + Vector3.new(0, 0, 3.5), 0)
                        task.wait(0.2)
                    end
                    hrp.CFrame = CFrame.new(hrp.Position, nearestBag.Position)
                    attackTarget()
                end
            end
        end
    end
end)

-- 6. Auto Eat / Smart Heal
task.spawn(function()
    while true do
        task.wait(0.8)
        if State.AutoEat then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if hum and hum.Health < State.EatThreshold and bp then
                local foodNames = { "[Pizza]", "[Taco]", "[Chicken]", "[Cranberry]", "[Donut]", "[Hamburger]", "Pizza", "Taco", "Chicken", "Cranberry", "Donut" }
                local foodTool = nil
                for _, fn in ipairs(foodNames) do
                    foodTool = char:FindFirstChild(fn) or bp:FindFirstChild(fn)
                    if foodTool then break end
                end

                if foodTool then
                    if foodTool.Parent == bp then
                        hum:EquipTool(foodTool)
                        task.wait(0.2)
                    end
                    if foodTool.Parent == char then
                        pcall(function() foodTool:Activate() end)
                    end
                end
            end
        end
    end
end)

-- 7. Auto Stomp Knocked Players
task.spawn(function()
    while true do
        task.wait(0.35)
        if State.AutoStomp then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local pChar = p.Character
                        local pHum = pChar:FindFirstChildOfClass("Humanoid")
                        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                        local isKO = pChar:FindFirstChild("BodyEffects") and pChar.BodyEffects:FindFirstChild("K.O")
                        local koVal = isKO and isKO.Value

                        if pHum and pRoot and (koVal == true or pHum.Health <= 15 or pHum.PlatformStand) then
                            local dist = (hrp.Position - pRoot.Position).Magnitude
                            if dist <= 12 then
                                pcall(function()
                                    local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
                                    if mainEvent then
                                        mainEvent:FireServer("Stomp")
                                    else
                                        -- Fallback: Emulate stomp key
                                        VirtualUser:SetKeyDown("e")
                                        task.wait(0.05)
                                        VirtualUser:SetKeyUp("e")
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 8. Auto Reload
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoReload then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and (tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip")) then
                    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip")
                    if ammo and ammo.Value <= 0 then
                        pcall(function()
                            local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
                            if mainEvent then
                                mainEvent:FireServer("Reload", tool)
                            else
                                VirtualUser:SetKeyDown("r")
                                task.wait(0.05)
                                VirtualUser:SetKeyUp("r")
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- 9. Anti-Ragdoll / Quick Recovery
task.spawn(function()
    while true do
        task.wait(0.15)
        if State.AntiRagdoll then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown or hum.PlatformStand then
                    hum.PlatformStand = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

-- 10. Downed Anti-Stomp Safe Sky Shield
task.spawn(function()
    while true do
        task.wait(0.2)
        if State.DownedAntiStomp then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local be = char and char:FindFirstChild("BodyEffects")
            local isKO = be and be:FindFirstChild("K.O") and be["K.O"].Value
            if hum and hrp and (isKO or hum.Health <= 15 or hum.PlatformStand) then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 4.5, 0)
            end
        end
    end
end)

-- 11. Combat Aimbot & Target Helpers
local function isDaHoodTargetAlive(p)
    if not p or p == LocalPlayer then return false end
    local char = p.Character
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local be = char:FindFirstChild("BodyEffects")
    if be then
        local dead = be:FindFirstChild("Dead")
        local ko = be:FindFirstChild("K.O")
        if (dead and dead.Value == true) or (ko and ko.Value == true) then
            return false
        end
    end
    return (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")) ~= nil
end

local function getBestAimbotTarget()
    local mouseLoc = UserInputService:GetMouseLocation()
    local bestTarget = nil
    local minDistance = State.AimbotFOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isDaHoodTargetAlive(p) then
            local char = p.Character
            local part = char:FindFirstChild(State.AimPart) or char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso")
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (mouseLoc - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        bestTarget = { Part = part, Player = p, Position = part.Position }
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Aimbot Input Handlers
local isAiming = false
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == State.AimKey then
        isAiming = true
    end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == State.AimKey then
        isAiming = false
    end
end))

-- Aimbot Camera Interpolation
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if State.AimbotEnabled and isAiming then
        local target = getBestAimbotTarget()
        if target and target.Part then
            local targetPos = target.Part.Position
            if State.Prediction then
                local vel = target.Part.AssemblyLinearVelocity or target.Part.Velocity or Vector3.zero
                targetPos = targetPos + (vel * State.PredictionMultiplier)
            end
            local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
            if State.AimSmoothness <= 1 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(State.AimSmoothness, 1))
            end
        end
    end
end))

-- 12. Hitbox Expander Loop
local OriginalHitboxes = {}
task.spawn(function()
    while true do
        task.wait(0.4)
        if State.HitboxExpander then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isDaHoodTargetAlive(p) then
                    local char = p.Character
                    local head = char and char:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then
                        if not OriginalHitboxes[head] then
                            OriginalHitboxes[head] = { Size = head.Size, CanCollide = head.CanCollide, Transparency = head.Transparency }
                        end
                        head.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                        head.Transparency = 0.65
                        head.CanCollide = false
                    end
                end
            end
        elseif next(OriginalHitboxes) ~= nil then
            for part, data in pairs(OriginalHitboxes) do
                if part and part.Parent then
                    pcall(function()
                        part.Size = data.Size
                        part.Transparency = data.Transparency
                        part.CanCollide = data.CanCollide
                    end)
                end
            end
            table.clear(OriginalHitboxes)
        end
    end
end)

-- 10. Anti-AFK Idle Keep-Alive Protection
task.spawn(function()
    local idledConnection = LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
            end)
        end
    end)
    table.insert(Connections, idledConnection)
end)

-- 11. WalkSpeed & JumpPower Monitor
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if State.WalkSpeedBoost and hum.WalkSpeed ~= State.WalkSpeedValue then
                hum.WalkSpeed = State.WalkSpeedValue
            end
            if State.JumpPowerBoost and hum.JumpPower ~= State.JumpPowerValue then
                hum.JumpPower = State.JumpPowerValue
            end
        end
    end
end)

-- 12. Infinite Jump Engine
local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
table.insert(Connections, jumpConn)

-- 13. Universal Noclip Loop
local noclipConn = RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)
table.insert(Connections, noclipConn)

-- 14. Fullbright Engine
local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldFogEnd = Lighting.FogEnd
local oldGlobalShadows = Lighting.GlobalShadows
local oldAmbient = Lighting.Ambient

local function applyFullbright(enable)
    if enable then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.Brightness = oldBrightness
        Lighting.ClockTime = oldClockTime
        Lighting.FogEnd = oldFogEnd
        Lighting.GlobalShadows = oldGlobalShadows
        Lighting.Ambient = oldAmbient
    end
end

-- =============================================================================
-- DRAWING API / CASH, PLAYER ESP & FOV RING
-- =============================================================================
local hasDrawing = pcall(function() return Drawing.new("Text") end)
local FOVCircle = nil

if hasDrawing then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.5
        FOVCircle.Filled = false
        FOVCircle.Color = Color3.fromRGB(0, 235, 255)
        FOVCircle.Transparency = 0.8
        FOVCircle.Radius = State.AimbotFOV
        FOVCircle.Visible = false
    end)
end

local function clearESP()
    for _, item in pairs(CashESPDrawings) do
        pcall(function() item:Remove() end)
    end
    table.clear(CashESPDrawings)

    for _, item in pairs(ESPBoxes) do
        pcall(function()
            if item.Box then item.Box:Remove() end
            if item.Text then item.Text:Remove() end
        end)
    end
    table.clear(ESPBoxes)
end

if hasDrawing then
    local renderConn = RunService.RenderStepped:Connect(function()
        -- FOV Circle Position
        if FOVCircle then
            FOVCircle.Visible = State.AimbotEnabled and State.ShowFOVRing
            FOVCircle.Radius = State.AimbotFOV
            FOVCircle.Position = UserInputService:GetMouseLocation()
        end
        -- Cash ESP
        if State.CashESP then
            local ignored = Workspace:FindFirstChild("Ignored")
            local dropFolder = (ignored and ignored:FindFirstChild("Drop")) or Workspace:FindFirstChild("Drop")
            if dropFolder then
                local currentIds = {}
                for _, obj in ipairs(dropFolder:GetChildren()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local pName = string.lower(obj.Name)
                        if string.find(pName, "money") or string.find(pName, "cash") or string.find(pName, "drop") then
                            local id = tostring(obj)
                            currentIds[id] = true
                            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)

                            if onScreen then
                                if not CashESPDrawings[id] then
                                    local txt = Drawing.new("Text")
                                    txt.Size = 13
                                    txt.Center = true
                                    txt.Outline = true
                                    txt.OutlineColor = Color3.fromRGB(0, 0, 0)
                                    txt.Color = Color3.fromRGB(85, 255, 127)
                                    CashESPDrawings[id] = txt
                                end
                                local d = math.floor((Camera.CFrame.Position - pos).Magnitude)
                                CashESPDrawings[id].Text = "💵 Cash [" .. d .. "m]"
                                CashESPDrawings[id].Position = Vector2.new(screenPos.X, screenPos.Y)
                                CashESPDrawings[id].Visible = true
                            elseif CashESPDrawings[id] then
                                CashESPDrawings[id].Visible = false
                            end
                        end
                    end
                end

                for id, txt in pairs(CashESPDrawings) do
                    if not currentIds[id] then
                        pcall(function() txt:Remove() end)
                        CashESPDrawings[id] = nil
                    end
                end
            end
        else
            for id, txt in pairs(CashESPDrawings) do
                pcall(function() txt:Remove() end)
                CashESPDrawings[id] = nil
            end
        end

        -- Player ESP
        if State.PlayerESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local pChar = p.Character
                    local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                    local pHum = pChar:FindFirstChildOfClass("Humanoid")
                    if pRoot and pHum and pHum.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
                        if onScreen then
                            if not ESPBoxes[p.UserId] then
                                local box = Drawing.new("Square")
                                box.Thickness = 1.5
                                box.Filled = false
                                box.Color = Color3.fromRGB(255, 65, 85)

                                local text = Drawing.new("Text")
                                text.Size = 12
                                text.Center = true
                                text.Outline = true
                                text.Color = Color3.fromRGB(255, 255, 255)

                                ESPBoxes[p.UserId] = { Box = box, Text = text }
                            end

                            local item = ESPBoxes[p.UserId]
                            local dist = math.floor((Camera.CFrame.Position - pRoot.Position).Magnitude)
                            local head = pChar:FindFirstChild("Head")
                            local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or screenPos
                            local footPos = Camera:WorldToViewportPoint(pRoot.Position - Vector3.new(0, 3, 0))

                            local h = math.abs(headPos.Y - footPos.Y)
                            local w = h / 2

                            item.Box.Size = Vector2.new(w, h)
                            item.Box.Position = Vector2.new(screenPos.X - w / 2, screenPos.Y - h / 2)
                            item.Box.Visible = true

                            item.Text.Text = string.format("%s [%dm] (%d HP)", p.DisplayName, dist, math.floor(pHum.Health))
                            item.Text.Position = Vector2.new(screenPos.X, screenPos.Y - h / 2 - 14)
                            item.Text.Visible = true
                        elseif ESPBoxes[p.UserId] then
                            ESPBoxes[p.UserId].Box.Visible = false
                            ESPBoxes[p.UserId].Text.Visible = false
                        end
                    elseif ESPBoxes[p.UserId] then
                        ESPBoxes[p.UserId].Box.Visible = false
                        ESPBoxes[p.UserId].Text.Visible = false
                    end
                end
            end
        else
            for id, item in pairs(ESPBoxes) do
                pcall(function()
                    item.Box:Remove()
                    item.Text:Remove()
                end)
                ESPBoxes[id] = nil
            end
        end
    end)
    table.insert(Connections, renderConn)
end

-- =============================================================================
-- [PULLZ PRO] SIGNATURE CYBER SUITE UI (DA HOOD EDITION)
-- =============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PullZ_DaHood_" .. tostring(math.random(10000, 99999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
SubTitleText.Text = "D A   H O O D"
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

local spinnerActive = true
task.spawn(function()
    while spinnerActive and SpinnerOuter and SpinnerOuter.Parent do
        SpinnerGradient.Rotation = (tick() * 320) % 360
        task.wait()
    end
end)

local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
TweenService:Create(SpinnerOuter, fadeInInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(SpinnerInner, fadeInInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(PercentText, fadeInInfo, {TextTransparency = 0}):Play()
TweenService:Create(TitleText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 60)}):Play()
TweenService:Create(SubTitleText, TweenInfo.new(0.7, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, 95)}):Play()

task.wait(0.5)

for i = 1, 100 do
    PercentText.Text = i .. "%"
    task.wait(0.01)
end

TweenService:Create(PercentText, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 52}):Play()
task.wait(0.1)
TweenService:Create(PercentText, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {TextSize = 42}):Play()
task.wait(0.15)
PercentText.Text = "OK"
task.wait(0.3)

TweenService:Create(Shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 400, 0, 400), Position = UDim2.new(0.5, -200, 0.5, -220), BackgroundTransparency = 0.8}):Play()

local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
TweenService:Create(SpinnerOuter, fadeOutInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(SpinnerInner, fadeOutInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(PercentText, fadeOutInfo, {TextTransparency = 1}):Play()
TweenService:Create(TitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 40)}):Play()
local finishTween = TweenService:Create(SubTitleText, fadeOutInfo, {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, 75)})
finishTween:Play()
TweenService:Create(Shockwave, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()

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
local Stats = game:GetService("Stats")
local Watermark = Instance.new("Frame")
Watermark.Name = "WatermarkHUD"
Watermark.Size = UDim2.new(0, 310, 0, 30)
Watermark.Position = UDim2.new(0, 14, 0, 14)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Watermark.BorderSizePixel = 0
Watermark.Visible = true
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
WatermarkLabel.Text = "⚡ PULLZ | DA HOOD | 60 FPS"
WatermarkLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
WatermarkLabel.Font = Enum.Font.GothamMedium
WatermarkLabel.TextSize = 11
WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
WatermarkLabel.Parent = Watermark

local frameCount = 0
local lastFpsTime = tick()
table.insert(Connections, RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFpsTime >= 0.5 then
        local fps = math.floor(frameCount / (now - lastFpsTime))
        local ping = 40
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        WatermarkLabel.Text = string.format("⚡ PULLZ | DA HOOD | %s | %d FPS | %dms", tostring(getgenv().PullZLicenseTier or "24H"), fps, ping)
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

task.spawn(function()
    local rot = 0
    while BorderFrame and BorderFrame.Parent do
        rot = (rot + 1) % 360
        if StrokeGradient then StrokeGradient.Rotation = rot end
        if MinContainerGradient then MinContainerGradient.Rotation = rot end
        task.wait(0.02)
    end
end)

-- Top Action Bar
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
    if getgenv().DaHoodSuiteUnload then
        getgenv().DaHoodSuiteUnload()
    else
        ScreenGui:Destroy()
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

local minDragStart = nil
MinimizedBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        minDragStart = input.Position
    end
end)

MinimizedBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if minDragStart and (input.Position - minDragStart).Magnitude < 10 then
            MinimizedBtn.Visible = false
            BorderFrame.Visible = true
        end
    end
end)

-- Sidebar Navigation
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
SubTitle.Text = "D A   H O O D"
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

local TabList = Instance.new("UIListLayout")
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 5)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Parent = Sidebar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 75)
TabPadding.Parent = Sidebar

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

-- =============================================================================
-- UI COMPONENT BUILDERS (SIGNATURE PULLZ SUITE)
-- =============================================================================
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

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end))

    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function createButton(parent, text, desc, callback, btnLabel)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 48)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local title = Instance.new("TextLabel")
    title.Text = text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(220, 225, 235)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, -115, 0, 20)
    title.Position = UDim2.new(0, 14, 0, (desc and desc ~= "") and 6 or 14)
    title.BackgroundTransparency = 1
    title.Parent = card

    if desc and desc ~= "" then
        local descLbl = Instance.new("TextLabel")
        descLbl.Text = desc
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 10
        descLbl.TextColor3 = Color3.fromRGB(140, 150, 170)
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Size = UDim2.new(1, -115, 0, 16)
        descLbl.Position = UDim2.new(0, 14, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Parent = card
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 28)
    btn.Position = UDim2.new(1, -100, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
    btn.BorderSizePixel = 0
    btn.Text = btnLabel or "SELECT"
    btn.TextColor3 = Color3.fromRGB(100, 150, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = card

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(36, 44, 64) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(28, 34, 48) }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        showNotification(text, "Triggered successfully", true)
        callback()
    end)
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

-- =============================================================================
-- BUILD CATEGORIZED PAGES (PULLZ DA HOOD)
-- =============================================================================
local farmPage = createTab("💰 Farming")
local combatPage = createTab("🎯 Combat")
local defPage = createTab("🛡️ Defense")
local tpPage = createTab("📍 Teleports")
local visPage = createTab("👁️ Visuals")
local movPage = createTab("⚡ Movement")
local setPage = createTab("⚙️ Settings")

-- Tab 1: 💰 Farming
createHeader(farmPage, "Cash & Economy Automation")

createToggle(farmPage, "Auto ATM Farm", State.AutoATM, function(s)
    State.AutoATM = s
end)

createToggle(farmPage, "Auto Cashier Farm", State.AutoCashier, function(s)
    State.AutoCashier = s
end)

createToggle(farmPage, "Auto TP & Collect Cash", State.AutoTPCash, function(s)
    State.AutoTPCash = s
end)

createSlider(farmPage, "TP Cash Delay", 5, 50, math.floor((State.TPCashDelay or 0.15) * 100), " ms", function(v)
    State.TPCashDelay = v / 100
end)

createToggle(farmPage, "Auto Cash Magnet / Vacuum", State.AutoCashMagnet, function(s)
    State.AutoCashMagnet = s
end)

createHeader(farmPage, "Gym & Fitness Automation")

createToggle(farmPage, "Auto Muscle / Weights", State.AutoWeights, function(s)
    State.AutoWeights = s
end)

createToggle(farmPage, "Auto Boxing Bag", State.AutoBoxingBag, function(s)
    State.AutoBoxingBag = s
end)

-- Tab 2: 🎯 Combat
createHeader(combatPage, "Camera Lock & Gun Assists")

createToggle(combatPage, "Camera Lock (Aimbot)", State.AimbotEnabled, function(s)
    State.AimbotEnabled = s
    if FOVCircle then FOVCircle.Visible = State.AimbotEnabled and State.ShowFOVRing end
end)

createToggle(combatPage, "Show Aimbot FOV Ring", State.ShowFOVRing, function(s)
    State.ShowFOVRing = s
    if FOVCircle then FOVCircle.Visible = State.AimbotEnabled and State.ShowFOVRing end
end)

createSegment(combatPage, "Aimbot Target Bone", { "Head", "UpperTorso", "HumanoidRootPart" }, State.AimPart or "Head", function(part)
    State.AimPart = part
    State.AimAtHead = (part == "Head")
end)

createSlider(combatPage, "Aimbot FOV Radius", 40, 350, State.AimbotFOV, " px", function(v)
    State.AimbotFOV = v
    if FOVCircle then FOVCircle.Radius = v end
end)

createSlider(combatPage, "Camera Smoothing", 1, 12, State.AimSmoothness, "", function(v)
    State.AimSmoothness = v
end)

createToggle(combatPage, "Lead Velocity Prediction", State.Prediction, function(s)
    State.Prediction = s
end)

createHeader(combatPage, "Hitbox Expander")

createToggle(combatPage, "Hitbox Expander", State.HitboxExpander, function(s)
    State.HitboxExpander = s
end)

createSlider(combatPage, "Hitbox Size", 3, 14, State.HitboxSize, " studs", function(v)
    State.HitboxSize = v
end)

-- Tab 3: 🛡️ Defense
createHeader(defPage, "Combat & Survival")

createToggle(defPage, "Auto Eat / Smart Heal", State.AutoEat, function(s)
    State.AutoEat = s
end)

createSlider(defPage, "Eat Health Threshold", 20, 95, State.EatThreshold, "% HP", function(v)
    State.EatThreshold = v
end)

createToggle(defPage, "Downed Anti-Stomp Safe Sky", State.DownedAntiStomp, function(s)
    State.DownedAntiStomp = s
end)

createToggle(defPage, "Auto Stomp Downed Players", State.AutoStomp, function(s)
    State.AutoStomp = s
end)

createToggle(defPage, "Auto Reload Gun", State.AutoReload, function(s)
    State.AutoReload = s
end)

createToggle(defPage, "Anti-Ragdoll Recovery", State.AntiRagdoll, function(s)
    State.AntiRagdoll = s
end)

createButton(defPage, "Force Eject & Stand Up", "Breaks any active seat welds and forces character upright", function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    ejectFromSeats(char, hum, hrp)
end, "EJECT")

-- Tab 4: 📍 Teleports
createHeader(tpPage, "Map Locations & Stores")

for locName, coords in pairs(Locations) do
    createButton(tpPage, locName, "Coordinates: " .. tostring(math.floor(coords.X)) .. ", " .. tostring(math.floor(coords.Z)), function()
        safeTeleport(coords, 3.5)
    end, "TELEPORT")
end

-- Tab 5: 👁️ Visuals
createHeader(visPage, "ESP & Highlighting")

createToggle(visPage, "Player Box & Info ESP", State.PlayerESP, function(s)
    State.PlayerESP = s
    if not s then clearESP() end
end)

createToggle(visPage, "Dropped Cash ESP", State.CashESP, function(s)
    State.CashESP = s
    if not s then clearESP() end
end)

-- Tab 6: ⚡ Movement
createHeader(movPage, "Player Physics Modifiers")

createToggle(movPage, "WalkSpeed Booster", State.WalkSpeedBoost, function(s)
    State.WalkSpeedBoost = s
    if not s then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

createSlider(movPage, "Custom WalkSpeed", 16, 75, State.WalkSpeedValue, " spd", function(v)
    State.WalkSpeedValue = v
    if State.WalkSpeedBoost then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

createToggle(movPage, "JumpPower Booster", State.JumpPowerBoost, function(s)
    State.JumpPowerBoost = s
    if not s then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
end)

createSlider(movPage, "Custom JumpPower", 50, 150, State.JumpPowerValue, " pwr", function(v)
    State.JumpPowerValue = v
    if State.JumpPowerBoost then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

createToggle(movPage, "Infinite Air-Jump", State.InfiniteJump, function(s)
    State.InfiniteJump = s
end)

createToggle(movPage, "Universal Noclip", State.Noclip, function(s)
    State.Noclip = s
end)

createToggle(movPage, "Fullbright & Ambient", State.Fullbright, function(s)
    State.Fullbright = s
    applyFullbright(s)
end)

-- Tab 7: ⚙️ Settings
createHeader(setPage, "HUD & Watermark")

createToggle(setPage, "Watermark HUD Pill", true, function(s)
    Watermark.Visible = s
end)

createHeader(setPage, "Suite Preferences & Lifecycle")

createToggle(setPage, "Anti-AFK Protection", State.AntiAFK, function(s)
    State.AntiAFK = s
end)

createButton(setPage, "Emergency Chair Eject", "Instantly ejects character from any stuck seat/chair", function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    ejectFromSeats(char, hum, hrp)
end, "EJECT")

createButton(setPage, "Self-Destruct / Clean Unload", "Terminates all loops, restores physics and removes UI cleanly", function()
    if getgenv().DaHoodSuiteUnload then
        getgenv().DaHoodSuiteUnload()
    end
end, "UNLOAD")

createHeader(setPage, "Keybinds & Diagnostics")

local diagCard = Instance.new("Frame")
diagCard.Size = UDim2.new(1, 0, 0, 48)
diagCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
diagCard.BorderSizePixel = 0
diagCard.Parent = setPage

local diagCorner = Instance.new("UICorner")
diagCorner.CornerRadius = UDim.new(0, 6)
diagCorner.Parent = diagCard

local diagText = Instance.new("TextLabel")
diagText.Size = UDim2.new(1, -24, 1, 0)
diagText.Position = UDim2.new(0, 12, 0, 0)
diagText.BackgroundTransparency = 1
diagText.Text = "Status: ACTIVE | Tier: " .. tostring(getgenv().PullZLicenseTier or "24H") .. " | Toggle: [Insert]"
diagText.TextColor3 = Color3.fromRGB(100, 150, 255)
diagText.Font = Enum.Font.GothamMedium
diagText.TextSize = 12
diagText.TextXAlignment = Enum.TextXAlignment.Left
diagText.Parent = diagCard

-- Activate default tab
switchTab("💰 Farming")

-- Toggle Keybind Handler ([Insert])
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
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

-- =============================================================================
-- UNLOAD HANDLER
-- =============================================================================
getgenv().DaHoodSuiteUnload = function()
    -- Disconnect event connections
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    -- Reset Lighting
    applyFullbright(false)

    -- Reset Character properties
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end

    -- Cancel any active flight/tween
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end

    -- Reset Hitboxes
    if next(OriginalHitboxes) ~= nil then
        for part, data in pairs(OriginalHitboxes) do
            if part and part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                    part.CanCollide = data.CanCollide
                end)
            end
        end
        table.clear(OriginalHitboxes)
    end

    -- Clear FOV Circle
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end

    -- Clear ESP
    clearESP()

    -- Remove UI
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
    if MinimizedBtn and MinimizedBtn.Parent then
        MinimizedBtn:Destroy()
    end

    getgenv().DaHoodSuiteLoaded = false
    getgenv().DaHoodSuiteUnload = nil
    print("[PullZ Da Hood] Suite cleanly unloaded.")
end

showNotification("PullZ Pro", "PullZ Da Hood Suite Ready! [" .. tostring(getgenv().PullZLicenseTier or "24H") .. "]", true)
print("[PullZ Da Hood] Ultimate Automation Suite successfully initialized!")

end -- end initMainHub

-- =========================================================================
-- EXECUTE AUTHENTICATION GATEWAY
-- =========================================================================
initAuthGateway(initMainHub)
