-- Archivo: src/server/LobbyManager.server.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local Logger = require(ModuleScripts:WaitForChild("Logger"))
local log = Logger:WithTag("Lobby")

log:Info("Gestor de salas iniciado")

-- ==========================================
-- CONFIGURACIÓN DEL SISTEMA
-- ==========================================
local MAX_PLAYERS_PER_ROOM = 4
local COUNTDOWN_SECONDS = 15
-- PEGA AQUÍ TU ID DEL LUGAR "Capitulo_1"
local CHAPTER_ONE_PLACE_ID = 73635928808717 
local lobbyConfig = (((require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants")) or {}).Server or {}).Lobby) or {}
local WAIT_TIMEOUT = lobbyConfig.WaitTimeoutSeconds or 10

local function getSalasFolder()
    local lobbyFolder = Workspace:WaitForChild("Lobby", WAIT_TIMEOUT)
    if not lobbyFolder then
        return nil
    end

    local hub = lobbyFolder:WaitForChild("Hub_Multijugador", WAIT_TIMEOUT)
    if not hub then
        return nil
    end

    return hub:WaitForChild("SalasDeEspera", WAIT_TIMEOUT)
end

local salasFolder = getSalasFolder() -- Contiene Sala_1, Sala_2, ...
if not salasFolder then
    log:Warn("No se encontro Workspace/Lobby/Hub_Multijugador/SalasDeEspera. Lobby deshabilitado para esta sesion.")
    return
end

local function getRoomHitbox(roomModel)
    return roomModel:FindFirstChild("Hitbox") or roomModel:FindFirstChild("HitBox")
end

-- Diccionario en memoria para rastrear el estado de cada sala independiente
local activeRooms = {}

-- Inicializamos el estado de todas las salas físicas que hayas creado en Studio
for _, salaModel in ipairs(salasFolder:GetChildren()) do
    if salaModel:IsA("Model") and getRoomHitbox(salaModel) then
        activeRooms[salaModel.Name] = {
            Model = salaModel,
            Timer = COUNTDOWN_SECONDS,
            StartTime = nil,
            State = "Waiting", -- Waiting, Counting, Teleporting
            PlayersInZone = {}
        }
    end
end

if next(activeRooms) == nil then
    log:Warn("No se detectaron salas validas en SalasDeEspera")
else
    log:Info("Salas detectadas: " .. tostring(#salasFolder:GetChildren()))
end

-- ==========================================
-- FUNCIÓN DE VIAJE (Crea el Servidor Dedicado)
-- ==========================================
local function despacharGrupo(roomName, roomData)
    roomData.State = "Teleporting"
    local hitbox = getRoomHitbox(roomData.Model)
    if not hitbox then
        log:Warn(roomName .. " no tiene Hitbox/HitBox")
        roomData.State = "Waiting"
        roomData.Timer = COUNTDOWN_SECONDS
        roomData.StartTime = nil
        roomData.PlayersInZone = {}
        return
    end

    local textoUI = hitbox.BillboardGui.TextoEstado
    textoUI.Text = "¡INICIANDO VIAJE!"
    textoUI.TextColor3 = Color3.fromRGB(0, 255, 0) -- Verde de éxito

    log:Info("Despachando grupo de " .. roomName)

    -- Usamos task.spawn para no congelar el bucle principal de las otras salas
    task.spawn(function()
        local success, result = pcall(function()
            local accessCode = TeleportService:ReserveServer(CHAPTER_ONE_PLACE_ID)
            TeleportService:TeleportToPrivateServer(CHAPTER_ONE_PLACE_ID, accessCode, roomData.PlayersInZone)
        end)

        if not success then
            log:Error(roomName .. " fallo al teletransportar: " .. tostring(result))
            textoUI.Text = "ERROR DE CONEXIÓN"
            textoUI.TextColor3 = Color3.fromRGB(255, 0, 0)
        end

        -- Damos tiempo a que los avatares desaparezcan antes de reiniciar la sala
        task.wait(6)
        
        -- Reinicio de fábrica para que el siguiente grupo la pueda usar
        roomData.State = "Waiting"
        roomData.Timer = COUNTDOWN_SECONDS
        roomData.StartTime = nil
        textoUI.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

-- ==========================================
-- EL MOTOR DE ESCANEO (Bucle Asíncrono)
-- ==========================================
-- Ejecutamos una auditoría cada 0.5 segundos (Super ligero para el servidor)
task.spawn(function()
    while task.wait(0.5) do
        
        for roomName, roomData in pairs(activeRooms) do
            -- Si esta sala ya está enviando a la gente, la ignoramos hasta que termine
            if roomData.State == "Teleporting" then continue end

            local hitbox = getRoomHitbox(roomData.Model)
            if not hitbox then
                roomData.State = "Waiting"
                roomData.Timer = COUNTDOWN_SECONDS
                roomData.StartTime = nil
                roomData.PlayersInZone = {}
                continue
            end

            local textoUI = hitbox.BillboardGui.TextoEstado
            
            -- Consulta Espacial: ¿Quién está cruzando el volumen 3D?
            local partes = Workspace:GetPartsInPart(hitbox)
            local currentPlayers = {}
            local unicos = {}

            for _, part in ipairs(partes) do
                local char = part.Parent
                if char and char:FindFirstChild("Humanoid") then
                    local player = Players:GetPlayerFromCharacter(char)
                    -- Evitamos duplicados (ej. contar brazo y pierna) y límite máximo
                    if player and not unicos[player.UserId] and #currentPlayers < MAX_PLAYERS_PER_ROOM then
                        unicos[player.UserId] = true
                        table.insert(currentPlayers, player)
                    end
                end
            end

            roomData.PlayersInZone = currentPlayers
            local numPlayers = #currentPlayers

            -- ==========================================
            -- MÁQUINA DE ESTADOS
            -- ==========================================
            if numPlayers > 0 then
                -- Hay gente adentro, arranca o continúa el reloj
                if roomData.State == "Waiting" then
                    roomData.State = "Counting"
                    roomData.StartTime = os.clock()
                end

                roomData.Timer = math.max(0, COUNTDOWN_SECONDS - (os.clock() - (roomData.StartTime or os.clock())))

                textoUI.Text = numPlayers .. "/" .. MAX_PLAYERS_PER_ROOM .. " - Saliendo en: " .. math.ceil(roomData.Timer) .. "s"

                -- Condición de disparo: Se acabó el tiempo O la sala se llenó a tope
                if roomData.Timer <= 0 or numPlayers == MAX_PLAYERS_PER_ROOM then
                    despacharGrupo(roomName, roomData)
                end
            else
                -- Si la gente se sale de la zona antes de que acabe el tiempo, se cancela todo
                if roomData.State == "Counting" then
                    roomData.State = "Waiting"
                    roomData.Timer = COUNTDOWN_SECONDS
                    roomData.StartTime = nil
                end
                
                textoUI.Text = "0/" .. MAX_PLAYERS_PER_ROOM .. " - Esperando Jugadores"
            end
        end
        
    end
end)