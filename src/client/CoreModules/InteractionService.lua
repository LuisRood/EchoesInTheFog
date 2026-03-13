local InteractionService = {}
local ProximityPromptService = game:GetService("ProximityPromptService")

function InteractionService:Init()
    local player = game.Players.LocalPlayer
    -- ¡NUEVO! Escuchar cuando un prompt está a punto de aparecer en pantalla
    ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
        -- Si es el prompt de revivir, y está pegado a MI personaje...
        if prompt.Name == "Revivir" and prompt.Parent and prompt.Parent.Parent == player.Character then
            -- Lo apagamos localmente. Los demás sí lo verán, tú no.
            prompt.Enabled = false 
        end
    end)
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local actionType = prompt.Name 
        
        -- El cliente SOLO se encarga de UI y efectos locales
        if actionType == "Nota" then
            print("[CLIENTE] Abriendo el UI para leer: " .. prompt.ObjectText)
            -- TODO: Mostrar GUI de papel en la pantalla de Mabel
        end
        
        -- Nota: No ponemos "Puerta" ni "Revivir" aquí porque de eso ya se encarga el Backend.
    end)
end

return InteractionService