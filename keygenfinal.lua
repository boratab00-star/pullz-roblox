--[[
    =============================================================================
    PULLZ SUITE | UNIVERSAL FIREBASE KEY SYSTEM TEMPLATE (KEYGENFINAL)
    =============================================================================
    Usage for any new script:
      1. Configure CONFIG table below (GameId, DisplayName, KeyUrl).
      2. Put your main game script / GUI code inside `initMainHub()`.
      3. Run or loadstring!
    =============================================================================
--]]

-- =============================================================================
-- [1] SUITE CONFIGURATION (Customize for each new game)
-- =============================================================================
local CONFIG = {
    -- Unique Identifier for single-game lock (must match Firebase 'game' field)
    -- e.g. "dahood", "rivals", "fisch", "bloxburg", "beeswarm", "doors"
    GameId = "rivals",

    -- Title displayed on the UI
    DisplayName = "R I V A L S",

    -- Website link for the "Get your 24 hour key" button
    KeyUrl = "https://pullzcheats.org/rivals.html",

    -- Local cache file to remember activated key on user's PC
    CacheFile = "pullz_key.txt",

    -- Firebase Firestore Gateway Config (Project: key-gen-4a3fb)
    FirebaseProjectId = "key-gen-4a3fb",

    -- Developer bypass keys for fast testing
    DevBypassKeys = {
        ["PULLZ-DEV"] = true,
        ["PULLZ"] = true,
        ["DEV"] = true
    }
}

-- =============================================================================
-- [2] CORE SERVICES & REQUESTER SETUP
-- =============================================================================
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local FIREBASE_REST_URL = "https://firestore.googleapis.com/v1/projects/" .. CONFIG.FirebaseProjectId .. "/databases/(default)/documents/keys/"
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

-- =============================================================================
-- [3] FIREBASE FIRESTORE VERIFICATION ENGINE
-- =============================================================================
local function verifyKey(userKey)
    local cleanKey = string.upper(userKey:gsub("%s+", ""))
    if cleanKey == "" then
        return false, "Error: Please enter a license key."
    end

    -- 1. Check Developer Bypass
    if CONFIG.DevBypassKeys[cleanKey] then
        getgenv().PullZLicenseTier = "DEVELOPER"
        return true, "Developer Bypass Authorized!", { is_dev = true }
    end

    if not httpRequest then
        return false, "Executor missing HTTP capability (request/syn.request)"
    end

    local myHWID = getClientHWID()

    -- 2. Query Firebase Firestore via direct REST API
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

    -- Safe status code parsing (handles number, string, or status_code)
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

    -- 3. Game Scope Authorization Check
    -- If key is single-game for another game, reject cleanly with non-overflowing English text
    if allowedGame ~= "all" and allowedGame:lower() ~= CONFIG.GameId:lower() then
        return false, "Access Denied: Key is for " .. string.upper(allowedGame) .. " only!\nGet a " .. CONFIG.DisplayName .. " key or an All-Access pass."
    end

    -- 4. Determine License Tier Label
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

    -- 5. Check HWID and Expiration
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

        local patchRawStatus = patchRes and (patchRes.StatusCode or patchRes.status_code or patchRes.Status or patchRes.status)
        local patchStatusNum = tonumber(patchRawStatus) or (patchRawStatus and tonumber(tostring(patchRawStatus):match("%d+")))
        if not patchStatusNum or patchStatusNum < 200 or patchStatusNum >= 300 then
            return false, "Failed to claim key: HTTP " .. tostring(patchStatusNum)
        end
    end

    return true, "Key validated successfully!", fields
end

-- Key Local Caching
local function getCachedKey()
    if isfile and isfile(CONFIG.CacheFile) and readfile then
        local ok, content = pcall(readfile, CONFIG.CacheFile)
        if ok and content and content:gsub("%s+", "") ~= "" then
            return content:gsub("%s+", "")
        end
    end
    return nil
end

local function saveCachedKey(key)
    if writefile then
        pcall(writefile, CONFIG.CacheFile, key)
    end
end

local function clearCachedKey()
    if isfile and isfile(CONFIG.CacheFile) and delfile then
        pcall(delfile, CONFIG.CacheFile)
    end
end

-- =============================================================================
-- [4] SIGNATURE CYBER-GLASSMORPHISM KEY UI MODAL
-- =============================================================================
local function initAuthGateway(onSuccess)
    -- Remove prior modal instance
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

    -- Create ScreenGui
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
    KeySubTitle.Text = CONFIG.DisplayName:upper() .. "   A U T H E N T I C A T I O N"
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
                openurl(CONFIG.KeyUrl)
            elseif open_url then
                open_url(CONFIG.KeyUrl)
            elseif syn and syn.open_url then
                syn.open_url(CONFIG.KeyUrl)
            end
        end)
        pcall(function()
            if setclipboard then
                setclipboard(CONFIG.KeyUrl)
            end
        end)
        GetKeyBtn.Text = "Opening Browser & Copied!"
        task.delay(2.5, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = "Get your 24 hour key"
            end
        end)
    end)

    -- HWID Indicator at Footer
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

    -- Verification Process with full pcall protection
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
                    VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
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

-- =============================================================================
-- [5] MAIN HUB / SCRIPT BODY ENTRY POINT
-- =============================================================================
local function initMainHub()
    print("-----------------------------------------------------------------")
    print(" [PULLZ SUITE] Authentication Passed!")
    print(" Active Game:  " .. CONFIG.DisplayName)
    print(" License Tier: " .. tostring(getgenv().PullZLicenseTier or "ACTIVE"))
    print("-----------------------------------------------------------------")

    -- =========================================================================
    -- PUT YOUR GAME CODE, ESP, AIMBOT, HUD, OR MENU BELOW:
    -- =========================================================================

    -- Example Watermark HUD with active tier display:
    -- local tierTag = getgenv().PullZLicenseTier and (" [" .. tostring(getgenv().PullZLicenseTier) .. "]") or ""
    -- print("Watermark: ⚡ PULLZ" .. tierTag .. " | READY")

    -- Example Notification:
    -- game:GetService("StarterGui"):SetCore("SendNotification", {
    --     Title = "PullZ " .. CONFIG.DisplayName,
    --     Text = "Suite Loaded! Tier: [" .. tostring(getgenv().PullZLicenseTier) .. "]",
    --     Duration = 5
    -- })
end

-- =============================================================================
-- [6] LAUNCH AUTHENTICATION
-- =============================================================================
initAuthGateway(initMainHub)
