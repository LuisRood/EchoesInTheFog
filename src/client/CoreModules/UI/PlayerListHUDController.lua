local Players = game:GetService("Players")

local PlayerListHUDController = {}

local connections = {}

local function disconnectAll()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    table.clear(connections)
end

local function getDisplayName(player)
    if player.DisplayName and player.DisplayName ~= "" and player.DisplayName ~= player.Name then
        return player.DisplayName .. "  @" .. player.Name
    end

    return player.Name
end

local function createLabel(parent, name, text, size, position, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position or UDim2.new()
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(235, 245, 240)
    label.TextStrokeTransparency = 0.55
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Oswald
    label.TextScaled = true
    label.Parent = parent
    return label
end

local function createPanel(hud)
    local existing = hud:FindFirstChild("JugadoresConectados")
    if existing then
        existing:Destroy()
    end

    local panel = Instance.new("Frame")
    panel.Name = "JugadoresConectados"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Size = UDim2.new(0, 240, 0, 190)
    panel.Position = UDim2.new(1, -24, 0, 24)
    panel.BackgroundColor3 = Color3.fromRGB(3, 6, 7)
    panel.BackgroundTransparency = 0.22
    panel.BorderSizePixel = 0
    panel.Parent = hud

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(52, 185, 150)
    stroke.Thickness = 1
    stroke.Transparency = 0.45
    stroke.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = panel

    createLabel(panel, "Titulo", "JUGADORES", UDim2.new(0.58, 0, 0, 28), UDim2.new(0, 0, 0, 0), Color3.fromRGB(220, 245, 235))

    local count = createLabel(panel, "Conteo", "0", UDim2.new(0.42, 0, 0, 28), UDim2.new(0.58, 0, 0, 0), Color3.fromRGB(92, 230, 170))
    count.TextXAlignment = Enum.TextXAlignment.Right

    local list = Instance.new("Frame")
    list.Name = "Lista"
    list.BackgroundTransparency = 1
    list.Size = UDim2.new(1, 0, 1, -36)
    list.Position = UDim2.new(0, 0, 0, 36)
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    return panel, count, list
end

local function updateList(countLabel, list)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local players = Players:GetPlayers()
    table.sort(players, function(left, right)
        return string.lower(left.Name) < string.lower(right.Name)
    end)

    countLabel.Text = tostring(#players) .. " ONLINE"

    for index, player in ipairs(players) do
        local row = createLabel(
            list,
            "Jugador_" .. tostring(player.UserId),
            getDisplayName(player),
            UDim2.new(1, 0, 0, 22),
            nil,
            player == Players.LocalPlayer and Color3.fromRGB(92, 230, 170) or Color3.fromRGB(220, 230, 226)
        )
        row.LayoutOrder = index
    end
end

function PlayerListHUDController:Init(hud)
    disconnectAll()

    local _, countLabel, list = createPanel(hud)
    local function refresh()
        updateList(countLabel, list)
    end

    table.insert(connections, Players.PlayerAdded:Connect(refresh))
    table.insert(connections, Players.PlayerRemoving:Connect(refresh))

    refresh()
end

return PlayerListHUDController
