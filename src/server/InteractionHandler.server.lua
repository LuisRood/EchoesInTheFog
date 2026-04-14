-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local TweenService = game:GetService("TweenService")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))
local InventoryManager = require(ModuleScripts:WaitForChild("InventoryManager"))
local WeaponStateManager = require(ModuleScripts:WaitForChild("WeaponStateManager"))
local WeaponCombatManager = require(ModuleScripts:WaitForChild("WeaponCombatManager"))
local EquipmentManager = require(ModuleScripts:WaitForChild("EquipmentManager"))
local RemoteRegistry = require(ModuleScripts:WaitForChild("RemoteRegistry"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventShowNotes = ReplicatedStorage:WaitForChild("EventoMostrarNota")
local EventEndGame = ReplicatedStorage:WaitForChild("EventoFinJuego")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PromptActionTypes = require(SharedModules:WaitForChild("PromptActionTypes"))
local AttributeNames = require(SharedModules:WaitForChild("AttributeNames"))
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local InteractionsFolder = script.Parent:WaitForChild("Interactions")
local ActionsFolder = InteractionsFolder:WaitForChild("Actions")
local DoorAnimator = require(InteractionsFolder:WaitForChild("DoorAnimator"))
local EndgameSequence = require(InteractionsFolder:WaitForChild("EndgameSequence"))
local RevivirAction = require(ActionsFolder:WaitForChild("RevivirAction"))
local PuertaAction = require(ActionsFolder:WaitForChild("PuertaAction"))
local LeerNotaAction = require(ActionsFolder:WaitForChild("LeerNotaAction"))
local PuertaFinalAction = require(ActionsFolder:WaitForChild("PuertaFinalAction"))
local BotiquinAction = require(ActionsFolder:WaitForChild("BotiquinAction"))
local RecogerObjetoAction = require(ActionsFolder:WaitForChild("RecogerObjetoAction"))
local ItemAction = require(ActionsFolder:WaitForChild("ItemAction"))

RemoteRegistry:RegisterInventoryEndpoint(InventoryManager)
RemoteRegistry:RegisterEquipEndpoint(InventoryManager, EquipmentManager, WeaponStateManager)
RemoteRegistry:RegisterWeaponEndpoints(InventoryManager, WeaponStateManager, WeaponCombatManager, PlayerStateManager)
print("[BACKEND] Motor de Interacciones del Servidor Iniciado")

Players.PlayerRemoving:Connect(function(player)
    WeaponStateManager:ClearPlayer(player)
    WeaponCombatManager:ClearPlayer(player)
    RemoteRegistry:ClearPlayer(player)
end)

local actionContext = {
    TweenService = TweenService,
    PlayerStateManager = PlayerStateManager,
    InventoryManager = InventoryManager,
    EventShowNotes = EventShowNotes,
    EventEndGame = EventEndGame,
    PromptActionTypes = PromptActionTypes,
    AttributeNames = AttributeNames,
    GameConstants = GameConstants,
    DoorAnimator = DoorAnimator,
    EndgameSequence = EndgameSequence,
}

local actionHandlers = {
    [PromptActionTypes.Revivir] = RevivirAction,
    [PromptActionTypes.Puerta] = PuertaAction,
    [PromptActionTypes.LeerNota] = LeerNotaAction,
    [PromptActionTypes.PuertaFinal] = PuertaFinalAction,
    [PromptActionTypes.Botiquin] = BotiquinAction,
    [PromptActionTypes.RecogerObjeto] = RecogerObjetoAction,
    [PromptActionTypes.Item] = ItemAction,
}

-- El servidor también escucha los ProximityPrompts, pero aquí ejecutamos la lógica real
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local actionType = prompt.Name

    local actionModule = actionHandlers[actionType]
    if actionModule and actionModule.Handle then
        actionModule.Handle(actionContext, prompt, player)
    end
end)