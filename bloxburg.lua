--[[
    =========================================================================
    BLOXBURG STYLEZ HAIRDRESSER - NATIVE NETWORK & STACK-BYPASS SUITE
    =========================================================================
    - Integrat cu: Stack Bypass + Network Module + Hairdresser Autofarm
    - Hook pe funcția de stack check 'i' din getgc()
    - Trimitere directă pe remote prin debug.getupvalue(DataService.FireServer, 5)
    - Detectare precisă a clientului "StylezHairStudioCustomer"
    - Verificare stare așezat (Humanoid.FloorMaterial == Air sau Sit == true)
    - Poziționare laterală în First Person (nu blochează scaunul)
    - UI compact, modern și eficient cu statistici live și controale
    =========================================================================
--]]

-- Curățare instanță precedentă
if getgenv().StylezHairLoaded then
    pcall(function()
        if getgenv().StylezHairUnload then getgenv().StylezHairUnload() end
    end)
end
getgenv().StylezHairLoaded = true

-- // 1. STACK BYPASS (Hookfunc pe verificarea internă 'i' din Bloxburg)
pcall(function()
    if getgc and hookfunction and debug and debug.getinfo then
        for _, value in pairs(getgc()) do
            if typeof(value) == "function" and not (iscclosure and iscclosure(value)) then
                local information = debug.getinfo(value)
                if information and information.name == "i" then
                    hookfunction(value, function() end)
                end
            end
        end
    end
end)

-- // 2. SERVICII ROBLOX
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local client = Players.LocalPlayer
if not client then
    repeat task.wait(0.05) client = Players.LocalPlayer until client
end

-- // 3. NETWORK ENGINE (DataService Remote Layer)
local dataService = nil
local getRemote = nil

pcall(function()
    local modules = ReplicatedStorage:WaitForChild("Modules", 5)
    local dsModule = modules and modules:WaitForChild("DataService", 5)
    if dsModule then
        dataService = require(dsModule)
        if dataService and dataService.FireServer and debug and debug.getupvalue then
            getRemote = debug.getupvalue(dataService.FireServer, 5)
        end
    end
end)

local function fireServer(remoteType, args)
    if getRemote then
        local ok, res = pcall(function()
            local rem = getRemote(remoteType)
            if rem then
                rem:FireServer(args)
                return true
            end
            return false
        end)
        if ok and res then return true end
    end

    -- Fallback pe DataService direct
    if dataService and dataService.FireServer then
        pcall(function() dataService.FireServer(remoteType, args) end)
        return true
    end

    return false
end

local function invokeServer(remoteType, args)
    if getRemote then
        local ok, res = pcall(function()
            local rem = getRemote(remoteType, true)
            if rem then
                return rem:InvokeServer(args)
            end
            return nil
        end)
        if ok and res then return res end
    end
    return nil
end

-- Asigură începerea turei la job
local function ensureJob()
    pcall(function()
        local stats = ReplicatedStorage:FindFirstChild("Stats")
        local pStats = stats and stats:FindFirstChild(client.Name)
        local curJob = (pStats and pStats:FindFirstChild("Job") and pStats.Job.Value) or ""
        if curJob ~= "StylezHairdresser" then
            invokeServer("ToWork", { Type = "ToWork", Name = "StylezHairdresser" })
        end
    end)
end

-- // 4. CONFIGURARE & STARE
local Config = {
    Active = true,
    Delay = 0.25 -- Delay nativ rapid
}

local State = {
    CurrentStation = nil,
    CurrentCustomer = nil,
    Ignore = {},
    TotalServed = 0,
    TotalEarned = 0,
    Connections = {},
    ScreenGui = nil,
    OriginalCameraMode = client.CameraMode
}

-- Curățare periodică a tabelei ignore pentru clienții care au părăsit jocul
task.spawn(function()
    while true do
        task.wait(10)
        if not getgenv().StylezHairLoaded then break end
        for cust, _ in pairs(State.Ignore) do
            if not cust or not cust.Parent then
                State.Ignore[cust] = nil
            end
        end
    end
end)

-- // 5. FUNCȚII DE LOCALIZARE STAȚIE & CLIENȚI
local function getHairdresserWorkstationsFolder()
    local folder = nil
    pcall(function()
        folder = Workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations
    end)
    if folder then return folder end

    pcall(function()
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "HairdresserWorkstations" then
                folder = desc
                break
            end
        end
    end)
    return folder
end

local function closestHairdresserStation()
    local char = client.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local wsFolder = getHairdresserWorkstationsFolder()
    local station = nil
    local maxDistance = math.huge

    if wsFolder then
        for _, instance in pairs(wsFolder:GetChildren()) do
            local primaryPart = instance.PrimaryPart or instance:FindFirstChild("Chair") or instance:FindFirstChild("Seat") or instance:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local distance = (primaryPart.Position - hrp.Position).Magnitude
                if distance < maxDistance then
                    station = instance
                    maxDistance = distance
                end
            end
        end
    end

    return station, maxDistance
end

local function getSpawnedCharactersFolder()
    local folder = nil
    pcall(function()
        folder = Workspace._game.SpawnedCharacters
    end)
    if folder then return folder end

    pcall(function()
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "SpawnedCharacters" then
                folder = desc
                break
            end
        end
    end)
    return folder or Workspace
end

-- Găsește clientul StylezHairStudioCustomer cel mai apropiat de scaunul ales
local function getCustomerForStation(station)
    if not station then return nil end
    local chairPart = station.PrimaryPart or station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station:FindFirstChildWhichIsA("BasePart")
    if not chairPart then return nil end

    local scFolder = getSpawnedCharactersFolder()
    local bestCustomer = nil
    local bestDist = 4.5 -- Raza scaunului

    for _, instance in pairs(scFolder:GetChildren()) do
        if instance:IsA("Model") and instance ~= client.Character then
            local isStylezCustomer = (instance.Name == "StylezHairStudioCustomer") or instance.Name:lower():find("hair") or instance.Name:lower():find("customer")
            if isStylezCustomer then
                local primaryPart = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or instance:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    -- Distanță față de scaun (nu față de jucător, pentru a evita clienții altor scaune)
                    local dx = primaryPart.Position.X - chairPart.Position.X
                    local dz = primaryPart.Position.Z - chairPart.Position.Z
                    local horizDist = math.sqrt(dx * dx + dz * dz)
                    local vertDist = math.abs(primaryPart.Position.Y - chairPart.Position.Y)

                    if horizDist < 3.2 and vertDist < 5.0 and horizDist < bestDist then
                        bestDist = horizDist
                        bestCustomer = instance
                    end
                end
            end
        end
    end

    return bestCustomer
end

-- Aliniere laterală la postul de lucru în First Person
local function alignToStation(station)
    if not station then station = closestHairdresserStation() end
    if not station then return false end

    local char = client.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local chair = station.PrimaryPart or station:FindFirstChild("Chair") or station:FindFirstChild("Seat") or station:FindFirstChildWhichIsA("BasePart")
    if not chair then return false end

    ensureJob()

    -- Poziționare în lateral (RightVector * 2.2) privind spre scaun/oglindă
    local sidePos = chair.Position + (chair.CFrame.RightVector * 2.2) + (chair.CFrame.LookVector * 0.3) + Vector3.new(0, 0.5, 0)
    local targetPos = chair.Position + Vector3.new(0, 1.2, 0)
    hrp.CFrame = CFrame.new(sidePos, targetPos)

    pcall(function()
        client.CameraMode = Enum.CameraMode.LockFirstPerson
        client.CameraMinZoomDistance = 0.5
        client.CameraMaxZoomDistance = 0.5
    end)

    return true
end

-- =========================================================================
-- INTERFAȚĂ GRAFICĂ COMPACTĂ ȘI MODERNĂ (280 x 310 px)
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
    ScreenGui.Parent = client:WaitForChild("PlayerGui", 5) or client.PlayerGui
end
State.ScreenGui = ScreenGui

-- Fereastră principală
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
TitleText.Text = "✂️ Stylez Hairdresser Auto"
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

-- Drag logic
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

-- Corp
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -16, 1, -44)
Body.Position = UDim2.new(0, 8, 0, 40)
Body.BackgroundTransparency = 1
Body.Parent = Frame

-- Card Info Live
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
RowStation.Text = "📍 Post: Caut scaunul din salon..."
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
RowStatus.Size = UDim2.new(1, -12, 0, 22)
RowStatus.Position = UDim2.new(0, 8, 0, 66)
RowStatus.BackgroundTransparency = 1
RowStatus.Text = "⚡ Stare: Network Engine pregătit ✅"
RowStatus.TextColor3 = Color3.fromRGB(140, 240, 160)
RowStatus.Font = Enum.Font.Gotham
RowStatus.TextSize = 9
RowStatus.TextWrapped = true
RowStatus.TextXAlignment = Enum.TextXAlignment.Left
RowStatus.Parent = InfoCard

-- Buton Principal ACTIV / PAUZĂ
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 32)
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

-- Butoane Acțiuni
local AlignBtn = Instance.new("TextButton")
AlignBtn.Size = UDim2.new(0.48, 0, 0, 28)
AlignBtn.Position = UDim2.new(0, 0, 0, 134)
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

local ServeBtn = Instance.new("TextButton")
ServeBtn.Size = UDim2.new(0.48, 0, 0, 28)
ServeBtn.Position = UDim2.new(0.52, 0, 0, 134)
ServeBtn.BackgroundColor3 = Color3.fromRGB(28, 55, 36)
ServeBtn.Text = "✂️ Servește Manual"
ServeBtn.TextColor3 = Color3.fromRGB(130, 250, 170)
ServeBtn.Font = Enum.Font.GothamBold
ServeBtn.TextSize = 9
ServeBtn.BorderSizePixel = 0
ServeBtn.Parent = Body

local ServeCorner = Instance.new("UICorner")
ServeCorner.CornerRadius = UDim.new(0, 6)
ServeCorner.Parent = ServeBtn

-- Slider Viteză Servire (Delay)
local SliderBox = Instance.new("Frame")
SliderBox.Size = UDim2.new(1, 0, 0, 36)
SliderBox.Position = UDim2.new(0, 0, 0, 168)
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
SliderText.Text = "⏱️ Delay Servire (Secunde)"
SliderText.TextColor3 = Color3.fromRGB(180, 180, 190)
SliderText.Font = Enum.Font.GothamMedium
SliderText.TextSize = 9
SliderText.TextXAlignment = Enum.TextXAlignment.Left
SliderText.Parent = SliderBox

local SliderValText = Instance.new("TextLabel")
SliderValText.Size = UDim2.new(0.25, 0, 0, 16)
SliderValText.Position = UDim2.new(0.72, 0, 0, 2)
SliderValText.BackgroundTransparency = 1
SliderValText.Text = "0.25s"
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
SliderFill.Size = UDim2.new((Config.Delay - 0.05) / (2.0 - 0.05), 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

local isDraggingSlider = false
SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
        local x = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.05 + (x * (2.0 - 0.05))) * 100) / 100
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.2fs", Config.Delay)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local x = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Config.Delay = math.floor((0.05 + (x * (2.0 - 0.05))) * 100) / 100
        SliderFill.Size = UDim2.new(x, 0, 1, 0)
        SliderValText.Text = string.format("%.2fs", Config.Delay)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
    end
end)

-- Statistici
local StatsPill = Instance.new("Frame")
StatsPill.Size = UDim2.new(1, 0, 0, 26)
StatsPill.Position = UDim2.new(0, 0, 0, 210)
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
-- BUCALĂ PRINCIPALĂ (HAIRDRESSER AUTOFARM HANDLING)
-- =========================================================================

local function serveCustomer(station, customer)
    if not station or not customer then return false end
    local order = customer:FindFirstChild("Order")
    if not order then return false end

    local styleObj = order:FindFirstChild("Style")
    local colorObj = order:FindFirstChild("Color")
    if not styleObj or not colorObj then return false end

    local styleVal = styleObj.Value
    local colorVal = colorObj.Value

    -- Marchează în ignore
    State.Ignore[customer] = true

    RowStatus.Text = string.format("⚡ Trimit comanda pentru %s...", customer.Name)
    RowStatus.TextColor3 = Color3.fromRGB(100, 220, 255)

    -- Așteaptă delay-ul configurat
    task.wait(math.clamp(Config.Delay or 0.25, 0.05, 3.0))

    -- Trimitere payload JobCompleted către server
    local payload = {
        Type = "JobCompleted",
        Workstation = station,
        Order = { styleVal, colorVal }
    }
    local success = fireServer("JobCompleted", payload)

    if success then
        State.TotalServed = State.TotalServed + 1
        State.TotalEarned = State.TotalServed * 75

        RowStatus.Text = "🎉 Client servit cu succes! Aștept următorul..."
        RowStatus.TextColor3 = Color3.fromRGB(120, 255, 150)
        StatsText.Text = string.format("Total Serviți: %d   |   Bani Estimați: $%d", State.TotalServed, State.TotalEarned)
        print(string.format("[Stylez Autofarm] Client servit! Total: %d, Stil: %s, Culoare: %s", State.TotalServed, tostring(styleVal), tostring(colorVal)))
        return true
    else
        RowStatus.Text = "⚠️ Rețeaua nu a răspuns, reîncerc..."
        RowStatus.TextColor3 = Color3.fromRGB(255, 160, 100)
        return false
    end
end

-- Bucla de monitorizare și servire continuă
table.insert(State.Connections, task.spawn(function()
    while true do
        task.wait(0.1)

        if not getgenv().StylezHairLoaded then break end

        if Config.Active then
            pcall(function()
                ensureJob()

                local currentJob = ""
                local stats = ReplicatedStorage:FindFirstChild("Stats")
                local pStats = stats and stats:FindFirstChild(client.Name)
                if pStats and pStats:FindFirstChild("Job") then
                    currentJob = pStats.Job.Value
                end

                if currentJob == "StylezHairdresser" then
                    local station, dist = closestHairdresserStation()

                    if station and dist < 16 then
                        State.CurrentStation = station
                        RowStation.Text = string.format("📍 Post: %s (la %d studs)", station.Name, math.floor(dist))
                        RowStation.TextColor3 = Color3.fromRGB(120, 220, 160)

                        local customer = getCustomerForStation(station)

                        if customer then
                            State.CurrentCustomer = customer
                            local order = customer:FindFirstChild("Order")

                            if order then
                                local sVal = (order:FindFirstChild("Style") and order.Style.Value) or "-"
                                local cVal = (order:FindFirstChild("Color") and order.Color.Value) or "-"
                                RowClient.Text = "👤 Client: " .. customer.Name
                                RowOrder.Text = string.format("💇 Stil: #%s   |   🎨 Culoare: #%s", tostring(sVal), tostring(cVal))

                                local hum = customer:FindFirstChildOfClass("Humanoid")
                                -- Condiția nativă de așezat: FloorMaterial == Enum.Material.Air sau hum.Sit
                                local isSeated = (hum and (hum.FloorMaterial == Enum.Material.Air or hum.Sit))

                                if isSeated and not State.Ignore[customer] then
                                    serveCustomer(station, customer)
                                elseif State.Ignore[customer] then
                                    RowStatus.Text = "⏳ Clientul servit se ridică de pe scaun..."
                                    RowStatus.TextColor3 = Color3.fromRGB(200, 200, 220)
                                end
                            else
                                RowClient.Text = "👤 Client: " .. customer.Name .. " (se așază...)"
                            end
                        else
                            State.CurrentCustomer = nil
                            RowClient.Text = "👤 Client: Aștept client la scaun..."
                            RowOrder.Text = "💇 Stil: -   |   🎨 Culoare: -"
                            RowStatus.Text = "⚡ Stare: Scaun liber, vine următorul client..."
                            RowStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
                        end
                    else
                        RowStation.Text = "📍 Post: Mergi lângă un scaun din salon..."
                        RowStation.TextColor3 = Color3.fromRGB(255, 180, 100)
                        RowStatus.Text = "⚡ Stare: Aștept să te așezi lângă un scaun"
                        RowStatus.TextColor3 = Color3.fromRGB(200, 200, 210)
                    end
                else
                    RowStatus.Text = "⚡ Pornesc tura de frizer (StylezHairdresser)..."
                    RowStatus.TextColor3 = Color3.fromRGB(255, 200, 120)
                end
            end)
        end
    end
end))

-- =========================================================================
-- BUTOANE INTERFAȚĂ
-- =========================================================================

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
            client.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
            client.CameraMinZoomDistance = 0.5
            client.CameraMaxZoomDistance = 128
        end)
    end
end)

AlignBtn.MouseButton1Click:Connect(function()
    local ok = alignToStation()
    if ok then
        RowStatus.Text = "⚡ Poziționat lateral la scaun în 1st Person! ✅"
    else
        RowStatus.Text = "⚡ Nu ești aproape de niciun scaun!"
    end
end)

ServeBtn.MouseButton1Click:Connect(function()
    local st = State.CurrentStation or closestHairdresserStation()
    local cust = State.CurrentCustomer or getCustomerForStation(st)
    if st and cust then
        serveCustomer(st, cust)
    else
        RowStatus.Text = "⚡ Niciun client la scaun pentru servire manuală!"
    end
end)

local function unload()
    Config.Active = false
    pcall(function()
        client.CameraMode = State.OriginalCameraMode or Enum.CameraMode.Classic
        client.CameraMinZoomDistance = 0.5
        client.CameraMaxZoomDistance = 128
    end)
    if State.ScreenGui and State.ScreenGui.Parent then
        State.ScreenGui:Destroy()
    end
    getgenv().StylezHairLoaded = nil
    getgenv().StylezHairUnload = nil
end

CloseBtn.MouseButton1Click:Connect(unload)
getgenv().StylezHairUnload = unload

print("[Stylez Hair Studio] Script 100% integrat și gata de lucru! ✂️")
