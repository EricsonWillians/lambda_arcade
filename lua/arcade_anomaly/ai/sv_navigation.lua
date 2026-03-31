--[[
    Lambda Arcade: Advanced Navigation System
    Enhanced pathfinding with obstacle avoidance, jump prediction, and tactical positioning
--]]

AA.Navigation = AA.Navigation or {}

-- Configuration
AA.Navigation.Config = {
    PathUpdateRate = 0.2,        -- Seconds between path updates
    StuckThreshold = 100,        -- Distance squared to consider stuck
    StuckTime = 1.5,             -- Seconds before considering stuck
    JumpThreshold = 40,          -- Height difference to trigger jump
    StepHeight = 35,             -- Max step height
    CornerSmoothing = 0.3,       -- How much to smooth corners (0-1)
    PathNodeSpacing = 64,        -- Space between path nodes
    MaxPathNodes = 32,           -- Maximum nodes in a path
    GroundCheckDist = 32,        -- Distance to check for ground
}

-- Initialize navigation for an entity
function AA.Navigation:Initialize(ent)
    ent.NavData = {
        lastPathUpdate = 0,
        path = {},                  -- Current path as array of vectors
        currentNode = 1,            -- Index of current target node
        stuckCounter = 0,
        lastPos = ent:GetPos(),
        lastMoveTime = CurTime(),
        isStuck = false,
        lastGroundPos = ent:GetPos(),
        state = "idle",             -- idle, moving, jumping, stuck
        targetPos = nil,
        velocity = Vector(0,0,0),
    }
end

-- Main update function - call every frame
function AA.Navigation:Update(ent, targetPos, speed)
    if not IsValid(ent) then return end
    if not ent.NavData then self:Initialize(ent) end
    if not ent.loco then return end
    
    local nav = ent.NavData
    local now = CurTime()
    local dt = FrameTime()
    
    -- Update state
    nav.targetPos = targetPos
    
    -- Check if we need a new path
    local needsNewPath = false
    if #nav.path == 0 or nav.currentNode > #nav.path then
        needsNewPath = true
    elseif now - nav.lastPathUpdate > self.Config.PathUpdateRate then
        -- Check if target moved significantly
        local lastNode = nav.path[#nav.path]
        if lastNode and lastNode:DistToSqr(targetPos) > 10000 then -- 100 units
            needsNewPath = true
        end
    end
    
    -- Generate new path if needed
    if needsNewPath then
        nav.path = self:GeneratePath(ent:GetPos(), targetPos, ent)
        nav.currentNode = 1
        nav.lastPathUpdate = now
    end
    
    -- Check for stuck condition
    self:CheckStuck(ent, dt)
    
    -- Follow path
    if #nav.path > 0 and nav.currentNode <= #nav.path then
        self:FollowPath(ent, speed)
    else
        -- Direct approach if no path
        self:DirectApproach(ent, targetPos, speed)
    end
    
    -- Update velocity tracking
    nav.velocity = ent:GetVelocity()
end

-- Generate a path from start to goal using simple grid-based pathfinding
function AA.Navigation:GeneratePath(startPos, goalPos, ent)
    local config = self.Config
    local path = {}
    
    -- Direct line first - check if we can go straight
    if self:CanWalkDirectly(startPos, goalPos, ent) then
        table.insert(path, goalPos)
        return path
    end
    
    -- Simple waypoint generation with obstacle avoidance
    local currentPos = startPos
    local targetPos = goalPos
    local maxIterations = config.MaxPathNodes
    local iteration = 0
    
    while currentPos:DistToSqr(targetPos) > config.PathNodeSpacing * config.PathNodeSpacing 
          and iteration < maxIterations do
        
        iteration = iteration + 1
        
        -- Try direct approach first
        local dir = (targetPos - currentPos):GetNormalized()
        local nextPos = currentPos + dir * config.PathNodeSpacing
        
        -- Check if this position is valid
        if self:IsValidMovePosition(nextPos, ent) then
            table.insert(path, nextPos)
            currentPos = nextPos
        else
            -- Try to find a way around
            local alternativePos = self:FindAlternativePosition(currentPos, targetPos, ent)
            if alternativePos then
                table.insert(path, alternativePos)
                currentPos = alternativePos
            else
                -- Can't find a path, go with what we have
                break
            end
        end
    end
    
    -- Always add the final goal
    table.insert(path, targetPos)
    
    -- Smooth the path
    path = self:SmoothPath(path, ent)
    
    return path
end

-- Check if we can walk directly to target without obstacles
function AA.Navigation:CanWalkDirectly(startPos, endPos, ent)
    local trace = util.TraceHull({
        start = startPos + Vector(0, 0, 32),
        endpos = endPos + Vector(0, 0, 32),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        filter = ent,
        mask = MASK_SOLID,
    })
    
    return not trace.Hit or trace.Fraction > 0.95
end

-- Find an alternative position when direct path is blocked
function AA.Navigation:FindAlternativePosition(currentPos, targetPos, ent)
    local config = self.Config
    local dir = (targetPos - currentPos):GetNormalized()
    local right = Vector(-dir.y, dir.x, 0) -- Perpendicular
    
    -- Try different offsets
    local offsets = {64, 128, 192, -64, -128, -192}
    
    for _, offset in ipairs(offsets) do
        local testPos = currentPos + right * offset
        
        -- Check if position is valid
        if self:IsValidMovePosition(testPos, ent) then
            -- Check if we can continue toward target from here
            local nextPos = testPos + dir * config.PathNodeSpacing
            if self:IsValidMovePosition(nextPos, ent) or self:CanWalkDirectly(testPos, targetPos, ent) then
                return testPos
            end
        end
    end
    
    -- Try jumping over obstacle
    local jumpPos = currentPos + dir * 64 + Vector(0, 0, 72)
    if self:IsValidMovePosition(jumpPos, ent) then
        return jumpPos
    end
    
    return nil
end

-- Check if a position is valid for movement
function AA.Navigation:IsValidMovePosition(pos, ent)
    -- Check for ground
    local groundTrace = util.TraceLine({
        start = pos + Vector(0, 0, 100),
        endpos = pos - Vector(0, 0, 100),
        mask = MASK_SOLID,
    })
    
    if not groundTrace.Hit then return false end
    
    -- Check height difference (don't fall off cliffs)
    local heightDiff = math.abs(groundTrace.HitPos.z - pos.z)
    if heightDiff > self.Config.StepHeight * 2 then return false end
    
    -- Check for space to stand
    local spaceTrace = util.TraceHull({
        start = groundTrace.HitPos + Vector(0, 0, 36),
        endpos = groundTrace.HitPos + Vector(0, 0, 36),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_SOLID,
    })
    
    return not spaceTrace.Hit
end

-- Smooth path using simple corner cutting
function AA.Navigation:SmoothPath(path, ent)
    if #path < 3 then return path end
    
    local smoothed = {path[1]}
    local i = 1
    
    while i < #path - 1 do
        local current = path[i]
        local nextNode = path[i + 1]
        local afterNext = path[i + 2]
        
        -- Try to cut corner
        if self:CanWalkDirectly(current, afterNext, ent) then
            -- Skip the middle node
            table.insert(smoothed, afterNext)
            i = i + 2
        else
            table.insert(smoothed, nextNode)
            i = i + 1
        end
    end
    
    -- Add last node if not already added
    if smoothed[#smoothed] ~= path[#path] then
        table.insert(smoothed, path[#path])
    end
    
    return smoothed
end

-- Follow the current path
function AA.Navigation:FollowPath(ent, speed)
    local nav = ent.NavData
    if not nav or #nav.path == 0 then return end
    
    local targetNode = nav.path[nav.currentNode]
    if not targetNode then return end
    
    local myPos = ent:GetPos()
    local distToNode = myPos:DistToSqr(targetNode)
    local arrivalDist = 2500 -- 50 units squared
    
    -- Check if we reached the current node
    if distToNode < arrivalDist then
        nav.currentNode = nav.currentNode + 1
        if nav.currentNode > #nav.path then
            -- Reached end of path
            nav.state = "idle"
            return
        end
        targetNode = nav.path[nav.currentNode]
    end
    
    -- Check for obstacles ahead and jump if needed
    self:CheckAndJump(ent, targetNode)
    
    -- Move toward target node
    if ent.loco then
        ent.loco:Approach(targetNode, speed)
        ent.loco:SetDesiredSpeed(speed)
        ent.loco:FaceTowards(targetNode)
    end
    
    nav.state = "moving"
end

-- Direct approach when no path is available
function AA.Navigation:DirectApproach(ent, targetPos, speed)
    if not ent.loco then return end
    
    -- Check for obstacles and jump
    self:CheckAndJump(ent, targetPos)
    
    ent.loco:Approach(targetPos, speed)
    ent.loco:SetDesiredSpeed(speed)
    ent.loco:FaceTowards(targetPos)
    
    ent.NavData.state = "moving"
end

-- Check for obstacles and jump if needed
function AA.Navigation:CheckAndJump(ent, targetPos)
    if not ent.loco then return end
    if not ent.loco:IsOnGround() then return end
    
    local myPos = ent:GetPos()
    local forward = (targetPos - myPos):GetNormalized()
    forward.z = 0
    
    if forward:LengthSqr() < 0.01 then return end
    forward:Normalize()
    
    -- Check ahead for obstacles
    local checkDist = 48
    local trace = util.TraceHull({
        start = myPos + Vector(0, 0, 36),
        endpos = myPos + Vector(0, 0, 36) + forward * checkDist,
        mins = Vector(-12, -12, 0),
        maxs = Vector(12, 12, 48),
        filter = ent,
        mask = MASK_SOLID,
    })
    
    if trace.Hit and trace.Fraction < 0.8 then
        -- Check if we can jump over
        local jumpTrace = util.TraceHull({
            start = myPos + Vector(0, 0, 72),
            endpos = myPos + Vector(0, 0, 72) + forward * checkDist,
            mins = Vector(-12, -12, 0),
            maxs = Vector(12, 12, 24),
            filter = ent,
            mask = MASK_SOLID,
        })
        
        if not jumpTrace.Hit then
            -- Try to jump
            ent.loco:Jump()
            ent.NavData.state = "jumping"
        end
    end
    
    -- Check for gaps (don't walk off cliffs)
    local groundTrace = util.TraceLine({
        start = myPos + Vector(0, 0, 36) + forward * 40,
        endpos = myPos - Vector(0, 0, 100) + forward * 40,
        mask = MASK_SOLID,
    })
    
    if groundTrace.Hit then
        local heightDiff = myPos.z - groundTrace.HitPos.z
        if heightDiff > self.Config.StepHeight * 3 then
            -- Gap ahead, try to jump
            local landingTrace = util.TraceLine({
                start = myPos + Vector(0, 0, 36) + forward * 120,
                endpos = myPos - Vector(0, 0, 200) + forward * 120,
                mask = MASK_SOLID,
            })
            
            if landingTrace.Hit and landingTrace.HitPos.z < myPos.z - 50 then
                -- Long jump needed
                ent.loco:Jump()
                ent.NavData.state = "jumping"
            end
        end
    end
end

-- Check if entity is stuck and try to resolve
function AA.Navigation:CheckStuck(ent, dt)
    local nav = ent.NavData
    if not nav then return end
    
    local myPos = ent:GetPos()
    local distMoved = myPos:DistToSqr(nav.lastPos)
    
    -- Update position tracking periodically
    if CurTime() - nav.lastMoveTime > self.Config.StuckTime then
        if distMoved < self.Config.StuckThreshold then
            -- We're stuck
            nav.stuckCounter = nav.stuckCounter + 1
            nav.isStuck = true
            
            -- Try to resolve
            self:ResolveStuck(ent)
        else
            nav.stuckCounter = 0
            nav.isStuck = false
        end
        
        nav.lastPos = myPos
        nav.lastMoveTime = CurTime()
    end
end

-- Resolve stuck condition
function AA.Navigation:ResolveStuck(ent)
    local nav = ent.NavData
    
    -- Method 1: Jump
    if ent.loco and ent.loco:IsOnGround() then
        ent.loco:Jump()
    end
    
    -- Method 2: Nudge in random direction
    local nudge = Vector(math.random(-50, 50), math.random(-50, 50), 10)
    ent:SetPos(ent:GetPos() + nudge)
    
    -- Method 3: Clear path and try direct approach
    nav.path = {}
    nav.currentNode = 1
    
    -- Method 4: If really stuck, teleport slightly
    if nav.stuckCounter > 5 then
        local teleportNudge = Vector(math.random(-100, 100), math.random(-100, 100), 20)
        local newPos = ent:GetPos() + teleportNudge
        
        -- Make sure new position is valid
        local trace = util.TraceLine({
            start = newPos + Vector(0, 0, 100),
            endpos = newPos - Vector(0, 0, 200),
            mask = MASK_SOLID,
        })
        
        if trace.Hit then
            ent:SetPos(trace.HitPos + Vector(0, 0, 10))
            nav.stuckCounter = 0
        end
    end
    
    -- Add velocity boost
    local vel = ent:GetVelocity()
    vel.z = 200
    ent:SetVelocity(vel)
end

-- Get debug info for an entity
function AA.Navigation:GetDebugInfo(ent)
    local nav = ent.NavData
    if not nav then return "No nav data" end
    
    return string.format(
        "State: %s | Path: %d/%d | Stuck: %s | Target: %s",
        nav.state,
        nav.currentNode,
        #nav.path,
        nav.isStuck and "YES" or "no",
        nav.targetPos and tostring(nav.targetPos:Round()) or "none"
    )
end

-- Force regenerate path for entity
function AA.Navigation:ForcePathRegeneration(ent)
    if not ent.NavData then self:Initialize(ent) end
    ent.NavData.lastPathUpdate = 0
    ent.NavData.path = {}
end

print("[Lambda Arcade] Advanced Navigation System initialized")
