local PlayerStateManager = {}

-- Diccionario en memoria para rastrear a cada jugador
local playerStates = {}

function PlayerStateManager:SetState(player, newState)
    playerStates[player.UserId] = newState
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    -- 1. Sincronizamos el estado con el Cliente usando un Atributo
    character:SetAttribute("Estado", newState)
    
    if newState == "Abatido" then
        print("[ESTADO] " .. player.Name .. " ha caído abatida.")
        
        -- Generamos el ProximityPrompt dinámicamente en el servidor
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Revivir"
        prompt.ActionText = "Levantar"
        prompt.ObjectText = "Compañera Caída"
        prompt.HoldDuration = 3 -- 3 segundos de tensión para revivir
        prompt.RequiresLineOfSight = false
        prompt.Parent = hrp
        
    elseif newState == "Sano" then
        print("[ESTADO] " .. player.Name .. " está de pie.")
        
        character:SetAttribute("VidaActual", 30)
        -- Limpiamos el prompt si existe
        if hrp then
            local prompt = hrp:FindFirstChild("Revivir")
            if prompt then prompt:Destroy() end
        end

        character:SetAttribute("Invulnerable", true)

        -- task.delay ejecuta esta función de limpieza 3 segundos en el futuro sin pausar el script
        task.delay(3, function()
            -- Verificamos que el personaje siga existiendo (no se desconectó)
            if character and character.Parent then
                character:SetAttribute("Invulnerable", false)
                print("[ESTADO] " .. player.Name .. " ya es vulnerable de nuevo.")
            end
        end)
        -- Aquí más adelante restauraremos la vida (Health)
    end
end

function PlayerStateManager:GetState(player)
    return playerStates[player.UserId] or "Sano"
end

function PlayerStateManager:TakeDamage(player, amount)
    local character = player.Character
    if not character then return end

    local estadoActual = self:GetState(player)
    local esInvulnerable = character:GetAttribute("Invulnerable")

    -- Si ya está en el suelo o tiene escudo de invulnerabilidad, ignoramos el daño
    if estadoActual == "Abatido" or esInvulnerable then return end

    local vidaActual = character:GetAttribute("VidaActual") or 100
    
    -- Restamos el daño asegurándonos de que no baje de 0
    vidaActual = math.clamp(vidaActual - amount, 0, 100)
    character:SetAttribute("VidaActual", vidaActual)

    print("[SISTEMA] " .. player.Name .. " recibió " .. amount .. " de daño. Vida restante: " .. vidaActual)

    -- Si la vida llega a cero, activamos el estado Abatido
    if vidaActual <= 0 then
        self:SetState(player, "Abatido")
    end
end

function PlayerStateManager:Heal(player, amount)
    local character = player.Character
    if not character then return end

    local estadoActual = self:GetState(player)
    
    -- No puedes curarte si ya estás en el suelo abatida
    if estadoActual == "Abatido" then return end

    local vidaActual = character:GetAttribute("VidaActual") or 100
    local vidaMaxima = character:GetAttribute("VidaMaxima") or 100
    
    -- math.clamp asegura que la vida no suba de 100
    vidaActual = math.clamp(vidaActual + amount, 0, vidaMaxima)
    character:SetAttribute("VidaActual", vidaActual)

    print("[SISTEMA] " .. player.Name .. " usó un botiquín. Vida actual: " .. vidaActual)
end

-- ==========================================
-- INICIALIZACIÓN (Constructor de Estados)
-- ==========================================

local function inicializarPersonaje(player, character)
    playerStates[player.UserId] = "Sano"
    
    -- Le pegamos las etiquetas físicas al personaje para que el Cliente las lea
    character:SetAttribute("Estado", "Sano")
    character:SetAttribute("Invulnerable", false)
    
    -- ¡NUEVO! Sistema de vida personalizado
    character:SetAttribute("VidaMaxima", 100)
    character:SetAttribute("VidaActual", 100)

    print("[ESTADO] Atributos inicializados para " .. player.Name)
end

local function inicializarJugador(player)
    -- 1. Si el personaje ya cargó antes de que el script lo viera (Tu caso en Play Solo)
    if player.Character then
        inicializarPersonaje(player, player.Character)
    end
    
    -- 2. Si muere y vuelve a reaparecer (Respawn)
    player.CharacterAdded:Connect(function(character)
        inicializarPersonaje(player, character)
    end)
end

-- Escuchar a los jugadores que entren en el futuro
game.Players.PlayerAdded:Connect(inicializarJugador)

-- Ejecutar para los jugadores que YA están adentro al arrancar el servidor
for _, player in ipairs(game.Players:GetPlayers()) do
    inicializarJugador(player)
end

return PlayerStateManager