local EndgameSequence = {}

function EndgameSequence.Run(context, player, prompt, panel, modeloPuerta)
    local log = context.Logger and context.Logger:WithTag("Endgame")
    if log then
        log:Info(player.Name .. " alcanzo la salida")
    end

    context.DoorAnimator.OpenDoor(context, panel, modeloPuerta)

    prompt.Enabled = false
    context.EventEndGame:FireClient(player)
    task.wait(context.GameConstants.Endgame.CinematicTimeSeconds)
    player:Kick("¡Gracias por jugar la Beta del Capítulo 1!")
end

return EndgameSequence
