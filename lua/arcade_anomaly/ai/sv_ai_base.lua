--[[
    Lambda Arcade: Enhanced Base AI Controller
    Provides sophisticated behavior states, tactical decisions, and group coordination
--]]

AA.AI = AA.AI or {}
AA.AI.Base = {}

-- AI State definitions
AA.AI.States = {
    IDLE = "idle",
    CHASE = "chase",
    ATTACK = "attack",
    SEARCH = "search",
    FLEE = "flee",
    REPOSITION = "reposition",
    STUNNED = "stunned",
    DEAD = "dead",
}

-- Initialize AI for an entity
function AA.AI.Base:Initialize(ent)
    ent.AIData = {
        initialized = true,
        state = AA.AI.States.IDLE,
        stateTime = 0,
        lastTarget = nil,
        lastTargetPos = Vector(0, 0, 0),
        lastSeenTarget = 0,
        targetLostTime = 0,
        aggression = math.random(0.7, 1.0), -- Individual variance
        reactionTime = math.random(0.1, 0.4),
        tacticalCooldown = 0,
        consecutiveMisses = 0,
        lastAttackTime = 0,
        preferredDistance = nil, -- For shooters
        strafeDirection = math.random() > 0.5 and 1 or -1,
        strafeChangeTime = 0,
    }
    
    -- Initialize navigation
    if AA.Navigation then
        AA.Navigation:Initialize(ent)
    end
end

-- Main AI think - called regularly
function AA.AI.Base:Think(ent)
    if not ent.AIData then
        self:Initialize(ent)
        return
    end
    
    local data = ent.AIData
    local now = CurTime()
    
    -- Update state timer
    data.stateTime = data.stateTime + FrameTime()
    
    -- Process tactical cooldowns
    if data.tacticalCooldown > 0 then
        data.tacticalCooldown = data.tacticalCooldown - FrameTime()
    end
    
    -- Change strafe direction periodically
    if now > data.strafeChangeTime then
        data.strafeDirection = -data.strafeDirection
        data.strafeChangeTime = now + math.random(1.5, 3.5)
    end
end

-- Evaluate if we should change targets
function AA.AI.Base:EvaluateTarget(ent, currentTarget, potentialTargets)
    if not IsValid(currentTarget) then
        return potentialTargets[1] -- Take nearest
    end
    
    local myPos = ent:GetPos()
    local currentDist = myPos:DistToSqr(currentTarget:GetPos())
    
    -- Check if there's a much closer target
    for _, potential in ipairs(potentialTargets) do
        if IsValid(potential) and potential ~= currentTarget then
            local dist = myPos:DistToSqr(potential:GetPos())
            -- Switch if new target is significantly closer (50%+ closer)
            if dist < currentDist * 0.5 then
                return potential
            end
        end
    end
    
    return currentTarget
end

-- Called when entity sees its target
function AA.AI.Base:OnTargetSighted(ent, target)
    local data = ent.AIData
    data.lastSeenTarget = CurTime()
    data.lastTargetPos = target:GetPos()
    data.consecutiveMisses = 0 -- Reset miss counter on new sighting
    
    -- Transition to chase if we were searching
    if data.state == AA.AI.States.SEARCH then
        self:TransitionState(ent, AA.AI.States.CHASE)
    end
end

-- Called when target is lost
function AA.AI.Base:OnTargetLost(ent, lastKnownPos)
    local data = ent.AIData
    data.targetLostTime = CurTime()
    data.lastTargetPos = lastKnownPos
    
    self:TransitionState(ent, AA.AI.States.SEARCH)
end

-- State transition helper
function AA.AI.Base:TransitionState(ent, newState)
    local data = ent.AIData
    if not data then return end
    
    if data.state ~= newState then
        -- Exit old state
        self:OnStateExit(ent, data.state)
        
        -- Enter new state
        data.state = newState
        data.stateTime = 0
        
        self:OnStateEnter(ent, newState)
    end
end

-- Called when entering a state
function AA.AI.Base:OnStateEnter(ent, state)
    if state == AA.AI.States.CHASE then
        -- Start chasing immediately
    elseif state == AA.AI.States.SEARCH then
        -- Initialize search
        self:InitializeSearch(ent)
    elseif state == AA.AI.States.ATTACK then
        -- Prepare attack
    elseif state == AA.AI.States.REPOSITION then
        -- Start repositioning
        self:PickRepositionPoint(ent)
    end
end

-- Called when exiting a state
function AA.AI.Base:OnStateExit(ent, state)
    -- Cleanup per-state data
end

-- Initialize search behavior
function AA.AI.Base:InitializeSearch(ent)
    local data = ent.AIData
    data.searchStartTime = CurTime()
    data.searchPoints = self:GenerateSearchPoints(ent, data.lastTargetPos)
    data.currentSearchPoint = 1
end

-- Generate points to search around last known position
function AA.AI.Base:GenerateSearchPoints(ent, basePos)
    local points = {}
    local numPoints = math.random(3, 5)
    
    for i = 1, numPoints do
        local angle = (i / numPoints) * math.pi * 2
        local dist = math.random(100, 300)
        local offset = Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
        
        local point = basePos + offset
        
        -- Ground the point
        local tr = util.TraceLine({
            start = point + Vector(0, 0, 100),
            endpos = point - Vector(0, 0, 200),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            point = tr.HitPos + Vector(0, 0, 10)
            table.insert(points, point)
        end
    end
    
    return points
end

-- Pick a reposition point (for tactical movement)
function AA.AI.Base:PickRepositionPoint(ent)
    local data = ent.AIData
    local myPos = ent:GetPos()
    
    -- Try to find cover or better position
    local candidates = {}
    
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local dist = math.random(150, 400)
        local offset = Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
        local point = myPos + offset
        
        -- Check if valid
        local tr = util.TraceLine({
            start = point + Vector(0, 0, 100),
            endpos = point - Vector(0, 0, 200),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            point = tr.HitPos + Vector(0, 0, 10)
            
            -- Score this point based on various factors
            local score = 0
            
            -- Prefer positions with cover
            local coverTrace = util.TraceLine({
                start = point + Vector(0, 0, 48),
                endpos = point + Vector(0, 0, 48) + offset:GetNormalized() * 100,
                mask = MASK_SOLID,
            })
            if coverTrace.Hit then score = score + 10 end
            
            -- Avoid being too close or too far from target
            if data.lastTarget then
                local distToTarget = point:DistTo(data.lastTargetPos)
                if distToTarget > 300 and distToTarget < 800 then
                    score = score + 5
                end
            end
            
            table.insert(candidates, {pos = point, score = score})
        end
    end
    
    -- Sort by score and pick best
    table.sort(candidates, function(a, b) return a.score > b.score end)
    
    if #candidates > 0 then
        data.repositionTarget = candidates[1].pos
    else
        -- Fallback to random nearby point
        data.repositionTarget = myPos + Vector(math.random(-200, 200), math.random(-200, 200), 0)
    end
end

-- Perform strafing movement during combat
function AA.AI.Base:StrafeMovement(ent, targetPos, speed)
    if not IsValid(ent) or not ent.loco then return end
    
    local data = ent.AIData
    local myPos = ent:GetPos()
    local toTarget = (targetPos - myPos):GetNormalized()
    
    -- Calculate strafe direction
    local strafe = Vector(-toTarget.y, toTarget.x, 0) * data.strafeDirection
    
    -- Check if strafe direction is clear
    local strafeTrace = util.TraceHull({
        start = myPos + Vector(0, 0, 36),
        endpos = myPos + Vector(0, 0, 36) + strafe * 100,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        filter = ent,
        mask = MASK_SOLID,
    })
    
    if strafeTrace.Hit then
        -- Obstacle, flip direction
        data.strafeDirection = -data.strafeDirection
        strafe = -strafe
    end
    
    -- Blend strafe with approach
    local moveDir = (toTarget * 0.7 + strafe * 0.3):GetNormalized()
    local goalPos = myPos + moveDir * 100
    
    ent.loco:Approach(goalPos, speed)
    ent.loco:SetDesiredSpeed(speed)
    ent.loco:FaceTowards(targetPos)
end

-- Called before attack - return true to override
function AA.AI.Base:OnAttack(ent, target)
    return false -- Use default
end

-- Called when taking damage - return true to override
function AA.AI.Base:OnTakeDamage(ent, dmg, attacker)
    local data = ent.AIData
    
    -- Consider fleeing if health is low (for some archetypes)
    if ent:Health() / ent:GetMaxHealth() < 0.25 then
        if math.random() < 0.3 then
            -- Flee behavior
            self:TransitionState(ent, AA.AI.States.FLEE)
            data.fleeTarget = self:FindFleePoint(ent, attacker)
        end
    end
    
    -- Switch target if taking heavy damage from someone else
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ent.Target then
        local myPos = ent:GetPos()
        local currentDist = ent.Target and myPos:DistTo(ent.Target:GetPos()) or math.huge
        local newDist = myPos:DistTo(attacker:GetPos())
        
        -- Switch if new attacker is significantly closer
        if newDist < currentDist * 0.6 then
            ent.Target = attacker
        end
    end
    
    return false
end

-- Find a point to flee to
function AA.AI.Base:FindFleePoint(ent, threat)
    local myPos = ent:GetPos()
    local threatPos = IsValid(threat) and threat:GetPos() or myPos
    local awayDir = (myPos - threatPos):GetNormalized()
    
    -- Find furthest valid point in flee direction
    local bestPoint = nil
    local bestDist = 0
    
    for dist = 200, 800, 100 do
        local point = myPos + awayDir * dist
        
        local tr = util.TraceLine({
            start = point + Vector(0, 0, 100),
            endpos = point - Vector(0, 0, 200),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            point = tr.HitPos + Vector(0, 0, 10)
            local distFromThreat = point:DistTo(threatPos)
            if distFromThreat > bestDist then
                bestDist = distFromThreat
                bestPoint = point
            end
        end
    end
    
    return bestPoint or (myPos + awayDir * 300)
end

-- Called on death - return true to override
function AA.AI.Base:OnDeath(ent, attacker)
    return false
end

-- Check if entity should be in combat mode
function AA.AI.Base:ShouldBeAggressive(ent, target)
    if not IsValid(target) then return false end
    
    local distSqr = ent:GetPos():DistToSqr(target:GetPos())
    local maxAggroDist = 2000 * 2000
    
    return distSqr < maxAggroDist
end

-- Calculate optimal attack timing based on aggression
function AA.AI.Base:GetAttackDelay(ent, baseDelay)
    local data = ent.AIData
    return baseDelay * (2 - data.aggression) -- Higher aggression = faster attacks
end

-- Debug info
function AA.AI.Base:GetDebugInfo(ent)
    local data = ent.AIData
    if not data then return "No AI data" end
    
    return string.format(
        "State: %s (%.1fs) | Agg: %.2f | Target: %s",
        data.state,
        data.stateTime,
        data.aggression,
        IsValid(data.lastTarget) and data.lastTarget:Nick() or "none"
    )
end

print("[Lambda Arcade] Enhanced Base AI System initialized")
