local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local InventoryUIController = {}

local FuncObtenerInventario = ReplicatedStorage:WaitForChild("ObtenerInventario")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local ACTION_TOGGLE_INVENTORY = "EITF_ToggleInventory"

local function construirMenuInventario(hudParent)
    local menu = Instance.new("Frame")
    menu.Name = "MenuInventario"
    menu.Size = UDim2.new(0.6, 0, 0.6, 0)
    menu.Position = UDim2.new(0.2, 0, 0.2, 0)
    menu.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
    menu.BackgroundTransparency = 0.1
    menu.Visible = false
    menu.Parent = hudParent

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0.15, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "I N V E N T A R I O"
    titulo.TextColor3 = Color3.new(0.8, 0, 0)
    titulo.Font = Enum.Font.Oswald
    titulo.TextScaled = true
    titulo.Parent = menu

    local contenedorItems = Instance.new("ScrollingFrame")
    contenedorItems.Name = "ContenedorItems"
    contenedorItems.Size = UDim2.new(0.9, 0, 0.8, 0)
    contenedorItems.Position = UDim2.new(0.05, 0, 0.15, 0)
    contenedorItems.BackgroundTransparency = 1
    contenedorItems.ScrollBarThickness = 6
    contenedorItems.Parent = menu

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.3, 0, 0.25, 0)
    grid.CellPadding = UDim2.new(0.03, 0, 0.03, 0)
    grid.Parent = contenedorItems

    return menu, contenedorItems
end

local function actualizarInventarioVisual(contenedorItems, inventarioDatos)
    for _, hijo in ipairs(contenedorItems:GetChildren()) do
        if hijo:IsA("Frame") then
            hijo:Destroy()
        end
    end

    for nombreItem, cantidad in pairs(inventarioDatos) do
        local infoItem = ItemDatabase[nombreItem] or {Descripcion = "Objeto misterioso."}

        local tarjeta = Instance.new("Frame")
        tarjeta.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        tarjeta.Parent = contenedorItems

        local textoNombre = Instance.new("TextLabel")
        textoNombre.Size = UDim2.new(1, 0, 0.3, 0)
        textoNombre.BackgroundTransparency = 1
        textoNombre.TextColor3 = Color3.new(1, 1, 1)
        textoNombre.TextScaled = true
        textoNombre.Text = nombreItem .. " (x" .. cantidad .. ")"
        textoNombre.Parent = tarjeta

        local textoDesc = Instance.new("TextLabel")
        textoDesc.Size = UDim2.new(0.9, 0, 0.6, 0)
        textoDesc.Position = UDim2.new(0.05, 0, 0.35, 0)
        textoDesc.BackgroundTransparency = 1
        textoDesc.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        textoDesc.TextWrapped = true
        textoDesc.TextScaled = true
        textoDesc.Text = infoItem.Descripcion
        textoDesc.Parent = tarjeta
    end
end

function InventoryUIController:Init(hud)
    local menuInventario, contenedorItems = construirMenuInventario(hud)
    local inventarioAbierto = false

    local function alternarInventario()
        inventarioAbierto = not inventarioAbierto
        menuInventario.Visible = inventarioAbierto

        if inventarioAbierto then
            print("[CLIENTE] Solicitando datos del inventario al backend...")
            local inventarioDatos = FuncObtenerInventario:InvokeServer()
            actualizarInventarioVisual(contenedorItems, inventarioDatos)
        end
    end

    ContextActionService:UnbindAction(ACTION_TOGGLE_INVENTORY)
    ContextActionService:BindAction(
        ACTION_TOGGLE_INVENTORY,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                alternarInventario()
            end
            return Enum.ContextActionResult.Pass
        end,
        true,
        Enum.KeyCode.Tab,
        Enum.KeyCode.ButtonY
    )
    ContextActionService:SetTitle(ACTION_TOGGLE_INVENTORY, "Inv")
    ContextActionService:SetPosition(ACTION_TOGGLE_INVENTORY, GameConstants.Client.Controls.MobileButtons.InventoryPosition)

end

return InventoryUIController
