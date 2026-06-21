local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LobbyBuilder = {}

local GENERATED_ATTRIBUTE = "GeneratedByLobbyBuilder"

local DEFAULT_CONFIG = {
    Enabled = true,
    ReplaceExisting = false,
    RoomCount = 4,
    Origin = Vector3.new(0, 0, 220),
    DisableExternalSpawnLocations = true,
}

local buildOrigin = DEFAULT_CONFIG.Origin

local function at(x, y, z)
    return CFrame.new(buildOrigin + Vector3.new(x, y, z))
end

local function atPosition(position)
    return CFrame.new(buildOrigin + position)
end

local function getConfig(config)
    local merged = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        merged[key] = value
    end

    if typeof(config) == "table" then
        for key, value in pairs(config) do
            merged[key] = value
        end
    end

    merged.RoomCount = math.clamp(math.floor(tonumber(merged.RoomCount) or 4), 1, 4)
    if typeof(merged.Origin) ~= "Vector3" then
        merged.Origin = DEFAULT_CONFIG.Origin
    end

    return merged
end

local function ensureFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function ensureWorldFolder(name)
    local existing = Workspace:FindFirstChild(name)
    if existing then
        return existing
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = Workspace
    return folder
end

local function hasUsableLobby()
    local lobby = Workspace:FindFirstChild("Lobby")
    if not lobby then
        return false
    end

    local hub = lobby:FindFirstChild("Hub_Multijugador")
    local salas = hub and hub:FindFirstChild("SalasDeEspera")
    if not salas then
        return false
    end

    for _, child in ipairs(salas:GetChildren()) do
        if child:IsA("Model") and (child:FindFirstChild("Hitbox") or child:FindFirstChild("HitBox")) then
            return true
        end
    end

    return false
end

local function makePart(parent, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function makeNeon(parent, name, size, cframe, color)
    local part = makePart(parent, name, size, cframe, color, Enum.Material.Neon)
    part.CanCollide = false
    return part
end

local function addPointLight(parent, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = true
    light.Parent = parent
    return light
end

local function addRoomBillboard(hitbox, maxPlayers)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BillboardGui"
    billboard.Enabled = true
    billboard.Size = UDim2.new(0, 170, 0, 34)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, -2.35, 11.1)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 90
    billboard.LightInfluence = 0
    billboard.Parent = hitbox

    local status = Instance.new("TextLabel")
    status.Name = "TextoEstado"
    status.BackgroundColor3 = Color3.fromRGB(4, 7, 7)
    status.BackgroundTransparency = 0.25
    status.Size = UDim2.new(1, 0, 1, 0)
    status.Position = UDim2.new(0, 0, 0, 0)
    status.Text = "0/" .. tostring(maxPlayers) .. " - Esperando"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextStrokeTransparency = 0.15
    status.Font = Enum.Font.Oswald
    status.TextScaled = true
    status.Parent = billboard

    return status
end

local function addLobbyTitleBillboard(anchor)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BillboardGui"
    billboard.Enabled = true
    billboard.Size = UDim2.new(0, 460, 0, 96)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150
    billboard.LightInfluence = 0
    billboard.Parent = anchor

    local title = Instance.new("TextLabel")
    title.Name = "TituloJuego"
    title.BackgroundColor3 = Color3.fromRGB(3, 5, 6)
    title.BackgroundTransparency = 0.32
    title.Size = UDim2.new(1, 0, 0.62, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "ECHOES IN THE FOG"
    title.TextColor3 = Color3.fromRGB(235, 245, 245)
    title.TextStrokeTransparency = 0.18
    title.Font = Enum.Font.Oswald
    title.TextScaled = true
    title.Parent = billboard

    local chapter = Instance.new("TextLabel")
    chapter.Name = "TituloCapitulo"
    chapter.BackgroundColor3 = Color3.fromRGB(3, 5, 6)
    chapter.BackgroundTransparency = 0.45
    chapter.Size = UDim2.new(1, 0, 0.38, 0)
    chapter.Position = UDim2.new(0, 0, 0.62, 0)
    chapter.Text = "CAPITULO 1 - SALAS DE EXPEDICION"
    chapter.TextColor3 = Color3.fromRGB(205, 225, 215)
    chapter.TextStrokeTransparency = 0.25
    chapter.Font = Enum.Font.Oswald
    chapter.TextScaled = true
    chapter.Parent = billboard

    return billboard
end

local function addDonorPodiumBillboard(anchor, rank)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DonorBillboard"
    billboard.Enabled = true
    billboard.Size = UDim2.new(0, 170, 0, 84)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 115
    billboard.LightInfluence = 0
    billboard.Parent = anchor

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "DonorRank_" .. tostring(rank) .. "_Rank"
    rankLabel.BackgroundColor3 = Color3.fromRGB(3, 5, 6)
    rankLabel.BackgroundTransparency = 0.22
    rankLabel.Size = UDim2.new(1, 0, 0.34, 0)
    rankLabel.Text = "#" .. tostring(rank)
    rankLabel.TextColor3 = rank == 1 and Color3.fromRGB(255, 220, 110) or Color3.fromRGB(220, 235, 230)
    rankLabel.TextStrokeTransparency = 0.18
    rankLabel.Font = Enum.Font.Oswald
    rankLabel.TextScaled = true
    rankLabel.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "DonorRank_" .. tostring(rank) .. "_Name"
    nameLabel.BackgroundColor3 = Color3.fromRGB(3, 5, 6)
    nameLabel.BackgroundTransparency = 0.35
    nameLabel.Size = UDim2.new(1, 0, 0.36, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.34, 0)
    nameLabel.Text = "VACANTE"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.Font = Enum.Font.Oswald
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "DonorRank_" .. tostring(rank) .. "_Amount"
    amountLabel.BackgroundColor3 = Color3.fromRGB(3, 5, 6)
    amountLabel.BackgroundTransparency = 0.5
    amountLabel.Size = UDim2.new(1, 0, 0.3, 0)
    amountLabel.Position = UDim2.new(0, 0, 0.7, 0)
    amountLabel.Text = "0 R$"
    amountLabel.TextColor3 = Color3.fromRGB(90, 220, 170)
    amountLabel.TextStrokeTransparency = 0.35
    amountLabel.Font = Enum.Font.Oswald
    amountLabel.TextScaled = true
    amountLabel.Parent = billboard
end

local function addDonorBoardSurface(board)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "DonorBoardSurface"
    surfaceGui.Face = Enum.NormalId.Back
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 34
    surfaceGui.LightInfluence = 0
    surfaceGui.Parent = board

    local title = Instance.new("TextLabel")
    title.Name = "DonorBoardTitle"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0.18, 0)
    title.Text = "TOP DONADORES"
    title.TextColor3 = Color3.fromRGB(235, 245, 245)
    title.TextStrokeTransparency = 0.22
    title.Font = Enum.Font.Oswald
    title.TextScaled = true
    title.Parent = surfaceGui

    for rank = 4, 10 do
        local row = Instance.new("TextLabel")
        row.Name = "DonorBoard_" .. tostring(rank)
        row.BackgroundTransparency = rank % 2 == 0 and 0.78 or 1
        row.BackgroundColor3 = Color3.fromRGB(4, 8, 8)
        row.Size = UDim2.new(0.92, 0, 0.105, 0)
        row.Position = UDim2.new(0.04, 0, 0.18 + ((rank - 4) * 0.112), 0)
        row.Text = "#" .. tostring(rank) .. "  VACANTE"
        row.TextColor3 = Color3.fromRGB(210, 230, 222)
        row.TextStrokeTransparency = 0.45
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Font = Enum.Font.Oswald
        row.TextScaled = true
        row.Parent = surfaceGui
    end
end

local function addSurfaceLabel(parent, labelName, text, color)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "SurfaceGui"
    surfaceGui.Face = Enum.NormalId.Back
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 42
    surfaceGui.LightInfluence = 0
    surfaceGui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = labelName or "Texto"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(230, 230, 230)
    label.TextStrokeTransparency = 0.35
    label.Font = Enum.Font.Oswald
    label.TextScaled = true
    label.Parent = surfaceGui
    return label
end

local function createRoom(salasFolder, index, totalRooms, maxPlayers)
    local spacing = 34
    local firstX = -((totalRooms - 1) * spacing) / 2
    local x = firstX + ((index - 1) * spacing)
    local z = -30

    local room = Instance.new("Model")
    room.Name = "Sala_" .. tostring(index)
    room.Parent = salasFolder

    local wallPanel = makePart(
        room,
        "PanelFondo",
        Vector3.new(30, 16, 0.35),
        at(x, 8, -48.8),
        Color3.fromRGB(15, 19, 20),
        Enum.Material.SmoothPlastic
    )
    wallPanel.CanCollide = false

    local wallAccent = makeNeon(
        room,
        "PanelFondo_Acento",
        Vector3.new(22, 0.14, 0.2),
        at(x, 15.4, -48.55),
        Color3.fromRGB(38, 125, 105)
    )
    wallAccent.Transparency = 0.48

    local pad = makePart(
        room,
        "Plataforma",
        Vector3.new(24, 0.35, 20),
        at(x, 0.25, z),
        Color3.fromRGB(46, 58, 54),
        Enum.Material.Concrete
    )
    pad.CanCollide = true

    local trimColor = Color3.fromRGB(52, 185, 150)
    local borderFront = makeNeon(room, "Borde_Frente", Vector3.new(24, 0.1, 0.32), at(x, 0.55, z + 10.2), trimColor)
    local borderBack = makeNeon(room, "Borde_Fondo", Vector3.new(24, 0.1, 0.32), at(x, 0.55, z - 10.2), trimColor)
    local borderLeft = makeNeon(room, "Borde_Izquierdo", Vector3.new(0.32, 0.1, 20), at(x - 12.2, 0.55, z), trimColor)
    local borderRight = makeNeon(room, "Borde_Derecho", Vector3.new(0.32, 0.1, 20), at(x + 12.2, 0.55, z), trimColor)
    borderFront.Transparency = 0.26
    borderBack.Transparency = 0.38
    borderLeft.Transparency = 0.38
    borderRight.Transparency = 0.38

    local portalBack = makePart(
        room,
        "MarcoPortal",
        Vector3.new(21, 12, 1),
        at(x, 6, z - 10.9),
        Color3.fromRGB(17, 22, 23),
        Enum.Material.SmoothPlastic
    )
    portalBack.CanCollide = true

    local portalLight = makeNeon(room, "Portal_Luz", Vector3.new(16, 7, 0.28), at(x, 6, z - 10.25), Color3.fromRGB(28, 135, 108))
    portalLight.Transparency = 0.42
    local labelPart = makePart(
        room,
        "SenalSala",
        Vector3.new(16, 2.2, 0.3),
        at(x, 11.9, z - 9.6),
        Color3.fromRGB(18, 18, 18),
        Enum.Material.SmoothPlastic
    )
    labelPart.CanCollide = false
    addSurfaceLabel(labelPart, "Texto", "SALA " .. tostring(index), Color3.fromRGB(220, 245, 235))

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Anchored = true
    hitbox.Size = Vector3.new(22, 10, 18)
    hitbox.CFrame = at(x, 5.2, z)
    hitbox.Transparency = 1
    hitbox.CanCollide = false
    hitbox.CanTouch = false
    hitbox.CanQuery = true
    hitbox.Parent = room
    addRoomBillboard(hitbox, maxPlayers)

    return room
end

local function createDonorShowcase(parent)
    local showcase = Instance.new("Model")
    showcase.Name = "DonorShowcase"
    showcase.Parent = parent

    local base = makePart(
        showcase,
        "BaseDonadores",
        Vector3.new(44, 0.4, 18),
        at(56, 0.2, 22),
        Color3.fromRGB(30, 39, 39),
        Enum.Material.Concrete
    )
    base.CanCollide = true

    local header = makePart(
        showcase,
        "HeaderDonadores",
        Vector3.new(40, 3.2, 0.35),
        at(56, 8.9, 13.2),
        Color3.fromRGB(12, 15, 16),
        Enum.Material.SmoothPlastic
    )
    header.CanCollide = false
    addSurfaceLabel(header, "Texto", "PODIO DE SOBREVIVIENTES", Color3.fromRGB(230, 245, 240))

    local podiums = {
        { Rank = 2, X = 47, Height = 2.2, Color = Color3.fromRGB(88, 102, 103) },
        { Rank = 1, X = 56, Height = 3.4, Color = Color3.fromRGB(110, 102, 70) },
        { Rank = 3, X = 65, Height = 1.7, Color = Color3.fromRGB(85, 70, 58) },
    }

    for _, podium in ipairs(podiums) do
        local part = makePart(
            showcase,
            "PodioDonador_" .. tostring(podium.Rank),
            Vector3.new(7.5, podium.Height, 7.5),
            at(podium.X, podium.Height / 2, 22),
            podium.Color,
            Enum.Material.Metal
        )
        part.CanCollide = true

        local accent = makeNeon(
            showcase,
            "PodioDonador_" .. tostring(podium.Rank) .. "_Acento",
            Vector3.new(7.8, 0.1, 7.8),
            at(podium.X, podium.Height + 0.1, 22),
            Color3.fromRGB(52, 185, 150)
        )
        accent.Transparency = 0.52

        addDonorPodiumBillboard(part, podium.Rank)
    end

    local board = makePart(
        showcase,
        "TableroTopDonadores",
        Vector3.new(18, 12, 0.35),
        at(74, 6.2, 19),
        Color3.fromRGB(9, 13, 14),
        Enum.Material.SmoothPlastic
    )
    board.CanCollide = false
    addDonorBoardSurface(board)

    local boardAccent = makeNeon(
        showcase,
        "TableroTopDonadores_Acento",
        Vector3.new(18.6, 0.12, 0.2),
        at(74, 12.4, 18.75),
        Color3.fromRGB(52, 185, 150)
    )
    boardAccent.Transparency = 0.45

    return showcase
end

local function configureLighting()
    Lighting.Ambient = Color3.fromRGB(26, 28, 30)
    Lighting.Brightness = 1.4
    Lighting.GlobalShadows = true
    Lighting.FogColor = Color3.fromRGB(140, 145, 145)
    Lighting.FogStart = 40
    Lighting.FogEnd = 160
end

local function disableExternalSpawnLocations(lobbyFolder)
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("SpawnLocation") and not descendant:IsDescendantOf(lobbyFolder) then
            descendant.Enabled = false
        end
    end
end

function LobbyBuilder.Build(config, context)
    local resolved = getConfig(config)
    if resolved.Enabled == false then
        return false, "Lobby generation disabled"
    end

    buildOrigin = resolved.Origin

    context = context or {}
    local maxPlayers = tonumber(context.MaxPlayersPerRoom) or 4

    ensureWorldFolder("Checkpoints")
    ensureWorldFolder("Peligros")

    local existingLobby = Workspace:FindFirstChild("Lobby")
    if existingLobby and hasUsableLobby() and not resolved.ReplaceExisting then
        return false, "Using existing Workspace/Lobby"
    end

    if existingLobby and existingLobby:GetAttribute(GENERATED_ATTRIBUTE) ~= true and not resolved.ReplaceExisting then
        return false, "Workspace/Lobby exists; set ReplaceExisting=true to rebuild it"
    end

    if existingLobby and (resolved.ReplaceExisting or existingLobby:GetAttribute(GENERATED_ATTRIBUTE) == true) then
        existingLobby:Destroy()
    end

    local lobbyFolder = Workspace:FindFirstChild("Lobby")
    if not lobbyFolder then
        lobbyFolder = Instance.new("Folder")
        lobbyFolder.Name = "Lobby"
        lobbyFolder.Parent = Workspace
    end
    lobbyFolder:SetAttribute(GENERATED_ATTRIBUTE, true)

    local hub = lobbyFolder:FindFirstChild("Hub_Multijugador")
    if hub then
        hub:Destroy()
    end

    hub = Instance.new("Model")
    hub.Name = "Hub_Multijugador"
    hub.Parent = lobbyFolder

    local architecture = ensureFolder(hub, "Arquitectura")
    local decor = ensureFolder(hub, "Decoracion")
    local salasFolder = ensureFolder(hub, "SalasDeEspera")

    local floor = makePart(
        architecture,
        "PisoPrincipal",
        Vector3.new(170, 1, 98),
        at(0, -0.5, 0),
        Color3.fromRGB(58, 64, 64),
        Enum.Material.Concrete
    )
    floor.CanCollide = true

    local centralWalkway = makePart(
        decor,
        "PasilloCentral",
        Vector3.new(30, 0.06, 64),
        at(0, 0.04, 0),
        Color3.fromRGB(34, 44, 44),
        Enum.Material.Slate
    )
    centralWalkway.CanCollide = false

    makePart(architecture, "ParedFondo", Vector3.new(170, 20, 2), at(0, 9.5, -50), Color3.fromRGB(52, 55, 57), Enum.Material.Concrete)
    makePart(architecture, "ParedFrente", Vector3.new(170, 20, 2), at(0, 9.5, 50), Color3.fromRGB(48, 50, 52), Enum.Material.Concrete)
    makePart(architecture, "ParedIzquierda", Vector3.new(2, 20, 98), at(-85, 9.5, 0), Color3.fromRGB(48, 50, 52), Enum.Material.Concrete)
    makePart(architecture, "ParedDerecha", Vector3.new(2, 20, 98), at(85, 9.5, 0), Color3.fromRGB(48, 50, 52), Enum.Material.Concrete)
    makePart(architecture, "Techo", Vector3.new(170, 1, 98), at(0, 19.5, 0), Color3.fromRGB(42, 44, 46), Enum.Material.Concrete)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Spawn_Lobby"
    spawn.Anchored = true
    spawn.Size = Vector3.new(14, 1, 10)
    spawn.CFrame = at(0, 0.15, 35)
    spawn.Color = Color3.fromRGB(42, 56, 60)
    spawn.Material = Enum.Material.Metal
    spawn.Neutral = true
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0
    spawn.Enabled = true
    spawn.Parent = hub

    if resolved.DisableExternalSpawnLocations then
        disableExternalSpawnLocations(lobbyFolder)
    end

    local spawnLine = makeNeon(decor, "LineaSpawn", Vector3.new(16, 0.08, 0.28), at(0, 0.62, 28), Color3.fromRGB(70, 175, 178))
    spawnLine.Transparency = 0.5

    local walkwayLeft = makeNeon(decor, "PasilloCentral_Izquierda", Vector3.new(0.18, 0.08, 35), at(-15.4, 0.58, 5), Color3.fromRGB(42, 150, 140))
    local walkwayRight = makeNeon(decor, "PasilloCentral_Derecha", Vector3.new(0.18, 0.08, 35), at(15.4, 0.58, 5), Color3.fromRGB(42, 150, 140))
    walkwayLeft.Transparency = 0.58
    walkwayRight.Transparency = 0.58

    local titleAnchor = makePart(decor, "TituloLobby", Vector3.new(1, 1, 1), at(0, 14.6, 3), Color3.fromRGB(12, 14, 16), Enum.Material.SmoothPlastic)
    titleAnchor.CanCollide = false
    titleAnchor.Transparency = 1
    addLobbyTitleBillboard(titleAnchor)

    createDonorShowcase(decor)

    for index = 1, resolved.RoomCount do
        createRoom(salasFolder, index, resolved.RoomCount, maxPlayers)
    end

    local lightPositions = {
        Vector3.new(-55, 18.8, 22),
        Vector3.new(0, 18.8, 24),
        Vector3.new(55, 18.8, 22),
        Vector3.new(-48, 18.8, -24),
        Vector3.new(0, 18.8, -25),
        Vector3.new(48, 18.8, -24),
    }

    for index, position in ipairs(lightPositions) do
        local fixture = makePart(decor, "LuzTecho_" .. tostring(index), Vector3.new(12, 0.22, 2.4), atPosition(position), Color3.fromRGB(120, 150, 145), Enum.Material.SmoothPlastic)
        fixture.CanCollide = false
        local glow = makeNeon(decor, "LuzTecho_Brillo_" .. tostring(index), Vector3.new(8.5, 0.06, 1.2), atPosition(position + Vector3.new(0, -0.18, 0)), Color3.fromRGB(100, 165, 155))
        glow.Transparency = 0.7
        addPointLight(fixture, Color3.fromRGB(145, 210, 198), 0.45, 22)
    end

    for index = 1, 8 do
        local x = -70 + ((index - 1) * 20)
        local stain = makePart(
            decor,
            "MarcaPiso_" .. tostring(index),
            Vector3.new(5, 0.05, 1.2),
            at(x, 0.04, -2 + ((index % 2) * 6)) * CFrame.Angles(0, math.rad(index * 17), 0),
            Color3.fromRGB(22, 24, 24),
            Enum.Material.SmoothPlastic
        )
        stain.CanCollide = false
    end

    configureLighting()
    hub.PrimaryPart = spawn

    return true, "Generated Workspace/Lobby"
end

return LobbyBuilder
