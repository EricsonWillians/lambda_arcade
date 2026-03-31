--[[
    Arcade Anomaly: Stuck Recovery System
    
    Multi-tier recovery for stuck enemies.
--]]

AA.StuckRecovery = AA.StuckRecovery or {}

function AA.StuckRecovery:Initialize(ent)
    ent.RecoveryData = {
        tier = AA.Types.RecoveryTier.NONE,
        stuckStartTime = 0,
        lastRecoveryAttempt = 0,
        recoveryAttempts = 0,
        originalPos = Vector(0, 0, 0),
    }
end

function AA.StuckRecovery:Update(ent)
    if not IsValid(ent) then return end
    
    local data = ent.RecoveryData
    if not data then
        self:Initialize(ent)
        data = ent.RecoveryData
    end
    
    -- Check if stuck
    local isStuck = AA.Navigation:CheckStuck(ent)
    
    if isStuck then
        if data.tier == AA.Types.RecoveryTier.NONE then
            -- Just became stuck
            data.stuckStartTime = CurTime()
            data.originalPos = ent:GetPos()
            ent.IsStuck = true
            
            AA.Events.Emit(AA.Events.Names.ENEMY_STUCK, ent)
        end
        
        self:AttemptRecovery(ent)
    else
        -- No longer stuck
        if data.tier ~= AA.Types.RecoveryTier.NONE then
            self:ClearStuck(ent)
        end
    end
end

function AA.StuckRecovery:AttemptRecovery(ent)
    local data = ent.RecoveryData
    local stuckTime = CurTime() - data.stuckStartTime
    local now = CurTime()
    
    -- Tier 1: Repath (immediate)
    if data.tier < AA.Types.RecoveryTier.REPATH then
        data.tier = AA.Types.RecoveryTier.REPATH
        self:DoRepath(ent)
        return
    end
    
    -- Tier 2: Nudge (after short delay)
    if stuckTime > AA.Balance.Recovery.Tier1_RepathTime and 
       data.tier < AA.Types.RecoveryTier.NUDGE then
        data.tier = AA.Types.RecoveryTier.NUDGE
        self:DoNudge(ent)
        return
    end
    
    -- Tier 3: Micro-reposition (after longer delay)
    if stuckTime > AA.Balance.Recovery.Tier1_RepathTime * 2 and
       data.tier < AA.Types.RecoveryTier.REPOSITION then
        data.tier = AA.Types.RecoveryTier.REPOSITION
        self:DoReposition(ent)
        return
    end
    
    -- Tier 4: Hard despawn (last resort)
    if stuckTime > AA.Balance.Recovery.Tier4_DespawnTime and
       data.tier < AA.Types.RecoveryTier.DESPAWN then
        data.tier = AA.Types.RecoveryTier.DESPAWN
        self:DoDespawn(ent)
        return
    end
end

function AA.StuckRecovery:DoRepath(ent)
    -- Force a new path computation
    AA.Navigation:ForceRepath(ent)
    
    -- Try jumping if there's something above
    local upTrace = util.TraceLine({
        start = ent:GetPos() + Vector(0, 0, 64),
        endpos = ent:GetPos() + Vector(0, 0, 128),
        mask = MASK_SOLID,
    })
    
    -- Note: NextBots don't support SetHull, use SetCollisionBounds instead
    if not upTrace.Hit and ent.SetCollisionBounds then
        -- Try crouching temporarily
        local normalMins, normalMaxs = ent:GetCollisionBounds()
        ent:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 36))
        timer.Simple(2, function()
            if IsValid(ent) and ent.SetCollisionBounds then
                ent:SetCollisionBounds(normalMins, normalMaxs)
            end
        end)
    end
    
    if AA.Config.Debug.ShowStuckRecovery then
        print("[AA Recovery] Repath for " .. tostring(ent))
    end
end

function AA.StuckRecovery:DoNudge(ent)
    local data = ent.RecoveryData
    local nudgeDist = AA.Balance.Recovery.Tier2_NudgeDistance
    
    -- Try nudging in random directions
    local directions = {
        Vector(1, 0, 0), Vector(-1, 0, 0),
        Vector(0, 1, 0), Vector(0, -1, 0),
    }
    
    for _, dir in ipairs(directions) do
        local nudgePos = ent:GetPos() + dir * nudgeDist
        
        -- Check if nudge position is valid
        if AA.MapAnalyzer:IsValidSpawnAnchor(nudgePos) then
            ent:SetPos(nudgePos)
            data.recoveryAttempts = data.recoveryAttempts + 1
            
            if AA.Config.Debug.ShowStuckRecovery then
                print("[AA Recovery] Nudge for " .. tostring(ent))
            end
            return
        end
    end
end

function AA.StuckRecovery:DoReposition(ent)
    local data = ent.RecoveryData
    local radius = AA.Balance.Recovery.Tier3_RepositionRadius
    
    -- Find nearest anchor or try random positions
    local anchor = AA.MapAnalyzer:GetNearestAnchor(ent:GetPos())
    
    if anchor then
        -- Pick a position near the anchor
        local newPos = anchor.position + Vector(
            math.random(-radius, radius),
            math.random(-radius, radius),
            0
        )
        
        if AA.MapAnalyzer:IsValidSpawnAnchor(newPos) then
            -- Teleport with effect
            AA.FX.DispatchSpawn(newPos, ent.IsElite)
            ent:SetPos(newPos)
            
            data.recoveryAttempts = data.recoveryAttempts + 1
            
            if AA.Config.Debug.ShowStuckRecovery then
                print("[AA Recovery] Reposition for " .. tostring(ent))
            end
            return
        end
    end
    
    -- Fallback: try to teleport to player spawn area
    if not AA.MapAnalyzer or not AA.MapAnalyzer.MapData or not AA.MapAnalyzer.MapData.playerSpawns then
        return
    end
    
    for _, spawnPos in ipairs(AA.MapAnalyzer.MapData.playerSpawns) do
        local offsetPos = spawnPos + Vector(
            math.random(-500, 500),
            math.random(-500, 500),
            0
        )
        
        if AA.MapAnalyzer:IsValidSpawnAnchor(offsetPos) then
            AA.FX.DispatchSpawn(offsetPos, ent.IsElite)
            ent:SetPos(offsetPos)
            return
        end
    end
end

function AA.StuckRecovery:DoDespawn(ent)
    local data = ent.RecoveryData
    
    if AA.Config.Debug.ShowStuckRecovery then
        print("[AA Recovery] Hard despawn for " .. tostring(ent))
    end
    
    -- Despawn and respawn if we have budget
    AA.EnemyManager:DespawnEnemy(ent, "stuck_recovery")
    
    -- Try to respawn
    if AA.EnemyManager:GetAliveCount() < AA.GameDirector:GetCurrentEnemyCap() then
        timer.Simple(0.5, function()
            if AA.RunState:IsRunning() then
                AA.SpawnManager:SpawnEnemy(ent.Archetype)
            end
        end)
    end
end

function AA.StuckRecovery:ClearStuck(ent)
    local data = ent.RecoveryData
    
    data.tier = AA.Types.RecoveryTier.NONE
    data.stuckStartTime = 0
    data.recoveryAttempts = 0
    ent.IsStuck = false
    
    AA.Events.Emit(AA.Events.Names.ENEMY_RECOVERED, ent)
end

-- Check if enemy can be considered recovered
function AA.StuckRecovery:IsRecovered(ent)
    local data = ent.RecoveryData
    if not data then return true end
    
    return data.tier == AA.Types.RecoveryTier.NONE
end

-- Get current recovery tier
function AA.StuckRecovery:GetTier(ent)
    local data = ent.RecoveryData
    if not data then return AA.Types.RecoveryTier.NONE end
    
    return data.tier
end
