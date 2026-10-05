--========================================================
-- N4T HUB
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local MaterialService = game:GetService("MaterialService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- COMPATIBILIDADE ENTRE EXECUTORES
--========================================================
local ExecutorCompat = {}

do
    local globalEnv = _G
    pcall(function()
        if type(getgenv) == "function" then
            local env = getgenv()
            if type(env) == "table" then
                globalEnv = env
            end
        end
    end)

    local compiler = loadstring
    if type(compiler) ~= "function" and type(globalEnv) == "table" then
        compiler = globalEnv.loadstring
    end
    if type(compiler) ~= "function" and type(load) == "function" then
        compiler = load
    end

    function ExecutorCompat.compile(source, chunkName)
        if type(compiler) ~= "function" then
            return nil, "Este executor não disponibiliza loadstring/load."
        end

        local ok, fn, err = pcall(compiler, source, chunkName)
        if not ok then
            return nil, tostring(fn)
        end
        if type(fn) ~= "function" then
            return nil, tostring(err or "Falha ao compilar o código.")
        end
        return fn
    end

    local function tryRequest(req, url)
        if type(req) ~= "function" then
            return nil
        end

        local ok, response = pcall(req, {
            Url = url,
            URL = url,
            Method = "GET",
            method = "GET"
        })

        if not ok then
            return nil
        end

        if type(response) == "string" then
            return response
        end

        if type(response) == "table" then
            local body = response.Body or response.body or response.ResponseBody or response.responseBody
            if type(body) == "string" and #body > 0 then
                return body
            end
        end

        return nil
    end

    function ExecutorCompat.httpGet(url)
        local ok, body = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and type(body) == "string" and #body > 0 then
            return body
        end

        local candidates = {}

        pcall(function()
            if type(request) == "function" then table.insert(candidates, request) end
        end)
        pcall(function()
            if type(http_request) == "function" then table.insert(candidates, http_request) end
        end)
        pcall(function()
            if type(syn) == "table" and type(syn.request) == "function" then
                table.insert(candidates, syn.request)
            end
        end)
        pcall(function()
            if type(fluxus) == "table" and type(fluxus.request) == "function" then
                table.insert(candidates, fluxus.request)
            end
        end)

        if type(globalEnv) == "table" then
            pcall(function()
                if type(globalEnv.request) == "function" then
                    table.insert(candidates, globalEnv.request)
                end
            end)
            pcall(function()
                if type(globalEnv.http_request) == "function" then
                    table.insert(candidates, globalEnv.http_request)
                end
            end)
        end

        for _, req in ipairs(candidates) do
            local result = tryRequest(req, url)
            if result then
                return result
            end
        end

        error("O executor não liberou HTTP GET para este script.")
    end

    pcall(function()
        if type(globalEnv) == "table" then
            if type(globalEnv.loadstring) ~= "function" and type(compiler) == "function" then
                globalEnv.loadstring = compiler
            end
            if type(globalEnv.N4T_HTTPGET) ~= "function" then
                globalEnv.N4T_HTTPGET = ExecutorCompat.httpGet
            end
        end
    end)
end

--========================================================
-- N4T HUB UI - COMPAT / HORIZONTAL / CATEGORIAS / NEON
-- A interface fica isolada em uma tabela para evitar excesso de
-- variaveis locais no chunk principal em executores mais limitados.
--========================================================

local RED = Color3.fromRGB(0, 205, 255)
local BG = Color3.fromRGB(3, 6, 11)
local OFF_COLOR = Color3.fromRGB(10, 17, 27)
local ON_COLOR = Color3.fromRGB(7, 48, 66)
local TEXT = Color3.fromRGB(255, 255, 255)
local TEXT_OFF = Color3.fromRGB(155, 185, 210)

local UI = {}

do
    local parent = playerGui

    -- Alguns executores preferem gethui/CoreGui. Se nao existir,
    -- PlayerGui continua sendo usado normalmente.
    pcall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if h then parent = h end
        end
    end)

    local function destroyOld(container)
        if not container then return end
        local old = container:FindFirstChild("N4T_HUB")
            or container:FindFirstChild("MM2_RedHub")
            or container:FindFirstChild("MM2_CyanHub")
        if old then pcall(function() old:Destroy() end) end
    end

    destroyOld(playerGui)
    if parent ~= playerGui then destroyOld(parent) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "N4T_HUB"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.DisplayOrder = 999 end)
    gui.Parent = parent
    UI.gui = gui

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    local width = viewport.X - 30
    local height = viewport.Y - 95
    if width < 350 then width = 350 end
    if width > 760 then width = 760 end
    if height < 300 then height = 300 end
    if height > 430 then height = 430 end

    UI.bigSize = UDim2.fromOffset(width, height)
    UI.smallSize = UDim2.fromOffset(190, 54)

    local shell = Instance.new("Frame")
    shell.Name = "Shell"
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.Position = UDim2.fromScale(0.5, 0.5)
    shell.Size = UI.bigSize
    shell.BackgroundTransparency = 1
    shell.BorderSizePixel = 0
    shell.Active = true
    shell.ZIndex = 5
    shell.Parent = gui
    UI.shell = shell

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromScale(1, 1)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.ZIndex = 10
    main.Parent = shell
    UI.main = main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = RED
    stroke.Thickness = 2
    stroke.Transparency = 0.08
    stroke.Parent = main
    UI.mainStroke = stroke

    -- Decoracao opcional. Se alguma propriedade visual nao existir em
    -- uma versao/executor, o painel principal continua carregando.
    pcall(function()
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 5, 10)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 16, 28)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 7, 12))
        })
        gradient.Rotation = 10
        gradient.Parent = main
        UI.mainGradient = gradient
    end)

    UI.glowStrokes = {}
    local function addGlow(extra, thickness, transparency, color)
        local g = Instance.new("Frame")
        g.Name = "NeonGlow"
        g.Position = UDim2.fromOffset(-extra, -extra)
        g.Size = UDim2.new(1, extra * 2, 1, extra * 2)
        g.BackgroundTransparency = 1
        g.BorderSizePixel = 0
        g.ZIndex = 4
        g.Parent = shell

        local gc = Instance.new("UICorner")
        gc.CornerRadius = UDim.new(0, 20 + extra)
        gc.Parent = g

        local gs = Instance.new("UIStroke")
        gs.Color = color
        gs.Thickness = thickness
        gs.Transparency = transparency
        gs.Parent = g
        table.insert(UI.glowStrokes, gs)
    end

    pcall(function()
        addGlow(4, 2, 0.28, RED)
        addGlow(8, 3, 0.58, RED)
        addGlow(13, 5, 0.80, Color3.fromRGB(90, 80, 255))
    end)

    local header = Instance.new("TextButton")
    header.Name = "DragHeader"
    header.Size = UDim2.new(1, 0, 0, 62)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Active = true
    header.ZIndex = 30
    header.Parent = main
    UI.header = header

    local logo = Instance.new("Frame")
    logo.Size = UDim2.fromOffset(42, 42)
    logo.Position = UDim2.fromOffset(12, 10)
    logo.BackgroundColor3 = RED
    logo.BorderSizePixel = 0
    logo.ZIndex = 31
    logo.Parent = header

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 13)
    logoCorner.Parent = logo

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Text = "N4T"
    logoText.TextColor3 = TEXT
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 13
    logoText.ZIndex = 32
    logoText.Parent = logo

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -130, 0, 25)
    title.Position = UDim2.fromOffset(65, 8)
    title.BackgroundTransparency = 1
    title.Text = "N4T HUB"
    title.TextColor3 = TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 31
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -130, 0, 18)
    subtitle.Position = UDim2.fromOffset(65, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "MM2 CONTROL CENTER"
    subtitle.TextColor3 = TEXT_OFF
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 10
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 31
    subtitle.Parent = header
    UI.subtitle = subtitle

    local minus = Instance.new("TextButton")
    minus.Name = "Minimize"
    minus.Size = UDim2.fromOffset(38, 34)
    minus.Position = UDim2.new(1, -50, 0, 13)
    minus.BackgroundColor3 = Color3.fromRGB(9, 24, 35)
    minus.BorderSizePixel = 0
    minus.Text = "-"
    minus.TextColor3 = RED
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 20
    minus.AutoButtonColor = false
    minus.Visible = true
    minus.ZIndex = 40
    minus.Parent = main
    UI.minus = minus

    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 11)
    minusCorner.Parent = minus

    local waveLine = Instance.new("Frame")
    waveLine.Name = "WaveLine"
    waveLine.Size = UDim2.new(1, -24, 0, 2)
    waveLine.Position = UDim2.fromOffset(12, 61)
    waveLine.BackgroundColor3 = RED
    waveLine.BorderSizePixel = 0
    waveLine.ZIndex = 25
    waveLine.Parent = main
    UI.waveLine = waveLine

    local waveGlow = Instance.new("Frame")
    waveGlow.Name = "WaveGlow"
    waveGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    waveGlow.Size = UDim2.fromOffset(90, 5)
    waveGlow.Position = UDim2.new(0, -45, 0.5, 0)
    waveGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    waveGlow.BackgroundTransparency = 0.15
    waveGlow.BorderSizePixel = 0
    waveGlow.ZIndex = 26
    waveGlow.Parent = waveLine
    UI.waveGlow = waveGlow

    local categoryBar = Instance.new("ScrollingFrame")
    categoryBar.Name = "Categories"
    categoryBar.Size = UDim2.new(1, -24, 0, 40)
    categoryBar.Position = UDim2.fromOffset(12, 68)
    categoryBar.BackgroundTransparency = 1
    categoryBar.BorderSizePixel = 0
    categoryBar.ScrollBarThickness = 0
    categoryBar.ScrollingDirection = Enum.ScrollingDirection.X
    categoryBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    categoryBar.CanvasSize = UDim2.new()
    categoryBar.ZIndex = 20
    categoryBar.Parent = main
    UI.categoryBar = categoryBar

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal
    categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    categoryLayout.Padding = UDim.new(0, 8)
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.Parent = categoryBar
    UI.categoryLayout = categoryLayout

    local content = Instance.new("ScrollingFrame")
    content.Name = "Scripts"
    content.Size = UDim2.new(1, -24, 1, -120)
    content.Position = UDim2.fromOffset(12, 114)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = RED
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new()
    content.Active = true
    content.Visible = true
    content.ZIndex = 15
    content.Parent = main
    UI.content = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 1)
    padding.PaddingRight = UDim.new(0, 1)
    padding.Parent = content

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(8, 8)
    grid.CellSize = UDim2.new(0.5, -5, 0, 58)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.FillDirectionMaxCells = 2
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = content
    UI.grid = grid
end

--========================================================
-- ESTADOS
--========================================================

local states = {
    ["ANTI INVALID"] = false,
    ["ANIM ANTIGA"] = false,
    ["CONFETE"] = false,
    ["SOM DA ARMA"] = false,
    ["SPEED"] = false,
    ["SPEED RAW"] = false,
    ["SPEED CWLLES"] = false,
    ["SPEED 1.2"] = false,
    ["BALAO DE CHAT OLD"] = false,
    ["CORPO ANTIGO"] = false,
    ["KORBLOX BIEL"] = false,
    ["2023 XP"] = false,
    ["HOT BAR 2025"] = false,
    ["2023 SHIFT"] = false,
    ["2024 SHIFT"] = false,
    ["HOT BAR TEXT"] = false,
    ["2020 QUALITY"] = false,
    ["2023 QUALITY"] = false,
    ["WATERBALLOON"] = false,
    ["TIRAR X DA GUN"] = false,
    ["VOICE 2023"] = false,
    ["SNOWBALL"] = false,
    ["HEADLESS"] = false,
    ["SPEED COIL"] = false,
    ["GRAVITY COIL"] = false,
    ["SOMBRAS"] = false,
    ["SOM ABAFADO"] = false,
    ["VANGUARD HUB"] = false,
    ["PSHADE"] = false,
    ["NÚMEROS PEQUENOS"] = false,
    ["SPEED OLD"] = false,
    ["OLD SPEED NICKY"] = false,
    ["SPEED EMOTE"] = false,
    ["SPEED DOUGLAS"] = false,
    ["SG NATAN"] = false
}

local buttons = {}
local updateButton

--========================================================
-- BALAO DE CHAT OLD
--========================================================

local chatOldConnections = {}
local baloesChat = {}

local TEMPO_NA_TELA = 8
local MAX_BALOES = 4
local ALTURA_BASE = 1.83
local DISTANCIA_ENTRE_BALOES = 0.83
local DISTANCIA_MAXIMA = 100
local DISTANCIA_PONTINHOS = 45

local function calcularTamanhoChat(texto)
    local bounds = TextService:GetTextSize(texto, 20, Enum.Font.SourceSans, Vector2.new(220, 1000))
    local largura = math.clamp(bounds.X + 16, 36, 240)
    local altura = math.clamp(bounds.Y + 8, 30, 120)
    return largura, altura
end

local function reorganizarChat(plr)
    local lista = baloesChat[plr]
    if not lista then return end

    for i, guiObj in ipairs(lista) do
        if guiObj and guiObj.Parent then
            local distanciaDoNovo = #lista - i
            guiObj.StudsOffsetWorldSpace = Vector3.new(0, ALTURA_BASE + (distanciaDoNovo * DISTANCIA_ENTRE_BALOES), 0)

            local balao = guiObj:FindFirstChild("Balao")
            if balao then
                local ponta = balao:FindFirstChild("Ponta")
                if ponta then ponta.Visible = (i == #lista) end
            end
        end
    end
end

local function removerBalaoChat(plr, guiObj)
    local lista = baloesChat[plr]
    if not lista then return end

    for i, item in ipairs(lista) do
        if item == guiObj then
            table.remove(lista, i)
            break
        end
    end

    if guiObj and guiObj.Parent then guiObj:Destroy() end
    reorganizarChat(plr)
end

local function criarBalaoChat(plr, texto)
    if not states["BALAO DE CHAT OLD"] then return end
    local character = plr.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    baloesChat[plr] = baloesChat[plr] or {}
    local lista = baloesChat[plr]

    while #lista >= MAX_BALOES do
        local antigo = table.remove(lista, 1)
        if antigo then antigo:Destroy() end
    end

    local largura, altura = calcularTamanhoChat(texto)

    local guiObj = Instance.new("BillboardGui")
    guiObj.Name = "BalaoChatClassico"
    guiObj.Adornee = head
    guiObj.Size = UDim2.fromOffset(largura, altura + 12)
    guiObj.AlwaysOnTop = false
    guiObj.MaxDistance = DISTANCIA_MAXIMA
    guiObj.Parent = head

    local balao = Instance.new("Frame")
    balao.Name = "Balao"
    balao.AnchorPoint = Vector2.new(0.5, 0)
    balao.Position = UDim2.new(0.5, 0, 0, 0)
    balao.Size = UDim2.fromOffset(largura, altura)
    balao.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    balao.BorderSizePixel = 0
    balao.ZIndex = 2
    balao.Parent = guiObj

    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 4)
    canto.Parent = balao

    local label = Instance.new("TextLabel")
    label.Name = "Texto"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -8, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.Text = texto
    label.TextColor3 = Color3.fromRGB(57, 68, 76)
    label.TextSize = 20
    label.Font = Enum.Font.SourceSans
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 5
    label.Parent = balao

    local ponta = Instance.new("Frame")
    ponta.Name = "Ponta"
    ponta.AnchorPoint = Vector2.new(0.5, 0.5)
    ponta.Position = UDim2.new(0.5, 0, 1, 0)
    ponta.Size = UDim2.fromOffset(16, 14)
    ponta.Rotation = 45
    ponta.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ponta.BorderSizePixel = 0
    ponta.ZIndex = 1
    ponta.Parent = balao

    local conexaoDistancia
    conexaoDistancia = RunService.RenderStepped:Connect(function()
        if not guiObj or not guiObj.Parent or not head then
            conexaoDistancia:Disconnect()
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local dist = (camera.CFrame.Position - head.Position).Magnitude

        if dist >= DISTANCIA_PONTINHOS then
            label.Text = "..."
            label.TextSize = 24
            balao.Size = UDim2.fromOffset(45, 28)
            guiObj.Size = UDim2.fromOffset(45, 40)
        else
            label.Text = texto
            label.TextSize = 20
            balao.Size = UDim2.fromOffset(largura, altura)
            guiObj.Size = UDim2.fromOffset(largura, altura + 12)
        end
    end)

    table.insert(lista, guiObj)
    reorganizarChat(plr)

    task.delay(TEMPO_NA_TELA, function()
        if conexaoDistancia then conexaoDistancia:Disconnect() end
        if guiObj and guiObj.Parent then removerBalaoChat(plr, guiObj) end
    end)
end

local function balaoChatOldOn()
    local bubbleConfig = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    if bubbleConfig then bubbleConfig.Enabled = false end

    table.insert(chatOldConnections, TextChatService.MessageReceived:Connect(function(message)
        if not message.TextSource then return end
        local plr = Players:GetPlayerByUserId(message.TextSource.UserId)
        if plr then criarBalaoChat(plr, message.Text) end
    end))

    table.insert(chatOldConnections, Players.PlayerRemoving:Connect(function(plr)
        baloesChat[plr] = nil
    end))

    print("✅ BALAO DE CHAT OLD ON")
end

local function balaoChatOldOff()
    for _, conn in ipairs(chatOldConnections) do
        pcall(function() conn:Disconnect() end)
    end
    chatOldConnections = {}

    for plr, lista in pairs(baloesChat) do
        for _, guiObj in ipairs(lista) do
            if guiObj and guiObj.Parent then guiObj:Destroy() end
        end
    end
    table.clear(baloesChat)

    local bubbleConfig = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    if bubbleConfig then bubbleConfig.Enabled = true end

    print("❌ BALAO DE CHAT OLD OFF")
end

--========================================================
-- SPEED RAW
--========================================================

local speedRawConnections = {}
local activeGhostRaw, activeWeldRaw
local currentOffsetRaw = CFrame.new(0, 0, 0)

local function deployGhostGlitchRaw()
    if not states["SPEED RAW"] then return end
    local char = player.Character
    if not char then return end

    local cachedRoot = char:FindFirstChild("HumanoidRootPart")
    local cachedTorso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not cachedTorso or not cachedRoot then return end

    local rawCF = cachedRoot.CFrame:ToObjectSpace(cachedTorso.CFrame)
    currentOffsetRaw = CFrame.new(rawCF.Position * 1.9) * rawCF.Rotation

    local oldGhost = char:FindFirstChild("Skibidi_Ghost_Active")
    if oldGhost then oldGhost:Destroy() end

    local newGhost = Instance.new("Part")
    newGhost.Name = "Skibidi_Ghost_Active"
    newGhost.Size = Vector3.new(1, 1, 1)

    local targetMass = 13
    local volume = newGhost.Size.X * newGhost.Size.Y * newGhost.Size.Z
    local requiredDensity = targetMass / volume

    newGhost.CustomPhysicalProperties = PhysicalProperties.new(requiredDensity, 0.7, 0.3, 1, 1)
    newGhost.CFrame = cachedTorso.CFrame 
    newGhost.Transparency = 1 
    newGhost.CanCollide = false
    newGhost.Parent = char

    activeWeldRaw = Instance.new("Weld")
    activeWeldRaw.Part0 = cachedTorso
    activeWeldRaw.Part1 = newGhost
    activeWeldRaw.C0 = currentOffsetRaw
    activeWeldRaw.Parent = newGhost

    activeGhostRaw = newGhost
end

local function speedRawOn()
    if states["SPEED"] then states["SPEED"] = false; if offFunctions and offFunctions["SPEED"] then offFunctions["SPEED"]() end; updateButton("SPEED") end
    if states["SPEED CWLLES"] then states["SPEED CWLLES"] = false; if offFunctions and offFunctions["SPEED CWLLES"] then offFunctions["SPEED CWLLES"]() end; updateButton("SPEED CWLLES") end

    local function setupListeners(char)
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            table.insert(speedRawConnections, humanoid.Died:Connect(function()
                activeGhostRaw = nil
                activeWeldRaw = nil
            end))
        end

        task.defer(deployGhostGlitchRaw)

        table.insert(speedRawConnections, char.ChildAdded:Connect(function(child)
            if not states["SPEED RAW"] then return end
            if child:IsA("Tool") or string.find(string.lower(child.Name), "radio") then 
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") then part.Massless = true end
                end
                deployGhostGlitchRaw() 
            end
        end))

        table.insert(speedRawConnections, char.ChildRemoved:Connect(function(child)
            if not states["SPEED RAW"] then return end
            if child:IsA("Tool") or string.find(string.lower(child.Name), "radio") then 
                deployGhostGlitchRaw() 
            end
        end))
    end

    if player.Character then setupListeners(player.Character) end
    table.insert(speedRawConnections, player.CharacterAdded:Connect(setupListeners))

    table.insert(speedRawConnections, RunService.Heartbeat:Connect(function()
        if not states["SPEED RAW"] then return end
        if activeWeldRaw then
            activeWeldRaw.C0 = currentOffsetRaw
        else
            if player.Character and (not activeGhostRaw or activeGhostRaw.Parent ~= player.Character) then
                deployGhostGlitchRaw()
            end
        end
    end))

    print("✅ SPEED RAW ON")
end

local function speedRawOff()
    for _, conn in ipairs(speedRawConnections) do
        pcall(function() conn:Disconnect() end)
    end
    speedRawConnections = {}

    if activeGhostRaw then pcall(function() activeGhostRaw:Destroy() end) end
    activeGhostRaw = nil
    activeWeldRaw = nil

    print("❌ SPEED RAW OFF")
end

--========================================================
-- SPEED CWLLES
--========================================================

local speedCwllesConnections = {}

local function aplicarCwlles(character)
    if not character or not states["SPEED CWLLES"] then return end

    local humanoid = character:WaitForChild("Humanoid", 10)
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not rootPart then return end

    if character:FindFirstChild("GlitchPart") then
        character.GlitchPart:Destroy()
    end

    local glitchPart = Instance.new("Part")
    glitchPart.Name = "GlitchPart"
    glitchPart.Size = Vector3.new(2, 2, 2)
    glitchPart.Transparency = 1
    glitchPart.CanCollide = false
    glitchPart.CanTouch = false
    glitchPart.CanQuery = false
    glitchPart.Anchored = false
    glitchPart.Massless = false
    glitchPart.Parent = character

    local weld = Instance.new("Weld")
    weld.Part0 = rootPart
    weld.Part1 = glitchPart
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = glitchPart

    local escalando = false

    local function setOffset(z) weld.C0 = CFrame.new(0, 0, z) end
    local function deslocarMassa() setOffset(10.5) end
    local function resetarMassa() setOffset(0) end

    table.insert(speedCwllesConnections, humanoid.StateChanged:Connect(function(_, newState)
        escalando = (newState == Enum.HumanoidStateType.Climbing)
    end))

    table.insert(speedCwllesConnections, character.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then
            if escalando then deslocarMassa() else resetarMassa() end
        end
    end))

    table.insert(speedCwllesConnections, character.ChildRemoved:Connect(function(obj)
        if obj:IsA("Tool") and not escalando then resetarMassa() end
    end))

    local backpack = player:WaitForChild("Backpack", 5)
    if backpack then
        table.insert(speedCwllesConnections, backpack.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") and not escalando then resetarMassa() end
        end))
        table.insert(speedCwllesConnections, backpack.ChildRemoved:Connect(function(obj)
            if obj:IsA("Tool") and not escalando then resetarMassa() end
        end))
    end
end

local function speedCwllesOn()
    if states["SPEED"] then states["SPEED"] = false; if offFunctions and offFunctions["SPEED"] then offFunctions["SPEED"]() end; updateButton("SPEED") end
    if states["SPEED RAW"] then states["SPEED RAW"] = false; if offFunctions and offFunctions["SPEED RAW"] then offFunctions["SPEED RAW"]() end; updateButton("SPEED RAW") end

    if player.Character then aplicarCwlles(player.Character) end
    table.insert(speedCwllesConnections, player.CharacterAdded:Connect(aplicarCwlles))

    print("✅ SPEED CWLLES ON")
end

local function speedCwllesOff()
    for _, conn in ipairs(speedCwllesConnections) do
        pcall(function() conn:Disconnect() end)
    end
    speedCwllesConnections = {}

    if player.Character and player.Character:FindFirstChild("GlitchPart") then
        pcall(function() player.Character.GlitchPart:Destroy() end)
    end

    print("❌ SPEED CWLLES OFF")
end

--========================================================
-- 2023 QUALITY
--========================================================

local quality2023Connections = {}
local originalLightBrightness = {}

local function ajustarLuzes2023()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
            if not originalLightBrightness[v] then
                originalLightBrightness[v] = v.Brightness
            end
            v.Brightness = originalLightBrightness[v] * 0.5
        end
    end
end

local function quality2023On()
    ajustarLuzes2023()

    table.insert(quality2023Connections, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if states["2023 QUALITY"] then
            ajustarLuzes2023()
        end
    end))

    table.insert(quality2023Connections, Workspace.DescendantAdded:Connect(function(v)
        if states["2023 QUALITY"] and (v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight")) then
            task.wait()
            if not originalLightBrightness[v] then
                originalLightBrightness[v] = v.Brightness
            end
            v.Brightness = originalLightBrightness[v] * 0.5
        end
    end))

    print("✅ 2023 QUALITY ON")
end

local function quality2023Off()
    for _, conn in ipairs(quality2023Connections) do
        pcall(function() conn:Disconnect() end)
    end
    quality2023Connections = {}

    for light, origBrightness in pairs(originalLightBrightness) do
        if light and light.Parent then
            light.Brightness = origBrightness
        end
    end
    originalLightBrightness = {}

    print("❌ 2023 QUALITY OFF")
end

--========================================================
-- 2020 QUALITY
--========================================================

local qualityConnections = {}
local origLightingSettings = {}
local disabledLightsList = {}

local function quality2020On()
    origLightingSettings = {
        Technology = Lighting.Technology,
        GlobalShadows = Lighting.GlobalShadows,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        ExposureCompensation = Lighting.ExposureCompensation,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        FogColor = Lighting.FogColor,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom
    }

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
            v:Destroy()
        end
    end

    pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2.12
    Lighting.ClockTime = 14
    Lighting.ExposureCompensation = 0
    Lighting.Ambient = Color3.fromRGB(148, 148, 148)
    Lighting.OutdoorAmbient = Color3.fromRGB(148, 148, 148)
    Lighting.FogStart = 100000
    Lighting.FogEnd = 100000
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    pcall(function()
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
    end)

    table.insert(qualityConnections, Lighting.ChildAdded:Connect(function(obj)
        if not states["2020 QUALITY"] then return end
        if obj:IsA("Atmosphere") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("DepthOfFieldEffect") then
            task.wait()
            if obj.Parent then obj:Destroy() end
        end
    end))

    local function disableLight(obj)
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            if obj.Enabled then
                disabledLightsList[obj] = true
                obj.Enabled = false
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        disableLight(obj)
    end

    table.insert(qualityConnections, Workspace.DescendantAdded:Connect(function(obj)
        if states["2020 QUALITY"] then
            disableLight(obj)
        end
    end))

    print("✅ 2020 QUALITY ON")
end

local function quality2020Off()
    for _, conn in ipairs(qualityConnections) do
        pcall(function() conn:Disconnect() end)
    end
    qualityConnections = {}

    if origLightingSettings.Technology then
        pcall(function() Lighting.Technology = origLightingSettings.Technology end)
        Lighting.GlobalShadows = origLightingSettings.GlobalShadows
        Lighting.Brightness = origLightingSettings.Brightness
        Lighting.ClockTime = origLightingSettings.ClockTime
        Lighting.ExposureCompensation = origLightingSettings.ExposureCompensation
        Lighting.Ambient = origLightingSettings.Ambient
        Lighting.OutdoorAmbient = origLightingSettings.OutdoorAmbient
        Lighting.FogStart = origLightingSettings.FogStart
        Lighting.FogEnd = origLightingSettings.FogEnd
        Lighting.FogColor = origLightingSettings.FogColor
        Lighting.EnvironmentDiffuseScale = origLightingSettings.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = origLightingSettings.EnvironmentSpecularScale
        pcall(function()
            Lighting.ColorShift_Top = origLightingSettings.ColorShift_Top
            Lighting.ColorShift_Bottom = origLightingSettings.ColorShift_Bottom
        end)
    end

    for light, _ in pairs(disabledLightsList) do
        if light and light.Parent then
            light.Enabled = true
        end
    end
    disabledLightsList = {}

    print("❌ 2020 QUALITY OFF")
end

--========================================================
-- TIRAR X DA GUN
--========================================================

local cleanGunConnections = {}

local function processGunChild(child)
    if not states["TIRAR X DA GUN"] then return end
    if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
        child.Enabled = false
        table.insert(cleanGunConnections, child:GetPropertyChangedSignal("Enabled"):Connect(function()
            if states["TIRAR X DA GUN"] then child.Enabled = false end
        end))
    elseif child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("Decal") then
        if child.Name:lower() == "x" or child.Name:lower():find("cross") or child.Name:lower():find("block") then
            child.Visible = false
            child.Transparency = 1
        end
    end
end

local function cleanWeaponX(tool)
    if not tool:IsA("Tool") or not states["TIRAR X DA GUN"] then return end

    for _, descendant in ipairs(tool:GetDescendants()) do
        processGunChild(descendant)
    end

    table.insert(cleanGunConnections, tool.DescendantAdded:Connect(processGunChild))
end

local function setupCharacterGun(char)
    if not char then return end

    table.insert(cleanGunConnections, char.ChildAdded:Connect(cleanWeaponX))
    for _, child in pairs(char:GetChildren()) do
        cleanWeaponX(child)
    end
end

local function tirarXGunOn()
    if player.Character then setupCharacterGun(player.Character) end
    table.insert(cleanGunConnections, player.CharacterAdded:Connect(setupCharacterGun))

    print("✅ TIRAR X DA GUN ON")
end

local function tirarXGunOff()
    for _, conn in ipairs(cleanGunConnections) do
        pcall(function() conn:Disconnect() end)
    end
    cleanGunConnections = {}

    print("❌ TIRAR X DA GUN OFF")
end

--========================================================
-- KORBLOX BIEL (R15 / R6)
--========================================================

local korbloxBielConnections = {}

local function applyKorbloxBiel()
    if not states["KORBLOX BIEL"] then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)

    if not hum or char:FindFirstChild("KorbloxFolder") then 
        return 
    end

    local folder = Instance.new("Folder")
    folder.Name = "KorbloxFolder"
    folder.Parent = char

    if hum.RigType == Enum.HumanoidRigType.R15 then
        local ru = char:WaitForChild("RightUpperLeg", 3)
        local rl = char:WaitForChild("RightLowerLeg", 3)
        local rf = char:WaitForChild("RightFoot", 3)

        if not (ru and rl and rf) then return end

        ru.Transparency = 1
        rl.Transparency = 1
        rf.Transparency = 1

        local korbloxPart = Instance.new("Part")
        korbloxPart.Name = "KorbloxR15Visual"
        korbloxPart.Size = Vector3.new(1, 2, 1)
        korbloxPart.CanCollide = false
        korbloxPart.Massless = true
        korbloxPart.Parent = folder

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = "rbxassetid://902942096"
        mesh.TextureId = "rbxassetid://902843398"
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = korbloxPart

        local weld = Instance.new("Weld")
        weld.Part0 = ru
        weld.Part1 = korbloxPart
        weld.C0 = CFrame.new(0.1, 0.2, 0) 
        weld.Parent = korbloxPart

    elseif hum.RigType == Enum.HumanoidRigType.R6 then
        local rightLeg = char:WaitForChild("Right Leg", 3)
        if not rightLeg then return end

        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                v:Destroy()
            end
        end

        rightLeg.Transparency = 1

        local korbloxLeg = Instance.new("Part")
        korbloxLeg.Name = "KorbloxR6Visual"
        korbloxLeg.Size = Vector3.new(1, 2, 1)
        korbloxLeg.CanCollide = false
        korbloxLeg.Massless = true
        korbloxLeg.Parent = folder

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://101851696"
        mesh.TextureId = "rbxassetid://101851254"
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = korbloxLeg

        local weld = Instance.new("Weld")
        weld.Part0 = rightLeg
        weld.Part1 = korbloxLeg
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = korbloxLeg
    end
end

local function korbloxBielOn()
    if player.Character then
        task.spawn(applyKorbloxBiel)
    end

    table.insert(korbloxBielConnections, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyKorbloxBiel()
    end))

    print("✅ KORBLOX BIEL ON")
end

local function korbloxBielOff()
    for _, conn in ipairs(korbloxBielConnections) do
        pcall(function() conn:Disconnect() end)
    end
    korbloxBielConnections = {}

    local char = player.Character
    if char then
        local folder = char:FindFirstChild("KorbloxFolder")
        if folder then folder:Destroy() end

        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if hum.RigType == Enum.HumanoidRigType.R15 then
                for _, name in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
                    local part = char:FindFirstChild(name)
                    if part then part.Transparency = 0 end
                end
            elseif hum.RigType == Enum.HumanoidRigType.R6 then
                local rl = char:FindFirstChild("Right Leg")
                if rl then rl.Transparency = 0 end
            end
        end
    end

    print("❌ KORBLOX BIEL OFF")
end

--========================================================
-- WATERBALLOON
--========================================================

local waterballoonConnections = {}
local waterballoonThread
local WATERBALLOON_IMAGE_ID = "rbxassetid://89108586792149"
local THROW_ANIMATION_ID = "rbxassetid://18324269091"
local COOLDOWN_TIME = 2.5
local HIDE_DELAY = 0.6
local canThrowBalloon = true

local function createWaterballoonTool()
    if not states["WATERBALLOON"] then return end
    local backpack = player:WaitForChild("Backpack", 5)
    if not backpack then return end

    if backpack:FindFirstChild("waterballoon") or (player.Character and player.Character:FindFirstChild("waterballoon")) then
        return
    end

    tool = Instance.new("Tool")
    tool.Name = "waterballoon"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.TextureId = WATERBALLOON_IMAGE_ID
    tool.Grip = CFrame.new(0.2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1.2, 1.2, 1.2)
    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.Massless = true
    handle.Color = Color3.fromRGB(235, 64, 88)
    handle.Material = Enum.Material.SmoothPlastic
    handle.Parent = tool

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = "rbxassetid://137510221029430"
    mesh.Scale = Vector3.new(0.45, 0.45, 0.45)
    mesh.Parent = handle

    local throwTrack

    local function loadAnimation()
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

        local animation = Instance.new("Animation")
        animation.AnimationId = THROW_ANIMATION_ID

        pcall(function()
            throwTrack = animator:LoadAnimation(animation)
        end)
    end

    loadAnimation()

    tool.Activated:Connect(function()
        if not canThrowBalloon or not tool.Parent then return end
        canThrowBalloon = false

        if not throwTrack then loadAnimation() end
        if throwTrack then pcall(function() throwTrack:Play() end) end

        task.wait(HIDE_DELAY)
        if handle and handle.Parent then handle.Transparency = 1 end

        task.wait(math.max(0, COOLDOWN_TIME - HIDE_DELAY))
        if handle and handle.Parent then handle.Transparency = 0 end

        canThrowBalloon = true
    end)

    tool.Parent = backpack
end

local function removeWaterballoonTool()
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local item = backpack:FindFirstChild("waterballoon")
        if item then item:Destroy() end
    end
    if player.Character then
        local item = player.Character:FindFirstChild("waterballoon")
        if item then item:Destroy() end
    end
end

local function waterballoonOn()
    canThrowBalloon = true
    createWaterballoonTool()

    table.insert(waterballoonConnections, player.CharacterAdded:Connect(function()
        task.wait(1)
        canThrowBalloon = true
        createWaterballoonTool()
    end))

    waterballoonThread = task.spawn(function()
        while states["WATERBALLOON"] do
            task.wait(2)
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                local hasTool = backpack:FindFirstChild("waterballoon") or (player.Character and player.Character:FindFirstChild("waterballoon"))
                if not hasTool then createWaterballoonTool() end
            end
        end
    end)

    print("✅ WATERBALLOON ON")
end

local function waterballoonOff()
    for _, conn in ipairs(waterballoonConnections) do
        pcall(function() conn:Disconnect() end)
    end
    waterballoonConnections = {}

    if waterballoonThread then
        task.cancel(waterballoonThread)
        waterballoonThread = nil
    end

    removeWaterballoonTool()
    print("❌ WATERBALLOON OFF")
end

--========================================================
-- ANIM ANTIGA
--========================================================

local originalRetargeting

pcall(function()
    originalRetargeting = workspace.Retargeting
end)

local function animAntigaOn()
    pcall(function()
        workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled
    end)
    print("✅ ANIM ANTIGA ON")
end

local function animAntigaOff()
    pcall(function()
        if originalRetargeting then
            workspace.Retargeting = originalRetargeting
        end
    end)
    print("❌ ANIM ANTIGA OFF")
end

--========================================================
-- CONFETE
--========================================================

local confeteConnections = {}
local LAG_DURATION = 1
local REPLICATION_LAG = 0.6

local function simulateLag()
    if not states["CONFETE"] then return end
    local NetworkSettings = settings():GetService("NetworkSettings")

    pcall(function()
        NetworkSettings.IncomingReplicationLag = REPLICATION_LAG
        NetworkSettings.OutgoingReplicationLag = REPLICATION_LAG
    end)

    task.delay(LAG_DURATION, function()
        pcall(function()
            NetworkSettings.IncomingReplicationLag = 0
            NetworkSettings.OutgoingReplicationLag = 0
        end)
    end)
end

local function monitorConfete(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    table.insert(confeteConnections, humanoid.Died:Connect(simulateLag))
end

local function confeteOff()
    for _, connection in ipairs(confeteConnections) do
        pcall(function() connection:Disconnect() end)
    end
    confeteConnections = {}

    local NetworkSettings
    pcall(function()
        NetworkSettings = settings():GetService("NetworkSettings")
    end)
    if NetworkSettings then
        pcall(function()
            NetworkSettings.IncomingReplicationLag = 0
            NetworkSettings.OutgoingReplicationLag = 0
        end)
    end

    print("❌ CONFETE OFF")
end

local function confeteOn()
    confeteOff()
    states["CONFETE"] = true

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then monitorConfete(plr.Character) end
        table.insert(confeteConnections, plr.CharacterAdded:Connect(monitorConfete))
    end

    table.insert(confeteConnections, Players.PlayerAdded:Connect(function(plr)
        table.insert(confeteConnections, plr.CharacterAdded:Connect(monitorConfete))
    end))

    print("✅ CONFETE ON")
end

--========================================================
-- SOM DA ARMA
--========================================================

local weaponSound
local weaponConnections = {}
local SOUND_ID = "rbxassetid://6968135315"
local TARGET_TOOL_NAME = "Gun"
local COOLDOWN_DURATION = 5

local function weaponSoundOn()
    weaponSound = Instance.new("Sound")
    weaponSound.SoundId = SOUND_ID
    weaponSound.Volume = 1
    weaponSound.Parent = SoundService

    local function setupCharacter(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        local animator = humanoid and humanoid:WaitForChild("Animator", 10)
        if not animator then return end

        local lastUnequippedTime = 0

        table.insert(weaponConnections, animator.AnimationPlayed:Connect(function(track)
            if not states["SOM DA ARMA"] then return end
            local tool = character:FindFirstChildOfClass("Tool")
            local isHoldingGun = tool and tool.Name == TARGET_TOOL_NAME
            local timeSinceUnequip = tick() - lastUnequippedTime

            if (isHoldingGun or timeSinceUnequip <= COOLDOWN_DURATION) and track.Priority == Enum.AnimationPriority.Action then
                track:Stop()
            end
        end))

        table.insert(weaponConnections, character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME and weaponSound then
                weaponSound:Play()
            end
        end))

        table.insert(weaponConnections, character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
                if weaponSound then weaponSound:Play() end
                lastUnequippedTime = tick()
            end
        end))
    end

    if player.Character then setupCharacter(player.Character) end
    table.insert(weaponConnections, player.CharacterAdded:Connect(setupCharacter))

    print("✅ SOM DA ARMA ON")
end

local function weaponSoundOff()
    for _, connection in ipairs(weaponConnections) do
        pcall(function() connection:Disconnect() end)
    end
    weaponConnections = {}

    if weaponSound then
        weaponSound:Destroy()
        weaponSound = nil
    end

    print("❌ SOM DA ARMA OFF")
end

--========================================================
-- SPEED
--========================================================

local activeGhost
local activeWeld
local currentOffset = CFrame.new()
local speedConnections = {}

local function isGlitchTarget(child)
    if child:IsA("Tool") then return true end
    return string.find(string.lower(child.Name), "radio") ~= nil
end

local function deployGhost()
    if not states["SPEED"] then return end
    local character = player.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not root or not torso then return end

    local rawCF = root.CFrame:ToObjectSpace(torso.CFrame)
    currentOffset = CFrame.new(rawCF.Position * 1.9) * rawCF.Rotation

    if activeGhost then activeGhost:Destroy() end

    local ghost = Instance.new("Part")
    ghost.Name = "Skibidi_Ghost_Active"
    ghost.Size = Vector3.new(1, 1, 1)
    ghost.Transparency = 1
    ghost.CanCollide = false
    ghost.CustomPhysicalProperties = PhysicalProperties.new(20, 0.7, 0.3, 1, 1)
    ghost.CFrame = torso.CFrame
    ghost.Parent = character

    local weld = Instance.new("Weld")
    weld.Part0 = torso
    weld.Part1 = ghost
    weld.C0 = currentOffset
    weld.Parent = ghost

    activeGhost = ghost
    activeWeld = weld
end

local function speedOn()
    if states["SPEED RAW"] then states["SPEED RAW"] = false; if offFunctions and offFunctions["SPEED RAW"] then offFunctions["SPEED RAW"]() end; updateButton("SPEED RAW") end
    if states["SPEED CWLLES"] then states["SPEED CWLLES"] = false; if offFunctions and offFunctions["SPEED CWLLES"] then offFunctions["SPEED CWLLES"]() end; updateButton("SPEED CWLLES") end

    local function setupCharacter(character)
        task.defer(function()
            if states["SPEED"] then deployGhost() end
        end)

        table.insert(speedConnections, character.ChildAdded:Connect(function(child)
            if not states["SPEED"] then return end
            if isGlitchTarget(child) then
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") then part.Massless = true end
                end
                deployGhost()
            end
        end))

        table.insert(speedConnections, character.ChildRemoved:Connect(function(child)
            if states["SPEED"] and isGlitchTarget(child) then deployGhost() end
        end))
    end

    if player.Character then setupCharacter(player.Character) end
    table.insert(speedConnections, player.CharacterAdded:Connect(setupCharacter))

    table.insert(speedConnections, RunService.Heartbeat:Connect(function()
        if not states["SPEED"] then return end
        if activeWeld then
            activeWeld.C0 = currentOffset
        elseif player.Character then
            deployGhost()
        end
    end))

    print("✅ SPEED ON")
end

local function speedOff()
    for _, connection in ipairs(speedConnections) do
        pcall(function() connection:Disconnect() end)
    end
    speedConnections = {}

    if activeGhost then pcall(function() activeGhost:Destroy() end) end
    activeGhost = nil
    activeWeld = nil
    currentOffset = CFrame.new()

    print("❌ SPEED OFF")
end

--========================================================
-- CORPO ANTIGO
--========================================================

local bodyConnections = {}
local bodySession = 0

local function applyBody(character, session)
    if not character or session ~= bodySession or not states["CORPO ANTIGO"] then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if session ~= bodySession or not states["CORPO ANTIGO"] or not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then return end

    humanoid.AutomaticScalingEnabled = false

    local height = humanoid:FindFirstChild("BodyHeightScale")
    local width = humanoid:FindFirstChild("BodyWidthScale")
    local depth = humanoid:FindFirstChild("BodyDepthScale")
    local head = humanoid:FindFirstChild("HeadScale")

    if height then height.Value = 1 end
    if width then width.Value = 1 end
    if depth then depth.Value = 0.8 end
    if head then head.Value = 1 end

    task.wait(0.2)

    if session ~= bodySession or not states["CORPO ANTIGO"] then
        humanoid.AutomaticScalingEnabled = true
        if height then height.Value = 1 end
        if width then width.Value = 1 end
        if depth then depth.Value = 1 end
        if head then head.Value = 1 end
        return
    end

    humanoid.AutomaticScalingEnabled = true
end

local function bodyOn()
    bodySession += 1
    local session = bodySession

    for _, connection in ipairs(bodyConnections) do
        pcall(function() connection:Disconnect() end)
    end
    bodyConnections = {}

    if player.Character then
        task.spawn(function() applyBody(player.Character, session) end)
    end

    table.insert(bodyConnections, player.CharacterAdded:Connect(function(character)
        if not states["CORPO ANTIGO"] then return end
        local currentSession = bodySession
        task.spawn(function() applyBody(character, currentSession) end)
    end))

    print("✅ CORPO ANTIGO ON")
end

local function bodyOff()
    bodySession += 1
    states["CORPO ANTIGO"] = false

    for _, connection in ipairs(bodyConnections) do
        pcall(function() connection:Disconnect() end)
    end
    bodyConnections = {}

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutomaticScalingEnabled = true
            local height = humanoid:FindFirstChild("BodyHeightScale")
            local width = humanoid:FindFirstChild("BodyWidthScale")
            local depth = humanoid:FindFirstChild("BodyDepthScale")
            local head = humanoid:FindFirstChild("HeadScale")

            if height then height.Value = 1 end
            if width then width.Value = 1 end
            if depth then depth.Value = 1 end
            if head then head.Value = 1 end
        end
    end

    print("❌ CORPO ANTIGO OFF")
end

--========================================================
-- 2023 XP
--========================================================

local xpConnections = {}
local originalPositions = {}

local function configurarXP(obj)
    if not obj:IsA("TextLabel") then return end

    local function atualizar()
        if not states["2023 XP"] then return end

        if string.find(obj.Text:lower(), "xp") then
            local pai = obj.Parent
            if pai and pai:IsA("GuiObject") and not originalPositions[pai] then
                originalPositions[pai] = pai.Position
                pai.Position = pai.Position + UDim2.new(0, 0, 0, 35)
            end
        end

        if string.match(obj.Text, "%dm%s*%d+s") and not originalPositions[obj] then
            originalPositions[obj] = obj.Position
            obj.Position = obj.Position + UDim2.new(0, 0, 0, 35)
        end
    end

    table.insert(xpConnections, obj:GetPropertyChangedSignal("Text"):Connect(atualizar))
    atualizar()
end

local function xp2023On()
    for _, v in ipairs(player.PlayerGui:GetDescendants()) do
        configurarXP(v)
    end

    table.insert(xpConnections, player.PlayerGui.DescendantAdded:Connect(configurarXP))
    print("✅ 2023 XP ON")
end

local function xp2023Off()
    for _, connection in ipairs(xpConnections) do
        pcall(function() connection:Disconnect() end)
    end
    xpConnections = {}

    for element, pos in pairs(originalPositions) do
        if element and element.Parent then
            element.Position = pos
        end
    end
    originalPositions = {}

    print("❌ 2023 XP OFF")
end

--========================================================
-- HOT BAR 2025
--========================================================

local hotbarConnections = {}

local function createTool()
    if not states["HOT BAR 2025"] then return end
    local backpack = player:WaitForChild("Backpack", 5)
    if not backpack then return end

    if backpack:FindFirstChild("Emotes") or (player.Character and player.Character:FindFirstChild("Emotes")) then
        return
    end

    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local lang = string.lower(player.LocaleId or "en-us")
    local names = {
        ["pt-br"] = "Emotes",
        ["en-us"] = "Emotes",
        ["es-es"] = "Emotes",
        ["fr-fr"] = "Émotes",
        ["de-de"] = "Emotes"
    }

    tool.Name = names[lang] or "Emotes"
    tool.Parent = backpack

    task.wait()

    local tools = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end

    for i, t in ipairs(tools) do
        if t == tool then
            table.remove(tools, i)
            break
        end
    end

    table.insert(tools, 2, tool)

    for _, t in ipairs(tools) do t.Parent = nil end
    for _, t in ipairs(tools) do t.Parent = backpack end
end

local function removeTool()
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local item = backpack:FindFirstChild("Emotes") or backpack:FindFirstChild("Émotes")
        if item then item:Destroy() end
    end
    if player.Character then
        local item = player.Character:FindFirstChild("Emotes") or player.Character:FindFirstChild("Émotes")
        if item then item:Destroy() end
    end
end

local function hotBar2025On()
    createTool()

    table.insert(hotbarConnections, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createTool()
    end))

    print("✅ HOT BAR 2025 ON")
end

local function hotBar2025Off()
    for _, connection in ipairs(hotbarConnections) do
        pcall(function() connection:Disconnect() end)
    end
    hotbarConnections = {}

    removeTool()
    print("❌ HOT BAR 2025 OFF")
end

--========================================================
-- 2023 SHIFT
--========================================================

local shift2023Connections = {}

local function applyToHumanoid2023(hum)
    if hum:IsA("Humanoid") then
        hum.AutomaticScalingEnabled = false
    end
end

local function scanCharacter2023(character)
    if not character then return end
    for _, obj in pairs(character:GetDescendants()) do
        applyToHumanoid2023(obj)
    end

    table.insert(shift2023Connections, character.DescendantAdded:Connect(function(obj)
        if states["2023 SHIFT"] then
            applyToHumanoid2023(obj)
        end
    end))
end

local function shift2023On()
    if player.Character then
        scanCharacter2023(player.Character)
    end

    table.insert(shift2023Connections, player.CharacterAdded:Connect(function(character)
        if states["2023 SHIFT"] then
            scanCharacter2023(character)
        end
    end))

    print("✅ 2023 SHIFT ON")
end

local function shift2023Off()
    for _, connection in ipairs(shift2023Connections) do
        pcall(function() connection:Disconnect() end)
    end
    shift2023Connections = {}

    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutomaticScalingEnabled = true
        end
    end

    print("❌ 2023 SHIFT OFF")
end

--========================================================
-- 2024 SHIFT
--========================================================

local shift2024Connections = {}
local shiftOffset2024 = Vector3.new(1.2, 0.8, 0)
local normalOffset2024 = Vector3.new(0, 0, 0)
local humanoid2024
local isShiftLocked2024 = false

local function shift2024Off()
    for _, connection in ipairs(shift2024Connections) do
        pcall(function() connection:Disconnect() end)
    end
    shift2024Connections = {}

    if humanoid2024 and humanoid2024.Parent then
        humanoid2024.CameraOffset = normalOffset2024
    end

    humanoid2024 = nil
    isShiftLocked2024 = false
    print("❌ 2024 SHIFT OFF")
end

local function shift2024On()
    -- Evita conexões duplicadas se ligar novamente.
    shift2024Off()

    local function onCharacterAdded(character)
        humanoid2024 = character:WaitForChild("Humanoid", 10)
        if humanoid2024 then
            humanoid2024.CameraOffset = normalOffset2024
            isShiftLocked2024 = false
        end
    end

    table.insert(shift2024Connections, player.CharacterAdded:Connect(onCharacterAdded))

    if player.Character then
        onCharacterAdded(player.Character)
    end

    table.insert(shift2024Connections, RunService.RenderStepped:Connect(function()
        if not states["2024 SHIFT"] or not humanoid2024 then return end

        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            if not isShiftLocked2024 then
                isShiftLocked2024 = true
                humanoid2024.CameraOffset = shiftOffset2024
            end
        else
            if isShiftLocked2024 then
                isShiftLocked2024 = false
                humanoid2024.CameraOffset = normalOffset2024
            end
        end
    end))

    print("✅ 2024 SHIFT ON")
end

--========================================================
-- HOT BAR TEXT
--========================================================

local hotbarTextConnections = {}
local cachedLabelsText = {}
local SMALL_TEXT_SIZE_HOTBAR = 12
local TARGET_POSITION_HOTBAR = UDim2.new(0, -1, 0, -4)

local function isHotbarSlotLabel(label)
    if not (label and label:IsA("TextLabel") and label.Parent) then return false end

    local rawText = label.Text:gsub("[%s%.]+", "")
    local num = tonumber(rawText)
    if not num or num < 0 or num > 10 then return false end

    local current = label.Parent
    local isHotbar = false

    while current and current ~= game do
        local name = current.Name:lower()

        if name:find("shop") or name:find("trade") or name:find("profile") or 
           name:find("leaderboard") or name:find("crafting") or name:find("level") or 
           name:find("coin") or name:find("menu") or name:find("hud") then
            return false
        end

        if name:find("hotbar") or name:find("backpack") or name:find("toolbar") or name:find("slot") then
            isHotbar = true
        end

        current = current.Parent
    end

    return isHotbar
end

local function checkAndCacheText(descendant)
    if descendant:IsA("TextLabel") and isHotbarSlotLabel(descendant) then
        cachedLabelsText[descendant] = true
    end
end

local function scanAndCacheText(container)
    if not container then return end
    for _, obj in ipairs(container:GetDescendants()) do
        checkAndCacheText(obj)
    end
end

local function hotBarTextOn()
    if _G.TinyHotbarThread then
        task.cancel(_G.TinyHotbarThread)
        _G.TinyHotbarThread = nil
    end

    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then 
        scanAndCacheText(pGui)
        table.insert(hotbarTextConnections, pGui.DescendantAdded:Connect(checkAndCacheText))
    end

    pcall(function()
        local coreGui = game:GetService("CoreGui")
        scanAndCacheText(coreGui)
        table.insert(hotbarTextConnections, coreGui.DescendantAdded:Connect(checkAndCacheText))
    end)

    table.insert(hotbarTextConnections, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        table.clear(cachedLabelsText)
        local currentPGui = player:FindFirstChild("PlayerGui")
        if currentPGui then scanAndCacheText(currentPGui) end
        pcall(function() scanAndCacheText(game:GetService("CoreGui")) end)
    end))

    _G.TinyHotbarThread = task.spawn(function()
        while states["HOT BAR TEXT"] do
            for label in pairs(cachedLabelsText) do
                if label and label.Parent then
                    if label.TextScaled then label.TextScaled = false end
                    if label.TextSize ~= SMALL_TEXT_SIZE_HOTBAR then label.TextSize = SMALL_TEXT_SIZE_HOTBAR end
                    if label.AnchorPoint ~= Vector2.new(0, 0) then label.AnchorPoint = Vector2.new(0, 0) end
                    if label.Position ~= TARGET_POSITION_HOTBAR then label.Position = TARGET_POSITION_HOTBAR end

                    label.Size = UDim2.new(0, 14, 0, 14)
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.TextYAlignment = Enum.TextYAlignment.Top
                else
                    cachedLabelsText[label] = nil
                end
            end
            task.wait(0.4)
        end
    end)

    print("✅ HOT BAR TEXT ON")
end

local function hotBarTextOff()
    for _, connection in ipairs(hotbarTextConnections) do
        pcall(function() connection:Disconnect() end)
    end
    hotbarTextConnections = {}

    if _G.TinyHotbarThread then
        task.cancel(_G.TinyHotbarThread)
        _G.TinyHotbarThread = nil
    end

    table.clear(cachedLabelsText)
    print("❌ HOT BAR TEXT OFF")
end

--========================================================
-- VOICE 2023
--========================================================
local voice2023Connections = {}
local RAW_ASSET_ID = "97664450574335"
local IMAGE_URI = "rbxthumb://type=Asset&id=" .. RAW_ASSET_ID .. "&w=420&h=420"
local function voice2023Create(char)
    if not states["VOICE 2023"] then return end
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    local existing = head:FindFirstChild("CustomVoiceBubble")
    if existing then existing:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CustomVoiceBubble"; billboard.Size = UDim2.new(0,30,0,30); billboard.StudsOffset = Vector3.new(0,2.2,0); billboard.AlwaysOnTop=true; billboard.Active=true; billboard.Adornee=head; billboard.Parent=head
    local button=Instance.new("TextButton"); button.Name="BubbleButton"; button.Size=UDim2.new(1,0,1,0); button.BackgroundColor3=Color3.fromRGB(240,240,240); button.BorderSizePixel=0; button.Text=""; button.AutoButtonColor=true; button.Active=true; button.Selectable=true; button.ClipsDescendants=false; button.Parent=billboard
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=button
    local tailHolder=Instance.new("Frame"); tailHolder.Name="TailHolder"; tailHolder.Size=UDim2.new(0,12,0,8); tailHolder.Position=UDim2.new(0.5,-6,1,-1); tailHolder.BackgroundTransparency=1; tailHolder.ClipsDescendants=true; tailHolder.Parent=button
    local rotatedSquare=Instance.new("Frame"); rotatedSquare.Name="PyramidTail"; rotatedSquare.Size=UDim2.new(0,8,0,8); rotatedSquare.Position=UDim2.new(0.5,-4,0,-4); rotatedSquare.Rotation=45; rotatedSquare.BackgroundColor3=Color3.fromRGB(240,240,240); rotatedSquare.BorderSizePixel=0; rotatedSquare.Parent=tailHolder
    local micIcon=Instance.new("ImageLabel"); micIcon.Name="MicIcon"; micIcon.Size=UDim2.new(0,18,0,18); micIcon.Position=UDim2.new(0.5,0,0.5,0); micIcon.AnchorPoint=Vector2.new(0.5,0.5); micIcon.BackgroundTransparency=1; micIcon.Image=IMAGE_URI; micIcon.ScaleType=Enum.ScaleType.Fit; micIcon.Parent=button
    local redSlash=Instance.new("Frame"); redSlash.Name="RedMuteSlash"; redSlash.Size=UDim2.new(0,18,0,2.5); redSlash.Position=UDim2.new(0.5,0,0.5,0); redSlash.AnchorPoint=Vector2.new(0.5,0.5); redSlash.Rotation=-45; redSlash.BackgroundColor3=Color3.fromRGB(215,65,65); redSlash.BorderSizePixel=0; redSlash.Visible=true; redSlash.Parent=button
    local lc=Instance.new("UICorner"); lc.CornerRadius=UDim.new(1,0); lc.Parent=redSlash
    local isMuted=true
    local function toggleVisualState() isMuted=not isMuted; redSlash.Visible=isMuted; micIcon.ImageColor3=isMuted and Color3.fromRGB(255,255,255) or Color3.fromRGB(45,180,105) end
    table.insert(voice2023Connections, button.MouseButton1Click:Connect(toggleVisualState))
    table.insert(voice2023Connections, button.TouchTap:Connect(toggleVisualState))
end
local function voice2023On()
    if player.Character then task.spawn(voice2023Create, player.Character) end
    table.insert(voice2023Connections, player.CharacterAdded:Connect(voice2023Create))
    print("✅ VOICE 2023 ON")
end
local function voice2023Off()
    for _,c in ipairs(voice2023Connections) do pcall(function() c:Disconnect() end) end; voice2023Connections={}
    if player.Character then local h=player.Character:FindFirstChild("Head"); if h then local b=h:FindFirstChild("CustomVoiceBubble"); if b then b:Destroy() end end end
    print("❌ VOICE 2023 OFF")
end

--========================================================
-- SNOWBALL
--========================================================
local function snowballOn()
    local ok, err = pcall(function()
        local snowballChunk, snowballCompileErr = ExecutorCompat.compile([==[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local TOOL_NAME = "SnowballToy"
local MIN_FORWARD_SPEED = 20
local MAX_FORWARD_SPEED = 120
local MIN_UPWARD_LIFT = 25
local MAX_UPWARD_LIFT = 25
local WINDUP_DELAY = 0.7
local RELOAD_TIME = 2.0
local COOLDOWN_TIME = 0.15

-- Runtime único: evita acumular conexões/slots quando desativa e ativa várias vezes.
if _G.N4T_SnowballCleanup then
    pcall(_G.N4T_SnowballCleanup)
end

local runtimeConnections = {}
local tool

local function bind(connection)
    table.insert(runtimeConnections, connection)
    return connection
end

local function removeSnowballUI()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end

    -- Primeiro remove linhas criadas exclusivamente para a Snowball.
    for _, obj in ipairs(pGui:GetDescendants()) do
        if obj.Name == "SnowballOnlyRow" or obj:GetAttribute("N4TSnowballOnlyRow") == true then
            pcall(function() obj:Destroy() end)
        end
    end

    -- Depois remove qualquer slot antigo restante, inclusive de versões anteriores.
    for _, obj in ipairs(pGui:GetDescendants()) do
        if obj.Name == "SnowballSlot" or obj:GetAttribute("N4TSnowballSlot") == true then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function removeSnowballWorldObjects()
    if LocalPlayer.Backpack then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name == TOOL_NAME or item.Name == "SnowBallToy2020" then
                pcall(function() item:Destroy() end)
            end
        end
    end
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item.Name == TOOL_NAME or item.Name == "SnowBallToy2020" then
                pcall(function() item:Destroy() end)
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "SnowballProjectile" or obj.Name == "SnowballImpact" then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function cleanupSnowballRuntime()
    for _, connection in ipairs(runtimeConnections) do
        pcall(function()
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end)
    end
    table.clear(runtimeConnections)

    if tool then
        pcall(function() tool:Destroy() end)
    end

    removeSnowballWorldObjects()
    removeSnowballUI()

    if _G.N4T_SnowballCleanup == cleanupSnowballRuntime then
        _G.N4T_SnowballCleanup = nil
    end
end

_G.N4T_SnowballCleanup = cleanupSnowballRuntime
removeSnowballUI()

-- 1. PURGE OLD INSTANCES & UI ELEMENTS*
if LocalPlayer.Backpack then
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item.Name == TOOL_NAME or item.Name == "SnowBallToy2020" then 
            item:Destroy() 
        end
    end
end
if LocalPlayer.Character then
    for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
        if item.Name == TOOL_NAME or item.Name == "SnowBallToy2020" then 
            item:Destroy() 
        end
    end
end
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj.Name == "SnowballProjectile" or obj.Name == "SnowballImpact" then
        obj:Destroy()
    end
end
-- Helper to safely locate the Game Emotes UI Container*
local function getGameEmotesPage()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil end

    -- Caminho real do menu T do MM2. Não procurar qualquer objeto chamado
    -- "Game Emotes", porque existe também a aba/botão com esse nome.
    local crossPlatform = pGui:FindFirstChild("CrossPlatform")
    if not crossPlatform then return nil end

    local emotes = crossPlatform:FindFirstChild("Emotes") or crossPlatform:FindFirstChild("Emotes", true)
    if not emotes then return nil end

    local emoteWindow = emotes:FindFirstChild("EmoteWindow", true)
    if not emoteWindow then return nil end

    local emoteContainer = emoteWindow:FindFirstChild("EmoteContainer", true)
    if not emoteContainer then return nil end

    local emotePages = emoteContainer:FindFirstChild("EmotePages", true)
    if not emotePages then return nil end

    local gameEmotes = emotePages:FindFirstChild("Game Emotes")
    if gameEmotes and (gameEmotes:IsA("GuiObject") or gameEmotes:IsA("Folder")) then
        return gameEmotes
    end
    return nil
end
-- Purge existing custom Emote UI rows to avoid duplicates when re-executing*
local gameEmotesPage = getGameEmotesPage()
if gameEmotesPage then
    for _, child in ipairs(gameEmotesPage:GetChildren()) do
        if child.Name == "SnowballRow" or child:FindFirstChild("SnowballSlot") then
            child:Destroy()
        end
    end
end
-- 2. CREATE TOOL CONTAINER & HANDLE*
local tool = Instance.new("Tool")
tool.Name = TOOL_NAME
tool.GripPos = Vector3.new(0.03, -0.24, -0.01)
tool.RequiresHandle = true
-- Hotbar Icon*
tool.TextureId = "rbxthumb://type=Asset&w=150&h=150&id=6123754554"
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Shape = Enum.PartType.Ball
handle.Size = Vector3.new(1, 1, 1)
handle.Material = Enum.Material.Sand
handle.Color = Color3.new(0.956863, 0.968627, 1)
handle.CanCollide = false
handle.Parent = tool

-- A Tool fica fora da hotbar até o jogador escolher Snowball no menu T do MM2.

-- 3. PARTICLES SETUP (Impact Burst Emitters)*
local p1 = Instance.new("ParticleEmitter")
p1.Name = "Effect1"
p1.Texture = "rbxassetid://2346141109"
p1.Enabled = false
p1.Rate = 20.0
p1.Speed = NumberRange.new(4.0, 4.0)
p1.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1875),
    NumberSequenceKeypoint.new(0.726751, 0),
    NumberSequenceKeypoint.new(1, 0)
})
p1.Parent = handle
local p2 = Instance.new("ParticleEmitter")
p2.Name = "Effect2"
p2.Texture = "rbxassetid://1539332776"
p2.Enabled = false
p2.Rate = 10.0
p2.Speed = NumberRange.new(1.0, 1.0)
p2.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 2.0),
    NumberSequenceKeypoint.new(0.716258, 0.560748),
    NumberSequenceKeypoint.new(1, 0)
})
p2.Parent = handle
-- 4. ANIMATION & THROW LOGIC*
local throwAnim = Instance.new("Animation")
throwAnim.AnimationId = "rbxassetid://18324269091"
local debounce = false
local function isShiftlockActive()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return true
    end
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and Camera then
            local camLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
            local rootLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
            if camLook:Dot(rootLook) > 0.95 and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                return true
            end
        end
    end
    return false
end
local function getTargetPosition()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local camera = Workspace.CurrentCamera
        if camera then
            local viewportCenter = camera.ViewportSize / 2
            local unitRay = camera:ViewportPointToRay(viewportCenter.X, viewportCenter.Y)
            return unitRay.Origin + (unitRay.Direction * 1000)
        end
    end
    return Mouse.Hit.Position
end
bind(tool.Activated:Connect(function()
    if debounce then return end
    debounce = true
    local char = LocalPlayer.Character
    if not char then 
        debounce = false 
        return 
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then
        debounce = false
        return
    end
    local animator = hum:FindFirstChildOfClass("Animator") or hum
    local track = animator:LoadAnimation(throwAnim)
    track.Priority = Enum.AnimationPriority.Action4 
    track:Play()
    task.wait(WINDUP_DELAY)
    if handle then
        handle.Transparency = 1
    end
    if char and char.Parent and hum and hum.Health > 0 and root and root.Parent then
        local targetPos = getTargetPosition()
        local aimOrigin = root.Position + Vector3.new(0, 1.5, 0)
        local rawDir = targetPos - aimOrigin
        local distance = rawDir.Magnitude
        local forwardSpeed, upwardLift
        if isShiftlockActive() then
            forwardSpeed = MAX_FORWARD_SPEED
            upwardLift = MAX_UPWARD_LIFT
        elseif tool.Parent == char then
            forwardSpeed = math.clamp(distance * 2.2, MIN_FORWARD_SPEED, MAX_FORWARD_SPEED)
            upwardLift = math.clamp(distance * 0.25, MIN_UPWARD_LIFT, MAX_UPWARD_LIFT)
        else
            forwardSpeed = MAX_FORWARD_SPEED
            upwardLift = MAX_UPWARD_LIFT
        end
        local flatDir = Vector3.new(rawDir.X, 0, rawDir.Z)
        if flatDir.Magnitude > 0.1 then
            flatDir = flatDir.Unit
        else
            flatDir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
        end
        local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        local spawnPos
        if tool.Parent == char and handle then
            spawnPos = handle.Position
        elseif rightHand then
            spawnPos = rightHand.Position
        else
            spawnPos = aimOrigin
        end
        local projectile = Instance.new("Part")
        projectile.Name = "SnowballProjectile"
        projectile.Shape = Enum.PartType.Ball
        projectile.Size = Vector3.new(1.00, 1.00, 1.00)
        projectile.Material = Enum.Material.Sand
        projectile.Color = Color3.new(0.956863, 0.968627, 1)
        projectile.CanCollide = false
        projectile.Anchored = false
        projectile.CFrame = CFrame.new(spawnPos, spawnPos + flatDir)
        projectile.Parent = Workspace
        projectile.AssemblyLinearVelocity = (flatDir * forwardSpeed) + Vector3.new(0, upwardLift, 0)
        local hitConn
        hitConn = bind(projectile.Touched:Connect(function(hit)
            if hit:IsDescendantOf(char) or hit.Name == "SnowballProjectile" then return end
            if hitConn then
                hitConn:Disconnect()
                hitConn = nil
            end
            local impact = Instance.new("Part")
            impact.Name = "SnowballImpact"
            impact.Size = Vector3.new(0.1, 0.1, 0.1)
            impact.Transparency = 1
            impact.Anchored = true
            impact.CanCollide = false
            impact.CFrame = projectile.CFrame
            impact.Parent = Workspace
            local b1 = p1:Clone()
            b1.SpreadAngle = Vector2.new(180, 180)
            b1.Lifetime = NumberRange.new(1.0, 1.0)
            b1.Parent = impact
            local b2 = p2:Clone()
            b2.SpreadAngle = Vector2.new(90, 90)
            b2.Lifetime = NumberRange.new(1.0, 1.0)
            b2.Parent = impact
            b1:Emit(10)
            b2:Emit(1)
            Debris:AddItem(impact, 1.0)
            projectile:Destroy()
        end))
        Debris:AddItem(projectile, 4)
        task.delay(4, function()
            if hitConn then
                hitConn:Disconnect()
                hitConn = nil
            end
        end)
    end
    task.wait(RELOAD_TIME)
    if handle then
        handle.Transparency = 0
    end
    task.wait(COOLDOWN_TIME)
    debounce = false
end))
-- 5. UI INJECTION & SMART EMOTE MENU KEYBIND*
local function isEmotesMenuOpen()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local crossPlatform = pGui:FindFirstChild("CrossPlatform")
        if crossPlatform then
            local emoteWindow = crossPlatform:FindFirstChild("EmoteWindow", true)
            if emoteWindow and emoteWindow:IsA("GuiObject") and emoteWindow.Visible then
                return true
            end
        end
    end
    return false
end
local function closeEmotesMenu()
    -- Try simulating keypress first (PC)*
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
    -- Mobile / Backup fallback: Directly hide EmoteWindow if it's still open*
    task.delay(0.05, function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local crossPlatform = pGui:FindFirstChild("CrossPlatform")
            if crossPlatform then
                local emoteWindow = crossPlatform:FindFirstChild("EmoteWindow", true)
                if emoteWindow and emoteWindow:IsA("GuiObject") then
                    emoteWindow.Visible = false
                end
            end
        end
    end)
end
local function equipSnowballAndCloseMenu()
    if not LocalPlayer.Backpack then return end
    if tool.Parent ~= LocalPlayer.Backpack and tool.Parent ~= LocalPlayer.Character then
        tool.Parent = LocalPlayer.Backpack
    end
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
        end
    end
    closeEmotesMenu()
end
-- O número mostrado/atalho acompanha a posição real da Snowball na linha.
local snowballSlotNumber = 1
local snowballHotkey = Enum.KeyCode.One
local snowballKeypadHotkey = Enum.KeyCode.KeypadOne

local function setSnowballHotkey(slotNumber)
    snowballSlotNumber = math.clamp(tonumber(slotNumber) or 1, 1, 4)
    local normalKeys = {
        [1] = Enum.KeyCode.One,
        [2] = Enum.KeyCode.Two,
        [3] = Enum.KeyCode.Three,
        [4] = Enum.KeyCode.Four,
    }
    local keypadKeys = {
        [1] = Enum.KeyCode.KeypadOne,
        [2] = Enum.KeyCode.KeypadTwo,
        [3] = Enum.KeyCode.KeypadThree,
        [4] = Enum.KeyCode.KeypadFour,
    }
    snowballHotkey = normalKeys[snowballSlotNumber]
    snowballKeypadHotkey = keypadKeys[snowballSlotNumber]
end

-- Só equipa se o T estiver aberto e a tecla corresponder ao slot real da Snowball.
bind(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == snowballHotkey or input.KeyCode == snowballKeypadHotkey then
        if isEmotesMenuOpen() then
            equipSnowballAndCloseMenu()
        end
    end
end))

local MAX_SLOTS_PER_ROW = 4

local function getRows(page)
    local rows = {}

    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("GuiObject") then
            local isRow = child.Name:match("^Row%d+$") ~= nil

            if not isRow then
                for _, slot in ipairs(child:GetChildren()) do
                    if slot:IsA("GuiObject") and slot.Name:match("^Emote%d+$") then
                        isRow = true
                        break
                    end
                end
            end

            if isRow then
                table.insert(rows, child)
            end
        end
    end

    table.sort(rows, function(a, b)
        local aNum = tonumber(a.Name:match("^Row(%d+)$"))
        local bNum = tonumber(b.Name:match("^Row(%d+)$"))

        if aNum and bNum and aNum ~= bNum then
            return aNum < bNum
        end

        if a.LayoutOrder ~= b.LayoutOrder then
            return a.LayoutOrder < b.LayoutOrder
        end

        return a.Name < b.Name
    end)

    return rows
end

local function getRowSlots(row)
    local slots = {}

    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("GuiObject") then
            local index = tonumber(child.Name:match("^Emote(%d+)$"))
            if index and index >= 1 and index <= MAX_SLOTS_PER_ROW then
                table.insert(slots, {
                    object = child,
                    index = index,
                    used = child.Visible ~= false,
                })
            end
        end
    end

    table.sort(slots, function(a, b)
        return a.index < b.index
    end)

    return slots
end

local function findFirstFreeSlot(row)
    local used = {}
    local slots = getRowSlots(row)

    for _, info in ipairs(slots) do
        if info.used then
            used[info.index] = true
        end
    end

    for index = 1, MAX_SLOTS_PER_ROW do
        if not used[index] then
            return index, slots
        end
    end

    return nil, slots
end

local function findTemplateSlot(row, wantedIndex, slots)
    -- Se o MM2 já deixou um slot escondido naquela posição, usa ele como molde.
    for _, info in ipairs(slots) do
        if info.index == wantedIndex then
            return info.object
        end
    end

    -- Senão usa o último slot real da mesma linha.
    for i = #slots, 1, -1 do
        if slots[i].object and slots[i].object.Parent then
            return slots[i].object
        end
    end

    return nil
end

local function styleSnowballSlot(snowballSlot, slotNumber)
    snowballSlot.Name = "SnowballSlot"
    snowballSlot:SetAttribute("N4TSnowballSlot", true)
    snowballSlot:SetAttribute("N4TSlotNumber", slotNumber)

    if snowballSlot:IsA("GuiObject") then
        snowballSlot.Visible = true
        snowballSlot.LayoutOrder = slotNumber
    end

    setSnowballHotkey(slotNumber)

    -- Troca apenas o número do atalho pelo número do slot real (1 a 4).
    for _, desc in ipairs(snowballSlot:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local clean = desc.Text:gsub("<.->", ""):gsub("[%s%.]+", "")
            local num = tonumber(clean)
            if num and num >= 0 and num <= 10 then
                desc.RichText = true
                desc.Text = '<font color="#FFFFFF">' .. tostring(slotNumber) .. '</font>'
            end
        end
    end

    local nameLabel = snowballSlot:FindFirstChild("EmoteName")
        or snowballSlot:FindFirstChild("Title")
        or snowballSlot:FindFirstChild("Name")

    if not nameLabel then
        for _, desc in ipairs(snowballSlot:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local clean = desc.Text:gsub("<.->", ""):gsub("[%s%.]+", "")
                if clean ~= "" and tonumber(clean) == nil then
                    nameLabel = desc
                    break
                end
            end
        end
    end

    if nameLabel and nameLabel:IsA("TextLabel") then
        nameLabel.Text = "Snowball"
    end

    local iconLabel = snowballSlot:FindFirstChildWhichIsA("ImageLabel", true)
        or snowballSlot:FindFirstChildWhichIsA("ImageButton", true)

    if iconLabel then
        iconLabel.Image = "rbxthumb://type=Asset&w=150&h=150&id=6123754554"
    end

    local connectedButtons = {}
    local function connectButton(button)
        if connectedButtons[button] then return end
        connectedButtons[button] = true
        bind(button.MouseButton1Click:Connect(equipSnowballAndCloseMenu))
    end

    if snowballSlot:IsA("GuiButton") then
        connectButton(snowballSlot)
    end

    for _, btn in ipairs(snowballSlot:GetDescendants()) do
        if btn:IsA("GuiButton") then
            connectButton(btn)
        end
    end
end

local function removeDuplicateSnowballs(page)
    local found = {}
    for _, obj in ipairs(page:GetDescendants()) do
        if obj.Name == "SnowballSlot" or obj:GetAttribute("N4TSnowballSlot") == true then
            table.insert(found, obj)
        end
    end

    -- Se uma versão antiga deixou várias Snowballs, mantém só uma.
    local keeper = found[1]
    if #found > 1 then
        for i = 2, #found do
            pcall(function() found[i]:Destroy() end)
        end
    end

    -- Também remove linhas extras/vazias que poderiam virar aquelas "25 abas".
    for _, obj in ipairs(page:GetDescendants()) do
        if obj.Name == "SnowballOnlyRow" or obj:GetAttribute("N4TSnowballOnlyRow") == true then
            local keepThisRow = keeper and keeper.Parent and keeper:IsDescendantOf(obj)
            if not keepThisRow then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    return keeper
end

local function injectIntoGameEmotes()
    local page = getGameEmotesPage()
    if not page then
        warn("[Snowball System] Game Emotes page folder not found.")
        return false
    end

    -- Nunca cria outra Snowball se uma já estiver presente.
    local existingSnowball = removeDuplicateSnowballs(page)
    if existingSnowball and existingSnowball.Parent then
        local existingNumber = existingSnowball:GetAttribute("N4TSlotNumber")
        if existingNumber then
            setSnowballHotkey(existingNumber)
        end
        return true
    end

    local rows = getRows(page)
    if #rows == 0 then
        warn("[Snowball System] No existing row found to use as template.")
        return false
    end

    -- Procura primeiro um espaço livre em qualquer linha existente.
    -- Ex.: 3 toys do jogador = Snowball vira o 4º, sem criar outra aba/linha.
    local targetRow
    local freeIndex
    local rowSlots

    for _, row in ipairs(rows) do
        local index, slots = findFirstFreeSlot(row)
        if index then
            targetRow = row
            freeIndex = index
            rowSlots = slots
            break
        end
    end

    if targetRow and freeIndex then
        local template = findTemplateSlot(targetRow, freeIndex, rowSlots)
        if not template then
            warn("[Snowball System] No slot template found in target row.")
            return false
        end

        local snowballSlot = template:Clone()
        styleSnowballSlot(snowballSlot, freeIndex)

        -- Se não existir layout automático, um placeholder escondido na posição
        -- livre já fornece a Position correta porque foi usado como template.
        snowballSlot.Parent = targetRow

        print("[Snowball System] Snowball inserted once in existing row at slot " .. tostring(freeIndex) .. ".")
        return true
    end

    -- Todas as linhas estão cheias. Nesse caso cria UMA única linha adicional,
    -- sem apagar nem limitar os itens reais de quem possui mais toys.
    local sourceRow = rows[#rows]
    local sourceSlots = getRowSlots(sourceRow)
    if #sourceSlots == 0 then
        warn("[Snowball System] Last row has no slot template.")
        return false
    end

    local newRow = sourceRow:Clone()
    newRow.Name = "SnowballOnlyRow"
    newRow:SetAttribute("N4TSnowballOnlyRow", true)
    newRow.Visible = true
    newRow.LayoutOrder = sourceRow.LayoutOrder + 1

    local templateSlot
    for _, child in ipairs(newRow:GetChildren()) do
        if child:IsA("GuiObject") and child.Name:match("^Emote%d+$") then
            if not templateSlot then
                templateSlot = child
            else
                child:Destroy()
            end
        end
    end

    if not templateSlot then
        newRow:Destroy()
        warn("[Snowball System] Could not build Snowball-only row.")
        return false
    end

    styleSnowballSlot(templateSlot, 1)
    newRow.Parent = page

    print("[Snowball System] Existing rows were full; created one Snowball-only row.")
    return true
end

local function ensureSnowballInjected()
    local page = getGameEmotesPage()
    if page then
        local existing = removeDuplicateSnowballs(page)
        if existing and existing.Parent then
            local slotNumber = existing:GetAttribute("N4TSlotNumber")
            if slotNumber then
                setSnowballHotkey(slotNumber)
            end
            return true
        end
    end

    return injectIntoGameEmotes()
end

-- A interface do T pode ainda não existir quando o botão do hub é ligado.
-- Enquanto o recurso estiver ON, tenta até conseguir UMA vez.
task.spawn(function()
    for _ = 1, 20 do
        if ensureSnowballInjected() then
            break
        end
        task.wait(0.5)
    end
end)

-- Se o MM2 reconstruir a interface quando o T abre, recoloca somente se sumiu.
bind(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T then
        task.spawn(function()
            for _, delayTime in ipairs({0.10, 0.25, 0.50, 1.00}) do
                task.wait(delayTime)
                if ensureSnowballInjected() then
                    break
                end
            end
        end)
    end
end))
]==], "@N4T_Snowball")
        if not snowballChunk then
            error(snowballCompileErr or "Falha ao compilar Snowball")
        end
        snowballChunk()
    end)
    if not ok then warn("SNOWBALL:", err) end
    print("✅ SNOWBALL ON")
end
local function snowballOff()
    if _G.N4T_SnowballCleanup then
        pcall(_G.N4T_SnowballCleanup)
        _G.N4T_SnowballCleanup = nil
    end

    -- Fallback de limpeza caso o runtime tenha sido interrompido.
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do
            if v.Name == "SnowballToy" or v.Name == "SnowBallToy2020" then
                pcall(function() v:Destroy() end)
            end
        end
    end

    if player.Character then
        for _, v in ipairs(player.Character:GetChildren()) do
            if v.Name == "SnowballToy" or v.Name == "SnowBallToy2020" then
                pcall(function() v:Destroy() end)
            end
        end
    end

    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "SnowballProjectile" or v.Name == "SnowballImpact" then
            pcall(function() v:Destroy() end)
        end
    end

    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, v in ipairs(pg:GetDescendants()) do
            if v.Name == "SnowballOnlyRow" or v.Name == "SnowballSlot" or v:GetAttribute("N4TSnowballOnlyRow") == true or v:GetAttribute("N4TSnowballSlot") == true then
                pcall(function() v:Destroy() end)
            end
        end
    end

    print("❌ SNOWBALL OFF")
end

--========================================================
-- SOMBRAS
--========================================================
local sombrasOriginal
local function sombrasOn()
    sombrasOriginal={Technology=Lighting.Technology,GlobalShadows=Lighting.GlobalShadows,ClockTime=Lighting.ClockTime,GeographicLatitude=Lighting.GeographicLatitude,Brightness=Lighting.Brightness,ExposureCompensation=Lighting.ExposureCompensation,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,ShadowSoftness=Lighting.ShadowSoftness,FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor}
    Lighting.Technology=Enum.Technology.Voxel; Lighting.GlobalShadows=true; Lighting.PrioritizeLightingQuality=true; Lighting.ClockTime=14; Lighting.GeographicLatitude=55; Lighting.Brightness=2; Lighting.ExposureCompensation=0.4; Lighting.Ambient=Color3.fromRGB(120,120,120); Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128); Lighting.ShadowSoftness=0.2; Lighting.FogStart=0; Lighting.FogEnd=100000; Lighting.FogColor=Color3.fromRGB(192,192,192)
    for _,o in ipairs(Lighting:GetChildren()) do if o:IsA("Atmosphere") or o:IsA("BloomEffect") or o:IsA("SunRaysEffect") or o:IsA("ColorCorrectionEffect") or o:IsA("DepthOfFieldEffect") then o:Destroy() end end
    pcall(function() Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0 end)
    Lighting.Brightness=2; Lighting.ExposureCompensation=0.4; Lighting.GlobalShadows=true
    print("OLD MM2 2024 LIGHTING ativado!")
end
local function sombrasOff()
    if sombrasOriginal then for k,v in pairs(sombrasOriginal) do pcall(function() Lighting[k]=v end) end end
    print("❌ SOMBRAS OFF")
end

--========================================================
-- SOM ABAFADO
--========================================================
local somAbafadoConnection
local function somAbafadoOn()
    local FILTER_NAME = "OldMM2Audio"
    local HIGH_GAIN = -2,1
    local MID_GAIN = -0.7
    local LOW_GAIN = 5
    local function aplicarFiltro(sound)
        if not sound:IsA("Sound") then return end
        if sound:FindFirstChild(FILTER_NAME) then return end
        local equalizer=Instance.new("EqualizerSoundEffect"); equalizer.Name=FILTER_NAME; equalizer.LowGain=LOW_GAIN; equalizer.MidGain=MID_GAIN; equalizer.HighGain=HIGH_GAIN; equalizer.Parent=sound
    end
    for _,object in ipairs(game:GetDescendants()) do aplicarFiltro(object) end
    somAbafadoConnection=game.DescendantAdded:Connect(function(object) task.wait(); aplicarFiltro(object) end)
    print("OLD MM2 AUDIO ativado!")
end
local function somAbafadoOff()
    if somAbafadoConnection then somAbafadoConnection:Disconnect(); somAbafadoConnection=nil end
    for _,object in ipairs(game:GetDescendants()) do if object:IsA("EqualizerSoundEffect") and object.Name=="OldMM2Audio" then object:Destroy() end end
    print("❌ SOM ABAFADO OFF")
end

--========================================================
-- HEADLESS
--========================================================

local headlessCharacterConnection
local headlessDescendantConnection
local headlessSnapshot

local function safeGetTransparency(object)
    local ok, value = pcall(function()
        return object.Transparency
    end)
    if ok then return value end
    return nil
end

local function safeSetTransparency(object, value)
    pcall(function()
        object.Transparency = value
    end)
end

local function restoreHeadless()
    if headlessDescendantConnection then
        pcall(function() headlessDescendantConnection:Disconnect() end)
        headlessDescendantConnection = nil
    end

    local data = headlessSnapshot
    headlessSnapshot = nil
    if not data then return end

    local head = data.head
    if head and head.Parent then
        pcall(function() head.Size = data.size end)
        pcall(function() head.Transparency = data.transparency end)
        pcall(function() head.CanCollide = data.canCollide end)
        pcall(function() head.CanTouch = data.canTouch end)
        pcall(function() head.CanQuery = data.canQuery end)
    end

    for object, transparency in pairs(data.visuals) do
        if object and object.Parent and transparency ~= nil then
            safeSetTransparency(object, transparency)
        end
    end
end

local function applyHeadless(character)
    restoreHeadless()

    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 10)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not head or not torso then return end

    local visuals = {}
    for _, object in ipairs(head:GetDescendants()) do
        if object:IsA("Decal") or object:IsA("Texture") or object:IsA("SpecialMesh") then
            visuals[object] = safeGetTransparency(object)
        end
    end

    headlessSnapshot = {
        head = head,
        size = head.Size,
        transparency = head.Transparency,
        canCollide = head.CanCollide,
        canTouch = head.CanTouch,
        canQuery = head.CanQuery,
        visuals = visuals
    }

    head.Size = Vector3.new(0.1, 0.1, 0.1)
    head.Transparency = 1
    head.CanCollide = false
    head.CanTouch = false
    head.CanQuery = false

    for object in pairs(visuals) do
        safeSetTransparency(object, 1)
    end

    headlessDescendantConnection = head.DescendantAdded:Connect(function(object)
        if not states["HEADLESS"] then return end
        if object:IsA("Decal") or object:IsA("Texture") or object:IsA("SpecialMesh") then
            if headlessSnapshot and headlessSnapshot.visuals[object] == nil then
                headlessSnapshot.visuals[object] = safeGetTransparency(object)
            end
            safeSetTransparency(object, 1)
        end
    end)
end

local function headlessOff()
    if headlessCharacterConnection then
        pcall(function() headlessCharacterConnection:Disconnect() end)
        headlessCharacterConnection = nil
    end
    restoreHeadless()
    print("❌ HEADLESS OFF")
end

local function headlessOn()
    headlessOff()

    if player.Character then
        task.spawn(function()
            task.wait(0.2)
            if states["HEADLESS"] and player.Character then
                applyHeadless(player.Character)
            end
        end)
    end

    headlessCharacterConnection = player.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        if states["HEADLESS"] then
            applyHeadless(character)
        end
    end)

    print("✅ HEADLESS ON")
end

--========================================================
-- SPEED COIL
--========================================================

local SPEED_COIL_SPEED = 32
local COIL_MESH_ID = "rbxassetid://16606212"
local SPEED_MESH_TEXTURE = "rbxassetid://99170547"
local SPEED_COIL_ICON = "rbxassetid://99170415"
local SPEED_COIL_SOUND = "rbxassetid://99173388"

local speedCoilCharacterConnection
local speedCoilTool
local speedCoilOriginalWalkSpeed
local speedCoilEffectHumanoid

local function removeSpeedCoilEffect()
    if speedCoilEffectHumanoid and speedCoilEffectHumanoid.Parent and speedCoilOriginalWalkSpeed ~= nil then
        pcall(function()
            speedCoilEffectHumanoid.WalkSpeed = speedCoilOriginalWalkSpeed
        end)
    end
    speedCoilEffectHumanoid = nil
    speedCoilOriginalWalkSpeed = nil
end

local function createSpeedCoil()
    local tool = Instance.new("Tool")
    tool.Name = "Zoewar Coil"
    tool.ToolTip = "Speed Up!"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.TextureId = SPEED_COIL_ICON
    tool:SetAttribute("CoilType", "Speed")

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1.2, 2)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = COIL_MESH_ID
    mesh.TextureId = SPEED_MESH_TEXTURE
    mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
    mesh.Parent = handle

    local sound = Instance.new("Sound")
    sound.Name = "CoilSound"
    sound.SoundId = SPEED_COIL_SOUND
    sound.Volume = 1
    sound.Parent = handle

    tool.Equipped:Connect(function()
        if not states["SPEED COIL"] then return end
        removeSpeedCoilEffect()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        speedCoilEffectHumanoid = humanoid
        speedCoilOriginalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = SPEED_COIL_SPEED
        sound:Play()
    end)

    tool.Unequipped:Connect(removeSpeedCoilEffect)
    return tool
end

local function findCoil(coilType)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("CoilType") == coilType then
                return item
            end
        end
    end
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("CoilType") == coilType then
                return item
            end
        end
    end
    return nil
end

local function destroyCoilsOfType(coilType)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("CoilType") == coilType then
                item:Destroy()
            end
        end
    end
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("CoilType") == coilType then
                item:Destroy()
            end
        end
    end
end

local function ensureSpeedCoil()
    local found = findCoil("Speed")
    if found then
        speedCoilTool = found
        return
    end
    local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 10)
    if backpack and states["SPEED COIL"] then
        speedCoilTool = createSpeedCoil()
        speedCoilTool.Parent = backpack
    end
end

local function speedCoilOff()
    if speedCoilCharacterConnection then
        pcall(function() speedCoilCharacterConnection:Disconnect() end)
        speedCoilCharacterConnection = nil
    end
    removeSpeedCoilEffect()
    destroyCoilsOfType("Speed")
    speedCoilTool = nil
    print("❌ SPEED COIL OFF")
end

local function speedCoilOn()
    speedCoilOff()
    ensureSpeedCoil()
    speedCoilCharacterConnection = player.CharacterAdded:Connect(function()
        task.wait(0.6)
        if states["SPEED COIL"] then
            ensureSpeedCoil()
        end
    end)
    print("✅ SPEED COIL ON")
end

--========================================================
-- GRAVITY COIL
--========================================================

local GRAVITY_REDUCTION = 0.62
local GRAVITY_MESH_TEXTURE = "rbxassetid://16606141"
local GRAVITY_COIL_ICON = "rbxassetid://16619617"
local GRAVITY_COIL_SOUND = "rbxassetid://16619553"

local gravityCoilCharacterConnection
local gravityCoilTool
local gravityCoilHeartbeat
local gravityCoilForce
local gravityCoilHumanoid
local gravityCoilOldJumpPower
local gravityCoilOldJumpHeight
local gravityCoilUseJumpPower

local function removeGravityCoilEffect()
    if gravityCoilHeartbeat then
        pcall(function() gravityCoilHeartbeat:Disconnect() end)
        gravityCoilHeartbeat = nil
    end
    if gravityCoilForce then
        pcall(function() gravityCoilForce:Destroy() end)
        gravityCoilForce = nil
    end
    if gravityCoilHumanoid and gravityCoilHumanoid.Parent then
        pcall(function()
            if gravityCoilUseJumpPower then
                gravityCoilHumanoid.JumpPower = gravityCoilOldJumpPower
            else
                gravityCoilHumanoid.JumpHeight = gravityCoilOldJumpHeight
            end
        end)
    end
    gravityCoilHumanoid = nil
    gravityCoilOldJumpPower = nil
    gravityCoilOldJumpHeight = nil
    gravityCoilUseJumpPower = nil
end

local function createGravityCoil()
    local tool = Instance.new("Tool")
    tool.Name = "Zoewar Coil"
    tool.ToolTip = "Jump higher!"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.TextureId = GRAVITY_COIL_ICON
    tool:SetAttribute("CoilType", "Gravity")

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1.2, 2)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = COIL_MESH_ID
    mesh.TextureId = GRAVITY_MESH_TEXTURE
    mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
    mesh.Parent = handle

    local sound = Instance.new("Sound")
    sound.Name = "CoilSound"
    sound.SoundId = GRAVITY_COIL_SOUND
    sound.Volume = 1
    sound.Parent = handle

    tool.Equipped:Connect(function()
        if not states["GRAVITY COIL"] then return end
        removeGravityCoilEffect()

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end

        sound:Play()

        gravityCoilHumanoid = humanoid
        gravityCoilOldJumpPower = humanoid.JumpPower
        gravityCoilOldJumpHeight = humanoid.JumpHeight
        gravityCoilUseJumpPower = humanoid.UseJumpPower

        gravityCoilForce = Instance.new("BodyForce")
        gravityCoilForce.Name = "GravityCoilEffect"
        gravityCoilForce.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * GRAVITY_REDUCTION, 0)
        gravityCoilForce.Parent = root

        if gravityCoilUseJumpPower then
            humanoid.JumpPower = 60
        else
            humanoid.JumpHeight = 12
        end

        gravityCoilHeartbeat = RunService.Heartbeat:Connect(function()
            if not states["GRAVITY COIL"]
                or tool.Parent ~= character
                or not character.Parent
                or not humanoid.Parent
                or not root.Parent then
                removeGravityCoilEffect()
                return
            end

            if gravityCoilForce and gravityCoilForce.Parent then
                gravityCoilForce.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * GRAVITY_REDUCTION, 0)
            end
        end)
    end)

    tool.Unequipped:Connect(removeGravityCoilEffect)
    return tool
end

local function ensureGravityCoil()
    local found = findCoil("Gravity")
    if found then
        gravityCoilTool = found
        return
    end
    local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 10)
    if backpack and states["GRAVITY COIL"] then
        gravityCoilTool = createGravityCoil()
        gravityCoilTool.Parent = backpack
    end
end

local function gravityCoilOff()
    if gravityCoilCharacterConnection then
        pcall(function() gravityCoilCharacterConnection:Disconnect() end)
        gravityCoilCharacterConnection = nil
    end
    removeGravityCoilEffect()
    destroyCoilsOfType("Gravity")
    gravityCoilTool = nil
    print("❌ GRAVITY COIL OFF")
end

local function gravityCoilOn()
    gravityCoilOff()
    ensureGravityCoil()
    gravityCoilCharacterConnection = player.CharacterAdded:Connect(function()
        task.wait(0.6)
        if states["GRAVITY COIL"] then
            ensureGravityCoil()
        end
    end)
    print("✅ GRAVITY COIL ON")
end

--========================================================
-- VANGUARD HUB
--========================================================
-- O Vanguard precisa rodar como chunk separado porque o código ofuscado
-- usa ... no escopo principal. Mantemos a fonte separada e compilamos no clique.
local vanguardRunning = false
local vanguardSource = [====[
local v0=string.char;local v1=string.byte;local v2=string.sub;local v3=bit32 or bit ;local v4=v3.bxor;local v5=table.concat;local v6=table.insert;local function v7(v24,v25) local v26=0;local v27;while true do if (v26==(695 -(619 + 75))) then return v5(v27);end if (v26==(0 -0)) then v27={};for v108=807 -(118 + 688) , #v24 do v6(v27,v0(v4(v1(v2(v24,v108,v108 + (49 -(25 + 23)) )),v1(v2(v25,1 + 0 + (v108% #v25) ,1 + (v108% #v25) + (1887 -(927 + 959)) )))%256 ));end v26=3 -2 ;end end end local v8=tonumber;local v9=string.byte;local v10=string.char;local v11=string.sub;local v12=string.gsub;local v13=string.rep;local v14=table.concat;local v15=table.insert;local v16=math.ldexp;local v17=getfenv or function() return _ENV;end ;local v18=setmetatable;local v19=pcall;local v20=select;local v21=unpack or table.unpack ;local v22=tonumber;local function v23(v28,v29,...) local v30=(734 -(16 + 716)) -1 ;local v31;v28=v12(v11(v28,5),v7("\204\99","\113\226\77\197\42\188\32"),function(v42) if (v9(v42,3 -1 )==(178 -(11 + 86))) then local v96=0 -0 ;while true do if ((285 -(175 + 110))==v96) then local v126=0 -0 ;while true do if (v126==0) then v31=v8(v11(v42,1,1));return "";end end end end else local v97=0 -0 ;local v98;while true do if (v97==(1796 -(503 + 1293))) then v98=v10(v8(v42,44 -28 ));if v31 then local v132=0 + 0 ;local v133;while true do if (v132==(1062 -(810 + 251))) then return v133;end if (v132==(0 + 0)) then v133=v13(v98,v31);v31=nil;v132=1 + 0 ;end end else return v98;end break;end end end end);local function v32(v43,v44,v45) if v45 then local v99=0 + 0 ;local v100;while true do if (v99==(533 -(43 + 490))) then v100=(v43/((735 -(711 + 22))^(v44-1)))%(2^(((v45-(3 -2)) -(v44-1)) + (860 -(240 + 619)))) ;return v100-(v100%(1 + 0)) ;end end else local v101=0 -0 ;local v102;local v103;while true do if (v101==(1 + 0)) then while true do if (v102==0) then local v135=1744 -(1344 + 400) ;local v136;while true do if (v135==(405 -(255 + 150))) then v136=0 + 0 ;while true do if (v136==(0 + 0)) then v103=(8 -6)^(v44-(3 -2)) ;return (((v43%(v103 + v103))>=v103) and (1740 -(404 + 1335))) or (406 -(183 + 223)) ;end end break;end end end end break;end if (v101==(0 -0)) then v102=0;v103=nil;v101=1;end end end end local function v33() local v46=0;local v47;while true do if (v46==1) then return v47;end if ((0 + 0)==v46) then v47=v9(v28,v30,v30);v30=v30 + 1 + 0 ;v46=338 -(10 + 327) ;end end end local function v34() local v48,v49=v9(v28,v30,v30 + 2 + 0 );v30=v30 + 2 ;return (v49 * (594 -(118 + 220))) + v48 ;end local function v35() local v50=0 + 0 ;local v51;local v52;local v53;local v54;local v55;while true do if (v50==(450 -(108 + 341))) then v53=nil;v54=nil;v50=1 + 1 ;end if (v50==(8 -6)) then v55=nil;while true do local v111=1493 -(711 + 782) ;while true do if (v111==(0 -0)) then if (v51==0) then v52,v53,v54,v55=v9(v28,v30,v30 + 3 );v30=v30 + (473 -(270 + 199)) ;v51=1;end if ((1 + 0)==v51) then return (v55 * (16779035 -(580 + 1239))) + (v54 * (194824 -129288)) + (v53 * 256) + v52 ;end break;end end end break;end if (v50==0) then local v109=0;while true do if (v109==(0 + 0)) then v51=0 + 0 ;v52=nil;v109=1 + 0 ;end if (v109==(2 -1)) then v50=1 + 0 ;break;end end end end end local function v36() local v56=0;local v57;local v58;local v59;local v60;local v61;local v62;while true do local v79=0;while true do if ((1168 -(645 + 522))==v79) then if (v56==(1791 -(1010 + 780))) then local v129=0 + 0 ;local v130;while true do if (v129==0) then v130=0 -0 ;while true do if ((2 -1)==v130) then v56=2;break;end if (v130==(1836 -(1045 + 791))) then v59=2 -1 ;v60=(v32(v58,1,20) * (2^((138 -47) -59))) + v57 ;v130=506 -(351 + 154) ;end end break;end end end if ((1577 -(1281 + 293))==v56) then if (v61==0) then if (v60==(0 -(266 -(28 + 238)))) then return v62 * (0 -0) ;else local v137=1559 -(1381 + 178) ;local v138;while true do if (v137==(0 + 0)) then v138=0 + 0 ;while true do if (v138==(0 + 0)) then v61=3 -2 ;v59=(0 + 0) -(470 -(381 + 89)) ;break;end end break;end end end elseif (v61==(1816 + 231)) then return ((v60==0) and (v62 * ((1 + 0)/0))) or (v62 * NaN) ;end return v16(v62,v61-(1642 -((950 -395) + (1220 -(1074 + 82)))) ) * (v59 + (v60/(2^(983 -((1877 -1020) + 74))))) ;end break;end if (v79==0) then if (v56==2) then local v131=1784 -(214 + 1570) ;while true do if (v131==(1455 -(990 + 465))) then v61=v32(v58,9 + 12 ,14 + 17 );v62=((v32(v58,32 + 0 )==1) and  -1) or 1 ;v131=3 -2 ;end if (1==v131) then v56=1729 -(1668 + 58) ;break;end end end if (v56==(626 -(512 + 114))) then v57=v35();v58=v35();v56=2 -1 ;end v79=1 -0 ;end end end end local function v37(v63) local v64;if  not v63 then local v104=0;local v105;while true do if (v104==(0 -0)) then v105=0;while true do if (v105==0) then v63=v35();if (v63==(0 + 0)) then return "";end break;end end break;end end end v64=v11(v28,v30,(v30 + v63) -((107 + 462) -(320 + 47 + 201)) );v30=v30 + v63 ;local v65={};for v80=1, #v64 do v65[v80]=v10(v9(v11(v64,v80,v80)));end return v14(v65);end local v38=v35;local function v39(...) return {...},v20("#",...);end local function v40() local v66=1994 -(109 + 1885) ;local v67;local v68;local v69;local v70;local v71;local v72;while true do if (v66==0) then v67={};v68={};v69={};v70={v67,v68,nil,v69};v66=827 -(802 + 24) ;end if (v66==2) then for v112=1 -0 ,v35() do local v113=0;local v114;local v115;while true do if (v113==0) then v114=0 -0 ;v115=nil;v113=1 + 0 ;end if (v113==(1 + 0)) then while true do if ((0 + 0)==v114) then v115=v33();if (v32(v115,1 + 0 ,2 -1 )==(0 -0)) then local v139=0;local v140;local v141;local v142;while true do if (v139==(1 + 0)) then v142={v34(),v34(),nil,nil};if (v140==(0 + 0)) then local v193=1433 -(797 + 636) ;local v194;while true do if (v193==0) then v194=0;while true do if (v194==(0 -0)) then v142[(1620 -(1427 + 192)) + 2 ]=v34();v142[4]=v34();break;end end break;end end elseif (v140==(1 + 0)) then v142[6 -3 ]=v35();elseif (v140==(2 + 0)) then v142[3]=v35() -(2^(8 + 8)) ;elseif (v140==(329 -(192 + 134))) then local v511=1276 -(316 + 960) ;local v512;while true do if (v511==(0 + 0)) then v512=0 + 0 ;while true do if (v512==(0 + 0)) then v142[3]=v35() -((7 -5)^(3 + (564 -(83 + 468)))) ;v142[1810 -(1202 + 604) ]=v34();break;end end break;end end end v139=9 -7 ;end if (v139==(2 -0)) then if (v32(v141,1,1)==1) then v142[5 -3 ]=v72[v142[327 -(45 + 280) ]];end if (v32(v141,2 + 0 ,2 + 0 )==(1 + 0)) then v142[2 + 1 ]=v72[v142[(155 + 725) -((521 -239) + (2506 -(340 + 1571))) ]];end v139=2 + 1 ;end if (v139==3) then if (v32(v141,1775 -(1733 + 39) ,8 -5 )==(1035 -(125 + 909))) then v142[1952 -(1096 + 852) ]=v72[v142[4]];end v67[v112]=v142;break;end if (v139==(0 + 0)) then local v144=0 -0 ;while true do if ((0 + 0)==v144) then v140=v32(v115,514 -(409 + 103) ,3);v141=v32(v115,240 -(46 + 190) ,101 -(51 + 44) );v144=1;end if (v144==1) then v139=1;break;end end end end end break;end end break;end end end for v116=1 + 0 ,v35() do v68[v116-1 ]=v40();end return v70;end if (v66==1) then v71=v35();v72={};for v118=1318 -(1114 + 203) ,v71 do local v119=726 -(228 + 498) ;local v120;local v121;while true do if (v119==(1 + 0)) then if (v120==1) then v121=v33()~=(0 + 0) ;elseif (v120==2) then v121=v36();elseif (v120==(666 -(174 + 489))) then v121=v37();end v72[v118]=v121;break;end if (v119==(0 -0)) then v120=v33();v121=nil;v119=1906 -(830 + 1075) ;end end end v70[527 -(303 + 221) ]=v33();v66=1271 -(231 + 1038) ;end end end local function v41(v73,v74,v75) local v76=v73[1 + 0 ];local v77=v73[1164 -(171 + 991) ];local v78=v73[3];return function(...) local v82=v76;local v83=v77;local v84=v78;local v85=v39;local v86=4 -3 ;local v87= -(2 -1);local v88={};local v89={...};local v90=v20("#",...) -(2 -1) ;local v91={};local v92={};for v106=0 + 0 ,v90 do if (v106>=v84) then v88[v106-v84 ]=v89[v106 + 1 ];else v92[v106]=v89[v106 + (3 -2) ];end end local v93=(v90-v84) + (2 -1) ;local v94;local v95;while true do local v107=0;while true do if (v107==(1 -0)) then if (v95<=((5122 -3465) -(1523 + 114))) then if (v95<=9) then if (v95<=(1252 -(111 + 1137))) then if (v95<=(159 -(91 + 67))) then if (v95>(0 -0)) then v92[v94[1 + 1 ]]=v92[v94[526 -(423 + 100) ]] + v94[1 + 3 ] ;else local v146=0 -0 ;local v147;while true do if (v146==0) then v147=v94[2];v92[v147]=v92[v147](v21(v92,v147 + 1 + 0 ,v94[(774 -(326 + 445)) + (0 -0) ]));break;end end end elseif (v95<=(4 -2)) then v92[v94[4 -2 ]]=v92[v94[714 -(530 + 181) ]]%v92[v94[(886 -(614 + 267)) -(33 -(19 + 13)) ]] ;elseif (v95>3) then local v201=0 -0 ;local v202;local v203;local v204;while true do if (v201==(0 -0)) then local v397=0;while true do if (v397==(2 -1)) then v201=1 + 0 ;break;end if (v397==(0 -0)) then v202=0 -0 ;v203=nil;v397=1813 -(1293 + 519) ;end end end if (v201==1) then v204=nil;while true do if (v202==0) then local v513=0 -0 ;while true do if (v513==(2 -1)) then v202=1 -0 ;break;end if (v513==(0 -0)) then v203=v94[6 -3 ];v204=v92[v203];v513=1 + 0 ;end end end if (v202==(1 + 0)) then for v537=v203 + (2 -1) ,v94[1 + 3 ] do v204=v204   .. v92[v537] ;end v92[v94[1 + 1 ]]=v204;break;end end break;end end else local v205=0;local v206;local v207;local v208;local v209;while true do if (v205==(1 + 0)) then v208=nil;v209=nil;v205=1098 -(709 + 387) ;end if (v205==(1860 -(673 + 1185))) then while true do if ((2 -1)==v206) then v209=v92[v207] + v208 ;v92[v207]=v209;v206=6 -4 ;end if ((2 -0)==v206) then if (v208>(0 + 0)) then if (v209<=v92[v207 + (1271 -(226 + 781 + 263)) ]) then local v592=0 -0 ;while true do if (v592==(0 + 0)) then v86=v94[5 -2 ];v92[v207 + (5 -2) ]=v209;break;end end end elseif (v209>=v92[v207 + (1881 -(446 + 1434)) ]) then v86=v94[(1295 -(1040 + 243)) -9 ];v92[v207 + (8 -5) ]=v209;end break;end if (v206==0) then local v516=1847 -(559 + 1288) ;local v517;while true do if (v516==(1931 -(609 + 1322))) then v517=0;while true do if ((454 -(13 + 441))==v517) then v207=v94[(3987 -2920) -((177 -109) + (4965 -3968)) ];v208=v92[v207 + 1 + 1 ];v517=3 -2 ;end if (v517==(1 + 0)) then v206=1 + 0 ;break;end end break;end end end end break;end if (0==v205) then v206=0 -0 ;v207=nil;v205=1 + 0 ;end end end elseif (v95<=(10 -4)) then if (v95>(4 + 1)) then local v149=0;local v150;while true do if (v149==(0 + 0)) then v150=v94[2 + 0 ];v92[v150](v21(v92,v150 + 1 + 0 ,v87));break;end end else v92[v94[2]]= #v92[v94[3]];end elseif (v95<=7) then v92[v94[2 + 0 ]]=v94[436 -(153 + 280) ] + v92[v94[11 -7 ]] ;elseif (v95>8) then local v210=v94[2 + 0 ];local v211={};for v271=1, #v91 do local v272=0 + 0 ;local v273;while true do if (0==v272) then v273=v91[v271];for v484=0 + 0 , #v273 do local v485=0 + 0 ;local v486;local v487;local v488;local v489;while true do if (v485==(0 + 0)) then v486=0 -0 ;v487=nil;v485=1 + 0 ;end if (v485==1) then v488=nil;v489=nil;v485=669 -(89 + 578) ;end if ((2 + 0)==v485) then while true do if (v486==1) then v489=v487[2];if ((v488==v92) and (v489>=v210)) then local v609=0 -0 ;while true do if (v609==0) then v211[v489]=v488[v489];v487[1050 -(572 + 477) ]=v211;break;end end end break;end if (v486==(0 + 0)) then local v602=0 + 0 ;while true do if (v602==(1 + 0)) then v486=1;break;end if (v602==0) then v487=v273[v484];v488=v487[1];v602=87 -(84 + 2) ;end end end end break;end end end break;end end end elseif (v92[v94[2 -0 ]]==v94[3 + 1 ]) then v86=v86 + 1 ;else v86=v94[3];end elseif (v95<=(856 -(497 + 345))) then if (v95<=11) then if (v95==(1 + 9)) then local v153=0;local v154;local v155;local v156;while true do if ((1 + 0)==v153) then v156=v92[v154 + (119 -((1365 -(605 + 728)) + 61 + 24)) ];if (v156>(0 -0)) then if (v155>v92[v154 + 1 + 0 ]) then v86=v94[10 -7 ];else v92[v154 + 3 ]=v155;end elseif (v155<v92[v154 + 1 + 0 ]) then v86=v94[3];else v92[v154 + (7 -4) ]=v155;end break;end if (v153==(0 + 0)) then v154=v94[491 -(457 + 32) ];v155=v92[v154];v153=1 + 0 ;end end else local v157=1402 -(832 + 570) ;local v158;local v159;local v160;while true do if (v157==(0 + 0)) then local v277=0 + 0 ;while true do if (v277==(0 -0)) then v158=0;v159=nil;v277=1 + 0 ;end if (v277==(797 -(588 + 208))) then v157=2 -1 ;break;end end end if (v157==1) then v160=nil;while true do if (v158==(1800 -(884 + 916))) then local v440=0 -0 ;while true do if (v440==(1 + 0)) then v158=654 -(232 + 421) ;break;end if (v440==0) then v159=v94[1891 -(1569 + 320) ];v160=v92[v159];v440=1;end end end if (v158==1) then for v494=v159 + 1 ,v87 do v15(v160,v92[v494]);end break;end end break;end end end elseif (v95<=(3 + 9)) then local v161=0 + 0 ;local v162;local v163;local v164;local v165;while true do if (v161==5) then v92[v165]=v92[v165](v21(v92,v165 + (3 -2) ,v87));v86=v86 + (606 -(316 + 289)) ;v94=v82[v86];v92[v94[2]]=v74[v94[5 -(5 -3) ]];v86=v86 + 1 + 0 ;v94=v82[v86];v92[v94[1455 -(666 + 787) ]]=v74[v94[428 -(360 + 65) ]];v161=6 + 0 ;end if (v161==(267 -(79 + 175))) then v87=(v164 + v165) -(1 -0) ;v162=0 + 0 ;for v385=v165,v87 do local v386=0;while true do if (v386==0) then v162=v162 + (2 -1) ;v92[v385]=v163[v162];break;end end end v86=v86 + (1 -0) ;v94=v82[v86];v165=v94[901 -(503 + 396) ];v92[v165](v21(v92,v165 + ((1179 -(92 + 89)) -((1774 -859) + 43 + 39)) ,v87));break;end if (v161==(7 + 4)) then v87=(v164 + v165) -(3 -2) ;v162=0 + 0 ;for v387=v165,v87 do local v388=0 -0 ;while true do if (v388==(0 + 0)) then v162=v162 + ((1 + 1) -1) ;v92[v387]=v163[v162];break;end end end v86=v86 + (2 -1) ;v94=v82[v86];v165=v94[(1 + 2) -1 ];v92[v165]=v92[v165](v21(v92,v165 + 1 ,v87));v161=17 -5 ;end if (v161==(1252 -(485 + 759))) then local v289=0 -0 ;while true do if (v289==(1189 -(442 + 747))) then v92[v94[1137 -(832 + 303) ]]= #v92[v94[3]];v86=v86 + (947 -(88 + 858)) ;v289=1 + 0 ;end if (v289==(1 + 0)) then v94=v82[v86];v92[v94[2]]=v92[v94[1 + 2 ]]%v92[v94[(798 -(766 + 23)) -(24 -19) ]] ;v289=2;end if (v289==3) then v92[v94[2 + (0 -0) ]]=v94[7 -4 ] + v92[v94[13 -9 ]] ;v161=1082 -(1036 + 37) ;break;end if (v289==(2 + 0)) then v86=v86 + (1 -0) ;v94=v82[v86];v289=3 + 0 ;end end end if (0==v161) then local v290=0;while true do if (v290==(1483 -(641 + 839))) then v92[v94[915 -(910 + 3) ]]=v74[v94[3]];v161=2 -1 ;break;end if (v290==(1685 -(1466 + 218))) then v165=nil;v92[v94[1 + 1 ]]=v92[v94[1151 -(556 + 592) ]];v290=1 + 1 ;end if ((808 -(329 + 479))==v290) then v162=nil;v163,v164=nil;v290=855 -(174 + 680) ;end if (v290==2) then v86=v86 + 1 ;v94=v82[v86];v290=10 -7 ;end end end if (v161==10) then v87=(v164 + v165) -(1 -0) ;v162=(680 + 272) -((1541 -(396 + 343)) + 14 + 136) ;for v389=v165,v87 do local v390=1477 -(29 + 1448) ;while true do if (v390==0) then v162=v162 + (1390 -(135 + 1254)) ;v92[v389]=v163[v162];break;end end end v86=v86 + 1 ;v94=v82[v86];v165=v94[7 -5 ];v163,v164=v85(v92[v165](v21(v92,v165 + (4 -3) ,v87)));v161=11;end if (v161==(6 + 3)) then v86=v86 + ((1530 -(389 + 1138)) -(576 -(102 + 472))) ;v94=v82[v86];v92[v94[2 + 0 ]]=v92[v94[2 + 1 ]] + v94[4] ;v86=v86 + 1 ;v94=v82[v86];v165=v94[2 + 0 ];v163,v164=v85(v92[v165](v21(v92,v165 + (1546 -(320 + 1225)) ,v94[3])));v161=10;end if (v161==4) then v163,v164=v85(v92[v165](v21(v92,v165 + 1 ,v94[5 -2 ])));v87=(v164 + v165) -(1 + 0) ;v162=1464 -(157 + 1307) ;for v391=v165,v87 do local v392=1859 -(821 + 1038) ;local v393;while true do if (v392==0) then v393=0 -0 ;while true do if (0==v393) then v162=v162 + 1 + 0 ;v92[v391]=v163[v162];break;end end break;end end end v86=v86 + 1 ;v94=v82[v86];v165=v94[2];v161=8 -3 ;end if (v161==(3 + 3)) then v86=v86 + (2 -1) ;v94=v82[v86];v92[v94[1028 -(834 + 192) ]]=v92[v94[(1 + 3) -(1 + 0) ]];v86=v86 + 1 ;v94=v82[v86];v92[v94[1 + 1 ]]= #v92[v94[3]];v86=v86 + 1 ;v161=10 -3 ;end if ((311 -(300 + 4))==v161) then v94=v82[v86];v92[v94[1 + 1 ]]=v92[v94[(924 -571) -((449 -(112 + 250)) + 105 + 158) ]]%v92[v94[4]] ;v86=v86 + 1 ;v94=v82[v86];v92[v94[4 -2 ]]=v94[(105 + 78) -(67 + 59 + 54) ] + v92[v94[3 + 1 ]] ;v86=v86 + 1 + 0 + 0 + 0 ;v94=v82[v86];v161=1422 -(1001 + 413) ;end if (v161==(26 -14)) then v86=v86 + 1 ;v94=v82[v86];v92[v94[2 + 0 ]]=v92[v94[885 -(244 + 638) ]]%v94[697 -(627 + 66) ] ;v86=v86 + (2 -1) ;v94=v82[v86];v165=v94[604 -(512 + 90) ];v163,v164=v85(v92[v165](v92[v165 + 1 ]));v161=1919 -(1665 + 241) ;end if (v161==1) then v86=v86 + 1 ;v94=v82[v86];v92[v94[2]]=v74[v94[720 -(373 + 344) ]];v86=v86 + 1 + 0 ;v94=v82[v86];v92[v94[1 + 1 ]]=v74[v94[7 -4 ]];v86=v86 + (1 -0) ;v161=1101 -(35 + 1064) ;end if (v161==(2 + 0)) then v94=v82[v86];v92[v94[2 + 0 ]]=v74[v94[6 -3 ]];v86=v86 + 1 + 0 ;v94=v82[v86];v92[v94[1238 -(298 + 938) ]]=v92[v94[3]];v86=v86 + (1260 -(233 + 1026)) ;v94=v82[v86];v161=1669 -(636 + 1030) ;end if (v161==(2 + 1)) then v92[v94[2 + 0 ]]=v92[v94[3]];v86=v86 + 1 ;v94=v82[v86];v92[v94[1 + 1 ]]=v92[v94[1 + 2 ]] + v94[(222 -(55 + 166)) + 1 + 2 ] ;v86=v86 + ((97 + 861) -(892 + 65)) ;v94=v82[v86];v165=v94[(15 -11) -(299 -(36 + 261)) ];v161=6 -2 ;end end elseif (v95>(1381 -(34 + 1334))) then local v212=0 + 0 ;local v213;local v214;local v215;while true do if (v212==(0 + 0)) then v213=v94[(1288 -(1035 + 248)) -3 ];v214={v92[v213](v92[v213 + 1 + 0 + (319 -(134 + 185)) ])};v212=1;end if (v212==(1134 -(549 + 584))) then v215=(685 -(314 + 371)) -(0 -0) ;for v451=v213,v94[4] do local v452=968 -(478 + 490) ;while true do if ((0 + 0)==v452) then v215=v215 + (1173 -(786 + 386)) ;v92[v451]=v214[v215];break;end end end break;end end else do return v92[v94[2]]();end end elseif (v95<=(55 -38)) then if (v95<=15) then local v166=1379 -(1055 + 324) ;local v167;local v168;local v169;while true do if (v166==(1340 -(1093 + 247))) then local v323=0 + 0 ;while true do if (v323==(1 + 0)) then v169=nil;v92[v94[7 -5 ]]={};v323=6 -4 ;end if (v323==2) then v166=1;break;end if (v323==(0 -0)) then v167=nil;v168=nil;v323=1;end end end if (v166==(4 -2)) then v94=v82[v86];v92[v94[1 + 1 ]]= #v92[v94[3]];v86=v86 + ((7 -5) -1) ;v94=v82[v86];v166=10 -7 ;end if ((3 + 0)==v166) then v92[v94[2]]=v94[7 -4 ];v86=v86 + 1 ;v94=v82[v86];v169=v94[690 -(364 + 324) ];v166=4;end if (v166==4) then v168=v92[v169];v167=v92[v169 + 2 ];if (v167>(0 -0)) then if (v168>v92[v169 + (2 -1) ]) then v86=v94[1 + 2 ];else v92[v169 + (12 -9) ]=v168;end elseif (v168<v92[v169 + (1 -0) ]) then v86=v94[3];else v92[v169 + (8 -5) ]=v168;end break;end if (v166==1) then v86=v86 + (1188 -((2337 -(1249 + 19)) + 107 + 11)) ;v94=v82[v86];v92[v94[2]]=v94[11 -8 ];v86=v86 + (1087 -(686 + 400)) ;v166=2 + 0 ;end end elseif (v95>(245 -(73 + 156))) then local v216=0;local v217;local v218;while true do if (v216==(1 + 0)) then while true do if ((811 -(721 + 90))==v217) then v218=v94[1 + 1 ];do return v92[v218](v21(v92,v218 + 1 ,v94[3]));end break;end end break;end if ((0 -0)==v216) then v217=470 -(224 + 246) ;v218=nil;v216=1 -0 ;end end else local v219=0 -0 ;local v220;local v221;local v222;local v223;while true do if ((1 + 1)==v219) then local v399=0;while true do if (v399==(1 + 0)) then v86=v86 + 1 + 0 + 0 ;v219=5 -2 ;break;end if (v399==0) then v223=v94[(9 -6) -1 ];v92[v223]=v92[v223](v21(v92,v223 + (514 -(203 + 310)) ,v94[1996 -(1238 + 755) ]));v399=1 + 0 ;end end end if (v219==0) then v220=nil;v221,v222=nil;v223=nil;v219=1535 -(709 + 825) ;end if ((4 -1)==v219) then v94=v82[v86];v92[v94[2 -0 ]]=v94[3];v86=v86 + (865 -(196 + 668)) ;v219=15 -11 ;end if (v219==(1 -0)) then local v403=0;while true do if (v403==(833 -(171 + 662))) then v92[v94[2]]=v94[3];v86=v86 + 1 ;v403=94 -(4 + 89) ;end if ((3 -2)==v403) then v94=v82[v86];v219=1 + 1 ;break;end end end if (v219==(17 -13)) then v94=v82[v86];v223=v94[3 -1 ];v221,v222=v85(v92[v223](v21(v92,v223 + 1 + 0 ,v94[1489 -(35 + 1451) ])));v219=1458 -(28 + 1425) ;end if (v219==(2000 -(941 + 1052))) then v92[v223]=v92[v223](v21(v92,v223 + 1 + 0 ,v87));v86=v86 + (1515 -(822 + 692)) ;v94=v82[v86];v219=8;end if (v219==(7 -1)) then v86=v86 + 1 + 0 ;v94=v82[v86];v223=v94[2];v219=304 -(45 + 252) ;end if (v219==(8 + 0)) then if (v92[v94[2]]==v94[2 + 2 ]) then v86=v86 + (2 -1) ;else v86=v94[436 -(114 + 319) ];end break;end if ((6 -1)==v219) then v87=(v222 + v223) -(1 -0) ;v220=0;for v454=v223,v87 do v220=v220 + 1 + 0 ;v92[v454]=v221[v220];end v219=8 -2 ;end end end elseif (v95<=(37 -19)) then v92[v94[2]]=v92[v94[1966 -(556 + 1407) ]];elseif (v95==((1225 -(741 + 465)) + (465 -(170 + 295)))) then v92[v94[2]]=v74[v94[2 + 1 ]];else local v226=0 + 0 ;local v227;local v228;local v229;local v230;local v231;local v232;while true do if (v226==(0 -0)) then local v410=0 + 0 ;while true do if ((0 + 0)==v410) then v227=0 + 0 ;v228=nil;v410=1231 -(957 + 273) ;end if (v410==1) then v226=1 + 0 ;break;end end end if ((1 + 1)==v226) then v231=nil;v232=nil;v226=11 -8 ;end if (v226==(7 -4)) then while true do if (v227==3) then local v524=0 -0 ;while true do if (v524==(9 -7)) then for v595=v94[1782 -(389 + 1391) ],v94[3] do v92[v595]=nil;end v86=v86 + 1 + 0 ;v524=1 + 2 ;end if (v524==(6 -3)) then v227=955 -(783 + 168) ;break;end if (v524==(0 -0)) then v94=v82[v86];v92[v94[2]]=v92[v94[3]];v524=1 + 0 ;end if (v524==(312 -(309 + 2))) then v86=v86 + 1 ;v94=v82[v86];v524=2;end end end if (v227==0) then local v525=0 -0 ;while true do if ((1212 -(1090 + 122))==v525) then v228=nil;v229=nil;v525=1 + 0 ;end if (v525==(6 -4)) then v92[v94[2 + 0 ]]=v74[v94[3]];v86=v86 + 1 ;v525=1121 -(628 + 490) ;end if (v525==(1 + 0)) then v230,v231=nil;v232=nil;v525=4 -2 ;end if (v525==(13 -10)) then v227=1;break;end end end if (v227==(778 -(431 + 343))) then local v526=0;while true do if (v526==(5 -2)) then v227=5;break;end if (v526==2) then v229=(0 -0) -(0 + 0) ;for v597=v232,v87 do local v598=0;while true do if (v598==0) then v229=v229 + 1 ;v92[v597]=v230[v229];break;end end end v526=1 + 2 ;end if (v526==0) then v94=v82[v86];v232=v94[1697 -(556 + 1139) ];v526=1;end if ((16 -(6 + 9))==v526) then v230,v231=v85(v92[v232](v21(v92,v232 + 1 ,v94[3])));v87=(v231 + v232) -(1 + 0) ;v526=2 + 0 ;end end end if (v227==(174 -(28 + 141))) then v86=v86 + 1 + 0 ;v94=v82[v86];v232=v94[2 -0 ];v228=v92[v232];for v542=v232 + 1 + 0 ,v87 do v15(v228,v92[v542]);end break;end if (v227==(1319 -(486 + 831))) then local v530=0;while true do if ((5 -3)==v530) then v92[v94[6 -4 ]]=v74[v94[3]];v86=v86 + 1 ;v530=1 + 2 ;end if (v530==(3 -2)) then v86=v86 + (1264 -(668 + 595)) ;v94=v82[v86];v530=2;end if (v530==(0 + 0)) then v94=v82[v86];v92[v94[2]]={};v530=1 + 0 ;end if (3==v530) then v227=8 -5 ;break;end end end if (v227==(291 -(23 + 267))) then local v531=1944 -(1129 + 815) ;while true do if (v531==3) then v227=2;break;end if (v531==(387 -(371 + 16))) then v94=v82[v86];v92[v94[1752 -(1326 + 424) ]]=v74[v94[5 -2 ]];v531=1;end if (v531==2) then v92[v94[2]]=v74[v94[3]];v86=v86 + (3 -2) ;v531=121 -(88 + 30) ;end if (v531==(772 -(720 + 51))) then v86=v86 + ((1761 -969) -((2144 -(421 + 1355)) + (697 -274))) ;v94=v82[v86];v531=1 + 1 ;end end end end break;end if (v226==(1084 -(286 + 797))) then local v411=0;while true do if (v411==(3 -2)) then v226=2;break;end if (v411==(0 -0)) then v229=nil;v230=nil;v411=440 -(397 + 42) ;end end end end end elseif (v95<=31) then if (v95<=((14 + 29) -((810 -(24 + 776)) + 8))) then if (v95<=((128 -44) -(847 -(222 + 563)))) then if (v95==(45 -24)) then local v172=0 + 0 ;local v173;local v174;local v175;while true do if (v172==(191 -(23 + 167))) then v175=nil;while true do if (0==v173) then local v457=1798 -(690 + 1108) ;while true do if (v457==0) then v174=v94[1 + 1 ];v175=v92[v94[3]];v457=1 + 0 ;end if (v457==(849 -(40 + 808))) then v173=1 + 0 ;break;end end end if (v173==(3 -2)) then v92[v174 + ((424 + 19) -(221 + 195 + 26)) ]=v175;v92[v174]=v175[v94[4]];break;end end break;end if ((0 + 0)==v172) then local v335=571 -(47 + 524) ;while true do if (v335==0) then v173=0 + 0 ;v174=nil;v335=2 -1 ;end if (v335==(1 -0)) then v172=2 -1 ;break;end end end end else v92[v94[1728 -(1165 + 561) ]]=v75[v94[1 + 2 ]];end elseif (v95<=(71 -48)) then local v178=0;local v179;local v180;local v181;local v182;while true do if (v178==2) then for v394=v179,v87 do local v395=0;while true do if (v395==(0 + 0)) then v182=v182 + (480 -(341 + 138)) ;v92[v394]=v180[v182];break;end end end break;end if (v178==0) then v179=v94[1 + 1 ];v180,v181=v85(v92[v179](v92[v179 + (1 -0) ]));v178=327 -(89 + 237) ;end if (v178==(3 -2)) then v87=(v181 + v179) -(1 -0) ;v182=0;v178=2;end end elseif (v95>24) then v92[v94[(887 -(581 + 300)) -(1224 -(855 + 365)) ]]={};else local v234=0 -0 ;local v235;local v236;local v237;local v238;while true do if (v234==2) then for v461=v235,v87 do local v462=0;while true do if (v462==0) then v238=v238 + 1 + 0 ;v92[v461]=v236[v238];break;end end end break;end if (v234==(1235 -(1030 + 205))) then v235=v94[1 + 0 + 1 + 0 ];v236,v237=v85(v92[v235](v21(v92,v235 + 1 ,v87)));v234=287 -(156 + 130) ;end if (v234==1) then v87=(v237 + v235) -(2 -1) ;v238=(0 -0) -0 ;v234=3 -1 ;end end end elseif (v95<=(8 + 20)) then if (v95<=(464 -(145 + 293))) then local v183=0 + 0 ;local v184;local v185;local v186;while true do if (v183==(70 -(10 + 59))) then v94=v82[v86];v92[v94[1 + 1 ]]=v94[14 -11 ];v86=v86 + (1164 -(671 + 492)) ;v94=v82[v86];v92[v94[2 + 0 ]]=v94[1218 -(369 + 846) ];v183=1 + 1 ;end if (v183==(6 + 0)) then v86=v86 + (1946 -(1036 + 909)) ;v94=v82[v86];v186=v94[2];v92[v186](v92[v186 + 1 + 0 ]);break;end if (v183==(4 -1)) then local v344=203 -(11 + 192) ;local v345;while true do if (v344==(0 + 0)) then v345=0;while true do if (v345==2) then v92[v94[177 -(135 + 40) ]]=v92[v94[3]];v183=9 -5 ;break;end if (v345==(0 + 0)) then v94=v82[v86];v92[v94[(3277 -1789) -(998 + (731 -243)) ]]=v75[v94[179 -(50 + 126) ]];v345=2 -1 ;end if (v345==(1 + 0)) then v86=v86 + 1 ;v94=v82[v86];v345=1415 -(1233 + 180) ;end end break;end end end if (v183==0) then v184=nil;v185=nil;v186=nil;v92[v94[(1401 -(522 + 447)) -((1465 -(107 + 1314)) + 180 + 206) ]]=v74[v94[3]];v86=v86 + (2 -1) ;v183=1 + 0 ;end if (v183==(3 -1)) then local v348=0 -0 ;while true do if (v348==(1910 -(716 + 1194))) then v86=v86 + 1 + 0 ;v94=v82[v86];v348=1 + 0 ;end if (v348==1) then v186=v94[505 -(74 + 429) ];v92[v186]=v92[v186](v21(v92,v186 + 1 ,v94[3]));v348=3 -1 ;end if (v348==2) then v86=v86 + 1 + 0 ;v183=6 -3 ;break;end end end if (v183==(3 + 1)) then local v349=0;while true do if (v349==(5 -3)) then v86=v86 + 1 ;v183=5;break;end if (v349==0) then v86=v86 + (2 -1) ;v94=v82[v86];v349=434 -(279 + 154) ;end if (1==v349) then v186=v94[780 -(454 + 324) ];v92[v186]=v92[v186](v92[v186 + 1 ]);v349=2 + 0 ;end end end if (v183==5) then local v350=0;while true do if (v350==1) then v184=v92[v185];for v508=v185 + (18 -(12 + 5)) ,v94[4] do v184=v184   .. v92[v508] ;end v350=2 + 0 ;end if (v350==(4 -2)) then v92[v94[1 + 1 ]]=v184;v183=1099 -(277 + 816) ;break;end if (v350==(0 -0)) then v94=v82[v86];v185=v94[1 + (1185 -(1058 + 125)) ];v350=1 + 0 ;end end end end elseif (v95==27) then local v239=975 -(815 + 160) ;local v240;local v241;local v242;local v243;local v244;while true do if (v239==3) then v94=v82[v86];v244=v94[8 -6 ];v241,v242=v85(v92[v244](v21(v92,v244 + (2 -1) ,v94[1141 -(28 + 88 + (2987 -1965)) ])));v87=(v242 + v244) -(4 -(1901 -(41 + 1857))) ;v240=1893 -(1222 + 671) ;for v473=v244,v87 do local v474=0;while true do if (0==v474) then v240=v240 + 1 ;v92[v473]=v241[v240];break;end end end v239=10 -6 ;end if ((0 -0)==v239) then v240=nil;v241,v242=nil;v243=nil;v244=nil;v92[v94[1184 -(229 + 953) ]]=v75[v94[3]];v86=v86 + (1775 -(1111 + 663)) ;v239=1580 -(874 + 705) ;end if ((1 + 0)==v239) then v94=v82[v86];v92[v94[2 + 0 ]]=v75[v94[6 -3 ]];v86=v86 + 1 + 0 ;v94=v82[v86];v244=v94[2];v243=v92[v94[3 + (679 -(642 + 37)) ]];v239=1 + 1 ;end if (v239==(1 + 1)) then v92[v244 + 1 ]=v243;v92[v244]=v243[v94[4]];v86=v86 + 1 ;v94=v82[v86];v92[v94[4 -2 ]]=v74[v94[(1229 -(233 + 221)) -((464 -263) + 503 + 68) ]];v86=v86 + (1542 -(718 + 823)) ;v239=2 + 1 ;end if (v239==4) then v86=v86 + 1 ;v94=v82[v86];v244=v94[2];v92[v244]=v92[v244](v21(v92,v244 + (806 -(266 + 539)) ,v87));v86=v86 + (2 -1) ;v94=v82[v86];v239=1230 -(636 + 589) ;end if (v239==(14 -8)) then v94=v82[v86];do return;end break;end if (v239==(10 -5)) then do return v92[v94[2 + 0 ]]();end v86=v86 + 1 ;v94=v82[v86];v244=v94[2];do return v21(v92,v244,v87);end v86=v86 + 1 + 0 ;v239=6;end end else local v245=1015 -(657 + 358) ;local v246;local v247;while true do if (v245==(2 -1)) then while true do if (v246==(0 -0)) then v247=v94[1189 -(1151 + 36) ];v92[v247]=v92[v247](v92[v247 + 1 + 0 ]);break;end end break;end if (v245==(0 + 0)) then v246=0 -0 ;v247=nil;v245=1833 -(1552 + 280) ;end end end elseif (v95<=(863 -(64 + 770))) then local v187=0;local v188;local v189;while true do if (v187==1) then while true do if (v188==(0 + 0)) then v189=v94[2];v92[v189]=v92[v189](v21(v92,v189 + (2 -1) + 0 + 0 ,v87));break;end end break;end if (v187==(1243 -(157 + 1086))) then v188=0;v189=nil;v187=1 -0 ;end end elseif (v95==(131 -101)) then if  not v92[v94[2 -0 ]] then v86=v86 + (3 -(2 -0)) ;else v86=v94[822 -(599 + 220) ];end else v92[v94[3 -1 ]]=v94[3];end elseif (v95<=(1967 -(1813 + 118))) then if (v95<=(25 + 8)) then if (v95==32) then do return;end else v92[v94[1219 -(841 + 376) ]]=v92[v94[3]]%v94[4] ;end elseif (v95<=(120 -(119 -33))) then local v191=0 + 0 ;while true do if (v191==(0 -0)) then local v351=859 -(464 + 395) ;local v352;while true do if (v351==(0 -0)) then v352=0;while true do if (v352==(0 + 0)) then v92[v94[(1698 -(467 + 370)) -((1682 -868) + 45) ]]=v75[v94[3 + 0 ]];v86=v86 + (3 -2) ;v352=1;end if (v352==1) then v94=v82[v86];v191=1 + 0 ;break;end end break;end end end if (v191==(4 -2)) then v92[v94[(524 -(150 + 370)) -2 ]]=v75[v94[3]];v86=v86 + (1283 -(74 + 1208)) + (0 -0) ;v94=v82[v86];v191=3;end if (v191==(4 -3)) then v92[v94[2 + 0 ]]=v92[v94[393 -(14 + 376) ]][v94[4]];v86=v86 + (1 -0) ;v94=v82[v86];v191=2;end if (v191==5) then local v359=0 + 0 ;while true do if (v359==(1 + 0)) then v94=v82[v86];v191=6 + 0 ;break;end if (v359==(0 -0)) then v92[v94[2]]=v92[v94[3 + 0 ]][v94[889 -((339 -(23 + 55)) + (1478 -854)) ]];v86=v86 + 1 + 0 ;v359=1 + 0 ;end end end if (v191==(4 -1)) then v92[v94[1 + 0 + (902 -(652 + 249)) ]]=v92[v94[7 -4 ]][v94[1872 -(708 + 1160) ]];v86=v86 + 1 ;v94=v82[v86];v191=4;end if (v191==(16 -10)) then v92[v94[3 -1 ]]=v75[v94[3]];v86=v86 + 1 ;v94=v82[v86];v191=7;end if (v191==4) then local v366=27 -(10 + 17) ;local v367;while true do if (v366==(0 + 0)) then v367=0;while true do if (v367==(1733 -(1400 + 332))) then v94=v82[v86];v191=5;break;end if (v367==(0 -0)) then v92[v94[2]]=v75[v94[1911 -(242 + 1666) ]];v86=v86 + 1 ;v367=1 + 0 ;end end break;end end end if (v191==(3 + 4)) then if  not v92[v94[2]] then v86=v86 + 1 ;else v86=v94[3 + 0 ];end break;end end elseif (v95>35) then local v250=940 -(850 + 90) ;local v251;local v252;local v253;local v254;local v255;while true do if (v250==2) then v255=nil;while true do if (v251==1) then local v534=0 -0 ;while true do if (v534==(1391 -(360 + 1030))) then v251=2;break;end if ((0 + 0)==v534) then v87=(v254 + v252) -1 ;v255=0;v534=1;end end end if (2==v251) then for v561=v252,v87 do local v562=0;while true do if ((0 -0)==v562) then v255=v255 + 1 ;v92[v561]=v253[v255];break;end end end break;end if (v251==(0 -0)) then v252=v94[1663 -(909 + 752) ];v253,v254=v85(v92[v252](v21(v92,v252 + (1224 -(109 + 1114)) ,v94[5 -2 ])));v251=1 + 0 ;end end break;end if ((242 -(6 + 236))==v250) then local v435=0 + 0 ;while true do if (v435==0) then v251=0 + 0 ;v252=nil;v435=1;end if (v435==(2 -1)) then v250=1 -0 ;break;end end end if ((1134 -(1076 + 57))==v250) then v253=nil;v254=nil;v250=1 + 1 ;end end else for v368=v94[691 -(579 + 110) ],v94[3] do v92[v368]=nil;end end elseif (v95<=(4 + 35)) then if (v95<=37) then v86=v94[3 + 0 ];elseif (v95==(21 + 17)) then local v256=407 -(174 + 233) ;local v257;while true do if (v256==(0 -0)) then v257=v94[3 -1 ];v92[v257](v92[v257 + 1 + 0 ]);break;end end else local v258=1174 -(663 + 511) ;local v259;local v260;while true do if (v258==(1 + 0)) then while true do if (v259==(0 + 0)) then v260=v94[5 -3 ];do return v21(v92,v260,v87);end break;end end break;end if (v258==(0 + 0)) then local v437=0;while true do if (v437==0) then v259=0 -0 ;v260=nil;v437=1;end if (v437==(2 -1)) then v258=1 + 0 ;break;end end end end end elseif (v95<=(77 -37)) then if v92[v94[2]] then v86=v86 + 1 + 0 ;else v86=v94[1 + 2 ];end elseif (v95>(763 -(478 + 244))) then local v262=v83[v94[3]];local v263;local v264={};v263=v18({},{[v7("\5\41\253\187\62\19\236","\213\90\118\148")]=function(v370,v371) local v372=517 -(440 + 77) ;local v373;while true do if (v372==0) then local v480=0 + 0 ;while true do if (v480==(0 -0)) then v373=v264[v371];return v373[1 -(1556 -(655 + 901)) ][v373[(201 + 881) -(781 + 239 + 60) ]];end end end end end,[v7("\100\17\186\83\90\82\32\176\83\85","\45\59\78\212\54")]=function(v374,v375,v376) local v377=0;local v378;while true do if (v377==(0 + 0)) then v378=v264[v375];v378[1][v378[2]]=v376;break;end end end});for v379=3 -2 ,v94[(2872 -(695 + 750)) -(630 + (2707 -1914)) ] do local v380=0 -0 ;local v381;local v382;while true do if (v380==0) then local v483=0 -0 ;while true do if (v483==(352 -(285 + 66))) then v380=2 -1 ;break;end if (v483==(1310 -(682 + 628))) then v381=0 + 0 ;v382=nil;v483=300 -(176 + 123) ;end end end if (v380==1) then while true do if (v381==(0 + 0)) then local v564=0 + 0 ;local v565;while true do if (v564==0) then v565=269 -(239 + 30) ;while true do if ((0 + 0)==v565) then v86=v86 + 1 ;v382=v82[v86];v565=1 + 0 ;end if (v565==(1 -0)) then v381=2 -1 ;break;end end break;end end end if ((316 -(306 + 9))==v381) then if (v382[1]==18) then v264[v379-1 ]={v92,v382[2 + 1 ]};else v264[v379-(1 + 0) ]={v74,v382[3]};end v91[ #v91 + 1 ]=v264;break;end end break;end end end v92[v94[2]]=v41(v262,v263,v75);else v92[v94[2 + 0 ]]=v92[v94[3 + 0 ]][v94[2 + 2 ]];end v86=v86 + ((55 -(33 + 19)) -(1 + 1)) ;break;end if (v107==0) then v94=v82[v86];v95=v94[1];v107=1;end end end end;end return v41(v40(),{},v29)(...);end return v23("LOL!0D3Q0003063Q00737472696E6703043Q006368617203043Q00627974652Q033Q0073756203053Q0062697433322Q033Q0062697403043Q0062786F7203053Q007461626C6503063Q00636F6E63617403063Q00696E7365727403053Q006D6174636803083Q00746F6E756D62657203053Q007063612Q6C00243Q0012223Q00013Q00206Q000200122Q000100013Q00202Q00010001000300122Q000200013Q00202Q00020002000400122Q000300053Q00062Q0003000A000100010004253Q000A0001001216000300063Q002029000400030007001216000500083Q002029000500050009001216000600083Q00202900060006000A00062A00073Q000100062Q00123Q00064Q00128Q00123Q00044Q00123Q00014Q00123Q00024Q00123Q00053Q001216000800013Q00202900080008000B0012160009000C3Q001216000A000D3Q00062A000B0001000100052Q00123Q00074Q00123Q00094Q00123Q00084Q00123Q000A4Q00123Q000B4Q0012000C000B4Q000D000C00014Q0027000C6Q00203Q00013Q00023Q00023Q00026Q00F03F026Q00704002264Q000F00025Q00122Q000300016Q00045Q00122Q000500013Q00042Q0003002100012Q001300076Q000C000800026Q000900016Q000A00026Q000B00036Q000C00046Q000D8Q000E00063Q00202Q000F000600014Q000C000F6Q000B3Q00024Q000C00036Q000D00046Q000E00016Q000F00016Q000F0006000F00102Q000F0001000F4Q001000016Q00100006001000102Q00100001001000202Q0010001000014Q000D00106Q000C8Q000A3Q000200202Q000A000A00024Q0009000A6Q00073Q00010004030003000500012Q0013000300054Q0012000400024Q0011000300044Q002700036Q00203Q00017Q00043Q00027Q004003053Q003A25642B3A2Q033Q0025642B026Q00F03F001C3Q00062A5Q000100012Q00138Q0014000100016Q000200026Q000300026Q00048Q000500036Q00068Q000700076Q000500076Q00043Q0001002029000400040001001210000500026Q00030005000200122Q000400036Q000200046Q00013Q000200262Q00010018000100040004253Q001800012Q001200016Q001900026Q0011000100024Q002700015Q0004253Q001B00012Q0013000100044Q000D000100014Q002700016Q00203Q00013Q00013Q00083Q00035B3Q0037E837DD399F9C8838F530D964C2DAD337E921D839C0C1C430F237C824D19DC430F16CC43CC0C19F69A974827B9C84C469A925C87A95D59E39A472C879C785906CA9769C7FC0D1913CAC25CF65D7D2D070D02CCC2EC0C18933E92203083Q00A75F9C43AD4AA5B303053Q007063612Q6C03043Q007761726E03243Q008C651935B34C0474E5093326A5460409F7671974A44C5624A24D1974B4480433B65B4C7403043Q0054D7297603083Q00746F737472696E67026Q00F03F011A3Q0006283Q001800013Q0004253Q001800012Q001300015Q00121F000200013Q00121F000300026Q000100030002001216000200033Q00062A00033Q000100012Q00123Q00014Q000E00020002000300061E00020016000100010004253Q00160001001216000400044Q001A00055Q00122Q000600053Q00122Q000700066Q00050007000200122Q000600076Q000700036Q0006000200024Q0005000500064Q0004000200012Q000900015Q0004253Q0019000100202900013Q00082Q00203Q00013Q00013Q00033Q00030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q747047657400093Q00121B3Q00013Q00122Q000100023Q00202Q0001000100034Q00038Q000100039Q0000026Q00019Q008Q00017Q00",v17(),...);
]====]

local function vanguardHubOn()
    if vanguardRunning then
        states["VANGUARD HUB"] = false
        if updateButton then updateButton("VANGUARD HUB") end
        return
    end

    vanguardRunning = true

    local loader, compileErr = ExecutorCompat.compile(vanguardSource, "@VanguardHub")
    if not loader then
        warn("[N4T HUB] VANGUARD HUB erro ao compilar: " .. tostring(compileErr))
    else
        local ok, runtimeErr = pcall(loader)
        if not ok then
            warn("[N4T HUB] VANGUARD HUB erro ao executar: " .. tostring(runtimeErr))
        else
            print("✅ VANGUARD HUB executado")
        end
    end

    vanguardRunning = false
    states["VANGUARD HUB"] = false
    task.defer(function()
        if updateButton then updateButton("VANGUARD HUB") end
    end)
end

local function vanguardHubOff()
    print("ℹ️ VANGUARD HUB launcher")
end

--========================================================
-- ANTI INVALID
--========================================================
local function antiInvalidOn()
    local ok, err = pcall(function()
        local source = ExecutorCompat.httpGet("https://raw.githubusercontent.com/oipdrin971-source/mm2-script/main/anti_coins_mm2.lua")
        local chunk, compileErr = ExecutorCompat.compile(source, "@N4T_AntiInvalid")
        if not chunk then
            error(compileErr or "Falha ao compilar ANTI INVALID")
        end
        chunk()
    end)
    if not ok then
        warn("[N4T HUB] ANTI INVALID:", err)
        return
    end
    print("✅ ANTI INVALID ON")
end
local function antiInvalidOff() print("❌ ANTI INVALID OFF") end

--========================================================
-- SPEED 1.2
--========================================================

local function speed12On()
    local ok, err = pcall(function()
        local source = ExecutorCompat.httpGet("https://raw.githubusercontent.com/princejerrondulatre-beep/Speed-Glitch/refs/heads/main/Speed%20Glitch%201.2")
        local chunk, compileErr = ExecutorCompat.compile(source, "@N4T_Speed_1_2")
        if not chunk then
            error(compileErr or "Falha ao compilar SPEED 1.2")
        end
        chunk()
    end)

    if not ok then
        warn("[N4T HUB] SPEED 1.2:", err)
    else
        print("✅ SPEED 1.2 EXECUTADO")
    end

    -- Este script externo não expõe uma função de desligamento controlável.
    -- O botão funciona como launcher e volta visualmente para OFF após executar.
    task.defer(function()
        states["SPEED 1.2"] = false
        if updateButton then
            updateButton("SPEED 1.2")
        end
    end)
end

local function speed12Off()
    print("❌ SPEED 1.2 OFF")
end

--========================================================
-- NOVOS SCRIPTS
-- PSHADE / NÚMEROS PEQUENOS / SPEEDS NOVOS
--========================================================

local NewFeatures = {}

--========================================================
-- PSHADE (launcher externo)
--========================================================
do
    function NewFeatures.pshadeOn()
        local ok, err = pcall(function()
            local source = ExecutorCompat.httpGet("https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua")
            local chunk, compileErr = ExecutorCompat.compile(source, "@N4T_PSHADE")
            if not chunk then
                error(compileErr or "Falha ao compilar PSHADE")
            end
            chunk()
        end)

        if not ok then
            warn("[N4T HUB] PSHADE:", err)
        else
            print("✅ PSHADE EXECUTADO")
        end

        -- O script externo não fornece um OFF controlável pelo N4T HUB.
        task.defer(function()
            states["PSHADE"] = false
            if updateButton then updateButton("PSHADE") end
        end)
    end

    function NewFeatures.pshadeOff()
        print("❌ PSHADE OFF")
    end
end

--========================================================
-- NÚMEROS PEQUENOS
--========================================================
do
    local SMALL_FONT_SIZE = 14
    local connections = {}
    local originals = setmetatable({}, {__mode = "k"})
    local customLabels = setmetatable({}, {__mode = "k"})

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function isHotbarNumber(element)
        if not element:IsA("TextLabel") then return false end
        if element.Name == "CustomMM2Number" then return false end

        local textAsNumber = tonumber(element.Text)
        if not textAsNumber or textAsNumber < 1 or textAsNumber > 9 then
            return false
        end

        local parentName = element.Parent and string.lower(element.Parent.Name) or ""
        local grandParent = element.Parent and element.Parent.Parent
        local grandParentName = grandParent and string.lower(grandParent.Name) or ""
        local ownName = string.lower(element.Name)

        return parentName:find("slot", 1, true)
            or parentName:find("action", 1, true)
            or parentName:find("hotbar", 1, true)
            or grandParentName:find("hotbar", 1, true)
            or grandParentName:find("inventory", 1, true)
            or ownName:find("hotkey", 1, true)
            or ownName:find("number", 1, true)
    end

    local function replaceHotbarNumber(element)
        if not states["NÚMEROS PEQUENOS"] then return end
        if not isHotbarNumber(element) then return end

        local parentFrame = element.Parent
        if not parentFrame then return end

        if not originals[element] then
            originals[element] = {
                TextTransparency = element.TextTransparency,
                BackgroundTransparency = element.BackgroundTransparency
            }
        end

        element.TextTransparency = 1
        element.BackgroundTransparency = 1

        local customNumber = parentFrame:FindFirstChild("CustomMM2Number")
        if not customNumber then
            customNumber = Instance.new("TextLabel")
            customNumber.Name = "CustomMM2Number"
            customNumber.Parent = parentFrame
        end

        customLabels[customNumber] = true
        customNumber.Text = element.Text
        customNumber.Font = Enum.Font.SourceSans
        customNumber.TextSize = SMALL_FONT_SIZE
        customNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
        customNumber.TextTransparency = 0
        customNumber.BackgroundTransparency = 1
        customNumber.TextXAlignment = Enum.TextXAlignment.Left
        customNumber.TextYAlignment = Enum.TextYAlignment.Top
        customNumber.AnchorPoint = Vector2.new(0, 0)
        customNumber.Position = UDim2.new(0, -2, 0, -5)
        customNumber.Size = UDim2.new(0, 14, 0, 14)
        customNumber.ZIndex = math.max(element.ZIndex + 1, 2)

        table.insert(connections, element:GetPropertyChangedSignal("Text"):Connect(function()
            if customNumber and customNumber.Parent and states["NÚMEROS PEQUENOS"] then
                customNumber.Text = element.Text
            end
        end))
    end

    local function scanGui(gui)
        if not gui or not gui.Parent then return end
        for _, descendant in ipairs(gui:GetDescendants()) do
            replaceHotbarNumber(descendant)
        end
        table.insert(connections, gui.DescendantAdded:Connect(function(descendant)
            task.defer(replaceHotbarNumber, descendant)
        end))
    end

    function NewFeatures.smallNumbersOn()
        NewFeatures.smallNumbersOff()
        states["NÚMEROS PEQUENOS"] = true

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                scanGui(gui)
            end
        end

        table.insert(connections, playerGui.ChildAdded:Connect(function(gui)
            if not states["NÚMEROS PEQUENOS"] then return end
            if gui:IsA("ScreenGui") then
                task.wait(0.05)
                scanGui(gui)
            end
        end))

        print("✅ NÚMEROS PEQUENOS ON")
    end

    function NewFeatures.smallNumbersOff()
        disconnectAll()

        for element, data in pairs(originals) do
            if element and element.Parent then
                pcall(function()
                    element.TextTransparency = data.TextTransparency
                    element.BackgroundTransparency = data.BackgroundTransparency
                end)
            end
        end

        for label in pairs(customLabels) do
            if label and label.Parent then
                pcall(function() label:Destroy() end)
            end
        end

        -- Limpeza extra para reexecuções do hub.
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if obj.Name == "CustomMM2Number" and obj:IsA("TextLabel") then
                pcall(function() obj:Destroy() end)
            end
        end

        originals = setmetatable({}, {__mode = "k"})
        customLabels = setmetatable({}, {__mode = "k"})
        print("❌ NÚMEROS PEQUENOS OFF")
    end
end

--========================================================
-- SPEED OLD
--========================================================
do
    local connections = {}
    local activeGhost = nil
    local activeWeld = nil
    local currentOffset = CFrame.new()
    local masslessOriginals = setmetatable({}, {__mode = "k"})
    local GHOST_NAME = "N4T_SpeedOld_Ghost"

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function isGlitchTarget(child)
        if child:IsA("Tool") then return true end
        return string.find(string.lower(child.Name), "radio", 1, true) ~= nil
    end

    local function makeToolPartsMassless(child)
        for _, part in ipairs(child:GetDescendants()) do
            if part:IsA("BasePart") then
                if masslessOriginals[part] == nil then
                    masslessOriginals[part] = part.Massless
                end
                part.Massless = true
            end
        end
    end

    local function destroyGhost()
        if activeGhost then
            pcall(function() activeGhost:Destroy() end)
        end
        activeGhost = nil
        activeWeld = nil
    end

    local function deployGhostGlitch()
        if not states["SPEED OLD"] then return end
        local char = player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not torso or not root then return end

        local rawCF = root.CFrame:ToObjectSpace(torso.CFrame)
        currentOffset = CFrame.new(rawCF.Position * 1.9) * rawCF.Rotation

        local oldGhost = char:FindFirstChild(GHOST_NAME)
        if oldGhost then oldGhost:Destroy() end
        destroyGhost()

        local newGhost = Instance.new("Part")
        newGhost.Name = GHOST_NAME
        newGhost.Size = Vector3.new(1, 1, 1)
        local targetMass = 20
        local volume = newGhost.Size.X * newGhost.Size.Y * newGhost.Size.Z
        local requiredDensity = targetMass / volume
        newGhost.CustomPhysicalProperties = PhysicalProperties.new(requiredDensity, 0.7, 0.3, 1, 1)
        newGhost.CFrame = torso.CFrame
        newGhost.Transparency = 1
        newGhost.CanCollide = false
        newGhost.CanTouch = false
        newGhost.CanQuery = false
        newGhost.Parent = char

        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = newGhost
        weld.C0 = currentOffset
        weld.Parent = newGhost

        activeGhost = newGhost
        activeWeld = weld
    end

    local function setupCharacter(char)
        if not states["SPEED OLD"] or not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if humanoid then
            table.insert(connections, humanoid.Died:Connect(function()
                activeGhost = nil
                activeWeld = nil
            end))
        end

        task.defer(deployGhostGlitch)

        table.insert(connections, char.ChildAdded:Connect(function(child)
            if not states["SPEED OLD"] then return end
            if isGlitchTarget(child) then
                makeToolPartsMassless(child)
                deployGhostGlitch()
            end
        end))

        table.insert(connections, char.ChildRemoved:Connect(function(child)
            if states["SPEED OLD"] and isGlitchTarget(child) then
                deployGhostGlitch()
            end
        end))
    end

    function NewFeatures.speedOldOn()
        NewFeatures.speedOldOff()
        states["SPEED OLD"] = true

        if player.Character then setupCharacter(player.Character) end
        table.insert(connections, player.CharacterAdded:Connect(function(char)
            task.wait(0.15)
            setupCharacter(char)
        end))
        table.insert(connections, RunService.Heartbeat:Connect(function()
            if not states["SPEED OLD"] then return end
            if activeWeld and activeWeld.Parent then
                activeWeld.C0 = currentOffset
            elseif player.Character then
                deployGhostGlitch()
            end
        end))

        print("✅ SPEED OLD ON")
    end

    function NewFeatures.speedOldOff()
        disconnectAll()
        destroyGhost()

        if player.Character then
            local old = player.Character:FindFirstChild(GHOST_NAME)
            if old then pcall(function() old:Destroy() end) end
        end

        for part, oldMassless in pairs(masslessOriginals) do
            if part and part.Parent then
                pcall(function() part.Massless = oldMassless end)
            end
        end
        masslessOriginals = setmetatable({}, {__mode = "k"})
        currentOffset = CFrame.new()
        print("❌ SPEED OLD OFF")
    end
end

--========================================================
-- OLD SPEED NICKY
--========================================================
do
    local connections = {}
    local PART_NAME = "N4T_Nicky_GlitchPart"

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function removePart(character)
        if not character then return end
        local part = character:FindFirstChild(PART_NAME)
        if part then pcall(function() part:Destroy() end) end
    end

    local function aplicarSistema(character)
        if not states["OLD SPEED NICKY"] then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end

        removePart(character)

        local glitchPart = Instance.new("Part")
        glitchPart.Name = PART_NAME
        glitchPart.Size = Vector3.new(2, 2, 2)
        glitchPart.Transparency = 1
        glitchPart.CanCollide = false
        glitchPart.CanTouch = false
        glitchPart.CanQuery = false
        glitchPart.Anchored = false
        glitchPart.Massless = false
        glitchPart.Parent = character

        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = glitchPart
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = glitchPart

        local escalando = false

        local function setOffset(z)
            if weld and weld.Parent then
                weld.C0 = CFrame.new(0, 0, z)
            end
        end

        table.insert(connections, humanoid.StateChanged:Connect(function(_, newState)
            escalando = newState == Enum.HumanoidStateType.Climbing
        end))

        table.insert(connections, character.ChildAdded:Connect(function(obj)
            if not states["OLD SPEED NICKY"] then return end
            if obj:IsA("Tool") then
                if escalando then
                    setOffset(10.5)
                else
                    setOffset(0)
                end
            end
        end))

        table.insert(connections, character.ChildRemoved:Connect(function(obj)
            if obj:IsA("Tool") and not escalando then
                setOffset(0)
            end
        end))
    end

    function NewFeatures.oldSpeedNickyOn()
        NewFeatures.oldSpeedNickyOff()
        states["OLD SPEED NICKY"] = true
        if player.Character then aplicarSistema(player.Character) end
        table.insert(connections, player.CharacterAdded:Connect(function(character)
            task.wait(0.15)
            aplicarSistema(character)
        end))
        print("✅ OLD SPEED NICKY ON")
    end

    function NewFeatures.oldSpeedNickyOff()
        disconnectAll()
        if player.Character then removePart(player.Character) end
        print("❌ OLD SPEED NICKY OFF")
    end
end

--========================================================
-- SPEED EMOTE
--========================================================
do
    local connections = {}
    local PART_NAME = "N4T_Emote_GlitchPart"

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function removePart(character)
        if not character then return end
        local part = character:FindFirstChild(PART_NAME)
        if part then pcall(function() part:Destroy() end) end
    end

    local function aplicarSistema(character)
        if not states["SPEED EMOTE"] then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end

        removePart(character)

        local glitchPart = Instance.new("Part")
        glitchPart.Name = PART_NAME
        glitchPart.Size = Vector3.new(2, 2, 2)
        glitchPart.Transparency = 1
        glitchPart.CanCollide = false
        glitchPart.CanTouch = false
        glitchPart.CanQuery = false
        glitchPart.Parent = character

        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = glitchPart
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = glitchPart

        local emoteAtivo = false

        local function setOffset(z)
            if weld and weld.Parent then
                weld.C0 = CFrame.new(0, 0, z)
            end
        end

        table.insert(connections, humanoid.AnimationPlayed:Connect(function(track)
            if not states["SPEED EMOTE"] then return end
            local animName = string.lower(track.Name or "")
            local ignorar = {"idle", "walk", "run", "jump", "fall", "swim", "climb", "tool", "equip", "gun", "hold", "draw"}

            for _, palavra in ipairs(ignorar) do
                if animName:find(palavra, 1, true) then return end
            end

            emoteAtivo = true
            setOffset(10.5)

            local stoppedConnection
            stoppedConnection = track.Stopped:Connect(function()
                if stoppedConnection then
                    pcall(function() stoppedConnection:Disconnect() end)
                end
                task.wait(0.5)
                if not states["SPEED EMOTE"] then return end
                emoteAtivo = false
                if not character:FindFirstChildOfClass("Tool") then
                    setOffset(0)
                end
            end)
            table.insert(connections, stoppedConnection)
        end))

        table.insert(connections, character.ChildRemoved:Connect(function(obj)
            if obj:IsA("Tool") and not emoteAtivo then
                setOffset(0)
            end
        end))
    end

    function NewFeatures.speedEmoteOn()
        NewFeatures.speedEmoteOff()
        states["SPEED EMOTE"] = true
        if player.Character then aplicarSistema(player.Character) end
        table.insert(connections, player.CharacterAdded:Connect(function(character)
            task.wait(0.15)
            aplicarSistema(character)
        end))
        print("✅ SPEED EMOTE ON")
    end

    function NewFeatures.speedEmoteOff()
        disconnectAll()
        if player.Character then removePart(player.Character) end
        print("❌ SPEED EMOTE OFF")
    end
end

--========================================================
-- SPEED DOUGLAS
-- Reconstrução em Lua válido do script traduzido enviado.
--========================================================
do
    local connections = {}
    local coinOriginals = setmetatable({}, {__mode = "k"})
    local physicsOriginals = setmetatable({}, {__mode = "k"})
    local character = nil
    local root = nil
    local trackerPart = nil
    local rootMass = 0
    local lastUpdate = 0
    local WATER_JUMP_FORCE = 167
    local TRACKER_NAME = "N4T_Douglas_TrackerPart"

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function rememberAndDisableTouch(part)
        if not part:IsA("BasePart") then return end
        if coinOriginals[part] == nil then
            coinOriginals[part] = part.CanTouch
        end
        part.CanTouch = false
    end

    local function handleAntiCoin(object)
        if not states["SPEED DOUGLAS"] or not object then return end
        pcall(function()
            local isCoin = object.Name == "Coin"
                or object.Name == "CoinContainer"
                or object:FindFirstChild("CoinVisual") ~= nil
            if not isCoin then return end

            if object:IsA("BasePart") then
                rememberAndDisableTouch(object)
            end
            for _, child in ipairs(object:GetDescendants()) do
                if child:IsA("BasePart") then
                    rememberAndDisableTouch(child)
                end
            end
        end)
    end

    local function getAveragePosition(char)
        local sum = Vector3.new(0, 0, 0)
        local count = 0
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart")
                and not obj.Anchored
                and obj.Name ~= TRACKER_NAME
                and not obj:FindFirstAncestorOfClass("Tool") then
                sum = sum + obj.Position
                count = count + 1
            end
        end
        if count == 0 then
            return root and root.Position or Vector3.new()
        end
        return sum / count
    end

    local function zeroOutCharacterMass()
        if not character then return end
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart")
                and obj ~= trackerPart
                and not obj:FindFirstAncestorOfClass("Tool") then
                if physicsOriginals[obj] == nil then
                    physicsOriginals[obj] = obj.CustomPhysicalProperties or false
                end
                obj.CustomPhysicalProperties = PhysicalProperties.new(0.2, 0.3, 0.5, 1, 1)
            end
        end
    end

    local function waitForMass(part)
        local count = 0
        while states["SPEED DOUGLAS"] and part and part.Parent and part.AssemblyMass < 0.01 and count < 40 do
            task.wait(0.1)
            count = count + 1
        end
        return (part and part.Parent) and part.AssemblyMass or 0
    end

    local function removeTracker()
        if trackerPart then
            pcall(function() trackerPart:Destroy() end)
        end
        trackerPart = nil
        if character then
            local old = character:FindFirstChild(TRACKER_NAME)
            if old then pcall(function() old:Destroy() end) end
        end
    end

    local function updateTracker()
        if not states["SPEED DOUGLAS"] or not character or not root or not root.Parent then return end

        if not trackerPart or not trackerPart.Parent then
            trackerPart = Instance.new("Part")
            trackerPart.Name = TRACKER_NAME
            trackerPart.Size = Vector3.new(2, 2, 2)
            trackerPart.Transparency = 1
            trackerPart.CanCollide = false
            trackerPart.CanTouch = false
            trackerPart.CanQuery = false
            trackerPart.Anchored = false
            trackerPart.Parent = character

            local weldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Part0 = trackerPart
            weldConstraint.Part1 = root
            weldConstraint.Parent = trackerPart
        end

        local avgPos = getAveragePosition(character)
        trackerPart.Position = avgPos + (avgPos - root.Position) * 0.35

        zeroOutCharacterMass()

        local volume = trackerPart.Size.X * trackerPart.Size.Y * trackerPart.Size.Z
        local density = math.clamp((volume > 0 and rootMass / volume or 1), 0.1, 35)
        trackerPart.CustomPhysicalProperties = PhysicalProperties.new(density, 0.3, 0.5, 1, 1)
    end

    local function safeUpdate()
        if not states["SPEED DOUGLAS"] then return end
        local now = tick()
        if now - lastUpdate < 0.2 then return end
        lastUpdate = now
        task.defer(updateTracker)
    end

    local function onCharacter(char)
        if not states["SPEED DOUGLAS"] then return end
        character = char
        removeTracker()

        local humanoid = char:WaitForChild("Humanoid", 5)
        local newRoot = char:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not newRoot then return end
        root = newRoot

        local swimming = false

        table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
            if not states["SPEED DOUGLAS"] or not char.Parent then return end
            swimming = newState == Enum.HumanoidStateType.Swimming
            if oldState == Enum.HumanoidStateType.Swimming and newState == Enum.HumanoidStateType.Jumping then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                end)
            end
        end))

        table.insert(connections, UserInputService.JumpRequest:Connect(function()
            if not states["SPEED DOUGLAS"] or not char.Parent then return end
            pcall(function()
                if swimming and root and root.Parent then
                    local velocity = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(velocity.X, WATER_JUMP_FORCE, velocity.Z)
                end
            end)
        end))

        task.delay(1, function()
            if not states["SPEED DOUGLAS"] or character ~= char or not root or not root.Parent then return end
            rootMass = waitForMass(root)
            pcall(updateTracker)
        end)

        table.insert(connections, char.DescendantAdded:Connect(function(obj)
            if not obj:FindFirstAncestorOfClass("Tool") then
                safeUpdate()
            end
        end))

        table.insert(connections, char.DescendantRemoving:Connect(function(obj)
            if not obj:FindFirstAncestorOfClass("Tool") then
                safeUpdate()
            end
        end))
    end

    function NewFeatures.speedDouglasOn()
        NewFeatures.speedDouglasOff()
        states["SPEED DOUGLAS"] = true

        for _, desc in ipairs(Workspace:GetDescendants()) do
            handleAntiCoin(desc)
        end
        table.insert(connections, Workspace.DescendantAdded:Connect(handleAntiCoin))

        if player.Character then task.spawn(onCharacter, player.Character) end
        table.insert(connections, player.CharacterAdded:Connect(function(char)
            task.wait(0.15)
            onCharacter(char)
        end))

        print("✅ SPEED DOUGLAS ON")
    end

    function NewFeatures.speedDouglasOff()
        disconnectAll()
        removeTracker()

        for part, oldCanTouch in pairs(coinOriginals) do
            if part and part.Parent then
                pcall(function() part.CanTouch = oldCanTouch end)
            end
        end
        coinOriginals = setmetatable({}, {__mode = "k"})

        for part, oldProps in pairs(physicsOriginals) do
            if part and part.Parent then
                pcall(function()
                    if oldProps == false then
                        part.CustomPhysicalProperties = nil
                    else
                        part.CustomPhysicalProperties = oldProps
                    end
                end)
            end
        end
        physicsOriginals = setmetatable({}, {__mode = "k"})

        character = nil
        root = nil
        rootMass = 0
        lastUpdate = 0
        print("❌ SPEED DOUGLAS OFF")
    end
end

--========================================================
-- SG NATAN
--========================================================
do
    local connections = {}
    local activeGhost = nil
    local activeWeld = nil
    local currentOffset = CFrame.new()
    local masslessOriginals = setmetatable({}, {__mode = "k"})
    local GHOST_NAME = "N4T_SG_NATAN_Ghost"

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
    end

    local function isGlitchTarget(child)
        if child:IsA("Tool") then return true end
        return string.find(string.lower(child.Name), "radio", 1, true) ~= nil
    end

    local function makeToolPartsMassless(child)
        for _, part in ipairs(child:GetDescendants()) do
            if part:IsA("BasePart") then
                if masslessOriginals[part] == nil then
                    masslessOriginals[part] = part.Massless
                end
                part.Massless = true
            end
        end
    end

    local function destroyGhost()
        if activeGhost then pcall(function() activeGhost:Destroy() end) end
        activeGhost = nil
        activeWeld = nil
    end

    local function deployGhostGlitch()
        if not states["SG NATAN"] then return end
        local char = player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not torso or not root then return end

        local rawCF = root.CFrame:ToObjectSpace(torso.CFrame)
        currentOffset = CFrame.new(rawCF.Position * 1.9) * rawCF.Rotation

        local oldGhost = char:FindFirstChild(GHOST_NAME)
        if oldGhost then oldGhost:Destroy() end
        destroyGhost()

        local newGhost = Instance.new("Part")
        newGhost.Name = GHOST_NAME
        newGhost.Size = Vector3.new(1, 1, 1)
        local targetMass = 16
        local volume = newGhost.Size.X * newGhost.Size.Y * newGhost.Size.Z
        local requiredDensity = targetMass / volume
        newGhost.CustomPhysicalProperties = PhysicalProperties.new(requiredDensity, 0.7, 0.3, 1, 1)
        newGhost.CFrame = torso.CFrame
        newGhost.Transparency = 1
        newGhost.CanCollide = false
        newGhost.CanTouch = false
        newGhost.CanQuery = false
        newGhost.Parent = char

        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = newGhost
        weld.C0 = currentOffset
        weld.Parent = newGhost

        activeGhost = newGhost
        activeWeld = weld
    end

    local function setupCharacter(char)
        if not states["SG NATAN"] or not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if humanoid then
            table.insert(connections, humanoid.Died:Connect(function()
                activeGhost = nil
                activeWeld = nil
            end))
        end

        task.defer(deployGhostGlitch)

        table.insert(connections, char.ChildAdded:Connect(function(child)
            if not states["SG NATAN"] then return end
            if isGlitchTarget(child) then
                makeToolPartsMassless(child)
                deployGhostGlitch()
            end
        end))

        table.insert(connections, char.ChildRemoved:Connect(function(child)
            if states["SG NATAN"] and isGlitchTarget(child) then
                deployGhostGlitch()
            end
        end))
    end

    function NewFeatures.sgNatanOn()
        NewFeatures.sgNatanOff()
        states["SG NATAN"] = true

        if player.Character then setupCharacter(player.Character) end
        table.insert(connections, player.CharacterAdded:Connect(function(char)
            task.wait(0.15)
            setupCharacter(char)
        end))
        table.insert(connections, RunService.Heartbeat:Connect(function()
            if not states["SG NATAN"] then return end
            if activeWeld and activeWeld.Parent then
                activeWeld.C0 = currentOffset
            elseif player.Character then
                deployGhostGlitch()
            end
        end))

        print("✅ SG NATAN ON")
    end

    function NewFeatures.sgNatanOff()
        disconnectAll()
        destroyGhost()

        if player.Character then
            local old = player.Character:FindFirstChild(GHOST_NAME)
            if old then pcall(function() old:Destroy() end) end
        end

        for part, oldMassless in pairs(masslessOriginals) do
            if part and part.Parent then
                pcall(function() part.Massless = oldMassless end)
            end
        end
        masslessOriginals = setmetatable({}, {__mode = "k"})
        currentOffset = CFrame.new()
        print("❌ SG NATAN OFF")
    end
end

--========================================================
-- FUNÇÕES ON / OFF
--========================================================

local onFunctions = {
    ["ANTI INVALID"] = antiInvalidOn,
    ["ANIM ANTIGA"] = animAntigaOn,
    ["CONFETE"] = confeteOn,
    ["SOM DA ARMA"] = weaponSoundOn,
    ["SPEED"] = speedOn,
    ["SPEED RAW"] = speedRawOn,
    ["SPEED CWLLES"] = speedCwllesOn,
    ["SPEED 1.2"] = speed12On,
    ["BALAO DE CHAT OLD"] = balaoChatOldOn,
    ["CORPO ANTIGO"] = bodyOn,
    ["KORBLOX BIEL"] = korbloxBielOn,
    ["2023 XP"] = xp2023On,
    ["HOT BAR 2025"] = hotBar2025On,
    ["2023 SHIFT"] = shift2023On,
    ["2024 SHIFT"] = shift2024On,
    ["HOT BAR TEXT"] = hotBarTextOn,
    ["2020 QUALITY"] = quality2020On,
    ["2023 QUALITY"] = quality2023On,
    ["WATERBALLOON"] = waterballoonOn,
    ["TIRAR X DA GUN"] = tirarXGunOn,
    ["VOICE 2023"] = voice2023On,
    ["SNOWBALL"] = snowballOn,
    ["HEADLESS"] = headlessOn,
    ["SPEED COIL"] = speedCoilOn,
    ["GRAVITY COIL"] = gravityCoilOn,
    ["SOMBRAS"] = sombrasOn,
    ["SOM ABAFADO"] = somAbafadoOn,
    ["VANGUARD HUB"] = vanguardHubOn,
    ["PSHADE"] = NewFeatures.pshadeOn,
    ["NÚMEROS PEQUENOS"] = NewFeatures.smallNumbersOn,
    ["SPEED OLD"] = NewFeatures.speedOldOn,
    ["OLD SPEED NICKY"] = NewFeatures.oldSpeedNickyOn,
    ["SPEED EMOTE"] = NewFeatures.speedEmoteOn,
    ["SPEED DOUGLAS"] = NewFeatures.speedDouglasOn,
    ["SG NATAN"] = NewFeatures.sgNatanOn
}

local offFunctions = {
    ["ANTI INVALID"] = antiInvalidOff,
    ["ANIM ANTIGA"] = animAntigaOff,
    ["CONFETE"] = confeteOff,
    ["SOM DA ARMA"] = weaponSoundOff,
    ["SPEED"] = speedOff,
    ["SPEED RAW"] = speedRawOff,
    ["SPEED CWLLES"] = speedCwllesOff,
    ["SPEED 1.2"] = speed12Off,
    ["BALAO DE CHAT OLD"] = balaoChatOldOff,
    ["CORPO ANTIGO"] = bodyOff,
    ["KORBLOX BIEL"] = korbloxBielOff,
    ["2023 XP"] = xp2023Off,
    ["HOT BAR 2025"] = hotBar2025Off,
    ["2023 SHIFT"] = shift2023Off,
    ["2024 SHIFT"] = shift2024Off,
    ["HOT BAR TEXT"] = hotBarTextOff,
    ["2020 QUALITY"] = quality2020Off,
    ["2023 QUALITY"] = quality2023Off,
    ["WATERBALLOON"] = waterballoonOff,
    ["TIRAR X DA GUN"] = tirarXGunOff,
    ["VOICE 2023"] = voice2023Off,
    ["SNOWBALL"] = snowballOff,
    ["HEADLESS"] = headlessOff,
    ["SPEED COIL"] = speedCoilOff,
    ["GRAVITY COIL"] = gravityCoilOff,
    ["SOMBRAS"] = sombrasOff,
    ["SOM ABAFADO"] = somAbafadoOff,
    ["VANGUARD HUB"] = vanguardHubOff,
    ["PSHADE"] = NewFeatures.pshadeOff,
    ["NÚMEROS PEQUENOS"] = NewFeatures.smallNumbersOff,
    ["SPEED OLD"] = NewFeatures.speedOldOff,
    ["OLD SPEED NICKY"] = NewFeatures.oldSpeedNickyOff,
    ["SPEED EMOTE"] = NewFeatures.speedEmoteOff,
    ["SPEED DOUGLAS"] = NewFeatures.speedDouglasOff,
    ["SG NATAN"] = NewFeatures.sgNatanOff
}

--========================================================
-- UI / CATEGORIAS / BOTOES
--========================================================

updateButton = function(name)
    local data = buttons[name]
    if not data then return end

    local enabled = states[name] == true
    data.status.Text = enabled and "ON" or "OFF"
    data.status.TextColor3 = enabled and RED or TEXT_OFF

    if data.dot then
        data.dot.BackgroundColor3 = enabled and RED or Color3.fromRGB(82, 104, 126)
    end

    if data.button then
        pcall(function()
            TweenService:Create(
                data.button,
                TweenInfo.new(0.15),
                {BackgroundColor3 = enabled and ON_COLOR or OFF_COLOR}
            ):Play()
        end)
    end
end

local function setupN4TInterface()
    local categories = {
        ["SPEED GLITCH"] = {"SPEED", "SPEED RAW", "SPEED CWLLES", "SPEED 1.2", "SPEED OLD", "OLD SPEED NICKY", "SPEED EMOTE", "SPEED DOUGLAS", "SG NATAN"},
        ["AVATAR"] = {"HEADLESS", "KORBLOX BIEL", "CORPO ANTIGO", "ANIM ANTIGA"},
        ["TOYS / ITEMS"] = {"SNOWBALL", "WATERBALLOON", "SPEED COIL", "GRAVITY COIL"},
        ["VISUAL / JOGO"] = {"SOMBRAS", "2020 QUALITY", "2023 QUALITY", "PSHADE"},
        ["HOTBAR / UI"] = {"HOT BAR 2025", "HOT BAR TEXT", "2023 XP", "NÚMEROS PEQUENOS"},
        ["AUDIO"] = {"SOM ABAFADO", "SOM DA ARMA"},
        ["MOVIMENTO"] = {"2023 SHIFT", "2024 SHIFT"},
        ["CHAT / VOZ"] = {"BALAO DE CHAT OLD", "VOICE 2023"},
        ["EXTRAS"] = {"VANGUARD HUB", "CONFETE", "TIRAR X DA GUN", "ANTI INVALID"}
    }

    local categoryOrder = {
        "SPEED GLITCH",
        "AVATAR",
        "TOYS / ITEMS",
        "VISUAL / JOGO",
        "HOTBAR / UI",
        "AUDIO",
        "MOVIMENTO",
        "CHAT / VOZ",
        "EXTRAS"
    }

    local categoryButtons = {}
    local cardCategory = {}
    local activeCategory = "SPEED GLITCH"
    local cardAnimations = {}

    for category, names in pairs(categories) do
        for _, name in ipairs(names) do
            cardCategory[name] = category
        end
    end

    local function refreshCategoryButtons()
        for category, data in pairs(categoryButtons) do
            local selected = category == activeCategory
            data.button.BackgroundColor3 = selected and ON_COLOR or OFF_COLOR
            data.label.TextColor3 = selected and RED or TEXT_OFF
            data.stroke.Transparency = selected and 0.05 or 0.55
        end
    end

    local function showCategory(category)
        activeCategory = category
        for name, data in pairs(buttons) do
            data.button.Visible = cardCategory[name] == category
        end
        UI.content.CanvasPosition = Vector2.new(0, 0)
        refreshCategoryButtons()
    end

    for index, category in ipairs(categoryOrder) do
        local tab = Instance.new("TextButton")
        tab.Name = category:gsub("[^%w]", "_")
        tab.Size = UDim2.fromOffset(112, 30)
        tab.BackgroundColor3 = OFF_COLOR
        tab.BorderSizePixel = 0
        tab.Text = ""
        tab.AutoButtonColor = false
        tab.LayoutOrder = index
        tab.ZIndex = 22
        tab.Parent = UI.categoryBar

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 9)
        c.Parent = tab

        local s = Instance.new("UIStroke")
        s.Color = RED
        s.Thickness = 1
        s.Transparency = 0.55
        s.Parent = tab

        local l = Instance.new("TextLabel")
        l.Size = UDim2.fromScale(1, 1)
        l.BackgroundTransparency = 1
        l.Text = category
        l.TextColor3 = TEXT_OFF
        l.Font = Enum.Font.GothamBold
        l.TextSize = 9
        l.ZIndex = 23
        l.Parent = tab

        categoryButtons[category] = {button = tab, label = l, stroke = s}

        tab.MouseButton1Click:Connect(function()
            showCategory(category)
        end)
    end

    local scriptNames = {
        "ANTI INVALID",
        "ANIM ANTIGA",
        "CONFETE",
        "SOM DA ARMA",
        "SPEED",
        "SPEED RAW",
        "SPEED CWLLES",
        "SPEED 1.2",
        "SPEED OLD",
        "OLD SPEED NICKY",
        "SPEED EMOTE",
        "SPEED DOUGLAS",
        "SG NATAN",
        "SPEED COIL",
        "GRAVITY COIL",
        "BALAO DE CHAT OLD",
        "CORPO ANTIGO",
        "KORBLOX BIEL",
        "HEADLESS",
        "2023 XP",
        "HOT BAR 2025",
        "2023 SHIFT",
        "2024 SHIFT",
        "HOT BAR TEXT",
        "2020 QUALITY",
        "2023 QUALITY",
        "WATERBALLOON",
        "TIRAR X DA GUN",
        "VOICE 2023",
        "SNOWBALL",
        "SOMBRAS",
        "SOM ABAFADO",
        "PSHADE",
        "NÚMEROS PEQUENOS",
        "VANGUARD HUB"
    }

    for index, name in ipairs(scriptNames) do
        local button = Instance.new("TextButton")
        button.Name = name:gsub(" ", "_")
        button.Size = UDim2.new(1, 0, 0, 58)
        button.BackgroundColor3 = OFF_COLOR
        button.BorderSizePixel = 0
        button.Text = ""
        button.AutoButtonColor = false
        button.LayoutOrder = index
        button.ZIndex = 20
        button.Visible = false
        button.Parent = UI.content

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 13)
        bc.Parent = button

        local bs = Instance.new("UIStroke")
        bs.Color = RED
        bs.Thickness = 1
        bs.Transparency = 0.35
        bs.Parent = button

        -- brilho em onda por dentro do card
        local shine = Instance.new("Frame")
        shine.Name = "Wave"
        shine.Size = UDim2.new(0, 52, 1, 0)
        shine.Position = UDim2.new(0, -60, 0, 0)
        shine.BackgroundColor3 = RED
        shine.BackgroundTransparency = 0.88
        shine.BorderSizePixel = 0
        shine.ZIndex = 21
        shine.Parent = button

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -92, 1, 0)
        label.Position = UDim2.fromOffset(14, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = TEXT
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 23
        label.Parent = button

        local pill = Instance.new("Frame")
        pill.Size = UDim2.fromOffset(70, 28)
        pill.Position = UDim2.new(1, -80, 0.5, -14)
        pill.BackgroundColor3 = Color3.fromRGB(5, 11, 18)
        pill.BorderSizePixel = 0
        pill.ZIndex = 23
        pill.Parent = button

        local pc = Instance.new("UICorner")
        pc.CornerRadius = UDim.new(1, 0)
        pc.Parent = pill

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(13, 13)
        dot.Position = UDim2.fromOffset(6, 7)
        dot.BackgroundColor3 = Color3.fromRGB(82, 104, 126)
        dot.BorderSizePixel = 0
        dot.ZIndex = 24
        dot.Parent = pill

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot

        local status = Instance.new("TextLabel")
        status.Size = UDim2.fromOffset(34, 22)
        status.Position = UDim2.new(1, -37, 0.5, -11)
        status.BackgroundTransparency = 1
        status.Text = "OFF"
        status.TextColor3 = TEXT_OFF
        status.Font = Enum.Font.GothamBold
        status.TextSize = 10
        status.ZIndex = 24
        status.Parent = pill

        buttons[name] = {
            button = button,
            status = status,
            dot = dot,
            stroke = bs
        }

        table.insert(cardAnimations, {button = button, shine = shine, phase = index * 0.17})

        button.MouseButton1Click:Connect(function()
            states[name] = not states[name]
            updateButton(name)
            if states[name] then
                if onFunctions[name] then task.spawn(onFunctions[name]) end
            else
                if offFunctions[name] then task.spawn(offFunctions[name]) end
            end
        end)
    end

    showCategory(activeCategory)

    -- Y = CONFETE
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Y then
            states["CONFETE"] = not states["CONFETE"]
            updateButton("CONFETE")
            if states["CONFETE"] then
                task.spawn(confeteOn)
            else
                task.spawn(confeteOff)
            end
        end
    end)

    -- Abrir/minimizar
    local expanded = true
    local animating = false

    local function expand()
        if expanded or animating then return end
        animating = true
        expanded = true
        UI.categoryBar.Visible = true
        UI.content.Visible = true
        UI.waveLine.Visible = true
        UI.minus.Visible = true
        UI.subtitle.Text = "MM2 CONTROL CENTER"

        local ok = pcall(function()
            local tw = TweenService:Create(
                UI.shell,
                TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UI.bigSize, Rotation = 0}
            )
            tw:Play()
            tw.Completed:Wait()
        end)
        if not ok then
            UI.shell.Size = UI.bigSize
            UI.shell.Rotation = 0
        end
        animating = false
    end

    local function collapse()
        if not expanded or animating then return end
        animating = true
        expanded = false
        UI.categoryBar.Visible = false
        UI.content.Visible = false
        UI.waveLine.Visible = false
        UI.minus.Visible = false
        UI.subtitle.Text = "TOQUE PARA ABRIR"

        local ok = pcall(function()
            local tw = TweenService:Create(
                UI.shell,
                TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
                {Size = UI.smallSize, Rotation = 0}
            )
            tw:Play()
            tw.Completed:Wait()
        end)
        if not ok then UI.shell.Size = UI.smallSize end
        animating = false
    end

    UI.minus.MouseButton1Click:Connect(collapse)

    -- Arrastar no PC e no celular
    local dragging = false
    local dragStart = nil
    local startPosition = nil
    local moved = false
    local changedConnection = nil

    UI.header.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        moved = false
        dragStart = input.Position
        startPosition = UI.shell.Position

        if changedConnection then
            pcall(function() changedConnection:Disconnect() end)
            changedConnection = nil
        end

        changedConnection = UserInputService.InputChanged:Connect(function(changed)
            if not dragging then return end
            if changed.UserInputType == Enum.UserInputType.MouseMovement
                or changed.UserInputType == Enum.UserInputType.Touch then
                local delta = changed.Position - dragStart
                if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then moved = true end
                UI.shell.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)

        local endConnection
        endConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changedConnection then
                    changedConnection:Disconnect()
                    changedConnection = nil
                end
                if endConnection then endConnection:Disconnect() end
                if not expanded and not moved then expand() end
            end
        end)
    end)

    -- Animacao continua de onda e neon. Se falhar, nao derruba o painel.
    local animationConnection
    animationConnection = RunService.RenderStepped:Connect(function()
        if not UI.gui or not UI.gui.Parent then
            if animationConnection then animationConnection:Disconnect() end
            return
        end

        local t = os.clock()
        pcall(function()
            UI.waveGlow.Position = UDim2.new((math.sin(t * 1.7) + 1) * 0.5, 0, 0.5, 0)
            for i, s in ipairs(UI.glowStrokes) do
                s.Transparency = math.clamp(0.35 + i * 0.14 + math.sin(t * 2 + i) * 0.08, 0.15, 0.9)
            end
            for _, item in ipairs(cardAnimations) do
                if item.button.Visible then
                    local x = ((math.sin(t * 1.25 + item.phase) + 1) * 0.5)
                    item.shine.Position = UDim2.new(x, -26, 0, 0)
                end
            end
        end)
    end)

    -- Entrada em onda: o painel ja existe antes da animacao.
    task.spawn(function()
        local finalPosition = UDim2.fromScale(0.5, 0.5)
        UI.shell.Position = UDim2.new(0.5, -85, 0.5, 0)
        UI.shell.Rotation = -2

        local ok = pcall(function()
            local first = TweenService:Create(
                UI.shell,
                TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, 24, 0.5, 0), Rotation = 1}
            )
            first:Play()
            first.Completed:Wait()

            local second = TweenService:Create(
                UI.shell,
                TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(0.5, -10, 0.5, 0), Rotation = -0.5}
            )
            second:Play()
            second.Completed:Wait()

            TweenService:Create(
                UI.shell,
                TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {Position = finalPosition, Rotation = 0}
            ):Play()
        end)

        if not ok then
            UI.shell.Position = finalPosition
            UI.shell.Rotation = 0
        end
    end)
end

local okUI, errUI = pcall(setupN4TInterface)
if not okUI then
    warn("[N4T HUB] Erro ao montar interface: " .. tostring(errUI))
    -- Mesmo se uma parte opcional falhar, mantemos o painel base visivel.
    if UI.shell then
        UI.shell.Visible = true
        UI.shell.Position = UDim2.fromScale(0.5, 0.5)
        UI.shell.Size = UI.bigSize
        UI.shell.Rotation = 0
    end
end

print("N4T HUB carregado!")
