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
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local ItemDatabase = require(SharedModules:WaitForChild("ItemDatabase"))
local FuncRecargarArma = ReplicatedStorage:WaitForChild("RecargarArma")
local FuncDispararArma = ReplicatedStorage:WaitForChild("DispararArma")
local FuncObtenerEstadoArma = ReplicatedStorage:WaitForChild("ObtenerEstadoArma")

-- REFERENCIAS
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- CREAR SONIDO DE DISPARO
local soundsConfig = GameConstants.Client.Sounds
local gunshot = Instance.new("Sound")
gunshot.Name = "Gunshot"
gunshot.Volume = soundsConfig.GunshotVolume
gunshot.SoundId = soundsConfig.GunshotSoundId
gunshot.Parent = hrp

-- CREAR SONIDO DE RECARGA
local reloadSound = Instance.new("Sound")
reloadSound.Name = "ReloadSound"
reloadSound.Volume = soundsConfig.ReloadVolume
reloadSound.SoundId = soundsConfig.ReloadSoundId
reloadSound.Parent = hrp

-- Variables de control de recarga
local isReloading = false

local function getEquippedWeapon()
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

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
        if isReloading then
            return
        end
        
        local equippedWeapon = getEquippedWeapon()
        if not equippedWeapon then
            return
        end
        
        -- Verificar si hay munición en inventario
        local ok, estado = FuncObtenerEstadoArma:InvokeServer(nil)
        if not ok or not estado or (estado.ReserveAmmo or 0) <= 0 then
            warn("[ARMA] No hay munición para recargar")
            return
        end
        
        isReloading = true
        reloadSound:Play()
        
        -- Delay de recarga según datos del arma
        local weaponData = ItemDatabase[equippedWeapon.Name]
        local reloadTime = (weaponData and weaponData.ReloadTimeSeconds) or 0
        
        if reloadTime > 0 then
            task.wait(reloadTime)
        end
        
        local reloadOk, resultado = FuncRecargarArma:InvokeServer(nil)
        if not reloadOk then
            warn("[ARMA] No se pudo recargar: " .. tostring(resultado))
        end
        
        isReloading = false
    end,
    function()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local ok, resultado = FuncDispararArma:InvokeServer(camera.CFrame.Position, camera.CFrame.LookVector)
        if ok then
            gunshot:Play()
        else
            warn("[ARMA] No se pudo disparar: " .. tostring(resultado))
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