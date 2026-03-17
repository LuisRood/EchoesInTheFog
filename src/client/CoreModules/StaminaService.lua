local StaminaService = {};
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

--private variables (Encapsulamiento)
local MAX_STAMINA = GameConstants.Client.Stamina.Max
local currentStamina = MAX_STAMINA
local STAMINA_DRAIN_RATE = GameConstants.Client.Stamina.DrainRate
local STAMINA_REGEN_RATE = GameConstants.Client.Stamina.RegenRate
local EXHAUSTION_LIMIT = GameConstants.Client.Stamina.ExhaustionLimit
local isExhausted = false

--Public metod for update every frame
function StaminaService:Update(dt, isRunning, isMoving)
    if isRunning and isMoving and not isExhausted then
        currentStamina = math.clamp(currentStamina - (STAMINA_DRAIN_RATE * dt),0,MAX_STAMINA)
        if currentStamina == 0 then
            isExhausted = true
        end
    else
        currentStamina = math.clamp(currentStamina + (STAMINA_REGEN_RATE * dt),0,MAX_STAMINA)
        if isExhausted and currentStamina >= EXHAUSTION_LIMIT then
            isExhausted = false
        end
    end
end

--Getters

function StaminaService:CanRun()
    return not isExhausted
end

function StaminaService:GetStamina()
    return currentStamina
end

return StaminaService