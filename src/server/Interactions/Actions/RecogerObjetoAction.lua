local RecogerObjetoAction = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))

function RecogerObjetoAction.Handle(context, prompt, player)
    local objetoFisico = prompt.Parent
    if not objetoFisico then
        return
    end

    local nombreObjeto = objetoFisico:GetAttribute(context.AttributeNames.NombreItem)
    local descripcionObjeto = objetoFisico:GetAttribute(context.AttributeNames.DescripcionItem)

    if not nombreObjeto then return end

    local itemData = ItemDatabase[nombreObjeto]
    local cantidadRecogida = (itemData and itemData.PickupAmount) or 1
    local sePudoRecoger = context.InventoryManager:AddItem(player, nombreObjeto, cantidadRecogida, descripcionObjeto)

    if sePudoRecoger then
        objetoFisico:Destroy()
    else
        prompt.Enabled = false
        task.delay(1.5, function()
            if prompt.Parent then
                prompt.Enabled = true
            end
        end)
    end
end

return RecogerObjetoAction
