-- Archivo: src/server/InteractionHandler.server.lua
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local TweenService = game:GetService("TweenService")
local Logger = require(ModuleScripts:WaitForChild("Logger"))
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))
local InventoryManager = require(ModuleScripts:WaitForChild("InventoryManager"))
local WeaponStateManager = require(ModuleScripts:WaitForChild("WeaponStateManager"))
local WeaponCombatManager = require(ModuleScripts:WaitForChild("WeaponCombatManager"))
local EquipmentManager = require(ModuleScripts:WaitForChild("EquipmentManager"))
local RemoteRegistry = require(ModuleScripts:WaitForChild("RemoteRegistry"))
local PersistenceService = require(ModuleScripts:WaitForChild("PersistenceService"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventShowNotes = ReplicatedStorage:WaitForChild("EventoMostrarNota")
local EventEndGame = ReplicatedStorage:WaitForChild("EventoFinJuego")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PromptActionTypes = require(SharedModules:WaitForChild("PromptActionTypes"))
local AttributeNames = require(SharedModules:WaitForChild("AttributeNames"))
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local ItemDatabase = require(SharedModules:WaitForChild("ItemDatabase"))

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
local log = Logger:WithTag("Interaction")
local persistenceConfig = (((GameConstants or {}).Server or {}).Persistence) or {}

InventoryManager:SetItemDatabase(ItemDatabase)
WeaponStateManager:SetItemDatabase(ItemDatabase)
WeaponCombatManager:SetItemDatabase(ItemDatabase)
EquipmentManager:SetItemDatabase(ItemDatabase)

RemoteRegistry:RegisterInventoryEndpoint(InventoryManager)
RemoteRegistry:RegisterEquipEndpoint(InventoryManager, EquipmentManager, WeaponStateManager)
RemoteRegistry:RegisterWeaponEndpoints(InventoryManager, WeaponStateManager, WeaponCombatManager, PlayerStateManager)
log:Info("Motor de interacciones iniciado")

local function applyCheckpoint(player, checkpointCFrame)
    if typeof(checkpointCFrame) ~= "CFrame" then
        return
    end

    player:SetAttribute("UltimoCheckpoint", checkpointCFrame)
    local character = player.Character
    if character then
        character:SetAttribute("UltimoCheckpoint", checkpointCFrame)
    end
end

local function loadPlayerData(player)
    local loaded = PersistenceService:LoadPlayerData(player)
    InventoryManager:ApplySnapshot(player, loaded.Inventory)
    WeaponStateManager:ApplySnapshot(player, loaded.WeaponStates)
    applyCheckpoint(player, loaded.LastCheckpoint)
end

local function savePlayerData(player)
    PersistenceService:SavePlayerData(player, {
        Inventory = InventoryManager:GetSnapshot(player),
        WeaponStates = WeaponStateManager:GetSnapshot(player),
        LastCheckpoint = player:GetAttribute("UltimoCheckpoint"),
    })
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        loadPlayerData(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        loadPlayerData(player)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    InventoryManager:ClearPlayer(player)
    WeaponStateManager:ClearPlayer(player)
    WeaponCombatManager:ClearPlayer(player)
    RemoteRegistry:ClearPlayer(player)
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end)

if PersistenceService:IsEnabled() then
    local autoSaveSeconds = persistenceConfig.AutoSaveSeconds or 90
    task.spawn(function()
        while task.wait(autoSaveSeconds) do
            for _, player in ipairs(Players:GetPlayers()) do
                savePlayerData(player)
            end
        end
    end)
end

local baseContext = {
    Logger = Logger,
    AttributeNames = AttributeNames,
    GameConstants = GameConstants,
}

local actionContexts = {
    [PromptActionTypes.Revivir] = {
        Logger = Logger,
        PlayerStateManager = PlayerStateManager,
        AttributeNames = AttributeNames,
    },
    [PromptActionTypes.Puerta] = {
        Logger = Logger,
        InventoryManager = InventoryManager,
        TweenService = TweenService,
        PromptActionTypes = PromptActionTypes,
        AttributeNames = AttributeNames,
        GameConstants = GameConstants,
        DoorAnimator = DoorAnimator,
        EndgameSequence = EndgameSequence,
    },
    [PromptActionTypes.LeerNota] = {
        Logger = Logger,
        EventShowNotes = EventShowNotes,
        AttributeNames = AttributeNames,
    },
    [PromptActionTypes.PuertaFinal] = {
        Logger = Logger,
        TweenService = TweenService,
        EndgameSequence = EndgameSequence,
        DoorAnimator = DoorAnimator,
        EventEndGame = EventEndGame,
        AttributeNames = AttributeNames,
        GameConstants = GameConstants,
    },
    [PromptActionTypes.Botiquin] = {
        Logger = Logger,
        PlayerStateManager = PlayerStateManager,
        GameConstants = GameConstants,
    },
    [PromptActionTypes.RecogerObjeto] = {
        Logger = Logger,
        InventoryManager = InventoryManager,
        AttributeNames = AttributeNames,
    },
    [PromptActionTypes.Item] = {
        Logger = Logger,
    },
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
        actionModule.Handle(actionContexts[actionType] or baseContext, prompt, player)
    end
end)