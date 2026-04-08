-- SERVICIOS DE ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- INYECCIÓN DE DEPENDENCIAS (Módulos)
local CoreModules = script.Parent:WaitForChild("CoreModules")
local CameraController = require(CoreModules:WaitForChild("CameraController"))
local MovementController = require(CoreModules:WaitForChild("MovementController"))
local StaminaService = require(CoreModules:WaitForChild("StaminaService"))
local FlashlightService = require(CoreModules:WaitForChild("FlashlightService"))
local InteractionService = require(CoreModules:WaitForChild("InteractionService"))
local RadioService = require(CoreModules:WaitForChild("RadioService"))
local UIController = require(CoreModules:WaitForChild("UIController"))
local InputController = require(CoreModules:WaitForChild("InputController"))
local FuncRecargarArma = ReplicatedStorage:WaitForChild("RecargarArma")

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
UIController:Init(character)

InputController:Init(
    function()
        FlashlightService:Toggle()
    end,
    function(deltaX, deltaY)
        CameraController:ProcessMouseMovement(deltaX, deltaY)
    end,
    function()
        local ok, resultado = FuncRecargarArma:InvokeServer(nil)
        if not ok then
            warn("[ARMA] No se pudo recargar: " .. tostring(resultado))
        end
    end
)

-- LOOP PRINCIPAL DE RENDERIZADO
RunService.RenderStepped:Connect(function(dt)
    InputController:Update(dt)
    local moveInput, strafeInput, isHoldingShift = InputController:GetState()
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