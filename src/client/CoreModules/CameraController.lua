local CameraController = {}

local cameraYaw = 0
local CAMERA_SENSITIVITY = 0.003
local CAMERA_LAG = 0.15
local cameraCFrame = workspace.CurrentCamera.CFrame

function CameraController:ProcessMouseMovement(deltaX)
    cameraYaw -= deltaX * CAMERA_SENSITIVITY
end

function CameraController:GetYaw()
    return cameraYaw
end

function CameraController:Update(hrpPosition)
    local camera = workspace.CurrentCamera
    
    local desiredCameraCFrame = 
        CFrame.new(hrpPosition) *
        CFrame.Angles(0, cameraYaw, 0) *
        CFrame.new(0, 2, 6)

    cameraCFrame = cameraCFrame:Lerp(desiredCameraCFrame, CAMERA_LAG)
    camera.CFrame = cameraCFrame
end

return CameraController