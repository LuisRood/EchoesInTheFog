local CameraController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local state = {
    cameraYaw = 0,
    cameraPitch = 0,
    cameraCFrame = workspace.CurrentCamera.CFrame,
}
local CAMERA_SENSITIVITY = GameConstants.Client.Camera.Sensitivity
local CAMERA_LAG = GameConstants.Client.Camera.Lag
-- Maximum incline 60 degree up and 60 degree down
local MAX_PITCH = math.rad(GameConstants.Client.Camera.MaxPitchDegrees)
local MIN_PITCH = math.rad(GameConstants.Client.Camera.MinPitchDegrees)
local CAMERA_OFFSET = GameConstants.Client.Camera.Offset

function CameraController:Reset()
    state.cameraYaw = 0
    state.cameraPitch = 0
    state.cameraCFrame = workspace.CurrentCamera.CFrame
end

function CameraController:ProcessMouseMovement(deltaX, deltaY)
    state.cameraYaw -= deltaX * CAMERA_SENSITIVITY
    state.cameraPitch -= deltaY * CAMERA_SENSITIVITY

    --NO COMPLETLY 360
    state.cameraPitch = math.clamp(state.cameraPitch, MIN_PITCH,MAX_PITCH)
end

function CameraController:GetYaw()
    return state.cameraYaw
end

function CameraController:Update(hrpPosition)
    local camera = workspace.CurrentCamera

    local desiredCameraCFrame = 
        CFrame.new(hrpPosition) *
        CFrame.Angles(0, state.cameraYaw, 0) * -- Horizontal
        CFrame.Angles(state.cameraPitch, 0, 0) * -- Vertical
        CFrame.new(CAMERA_OFFSET) -- Offset

    state.cameraCFrame = state.cameraCFrame:Lerp(desiredCameraCFrame, CAMERA_LAG)
    camera.CFrame = state.cameraCFrame
end

return CameraController