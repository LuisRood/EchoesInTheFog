local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))

local EquipmentManager = {}

local function normalizarNombreItem(itemName)
    if typeof(itemName) ~= "string" then
        return itemName
    end

    local limpio = string.match(itemName, "^%s*(.-)%s*$")
    if limpio == "" then
        return itemName
    end

    if ItemDatabase[limpio] then
        return limpio
    end

    local lower = string.lower(limpio)
    for key in pairs(ItemDatabase) do
        if string.lower(key) == lower then
            return key
        end
    end

    return limpio
end

local function isWeaponItem(itemName)
    local itemData = ItemDatabase[itemName]
    if not itemData then
        return false
    end

    return itemData.Tipo == "Fuego" or itemData.Tipo == "Melee"
end

local function findToolTemplate(itemName)
    local toolsFolder = ServerStorage:FindFirstChild("Tools")
    if toolsFolder then
        local direct = toolsFolder:FindFirstChild(itemName)
        if direct and direct:IsA("Tool") then
            return direct
        end
    end

    local recursive = ServerStorage:FindFirstChild(itemName, true)
    if recursive and recursive:IsA("Tool") then
        return recursive
    end

    return nil
end

local function getToolFromContainers(itemName, character, backpack)
    local equipped = character and character:FindFirstChild(itemName)
    if equipped and equipped:IsA("Tool") then
        return equipped
    end

    local stored = backpack and backpack:FindFirstChild(itemName)
    if stored and stored:IsA("Tool") then
        return stored
    end

    return nil
end

local function clearOtherWeapons(character, backpack, keepName)
    local function clearIn(container)
        if not container then
            return
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and child.Name ~= keepName and isWeaponItem(child.Name) then
                child:Destroy()
            end
        end
    end

    clearIn(character)
    clearIn(backpack)
end

function EquipmentManager:EquipItem(player, itemName, inventoryManager, weaponStateManager)
    itemName = normalizarNombreItem(itemName)

    if typeof(itemName) ~= "string" or itemName == "" then
        return false, "Item invalido"
    end

    if not isWeaponItem(itemName) then
        return false, "Este item no se puede equipar"
    end

    if not inventoryManager:HasItem(player, itemName) then
        return false, "No tienes este item en inventario"
    end

    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then
        return false, "Jugador no listo para equipar"
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid no disponible"
    end

    local tool = getToolFromContainers(itemName, character, backpack)
    if not tool then
        local template = findToolTemplate(itemName)
        if not template then
            return false, "No existe Tool plantilla para " .. itemName
        end

        tool = template:Clone()
        tool.Parent = backpack
    end

    clearOtherWeapons(character, backpack, itemName)
    humanoid:EquipTool(tool)

    if weaponStateManager and weaponStateManager.EnsureWeaponState then
        weaponStateManager:EnsureWeaponState(player, itemName)
        weaponStateManager:SyncToolAttributes(player, itemName, tool)
    end

    return true, "Equipado"
end

return EquipmentManager