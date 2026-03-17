local Players = game:GetService("Players")

local RevivirAction = {}

function RevivirAction.Handle(context, prompt, player)
    local promptParent = prompt.Parent
    local targetCharacter = promptParent and promptParent.Parent
    if not targetCharacter or not targetCharacter:IsA("Model") then return end

    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

    if targetPlayer then
        if targetPlayer.UserId ~= player.UserId then
            context.PlayerStateManager:SetState(targetPlayer, "Sano")
            print("[SERVIDOR] " .. player.Name .. " salvó a " .. targetPlayer.Name)
        end
    else
        targetCharacter:SetAttribute(context.AttributeNames.Estado, "Sano")
        prompt:Destroy()
        print("[SERVIDOR] " .. player.Name .. " salvó a un Compañero NPC.")
    end
end

return RevivirAction
