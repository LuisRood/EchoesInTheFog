local ItemAction = {}

function ItemAction.Handle(_context, prompt, player)
    print("[SERVIDOR] " .. player.Name .. " recogió " .. prompt.ObjectText)

    if prompt.Parent then
        prompt.Parent:Destroy()
    end
end

return ItemAction
