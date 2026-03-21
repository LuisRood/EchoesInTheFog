local FlashlightService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

-- Variables privadas del servicio
local lightObject = nil
local isOn = false
local FLICKER_CHANCE = GameConstants.Client.Flashlight.FlickerChance -- Probabilidad de que la luz parpadee y falle un poco

-- "Constructor": Configura la luz y la ancla al jugador
function FlashlightService:Init(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    -- ==========================================
    -- FIX DEL CABELLO (Desactivar sombras locales)
    -- ==========================================
    for _, objeto in ipairs(character:GetDescendants()) do
        -- Si el objeto es un accesorio (cabello, bufandas, sombreros)...
        if objeto:IsA("Accessory") then
            local handle = objeto:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                -- Le quitamos la capacidad de bloquear la luz de nuestra linterna
                handle.CastShadow = false
            end
        end
    end
    -- ==========================================
    -- Creamos un SpotLight (luz de cono) mediante código
    lightObject = Instance.new("SpotLight")
    lightObject.Name = "PocketFlashlight"
    lightObject.Brightness = 0 -- Inicia apagada
    lightObject.Range = GameConstants.Client.Flashlight.Range -- Distancia en metros (studs) que ilumina
    lightObject.Angle = GameConstants.Client.Flashlight.Angle -- Apertura del cono de luz
    lightObject.Color = Color3.fromRGB(255, 240, 215) -- Un tono ligeramente cálido/viejo
    lightObject.Shadows = true -- ¡CRUCIAL! Esto activa las sombras dinámicas de terror
    lightObject.Parent = hrp
end

-- Método para encender/apagar
function FlashlightService:Toggle()
    if not lightObject then return end
    
    isOn = not isOn
    if isOn then
        lightObject.Brightness = GameConstants.Client.Flashlight.MaxBrightness
    else
        lightObject.Brightness = 0
    end
end

-- Bucle de actualización para darle atmósfera (el parpadeo)
function FlashlightService:Update(dt)
    if not isOn or not lightObject then return end
    
    -- Inmersión: Un pequeño parpadeo errático simulando interferencia o batería vieja
    if math.random() < FLICKER_CHANCE then
        lightObject.Brightness = math.random() * GameConstants.Client.Flashlight.FlickerDropMax -- Baja la intensidad de golpe
    else
        -- Regresa suavemente a la intensidad normal
        lightObject.Brightness = math.clamp(
            lightObject.Brightness + (GameConstants.Client.Flashlight.RecoverRate * dt),
            0,
            GameConstants.Client.Flashlight.MaxBrightness
        )
    end
end

return FlashlightService