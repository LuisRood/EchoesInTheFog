local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local donationConfig = (((GameConstants or {}).Server or {}).Donations) or {}
local storeName = donationConfig.StoreName or "EchoesInTheFog_Donations_V1"

local DonorLeaderboardService = {}
local nameCache = {}

local function formatAmount(amount)
    return tostring(math.max(0, math.floor(tonumber(amount) or 0))) .. " R$"
end

local function getNameForUserId(userId)
    if not userId then
        return "VACANTE"
    end

    if nameCache[userId] then
        return nameCache[userId]
    end

    local player = Players:GetPlayerByUserId(userId)
    if player then
        nameCache[userId] = player.DisplayName ~= "" and player.DisplayName or player.Name
        return nameCache[userId]
    end

    local ok, name = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)

    if ok and name then
        nameCache[userId] = name
        return name
    end

    return "Usuario " .. tostring(userId)
end

local function setText(root, labelName, text)
    local label = root:FindFirstChild(labelName, true)
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
end

function DonorLeaderboardService:GetTopDonors(limit)
    local ok, pages = pcall(function()
        local dataStore = DataStoreService:GetOrderedDataStore(storeName)
        return dataStore:GetSortedAsync(false, limit)
    end)

    if not ok then
        return nil, pages
    end

    local entries = {}
    for rank, entry in ipairs(pages:GetCurrentPage()) do
        local userId = tonumber(entry.key)
        local amount = tonumber(entry.value) or 0
        table.insert(entries, {
            Rank = rank,
            UserId = userId,
            Name = getNameForUserId(userId),
            Amount = amount,
        })
    end

    return entries, nil
end

function DonorLeaderboardService:ApplyToShowcase(showcase, entries)
    local byRank = {}
    for rank, entry in ipairs(entries or {}) do
        byRank[entry.Rank or rank] = entry
    end

    for rank = 1, 3 do
        local entry = byRank[rank]
        setText(showcase, "DonorRank_" .. tostring(rank) .. "_Name", entry and entry.Name or "VACANTE")
        setText(showcase, "DonorRank_" .. tostring(rank) .. "_Amount", formatAmount(entry and entry.Amount or 0))
    end

    for rank = 4, 10 do
        local entry = byRank[rank]
        local text = "#" .. tostring(rank) .. "  VACANTE"
        if entry then
            text = "#" .. tostring(rank) .. "  " .. tostring(entry.Name) .. " - " .. formatAmount(entry.Amount)
        end

        setText(showcase, "DonorBoard_" .. tostring(rank), text)
    end
end

return DonorLeaderboardService
