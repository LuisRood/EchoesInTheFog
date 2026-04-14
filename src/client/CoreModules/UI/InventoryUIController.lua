local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local InventoryUIController = {}

local FuncObtenerInventario = ReplicatedStorage:WaitForChild("ObtenerInventario")
local FuncEquiparItem = ReplicatedStorage:WaitForChild("EquiparItem")
local FuncObtenerEstadoArma = ReplicatedStorage:WaitForChild("ObtenerEstadoArma")
local FuncRecargarArma = ReplicatedStorage:WaitForChild("RecargarArma")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemDatabase"))
local ItemTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("ItemTypes"))
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local ACTION_TOGGLE_INVENTORY = "EITF_ToggleInventory"

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

local function solicitarEquipar(nombreItem)
    local invokeOk, ok, mensaje = invokeServerSafe(FuncEquiparItem, nombreItem)
    if not invokeOk then
        warn("[INVENTARIO] Error al equipar item: " .. tostring(mensaje))
        return false
    end

    if not ok then
        warn("[INVENTARIO] No se pudo equipar: " .. tostring(mensaje))
        return false
    end

    print("[INVENTARIO] Equipado: " .. tostring(nombreItem))
    return true
end

local function normalizarNombreItem(itemName)
    if typeof(itemName) ~= "string" then
        return itemName
    end

    local limpio = string.match(itemName, "^%s*(.-)%s*$")
    if limpio == "" then
        return itemName
    end

    if ItemDatabase[limpio] then
        return limpio
    end

    local lower = string.lower(limpio)
    for key in pairs(ItemDatabase) do
        if string.lower(key) == lower then
            return key
        end
    end

    return limpio
end

local function esItemEquipable(infoItem)
    if not infoItem then
        return false
    end

    local tipo = string.lower(tostring(infoItem.Tipo or ""))
    return tipo == string.lower(ItemTypes.Firearm)
        or tipo == string.lower(ItemTypes.Melee)
        or infoItem.Dano ~= nil
        or infoItem.UsaMunicion ~= nil
        or infoItem.Rango ~= nil
end

local function construirMenuInventario(hudParent)
    local menu = Instance.new("Frame")
    menu.Name = "MenuInventario"
    menu.Size = UDim2.new(0.74, 0, 0.7, 0)
    menu.Position = UDim2.new(0.13, 0, 0.15, 0)
    menu.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    menu.BackgroundTransparency = 0.08
    menu.Visible = false
    menu.SelectionGroup = true
    menu.ClipsDescendants = true
    menu.Parent = hudParent

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.35
    stroke.Parent = menu

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0.12, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "I N V E N T A R I O"
    titulo.TextColor3 = Color3.fromRGB(190, 20, 20)
    titulo.Font = Enum.Font.Oswald
    titulo.TextScaled = true
    titulo.Parent = menu

    local subtitulo = Instance.new("TextLabel")
    subtitulo.Size = UDim2.new(1, 0, 0.045, 0)
    subtitulo.Position = UDim2.new(0, 0, 0.11, 0)
    subtitulo.BackgroundTransparency = 1
    subtitulo.Text = "Selecciona un objeto para ver detalles y acciones"
    subtitulo.TextColor3 = Color3.fromRGB(165, 165, 165)
    subtitulo.Font = Enum.Font.Oswald
    subtitulo.TextScaled = true
    subtitulo.Parent = menu

    local panelLista = Instance.new("Frame")
    panelLista.Name = "PanelLista"
    panelLista.Size = UDim2.new(0.38, 0, 0.73, 0)
    panelLista.Position = UDim2.new(0.03, 0, 0.17, 0)
    panelLista.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    panelLista.BackgroundTransparency = 0.04
    panelLista.BorderSizePixel = 0
    panelLista.Parent = menu

    local panelDetalle = Instance.new("Frame")
    panelDetalle.Name = "PanelDetalle"
    panelDetalle.Size = UDim2.new(0.53, 0, 0.73, 0)
    panelDetalle.Position = UDim2.new(0.44, 0, 0.17, 0)
    panelDetalle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    panelDetalle.BackgroundTransparency = 0.04
    panelDetalle.BorderSizePixel = 0
    panelDetalle.Parent = menu

    local contenedorItems = Instance.new("ScrollingFrame")
    contenedorItems.Name = "ContenedorItems"
    contenedorItems.Size = UDim2.new(1, -10, 1, -10)
    contenedorItems.Position = UDim2.new(0, 5, 0, 5)
    contenedorItems.BackgroundTransparency = 1
    contenedorItems.BorderSizePixel = 0
    contenedorItems.ScrollBarThickness = 8
    contenedorItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contenedorItems.CanvasSize = UDim2.new(0, 0, 0, 0)
    contenedorItems.Parent = panelLista

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = contenedorItems

    local tituloDetalle = Instance.new("TextLabel")
    tituloDetalle.Name = "TituloDetalle"
    tituloDetalle.Size = UDim2.new(0.92, 0, 0.14, 0)
    tituloDetalle.Position = UDim2.new(0.04, 0, 0.05, 0)
    tituloDetalle.BackgroundTransparency = 1
    tituloDetalle.Text = "SELECCIONA UN OBJETO"
    tituloDetalle.TextColor3 = Color3.fromRGB(245, 245, 245)
    tituloDetalle.Font = Enum.Font.Oswald
    tituloDetalle.TextScaled = true
    tituloDetalle.TextXAlignment = Enum.TextXAlignment.Left
    tituloDetalle.Parent = panelDetalle

    local descDetalle = Instance.new("TextLabel")
    descDetalle.Name = "DescripcionDetalle"
    descDetalle.Size = UDim2.new(0.9, 0, 0.34, 0)
    descDetalle.Position = UDim2.new(0.05, 0, 0.22, 0)
    descDetalle.BackgroundTransparency = 1
    descDetalle.Text = ""
    descDetalle.TextColor3 = Color3.fromRGB(210, 210, 210)
    descDetalle.Font = Enum.Font.Oswald
    descDetalle.TextWrapped = true
    descDetalle.TextScaled = true
    descDetalle.TextXAlignment = Enum.TextXAlignment.Left
    descDetalle.Parent = panelDetalle

    local estadoDetalle = Instance.new("TextLabel")
    estadoDetalle.Name = "EstadoDetalle"
    estadoDetalle.Size = UDim2.new(0.9, 0, 0.13, 0)
    estadoDetalle.Position = UDim2.new(0.05, 0, 0.58, 0)
    estadoDetalle.BackgroundTransparency = 1
    estadoDetalle.Text = ""
    estadoDetalle.TextColor3 = Color3.fromRGB(150, 150, 150)
    estadoDetalle.Font = Enum.Font.Oswald
    estadoDetalle.TextScaled = true
    estadoDetalle.TextXAlignment = Enum.TextXAlignment.Left
    estadoDetalle.Parent = panelDetalle

    local btnAccion = Instance.new("TextButton")
    btnAccion.Name = "BotonAccion"
    btnAccion.Size = UDim2.new(0.56, 0, 0.1, 0)
    btnAccion.Position = UDim2.new(0.22, 0, 0.86, 0)
    btnAccion.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    btnAccion.TextColor3 = Color3.new(1, 1, 1)
    btnAccion.Text = "EQUIPAR"
    btnAccion.TextScaled = true
    btnAccion.Font = Enum.Font.Oswald
    btnAccion.AutoButtonColor = true
    btnAccion.Active = true
    btnAccion.Selectable = true
    btnAccion.Visible = false
    btnAccion.Parent = panelDetalle

    local btnSecundario = Instance.new("TextButton")
    btnSecundario.Name = "BotonSecundario"
    btnSecundario.Size = UDim2.new(0.56, 0, 0.1, 0)
    btnSecundario.Position = UDim2.new(0.22, 0, 0.74, 0)
    btnSecundario.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btnSecundario.TextColor3 = Color3.new(1, 1, 1)
    btnSecundario.Text = "RECARGAR"
    btnSecundario.TextScaled = true
    btnSecundario.Font = Enum.Font.Oswald
    btnSecundario.AutoButtonColor = true
    btnSecundario.Active = true
    btnSecundario.Selectable = true
    btnSecundario.Visible = false
    btnSecundario.Parent = panelDetalle

    local hintDetalle = Instance.new("TextLabel")
    hintDetalle.Name = "HintDetalle"
    hintDetalle.Size = UDim2.new(0.9, 0, 0.035, 0)
    hintDetalle.Position = UDim2.new(0.05, 0, 0.96, 0)
    hintDetalle.BackgroundTransparency = 1
    hintDetalle.Text = "PC: click | Móvil: tocar | Control: A"
    hintDetalle.TextColor3 = Color3.fromRGB(120, 120, 120)
    hintDetalle.Font = Enum.Font.Oswald
    hintDetalle.TextScaled = true
    hintDetalle.TextXAlignment = Enum.TextXAlignment.Left
    hintDetalle.Parent = panelDetalle

    return menu, contenedorItems, tituloDetalle, descDetalle, estadoDetalle, btnAccion, btnSecundario
end

local function limpiarContenido(contenedorItems)
    for _, hijo in ipairs(contenedorItems:GetChildren()) do
        if hijo:IsA("GuiObject") then
            hijo:Destroy()
        end
    end
end

local function crearFilaItem(contenedorItems, nombreCanonico, cantidad, infoItem, esEquipable, onSeleccionar)
    local fila = Instance.new("TextButton")
    fila.Name = nombreCanonico
    fila.Size = UDim2.new(1, -4, 0, 58)
    fila.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    fila.BorderSizePixel = 0
    fila.AutoButtonColor = false
    fila.Active = true
    fila.Selectable = true
    fila.Text = ""
    fila.Parent = contenedorItems

    local stroke = Instance.new("UIStroke")
    stroke.Color = esEquipable and Color3.fromRGB(140, 30, 30) or Color3.fromRGB(70, 70, 70)
    stroke.Thickness = 1
    stroke.Transparency = 0.2
    stroke.Parent = fila

    local nombre = Instance.new("TextLabel")
    nombre.BackgroundTransparency = 1
    nombre.Size = UDim2.new(0.7, 0, 0.45, 0)
    nombre.Position = UDim2.new(0.04, 0, 0.08, 0)
    nombre.Text = nombreCanonico .. " (x" .. cantidad .. ")"
    nombre.TextColor3 = Color3.fromRGB(245, 245, 245)
    nombre.Font = Enum.Font.Oswald
    nombre.TextScaled = true
    nombre.TextXAlignment = Enum.TextXAlignment.Left
    nombre.Parent = fila

    local descripcion = Instance.new("TextLabel")
    descripcion.BackgroundTransparency = 1
    descripcion.Size = UDim2.new(0.7, 0, 0.35, 0)
    descripcion.Position = UDim2.new(0.04, 0, 0.5, 0)
    descripcion.Text = infoItem.Descripcion or "Objeto misterioso."
    descripcion.TextColor3 = Color3.fromRGB(170, 170, 170)
    descripcion.Font = Enum.Font.Oswald
    descripcion.TextScaled = true
    descripcion.TextXAlignment = Enum.TextXAlignment.Left
    descripcion.Parent = fila

    local badge = Instance.new("TextLabel")
    badge.BackgroundTransparency = 1
    badge.Size = UDim2.new(0.22, 0, 0.4, 0)
    badge.Position = UDim2.new(0.74, 0, 0.3, 0)
    badge.Text = esEquipable and "EQUIPAR" or ""
    badge.TextColor3 = Color3.fromRGB(220, 120, 120)
    badge.Font = Enum.Font.Oswald
    badge.TextScaled = true
    badge.TextXAlignment = Enum.TextXAlignment.Right
    badge.Parent = fila

    fila:SetAttribute("ItemName", nombreCanonico)
    fila:SetAttribute("ItemAmount", cantidad)
    fila:SetAttribute("IsEquipable", esEquipable)

    fila.Activated:Connect(function()
        onSeleccionar(fila)
    end)

    fila.MouseButton1Click:Connect(function()
        onSeleccionar(fila)
    end)

    return fila
end

function InventoryUIController:Init(hud)
    local menuInventario, contenedorItems, tituloDetalle, descDetalle, estadoDetalle, btnAccion, btnSecundario = construirMenuInventario(hud)
    local inventarioAbierto = false
    local inventarioActual = {}
    local itemSeleccionado = nil
    local itemSeleccionadoEquipable = false
    local botonesItem = {}
    local ultimoEquipar = 0

    local function actualizarDetalle(nombreCanonico)
        local cantidad = inventarioActual[nombreCanonico] or 1
        local infoItem = ItemDatabase[nombreCanonico] or {Descripcion = "Objeto misterioso."}
        local esEquipable = esItemEquipable(infoItem)
        local esArmaFuego = string.lower(tostring(infoItem.Tipo or "")) == string.lower(ItemTypes.Firearm)

        tituloDetalle.Text = nombreCanonico .. " (x" .. cantidad .. ")"
        descDetalle.Text = infoItem.Descripcion or "Objeto misterioso."
        itemSeleccionado = nombreCanonico
        itemSeleccionadoEquipable = esEquipable

        if esEquipable then
            estadoDetalle.Text = "Arma disponible para equipar"
            btnAccion.Visible = true
            btnAccion.Text = "EQUIPAR"

            if esArmaFuego then
                local invokeOk, ok, estadoArma = invokeServerSafe(FuncObtenerEstadoArma, nombreCanonico)
                if not invokeOk then
                    estadoDetalle.Text = "Error al consultar estado del arma"
                    btnSecundario.Visible = false
                    return
                end

                if ok and estadoArma then
                    estadoDetalle.Text = string.format(
                        "Cargador: %d/%d  |  Reserva (%s): %d",
                        estadoArma.AmmoInMag or 0,
                        estadoArma.MagCapacity or 0,
                        tostring(estadoArma.AmmoType or "?"),
                        estadoArma.ReserveAmmo or 0
                    )
                end

                btnSecundario.Visible = true
            else
                btnSecundario.Visible = false
            end
        else
            estadoDetalle.Text = "Objeto sin acción de equipo"
            btnAccion.Visible = false
            btnSecundario.Visible = false
        end

        if UserInputService.GamepadEnabled and esEquipable then
            GuiService.SelectedObject = btnAccion
        end
    end

    local function renderInventario()
        limpiarContenido(contenedorItems)
        botonesItem = {}
        itemSeleccionado = nil
        itemSeleccionadoEquipable = false
        btnAccion.Visible = false
        btnSecundario.Visible = false
        estadoDetalle.Text = ""

        local listaNombres = {}
        for nombreItem in pairs(inventarioActual) do
            table.insert(listaNombres, nombreItem)
        end
        table.sort(listaNombres)

        for _, nombreItem in ipairs(listaNombres) do
            local nombreCanonico = normalizarNombreItem(nombreItem)
            local infoItem = ItemDatabase[nombreCanonico] or {Descripcion = "Objeto misterioso."}
            local esEquipable = esItemEquipable(infoItem)

            local fila = crearFilaItem(contenedorItems, nombreCanonico, inventarioActual[nombreItem], infoItem, esEquipable, function()
                actualizarDetalle(nombreCanonico)
            end)

            table.insert(botonesItem, fila)
        end

        if #botonesItem > 0 then
            local primer = botonesItem[1]
            GuiService.SelectedObject = primer
            actualizarDetalle(primer:GetAttribute("ItemName"))
        else
            tituloDetalle.Text = "INVENTARIO VACÍO"
            descDetalle.Text = "No llevas objetos contigo."
            estadoDetalle.Text = ""
        end
    end

    local function alternarInventario()
        inventarioAbierto = not inventarioAbierto
        menuInventario.Visible = inventarioAbierto

        if inventarioAbierto then
            print("[CLIENTE] Solicitando datos del inventario al backend...")
            local invokeOk, datos = pcall(function()
                return FuncObtenerInventario:InvokeServer()
            end)
            inventarioActual = (invokeOk and datos) or {}
            renderInventario()
        else
            if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(menuInventario) then
                GuiService.SelectedObject = nil
            end
        end
    end

    btnAccion.MouseButton1Click:Connect(function()
        if not itemSeleccionado or not itemSeleccionadoEquipable then
            return
        end

        local now = os.clock()
        if now - ultimoEquipar < 0.15 then
            return
        end
        ultimoEquipar = now

        if solicitarEquipar(itemSeleccionado) then
            estadoDetalle.Text = "Objeto equipado"
        end
    end)

    btnAccion.Activated:Connect(function()
        if not itemSeleccionado or not itemSeleccionadoEquipable then
            return
        end

        local now = os.clock()
        if now - ultimoEquipar < 0.15 then
            return
        end
        ultimoEquipar = now

        if solicitarEquipar(itemSeleccionado) then
            actualizarDetalle(itemSeleccionado)
        end
    end)

    local function intentarRecargarSeleccionada()
        if not itemSeleccionado or not itemSeleccionadoEquipable then
            return
        end

        local infoItem = ItemDatabase[itemSeleccionado]
        if not infoItem or string.lower(tostring(infoItem.Tipo or "")) ~= string.lower(ItemTypes.Firearm) then
            return
        end

        local invokeOk, ok, estadoOError = invokeServerSafe(FuncRecargarArma, itemSeleccionado)
        if not invokeOk then
            estadoDetalle.Text = "Error al recargar"
            return
        end

        if not ok then
            estadoDetalle.Text = tostring(estadoOError)
            return
        end

        local estadoArma = estadoOError
        estadoDetalle.Text = string.format(
            "Cargador: %d/%d  |  Reserva (%s): %d",
            estadoArma.AmmoInMag or 0,
            estadoArma.MagCapacity or 0,
            tostring(estadoArma.AmmoType or "?"),
            estadoArma.ReserveAmmo or 0
        )
    end

    btnSecundario.MouseButton1Click:Connect(intentarRecargarSeleccionada)
    btnSecundario.Activated:Connect(intentarRecargarSeleccionada)

    ContextActionService:UnbindAction(ACTION_TOGGLE_INVENTORY)
    ContextActionService:BindAction(
        ACTION_TOGGLE_INVENTORY,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                alternarInventario()
            end
            return Enum.ContextActionResult.Pass
        end,
        true,
        Enum.KeyCode.Tab,
        Enum.KeyCode.ButtonY
    )
    ContextActionService:SetTitle(ACTION_TOGGLE_INVENTORY, "Inv")
    ContextActionService:SetPosition(ACTION_TOGGLE_INVENTORY, GameConstants.Client.Controls.MobileButtons.InventoryPosition)
end

return InventoryUIController
