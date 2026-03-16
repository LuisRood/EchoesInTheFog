local UIController = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 

function UIController:Init(character)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Buscamos el texto que creamos en Studio
    local hud = playerGui:WaitForChild("HUD")
    local visorEstado = hud:WaitForChild("VisorEstado")

    -- Variable para controlar qué tan rápido oscila la matemática
    local velocidadParpadeo = 0

    -- ==========================================
    -- REFERENCIAS AL SISTEMA DE NOTAS
    -- ==========================================
    local panelNota = hud:WaitForChild("PanelNota")
    local textoLore = panelNota:WaitForChild("TextoLore")
    local botonCerrar = panelNota:WaitForChild("BotonCerrar")
    local eventoMostrarNota = ReplicatedStorage:WaitForChild("EventoMostrarNota")

    local TweenService = game:GetService("TweenService")
    local eventoFinJuego = ReplicatedStorage:WaitForChild("EventoFinJuego")
    local pantallaFinal = hud:WaitForChild("PantallaFinal")
    local textoFin = pantallaFinal:WaitForChild("TextoFin")

    -- ==========================================
    -- LISTENER: SECUENCIA DE FIN DE JUEGO
    -- ==========================================
    eventoFinJuego.OnClientEvent:Connect(function()
        print("[CLIENTE] Ejecutando cinemática final...")
        
        pantallaFinal.Visible = true
        -- Creamos una animación lineal que dure 4 segundos
        local infoFade = TweenInfo.new(4, Enum.EasingStyle.Linear)
        
        -- Animamos la transparencia del fondo y del texto hacia 0 (totalmente visibles)
        local animarFondo = TweenService:Create(pantallaFinal, infoFade, {BackgroundTransparency = 0})
        local animarTexto = TweenService:Create(textoFin, infoFade, {TextTransparency = 0})
        
        animarFondo:Play()
        animarTexto:Play()
        
        -- Esperamos a que la pantalla esté totalmente negra
        task.wait(4) -- Tiempo exacto que tarda la pantalla en ponerse negra
        task.wait(2) -- Tiempo extra para que el jugador alcance a leer el texto
        -- Cortamos la conexión del jugador. ¡MVP Completado!
    end)
    -- ==========================================
    -- LISTENER DEL SERVIDOR (Atrapa el texto)
    -- ==========================================
    eventoMostrarNota.OnClientEvent:Connect(function(textoRecibido)
        -- 1. Inyectamos el texto en la etiqueta
        textoLore.Text = textoRecibido
        
        -- 2. Hacemos visible el papel en la pantalla
        panelNota.Visible = true
        
        -- Opcional: Podrías reproducir un sonido de "hoja de papel" aquí
        print("[CLIENTE] Leyendo nota...")
    end)

    -- ==========================================
    -- LÓGICA DEL BOTÓN CERRAR
    -- ==========================================
    botonCerrar.MouseButton1Click:Connect(function()
        panelNota.Visible = false
        print("[CLIENTE] Nota cerrada.")
    end)

    -- Función que evalúa la vida y cambia la UI
    local function actualizarVisor()
        local vidaActual = character:GetAttribute("VidaActual") or 100
        
        if vidaActual > 70 then
            visorEstado.Text = "ESTADO: ÓPTIMO"
            visorEstado.TextColor3 = Color3.fromRGB(0, 255, 0) -- Verde vibrante
            velocidadParpadeo = 0
            visorEstado.TextTransparency = 0

        elseif vidaActual > 30 then
            visorEstado.Text = "ESTADO: PRECAUCIÓN"
            visorEstado.TextColor3 = Color3.fromRGB(255, 200, 0) -- Amarillo/Naranja
            velocidadParpadeo = 4
            
        elseif vidaActual > 0 then
            visorEstado.Text = "ESTADO: PELIGRO"
            visorEstado.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rojo sangre
            velocidadParpadeo = 8
        else
            visorEstado.Text = "ESTADO: ABATIDO"
            visorEstado.TextColor3 = Color3.fromRGB(0, 0, 0) -- Rojo sangre
            velocidadParpadeo = 2
        end
    end

    -- 1. Ejecutamos la función una vez al nacer para poner el color inicial
    actualizarVisor()

    -- 2. LISTENER REACTIVO: Se ejecuta automáticamente SOLO cuando la vida cambia
    character:GetAttributeChangedSignal("VidaActual"):Connect(actualizarVisor)
    character:GetAttributeChangedSignal("Estado"):Connect(actualizarVisor)

    -- ==========================================
    -- 3. ANIMACIÓN FLUIDA (El parpadeo cómodo)
    -- ==========================================
    RunService.RenderStepped:Connect(function()
        if velocidadParpadeo > 0 then
            -- os.clock() es el tiempo del CPU. math.sin crea una onda entre -1 y 1.
            -- Lo ajustamos para que la transparencia oscile entre 0 (opaco) y 0.5 (semitransparente)
            local pulso = (math.sin(os.clock() * velocidadParpadeo) + 1) / 2
            visorEstado.TextTransparency = pulso * 0.5 
        else
            -- Si estás en ÓPTIMO, aseguramos que sea totalmente opaco
            visorEstado.TextTransparency = 0
        end
    end)
end

return UIController