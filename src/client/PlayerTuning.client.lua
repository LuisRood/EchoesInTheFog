-- SERVICIOS DE ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- INYECCIÓN DE DEPENDENCIAS (Módulos)
local CoreModules = script.Parent:WaitForChild("CoreModules")
local CameraController = require(CoreModules:WaitForChild("CameraController"))
local MovementController = require(CoreModules:WaitForChild("MovementController"))
local StaminaService = require(CoreModules:WaitForChild("StaminaService"))
local FlashlightService = require(CoreModules:WaitForChild("FlashlightService"))
local InteractionService = require(CoreModules:WaitForChild("InteractionService"))
local RadioService = require(CoreModules:WaitForChild("RadioService"))

-- REFERENCIAS
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- SETUP INICIAL
humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
humanoid.AutoRotate = false
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
FlashlightService:Init(character) -- Linterna en el pecho
InteractionService:Init()
RadioService:Init(character)


-- ESTADO DEL INPUT
local moveInput = 0
local strafeInput = 0
local isHoldingShift = false

-- LISTENERS DE EVENTOS
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then moveInput = 1
    elseif input.KeyCode == Enum.KeyCode.S then moveInput = -1
    elseif input.KeyCode == Enum.KeyCode.A then strafeInput = -1
    elseif input.KeyCode == Enum.KeyCode.D then strafeInput = 1
    elseif input.KeyCode == Enum.KeyCode.LeftShift then isHoldingShift = true 
	elseif input.KeyCode == Enum.KeyCode.F then FlashlightService:Toggle() end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then moveInput = 0
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then strafeInput = 0
    elseif input.KeyCode == Enum.KeyCode.LeftShift then isHoldingShift = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        CameraController:ProcessMouseMovement(input.Delta.X, input.Delta.Y)
    end
end)

-- LOOP PRINCIPAL DE RENDERIZADO
RunService.RenderStepped:Connect(function(dt)
    local currentYaw = CameraController:GetYaw()
    local isTryingToMove = math.abs(moveInput) > 0 or math.abs(strafeInput) > 0
    
    -- 1. Actualizar Servicio de Stamina
    StaminaService:Update(dt, isHoldingShift, isTryingToMove)
    local canRun = StaminaService:CanRun()
    
    -- 2. Actualizar Físicas de Movimiento
    MovementController:Update(dt, hrp, moveInput, strafeInput, isHoldingShift, canRun, currentYaw)
    
    -- 3. Actualizar Render de Cámara
    CameraController:Update(hrp.Position)
	FlashlightService:Update(dt)
    RadioService:Update(hrp.Position)
end)