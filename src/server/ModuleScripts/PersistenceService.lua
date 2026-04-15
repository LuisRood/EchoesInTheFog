local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local PersistenceService = {}

local log = Logger:WithTag("Persistence")
local persistenceConfig = (((GameConstants or {}).Server or {}).Persistence) or {}
local enabledInStudio = persistenceConfig.EnabledInStudio == true
local isStudio = RunService:IsStudio()
local isEnabled = persistenceConfig.Enabled == true and (not isStudio or enabledInStudio)
local storeName = persistenceConfig.StoreName or "EchoesInTheFog_PlayerData_V1"
local keyPrefix = persistenceConfig.KeyPrefix or "player_"
local dataStore = isEnabled and DataStoreService:GetDataStore(storeName) or nil

if persistenceConfig.Enabled == true and isStudio and not enabledInStudio then
    log:Info("Persistencia deshabilitada en Studio (EnabledInStudio=false)")
end

local function getPlayerKey(player)
    return keyPrefix .. tostring(player.UserId)
end

local function serializeCFrame(cf)
    if typeof(cf) ~= "CFrame" then
        return nil
    end

    local x, y, z,
        r00, r01, r02,
        r10, r11, r12,
        r20, r21, r22 = cf:GetComponents()

    return {
        x, y, z,
        r00, r01, r02,
        r10, r11, r12,
        r20, r21, r22,
    }
end

local function deserializeCFrame(raw)
    if typeof(raw) ~= "table" or #raw ~= 12 then
        return nil
    end

    return CFrame.new(
        raw[1], raw[2], raw[3],
        raw[4], raw[5], raw[6],
        raw[7], raw[8], raw[9],
        raw[10], raw[11], raw[12]
    )
end

function PersistenceService:IsEnabled()
    return isEnabled
end

function PersistenceService:LoadPlayerData(player)
    if not isEnabled or not dataStore then
        return {
            Inventory = {},
            WeaponStates = {},
            LastCheckpoint = nil,
        }
    end

    local key = getPlayerKey(player)
    local ok, result = pcall(function()
        return dataStore:GetAsync(key)
    end)

    if not ok then
        log:Warn("No se pudo cargar datos de " .. player.Name .. ": " .. tostring(result))
        return {
            Inventory = {},
            WeaponStates = {},
            LastCheckpoint = nil,
        }
    end

    if typeof(result) ~= "table" then
        return {
            Inventory = {},
            WeaponStates = {},
            LastCheckpoint = nil,
        }
    end

    return {
        Inventory = result.Inventory or {},
        WeaponStates = result.WeaponStates or {},
        LastCheckpoint = deserializeCFrame(result.LastCheckpoint),
    }
end

function PersistenceService:SavePlayerData(player, payload)
    if not isEnabled or not dataStore then
        return true
    end

    payload = payload or {}
    local key = getPlayerKey(player)
    local serialized = {
        Inventory = payload.Inventory or {},
        WeaponStates = payload.WeaponStates or {},
        LastCheckpoint = serializeCFrame(payload.LastCheckpoint),
        UpdatedAt = os.time(),
    }

    local ok, err = pcall(function()
        dataStore:UpdateAsync(key, function()
            return serialized
        end)
    end)

    if not ok then
        log:Warn("No se pudo guardar datos de " .. player.Name .. ": " .. tostring(err))
        return false
    end

    return true
end

return PersistenceService