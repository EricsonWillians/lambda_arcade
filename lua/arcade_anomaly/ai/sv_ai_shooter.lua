--[[
    Lambda Arcade: Enhanced Shooter AI
    Ranged enemy that maintains distance, finds cover, and lays down suppressive fire
--]]

AA.AI.Shooter = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Shooter:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Shooter-specific stats
    ent.MoveSpeed = ent.MoveSpeed or 140
    ent.RunSpeed = ent.RunSpeed or 220
    ent.AttackRange = ent.AttackRange or 1500
    ent.AttackCooldown = ent.AttackCooldown or 1.2
    ent.AttackWindup = ent.AttackWindup or 0.3
    ent.Damage = ent.Damage or 10
    ent.PreferredDistance = ent.PreferredDistance or 600 -- Ideal combat range
    ent.MinDistance = ent.MinDistance or 300 -- Too close
    ent.MaxDistance = ent.MaxDistance or 1200 -- Too far
    
    -- AI data
    ent.AIData.lastShotTime = 0
    ent.AIData.shotsInBurst = 0
    ent.AIData.maxBurstSize = 3
    ent.AIData.coverTarget = nil
    ent.AIData.isInCover = false
    ent.AIData.coverExitTime = 0
    ent.AIData.repositioning = false
    ent.AIData.suppressionMode = false
end

function AA.AI.Shooter:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local now = CurTime()
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local dist = math.sqrt(distSqr)
    local hasLOS = ent:HasLineOfSight and ent:HasLineOfSight(target) or true
    
    -- Cover logic
    if data.isInCover then
        if now > data.coverExitTime then
            -- Peek and shoot
            data.isInCover = false
            data.shotsInBurst = 0
        else
            -- Stay in cover
            ent:SetAnimState(0)
            ent.TargetSpeed = 0
            return
        end
    end
    
    -- Distance-based behavior
    if dist < (ent.MinDistance or 300) then
        -- Too close - retreat or find cover
        if not data.coverTarget then
            data.coverTarget = self:FindCover(ent, target)
        end
        
        if data.coverTarget then
            -- Move to cover
            ent:SetAnimState(2)
            ent.TargetSpeed = ent.RunSpeed or 220
            
            if AA.Navigation then
                AA.Navigation:Update(ent, data.coverTarget, ent.RunSpeed or 220)
            else
                ent.loco:Approach(data.coverTarget, ent.RunSpeed or 220)
                ent.loco:SetDesiredSpeed(ent.RunSpeed or 220)
            end
            
            -- Check if reached cover
            if myPos:DistToSqr(data.coverTarget) < 2500 then
                data.isInCover = true
                data.coverExitTime = now + math.random(1.5, 3.0)
                data.coverTarget = nil
            end
        else
            -- No cover, kite backward
            self:KiteTarget(ent, target, ent.RunSpeed or 220)
        end
        
    elseif dist > (ent.MaxDistance or 1200) then
        -- Too far - close in
        data.coverTarget = nil
        ent:SetAnimState(1)
        ent.TargetSpeed = ent.RunSpeed or 220
        
        if AA.Navigation then
            AA.Navigation:Update(ent, targetPos, ent.RunSpeed or 220)
        else
            ent.loco:Approach(targetPos, ent.RunSpeed or 220)
            ent.loco:SetDesiredSpeed(ent.RunSpeed or 220)
            ent.loco:FaceTowards(targetPos)
        end
        
    else
        -- Good distance - maintain and shoot
        data.coverTarget = nil
        
        if hasLOS then
            -- Can shoot
            if now >= (data.lastShotTime or 0) + (ent.AttackCooldown or 1.2) then
                self:TryShoot(ent, target)
            else
                -- Strafe while waiting
                self:StrafeMaintainDistance(ent, target, ent.PreferredDistance or 600)
            end
        else
            -- No LOS, reposition
            ent:SetAnimState(1)
            ent.TargetSpeed = ent.MoveSpeed or 140
            
            -- Try to find angle with LOS
            local newAngle = self:FindLOSAngle(ent, target)
            if newAngle then
                local targetPoint = targetPos + newAngle * 300
                if AA.Navigation then
                    AA.Navigation:Update(ent, targetPoint, ent.MoveSpeed or 140)
                else
                    ent.loco:Approach(targetPoint, ent.MoveSpeed or 140)
                end
            else
                -- Move closer to guarantee LOS
                if AA.Navigation then
                    AA.Navigation:Update(ent, targetPos, ent.MoveSpeed or 140)
                else
                    ent.loco:Approach(targetPos, ent.MoveSpeed or 140)
                end
            end
        end
    end
end

function AA.AI.Shooter:FindCover(ent, threat)
    local myPos = ent:GetPos()
    local threatPos = IsValid(threat) and threat:GetPos() or myPos
    local awayDir = (myPos - threatPos):GetNormalized()
    
    local bestCover = nil
    local bestScore = -math.huge
    
    -- Check multiple directions for cover
    for angle = -90, 90, 30 do
        local rad = math.rad(angle)
        local checkDir = Vector(
            awayDir.x * math.cos(rad) - awayDir.y * math.sin(rad),
            awayDir.x * math.sin(rad) + awayDir.y * math.cos(rad),
            0
        )
        
        local checkDist = math.random(200, 400)
        local checkPos = myPos + checkDir * checkDist
        
        -- Check if position blocks LOS from threat
        local losTrace = util.TraceLine({
            start = checkPos + Vector(0, 0, 48),
            endpos = threatPos + Vector(0, 0, 48),
            mask = MASK_SOLID,
        })
        
        if losTrace.Hit then
            -- Good cover found
            local groundTrace = util.TraceLine({
                start = checkPos + Vector(0, 0, 100),
                endpos = checkPos - Vector(0, 0, 200),
                mask = MASK_SOLID,
            })
            
            if groundTrace.Hit then
                local coverPos = groundTrace.HitPos + Vector(0, 0, 10)
                
                -- Score based on distance (not too far, not too close)
                local distFromThreat = coverPos:DistTo(threatPos)
                local score = 0
                
                if distFromThreat > 400 and distFromThreat < 1000 then
                    score = score + 10
                end
                
                -- Prefer positions we can shoot from
                local peekTrace = util.TraceLine({
                    start = coverPos + checkDir * 50 + Vector(0, 0, 48),
                    endpos = threatPos + Vector(0, 0, 48),
                    mask = MASK_SOLID,
                })
                if not peekTrace.Hit then
                    score = score + 20 -- Can shoot from here
                end
                
                if score > bestScore then
                    bestScore = score
                    bestCover = coverPos
                end
            end
        end
    end
    
    return bestCover
end

function AA.AI.Shooter:KiteTarget(ent, target, speed)
    if not ent.loco then return end
    
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local awayDir = (myPos - targetPos):GetNormalized()
    
    -- Add lateral movement
    local lateral = Vector(-awayDir.y, awayDir.x, 0) * ent.AIData.strafeDirection
    local goalDir = (awayDir * 0.8 + lateral * 0.4):GetNormalized()
    local goalPos = myPos + goalDir * 200
    
    ent:SetAnimState(2)
    ent.TargetSpeed = speed
    
    if AA.Navigation then
        AA.Navigation:Update(ent, goalPos, speed)
    else
        ent.loco:Approach(goalPos, speed)
        ent.loco:SetDesiredSpeed(speed)
    end
    
    ent.loco:FaceTowards(targetPos)
end

function AA.AI.Shooter:StrafeMaintainDistance(ent, target, preferredDist)
    if not ent.loco then return end
    
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local dist = myPos:DistTo(targetPos)
    local data = ent.AIData
    
    -- Calculate desired movement
    local toTarget = (targetPos - myPos):GetNormalized()
    local lateral = Vector(-toTarget.y, toTarget.x, 0) * data.strafeDirection
    
    -- Adjust distance
    local distCorrection = 0
    if dist > preferredDist + 100 then
        distCorrection = 0.5 -- Move closer
    elseif dist < preferredDist - 100 then
        distCorrection = -0.5 -- Back away
    end
    
    local goalDir = (lateral * 0.7 + toTarget * distCorrection):GetNormalized()
    local goalPos = myPos + goalDir * 100
    
    ent:SetAnimState(1)
    ent.TargetSpeed = ent.MoveSpeed or 140
    
    ent.loco:Approach(goalPos, ent.MoveSpeed or 140)
    ent.loco:SetDesiredSpeed(ent.MoveSpeed or 140)
    ent.loco:FaceTowards(targetPos)
end

function AA.AI.Shooter:FindLOSAngle(ent, target)
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local toTarget = (targetPos - myPos):GetNormalized()
    
    -- Try different angles
    for angle = -60, 60, 20 do
        local rad = math.rad(angle)
        local testDir = Vector(
            toTarget.x * math.cos(rad) - toTarget.y * math.sin(rad),
            toTarget.x * math.sin(rad) + toTarget.y * math.cos(rad),
            0
        )
        
        local testPos = myPos + testDir * 300
        local losTrace = util.TraceLine({
            start = testPos + Vector(0, 0, 48),
            endpos = targetPos + Vector(0, 0, 48),
            mask = MASK_SOLID,
        })
        
        if not losTrace.Hit then
            return testDir
        end
    end
    
    return nil
end

function AA.AI.Shooter:TryShoot(ent, target)
    local data = ent.AIData
    
    data.lastShotTime = CurTime()
    data.shotsInBurst = (data.shotsInBurst or 0) + 1
    
    -- Fire projectile
    if ent.ShootProjectile then
        ent:ShootProjectile(target)
    end
    
    -- Check if burst is complete
    if data.shotsInBurst >= (data.maxBurstSize or 3) then
        data.shotsInBurst = 0
        -- Take cover or reposition after burst
        if math.random() < 0.4 then
            data.coverTarget = self:FindCover(ent, target)
        end
    end
end

function AA.AI.Shooter:OnTakeDamage(ent, dmg, attacker)
    AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
    
    -- Immediately seek cover when hit
    local data = ent.AIData
    if not data.isInCover then
        data.coverTarget = self:FindCover(ent, attacker)
    end
end

print("[Lambda Arcade] Enhanced Shooter AI initialized")
