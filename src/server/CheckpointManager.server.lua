local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Buscamos la carpeta que creaste en Studio
local checkpointsFolder = workspace:WaitForChild("Checkpoints")
local checkpointConnections = {}

print("[BACKEND] Gestor de Checkpoints Iniciado")

-- Iteramos sobre todos los bloques dentro de la carpeta
for _, checkpoint in ipairs(checkpointsFolder:GetChildren()) do
    if checkpoint:IsA("BasePart") then
        
        -- Creamos un Event Listener para cuando algo toque este bloque
        local touchedConnection = checkpoint.Touched:Connect(function(hit)
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)

            -- Validamos que quien lo pisó sea un jugador real y no el monstruo
            if player then
                -- Calculamos la coordenada. Le sumamos 3 metros en Y (arriba) 
                -- para asegurar que al revivir no te quedes atorada en el piso.
                local nuevaPosicion = checkpoint.CFrame + Vector3.new(0, 3, 0)
                
                -- Validamos si esta coordenada ya es la guardada
                local checkpointActual = character:GetAttribute("UltimoCheckpoint")
                
                -- Esto actúa como un "Debounce". Como tu personaje tiene muchos bloques 
                -- (pies, piernas), el evento Touched se dispara varias veces seguidas.
                -- Al validar que sea diferente, evitamos spamear la memoria.
                if checkpointActual ~= nuevaPosicion then
                    character:SetAttribute("UltimoCheckpoint", nuevaPosicion)
                    print("[SISTEMA] Punto de control guardado para " .. player.Name)
                end
            end
        end)

        local ancestryConnection = checkpoint.AncestryChanged:Connect(function(_, parent)
            if parent then
                return
            end

            local refs = checkpointConnections[checkpoint]
            if refs then
                if refs.touched then refs.touched:Disconnect() end
                if refs.ancestry then refs.ancestry:Disconnect() end
                checkpointConnections[checkpoint] = nil
            end
        end)

        checkpointConnections[checkpoint] = {
            touched = touchedConnection,
            ancestry = ancestryConnection,
        }
    end
end