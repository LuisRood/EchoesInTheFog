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
        
        -- Limpiamos el prompt si existe
        if hrp then
            local prompt = hrp:FindFirstChild("Revivir")
            if prompt then prompt:Destroy() end
        end
        
        -- Aquí más adelante restauraremos la vida (Health)
    end
end

function PlayerStateManager:GetState(player)
    return playerStates[player.UserId] or "Sano"
end

return PlayerStateManager