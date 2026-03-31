--[[
    Lambda Arcade: Enhanced Base AI Controller
    Base functions for all AI types
--]]

AA.AI = AA.AI or {}
AA.AI.Base = {}

-- Initialize AI for an entity
function AA.AI.Base:Initialize(ent)
    ent.AIData = {
        initialized = true,
        lastTarget = nil,
        lastTargetPos = Vector(0, 0, 0),
        lastSeenTarget = 0,
        targetLostTime = 0,
        aggression = math.random(0.7, 1.0),
        reactionTime = math.random(0.1, 0.4),
        consecutiveMisses = 0,
        lastAttackTime = 0,
        lastDamageTime = 0,
        strafeDirection = math.random() > 0.5 and 1 or -1,
    }
end

-- Called before attack - return true to override
function AA.AI.Base:OnAttack(ent, target)
    return false
end

-- Called when taking damage - return true to override
function AA.AI.Base:OnTakeDamage(ent, dmg, attacker)
    if not ent.AIData then return false end
    
    -- Update last damage time
    ent.AIData.lastDamageTime = CurTime()
    
    -- Switch target if damaged by someone else
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ent.Target then
        local myPos = ent:GetPos()
        local currentDist = math.huge
        
        if IsValid(ent.Target) then
            local targetPos = ent.Target:GetPos()
            if targetPos and isvector(targetPos) then
                currentDist = myPos:DistTo(targetPos)
            end
        end
        
        local attackerPos = attacker:GetPos()
        if attackerPos and isvector(attackerPos) then
            local newDist = myPos:DistTo(attackerPos)
            
            -- Switch if new attacker is significantly closer
            if newDist < currentDist * 0.6 then
                ent.Target = attacker
            end
        end
    end
    
    return false
end

-- Called on death - return true to override
function AA.AI.Base:OnDeath(ent, attacker)
    return false
end

print("[Lambda Arcade] Enhanced Base AI System initialized")
