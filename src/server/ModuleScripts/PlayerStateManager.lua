local PlayerStateManager = {}
local Players = game:GetService("Players")

-- Diccionario en memoria para rastrear a cada jugador
local playerStates = {}

-- ==========================================
-- NUEVO: LÓGICA DE TELETRANSPORTE (CHECKPOINT)
-- ==========================================
function PlayerStateManager:EjecutarRespawn(player)
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- 1. Restauramos sus estadísticas al 100%
    character:SetAttribute("VidaActual", character:GetAttribute("VidaMaxima") or 100)

    -- Sincronizamos el estado lógico y visual para que la IA vuelva a detectarlo.
    self:SetState(player, "Sano")
    
    -- 2. Buscamos si pisó un checkpoint antes. Si no, lo mandamos al origen (0,5,0)
    local ultimoCheckpoint = character:GetAttribute("UltimoCheckpoint")
    
    if rootPart then
        if ultimoCheckpoint then
            -- Lo teletransportamos a la coordenada guardada
            rootPart.CFrame = ultimoCheckpoint
            print("[SISTEMA] " .. player.Name .. " reapareció en su último Checkpoint.")
        else
            -- Coordenada de emergencia por si muere al principio del nivel
            rootPart.CFrame = CFrame.new(0, 5, 0) 
            print("[SISTEMA] " .. player.Name .. " reapareció en el inicio del mapa.")
        end
    end
end

-- ==========================================
-- TU FUNCIÓN SET STATE ACTUALIZADA
-- ==========================================
function PlayerStateManager:SetState(player, newState)
    playerStates[player.UserId] = newState
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    -- 1. Sincronizamos el estado con el Cliente usando un Atributo
    character:SetAttribute("Estado", newState)
    
    if newState == "Abatido" then
        print("[ESTADO] " .. player.Name .. " ha caído abatida.")

        if hrp and hrp:FindFirstChild("Revivir") then
            return
        end
        
        -- Generamos el ProximityPrompt dinámicamente en el servidor
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Revivir"
        prompt.ActionText = "Levantar"
        prompt.ObjectText = "Compañera Caída"
        prompt.HoldDuration = 3 -- 3 segundos de tensión para revivir
        prompt.RequiresLineOfSight = false
        prompt.Parent = hrp
        
        -- ==========================================
        -- ¡NUEVO! TEMPORIZADOR DE DESANGRADO
        -- ==========================================
        local tiempoLimite = 30 -- 30 segundos para ser revivida
        print("[ALERTA] Tienen " .. tiempoLimite .. " segundos para salvar a " .. player.Name)
        
        -- 1. Creamos la UI flotante dinámicamente en el servidor
        local cartelFlotante = Instance.new("BillboardGui")
        cartelFlotante.Name = "RelojDesangrado"
        cartelFlotante.Size = UDim2.new(0, 100, 0, 50)
        cartelFlotante.StudsOffset = Vector3.new(0, 3, 0) -- Flota 3 metros sobre el cuerpo
        cartelFlotante.AlwaysOnTop = true -- Se ve a través de las paredes
        cartelFlotante.Parent = hrp

        local textoReloj = Instance.new("TextLabel")
        textoReloj.Size = UDim2.new(1, 0, 1, 0)
        textoReloj.BackgroundTransparency = 1
        textoReloj.TextColor3 = Color3.new(1, 0.2, 0.2) -- Rojo sangre
        textoReloj.TextScaled = true
        textoReloj.Font = Enum.Font.Creepster
        textoReloj.Text = tostring(tiempoLimite)
        textoReloj.Parent = cartelFlotante

        -- 2. Creamos un hilo paralelo para la cuenta regresiva visual
        task.spawn(function()
            local tiempoRestante = tiempoLimite

            -- Mientras siga abatida y el tiempo sea mayor a 0...
            while tiempoRestante > 0 and character and character:GetAttribute("Estado") == "Abatido" do
                task.wait(1)
                tiempoRestante -= 1
                textoReloj.Text = tostring(tiempoRestante)
            end

            -- Si el bucle termina, limpiamos la UI flotante
            if cartelFlotante then cartelFlotante:Destroy() end

            -- Si el tiempo llegó a 0 y SIGUE abatida, ejecutamos el castigo
            if tiempoRestante <= 0 and character and character:GetAttribute("Estado") == "Abatido" then
                print("[SISTEMA] Se acabó el tiempo. " .. player.Name .. " no resistió.")
                self:EjecutarRespawn(player)
            end
        end)
        
    elseif newState == "Sano" then
        print("[ESTADO] " .. player.Name .. " está de pie.")
        
        -- Validamos: Si un amigo la levanta (vida 0), le damos 30. 
        -- Si viene del Respawn (vida 100), no se la bajamos a 30.
        local vidaActual = character:GetAttribute("VidaActual") or 0
        if vidaActual < 30 then
            character:SetAttribute("VidaActual", 30)
        end

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
Players.PlayerAdded:Connect(inicializarJugador)

-- Limpiar estados huérfanos cuando el jugador sale
Players.PlayerRemoving:Connect(function(player)
    playerStates[player.UserId] = nil
end)

-- Ejecutar para los jugadores que YA están adentro al arrancar el servidor
for _, player in ipairs(Players:GetPlayers()) do
    inicializarJugador(player)
end

return PlayerStateManager