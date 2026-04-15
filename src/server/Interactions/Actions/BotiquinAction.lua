local BotiquinAction = {}

function BotiquinAction.Handle(context, prompt, player)
    local log = context.Logger and context.Logger:WithTag("Action.Medkit")
    context.PlayerStateManager:Heal(player, context.GameConstants.Player.HealthRestore)

    if log then log:Info(player.Name .. " recogio un botiquin") end
    if prompt.Parent then
        prompt.Parent:Destroy()
    end
end

return BotiquinAction
