local RunService = game:GetService("RunService")

local HealthHUDController = {}

function HealthHUDController:Init(character, hud)
    local visorEstado = hud:WaitForChild("VisorEstado")
    local velocidadParpadeo = 0

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

return HealthHUDController
