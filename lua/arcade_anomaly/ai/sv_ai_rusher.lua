--[[
    Lambda Arcade: Enhanced Rusher AI
    Fast enemy with burst speed ability and hit-and-run tactics
--]]

AA.AI.Rusher = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Rusher:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Rusher-specific stats
    ent.MoveSpeed = ent.MoveSpeed or 220
    ent.RunSpeed = ent.RunSpeed or 350
    ent.BurstSpeed = ent.BurstSpeed or 500
    ent.AttackRange = ent.AttackRange or 60
    ent.AttackCooldown = ent.AttackCooldown or 0.7
    ent.AttackWindup = ent.AttackWindup or 0.15
    ent.Damage = ent.Damage or 12
    
    -- Ability cooldowns
    ent.AIData.burstCooldown = 0
    ent.AIData.burstDuration = 0
    ent.AIData.isBursting = false
    ent.AIData.lastBurstTime = 0
    ent.AIData.hitAndRunMode = false
    ent.AIData.retreatTarget = nil
end

function AA.AI.Rusher:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local now = CurTime()
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local attackRangeSqr = (ent.AttackRange or 60) ^ 2
    
    -- Handle burst ability
    if data.isBursting then
        if now > data.burstDuration then
            -- Burst ended
            data.isBursting = false
            data.hitAndRunMode = true
            data.retreatTarget = self:FindRetreatPoint(ent, target)
            data.retreatEndTime = now + 1.5
        end
    end
    
    -- Handle hit-and-run retreat
    if data.hitAndRunMode then
        if now > data.retreatEndTime or (data.retreatTarget and myPos:DistToSqr(data.retreatTarget) < 2500) then
            data.hitAndRunMode = false
            data.retreatTarget = nil
        else
            -- Retreat
            ent:SetAnimState(2) -- Sprinting
            ent.TargetSpeed = ent.RunSpeed or 350
            
            if AA.Navigation and data.retreatTarget then
                AA.Navigation:Update(ent, data.retreatTarget, ent.RunSpeed or 350)
            elseif data.retreatTarget then
                ent.loco:Approach(data.retreatTarget, ent.RunSpeed or 350)
                ent.loco:SetDesiredSpeed(ent.RunSpeed or 350)
            end
            return
        end
    end
    
    -- Combat logic
    if distSqr <= attackRangeSqr then
        -- In attack range - attack
        if now >= (data.lastAttackTime or 0) + (ent.AttackCooldown or 0.7) then
            self:PerformAttack(ent, target)
        end
    else
        -- Out of range - close distance
        local canBurst = now > (data.lastBurstTime or 0) + 4 -- 4 second cooldown
        local shouldBurst = canBurst and distSqr > 40000 and distSqr < 90000 -- 200-300 range
        
        if shouldBurst and not data.isBursting then
            -- Activate burst speed
            self:ActivateBurst(ent, target)
        else
            -- Normal approach
            ent:SetAnimState(1)
            ent.TargetSpeed = data.isBursting and (ent.BurstSpeed or 500) or (ent.RunSpeed or 350)
            
            if AA.Navigation then
                AA.Navigation:Update(ent, targetPos, ent.TargetSpeed)
            else
                ent.loco:Approach(targetPos, ent.TargetSpeed)
                ent.loco:SetDesiredSpeed(ent.TargetSpeed)
                ent.loco:FaceTowards(targetPos)
            end
        end
    end
end

function AA.AI.Rusher:ActivateBurst(ent, target)
    local data = ent.AIData
    
    data.isBursting = true
    data.lastBurstTime = CurTime()
    data.burstDuration = CurTime() + 2.0 -- 2 second burst
    
    -- Visual/audio cue
    if AA.FX and AA.FX.DispatchEffect then
        AA.FX.DispatchEffect(ent:GetPos(), "burst_start")
    end
    
    -- Jump slightly on burst start
    if ent.loco then
        ent.loco:Jump()
    end
end

function AA.AI.Rusher:FindRetreatPoint(ent, threat)
    local myPos = ent:GetPos()
    local threatPos = IsValid(threat) and threat:GetPos() or myPos
    local awayDir = (myPos - threatPos):GetNormalized()
    
    -- Find point away from threat but still in combat range
    local retreatDist = math.random(300, 500)
    local point = myPos + awayDir * retreatDist
    
    -- Add some randomness to direction
    local angle = math.random(-30, 30)
    local rad = math.rad(angle)
    local rotatedDir = Vector(
        awayDir.x * math.cos(rad) - awayDir.y * math.sin(rad),
        awayDir.x * math.sin(rad) + awayDir.y * math.cos(rad),
        0
    )
    
    point = myPos + rotatedDir * retreatDist
    
    -- Ground the point
    local tr = util.TraceLine({
        start = point + Vector(0, 0, 100),
        endpos = point - Vector(0, 0, 200),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        return tr.HitPos + Vector(0, 0, 10)
    end
    
    return point
end

function AA.AI.Rusher:PerformAttack(ent, target)
    local data = ent.AIData
    
    data.lastAttackTime = CurTime()
    
    -- Set attack animation
    ent:SetAnimState(3)
    ent.TargetSpeed = 0
    ent.InAttack = true
    
    -- Quick lunge attack
    if IsValid(target) and ent.loco then
        local toTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        ent.loco:SetVelocity(toTarget * 300 + Vector(0, 0, 50))
    end
    
    -- Damage after windup
    timer.Simple(ent.AttackWindup or 0.15, function()
        if not IsValid(ent) or not IsValid(target) then return end
        
        local distSqr = ent:GetPos():DistToSqr(target:GetPos())
        local range = (ent.AttackRange or 60) * 1.5
        
        if distSqr <= range * range then
            local dmg = DamageInfo()
            dmg:SetDamage(ent.Damage or 12)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(ent)
            dmg:SetInflictor(ent)
            target:TakeDamageInfo(dmg)
        end
        
        ent.InAttack = false
    end)
end

function AA.AI.Rusher:OnTakeDamage(ent, dmg, attacker)
    AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
    
    -- Immediately retreat if hit while not bursting
    local data = ent.AIData
    if not data.isBursting and not data.hitAndRunMode then
        data.hitAndRunMode = true
        data.retreatTarget = self:FindRetreatPoint(ent, attacker)
        data.retreatEndTime = CurTime() + 1.0
    end
end

print("[Lambda Arcade] Enhanced Rusher AI initialized")
