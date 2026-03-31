--[[
    Lambda Arcade: Enhanced Rusher AI
    Fast enemy with burst speed ability and hit-and-run tactics
--]]

AA.AI.Rusher = {}

function AA.AI.Rusher:Initialize(ent)
    -- Rusher-specific stats
    ent.BurstSpeed = ent.BurstSpeed or 500
    
    -- AI data
    if ent.AIData then
        ent.AIData.burstCooldown = 0
        ent.AIData.burstDuration = 0
        ent.AIData.isBursting = false
        ent.AIData.lastBurstTime = 0
        ent.AIData.hitAndRunMode = false
        ent.AIData.retreatTarget = nil
    end
end

function AA.AI.Rusher:OnAttack(ent, target)
    -- Lunge attack
    if IsValid(target) and ent.loco then
        local toTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        ent.loco:SetVelocity(toTarget * 300 + Vector(0, 0, 50))
    end
    
    return false -- Let base handle damage
end

function AA.AI.Rusher:OnTakeDamage(ent, dmg, attacker)
    -- Immediately retreat if hit while not bursting
    local data = ent.AIData
    if data and not data.isBursting and not data.hitAndRunMode then
        data.hitAndRunMode = true
        data.retreatEndTime = CurTime() + 1.0
    end
    
    return false -- Let base handle damage
end

print("[Lambda Arcade] Enhanced Rusher AI initialized")
