local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local movementConfig = (GameConstants.Server and GameConstants.Server.MovementValidation) or {}
if movementConfig.Enabled == false then
    return
end

local MAX_SPEED = movementConfig.MaxSpeed or 25
local TOLERANCE_FACTOR = movementConfig.ToleranceFactor or 2.6
local GRACE_DISTANCE = movementConfig.GraceDistance or 2
local MAX_STRIKES = movementConfig.MaxStrikes or 3

local tracking = {}

local function resetTrackingByUserId(userId)
    tracking[userId] = {
        LastPosition = nil,
        LastTime = os.clock(),
        Strikes = 0,
    }
end

local function getTracking(player)
    local state = tracking[player.UserId]
    if not state then
        state = {
            LastPosition = nil,
            LastTime = os.clock(),
            Strikes = 0,
        }
        tracking[player.UserId] = state
    end
    return state
end

Players.PlayerAdded:Connect(function(player)
    resetTrackingByUserId(player.UserId)

    player.CharacterAdded:Connect(function()
        resetTrackingByUserId(player.UserId)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    tracking[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    resetTrackingByUserId(player.UserId)
    player.CharacterAdded:Connect(function()
        resetTrackingByUserId(player.UserId)
    end)
end

RunService.Heartbeat:Connect(function()
    local now = os.clock()

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            continue
        end

        local state = getTracking(player)
        local currentPos = hrp.Position
        local dt = now - (state.LastTime or now)

        if not state.LastPosition or dt <= 0 then
            state.LastPosition = currentPos
            state.LastTime = now
            continue
        end

        local distance = (currentPos - state.LastPosition).Magnitude
        local maxAllowed = (MAX_SPEED * dt * TOLERANCE_FACTOR) + GRACE_DISTANCE

        if distance > maxAllowed then
            state.Strikes += 1

            if state.Strikes >= MAX_STRIKES then
                hrp.CFrame = CFrame.new(state.LastPosition)
                hrp.AssemblyLinearVelocity = Vector3.zero
                state.Strikes = 0
            end
        else
            state.Strikes = math.max(state.Strikes - 1, 0)
            state.LastPosition = currentPos
        end

        state.LastTime = now
    end
end)