local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotesUIController = {}

function NotesUIController:Init(hud)
    local panelNota = hud:WaitForChild("PanelNota")
    local textoLore = panelNota:WaitForChild("TextoLore")
    local botonCerrar = panelNota:WaitForChild("BotonCerrar")
    local eventoMostrarNota = ReplicatedStorage:WaitForChild("EventoMostrarNota")

    eventoMostrarNota.OnClientEvent:Connect(function(textoRecibido)
        textoLore.Text = textoRecibido
        panelNota.Visible = true
        print("[CLIENTE] Leyendo nota...")
    end)

    botonCerrar.MouseButton1Click:Connect(function()
        panelNota.Visible = false
        print("[CLIENTE] Nota cerrada.")
    end)
end

return NotesUIController
