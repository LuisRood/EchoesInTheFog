local MovementController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local PlayerStates = require(SharedModules:WaitForChild("PlayerStates"))

local WALK_SPEED = GameConstants.Client.Movement.WalkSpeed
local RUN_SPEED = GameConstants.Client.Movement.RunSpeed
local ACCELERATION = GameConstants.Client.Movement.Acceleration
local DECELERATION = GameConstants.Client.Movement.Deceleration
local BODY_TURN_SPEED = GameConstants.Client.Movement.BodyTurnSpeed
local CRITICAL_HEALTH_THRESHOLD = GameConstants.Client.Movement.CriticalHealthThreshold
local CRITICAL_SPEED_MULTIPLIER = GameConstants.Client.Movement.CriticalSpeedMultiplier

local currentSpeed = 0

function MovementController:Update(dt, hrp, moveInput, strafeInput, isRunning, canRun, cameraYaw)
    -- Leemos la maquina de estados del Servidor de revivir 
    local playerState = hrp.Parent:GetAttribute("Estado") or PlayerStates.Healthy
    if playerState == PlayerStates.Downed then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y,0)
        return
    end

    -- ==========================================
    -- ¡NUEVO! PENALIZACIÓN POR HERIDAS CRÍTICAS
    -- ==========================================
    local vidaActual = hrp.Parent:GetAttribute("VidaActual") or 100
    local estaMalHerida = vidaActual <= CRITICAL_HEALTH_THRESHOLD
    
    -- Definimos las velocidades base (ajusta los números a los que ya tenías)
    local velocidadCaminar = WALK_SPEED
    local velocidadCorrer = RUN_SPEED

    -- Si la vida es 30 o menos, cortamos la velocidad a la mitad
    if estaMalHerida then
        velocidadCaminar = velocidadCaminar * CRITICAL_SPEED_MULTIPLIER
        velocidadCorrer = velocidadCorrer * CRITICAL_SPEED_MULTIPLIER
        -- Opcional: Podríamos hacer que aquí la pantalla palpite rojo después
    end

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
            targetSpeed = velocidadCorrer
        else
            targetSpeed = velocidadCaminar
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