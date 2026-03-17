-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local TweenService = game:GetService("TweenService")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))
local InventoryManager = require(ModuleScripts:WaitForChild("InventoryManager"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventShowNotes = ReplicatedStorage:WaitForChild("EventoMostrarNota")
local EventEndGame = ReplicatedStorage:WaitForChild("EventoFinJuego")
-- ¡NUEVO! Creamos el "Endpoint" del inventario
local FuncObtenerInventario = Instance.new("RemoteFunction")
FuncObtenerInventario.Name = "ObtenerInventario"
FuncObtenerInventario.Parent = ReplicatedStorage

-- Le decimos al servidor qué hacer cuando un cliente llame a esta función
FuncObtenerInventario.OnServerInvoke = function(player)
    return InventoryManager:GetInventory(player)
end
print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

-- ==========================================
-- CONSTANTES Y CONFIGURACIÓN
-- ==========================================
local TWEEN_DOOR_DURATION = 2.5
local TWEEN_EASING_STYLE = Enum.EasingStyle.Sine
local TWEEN_EASING_DIRECTION = Enum.EasingDirection.InOut
local DOOR_ROTATION_DEGREES = 90
local DOOR_DISTANCE_THRESHOLD = 5
local BLOCKED_DOOR_WAIT = 2
local HEALTH_RESTORE = 50
local ENDGAME_CINEMATIC_TIME = 6

-- ==========================================
-- FUNCIONES AUXILIARES
-- ==========================================
local function abrirPuerta(panel, modeloPuerta)
    if not modeloPuerta then return false end

    local bisagra = modeloPuerta:FindFirstChild("Bisagra")
    if not bisagra then return false end
    
    -- Guardamos la posición original la primera vez
    if not modeloPuerta:GetAttribute("CFrameOriginal") then
        modeloPuerta:SetAttribute("CFrameOriginal", bisagra.CFrame)
    end
    
    local cframeBase = modeloPuerta:GetAttribute("CFrameOriginal")
    local estaAbierta = modeloPuerta:GetAttribute("EstaAbierta") or false

    -- Si ya está abierta, no hacer nada
    if estaAbierta then
        return true
    end
    
    local infoAnimacion = TweenInfo.new(
        TWEEN_DOOR_DURATION,
        TWEEN_EASING_STYLE,
        TWEEN_EASING_DIRECTION
    )
    
    local objetivoCFrame = cframeBase * CFrame.Angles(0, math.rad(DOOR_ROTATION_DEGREES), 0)

    local animacion = TweenService:Create(bisagra, infoAnimacion, {CFrame = objetivoCFrame})
    local sonidoRechinido = panel:FindFirstChild("SonidoRechinido")
    if sonidoRechinido then sonidoRechinido:Play() end
    
    animacion:Play()
    animacion.Completed:Wait()

    modeloPuerta:SetAttribute("EstaAbierta", true)
    return true
end

local function esPuertaFinal(prompt, modeloPuerta)
    return prompt.Name == "PuertaFinal"
        or modeloPuerta.Name == "PuertaFin"
        or modeloPuerta:GetAttribute("EsPuertaFinal") == true
end

local function ejecutarFinDeBeta(player, prompt, panel, modeloPuerta)
    print("[SERVIDOR] " .. player.Name .. " ha alcanzado la salida. Iniciando secuencia de fin.")

    abrirPuerta(panel, modeloPuerta)

    prompt.Enabled = false
    EventEndGame:FireClient(player)
    task.wait(ENDGAME_CINEMATIC_TIME)
    player:Kick("¡Gracias por jugar la Beta del Capítulo 1!")
end

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
                task.wait(BLOCKED_DOOR_WAIT)
                prompt.ActionText = "Abrir"
                return -- Cortamos la ejecución aquí, la puerta no se mueve
            else
                -- ¡Tiene la llave! Desbloqueamos la puerta permanentemente
                print("[SISTEMA] Puerta desbloqueada con: " .. requiereLlave)

                -- ==========================================
                -- ¡EL FIX! Descontamos la llave del inventario
                -- ==========================================
                InventoryManager:RemoveItem(player, requiereLlave, 1)
                -- Reproducimos el audio de éxito
                local sonidoDesbloqueo = panel:FindFirstChild("SonidoDesbloqueo")
                if sonidoDesbloqueo then sonidoDesbloqueo:Play() end
                
                -- Rompemos el candado lógico para futuras interacciones
                modeloPuerta:SetAttribute("RequiereLlave", nil)
            end
        end
        if bisagra then
            prompt.Enabled = false
            
            local estaAbierta = modeloPuerta:GetAttribute("EstaAbierta") or false
            
            if estaAbierta then
                -- CERRAR: Lógica de cierre (invertir rotación)
                if not modeloPuerta:GetAttribute("CFrameOriginal") then
                    modeloPuerta:SetAttribute("CFrameOriginal", bisagra.CFrame)
                end
                
                local cframeBase = modeloPuerta:GetAttribute("CFrameOriginal")
                local infoAnimacion = TweenInfo.new(
                    TWEEN_DOOR_DURATION,
                    TWEEN_EASING_STYLE,
                    TWEEN_EASING_DIRECTION
                )
                
                local animacion = TweenService:Create(bisagra, infoAnimacion, {CFrame = cframeBase})
                local sonidoRechinido = panel:FindFirstChild("SonidoRechinido")
                if sonidoRechinido then sonidoRechinido:Play() end
                animacion:Play()
                print("[SERVIDOR] " .. player.Name .. " está cerrando la puerta.")
                animacion.Completed:Wait()
                
                modeloPuerta:SetAttribute("EstaAbierta", false)
                prompt.ActionText = "Abrir"
            else
                -- ABRIR: Delegamos a la función auxiliar
                print("[SERVIDOR] " .. player.Name .. " está abriendo la puerta.")
                abrirPuerta(panel, modeloPuerta)

                if esPuertaFinal(prompt, modeloPuerta) then
                    ejecutarFinDeBeta(player, prompt, panel, modeloPuerta)
                    return
                end

                prompt.ActionText = "Cerrar"
            end
            
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
    -- ==========================================
    -- CONDICIÓN DE VICTORIA (FIN DE LA BETA)
    -- ==========================================
    elseif actionType == "PuertaFinal" then
        local panel = prompt.Parent
        local modeloPuerta = panel and panel.Parent

        if modeloPuerta then
            ejecutarFinDeBeta(player, prompt, panel, modeloPuerta)
        end
    -- ==========================================
    -- BOTIQUÍN / ITEMS DE CURACIÓN
    -- ==========================================
    elseif actionType == "Botiquin" then
        -- 1. Curamos al jugador con la cantidad configurada
        PlayerStateManager:Heal(player, HEALTH_RESTORE)
        
        -- 2. Imprimimos el log y destruimos el objeto físico para que nadie más lo use
        print("[SERVIDOR] " .. player.Name .. " recogió un Botiquín de Primeros Auxilios.")
        if prompt.Parent then
            prompt.Parent:Destroy()
        end 
    -- ==========================================
    -- RECOGER OBJETOS (Llaves, Munición, etc.)
    -- ==========================================
    elseif actionType == "RecogerObjeto" then
        local objetoFisico = prompt.Parent
        local nombreObjeto = objetoFisico:GetAttribute("NombreItem")
        local descripcionObjeto = objetoFisico:GetAttribute("DescripcionItem")

        if nombreObjeto then
            -- Intentamos meterlo a la mochila
            local sePudoRecoger = InventoryManager:AddItem(player, nombreObjeto, 1)
            
            if sePudoRecoger then
                -- Solo si entró a la mochila, lo borramos del mapa
                objetoFisico:Destroy() 
            else
                -- Si no cupo, se queda en el suelo y apagamos el prompt un ratito para no spamear
                prompt.Enabled = false
                task.delay(1.5, function() prompt.Enabled = true end)
            end
        end    
    -- ==========================================
    -- OBJETOS GENÉRICOS DEL MAPA
    -- ==========================================
    elseif actionType == "Item" then
        print("[SERVIDOR] " .. player.Name .. " recogió " .. prompt.ObjectText)
        
        -- Destruimos el objeto del mapa para que nadie más lo recoja
        if prompt.Parent then
            prompt.Parent:Destroy()
        end
    end
end)