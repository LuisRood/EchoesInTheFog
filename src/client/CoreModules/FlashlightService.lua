local FlashlightService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local toggleRemote = nil
local lightObject = nil
local isOn = false
local lastToggleTime = 0
local TOGGLE_DEBOUNCE_SECONDS = 0.2
local FLICKER_CHANCE = GameConstants.Client.Flashlight.FlickerChance

function FlashlightService:Init(character)
    local hrp = character:WaitForChild("HumanoidRootPart")

    for _, objeto in ipairs(character:GetDescendants()) do
        if objeto:IsA("Accessory") then
            local handle = objeto:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.CastShadow = false
            end
        end
    end

    toggleRemote = ReplicatedStorage:WaitForChild("ToggleFlashlight")
    lightObject = hrp:WaitForChild("PocketFlashlight", 5)

    isOn = character:GetAttribute("FlashlightOn") == true

    character:GetAttributeChangedSignal("FlashlightOn"):Connect(function()
        isOn = character:GetAttribute("FlashlightOn") == true
        if lightObject then
            if isOn then
                lightObject.Brightness = GameConstants.Client.Flashlight.MaxBrightness
            else
                lightObject.Brightness = 0
            end
        end
    end)
end

function FlashlightService:Toggle()
    local now = os.clock()
    if now - lastToggleTime < TOGGLE_DEBOUNCE_SECONDS then
        return
    end
    lastToggleTime = now

    if toggleRemote then
        toggleRemote:FireServer()
    end
end

function FlashlightService:Update(dt)
    if not isOn or not lightObject then
        return
    end

    if math.random() < FLICKER_CHANCE then
        lightObject.Brightness = math.random() * GameConstants.Client.Flashlight.FlickerDropMax
    else
        lightObject.Brightness = math.clamp(
            lightObject.Brightness + (GameConstants.Client.Flashlight.RecoverRate * dt),
            0,
            GameConstants.Client.Flashlight.MaxBrightness
        )
    end
end

return FlashlightService
