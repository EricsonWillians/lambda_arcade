--[[
    Lambda Arcade: Enhanced Elite AI
    Enhanced enemy with special abilities
--]]

AA.AI.Elite = {}

function AA.AI.Elite:Initialize(ent)
    -- Elite stats - boost health
    local newHealth = (ent:Health() or 100) * 1.5
    ent:SetHealth(newHealth)
    ent:SetMaxHealth(newHealth)
    
    -- AI data
    if ent.AIData then
        ent.AIData.rageTriggered = false
        ent.AIData.canHeal = true
        ent.AIData.healCooldown = 0
    end
end

function AA.AI.Elite:OnAttack(ent, target)
    -- Apply brief slow to target
    if IsValid(target) then
        target.AA_Slowed = true
        timer.Simple(1.0, function()
            if IsValid(target) then target.AA_Slowed = nil end
        end)
    end
    
    return false
end

function AA.AI.Elite:OnTakeDamage(ent, dmg, attacker)
    local data = ent.AIData
    if not data then return false end
    
    -- Trigger rage at 50% health
    local healthPercent = ent:Health() / ent:GetMaxHealth()
    if healthPercent <= 0.5 and not data.rageTriggered then
        data.rageTriggered = true
        ent:SetColor(Color(255, 50, 50))
        ent.RunSpeed = (ent.RunSpeed or 300) * 1.3
        ent.Damage = (ent.Damage or 25) * 1.2
    end
    
    return false
end

function AA.AI.Elite:OnDeath(ent, attacker)
    -- Explosion on death
    local myPos = ent:GetPos()
    local effect = EffectData()
    effect:SetOrigin(myPos)
    effect:SetRadius(150)
    util.Effect("Explosion", effect)
    
    -- Damage nearby
    local nearby = ents.FindInSphere(myPos, 150)
    for _, hit in ipairs(nearby) do
        if hit:IsPlayer() then
            local dmg = DamageInfo()
            dmg:SetDamage(20)
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(ent)
            hit:TakeDamageInfo(dmg)
        end
    end
    
    return false
end

print("[Lambda Arcade] Enhanced Elite AI initialized")
