local LeerNotaAction = {}

function LeerNotaAction.Handle(context, prompt, player)
    local textoDeLaNota = prompt.Parent:GetAttribute(context.AttributeNames.TextoLore)

    if textoDeLaNota then
        print("[SERVIDOR] Enviando nota a la pantalla de " .. player.Name)
        context.EventShowNotes:FireClient(player, textoDeLaNota)
    else
        print("ERROR: Esta nota no tiene el atributo 'TextoLore'")
    end
end

return LeerNotaAction
