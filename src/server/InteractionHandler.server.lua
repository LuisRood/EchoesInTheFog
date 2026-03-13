-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")

print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

-- El servidor también escucha los ProximityPrompts, pero aquí ejecutamos la lógica real
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local actionType = prompt.Name 
    
    if actionType == "Puerta" then
        -- Aquí programaremos la rotación de la bisagra para que todos vean la puerta abrirse
        print("[SERVIDOR] " .. player.Name .. " interactuó con una puerta.")
        
    elseif actionType == "Revivir" then
        -- Aquí validaremos quién está en el suelo y le restauraremos la vida
        print("[SERVIDOR] " .. player.Name .. " completó la acción de revivir.")
        
    elseif actionType == "Item" then
        -- Lógica para añadir a un inventario global o dar una herramienta
        print("[SERVIDOR] " .. player.Name .. " recogió " .. prompt.ObjectText)
        
        -- Destruimos el objeto del mapa para que nadie más lo recoja
        if prompt.Parent then
            prompt.Parent:Destroy()
        end
    end
end)