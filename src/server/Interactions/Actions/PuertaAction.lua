local PuertaAction = {}

local function esPuertaFinal(context, prompt, modeloPuerta)
    return prompt.Name == context.PromptActionTypes.PuertaFinal
        or modeloPuerta:GetAttribute(context.AttributeNames.EsPuertaFinal) == true
end

function PuertaAction.Handle(context, prompt, player)
    local panel = prompt.Parent
    local modeloPuerta = panel.Parent
    local bisagra = modeloPuerta:FindFirstChild("Bisagra")
    local lockAttribute = context.AttributeNames.PuertaBloqueada

    if modeloPuerta:GetAttribute(lockAttribute) then
        return
    end

    modeloPuerta:SetAttribute(lockAttribute, true)

    local requiereLlave = modeloPuerta:GetAttribute(context.AttributeNames.RequiereLlave)

    if requiereLlave and requiereLlave ~= "" then
        if not context.InventoryManager:HasItem(player, requiereLlave) then
            print("[SISTEMA] Puerta cerrada. Necesitas: " .. requiereLlave)

            local sonidoBloqueo = panel:FindFirstChild("SonidoBloqueado")
            if sonidoBloqueo then
                print("¡ÉXITO! Encontré el audio. Intentando reproducir...")
                sonidoBloqueo:Play()
            else
                print("ERROR FATAL: El código buscó en el Panel, pero el SonidoBloqueado no está ahí.")
            end

            prompt.ActionText = "Bloqueada"
            task.wait(context.GameConstants.Door.BlockedWaitSeconds)
            prompt.ActionText = "Abrir"
            modeloPuerta:SetAttribute(lockAttribute, false)
            return
        else
            print("[SISTEMA] Puerta desbloqueada con: " .. requiereLlave)
            context.InventoryManager:RemoveItem(player, requiereLlave, 1)

            local sonidoDesbloqueo = panel:FindFirstChild("SonidoDesbloqueo")
            if sonidoDesbloqueo then sonidoDesbloqueo:Play() end

            modeloPuerta:SetAttribute(context.AttributeNames.RequiereLlave, nil)
        end
    end

    if not bisagra then
        modeloPuerta:SetAttribute(lockAttribute, false)
        return
    end

    prompt.Enabled = false

    local estaAbierta = modeloPuerta:GetAttribute(context.AttributeNames.EstaAbierta) or false

    if estaAbierta then
        print("[SERVIDOR] " .. player.Name .. " está cerrando la puerta.")
        context.DoorAnimator.CloseDoor(context, panel, modeloPuerta)
        prompt.ActionText = "Abrir"
    else
        print("[SERVIDOR] " .. player.Name .. " está abriendo la puerta.")
        context.DoorAnimator.OpenDoor(context, panel, modeloPuerta)

        if esPuertaFinal(context, prompt, modeloPuerta) then
            context.EndgameSequence.Run(context, player, prompt, panel, modeloPuerta)
            modeloPuerta:SetAttribute(lockAttribute, false)
            return
        end

        prompt.ActionText = "Cerrar"
    end

    prompt.Enabled = true
    modeloPuerta:SetAttribute(lockAttribute, false)
end

return PuertaAction
