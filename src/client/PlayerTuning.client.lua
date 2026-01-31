-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- REFERENCIAS
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- CÁMARA
local cameraYaw = 0
local CAMERA_SENSITIVITY = 0.003
local cameraCFrame = camera.CFrame
local CAMERA_LAG = 0.15


-- BLOQUEAMOS CONTROL ARCADE
humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
humanoid.AutoRotate = false
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

-- INPUT
local moveInput = 0
local strafeInput = 0

-- VELOCIDAD
local currentSpeed = 0
local isRunning = false

-- CONFIGURACIÓN
local WALK_SPEED = 10
local RUN_SPEED = 16
local ACCELERATION = 18
local DECELERATION = 22
local BODY_TURN_SPEED = 0.12

-- INPUT MOVIMIENTO
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.W then
		moveInput = 1
	elseif input.KeyCode == Enum.KeyCode.S then
		moveInput = -1
	elseif input.KeyCode == Enum.KeyCode.A then
		strafeInput = -1
	elseif input.KeyCode == Enum.KeyCode.D then
		strafeInput = 1
	end
	
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
		moveInput = 0
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
		strafeInput = 0
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = false
	end
	
end)


UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		cameraYaw -= input.Delta.X * CAMERA_SENSITIVITY
	end
end)

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function(dt)

	-- ROTACIÓN BASE DE CÁMARA
	local camRotation = CFrame.Angles(0, cameraYaw, 0)
	local camCF = camRotation * CFrame.new(hrp.Position)

	-- DIRECCIONES RELATIVAS A LA CÁMARA
	local forward = Vector3.new(
		camRotation.LookVector.X,
		0,
		camRotation.LookVector.Z
	).Unit

	local right = Vector3.new(
		camRotation.RightVector.X,
		0,
		camRotation.RightVector.Z
	).Unit

	-- INPUT COMBINADO
	local inputVector =
		(forward * moveInput) +
		(right * strafeInput)

	if inputVector.Magnitude > 0 then
		inputVector = inputVector.Unit
	end

	-- APLICAMOS VELOCIDAD
	local maxAllowedSpeed = RUN_SPEED
	if isRunning and inputVector.Magnitude > 0 and inputVector.Z < 0 then
		maxAllowedSpeed = RUN_SPEED
	end

	local hasInput = inputVector.Magnitude > 0.05

	-- VELOCIDAD OBJETIVO
	local targetSpeed = 0

	if inputVector.Magnitude > 0 then
		if isRunning then
			targetSpeed = RUN_SPEED
		else
			targetSpeed = WALK_SPEED
		end
	end

	if currentSpeed < targetSpeed then
		currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
	elseif currentSpeed > targetSpeed then
		currentSpeed = math.max(currentSpeed - DECELERATION * dt, targetSpeed)
	end

	-- MOVIMIENTO FÍSICO
	if inputVector.Magnitude > 0 then
		hrp.AssemblyLinearVelocity =
			inputVector * currentSpeed +
			Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
	else
		hrp.AssemblyLinearVelocity =
			Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
	end

	-- ROTACIÓN DEL PERSONAJE (SIGUE CÁMARA)
	if inputVector.Magnitude > 0 then
		local targetCFrame = CFrame.new(hrp.Position, hrp.Position + forward)
		hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, BODY_TURN_SPEED)
	end


	-- CÁMARA SUAVIZADA
	local desiredCameraCFrame =
		CFrame.new(hrp.Position) *
		CFrame.Angles(0, cameraYaw, 0) *
		CFrame.new(0, 2, 6)

	cameraCFrame = cameraCFrame:Lerp(desiredCameraCFrame, CAMERA_LAG)
	camera.CFrame = cameraCFrame
	-- CÁMARA TERCERA PERSONA
	--camera.CFrame =
	--	CFrame.new(hrp.Position) *
	--	CFrame.Angles(0, cameraYaw, 0) *
	--	CFrame.new(0, 2, 6)

end)

