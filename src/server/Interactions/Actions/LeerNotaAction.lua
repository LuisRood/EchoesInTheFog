local LeerNotaAction = {}

function LeerNotaAction.Handle(context, prompt, player)
    local log = context.Logger and context.Logger:WithTag("Action.Note")
    local notePart = prompt.Parent
    if not notePart then
        return
    end

    local textoDeLaNota = notePart:GetAttribute(context.AttributeNames.TextoLore)

    if textoDeLaNota then
        if log then log:Debug("Enviando nota a " .. player.Name) end
        context.EventShowNotes:FireClient(player, textoDeLaNota)
    else
        if log then log:Warn("Nota sin atributo TextoLore") end
    end
end

return LeerNotaAction
