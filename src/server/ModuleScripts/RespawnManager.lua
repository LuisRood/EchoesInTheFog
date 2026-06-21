local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local AttributeNames = require(SharedModules:WaitForChild("AttributeNames"))

local RespawnManager = {}

local SANITY_BYPASS_SECONDS = 1

function RespawnManager:Execute(player)
    local character = player.Character
    if not character then
        return false
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    local savedCheckpoint = player:GetAttribute("UltimoCheckpoint") or character:GetAttribute("UltimoCheckpoint")
    character:SetAttribute("UltimoCheckpoint", savedCheckpoint)
    character:SetAttribute(AttributeNames.MovementSanityBypassUntil, os.clock() + SANITY_BYPASS_SECONDS)

    if typeof(savedCheckpoint) == "CFrame" then
        rootPart.CFrame = savedCheckpoint
    else
        rootPart.CFrame = CFrame.new(0, 5, 0)
    end

    return true
end

return RespawnManager
