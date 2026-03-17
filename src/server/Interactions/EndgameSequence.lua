local EndgameSequence = {}

function EndgameSequence.Run(context, player, prompt, panel, modeloPuerta)
    print("[SERVIDOR] " .. player.Name .. " ha alcanzado la salida. Iniciando secuencia de fin.")

    context.DoorAnimator.OpenDoor(context, panel, modeloPuerta)

    prompt.Enabled = false
    context.EventEndGame:FireClient(player)
    task.wait(context.GameConstants.Endgame.CinematicTimeSeconds)
    player:Kick("¡Gracias por jugar la Beta del Capítulo 1!")
end

return EndgameSequence
