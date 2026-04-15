local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))

local Logger = {}

local levelOrder = {
    DEBUG = 10,
    INFO = 20,
    WARN = 30,
    ERROR = 40,
}

local loggerConfig = (((GameConstants or {}).Server or {}).Logger) or {}
local configuredLevel = tostring(loggerConfig.Level or "INFO"):upper()
local minLevel = levelOrder[configuredLevel] or levelOrder.INFO

local function shouldLog(level)
    local value = levelOrder[level] or levelOrder.INFO
    return value >= minLevel
end

local function emit(level, tag, message)
    if not shouldLog(level) then
        return
    end

    local prefix = string.format("[%s][%s] ", level, tag or "APP")
    if level == "WARN" or level == "ERROR" then
        warn(prefix .. tostring(message))
    else
        print(prefix .. tostring(message))
    end
end

function Logger:WithTag(tag)
    local scoped = {}

    function scoped:Debug(message)
        emit("DEBUG", tag, message)
    end

    function scoped:Info(message)
        emit("INFO", tag, message)
    end

    function scoped:Warn(message)
        emit("WARN", tag, message)
    end

    function scoped:Error(message)
        emit("ERROR", tag, message)
    end

    return scoped
end

return Logger