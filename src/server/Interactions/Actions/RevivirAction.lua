local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PlayerStates = require(SharedModules:WaitForChild("PlayerStates"))

local RevivirAction = {}

function RevivirAction.Handle(context, prompt, player)
    local log = context.Logger and context.Logger:WithTag("Action.Revive")
    local promptParent = prompt.Parent
    local targetCharacter = promptParent and promptParent.Parent
    if not targetCharacter or not targetCharacter:IsA("Model") then return end

    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

    if targetPlayer then
        if targetPlayer.UserId ~= player.UserId then
            context.PlayerStateManager:SetState(targetPlayer, PlayerStates.Healthy)
            if log then log:Info(player.Name .. " salvo a " .. targetPlayer.Name) end
        end
    else
        targetCharacter:SetAttribute(context.AttributeNames.Estado, PlayerStates.Healthy)
        prompt:Destroy()
        if log then log:Info(player.Name .. " salvo a un companero NPC") end
    end
end

return RevivirAction
