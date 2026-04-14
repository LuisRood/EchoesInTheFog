local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local ItemDatabase = require(SharedModules:WaitForChild("ItemDatabase"))
local ItemTypes = require(SharedModules:WaitForChild("ItemTypes"))

local WeaponCombatManager = {}

local lastShotByPlayer = {}

local function getFireConfig()
    local weapons = GameConstants.Weapons or {}
    return {
        MaxDistance = weapons.HitscanDistance or 180,
        Cooldown = weapons.FireCooldownSeconds or 0.12,
        MaxOriginOffset = weapons.MaxOriginOffsetFromHead or 20,
    }
end

local function findDamageableHumanoid(hitInstance)
    if not hitInstance then
        return nil
    end

    local model = hitInstance:FindFirstAncestorOfClass("Model")
    if not model then
        return nil
    end

    return model:FindFirstChildOfClass("Humanoid")
end

local function resolveShotOrigin(player, clientOrigin, maxOffset)
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    local fallback = head and head.Position or (character and character:GetPivot().Position) or Vector3.new(0, 0, 0)

    if typeof(clientOrigin) ~= "Vector3" then
        return fallback
    end

    if (clientOrigin - fallback).Magnitude > maxOffset then
        return fallback
    end

    return clientOrigin
end

function WeaponCombatManager:FireWeapon(player, shotOrigin, shotDirection, weaponStateManager, inventoryManager)
    local config = getFireConfig()

    local now = os.clock()
    local last = lastShotByPlayer[player.UserId] or 0
    if now - last < config.Cooldown then
        return false, "Demasiado rapido"
    end

    local okStatus, statusOrMessage = weaponStateManager:GetWeaponStatus(player, nil, inventoryManager)
    if not okStatus then
        return false, statusOrMessage
    end

    local status = statusOrMessage
    local weaponName = status.WeaponName
    local weaponData = ItemDatabase[weaponName]
    if not weaponData or weaponData.Tipo ~= ItemTypes.Firearm then
        return false, "No hay arma de fuego equipada"
    end

    if typeof(shotDirection) ~= "Vector3" or shotDirection.Magnitude <= 0.001 then
        return false, "Direccion de disparo invalida"
    end

    local okAmmo, ammoOrMessage = weaponStateManager:ConsumeBullet(player, weaponName)
    if not okAmmo then
        return false, ammoOrMessage
    end

    lastShotByPlayer[player.UserId] = now

    local direction = shotDirection.Unit
    local origin = resolveShotOrigin(player, shotOrigin, config.MaxOriginOffset)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character }

    local result = Workspace:Raycast(origin, direction * config.MaxDistance, params)

    local hitHumanoid = findDamageableHumanoid(result and result.Instance)
    local didDamage = false

    if hitHumanoid and hitHumanoid.Health > 0 and hitHumanoid.Parent ~= player.Character then
        hitHumanoid:TakeDamage(weaponData.Dano or 0)
        didDamage = true
    end

    local _, updatedStatus = weaponStateManager:GetWeaponStatus(player, weaponName, inventoryManager)

    return true, {
        WeaponName = weaponName,
        Hit = result ~= nil,
        DidDamage = didDamage,
        HitPartName = result and result.Instance and result.Instance.Name or nil,
        AmmoInMag = updatedStatus and updatedStatus.AmmoInMag or 0,
        MagCapacity = updatedStatus and updatedStatus.MagCapacity or (weaponData.Capacidad or 0),
        ReserveAmmo = updatedStatus and updatedStatus.ReserveAmmo or 0,
    }
end

function WeaponCombatManager:ClearPlayer(player)
    lastShotByPlayer[player.UserId] = nil
end

return WeaponCombatManager
