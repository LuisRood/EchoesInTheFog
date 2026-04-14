local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))
local ItemTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemTypes"))

local CrosshairUIController = {}

local function isFirearmTool(instance)
    if not instance or not instance:IsA("Tool") then
        return false
    end

    local data = ItemDatabase[instance.Name]
    return data and data.Tipo == ItemTypes.Firearm
end

local function createCrosshair(hud)
    local root = Instance.new("Frame")
    root.Name = "Crosshair"
    root.Size = UDim2.new(0, 24, 0, 24)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.new(0.5, 0, 0.5, 0)
    root.BackgroundTransparency = 1
    root.Visible = false
    root.ZIndex = 20
    root.Parent = hud

    local function makeBar(name, size, position)
        local bar = Instance.new("Frame")
        bar.Name = name
        bar.Size = size
        bar.Position = position
        bar.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
        bar.BorderSizePixel = 0
        bar.ZIndex = 20
        bar.Parent = root
    end

    makeBar("Top", UDim2.new(0, 2, 0, 6), UDim2.new(0.5, -1, 0, 0))
    makeBar("Bottom", UDim2.new(0, 2, 0, 6), UDim2.new(0.5, -1, 1, -6))
    makeBar("Left", UDim2.new(0, 6, 0, 2), UDim2.new(0, 0, 0.5, -1))
    makeBar("Right", UDim2.new(0, 6, 0, 2), UDim2.new(1, -6, 0.5, -1))

    local dot = Instance.new("Frame")
    dot.Name = "CenterDot"
    dot.Size = UDim2.new(0, 2, 0, 2)
    dot.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    dot.BorderSizePixel = 0
    dot.ZIndex = 21
    dot.Parent = root

    return root
end

function CrosshairUIController:Init(character, hud)
    local crosshair = createCrosshair(hud)

    local function refreshVisibility()
        local visible = false
        for _, child in ipairs(character:GetChildren()) do
            if isFirearmTool(child) then
                visible = true
                break
            end
        end
        crosshair.Visible = visible
    end

    character.ChildAdded:Connect(function(child)
        if isFirearmTool(child) then
            refreshVisibility()
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if isFirearmTool(child) then
            refreshVisibility()
        end
    end)

    refreshVisibility()
end

return CrosshairUIController
