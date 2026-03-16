local RadioService = {}

local radioSound = nil
local MAX_DISTANCE = 60 -- A los 60 studs de distancia empezará a sonar bajito

function RadioService:Init(character)
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Creamos el reproductor de audio mediante código
    radioSound = Instance.new("Sound")
    radioSound.Name = "RadioEstatica"
    -- Usamos un ID público y gratuito de ruido blanco de la librería de Roblox
    radioSound.SoundId = "rbxassetid://90999463614853" 
    radioSound.Looped = true
    radioSound.Volume = 0
    radioSound.Parent = hrp
    
    -- Lo encendemos, pero como el volumen es 0, no se escucha aún
    radioSound:Play()
end

function RadioService:Update(hrpPosition)
    if not radioSound then return end

    -- Buscamos la carpeta de amenazas
    local carpetaPeligros = workspace:FindFirstChild("Peligros")
    if not carpetaPeligros then return end

    local distanciaMinima = MAX_DISTANCE
    local hayPeligroCerca = false

    -- Escaneamos todos los objetos dentro de la carpeta Peligros
    for _, peligro in ipairs(carpetaPeligros:GetChildren()) do
        if peligro:IsA("BasePart") or peligro:IsA("Model") then
            local posicionPeligro

            -- Si es un modelo (como un NPC), buscamos un pivote seguro
            if peligro:IsA("Model") then
                local referencia = peligro.PrimaryPart or peligro:FindFirstChild("HumanoidRootPart")
                if referencia and referencia:IsA("BasePart") then
                    posicionPeligro = referencia.Position
                else
                    posicionPeligro = peligro:GetPivot().Position
                end
            else
                posicionPeligro = peligro.Position
            end
            
            -- Calculamos la distancia vectorial exacta
            local distancia = (posicionPeligro - hrpPosition).Magnitude
            
            if distancia < distanciaMinima then
                distanciaMinima = distancia
                hayPeligroCerca = true
            end
        end
    end

    -- Ajustamos el volumen dinámicamente
    if hayPeligroCerca then
        -- Regla de 3 invertida: Si está lejos, volumen bajo. Si está encima de ti, volumen al máximo.
        local volumenCalculado = 1 - (distanciaMinima / MAX_DISTANCE)
        -- Interpolación suave para que el volumen no cambie de golpe y suene más natural
        radioSound.Volume = radioSound.Volume + (volumenCalculado - radioSound.Volume) * 0.1
    else
        -- Si ya no hay peligros cerca, apagamos el volumen suavemente
        radioSound.Volume = radioSound.Volume + (0 - radioSound.Volume) * 0.1
    end
end

return RadioService