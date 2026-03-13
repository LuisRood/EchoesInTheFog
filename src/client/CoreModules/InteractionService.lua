local InteractionService = {}
local ProximityPromptService = game:GetService("ProximityPromptService")

function InteractionService:Init()
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