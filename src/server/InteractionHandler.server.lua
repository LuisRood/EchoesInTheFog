-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local TweenService = game:GetService("TweenService")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))

print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

-- El servidor también escucha los ProximityPrompts, pero aquí ejecutamos la lógica real
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local actionType = prompt.Name

    if actionType == "Revivir" then
        local targetCharacter = prompt.Parent.Parent
        local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(targetCharacter)
        
        if targetPlayer then
            -- VALIDACIÓN JUGADOR REAL: No revivirse a sí mismo
            if targetPlayer.UserId ~= player.UserId then
                PlayerStateManager:SetState(targetPlayer, "Sano")
                print("[SERVIDOR] " .. player.Name .. " salvó a " .. targetPlayer.Name)
            end
        else
            -- VALIDACIÓN NPC/DUMMY: No tiene un Player asociado
            targetCharacter:SetAttribute("Estado", "Sano")
            prompt:Destroy() -- Quitamos el prompt porque ya lo salvamos
            print("[SERVIDOR] " .. player.Name .. " salvó a un Compañero NPC.")
        end
    -- ==========================================
    -- ¡NUEVA LÓGICA DE PUERTAS TIPO SILENT HILL!
    -- ==========================================
    elseif actionType == "Puerta" then
        local panel = prompt.Parent
        local modeloPuerta = panel.Parent
        local bisagra = modeloPuerta:FindFirstChild("Bisagra")
        
        if bisagra then
            prompt.Enabled = false 
            
            -- 1. Guardamos la posición original la primera vez que se toca (Estado Base Absoluto)
            if not modeloPuerta:GetAttribute("CFrameOriginal") then
                modeloPuerta:SetAttribute("CFrameOriginal", bisagra.CFrame)
            end
            
            local cframeBase = modeloPuerta:GetAttribute("CFrameOriginal")
            local estaAbierta = modeloPuerta:GetAttribute("EstaAbierta") or false
            
            local infoAnimacion = TweenInfo.new(
                2.5, -- Tiempo lento de suspenso
                Enum.EasingStyle.Sine, 
                Enum.EasingDirection.InOut
            )
            
            -- 2. Calculamos la rotación basados siempre en el CFrame original
            local objetivoCFrame
            if estaAbierta then
                -- Para cerrar, volvemos exactamente a la posición guardada
                objetivoCFrame = cframeBase 
            else
                -- Para abrir, tomamos la posición guardada y le sumamos 90 grados
                objetivoCFrame = cframeBase * CFrame.Angles(0, math.rad(90), 0) 
            end
            
            local animacion = TweenService:Create(bisagra, infoAnimacion, {CFrame = objetivoCFrame})
            animacion:Play()
            print("[SERVIDOR] " .. player.Name .. " está " .. (estaAbierta and "cerrando" or "abriendo") .. " la puerta.")
            
            animacion.Completed:Wait()
            
            -- 3. Invertimos el estado y reactivamos
            modeloPuerta:SetAttribute("EstaAbierta", not estaAbierta)
            prompt.ActionText = estaAbierta and "Abrir" or "Cerrar"
            prompt.Enabled = true
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