local InventoryManager = {}
-- ItemDatabase vive en ReplicatedStorage/Shared/ModuleScripts (src/shared/ModuleScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))

local playerInventories = {} -- Tabla para almacenar los inventarios de cada jugador

-- Función privada (Lazy Initialization)
local function obtenerOCrearInventario(player)
    local inventario = player:FindFirstChild("Inventario")
    if not inventario then
        -- Si no existe, la creamos en este preciso instante
        inventario = Instance.new("Folder")
        inventario.Name = "Inventario"
        inventario.Parent = player
        print("[SISTEMA] Carpeta de Inventario creada para " .. player.Name)
    end
    return inventario
end

-- ==========================================
-- AGREGAR OBJETO (Con validación de MaxStack)
-- ==========================================
-- ¡Actualizamos la función para recibir itemDescription!
function InventoryManager:AddItem(player, itemName, amount, itemDescription)
    if not playerInventories[player.UserId] then
        playerInventories[player.UserId] = {}
    end

    local inventory = playerInventories[player.UserId]
    local currentAmount = inventory[itemName] or 0
    local itemData = ItemDatabase[itemName]

    -- ==========================================
    -- INYECCIÓN DINÁMICA DE OBJETOS CLAVE
    -- ==========================================
    if not itemData then
        -- Lo registramos en la base de datos en tiempo de ejecución
        itemData = {
            Tipo = "ObjetoClave",
            MaxStack = 1,
            Descripcion = itemDescription or "Un objeto misterioso." -- Fallback por si olvidas ponerle descripción en Studio
        }
        -- ¡Magia! Lo guardamos en el diccionario maestro para que la UI lo pueda leer después
        ItemDatabase[itemName] = itemData
        
        print("[INVENTARIO] Registrado dinámicamente: " .. itemName .. " - " .. itemData.Descripcion)
    end

    -- 2. Validar límite de capacidad
    local limiteGramos = itemData.MaxStack or 99 
    
    if currentAmount + amount > limiteGramos then
        print("[INVENTARIO] " .. player.Name .. " no puede cargar más " .. itemName .. ". Inventario lleno.")
        return false
    end

    -- 3. Si pasa las validaciones, lo agregamos
    inventory[itemName] = currentAmount + amount
    print("[INVENTARIO] " .. player.Name .. " guardó " .. itemName .. " (" .. inventory[itemName] .. "/" .. limiteGramos .. ")")
    
    return true
end

-- ==========================================
-- CONSULTAR OBJETO (Para llaves o armas)
-- ==========================================
function InventoryManager:HasItem(player, itemName)
    local inventory = playerInventories[player.UserId]
    if not inventory then return false end
    
    return (inventory[itemName] or 0) > 0
end

-- ==========================================
-- CONSUMIR OBJETO (Curarse o disparar)
-- ==========================================
function InventoryManager:RemoveItem(player, itemName, amount)
    local inventory = playerInventories[player.UserId]
    if not inventory then return false end
    
    local currentAmount = inventory[itemName] or 0
    
    if currentAmount >= amount then
        inventory[itemName] = currentAmount - amount
        print("[INVENTARIO] " .. player.Name .. " usó " .. amount .. " " .. itemName .. ". Restantes: " .. inventory[itemName])
        return true
    end
    
    return false
end

return InventoryManager