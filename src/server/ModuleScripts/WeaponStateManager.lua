local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))

local WeaponStateManager = {}

local playerWeaponStates = {}

local function normalizeItemName(itemName)
    if typeof(itemName) ~= "string" then
        return itemName
    end

    local trimmed = string.match(itemName, "^%s*(.-)%s*$")
    if trimmed == "" then
        return itemName
    end

    if ItemDatabase[trimmed] then
        return trimmed
    end

    local lower = string.lower(trimmed)
    for key in pairs(ItemDatabase) do
        if string.lower(key) == lower then
            return key
        end
    end

    return trimmed
end

local function isFirearm(itemName)
    local data = ItemDatabase[itemName]
    return data and data.Tipo == "Fuego"
end

local function getOrCreatePlayerState(player)
    local userId = player.UserId
    if not playerWeaponStates[userId] then
        playerWeaponStates[userId] = {}
    end

    return playerWeaponStates[userId]
end

local function getWeaponData(itemName)
    local data = ItemDatabase[itemName]
    if not data then
        return nil
    end

    if data.Tipo ~= "Fuego" then
        return nil
    end

    return data
end

local function getEquippedWeaponTool(player)
    local character = player.Character
    if not character then
        return nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and isFirearm(child.Name) then
            return child
        end
    end

    return nil
end

function WeaponStateManager:EnsureWeaponState(player, weaponName)
    weaponName = normalizeItemName(weaponName)
    local data = getWeaponData(weaponName)
    if not data then
        return nil
    end

    local stateByWeapon = getOrCreatePlayerState(player)
    local state = stateByWeapon[weaponName]
    if not state then
        state = {
            AmmoInMag = data.Capacidad or 0,
            MagCapacity = data.Capacidad or 0,
            AmmoType = data.UsaMunicion,
        }
        stateByWeapon[weaponName] = state
    end

    return state
end

function WeaponStateManager:SyncToolAttributes(player, weaponName, tool)
    local state = self:EnsureWeaponState(player, weaponName)
    if not state or not tool then
        return
    end

    tool:SetAttribute("AmmoInMag", state.AmmoInMag)
    tool:SetAttribute("MagCapacity", state.MagCapacity)
    tool:SetAttribute("AmmoType", state.AmmoType)
end

function WeaponStateManager:GetWeaponStatus(player, weaponName, inventoryManager)
    weaponName = normalizeItemName(weaponName)

    if not weaponName or weaponName == "" then
        local equipped = getEquippedWeaponTool(player)
        if not equipped then
            return false, "No hay arma equipada"
        end
        weaponName = equipped.Name
    end

    local state = self:EnsureWeaponState(player, weaponName)
    if not state then
        return false, "El item no es arma de fuego"
    end

    local reserve = 0
    if state.AmmoType and inventoryManager and inventoryManager.GetItemCount then
        reserve = inventoryManager:GetItemCount(player, state.AmmoType)
    end

    return true, {
        WeaponName = weaponName,
        AmmoInMag = state.AmmoInMag,
        MagCapacity = state.MagCapacity,
        AmmoType = state.AmmoType,
        ReserveAmmo = reserve,
    }
end

function WeaponStateManager:ReloadWeapon(player, weaponName, inventoryManager)
    local ok, statusOrMessage = self:GetWeaponStatus(player, weaponName, inventoryManager)
    if not ok then
        return false, statusOrMessage
    end

    local status = statusOrMessage
    if status.MagCapacity <= 0 then
        return false, "Arma sin cargador"
    end

    local missing = status.MagCapacity - status.AmmoInMag
    if missing <= 0 then
        return false, "Cargador ya completo"
    end

    if not status.AmmoType then
        return false, "Arma sin tipo de municion"
    end

    local reserve = status.ReserveAmmo or 0
    if reserve <= 0 then
        return false, "Sin municion en inventario"
    end

    local toLoad = math.min(missing, reserve)
    local consumed = inventoryManager:RemoveItem(player, status.AmmoType, toLoad)
    if not consumed then
        return false, "No se pudo consumir municion"
    end

    local state = self:EnsureWeaponState(player, status.WeaponName)
    state.AmmoInMag += toLoad

    local equippedTool = getEquippedWeaponTool(player)
    if equippedTool and equippedTool.Name == status.WeaponName then
        self:SyncToolAttributes(player, status.WeaponName, equippedTool)
    end

    local _, updated = self:GetWeaponStatus(player, status.WeaponName, inventoryManager)
    return true, updated
end

function WeaponStateManager:ConsumeBullet(player, weaponName)
    weaponName = normalizeItemName(weaponName)
    local state = self:EnsureWeaponState(player, weaponName)
    if not state then
        return false, "El item no es arma de fuego"
    end

    if state.AmmoInMag <= 0 then
        return false, "Sin balas en cargador"
    end

    state.AmmoInMag -= 1

    local equippedTool = getEquippedWeaponTool(player)
    if equippedTool and equippedTool.Name == weaponName then
        self:SyncToolAttributes(player, weaponName, equippedTool)
    end

    return true, state.AmmoInMag
end

function WeaponStateManager:ClearPlayer(player)
    playerWeaponStates[player.UserId] = nil
end

return WeaponStateManager