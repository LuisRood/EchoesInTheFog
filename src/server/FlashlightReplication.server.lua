local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local REMOTE_NAME = "ToggleFlashlight"
local TOGGLE_DEBOUNCE_SECONDS = 0.2
local lastToggleByPlayer = {}

local function getOrCreateToggleRemote()
    local existing = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
    if existing then
        if existing:IsA("RemoteEvent") then
            return existing
        end
        error("[FLASHLIGHT] Ya existe un objeto con nombre '" .. REMOTE_NAME .. "' y no es RemoteEvent")
    end

    local remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
    return remote
end

local function getOrCreateFlashlight(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local existing = hrp:FindFirstChild("PocketFlashlight")
    if existing and existing:IsA("SpotLight") then
        return existing
    end

    local light = Instance.new("SpotLight")
    light.Name = "PocketFlashlight"
    light.Brightness = 0
    light.Range = GameConstants.Client.Flashlight.Range
    light.Angle = GameConstants.Client.Flashlight.Angle
    light.Color = Color3.fromRGB(255, 240, 215)
    light.Shadows = true
    light.Parent = hrp
    return light
end

local function applyFlashlightState(character, enabled)
    local light = getOrCreateFlashlight(character)
    if not light then
        return
    end

    character:SetAttribute("FlashlightOn", enabled)
    light.Brightness = enabled and GameConstants.Client.Flashlight.MaxBrightness or 0
end

local function onCharacterAdded(character)
    character:SetAttribute("FlashlightOn", false)
    getOrCreateFlashlight(character)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

Players.PlayerRemoving:Connect(function(player)
    lastToggleByPlayer[player.UserId] = nil
end)

local toggleRemote = getOrCreateToggleRemote()

toggleRemote.OnServerEvent:Connect(function(player)
    local now = os.clock()
    local lastToggle = lastToggleByPlayer[player.UserId] or 0
    if now - lastToggle < TOGGLE_DEBOUNCE_SECONDS then
        return
    end
    lastToggleByPlayer[player.UserId] = now

    local character = player.Character
    if not character then
        return
    end

    local current = character:GetAttribute("FlashlightOn") == true
    applyFlashlightState(character, not current)
end)
