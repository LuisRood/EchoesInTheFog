local BotiquinAction = {}

function BotiquinAction.Handle(context, prompt, player)
    context.PlayerStateManager:Heal(player, context.GameConstants.Player.HealthRestore)

    print("[SERVIDOR] " .. player.Name .. " recogió un Botiquín de Primeros Auxilios.")
    if prompt.Parent then
        prompt.Parent:Destroy()
    end
end

return BotiquinAction
