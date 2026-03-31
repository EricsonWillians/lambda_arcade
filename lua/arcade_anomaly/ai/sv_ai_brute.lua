--[[
    Lambda Arcade: Enhanced Brute AI
    Slow but powerful tank with charge ability
--]]

AA.AI.Brute = {}

function AA.AI.Brute:Initialize(ent)
    -- Brute-specific stats
    ent.ChargeSpeed = ent.ChargeSpeed or 400
    ent.KnockbackPower = ent.KnockbackPower or 300
    
    -- AI data
    if ent.AIData then
        ent.AIData.chargeCooldown = 0
        ent.AIData.isCharging = false
        ent.AIData.groundSlamReady = true
    end
end

function AA.AI.Brute:OnTakeDamage(ent, dmg, attacker)
    -- Rage mechanic - speed up when damaged
    local healthPercent = ent:Health() / ent:GetMaxHealth()
    if healthPercent < 0.5 then
        ent.RunSpeed = 180 * (1.5 - healthPercent) -- Up to 50% faster
    end
    
    return false
end

print("[Lambda Arcade] Enhanced Brute AI initialized")
