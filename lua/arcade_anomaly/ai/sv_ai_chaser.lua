--[[
    Lambda Arcade: Enhanced Chaser AI
    Balanced melee fighter with flanking behavior and persistence
--]]

AA.AI.Chaser = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Chaser:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Chaser-specific stats
    ent.MoveSpeed = ent.MoveSpeed or 180
    ent.RunSpeed = ent.RunSpeed or 280
    ent.AttackRange = ent.AttackRange or 70
    ent.AttackCooldown = ent.AttackCooldown or 0.9
    ent.AttackWindup = ent.AttackWindup or 0.25
    ent.Damage = ent.Damage or 15
    ent.FlankAggressiveness = 0.3 -- Chance to try flanking
    
    -- AI data specific to chaser
    ent.AIData.flankTarget = nil
    ent.AIData.isFlanking = false
    ent.AIData.attackCombo = 0
    ent.AIData.maxCombo = 2
end

function AA.AI.Chaser:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local attackRangeSqr = (ent.AttackRange or 70) ^ 2
    
    -- State machine logic
    if distSqr <= attackRangeSqr then
        -- In attack range
        if CurTime() >= (data.lastAttackTime or 0) + (ent.AttackCooldown or 0.9) then
            self:TransitionState(ent, AA.AI.States.ATTACK)
        else
            -- Circle around target while waiting for cooldown
            self:CircleTarget(ent, target, ent.RunSpeed or 280)
        end
    else
        -- Out of range - chase or flank
        if not data.isFlanking and math.random() < ent.FlankAggressiveness then
            -- Try flanking
            data.isFlanking = true
            data.flankTarget = self:CalculateFlankPoint(ent, target)
        end
        
        if data.isFlanking and data.flankTarget then
            -- Move to flank position
            local distToFlank = myPos:DistToSqr(data.flankTarget)
            if distToFlank < 2500 then -- Within 50 units
                data.isFlanking = false -- Reached flank position, now attack
            else
                self:MoveToFlank(ent, data.flankTarget, ent.RunSpeed or 280)
            end
        else
            -- Direct chase
            self:TransitionState(ent, AA.AI.States.CHASE)
            if AA.Navigation then
                AA.Navigation:Update(ent, targetPos, ent.RunSpeed or 280)
            end
        end
    end
end

function AA.AI.Chaser:CalculateFlankPoint(ent, target)
    local targetPos = target:GetPos()
    local myPos = ent:GetPos()
    
    -- Calculate a point to the side of the target
    local toTarget = (targetPos - myPos):GetNormalized()
    local side = Vector(-toTarget.y, toTarget.x, 0)
    
    -- Pick left or right randomly
    if math.random() > 0.5 then
        side = -side
    end
    
    local flankPoint = targetPos + side * 150 + toTarget * 100
    
    -- Ground the point
    local tr = util.TraceLine({
        start = flankPoint + Vector(0, 0, 100),
        endpos = flankPoint - Vector(0, 0, 200),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        return tr.HitPos + Vector(0, 0, 10)
    end
    
    return flankPoint
end

function AA.AI.Chaser:MoveToFlank(ent, flankPos, speed)
    if not ent.loco then return end
    
    ent:SetAnimState(1) -- Running
    ent.TargetSpeed = speed
    
    if AA.Navigation then
        AA.Navigation:Update(ent, flankPos, speed * 0.8) -- Slower when flanking
    else
        ent.loco:Approach(flankPos, speed * 0.8)
        ent.loco:SetDesiredSpeed(speed * 0.8)
    end
end

function AA.AI.Chaser:CircleTarget(ent, target, speed)
    if not ent.loco then return end
    
    local data = ent.AIData
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    
    -- Circle around while maintaining distance
    local toTarget = (targetPos - myPos):GetNormalized()
    local tangent = Vector(-toTarget.y, toTarget.x, 0) * data.strafeDirection
    
    local goalPos = myPos + tangent * 50
    
    ent:SetAnimState(1)
    ent.TargetSpeed = speed * 0.6
    
    ent.loco:Approach(goalPos, speed * 0.6)
    ent.loco:SetDesiredSpeed(speed * 0.6)
    ent.loco:FaceTowards(targetPos)
end

function AA.AI.Chaser:OnAttack(ent, target)
    local data = ent.AIData
    
    -- Combo attack logic
    data.attackCombo = (data.attackCombo or 0) + 1
    
    if data.attackCombo >= data.maxCombo then
        -- Reset combo after max hits
        data.attackCombo = 0
        data.lastAttackTime = CurTime()
    else
        -- Quick follow-up attack
        data.lastAttackTime = CurTime() + (ent.AttackCooldown or 0.9) * 0.5
    end
    
    -- Slight lunge toward target on attack
    if IsValid(target) then
        local toTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        ent.loco:SetVelocity(toTarget * 200 + Vector(0, 0, 100))
    end
    
    return false -- Let base handle the actual damage
end

function AA.AI.Chaser:OnTakeDamage(ent, dmg, attacker)
    AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
    
    -- Stop flanking if hit
    ent.AIData.isFlanking = false
    ent.AIData.flankTarget = nil
    
    -- Brief speed boost when damaged (berserk reaction)
    if ent:Health() / ent:GetMaxHealth() < 0.3 then
        ent.RunSpeed = (ent.RunSpeed or 280) * 1.2
    end
end

print("[Lambda Arcade] Enhanced Chaser AI initialized")
