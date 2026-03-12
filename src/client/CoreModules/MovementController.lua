local MovementController = {}

local WALK_SPEED = 10
local RUN_SPEED = 16
local ACCELERATION = 18
local DECELERATION = 22
local BODY_TURN_SPEED = 0.12

local currentSpeed = 0

function MovementController:Update(dt, hrp, moveInput, strafeInput, isRunning, canRun, cameraYaw)
    -- Rotación relativa a la cámara
    local camRotation = CFrame.Angles(0, cameraYaw, 0)
    local forward = Vector3.new(camRotation.LookVector.X, 0, camRotation.LookVector.Z).Unit
    local right = Vector3.new(camRotation.RightVector.X, 0, camRotation.RightVector.Z).Unit

    -- Input combinado
    local inputVector = (forward * moveInput) + (right * strafeInput)
    if inputVector.Magnitude > 0 then
        inputVector = inputVector.Unit
    end
    
    local isMoving = inputVector.Magnitude > 0.05

    -- Velocidad objetivo
    local targetSpeed = 0
    if isMoving then
        if isRunning and canRun then
            targetSpeed = RUN_SPEED
        else
            targetSpeed = WALK_SPEED
        end
    end

    -- Aceleración/Desaceleración
    if currentSpeed < targetSpeed then
        currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
    elseif currentSpeed > targetSpeed then
        currentSpeed = math.max(currentSpeed - DECELERATION * dt, targetSpeed)
    end

    -- Aplicar físicas
    if isMoving then
        hrp.AssemblyLinearVelocity = inputVector * currentSpeed + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        
        -- Rotación del cuerpo
        local targetCFrame = CFrame.new(hrp.Position, hrp.Position + forward)
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, BODY_TURN_SPEED)
    else
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
    end
end

return MovementController