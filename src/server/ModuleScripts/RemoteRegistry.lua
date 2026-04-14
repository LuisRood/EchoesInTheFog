local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local RemoteRegistry = {}
local reloadLockByPlayer = {}

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

function RemoteRegistry:RegisterEquipEndpoint(inventoryManager, equipmentManager, weaponStateManager)
    local remoteFunction = getOrCreateRemoteFunction("EquiparItem")

    remoteFunction.OnServerInvoke = function(player, itemName)
        return equipmentManager:EquipItem(player, itemName, inventoryManager, weaponStateManager)
    end

    return remoteFunction
end

function RemoteRegistry:RegisterWeaponEndpoints(inventoryManager, weaponStateManager, weaponCombatManager, playerStateManager)
    local getStatus = getOrCreateRemoteFunction("ObtenerEstadoArma")
    local reloadWeapon = getOrCreateRemoteFunction("RecargarArma")
    local fireWeapon = getOrCreateRemoteFunction("DispararArma")
    local reloadDebounce = GameConstants.Weapons.ReloadDebounceSeconds or 0.2

    local function canUseWeapon(player)
        if not playerStateManager or not playerStateManager.GetState then
            return true
        end

        return playerStateManager:GetState(player) ~= "Abatido"
    end

    getStatus.OnServerInvoke = function(player, weaponName)
        if not canUseWeapon(player) then
            return false, "No disponible mientras estas abatido"
        end
        return weaponStateManager:GetWeaponStatus(player, weaponName, inventoryManager)
    end

    reloadWeapon.OnServerInvoke = function(player, weaponName)
        if not canUseWeapon(player) then
            return false, "No disponible mientras estas abatido"
        end

        if reloadLockByPlayer[player.UserId] then
            return false, "Recarga en progreso"
        end

        reloadLockByPlayer[player.UserId] = true
        task.delay(reloadDebounce, function()
            reloadLockByPlayer[player.UserId] = nil
        end)

        return weaponStateManager:ReloadWeapon(player, weaponName, inventoryManager)
    end

    fireWeapon.OnServerInvoke = function(player, shotOrigin, shotDirection)
        if not canUseWeapon(player) then
            return false, "No disponible mientras estas abatido"
        end
        return weaponCombatManager:FireWeapon(player, shotOrigin, shotDirection, weaponStateManager, inventoryManager)
    end

    return getStatus, reloadWeapon, fireWeapon
end

function RemoteRegistry:ClearPlayer(player)
    reloadLockByPlayer[player.UserId] = nil
end

return RemoteRegistry
