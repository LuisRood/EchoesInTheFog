local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts"):WaitForChild("GameConstants"))

local EndgameUIController = {}

function EndgameUIController:Init(hud)
    local eventoFinJuego = ReplicatedStorage:WaitForChild("EventoFinJuego")
    local pantallaFinal = hud:WaitForChild("PantallaFinal")
    local textoFin = pantallaFinal:WaitForChild("TextoFin")

    eventoFinJuego.OnClientEvent:Connect(function()
        print("[CLIENTE] Ejecutando cinemática final...")

        pantallaFinal.Visible = true
        local infoFade = TweenInfo.new(GameConstants.Client.EndgameUI.FadeSeconds, Enum.EasingStyle.Linear)
        local animarFondo = TweenService:Create(pantallaFinal, infoFade, {BackgroundTransparency = 0})
        local animarTexto = TweenService:Create(textoFin, infoFade, {TextTransparency = 0})

        animarFondo:Play()
        animarTexto:Play()

        task.wait(GameConstants.Client.EndgameUI.FadeSeconds)
        task.wait(GameConstants.Client.EndgameUI.PostFadeSeconds)
    end)
end

return EndgameUIController
