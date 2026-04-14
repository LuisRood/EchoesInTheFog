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

local function createCharacterSound(name, volume, soundId)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.Volume = volume
    sound.SoundId = soundId
    sound.Parent = hrp
    return sound
end

local gunshot = createCharacterSound("Gunshot", 0.8, "rbxassetid://123448793380050")
local reloadSound = createCharacterSound("ReloadSound", 0.5, "rbxassetid://139798971373512")

local function ensureSound(soundRef, name, volume, soundId)
    if not soundRef or not soundRef.Parent or soundRef.Parent ~= hrp then
        if soundRef and soundRef.Parent then
            soundRef:Destroy()
        end
        return createCharacterSound(name, volume, soundId)
    end

    return soundRef
end

-- Variables de control de recarga
local isReloading = false

local function invokeServerSafe(remote, ...)
    local packed = table.pack(...)
    local success, serverOk, serverResult = pcall(function()
        return remote:InvokeServer(table.unpack(packed, 1, packed.n))
    end)

    if not success then
        return false, false, serverOk
    end

    return true, serverOk, serverResult
end

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
CameraController:Reset()
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
        local invokeOk, ok, estado = invokeServerSafe(FuncObtenerEstadoArma, nil)
        if not invokeOk then
            warn("[ARMA] Error solicitando estado de arma: " .. tostring(estado))
            return
        end

        if not ok or not estado or (estado.ReserveAmmo or 0) <= 0 then
            warn("[ARMA] No hay munición para recargar")
            return
        end
        
        isReloading = true
        reloadSound = ensureSound(reloadSound, "ReloadSound", 0.5, "rbxassetid://139798971373512")
        reloadSound:Play()
        
        -- Delay de recarga según datos del arma
        local weaponData = ItemDatabase[equippedWeapon.Name]
        local reloadTime = (weaponData and weaponData.ReloadTimeSeconds) or 0
        
        if reloadTime > 0 then
            task.wait(reloadTime)
        end
        
        local reloadInvokeOk, reloadOk, resultado = invokeServerSafe(FuncRecargarArma, nil)
        if not reloadInvokeOk then
            warn("[ARMA] Error de red en recarga: " .. tostring(resultado))
            isReloading = false
            return
        end

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

        local invokeOk, ok, resultado = invokeServerSafe(FuncDispararArma, camera.CFrame.Position, camera.CFrame.LookVector)
        if not invokeOk then
            warn("[ARMA] Error al invocar disparo: " .. tostring(resultado))
            return
        end

        if ok then
            gunshot = ensureSound(gunshot, "Gunshot", 0.8, "rbxassetid://123448793380050")
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