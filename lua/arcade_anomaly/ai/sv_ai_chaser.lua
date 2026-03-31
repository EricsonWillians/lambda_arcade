--[[
    Lambda Arcade: Enhanced Chaser AI
    Balanced melee fighter with flanking behavior and persistence
--]]

AA.AI.Chaser = {}

function AA.AI.Chaser:Initialize(ent)
    -- Chaser-specific stats
    ent.FlankAggressiveness = 0.3 -- Chance to try flanking
    
    -- AI data specific to chaser
    if ent.AIData then
        ent.AIData.flankTarget = nil
        ent.AIData.isFlanking = false
        ent.AIData.attackCombo = 0
        ent.AIData.maxCombo = 2
    end
end

function AA.AI.Chaser:OnAttack(ent, target)
    local data = ent.AIData
    if not data then return false end
    
    -- Combo attack logic
    data.attackCombo = (data.attackCombo or 0) + 1
    
    if data.attackCombo >= data.maxCombo then
        -- Reset combo after max hits
        data.attackCombo = 0
        ent.NextAttack = CurTime() + (ent.AttackCooldown or 0.9)
    else
        -- Quick follow-up attack
        ent.NextAttack = CurTime() + (ent.AttackCooldown or 0.9) * 0.5
    end
    
    -- Slight lunge toward target on attack
    if IsValid(target) and ent.loco then
        local toTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        ent.loco:SetVelocity(toTarget * 200 + Vector(0, 0, 100))
    end
    
    return false -- Let base handle the actual damage
end

function AA.AI.Chaser:OnTakeDamage(ent, dmg, attacker)
    -- Stop flanking if hit
    if ent.AIData then
        ent.AIData.isFlanking = false
        ent.AIData.flankTarget = nil
    end
    
    -- Brief speed boost when damaged (berserk reaction)
    if ent:Health() / ent:GetMaxHealth() < 0.3 then
        ent.RunSpeed = (ent.RunSpeed or 280) * 1.2
    end
    
    return false -- Let base handle damage
end

print("[Lambda Arcade] Enhanced Chaser AI initialized")
