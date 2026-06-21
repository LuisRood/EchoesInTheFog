local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local InputController = {}

local moveInput = 0
local strafeInput = 0
local isHoldingShift = false
local digitalMoveInput = 0
local digitalTurnInput = 0

local keyForward = false
local keyBackward = false
local keyTurnLeft = false
local keyTurnRight = false
local keyStrafeLeft = false
local keyStrafeRight = false

local shoulderStrafeLeft = false
local shoulderStrafeRight = false

local gamepadMoveY = 0
local gamepadStrafeX = 0
local gamepadLook = Vector2.zero

local rightLookTouches = {}
local beganConnection = nil
local endedConnection = nil
local changedConnection = nil

local flashlightCallback
local mouseMoveCallback
local reloadCallback
local fireCallback

local ACTION_RUN = "EITF_Run"
local ACTION_FLASHLIGHT = "EITF_Flashlight"
local ACTION_RELOAD = "EITF_Reload"
local ACTION_FIRE = "EITF_Fire"

local controlsConfig = GameConstants.Client.Controls
local STICK_DEADZONE = controlsConfig.StickDeadzone
local KEYBOARD_TURN_RATE = math.rad(controlsConfig.KeyboardTurnRateDegPerSec)
local GAMEPAD_TURN_RATE = math.rad(controlsConfig.GamepadTurnRateDegPerSec)
local GAMEPAD_LOOK_RATE = math.rad(controlsConfig.GamepadLookRateDegPerSec)

local function applyDeadzone(value)
    if math.abs(value) < STICK_DEADZONE then
        return 0
    end
    return value
end

local function recomputeDigitalAxes()
    local forwardValue = (keyForward and 1 or 0) + (keyBackward and -1 or 0)
    local strafeValue = (keyStrafeRight and 1 or 0) + (keyStrafeLeft and -1 or 0)
    local turnValue = (keyTurnRight and 1 or 0) + (keyTurnLeft and -1 or 0)

    digitalMoveInput = math.clamp(forwardValue, -1, 1)
    strafeInput = math.clamp(strafeValue, -1, 1)
    digitalTurnInput = math.clamp(turnValue, -1, 1)
end

local function isGamepadConnected()
    local connectedPads = UserInputService:GetConnectedGamepads()
    for _, gamepad in ipairs(connectedPads) do
        if gamepad == Enum.UserInputType.Gamepad1 then
            return true
        end
    end
    return false
end

local function pollGamepadAxes()
    gamepadMoveY = 0
    gamepadStrafeX = 0
    gamepadLook = Vector2.zero

    for _, state in ipairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
        if state.KeyCode == Enum.KeyCode.Thumbstick1 then
            gamepadMoveY = applyDeadzone(state.Position.Y)
            gamepadStrafeX = applyDeadzone(state.Position.X)
        elseif state.KeyCode == Enum.KeyCode.Thumbstick2 then
            gamepadLook = Vector2.new(
                applyDeadzone(state.Position.X),
                applyDeadzone(state.Position.Y)
            )
        end
    end
end

local function onRunAction(_, state)
    if state == Enum.UserInputState.Begin then
        isHoldingShift = true
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        isHoldingShift = false
    end
    return Enum.ContextActionResult.Pass
end

local function onFlashlightAction(_, state)
    if state == Enum.UserInputState.Begin and flashlightCallback then
        flashlightCallback()
    end
    return Enum.ContextActionResult.Pass
end

local function onReloadAction(_, state)
    if state == Enum.UserInputState.Begin and reloadCallback then
        reloadCallback()
    end
    return Enum.ContextActionResult.Pass
end

local function onFireAction(_, state)
    if state == Enum.UserInputState.Begin and fireCallback then
        fireCallback()
    end
    return Enum.ContextActionResult.Pass
end

local function updateMobileMoveFromHumanoid()
    if not UserInputService.TouchEnabled then
        return
    end

    local player = Players.LocalPlayer
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if not humanoid or not camera then
        return
    end

    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude < 0.001 then
        moveInput = 0
        strafeInput = 0
        return
    end

    local camLook = camera.CFrame.LookVector
    local camRight = camera.CFrame.RightVector
    local flatForward = Vector3.new(camLook.X, 0, camLook.Z)
    local flatRight = Vector3.new(camRight.X, 0, camRight.Z)

    if flatForward.Magnitude < 0.001 or flatRight.Magnitude < 0.001 then
        return
    end

    flatForward = flatForward.Unit
    flatRight = flatRight.Unit

    moveInput = math.clamp(moveDir:Dot(flatForward), -1, 1)
    strafeInput = math.clamp(moveDir:Dot(flatRight), -1, 1)
end

function InputController:Init(onFlashlightToggle, onMouseMove, onReload, onFire)
    flashlightCallback = onFlashlightToggle
    mouseMoveCallback = onMouseMove
    reloadCallback = onReload
    fireCallback = onFire

    if beganConnection then
        beganConnection:Disconnect()
        beganConnection = nil
    end
    if endedConnection then
        endedConnection:Disconnect()
        endedConnection = nil
    end
    if changedConnection then
        changedConnection:Disconnect()
        changedConnection = nil
    end

    moveInput = 0
    strafeInput = 0
    isHoldingShift = false
    digitalMoveInput = 0
    digitalTurnInput = 0

    keyForward = false
    keyBackward = false
    keyTurnLeft = false
    keyTurnRight = false
    keyStrafeLeft = false
    keyStrafeRight = false

    shoulderStrafeLeft = false
    shoulderStrafeRight = false

    gamepadMoveY = 0
    gamepadStrafeX = 0
    gamepadLook = Vector2.zero

    ContextActionService:UnbindAction(ACTION_RUN)
    ContextActionService:UnbindAction(ACTION_FLASHLIGHT)
    ContextActionService:UnbindAction(ACTION_RELOAD)
    ContextActionService:UnbindAction(ACTION_FIRE)

    ContextActionService:BindAction(ACTION_RUN, onRunAction, true, Enum.KeyCode.ButtonX)
    ContextActionService:SetTitle(ACTION_RUN, "Correr")
    ContextActionService:SetPosition(ACTION_RUN, controlsConfig.MobileButtons.RunPosition)

    ContextActionService:BindAction(ACTION_FLASHLIGHT, onFlashlightAction, true, Enum.KeyCode.DPadUp)
    ContextActionService:SetTitle(ACTION_FLASHLIGHT, "Luz")
    ContextActionService:SetPosition(ACTION_FLASHLIGHT, controlsConfig.MobileButtons.FlashlightPosition)

    ContextActionService:BindAction(ACTION_RELOAD, onReloadAction, true, Enum.KeyCode.DPadDown)
    ContextActionService:SetTitle(ACTION_RELOAD, "Rec")
    ContextActionService:SetPosition(ACTION_RELOAD, controlsConfig.MobileButtons.ReloadPosition)

    ContextActionService:BindAction(ACTION_FIRE, onFireAction, true, Enum.KeyCode.ButtonR2)
    ContextActionService:SetTitle(ACTION_FIRE, "Fuego")
    ContextActionService:SetPosition(ACTION_FIRE, controlsConfig.MobileButtons.FirePosition)

    beganConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
            return
        end

        if input.KeyCode == Enum.KeyCode.W then
            keyForward = true
        elseif input.KeyCode == Enum.KeyCode.S then
            keyBackward = true
        elseif input.KeyCode == Enum.KeyCode.A then
            keyStrafeLeft = true
        elseif input.KeyCode == Enum.KeyCode.D then
            keyStrafeRight = true
        elseif input.KeyCode == Enum.KeyCode.Left then
            keyTurnLeft = true
        elseif input.KeyCode == Enum.KeyCode.Right then
            keyTurnRight = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            isHoldingShift = true
        elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
            shoulderStrafeLeft = true
        elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
            shoulderStrafeRight = true
        elseif input.KeyCode == Enum.KeyCode.F and flashlightCallback then
            flashlightCallback()
        elseif input.KeyCode == Enum.KeyCode.R and reloadCallback then
            reloadCallback()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and fireCallback then
            fireCallback()
        end

        recomputeDigitalAxes()
    end)

    endedConnection = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
            if input.KeyCode == Enum.KeyCode.W then
                keyForward = false
            else
                keyBackward = false
            end
        elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
            if input.KeyCode == Enum.KeyCode.A then
                keyStrafeLeft = false
            else
                keyStrafeRight = false
            end
        elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right then
            if input.KeyCode == Enum.KeyCode.Left then
                keyTurnLeft = false
            else
                keyTurnRight = false
            end
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            isHoldingShift = false
        elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
            shoulderStrafeLeft = false
        elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
            shoulderStrafeRight = false
        end

        recomputeDigitalAxes()
    end)

    changedConnection = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and mouseMoveCallback then
            mouseMoveCallback(input.Delta.X, input.Delta.Y)
        elseif input.UserInputType == Enum.UserInputType.Touch and mouseMoveCallback then
            local camera = workspace.CurrentCamera
            if not camera then
                return
            end
            local viewport = camera.ViewportSize
            if viewport.X <= 0 then
                return
            end

            local minX = viewport.X * controlsConfig.MobileLookAreaMinX
            if input.Position.X >= minX then
                rightLookTouches[input] = true
                mouseMoveCallback(
                    input.Delta.X * controlsConfig.MobileLookSensitivityMultiplier,
                    input.Delta.Y * controlsConfig.MobileLookSensitivityMultiplier
                )
            elseif rightLookTouches[input] then
                rightLookTouches[input] = nil
            end
        end
    end)
end

function InputController:Update(dt)
    local usingGamepad = isGamepadConnected()

    local activeMove = digitalMoveInput
    local activeStrafe = strafeInput
    local activeTurn = digitalTurnInput

    if usingGamepad then
        pollGamepadAxes()
        activeMove = gamepadMoveY
        activeTurn = 0
        activeStrafe = gamepadStrafeX
    end

    if shoulderStrafeLeft or shoulderStrafeRight then
        local shoulder = (shoulderStrafeRight and 1 or 0) + (shoulderStrafeLeft and -1 or 0)
        activeStrafe = math.clamp(shoulder, -1, 1)
    end

    if UserInputService.TouchEnabled then
        updateMobileMoveFromHumanoid()
        activeMove = moveInput
        activeStrafe = strafeInput
        activeTurn = digitalTurnInput
    end

    local yawDelta = 0
    if math.abs(activeTurn) > 0 then
        local turnRate = usingGamepad and GAMEPAD_TURN_RATE or KEYBOARD_TURN_RATE
        yawDelta = -(turnRate / GameConstants.Client.Camera.Sensitivity) * activeTurn * dt
    end

    if yawDelta ~= 0 and mouseMoveCallback then
        mouseMoveCallback(yawDelta, 0)
    end

    if usingGamepad and mouseMoveCallback and gamepadLook.Magnitude > 0 then
        local lookDeltaX = (GAMEPAD_LOOK_RATE / GameConstants.Client.Camera.Sensitivity) * gamepadLook.X * dt
        local lookDeltaY = -(GAMEPAD_LOOK_RATE / GameConstants.Client.Camera.Sensitivity) * gamepadLook.Y * dt
        mouseMoveCallback(lookDeltaX, lookDeltaY)
    end

    moveInput = activeMove
    strafeInput = activeStrafe
end

function InputController:GetState()
    return moveInput, strafeInput, isHoldingShift
end

return InputController
