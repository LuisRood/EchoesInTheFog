local CameraController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local cameraYaw = 0 -- Horizontal Axis
local cameraPitch = 0 --Vertical Axis
local CAMERA_SENSITIVITY = GameConstants.Client.Camera.Sensitivity
local CAMERA_LAG = GameConstants.Client.Camera.Lag
local cameraCFrame = workspace.CurrentCamera.CFrame
-- Maximum incline 60 degree up and 60 degree down
local MAX_PITCH = math.rad(GameConstants.Client.Camera.MaxPitchDegrees)
local MIN_PITCH = math.rad(GameConstants.Client.Camera.MinPitchDegrees)
local CAMERA_OFFSET = GameConstants.Client.Camera.Offset

function CameraController:ProcessMouseMovement(deltaX, deltaY)
    cameraYaw -= deltaX * CAMERA_SENSITIVITY
    cameraPitch -= deltaY * CAMERA_SENSITIVITY

    --NO COMPLETLY 360
    cameraPitch = math.clamp(cameraPitch, MIN_PITCH,MAX_PITCH)
end

function CameraController:GetYaw()
    return cameraYaw
end

function CameraController:Update(hrpPosition)
    local camera = workspace.CurrentCamera

    local desiredCameraCFrame = 
        CFrame.new(hrpPosition) *
        CFrame.Angles(0, cameraYaw, 0) * -- Horizontal
        CFrame.Angles(cameraPitch, 0, 0) * -- Vertical
        CFrame.new(CAMERA_OFFSET) -- Offset

    cameraCFrame = cameraCFrame:Lerp(desiredCameraCFrame, CAMERA_LAG)
    camera.CFrame = cameraCFrame
end

return CameraController