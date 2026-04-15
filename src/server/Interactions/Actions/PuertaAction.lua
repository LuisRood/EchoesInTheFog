local PuertaAction = {}

local function esPuertaFinal(context, prompt, modeloPuerta)
    return prompt.Name == context.PromptActionTypes.PuertaFinal
        or modeloPuerta:GetAttribute(context.AttributeNames.EsPuertaFinal) == true
end

function PuertaAction.Handle(context, prompt, player)
    local log = context.Logger and context.Logger:WithTag("Action.Door")
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
            if log then log:Debug("Puerta bloqueada para " .. player.Name .. ": requiere " .. requiereLlave) end

            local sonidoBloqueo = panel:FindFirstChild("SonidoBloqueado")
            if sonidoBloqueo then
                sonidoBloqueo:Play()
            end

            prompt.ActionText = "Bloqueada"
            task.wait(context.GameConstants.Door.BlockedWaitSeconds)
            prompt.ActionText = "Abrir"
            modeloPuerta:SetAttribute(lockAttribute, false)
            return
        else
            if log then log:Debug("Puerta desbloqueada con llave " .. requiereLlave) end
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
        if log then log:Debug(player.Name .. " cierra puerta") end
        context.DoorAnimator.CloseDoor(context, panel, modeloPuerta)
        prompt.ActionText = "Abrir"
    else
        if log then log:Debug(player.Name .. " abre puerta") end
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
