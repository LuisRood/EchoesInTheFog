local UIController = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local UserInputService = game:GetService("UserInputService")

-- Conectamos con la API que creaste en el backend
local FuncObtenerInventario = ReplicatedStorage:WaitForChild("ObtenerInventario")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))

-- ==========================================
-- MÉTODOS PRIVADOS: UI AS CODE (Generador Visual)
-- ==========================================
local function construirMenuInventario(hudParent)
    local menu = Instance.new("Frame")
    menu.Name = "MenuInventario"
    menu.Size = UDim2.new(0.6, 0, 0.6, 0) 
    menu.Position = UDim2.new(0.2, 0, 0.2, 0) 
    menu.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05) 
    menu.BackgroundTransparency = 0.1 
    menu.Visible = false
    menu.Parent = hudParent

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0.15, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "I N V E N T A R I O"
    titulo.TextColor3 = Color3.new(0.8, 0, 0)
    titulo.Font = Enum.Font.Oswald
    titulo.TextScaled = true
    titulo.Parent = menu

    local contenedorItems = Instance.new("ScrollingFrame")
    contenedorItems.Name = "ContenedorItems"
    contenedorItems.Size = UDim2.new(0.9, 0, 0.8, 0)
    contenedorItems.Position = UDim2.new(0.05, 0, 0.15, 0)
    contenedorItems.BackgroundTransparency = 1
    contenedorItems.ScrollBarThickness = 6
    contenedorItems.Parent = menu

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.3, 0, 0.25, 0)
    grid.CellPadding = UDim2.new(0.03, 0, 0.03, 0)
    grid.Parent = contenedorItems

    return menu, contenedorItems
end

local function actualizarInventarioVisual(contenedorItems, inventarioDatos)
    for _, hijo in ipairs(contenedorItems:GetChildren()) do
        if hijo:IsA("Frame") then hijo:Destroy() end
    end

    for nombreItem, cantidad in pairs(inventarioDatos) do
        local infoItem = ItemDatabase[nombreItem] or {Descripcion = "Objeto misterioso."}

        local tarjeta = Instance.new("Frame")
        tarjeta.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        tarjeta.Parent = contenedorItems

        local textoNombre = Instance.new("TextLabel")
        textoNombre.Size = UDim2.new(1, 0, 0.3, 0)
        textoNombre.BackgroundTransparency = 1
        textoNombre.TextColor3 = Color3.new(1, 1, 1)
        textoNombre.TextScaled = true
        textoNombre.Text = nombreItem .. " (x" .. cantidad .. ")"
        textoNombre.Parent = tarjeta

        local textoDesc = Instance.new("TextLabel")
        textoDesc.Size = UDim2.new(0.9, 0, 0.6, 0)
        textoDesc.Position = UDim2.new(0.05, 0, 0.35, 0)
        textoDesc.BackgroundTransparency = 1
        textoDesc.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        textoDesc.TextWrapped = true
        textoDesc.TextScaled = true
        textoDesc.Text = infoItem.Descripcion
        textoDesc.Parent = tarjeta
    end
end

-- ==========================================
-- INICIALIZACIÓN DEL CLIENTE (Init)
-- ==========================================
function UIController:Init(character)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- ==========================================
    -- ¡EL FIX! APAGAR LA INTERFAZ NATIVA DE ROBLOX
    -- ==========================================
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- Apaga el menú del martillo
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- Apaga el inventario feo de abajo

    local hud = playerGui:WaitForChild("HUD")
    local visorEstado = hud:WaitForChild("VisorEstado")
    local velocidadParpadeo = 0

    -- 1. Construimos el menú de inventario en memoria
    local menuInventario, contenedorItems = construirMenuInventario(hud)
    local inventarioAbierto = false

    -- 2. Escuchamos la tecla TAB para el inventario
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end 

        if input.KeyCode == Enum.KeyCode.Tab then
            inventarioAbierto = not inventarioAbierto
            menuInventario.Visible = inventarioAbierto

            if inventarioAbierto then
                print("[CLIENTE] Solicitando datos del inventario al backend...")
                local inventarioDatos = FuncObtenerInventario:InvokeServer()
                actualizarInventarioVisual(contenedorItems, inventarioDatos)
            end
        end
    end)

    -- ==========================================
    -- REFERENCIAS Y LÓGICA DE NOTAS / FIN DE JUEGO
    -- ==========================================
    local panelNota = hud:WaitForChild("PanelNota")
    local textoLore = panelNota:WaitForChild("TextoLore")
    local botonCerrar = panelNota:WaitForChild("BotonCerrar")
    local eventoMostrarNota = ReplicatedStorage:WaitForChild("EventoMostrarNota")

    local TweenService = game:GetService("TweenService")
    local eventoFinJuego = ReplicatedStorage:WaitForChild("EventoFinJuego")
    local pantallaFinal = hud:WaitForChild("PantallaFinal")
    local textoFin = pantallaFinal:WaitForChild("TextoFin")

    eventoFinJuego.OnClientEvent:Connect(function()
        print("[CLIENTE] Ejecutando cinemática final...")
        pantallaFinal.Visible = true
        local infoFade = TweenInfo.new(4, Enum.EasingStyle.Linear)
        local animarFondo = TweenService:Create(pantallaFinal, infoFade, {BackgroundTransparency = 0})
        local animarTexto = TweenService:Create(textoFin, infoFade, {TextTransparency = 0})
        animarFondo:Play()
        animarTexto:Play()
        task.wait(4)
        task.wait(2)
    end)

    eventoMostrarNota.OnClientEvent:Connect(function(textoRecibido)
        textoLore.Text = textoRecibido
        panelNota.Visible = true
        print("[CLIENTE] Leyendo nota...")
    end)

    botonCerrar.MouseButton1Click:Connect(function()
        panelNota.Visible = false
        print("[CLIENTE] Nota cerrada.")
    end)

    -- ==========================================
    -- LÓGICA DEL VISOR DE VIDA (LATIDO)
    -- ==========================================
    local function actualizarVisor()
        local vidaActual = character:GetAttribute("VidaActual") or 100
        
        if vidaActual > 70 then
            visorEstado.Text = "ESTADO: ÓPTIMO"
            visorEstado.TextColor3 = Color3.fromRGB(0, 255, 0)
            velocidadParpadeo = 0
            visorEstado.TextTransparency = 0
        elseif vidaActual > 30 then
            visorEstado.Text = "ESTADO: PRECAUCIÓN"
            visorEstado.TextColor3 = Color3.fromRGB(255, 200, 0)
            velocidadParpadeo = 4
        elseif vidaActual > 0 then
            visorEstado.Text = "ESTADO: PELIGRO"
            visorEstado.TextColor3 = Color3.fromRGB(255, 0, 0)
            velocidadParpadeo = 8
        else
            visorEstado.Text = "ESTADO: ABATIDO"
            visorEstado.TextColor3 = Color3.fromRGB(0, 0, 0)
            velocidadParpadeo = 2
        end
    end

    actualizarVisor()
    character:GetAttributeChangedSignal("VidaActual"):Connect(actualizarVisor)
    character:GetAttributeChangedSignal("Estado"):Connect(actualizarVisor)

    RunService.RenderStepped:Connect(function()
        if velocidadParpadeo > 0 then
            local pulso = (math.sin(os.clock() * velocidadParpadeo) + 1) / 2
            visorEstado.TextTransparency = pulso * 0.5 
        else
            visorEstado.TextTransparency = 0
        end
    end)
end

return UIController