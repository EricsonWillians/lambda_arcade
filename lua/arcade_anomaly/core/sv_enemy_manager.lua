--[[
    Arcade Anomaly: Enemy Manager
    
    Tracks all living enemies and provides aggregate data.
--]]

AA.EnemyManager = AA.EnemyManager or {}
AA.EnemyManager.Enemies = {}
AA.EnemyManager.EnemyCountByArchetype = {}
AA.EnemyManager.EliteCount = 0

-- Registration
function AA.EnemyManager:RegisterEnemy(enemy)
    if not IsValid(enemy) then return end
    
    table.insert(self.Enemies, enemy)
    
    local archetype = enemy.Archetype
    self.EnemyCountByArchetype[archetype] = (self.EnemyCountByArchetype[archetype] or 0) + 1
    
    if enemy.IsElite then
        self.EliteCount = self.EliteCount + 1
        
        -- Broadcast elite warning
        if AA.Net and AA.Net.BroadcastEliteWarning then
            AA.Net.BroadcastEliteWarning(enemy:GetPos())
        end
    end
    
    -- Hook into enemy death
    enemy:CallOnRemove("AA_EnemyDeath", function(ent)
        self:OnEnemyDeath(ent)
    end)
    
    if AA.Events and AA.Events.Emit then
        AA.Events.Emit(AA.Events.Names.ENEMY_SPAWN, enemy)
    end
end

function AA.EnemyManager:UnregisterEnemy(enemy)
    if not enemy then return end
    
    for i, ent in ipairs(self.Enemies) do
        if ent == enemy then
            table.remove(self.Enemies, i)
            break
        end
    end
    
    local archetype = enemy.Archetype
    if archetype and self.EnemyCountByArchetype and self.EnemyCountByArchetype[archetype] then
        self.EnemyCountByArchetype[archetype] = math.max(0, self.EnemyCountByArchetype[archetype] - 1)
    end
    
    if enemy.IsElite then
        self.EliteCount = math.max(0, self.EliteCount - 1)
    end
end

function AA.EnemyManager:OnEnemyDeath(enemy)
    if not enemy then return end
    
    self:UnregisterEnemy(enemy)
    
    -- Notify score manager
    if AA.ScoreManager and AA.ScoreManager.OnEnemyKilled then
        AA.ScoreManager:OnEnemyKilled(enemy, enemy.LastAttacker)
    end
    
    -- Notify spawn system
    local anchor = enemy.SpawnAnchor
    if anchor and AA.MapAnalyzer and AA.MapAnalyzer.RecordAnchorResult then
        local engagementTime = CurTime() - (enemy.SpawnTime or CurTime())
        AA.MapAnalyzer:RecordAnchorResult(anchor, true, engagementTime)
    end
    
    -- Broadcast death
    if AA.Net and AA.Net.BroadcastEnemyDeath then
        AA.Net.BroadcastEnemyDeath(
            enemy:EntIndex() or 0,
            enemy:GetPos(),
            enemy.ScoreValue or 0,
            enemy.LastAttacker
        )
    end
    
    -- FX
    if AA.FX and AA.FX.DispatchDeath then
        AA.FX.DispatchDeath(enemy:GetPos(), enemy.IsElite)
    end
    
    if AA.Events and AA.Events.Emit then
        AA.Events.Emit(AA.Events.Names.ENEMY_DEATH, enemy, enemy.LastAttacker)
    end
end

-- Cleanup
function AA.EnemyManager:DespawnEnemy(enemy, reason)
    if not IsValid(enemy) then return end
    
    reason = reason or "unknown"
    
    if enemy.SpawnAnchor and AA.MapAnalyzer and AA.MapAnalyzer.RecordAnchorResult then
        AA.MapAnalyzer:RecordAnchorResult(enemy.SpawnAnchor, false)
    end
    
    -- Mark for removal
    enemy.AA_DespawnReason = reason
    enemy:Remove()
end

function AA.EnemyManager:CleanupAll()
    for _, enemy in ipairs(self.Enemies) do
        if IsValid(enemy) then
            enemy:Remove()
        end
    end
    
    self.Enemies = {}
    self.EnemyCountByArchetype = {}
    self.EliteCount = 0
end

-- Queries
function AA.EnemyManager:GetAliveEnemies()
    -- Clean up invalid entries
    local valid = {}
    for _, enemy in ipairs(self.Enemies) do
        if IsValid(enemy) then
            table.insert(valid, enemy)
        end
    end
    self.Enemies = valid
    
    return self.Enemies
end

function AA.EnemyManager:GetAliveCount()
    return #self:GetAliveEnemies()
end

function AA.EnemyManager:GetAliveCountByArchetype(archetype)
    return self.EnemyCountByArchetype[archetype] or 0
end

function AA.EnemyManager:GetEliteCount()
    return self.EliteCount
end

function AA.EnemyManager:GetEngagementRate()
    -- Calculate what percentage of enemies are currently engaging a player
    local alive = self:GetAliveEnemies()
    if #alive == 0 then return 1 end
    
    local engaging = 0
    for _, enemy in ipairs(alive) do
        -- Check if enemy has valid target (is actively engaging a player)
        if IsValid(enemy) and enemy.AIData and enemy.AIData.hasValidTarget then
            engaging = engaging + 1
        end
    end
    
    return engaging / #alive
end

function AA.EnemyManager:GetAverageDistanceToPlayers()
    local alive = self:GetAliveEnemies()
    if #alive == 0 then return 0 end
    
    local players = AA.Util.GetAlivePlayers()
    if #players == 0 then return 0 end
    
    local totalDist = 0
    local count = 0
    
    for _, enemy in ipairs(alive) do
        local nearestDist = math.huge
        for _, ply in ipairs(players) do
            local dist = enemy:GetPos():DistToSqr(ply:GetPos())
            nearestDist = math.min(nearestDist, dist)
        end
        
        totalDist = totalDist + math.sqrt(nearestDist)
        count = count + 1
    end
    
    return totalDist / count
end

-- Stuck recovery coordination
function AA.EnemyManager:GetStuckEnemies()
    local stuck = {}
    for _, enemy in ipairs(self:GetAliveEnemies()) do
        if enemy.IsStuck then
            table.insert(stuck, enemy)
        end
    end
    return stuck
end

function AA.EnemyManager:RecoverStuckEnemies()
    local stuck = self:GetStuckEnemies()
    for _, enemy in ipairs(stuck) do
        if enemy.RecoverFromStuck then
            enemy:RecoverFromStuck()
        end
    end
end

-- Target selection (for multi-enemy coordination)
function AA.EnemyManager:SelectTargetForEnemy(enemy)
    local players = AA.Util.GetAlivePlayers()
    if #players == 0 then return nil end
    if #players == 1 then return players[1] end
    
    -- Find player with fewest attackers
    local targetScores = {}
    for _, ply in ipairs(players) do
        targetScores[ply] = {
            player = ply,
            dist = enemy:GetPos():DistToSqr(ply:GetPos()),
            attackers = 0,
        }
    end
    
    -- Count attackers per player
    for _, otherEnemy in ipairs(self:GetAliveEnemies()) do
        if otherEnemy ~= enemy and otherEnemy.Target then
            local target = otherEnemy.Target
            if targetScores[target] then
                targetScores[target].attackers = targetScores[target].attackers + 1
            end
        end
    end
    
    -- Score each target (prefer closer, but distribute)
    local bestTarget = nil
    local bestScore = -math.huge
    
    for _, score in pairs(targetScores) do
        local distFactor = -math.sqrt(score.dist) / 1000 -- Closer is better
        local crowdFactor = -score.attackers * 500 -- Fewer attackers is better
        local totalScore = distFactor + crowdFactor
        
        if totalScore > bestScore then
            bestScore = totalScore
            bestTarget = score.player
        end
    end
    
    return bestTarget or players[1]
end

-- Periodic cleanup
hook.Add("Think", "AA_EnemyManager_Cleanup", function()
    if not AA.EnemyManager then return end
    
    -- Remove invalid entries periodically
    if CurTime() % 5 < FrameTime() then
        AA.EnemyManager:GetAliveEnemies() -- This cleans up
    end
end)

-- Debug commands
concommand.Add("aa_enemy_count", function(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    print("[AA] Alive enemies: " .. AA.EnemyManager:GetAliveCount())
    print("[AA] Elite count: " .. AA.EnemyManager:GetEliteCount())
    
    for archetype, count in pairs(AA.EnemyManager.EnemyCountByArchetype) do
        local name = AA.Types.ArchetypeNames[archetype] or "UNKNOWN"
        print("[AA]  " .. name .. ": " .. count)
    end
end)

concommand.Add("aa_enemy_clear", function(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    AA.EnemyManager:CleanupAll()
    print("[AA] All enemies cleared")
end)
