--[[
    Arcade Anomaly: Base AI Controller
    Provides behavior modifiers for enemy AI
--]]

AA.AI = AA.AI or {}
AA.AI.Base = {}

function AA.AI.Base:Initialize(ent)
    -- Base initialization - can be overridden
    ent.AIData = {
        initialized = true,
    }
end

-- Called before attack - return true to override
function AA.AI.Base:OnAttack(ent, target)
    return false -- Use default
end

-- Called when taking damage - return true to override
function AA.AI.Base:OnTakeDamage(ent, dmg)
    return false -- Use default
end

-- Called on death - return true to override
function AA.AI.Base:OnDeath(ent, attacker)
    return false -- Use default
end
