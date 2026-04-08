local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteRegistry = {}

local function getOrCreateRemoteFunction(name)
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing then
        if existing:IsA("RemoteFunction") then
            return existing
        end
        error("[REMOTES] Ya existe un objeto con nombre '" .. name .. "' y no es RemoteFunction")
    end

    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = name
    remoteFunction.Parent = ReplicatedStorage
    return remoteFunction
end

function RemoteRegistry:RegisterInventoryEndpoint(inventoryManager)
    local remoteFunction = getOrCreateRemoteFunction("ObtenerInventario")

    remoteFunction.OnServerInvoke = function(player)
        return inventoryManager:GetInventory(player)
    end

    return remoteFunction
end

function RemoteRegistry:RegisterEquipEndpoint(inventoryManager, equipmentManager)
    local remoteFunction = getOrCreateRemoteFunction("EquiparItem")

    remoteFunction.OnServerInvoke = function(player, itemName)
        return equipmentManager:EquipItem(player, itemName, inventoryManager)
    end

    return remoteFunction
end

return RemoteRegistry
