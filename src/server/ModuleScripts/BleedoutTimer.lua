local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PlayerStates = require(SharedModules:WaitForChild("PlayerStates"))

local BleedoutTimer = {}

local activeTokens = {}

local function destroyBleedoutUi(character)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local existing = hrp:FindFirstChild("RelojDesangrado")
    if existing then
        existing:Destroy()
    end
end

function BleedoutTimer:Stop(player)
    activeTokens[player.UserId] = (activeTokens[player.UserId] or 0) + 1

    local character = player.Character
    if character then
        destroyBleedoutUi(character)
    end
end

function BleedoutTimer:Start(player, seconds, onExpired)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not hrp then
        return
    end

    self:Stop(player)

    local token = activeTokens[player.UserId]

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RelojDesangrado"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 0.2, 0.2)
    label.TextScaled = true
    label.Font = Enum.Font.Creepster
    label.Text = tostring(seconds)
    label.Parent = billboard

    task.spawn(function()
        local remaining = seconds

        while remaining > 0 do
            if activeTokens[player.UserId] ~= token then
                return
            end

            if not character.Parent or character:GetAttribute("Estado") ~= PlayerStates.Downed then
                break
            end

            task.wait(1)
            remaining -= 1
            label.Text = tostring(remaining)
        end

        if activeTokens[player.UserId] ~= token then
            return
        end

        if billboard and billboard.Parent then
            billboard:Destroy()
        end

        if remaining <= 0 and character.Parent and character:GetAttribute("Estado") == PlayerStates.Downed then
            onExpired()
        end
    end)
end

return BleedoutTimer