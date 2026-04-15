local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local PlayerStateManager = require(ModuleScripts:WaitForChild("PlayerStateManager"))
local Logger = require(ModuleScripts:WaitForChild("Logger"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PlayerStates = require(SharedModules:WaitForChild("PlayerStates"))
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local dangersFolder = workspace:WaitForChild("Peligros")

local VISION_RANGE = 100
local AI_UPDATE_INTERVAL = 0.15
local CHASE_SPEED = 12
local PATROL_SPEED = 8
local HOME_RADIUS = 5

local aiConfig = (((GameConstants or {}).Server or {}).AI) or {}
local REPATH_INTERVAL = aiConfig.RepathIntervalSeconds or 1
local REPATH_DISTANCE_THRESHOLD = aiConfig.RepathDistanceThreshold or 6

local aiAccumulator = 0
local navByMonster = {}
local log = Logger:WithTag("Danger")

local function createPath(rootPosition, targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
    })

    local ok = pcall(function()
        path:ComputeAsync(rootPosition, targetPosition)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        return nil
    end

    return path:GetWaypoints()
end

local function issueMove(navState, humanoid, targetPosition)
    if not targetPosition then
        return
    end

    local lastTarget = navState.CurrentMoveTarget
    if not lastTarget or (lastTarget - targetPosition).Magnitude > 1 then
        navState.CurrentMoveTarget = targetPosition
        humanoid:MoveTo(targetPosition)
    end
end

local function ensureNavigationState(monster, humanoid)
    if navByMonster[monster] then
        return navByMonster[monster]
    end

    local state = {
        Waypoints = nil,
        WaypointIndex = 2,
        LastPathBuild = 0,
        LastTargetPosition = nil,
        CurrentMoveTarget = nil,
    }

    state.MoveConnection = humanoid.MoveToFinished:Connect(function(reached)
        if reached and state.Waypoints then
            state.WaypointIndex += 1
        end
    end)

    navByMonster[monster] = state

    monster.AncestryChanged:Connect(function(_, parent)
        if parent then
            return
        end

        local nav = navByMonster[monster]
        if nav and nav.MoveConnection then
            nav.MoveConnection:Disconnect()
        end
        navByMonster[monster] = nil
    end)

    return state
end

local function shouldRepath(navState, destination)
    local now = os.clock()

    if not navState.Waypoints or navState.WaypointIndex > #navState.Waypoints then
        return true
    end

    if now - navState.LastPathBuild >= REPATH_INTERVAL then
        return true
    end

    if not navState.LastTargetPosition then
        return true
    end

    return (destination - navState.LastTargetPosition).Magnitude >= REPATH_DISTANCE_THRESHOLD
end

local function updateNavigation(monster, humanoid, rootPart, destination)
    local navState = ensureNavigationState(monster, humanoid)

    if shouldRepath(navState, destination) then
        navState.Waypoints = createPath(rootPart.Position, destination)
        navState.WaypointIndex = 2
        navState.LastPathBuild = os.clock()
        navState.LastTargetPosition = destination
    end

    local waypoints = navState.Waypoints
    if waypoints and navState.WaypointIndex <= #waypoints then
        local nextWaypoint = waypoints[navState.WaypointIndex]
        if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        issueMove(navState, humanoid, nextWaypoint.Position)
        return
    end

    issueMove(navState, humanoid, destination)
end

local function findClosestHealthyTarget(monsterRoot)
    local nearestRoot = nil
    local nearestDistance = VISION_RANGE

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local stateByAttribute = character:GetAttribute("Estado") or PlayerStates.Healthy
            local stateByManager = PlayerStateManager:GetPlayerState(player)
            if stateByAttribute ~= PlayerStates.Downed and stateByManager == PlayerStates.Healthy then
                local distance = (hrp.Position - monsterRoot.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestRoot = hrp
                end
            end
        end
    end

    return nearestRoot
end

local function initializeAttack(monster)
    local rootPart = monster:WaitForChild("HumanoidRootPart")
    local nextAllowedAttack = 0
    local damage = monster:GetAttribute("Dano") or 34

    rootPart.Touched:Connect(function(hit)
        if os.clock() < nextAllowedAttack then
            return
        end

        if not monster.Parent then
            return
        end

        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        local invulnerable = character:GetAttribute("Invulnerable")
        local state = PlayerStateManager:GetPlayerState(player)
        if not invulnerable and state == PlayerStates.Healthy then
            nextAllowedAttack = os.clock() + 2
            PlayerStateManager:TakeDamage(player, damage)
            log:Debug("Monstruo dano a " .. player.Name)
        end
    end)
end

local function initializeMonster(monster)
    if not monster:IsA("Model") then
        return
    end

    local humanoid = monster:FindFirstChild("Humanoid")
    local rootPart = monster:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then
        return
    end

    monster:SetAttribute("PosicionOrigen", rootPart.Position)

    for _, part in ipairs(monster:GetDescendants()) do
        if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
            part:SetNetworkOwner(nil)
        end
    end

    initializeAttack(monster)
    ensureNavigationState(monster, humanoid)
end

for _, monster in ipairs(dangersFolder:GetChildren()) do
    initializeMonster(monster)
end

dangersFolder.ChildAdded:Connect(function(child)
    initializeMonster(child)
end)

RunService.Heartbeat:Connect(function(dt)
    aiAccumulator += dt
    if aiAccumulator < AI_UPDATE_INTERVAL then
        return
    end
    aiAccumulator = 0

    for _, monster in ipairs(dangersFolder:GetChildren()) do
        local humanoid = monster:FindFirstChild("Humanoid")
        local rootPart = monster:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then
            continue
        end

        local targetRoot = findClosestHealthyTarget(rootPart)
        if targetRoot then
            humanoid.WalkSpeed = CHASE_SPEED
            updateNavigation(monster, humanoid, rootPart, targetRoot.Position)
        else
            local origin = monster:GetAttribute("PosicionOrigen")
            if typeof(origin) == "Vector3" then
                local distanceToOrigin = (rootPart.Position - origin).Magnitude
                if distanceToOrigin > HOME_RADIUS then
                    humanoid.WalkSpeed = PATROL_SPEED
                    updateNavigation(monster, humanoid, rootPart, origin)
                else
                    humanoid.WalkSpeed = 0
                    local navState = navByMonster[monster]
                    if navState then
                        navState.Waypoints = nil
                        navState.CurrentMoveTarget = nil
                    end
                end
            end
        end
    end
end)
