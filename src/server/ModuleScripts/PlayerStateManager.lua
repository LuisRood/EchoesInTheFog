local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PlayerStates = require(SharedModules:WaitForChild("PlayerStates"))

local HealthManager = require(script.Parent:WaitForChild("HealthManager"))
local RespawnManager = require(script.Parent:WaitForChild("RespawnManager"))
local BleedoutTimer = require(script.Parent:WaitForChild("BleedoutTimer"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local PlayerStateManager = {}

local playerStates = {}
local log = Logger:WithTag("PlayerState")

local BLEEDOUT_SECONDS = 30
local REVIVE_PROMPT_NAME = "Revivir"

local function getCharacter(player)
    return player and player.Character
end

local function getRootPart(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function ensureRevivePrompt(character)
    local rootPart = getRootPart(character)
    if not rootPart then
        return
    end

    if rootPart:FindFirstChild(REVIVE_PROMPT_NAME) then
        return
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = REVIVE_PROMPT_NAME
    prompt.ActionText = "Levantar"
    prompt.ObjectText = "Compañera Caída"
    prompt.HoldDuration = 3
    prompt.RequiresLineOfSight = false
    prompt.Parent = rootPart
end

local function removeRevivePrompt(character)
    local rootPart = getRootPart(character)
    if not rootPart then
        return
    end

    local prompt = rootPart:FindFirstChild(REVIVE_PROMPT_NAME)
    if prompt then
        prompt:Destroy()
    end
end

function PlayerStateManager:SetPlayerState(player, newState)
    playerStates[player.UserId] = newState

    local character = getCharacter(player)
    if not character then
        return
    end

    character:SetAttribute("Estado", newState)

    if newState == PlayerStates.Downed then
        ensureRevivePrompt(character)
        log:Info(player.Name .. " cayo abatida")

        BleedoutTimer:Start(player, BLEEDOUT_SECONDS, function()
            if self:GetPlayerState(player) == PlayerStates.Downed then
                log:Info("Tiempo de desangrado agotado para " .. player.Name)
                self:ExecuteRespawn(player)
            end
        end)
        return
    end

    BleedoutTimer:Stop(player)
    removeRevivePrompt(character)

    local currentHealth = HealthManager:GetCurrentHealth(character)
    if currentHealth < 30 then
        character:SetAttribute("VidaActual", 30)
    end

    character:SetAttribute("Invulnerable", true)
    local userId = player.UserId
    task.delay(3, function()
        local currentPlayer = Players:GetPlayerByUserId(userId)
        local currentCharacter = currentPlayer and currentPlayer.Character
        if currentCharacter and currentCharacter.Parent then
            currentCharacter:SetAttribute("Invulnerable", false)
        end
    end)

    log:Info(player.Name .. " esta de pie")
end

function PlayerStateManager:SetState(player, newState)
    self:SetPlayerState(player, newState)
end

function PlayerStateManager:GetPlayerState(player)
    return playerStates[player.UserId] or PlayerStates.Healthy
end

function PlayerStateManager:GetState(player)
    return self:GetPlayerState(player)
end

function PlayerStateManager:TakeDamage(player, amount)
    local character = getCharacter(player)
    if not character then
        return
    end

    if self:GetPlayerState(player) == PlayerStates.Downed then
        return
    end

    if character:GetAttribute("Invulnerable") then
        return
    end

    local updatedHealth = HealthManager:ApplyDamage(character, amount)
    log:Debug(string.format("%s recibio %.2f dano. Vida: %.2f", player.Name, amount, updatedHealth))

    if updatedHealth <= 0 then
        self:SetPlayerState(player, PlayerStates.Downed)
    end
end

function PlayerStateManager:Heal(player, amount)
    local character = getCharacter(player)
    if not character then
        return
    end

    if self:GetPlayerState(player) == PlayerStates.Downed then
        return
    end

    local updatedHealth = HealthManager:Heal(character, amount)
    log:Debug(string.format("%s se curo %.2f. Vida: %.2f", player.Name, amount, updatedHealth))
end

function PlayerStateManager:ExecuteRespawn(player)
    local character = getCharacter(player)
    if not character then
        return
    end

    local maxHealth = HealthManager:GetMaxHealth(character)
    character:SetAttribute("VidaActual", maxHealth)

    self:SetPlayerState(player, PlayerStates.Healthy)
    local success = RespawnManager:Execute(player)

    if success then
        log:Info(player.Name .. " reaparecio")
    else
        log:Warn("No se pudo completar respawn para " .. player.Name)
    end
end

function PlayerStateManager:EjecutarRespawn(player)
    self:ExecuteRespawn(player)
end

local function initializeCharacter(player, character)
    playerStates[player.UserId] = PlayerStates.Healthy
    character:SetAttribute("Estado", PlayerStates.Healthy)

    HealthManager:InitializeCharacter(character, 100)

    local savedCheckpoint = player:GetAttribute("UltimoCheckpoint")
    if typeof(savedCheckpoint) == "CFrame" then
        character:SetAttribute("UltimoCheckpoint", savedCheckpoint)
    end
end

local function initializePlayer(player)
    if player.Character then
        initializeCharacter(player, player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        initializeCharacter(player, character)
    end)
end

Players.PlayerAdded:Connect(initializePlayer)

Players.PlayerRemoving:Connect(function(player)
    playerStates[player.UserId] = nil
    BleedoutTimer:Stop(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    initializePlayer(player)
end

return PlayerStateManager
