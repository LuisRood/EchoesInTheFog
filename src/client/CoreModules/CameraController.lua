local CameraController = {}

local cameraYaw = 0 -- Horizontal Axis
local cameraPitch = 0 --Vertical Axis
local CAMERA_SENSITIVITY = 0.003
local CAMERA_LAG = 0.15
local cameraCFrame = workspace.CurrentCamera.CFrame
-- Maximum incline 60 degree up and 60 degree down
local MAX_PITCH = math.rad(60)
local MIN_PITCH = math.rad(-60)

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
        CFrame.new(0, 2, 6) -- Offset

    cameraCFrame = cameraCFrame:Lerp(desiredCameraCFrame, CAMERA_LAG)
    camera.CFrame = cameraCFrame
end

return CameraController