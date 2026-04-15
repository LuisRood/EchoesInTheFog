local InventoryManager = {}
-- ItemDatabase vive en ReplicatedStorage/Shared/ModuleScripts (src/shared/ModuleScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))
local ItemTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemTypes"))
local ItemUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemUtils"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local playerInventories = {} -- Tabla para almacenar los inventarios de cada jugador
local dynamicItems = {}
local log = Logger:WithTag("Inventory")
local itemDatabase = ItemDatabase

local function normalizarNombreItem(itemName)
    return ItemUtils.NormalizeItemName(itemName, itemDatabase, dynamicItems)
end

local function getItemData(itemName)
    return itemDatabase[itemName] or dynamicItems[itemName]
end

-- Función privada (Lazy Initialization)
local function obtenerOCrearInventario(player)
    local inventario = player:FindFirstChild("Inventario")
    if not inventario then
        -- Si no existe, la creamos en este preciso instante
        inventario = Instance.new("Folder")
        inventario.Name = "Inventario"
        inventario.Parent = player
        log:Debug("Carpeta Inventario creada para " .. player.Name)
    end
    return inventario
end

-- ==========================================
-- AGREGAR OBJETO (Con validación de MaxStack)
-- ==========================================
-- ¡Actualizamos la función para recibir itemDescription!
function InventoryManager:AddItem(player, itemName, amount, itemDescription)
    itemName = normalizarNombreItem(itemName)

    if not playerInventories[player.UserId] then
        playerInventories[player.UserId] = {}
    end

    local inventory = playerInventories[player.UserId]
    local currentAmount = inventory[itemName] or 0
    local itemData = getItemData(itemName)

    -- ==========================================
    -- INYECCIÓN DINÁMICA DE OBJETOS CLAVE
    -- ==========================================
    if not itemData then
        itemData = {
            Tipo = ItemTypes.KeyItem,
            MaxStack = 1,
            Descripcion = itemDescription or "Un objeto misterioso." -- Fallback por si olvidas ponerle descripción en Studio
        }
        -- Nunca mutamos ItemDatabase compartido: los dinámicos viven solo en servidor.
        dynamicItems[itemName] = itemData
        
        log:Info("Item dinamico registrado: " .. itemName)
    end

    -- 2. Validar límite de capacidad
    local limiteGramos = itemData.MaxStack or 99 
    
    if currentAmount + amount > limiteGramos then
        log:Debug(player.Name .. " sin capacidad para " .. itemName)
        return false
    end

    -- 3. Si pasa las validaciones, lo agregamos
    inventory[itemName] = currentAmount + amount
    log:Debug(player.Name .. " guardo " .. itemName .. " (" .. inventory[itemName] .. "/" .. limiteGramos .. ")")
    
    return true
end

-- ==========================================
-- CONSULTAR OBJETO (Para llaves o armas)
-- ==========================================
function InventoryManager:HasItem(player, itemName)
    itemName = normalizarNombreItem(itemName)

    local inventory = playerInventories[player.UserId]
    if not inventory then return false end
    
    return (inventory[itemName] or 0) > 0
end

function InventoryManager:GetItemCount(player, itemName)
    itemName = normalizarNombreItem(itemName)

    local inventory = playerInventories[player.UserId]
    if not inventory then
        return 0
    end

    return inventory[itemName] or 0
end

-- ==========================================
-- CONSUMIR OBJETO (Curarse o disparar)
-- ==========================================
function InventoryManager:RemoveItem(player, itemName, amount)
    itemName = normalizarNombreItem(itemName)

    local inventory = playerInventories[player.UserId]
    if not inventory then return false end
    
    local currentAmount = inventory[itemName] or 0
    
    if currentAmount >= amount then
        local nuevoTotal = currentAmount - amount

        -- Si llega a cero, eliminamos la clave para evitar "x0" en UI.
        if nuevoTotal <= 0 then
            inventory[itemName] = nil
        else
            inventory[itemName] = nuevoTotal
        end

        log:Debug(player.Name .. " uso " .. amount .. " " .. itemName .. ". Restantes: " .. tostring(inventory[itemName] or 0))
        return true
    end
    
    return false
end
-- ==========================================
-- OBTENER INVENTARIO (Endpoint para el Cliente)
-- ==========================================
function InventoryManager:GetInventory(player)
    local inventory = playerInventories[player.UserId] or {}
    local limpio = {}

    -- Mandamos al cliente solo entradas con cantidad positiva.
    for itemName, cantidad in pairs(inventory) do
        if cantidad and cantidad > 0 then
            limpio[itemName] = cantidad
        end
    end

    return limpio
end

function InventoryManager:GetItemData(itemName)
    itemName = normalizarNombreItem(itemName)
    return getItemData(itemName)
end

function InventoryManager:SetItemDatabase(customDatabase)
    if typeof(customDatabase) == "table" then
        itemDatabase = customDatabase
    end
end

function InventoryManager:GetSnapshot(player)
    local source = playerInventories[player.UserId] or {}
    local snapshot = {}
    for itemName, amount in pairs(source) do
        if amount and amount > 0 then
            snapshot[itemName] = amount
        end
    end
    return snapshot
end

function InventoryManager:ApplySnapshot(player, snapshot)
    playerInventories[player.UserId] = {}
    if typeof(snapshot) ~= "table" then
        return
    end

    for itemName, amount in pairs(snapshot) do
        if typeof(itemName) == "string" and typeof(amount) == "number" and amount > 0 then
            playerInventories[player.UserId][normalizarNombreItem(itemName)] = math.floor(amount)
        end
    end
end

function InventoryManager:ClearPlayer(player)
    playerInventories[player.UserId] = nil
end

return InventoryManager