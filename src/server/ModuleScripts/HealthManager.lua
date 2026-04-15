local HealthManager = {}

function HealthManager:InitializeCharacter(character, maxHealth)
    maxHealth = maxHealth or 100
    character:SetAttribute("VidaMaxima", maxHealth)
    character:SetAttribute("VidaActual", maxHealth)
    character:SetAttribute("Invulnerable", false)
end

function HealthManager:GetCurrentHealth(character)
    local current = character:GetAttribute("VidaActual")
    if current ~= nil then
        return current
    end
    -- Fallback consistente: si VidaActual no existe, usar VidaMaxima o 100
    return self:GetMaxHealth(character)
end

function HealthManager:GetMaxHealth(character)
    return character:GetAttribute("VidaMaxima") or 100
end

function HealthManager:ApplyDamage(character, amount)
    local currentHealth = self:GetCurrentHealth(character)
    local maxHealth = self:GetMaxHealth(character)
    local updated = math.clamp(currentHealth - amount, 0, maxHealth)
    character:SetAttribute("VidaActual", updated)
    return updated
end

function HealthManager:Heal(character, amount)
    local currentHealth = self:GetCurrentHealth(character)
    local maxHealth = self:GetMaxHealth(character)
    local updated = math.clamp(currentHealth + amount, 0, maxHealth)
    character:SetAttribute("VidaActual", updated)
    return updated
end

return HealthManager