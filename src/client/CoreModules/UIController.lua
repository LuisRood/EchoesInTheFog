local UIController = {}
local Players = game:GetService("Players")

local UIPath = script.Parent:WaitForChild("UI")
local InventoryUIController = require(UIPath:WaitForChild("InventoryUIController"))
local NotesUIController = require(UIPath:WaitForChild("NotesUIController"))
local EndgameUIController = require(UIPath:WaitForChild("EndgameUIController"))
local HealthHUDController = require(UIPath:WaitForChild("HealthHUDController"))

-- ==========================================
-- INICIALIZACIÓN DEL CLIENTE (Init)
-- ==========================================
function UIController:Init(character)
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
end

return UIController