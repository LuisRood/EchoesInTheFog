local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
-- ¡NUEVO! Importamos la máquina de estados
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))

local carpetaPeligros = workspace:WaitForChild("Peligros")
local RANGO_VISION = 100 
local AI_UPDATE_INTERVAL = 0.15
local aiAccumulator = 0

-- ==========================================
-- SISTEMA DE ATAQUE (Colisión)
-- ==========================================
local function inicializarAtaque(monstruo)
    local rootPart = monstruo:WaitForChild("HumanoidRootPart")
    local enEnfriamiento = false -- Evita que te haga daño 60 veces por segundo al tocarte

    -- Leemos cuánto daño hace este monstruo desde sus propiedades (Si no tiene, hace 34 por defecto)
    -- 34 significa que te abate al tercer golpe (34 + 34 + 34 = 102)
    local danoDelMonstruo = monstruo:GetAttribute("Dano") or 34

    rootPart.Touched:Connect(function(hit)
        if enEnfriamiento then return end

        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)

        if player then
            -- Consultamos a la Máquina de Estados
            local esInvulnerable = character:GetAttribute("Invulnerable")
            local estadoActual = PlayerStateManager:GetState(player)

            -- Si te toca, no eres invulnerable y estás sana...
            if not esInvulnerable and estadoActual == "Sano" then
                enEnfriamiento = true
                print("[PELIGRO] El monstruo alcanzó a " .. player.Name .. "!")
                
                -- ¡NUEVO! En lugar de abatirlo de golpe, le mandamos el daño
                PlayerStateManager:TakeDamage(player, danoDelMonstruo)

                -- Le damos 2 segundos de "cooldown" al monstruo antes de que pueda volver a morder
                task.wait(2) 
                enEnfriamiento = false
            end
        end
    end)
end

-- Conectamos el sistema de ataque a todos los monstruos de la carpeta
for _, monstruo in ipairs(carpetaPeligros:GetChildren()) do
    if monstruo:IsA("Model") and monstruo:FindFirstChild("HumanoidRootPart") then
        inicializarAtaque(monstruo)
    end
end

-- ==========================================
-- SISTEMA DE NAVEGACIÓN (Persecución)
-- ==========================================
RunService.Heartbeat:Connect(function(dt)
    aiAccumulator += dt
    if aiAccumulator < AI_UPDATE_INTERVAL then
        return
    end
    aiAccumulator = 0

    for _, monstruo in ipairs(carpetaPeligros:GetChildren()) do
        local humanoid = monstruo:FindFirstChild("Humanoid")
        local rootPart = monstruo:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            local objetivoHRP = nil
            local distanciaMinima = RANGO_VISION

            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    local distancia = (hrp.Position - rootPart.Position).Magnitude
                    
                    if distancia < distanciaMinima then
                        -- Solo persigue si el jugador NO está abatido (Opcional: para que vaya por los vivos)
                        if PlayerStateManager:GetState(player) == "Sano" then
                            distanciaMinima = distancia
                            objetivoHRP = hrp
                        end
                    end
                end
            end

            if objetivoHRP then
                humanoid.WalkSpeed = 12 
                humanoid:MoveTo(objetivoHRP.Position)
            else
                humanoid.WalkSpeed = 0
            end
        end
    end
end)