local RecogerObjetoAction = {}

function RecogerObjetoAction.Handle(context, prompt, player)
    local objetoFisico = prompt.Parent
    local nombreObjeto = objetoFisico:GetAttribute(context.AttributeNames.NombreItem)
    local descripcionObjeto = objetoFisico:GetAttribute(context.AttributeNames.DescripcionItem)

    if not nombreObjeto then return end

    local sePudoRecoger = context.InventoryManager:AddItem(player, nombreObjeto, 1, descripcionObjeto)

    if sePudoRecoger then
        objetoFisico:Destroy()
    else
        prompt.Enabled = false
        task.delay(1.5, function()
            prompt.Enabled = true
        end)
    end
end

return RecogerObjetoAction
