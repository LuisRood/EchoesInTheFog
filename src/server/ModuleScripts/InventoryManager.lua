local InventoryManager = {}

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

function InventoryManager:AddItem(player, itemName, amount)
    amount = amount or 1
    local inventario = obtenerOCrearInventario(player)
    
    local item = inventario:FindFirstChild(itemName)
    if item then
        item.Value = item.Value + amount
    else
        local nuevoItem = Instance.new("IntValue")
        nuevoItem.Name = itemName
        nuevoItem.Value = amount
        nuevoItem.Parent = inventario
    end
    print("[INVENTARIO] Recogiste: " .. amount .. "x " .. itemName)
end

function InventoryManager:HasItem(player, itemName)
    local inventario = player:FindFirstChild("Inventario")
    if inventario then
        local item = inventario:FindFirstChild(itemName)
        return item ~= nil and item.Value > 0
    end
    return false
end

return InventoryManager