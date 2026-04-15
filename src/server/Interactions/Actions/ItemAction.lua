local ItemAction = {}

function ItemAction.Handle(context, prompt, player)
    local log = context.Logger and context.Logger:WithTag("Action.Item")
    if log then
        log:Debug(player.Name .. " recogio " .. tostring(prompt.ObjectText))
    end

    if prompt.Parent then
        prompt.Parent:Destroy()
    end
end

return ItemAction
