-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local TweenService = game:GetService("TweenService")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))
local InventoryManager = require(ModuleScripts:WaitForChild("InventoryManager"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventShowNotes = ReplicatedStorage:WaitForChild("EventoMostrarNota")

print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

-- El servidor también escucha los ProximityPrompts, pero aquí ejecutamos la lógica real
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local actionType = prompt.Name

    if actionType == "Revivir" then
        local promptParent = prompt.Parent
        local targetCharacter = promptParent and promptParent.Parent
        if not targetCharacter or not targetCharacter:IsA("Model") then return end

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
    -- NUEVO: RECOGER OBJETOS (Llaves, Munición, etc.)
    -- ==========================================
    elseif actionType == "RecogerObjeto" then
        -- Leemos el nombre del item desde un Atributo del objeto físico
        local nombreObjeto = prompt.Parent:GetAttribute("NombreItem")
        
        if nombreObjeto then
            InventoryManager:AddItem(player, nombreObjeto, 1)
            prompt.Parent:Destroy() -- El objeto desaparece del mapa
        end    
    -- ==========================================
    -- ¡NUEVA LÓGICA DE PUERTAS TIPO SILENT HILL!
    -- ==========================================
    elseif actionType == "Puerta" then
        local panel = prompt.Parent
        local modeloPuerta = panel.Parent
        local bisagra = modeloPuerta:FindFirstChild("Bisagra")

        -- Verificamos si la puerta tiene un candado lógico
        local requiereLlave = modeloPuerta:GetAttribute("RequiereLlave")
        
        -- Si requiere llave y no está vacía la variable, validamos el inventario
        if requiereLlave and requiereLlave ~= "" then
            if not InventoryManager:HasItem(player, requiereLlave) then
                print("[SISTEMA] Puerta cerrada. Necesitas: " .. requiereLlave)
                -- Reproducimos el audio de forcejeo
                local sonidoBloqueo = panel:FindFirstChild("SonidoBloqueado")
                if sonidoBloqueo then 
                    print("¡ÉXITO! Encontré el audio. Intentando reproducir...")
                    sonidoBloqueo:Play() 
                else
                    print("ERROR FATAL: El código buscó en el Panel, pero el SonidoBloqueado no está ahí.")
                end
                prompt.ActionText = "Bloqueada"
                task.wait(2)
                prompt.ActionText = "Abrir"
                return -- Cortamos la ejecución aquí, la puerta no se mueve
            else
                -- ¡Tiene la llave! Desbloqueamos la puerta permanentemente
                print("[SISTEMA] Puerta desbloqueada con: " .. requiereLlave)
                
                -- Reproducimos el audio de éxito
                local sonidoDesbloqueo = panel:FindFirstChild("SonidoDesbloqueo")
                if sonidoDesbloqueo then sonidoDesbloqueo:Play() end
                
                -- Rompemos el candado lógico para futuras interacciones
                modeloPuerta:SetAttribute("RequiereLlave", nil)
            end
        end
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
            local sonidoRechinido = panel:FindFirstChild("SonidoRechinido")
            if sonidoRechinido then sonidoRechinido:Play() end
            animacion:Play()
            print("[SERVIDOR] " .. player.Name .. " está " .. (estaAbierta and "cerrando" or "abriendo") .. " la puerta.")
            
            animacion.Completed:Wait()
            
            -- 3. Invertimos el estado y reactivamos
            modeloPuerta:SetAttribute("EstaAbierta", not estaAbierta)
            prompt.ActionText = estaAbierta and "Abrir" or "Cerrar"
            prompt.Enabled = true
        end
    -- ==========================================
    -- NUEVO: SISTEMA DE NOTAS Y LORE
    -- ==========================================
    elseif actionType == "LeerNota" then
        -- Extraemos el texto que escribiste en las propiedades del objeto físico
        local textoDeLaNota = prompt.Parent:GetAttribute("TextoLore")
        
        if textoDeLaNota then
            print("[SERVIDOR] Enviando nota a la pantalla de " .. player.Name)
            
            -- ¡LA MAGIA! Disparamos el evento a través del puente, solo hacia este jugador
            EventShowNotes:FireClient(player, textoDeLaNota)
        else
            print("ERROR: Esta nota no tiene el atributo 'TextoLore'")
        end    
    --Botequines
    elseif actionType == "Botiquin" then
        -- 1. Curamos al jugador (le damos 50 puntos de vida)
        PlayerStateManager:Heal(player, 50)
        
        -- 2. Imprimimos el log y destruimos el objeto físico para que nadie más lo use
        print("[SERVIDOR] " .. player.Name .. " recogió un Botiquín de Primeros Auxilios.")
        if prompt.Parent then prompt.Parent:Destroy() 
    end
    --Items    
    elseif actionType == "Item" then
        -- Lógica para añadir a un inventario global o dar una herramienta
        print("[SERVIDOR] " .. player.Name .. " recogió " .. prompt.ObjectText)
        
        -- Destruimos el objeto del mapa para que nadie más lo recoja
        if prompt.Parent then
            prompt.Parent:Destroy()
        end
    end
end)