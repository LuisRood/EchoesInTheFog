local PuertaFinalAction = {}

function PuertaFinalAction.Handle(context, prompt, player)
    local panel = prompt.Parent
    local modeloPuerta = panel and panel.Parent

    if modeloPuerta then
        context.EndgameSequence.Run(context, player, prompt, panel, modeloPuerta)
    end
end

return PuertaFinalAction
