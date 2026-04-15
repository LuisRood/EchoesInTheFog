local PlayerStates = {
    Healthy = "Sano",
    Downed = "Abatido",
}

-- Aliases para backward compatibility
PlayerStates.Sano = PlayerStates.Healthy
PlayerStates.Abatido = PlayerStates.Downed

-- Legacy state mapping para DataStore/atributos antiguos
local legacyMap = {
    ["Sano"] = PlayerStates.Healthy,
    ["Healthy"] = PlayerStates.Healthy,
    ["Abatido"] = PlayerStates.Downed,
    ["Downed"] = PlayerStates.Downed,
}

---Normaliza un estado al valor canonical, soporta aliases y valores legacy
---@param state string? El estado a normalizar
---@return string El estado canonical (PlayerStates.Healthy o PlayerStates.Downed)
function PlayerStates:Normalize(state)
    if not state or typeof(state) ~= "string" then
        return self.Healthy -- default a sano si es nil o tipo incorrecto
    end
    
    local normalized = legacyMap[state]
    if normalized then
        return normalized
    end
    
    -- Si no está en el map, devolver Healthy como fallback seguro
    return self.Healthy
end

return PlayerStates