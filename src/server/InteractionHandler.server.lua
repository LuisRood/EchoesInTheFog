-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))

print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

-- El servidor también escucha los ProximityPrompts, pero aquí ejecutamos la lógica real
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local actionType = prompt.Name

    if actionType == "Revivir" then
        -- El prompt está anclado al HumanoidRootPart del jugador caído
        local targetCharacter = prompt.Parent.Parent
        local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(targetCharacter)
        if targetPlayer and targetPlayer.UserId ~= player.UserId then
            -- Cambiamos el estado de la persona caída a "Sano"
            PlayerStateManager:SetState(targetPlayer, "Sano")
            print("[SERVIDOR] " .. player.Name .. " salvó a " .. targetPlayer.Name)
        end
    elseif actionType == "Item" then
        -- Lógica para añadir a un inventario global o dar una herramienta
        print("[SERVIDOR] " .. player.Name .. " recogió " .. prompt.ObjectText)
        
        -- Destruimos el objeto del mapa para que nadie más lo recoja
        if prompt.Parent then
            prompt.Parent:Destroy()
        end
    end
end)