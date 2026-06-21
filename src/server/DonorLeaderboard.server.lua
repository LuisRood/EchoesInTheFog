local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local Logger = require(ModuleScripts:WaitForChild("Logger"))
local DonorLeaderboardService = require(ModuleScripts:WaitForChild("DonorLeaderboardService"))

local log = Logger:WithTag("Donors")
local donationConfig = (((GameConstants or {}).Server or {}).Donations) or {}

if donationConfig.Enabled == false then
    log:Info("Ranking de donadores deshabilitado")
    return
end

local function findShowcase()
    local lobby = Workspace:FindFirstChild("Lobby")
    local hub = lobby and lobby:FindFirstChild("Hub_Multijugador")
    local decor = hub and hub:FindFirstChild("Decoracion")
    return decor and decor:FindFirstChild("DonorShowcase")
end

task.spawn(function()
    local showcase = findShowcase()
    local startedAt = os.clock()
    while not showcase and os.clock() - startedAt < 30 do
        task.wait(1)
        showcase = findShowcase()
    end

    if not showcase then
        log:Warn("No se encontro DonorShowcase en el lobby")
        return
    end

    local refreshSeconds = math.max(30, tonumber(donationConfig.RefreshSeconds) or 120)

    while showcase.Parent do
        local entries, err = DonorLeaderboardService:GetTopDonors(10)
        if entries then
            DonorLeaderboardService:ApplyToShowcase(showcase, entries)
        else
            DonorLeaderboardService:ApplyToShowcase(showcase, {})
            log:Warn("No se pudo leer ranking de donadores: " .. tostring(err))
        end

        task.wait(refreshSeconds)
    end
end)
