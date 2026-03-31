--[[
    Arcade Anomaly: Game Director
    
    Controls pacing, difficulty scaling, and enemy composition.
--]]

AA.GameDirector = AA.GameDirector or {}
AA.GameDirector.Active = false
AA.GameDirector.RunStartTime = 0
AA.GameDirector.CurrentEnemyCap = 8
AA.GameDirector.EliteChance = 0.05
AA.GameDirector.LastDifficultyUpdate = 0
AA.GameDirector.ArchetypeWeights = {}

function AA.GameDirector:StartRun()
    -- Safety check for Config
    if not AA.Config or not AA.Config.Game then
        print("[AA Director] ERROR: Config not initialized")
        return
    end
    
    self.Active = true
    self.RunStartTime = CurTime()
    self.CurrentEnemyCap = AA.Config.Game.BaseEnemyCap or 8
    self.EliteChance = AA.Config.Game.EliteChanceBase or 0.05
    self.LastDifficultyUpdate = 0
    
    -- Initialize archetype weights
    self:InitializeArchetypeWeights()
    
    -- Start spawn timer
    timer.Create("AA_Director_Spawn", 1, 0, function()
        if AA.GameDirector and AA.GameDirector.OnSpawnTick then
            AA.GameDirector:OnSpawnTick()
        end
    end)
    
    -- Start difficulty timer
    timer.Create("AA_Director_Difficulty", AA.Config.Game.DifficultyScaleInterval or 30, 0, function()
        if AA.GameDirector and AA.GameDirector.OnDifficultyTick then
            AA.GameDirector:OnDifficultyTick()
        end
    end)
    
    print("[AA Director] Run started")
end

function AA.GameDirector:StopRun()
    self.Active = false
    
    timer.Remove("AA_Director_Spawn")
    timer.Remove("AA_Director_Difficulty")
    
    -- Clear spawn queue to prevent stale requests
    if AA.SpawnManager and AA.SpawnManager.SpawnQueue then
        AA.SpawnManager.SpawnQueue = {}
    end
    
    print("[AA Director] Run stopped")
end

function AA.GameDirector:InitializeArchetypeWeights()
    self.ArchetypeWeights = {
        [AA.Types.Archetype.CHASER] = 40,
        [AA.Types.Archetype.RUSHER] = 20,
        [AA.Types.Archetype.BRUTE] = 10,
        [AA.Types.Archetype.SHOOTER] = 15,
        [AA.Types.Archetype.EXPLODER] = 10,
    }
    -- Elite is not spawned directly, it's a modifier
end

function AA.GameDirector:OnSpawnTick()
    if not self.Active then return end
    if not AA.EnemyManager then return end
    if not AA.SpawnManager then return end
    
    local aliveCount = AA.EnemyManager:GetAliveCount()
    local targetCount = self:GetDesiredEnemyCount()
    
    -- Spawn if below target
    if aliveCount < targetCount then
        local spawnCount = math.min(targetCount - aliveCount, 3) -- Max 3 per tick
        
        for i = 1, spawnCount do
            local archetype = self:SelectArchetype()
            AA.SpawnManager:QueueSpawn(archetype, 0)
        end
    end
end

function AA.GameDirector:OnDifficultyTick()
    if not self.Active then return end
    
    local runTime = CurTime() - self.RunStartTime
    local minutes = runTime / 60
    
    -- Increase enemy cap
    local capIncrease = 0
    if AA.Balance and AA.Balance.Difficulty then
        capIncrease = minutes * AA.Balance.Difficulty.EnemyCapGrowth
    end
    self.CurrentEnemyCap = math.min(
        AA.Config.Game.BaseEnemyCap + math.floor(capIncrease),
        AA.Config.Game.MaxEnemyCap
    )
    
    -- Increase elite chance
    if minutes >= AA.Config.Game.EliteMinDifficulty then
        local eliteIncrease = (minutes - AA.Config.Game.EliteMinDifficulty) * 0.01
        self.EliteChance = math.min(
            AA.Config.Game.EliteChanceBase + eliteIncrease,
            AA.Config.Game.EliteChanceMax
        )
    end
    
    -- Adjust archetype weights based on map and time
    self:AdjustArchetypeWeights(minutes)
    
    self.LastDifficultyUpdate = CurTime()
    
    if AA.Debug then
        print(string.format("[AA Director] Difficulty updated: cap=%d, elite=%.2f%%",
            self.CurrentEnemyCap, self.EliteChance * 100))
    end
end

function AA.GameDirector:GetDesiredEnemyCount()
    local alive = 0
    if AA.EnemyManager then
        alive = AA.EnemyManager:GetAliveCount()
    end
    local target = self.CurrentEnemyCap
    
    -- Adjust based on player performance (aggression)
    local engagementRate = AA.EnemyManager:GetEngagementRate()
    if engagementRate > 0.8 then
        -- Players are clearing enemies fast, spawn more
        target = target + 2
    elseif engagementRate < 0.3 then
        -- Players are struggling, ease up slightly
        target = math.max(target - 1, 3)
    end
    
    return math.min(target, AA.Config.Game.MaxEnemyCap)
end

function AA.GameDirector:SelectArchetype()
    -- Check map constraints
    local mapData = nil
    if AA.MapAnalyzer and AA.MapAnalyzer.GetMapData then
        mapData = AA.MapAnalyzer:GetMapData()
    end
    
    local weights = table.Copy(self.ArchetypeWeights)
    
    -- On small maps, reduce shooters (ranged need space)
    if mapData and mapData.opennessScore < 0.3 then
        weights[AA.Types.Archetype.SHOOTER] = weights[AA.Types.Archetype.SHOOTER] * 0.5
        weights[AA.Types.Archetype.BRUTE] = weights[AA.Types.Archetype.BRUTE] * 0.7
    end
    
    -- On very open maps, increase shooters
    if mapData and mapData.opennessScore > 0.7 then
        weights[AA.Types.Archetype.SHOOTER] = weights[AA.Types.Archetype.SHOOTER] * 1.5
    end
    
    -- Convert to weighted random choices
    local choices = {}
    for archetype, weight in pairs(weights) do
        table.insert(choices, { item = archetype, weight = weight })
    end
    
    if AA.Util and AA.Util.WeightedRandom then
        return AA.Util.WeightedRandom(choices)
    else
        -- Fallback to chaser if util not available
        return AA.Types.Archetype.CHASER
    end
end

function AA.GameDirector:AdjustArchetypeWeights(minutes)
    -- As time progresses, shift toward more dangerous archetypes
    local shift = math.min(minutes / 10, 1.0) -- Max shift at 10 minutes
    
    -- Reduce chasers
    self.ArchetypeWeights[AA.Types.Archetype.CHASER] = 40 * (1 - shift * 0.5)
    
    -- Increase rushers and brutes
    self.ArchetypeWeights[AA.Types.Archetype.RUSHER] = 20 + (15 * shift)
    self.ArchetypeWeights[AA.Types.Archetype.BRUTE] = 10 + (10 * shift)
    
    -- Exploders become more common
    self.ArchetypeWeights[AA.Types.Archetype.EXPLODER] = 10 + (10 * shift)
end

-- Special round handling
function AA.GameDirector:TriggerSpecialRound(roundType)
    if roundType == "ELITE_SURGE" then
        -- Spawn multiple elites
        for i = 1, 3 do
            AA.SpawnManager:QueueSpawn(AA.Types.Archetype.ELITE, 100)
        end
        
        -- Notify clients
        AA.Net.BroadcastRunState(AA.RunState:GetCurrentState(), {
            event = "ELITE_SURGE",
            duration = 30,
        })
        
    elseif roundType == "RUSHER_WAVE" then
        -- Spawn many rushers quickly
        for i = 1, 10 do
            AA.SpawnManager:QueueSpawn(AA.Types.Archetype.RUSHER, 90)
        end
        
    elseif roundType == "BRUTE_HORDE" then
        -- Spawn brutes
        for i = 1, 5 do
            AA.SpawnManager:QueueSpawn(AA.Types.Archetype.BRUTE, 80)
        end
    end
    
    AA.Events.Emit("SpecialRoundStarted", roundType)
end

-- Public API
function AA.GameDirector:IsActive()
    return self.Active
end

function AA.GameDirector:GetCurrentEnemyCap()
    return self.CurrentEnemyCap
end

function AA.GameDirector:GetEliteChance()
    return self.EliteChance
end

function AA.GameDirector:GetRunTime()
    if not self.Active then return 0 end
    return CurTime() - self.RunStartTime
end

function AA.GameDirector:GetDifficultyLevel()
    local minutes = self:GetRunTime() / 60
    return math.min(minutes, AA.Types.Constants.MAX_DIFFICULTY)
end

-- Debug commands
concommand.Add("aa_director_force_surge", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    AA.GameDirector:TriggerSpecialRound("ELITE_SURGE")
end)

concommand.Add("aa_director_set_cap", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local cap = tonumber(args[1]) or 10
    AA.GameDirector.CurrentEnemyCap = math.min(cap, AA.Config.Game.MaxEnemyCap)
    print("[AA Director] Enemy cap set to: " .. AA.GameDirector.CurrentEnemyCap)
end)
