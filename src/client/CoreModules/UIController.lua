local UIController = {}
local Players = game:GetService("Players")

local UIPath = script.Parent:WaitForChild("UI", 10)

if not UIPath then
    warn("[UI] No se encontro la carpeta UI en CoreModules despues de esperar 10s.")
    return UIController
end

local function listChildrenNames(parent)
    local names = {}
    for _, child in ipairs(parent:GetChildren()) do
        table.insert(names, child.Name)
    end
    table.sort(names)
    return table.concat(names, ", ")
end

local function requireModule(moduleName)
    local moduleScript = UIPath:WaitForChild(moduleName, 10)
    if not moduleScript then
        warn("[UI] Falta el modulo " .. moduleName .. " dentro de CoreModules/UI. Hijos actuales: " .. listChildrenNames(UIPath))
        return nil
    end

    local ok, result = pcall(require, moduleScript)
    if not ok then
        warn("[UI] Error cargando " .. moduleName .. ": " .. tostring(result))
        return nil
    end

    return result
end

local InventoryUIController = requireModule("InventoryUIController")
local NotesUIController = requireModule("NotesUIController")
local EndgameUIController = requireModule("EndgameUIController")
local HealthHUDController = requireModule("HealthHUDController")
local CrosshairUIController = requireModule("CrosshairUIController")

-- ==========================================
-- INICIALIZACIÓN DEL CLIENTE (Init)
-- ==========================================
function UIController:Init(character)
    if not InventoryUIController or not NotesUIController or not EndgameUIController or not HealthHUDController or not CrosshairUIController then
        warn("[UI] No se pudo inicializar la UI completa por un modulo faltante o con error.")
        return
    end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- ==========================================
    -- ¡EL FIX! APAGAR LA INTERFAZ NATIVA DE ROBLOX
    -- ==========================================
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- Apaga el menú del martillo
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- Apaga el inventario feo de abajo

    local hud = playerGui:WaitForChild("HUD")

    InventoryUIController:Init(hud)
    NotesUIController:Init(hud)
    EndgameUIController:Init(hud)
    HealthHUDController:Init(character, hud)
    CrosshairUIController:Init(character, hud)
end

return UIController