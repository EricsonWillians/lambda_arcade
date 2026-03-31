-- addons/arcade_spawner/lua/arcade_spawner/core/spawner.lua
-- BULLETPROOF Spawner with Intelligent Distribution & Procedural Enhancements

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.Spawner = ArcadeSpawner.Spawner or {}
local Spawner = ArcadeSpawner.Spawner

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════
Spawner.Active = false
Spawner.SpawnPoints = {}
Spawner.CurrentWave = 1
Spawner.EnemiesKilled = 0
Spawner.ActiveEnemies = {}
Spawner.WaveEnemiesSpawned = 0
Spawner.WaveEnemiesKilled = 0
Spawner.WaveEnemiesTarget = 10
Spawner.WaveEnemiesRemaining = 10
Spawner.SessionStartTime = 0
Spawner.LastBossWave = 0
Spawner.MapBounds = nil
Spawner.LastPlayerPositions = {}
Spawner.DynamicDifficulty = 1.0
Spawner.WaveStartTime = 0
Spawner.LastSentRemaining = -1
Spawner.SpawningEnabled = false

-- Enhanced network strings
util.AddNetworkString("ArcadeSpawner_SessionStart")
util.AddNetworkString("ArcadeSpawner_SessionEnd")
util.AddNetworkString("ArcadeSpawner_WaveStart")
util.AddNetworkString("ArcadeSpawner_EnemyKilled")
util.AddNetworkString("ArcadeSpawner_BossWave")
util.AddNetworkString("ArcadeSpawner_WaveComplete")
util.AddNetworkString("ArcadeSpawner_WaveInfo")

-- ═══════════════════════════════════════════════════════════════
-- INTELLIGENT SPAWN POINT GENERATION
-- ═══════════════════════════════════════════════════════════════
function Spawner.PerformIntelligentMapAnalysis()
    Spawner.SpawnPoints = {}
    
    local players = player.GetAll()
    local playerPositions = {}
    for _, ply in pairs(players) do
        if IsValid(ply) and ply:Alive() then
            table.insert(playerPositions, ply:GetPos())
        end
    end
    
    if #playerPositions == 0 then
        print("[Arcade Spawner] ❌ No valid players found!")
        return false
    end
    
    print("[Arcade Spawner] 🔍 Performing intelligent spawn point analysis...")
    
    -- Store for dynamic respawn calculations
    Spawner.LastPlayerPositions = playerPositions
    
    -- Multiple scanning methods for comprehensive coverage
    local methods = {
        {func = Spawner.NavMeshAnalysis, name = "NavMesh", target = 60},
        {func = Spawner.EntityBasedAnalysis, name = "Entity", target = 40},
        {func = Spawner.GridAnalysis, name = "Grid", target = 50},
        {func = Spawner.RadialAnalysis, name = "Radial", target = 30}
    }
    
    for _, method in ipairs(methods) do
        local foundPoints = method.func(playerPositions)
        print("[Arcade Spawner] " .. method.name .. ": " .. foundPoints .. " spawn points")
        
        if #Spawner.SpawnPoints >= 80 then
            break
        end
    end
    
    -- Optimize spawn distribution
    Spawner.OptimizeSpawnDistribution()
    
    if #Spawner.SpawnPoints == 0 then
        print("[Arcade Spawner] ❌ CRITICAL: No spawn points found!")
        return false
    end
    
    print("[Arcade Spawner] ✅ Analysis complete: " .. #Spawner.SpawnPoints .. " optimized spawn points")
    return true
end

-- NavMesh-based analysis
function Spawner.NavMeshAnalysis(playerPositions)
    local navAreas = navmesh.GetAllNavAreas()
    if not navAreas or #navAreas == 0 then return 0 end
    
    local found = 0
    local maxAreas = math.min(#navAreas, 150)
    
    for i = 1, maxAreas do
        local area = navAreas[i]
        if IsValid(area) then
            -- Test multiple points per area
            local testPoints = {
                area:GetCenter(),
                area:GetRandomPoint(),
                area:GetRandomPoint()
            }
            
            for j = 0, 3 do
                local corner = area:GetCorner(j)
                if corner then table.insert(testPoints, corner) end
            end
            
            for _, pos in ipairs(testPoints) do
                if Spawner.ValidateSpawnPoint(pos, playerPositions) then
                    table.insert(Spawner.SpawnPoints, {
                        pos = pos,
                        quality = Spawner.CalculateSpawnQuality(pos, playerPositions),
                        type = "navmesh",
                        area = area
                    })
                    found = found + 1
                    
                    if found >= 60 then break end
                end
            end
            
            if found >= 60 then break end
        end
    end
    
    return found
end

-- Entity-based analysis for tactical positions
function Spawner.EntityBasedAnalysis(playerPositions)
    local entityTypes = {
        "info_player_start", "info_node", "info_target",
        "prop_physics", "func_door"
    }
    
    local found = 0
    
    for _, entityType in ipairs(entityTypes) do
        for _, ent in pairs(ents.FindByClass(entityType)) do
            if IsValid(ent) and found < 40 then
                local basePos = ent:GetPos()
                
                -- Test multiple positions around entity
                local offsets = {
                    Vector(0, 0, 0),
                    Vector(150, 0, 0), Vector(-150, 0, 0),
                    Vector(0, 150, 0), Vector(0, -150, 0),
                    Vector(200, 200, 0), Vector(-200, -200, 0),
                    Vector(200, -200, 0), Vector(-200, 200, 0)
                }
                
                for _, offset in ipairs(offsets) do
                    local testPos = basePos + offset
                    if Spawner.ValidateSpawnPoint(testPos, playerPositions) then
                        table.insert(Spawner.SpawnPoints, {
                            pos = testPos,
                            quality = Spawner.CalculateSpawnQuality(testPos, playerPositions),
                            type = "entity",
                            sourceEntity = ent
                        })
                        found = found + 1
                        break
                    end
                end
            end
        end
    end
    
    return found
end

-- Grid-based systematic analysis
function Spawner.GridAnalysis(playerPositions)
    local bounds = Spawner.GetMapBounds()
    local step = 250
    local found = 0
    local maxTests = 600
    local tests = 0
    
    for x = bounds.min.x, bounds.max.x, step do
        for y = bounds.min.y, bounds.max.y, step do
            tests = tests + 1
            if tests > maxTests or found >= 50 then break end
            
            -- Test at multiple heights
            local heights = {0, 100, 200, -100}
            
            for _, heightOffset in ipairs(heights) do
                local skyPos = Vector(x, y, bounds.max.z + heightOffset)
                
                local groundTrace = util.TraceLine({
                    start = skyPos,
                    endpos = Vector(x, y, bounds.min.z),
                    mask = MASK_SOLID_BRUSHONLY
                })
                
                if groundTrace.Hit then
                    local testPos = groundTrace.HitPos + Vector(0, 0, 20)
                    if Spawner.ValidateSpawnPoint(testPos, playerPositions) then
                        table.insert(Spawner.SpawnPoints, {
                            pos = testPos,
                            quality = Spawner.CalculateSpawnQuality(testPos, playerPositions),
                            type = "grid"
                        })
                        found = found + 1
                        break
                    end
                end
            end
        end
        if tests > maxTests or found >= 50 then break end
    end
    
    return found
end

-- Radial analysis around players
function Spawner.RadialAnalysis(playerPositions)
    local found = 0
    
    for _, playerPos in pairs(playerPositions) do
        local distances = {450, 650, 850, 1100, 1400}
        
        for _, distance in ipairs(distances) do
            local pointsPerRing = 12
            for i = 1, pointsPerRing do
                if found >= 30 then break end
                
                local angle = (i - 1) * (360 / pointsPerRing)
                local rad = math.rad(angle)
                
                local testPos = playerPos + Vector(
                    math.cos(rad) * distance,
                    math.sin(rad) * distance,
                    50
                )
                
                if Spawner.ValidateSpawnPoint(testPos, playerPositions) then
                    table.insert(Spawner.SpawnPoints, {
                        pos = testPos,
                        quality = Spawner.CalculateSpawnQuality(testPos, playerPositions),
                        type = "radial"
                    })
                    found = found + 1
                end
            end
            if found >= 30 then break end
        end
        if found >= 30 then break end
    end
    
    return found
end

-- ═══════════════════════════════════════════════════════════════
-- SPAWN POINT VALIDATION & OPTIMIZATION
-- ═══════════════════════════════════════════════════════════════
function Spawner.ValidateSpawnPoint(pos, playerPositions)
    if not pos or not isvector(pos) then return false end
    
    -- Collision check
    local trace = util.TraceLine({
        start = pos,
        endpos = pos,
        mask = MASK_SOLID_BRUSHONLY
    })
    if trace.StartSolid then return false end
    
    -- Ground validation with multiple attempts
    local groundFound = false
    local groundPos = pos
    
    for zOffset = 0, 150, 25 do
        local groundTrace = util.TraceLine({
            start = pos + Vector(0, 0, zOffset),
            endpos = pos - Vector(0, 0, 250),
            mask = MASK_SOLID_BRUSHONLY
        })
        
        if groundTrace.Hit then
            groundPos = groundTrace.HitPos + Vector(0, 0, 18)
            groundFound = true
            break
        end
    end
    
    if not groundFound then return false end
    
    -- Update position to ground level
    pos = groundPos
    
    -- Headroom check
    local headTrace = util.TraceLine({
        start = pos,
        endpos = pos + Vector(0, 0, 72),
        mask = MASK_SOLID_BRUSHONLY
    })
    if headTrace.Hit and headTrace.Fraction < 0.9 then return false end
    
    -- Player distance validation
    local minDistance = GetConVar("arcade_min_spawn_distance"):GetInt()
    for _, playerPos in pairs(playerPositions) do
        if pos:Distance(playerPos) < minDistance then return false end
    end
    
    -- Entity collision check
    local entities = ents.FindInSphere(pos, 70)
    for _, ent in pairs(entities) do
        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent.IsArcadeEnemy) then
            return false
        end
    end
    
    return true
end

function Spawner.CalculateSpawnQuality(pos, playerPositions)
    local quality = 5.0
    
    if not playerPositions or #playerPositions == 0 then return quality end
    
    -- Distance scoring
    local minPlayerDist = math.huge
    local avgPlayerDist = 0
    
    for _, playerPos in pairs(playerPositions) do
        local dist = pos:Distance(playerPos)
        minPlayerDist = math.min(minPlayerDist, dist)
        avgPlayerDist = avgPlayerDist + dist
    end
    avgPlayerDist = avgPlayerDist / #playerPositions
    
    -- Optimal distance bonus (450-1200 units)
    if minPlayerDist >= 450 and minPlayerDist <= 1200 then
        quality = quality + 3
    elseif minPlayerDist >= 350 and minPlayerDist <= 1500 then
        quality = quality + 1
    end
    
    -- Line of sight penalty (hidden spawns preferred)
    local hiddenFromAll = true
    for _, playerPos in pairs(playerPositions) do
        local trace = util.TraceLine({
            start = playerPos + Vector(0, 0, 64),
            endpos = pos + Vector(0, 0, 32),
            mask = MASK_SOLID_BRUSHONLY
        })
        
        if not trace.Hit then
            hiddenFromAll = false
            break
        end
    end
    
    if hiddenFromAll then
        quality = quality + 2
    end
    
    -- Height advantage bonus
    for _, playerPos in pairs(playerPositions) do
        if pos.z > playerPos.z + 100 then
            quality = quality + 1.5
            break
        end
    end
    
    return math.Clamp(quality, 1, 10)
end

function Spawner.OptimizeSpawnDistribution()
    -- Sort by quality
    table.sort(Spawner.SpawnPoints, function(a, b)
        return (a.quality or 5) > (b.quality or 5)
    end)
    
    -- Remove clustered points for better distribution
    local optimized = {}
    local minDistance = 150
    
    for _, point in ipairs(Spawner.SpawnPoints) do
        local tooClose = false
        
        for _, existing in ipairs(optimized) do
            if point.pos:Distance(existing.pos) < minDistance then
                tooClose = true
                break
            end
        end
        
        if not tooClose and #optimized < 120 then
            table.insert(optimized, point)
        end
    end
    
    Spawner.SpawnPoints = optimized
    print("[Arcade Spawner] Optimized to " .. #Spawner.SpawnPoints .. " distributed spawn points")
end

-- ═══════════════════════════════════════════════════════════════
-- SESSION MANAGEMENT
-- ═══════════════════════════════════════════════════════════════
function ArcadeSpawner.StartSession()
    if Spawner.Active then
        print("[Arcade Spawner] Session already active!")
        return false
    end
    
    print("[Arcade Spawner] 🚀 Starting enhanced session...")
    
    -- Clear existing enemies
    if ArcadeSpawner.EnemyManager then
        local cleared = ArcadeSpawner.EnemyManager.ClearAllEnemies()
        print("[Arcade Spawner] Cleared " .. cleared .. " enemies")
    end
    
    -- Initialize session with proper tracking
    Spawner.Active = true
    Spawner.CurrentWave = 1
    Spawner.EnemiesKilled = 0
    Spawner.WaveEnemiesSpawned = 0
    Spawner.WaveEnemiesKilled = 0
    Spawner.SessionStartTime = CurTime()
    Spawner.WaveStartTime = CurTime()
    Spawner.DynamicDifficulty = 1.0
    Spawner.ActiveEnemies = {}
    Spawner.LastBossWave = 0
    Spawner.SpawningEnabled = true
    
    -- Calculate wave target
    Spawner.WaveEnemiesTarget = Spawner.CalculateWaveTarget(1)
    Spawner.WaveEnemiesRemaining = Spawner.WaveEnemiesTarget
    
    -- Perform map analysis
    local success = Spawner.PerformIntelligentMapAnalysis()
    if not success then
        print("[Arcade Spawner] ❌ Map analysis failed!")
        Spawner.Active = false
        return false
    end
    
    -- Start spawn system
    Spawner.InitializeSpawnSystem()
    
    -- FIXED: Send proper wave target to clients
    net.Start("ArcadeSpawner_SessionStart")
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)  -- Send target count
    net.Broadcast()
    
    -- FIXED: Also send initial wave start
    net.Start("ArcadeSpawner_WaveStart")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.WriteBool(false) -- Not a boss wave
    net.Broadcast()

    net.Start("ArcadeSpawner_WaveInfo")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.Broadcast()

    Spawner.LastSentRemaining = Spawner.WaveEnemiesTarget

    Spawner.LastSentRemaining = Spawner.WaveEnemiesTarget
    
    print("[Arcade Spawner] ✅ Session started! Wave 1 target: " .. Spawner.WaveEnemiesTarget)
    return true
end

function ArcadeSpawner.StopSession()
    if not Spawner.Active then return end
    
    Spawner.Active = false
    Spawner.SpawningEnabled = false
    
    -- Remove timers
    timer.Remove("ArcadeSpawner_MainSpawnLoop")
    timer.Remove("ArcadeSpawner_WaveManager")
    
    -- Clear enemies
    if ArcadeSpawner.EnemyManager then
        ArcadeSpawner.EnemyManager.ClearAllEnemies()
    end
    
    local sessionTime = math.floor(CurTime() - Spawner.SessionStartTime)
    
    print("[Arcade Spawner] Session ended! Kills: " .. Spawner.EnemiesKilled .. 
          ", Waves: " .. Spawner.CurrentWave .. ", Time: " .. sessionTime .. "s")
    
    -- Notify clients
    net.Start("ArcadeSpawner_SessionEnd")
    net.WriteInt(Spawner.EnemiesKilled, 32)
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(sessionTime, 16)
    net.Broadcast()
end

-- ═══════════════════════════════════════════════════════════════
-- SPAWN SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Spawner.InitializeSpawnSystem()
    -- Main spawn loop
    timer.Create("ArcadeSpawner_MainSpawnLoop", 1.0, 0, function()
        if not Spawner.Active then
            timer.Remove("ArcadeSpawner_MainSpawnLoop")
            return
        end
        
        Spawner.ExecuteSpawnCycle()
    end)
    
    -- Wave management
    timer.Create("ArcadeSpawner_WaveManager", 2.0, 0, function()
        if not Spawner.Active then
            timer.Remove("ArcadeSpawner_WaveManager")
            return
        end
        
        Spawner.ManageWaveProgression()
    end)
    
    -- Initial spawn burst
    timer.Simple(2, function()
        if not Spawner.Active then return end
        for i = 0, 3 do
            timer.Simple(i * 0.5, function()
                if Spawner.Active and Spawner.WaveEnemiesSpawned < Spawner.WaveEnemiesTarget then
                    Spawner.SpawnIntelligentEnemy()
                end
            end)
        end
    end)
end

function Spawner.ExecuteSpawnCycle()
    -- Clean up dead enemies
    Spawner.CleanupDeadEnemies()
    
    -- Calculate spawn requirements
    local maxEnemies = GetConVar("arcade_max_enemies"):GetInt()
    local remainingInWave = Spawner.WaveEnemiesTarget - Spawner.WaveEnemiesSpawned
    local currentEnemies = #Spawner.ActiveEnemies

    if remainingInWave > 0 and currentEnemies < maxEnemies then
        local spawnLeft = math.max(0, Spawner.WaveEnemiesTarget - Spawner.WaveEnemiesSpawned)
        local spawnCount = math.min(2, spawnLeft, maxEnemies - currentEnemies)

        for i = 1, spawnCount do
            if Spawner.WaveEnemiesSpawned >= Spawner.WaveEnemiesTarget then break end
            if not Spawner.SpawnIntelligentEnemy() then
                break
            end
        end
    end
end

function Spawner.SpawnIntelligentEnemy()
    if not Spawner.SpawningEnabled then return end

    if Spawner.WaveEnemiesSpawned >= Spawner.WaveEnemiesTarget then return end

    -- Select optimal spawn point
    local spawnPoint = Spawner.SelectOptimalSpawnPoint()
    if not spawnPoint or Spawner.WaveEnemiesSpawned >= Spawner.WaveEnemiesTarget then
        print("[Arcade Spawner] ⚠️ No available spawn points!")
        return
    end
    
    -- Determine if boss enemy
    local forceRarity = nil
    if Spawner.ShouldSpawnBoss() then
        forceRarity = "Mythic"
        print("[Arcade Spawner] 👹 Spawning BOSS enemy!")
    end
    
    -- Create enemy
    local enemy = nil
    if ArcadeSpawner.EnemyManager and ArcadeSpawner.EnemyManager.CreateEnemy then
        enemy = ArcadeSpawner.EnemyManager.CreateEnemy(spawnPoint.pos, Spawner.CurrentWave, forceRarity)
    end
    
    if IsValid(enemy) then
        table.insert(Spawner.ActiveEnemies, enemy)
        Spawner.WaveEnemiesSpawned = Spawner.WaveEnemiesSpawned + 1
        if Spawner.WaveEnemiesSpawned > Spawner.WaveEnemiesTarget then
            Spawner.WaveEnemiesSpawned = Spawner.WaveEnemiesTarget
        end

        print("[Arcade Spawner] ✅ Spawned " .. (enemy.RarityType or "Common") ..
              " enemy (" .. Spawner.WaveEnemiesSpawned .. "/" .. Spawner.WaveEnemiesTarget .. ")")
        
        return enemy
    else
        print("[Arcade Spawner] ❌ Failed to spawn enemy!")
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- WAVE MANAGEMENT & BOSS SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Spawner.ManageWaveProgression()
    if not Spawner.Active then return end

    -- ENHANCED: Comprehensive enemy cleanup and counting
    Spawner.CleanupDeadEnemies()

    if Spawner.WaveEnemiesSpawned > Spawner.WaveEnemiesTarget then
        Spawner.WaveEnemiesSpawned = Spawner.WaveEnemiesTarget
    end
    
    -- Count ONLY valid, alive enemies
    local aliveEnemies = 0
    local validEnemies = {}
    
    for i, enemy in ipairs(Spawner.ActiveEnemies) do
        if IsValid(enemy) and enemy:Alive() and enemy.IsArcadeEnemy then
            aliveEnemies = aliveEnemies + 1
            table.insert(validEnemies, enemy)
        end
    end
    
    -- Update active enemies list
    Spawner.ActiveEnemies = validEnemies
    
    -- FIXED: Accurate remaining calculation
    local enemiesRemaining = math.max(0, Spawner.WaveEnemiesTarget - Spawner.WaveEnemiesKilled)
    Spawner.WaveEnemiesRemaining = enemiesRemaining

    if enemiesRemaining ~= Spawner.LastSentRemaining then
        Spawner.LastSentRemaining = enemiesRemaining
        net.Start("ArcadeSpawner_WaveInfo")
        net.WriteInt(Spawner.CurrentWave, 16)
        net.WriteInt(enemiesRemaining, 16)
        net.WriteInt(Spawner.WaveEnemiesTarget, 16)
        net.Broadcast()
    end
    
    -- Track enemy count for HUD updates
    if aliveEnemies ~= Spawner.LastAliveCount then
        Spawner.LastAliveCount = aliveEnemies
    end
    
    -- Check wave completion
    local waveComplete = (Spawner.WaveEnemiesKilled >= Spawner.WaveEnemiesTarget) and (aliveEnemies == 0)
    
    if waveComplete then
        print("[Arcade Spawner] 🌊 Wave " .. Spawner.CurrentWave .. " COMPLETE!")
        Spawner.HandleWaveComplete()
    end
end

function Spawner.StartNextWave()
    Spawner.CurrentWave = Spawner.CurrentWave + 1
    Spawner.WaveEnemiesSpawned = 0
    Spawner.WaveEnemiesKilled = 0
    Spawner.WaveEnemiesTarget = Spawner.CalculateWaveTarget(Spawner.CurrentWave)
    Spawner.WaveEnemiesRemaining = Spawner.WaveEnemiesTarget
    Spawner.WaveStartTime = CurTime()
    Spawner.SpawningEnabled = true
    
    local isBossWave = Spawner.IsBossWave(Spawner.CurrentWave)
    
    print("[Arcade Spawner] 🌊 Wave " .. Spawner.CurrentWave .. " started! Target: " .. 
          Spawner.WaveEnemiesTarget .. (isBossWave and " (BOSS WAVE)" or ""))
    
    -- Refresh spawn points every few waves
    if Spawner.CurrentWave % 5 == 0 then
        timer.Simple(1, function()
            print("[Arcade Spawner] 🔄 Refreshing spawn points...")
            Spawner.PerformIntelligentMapAnalysis()
        end)
    end
    
    -- Notify clients
    net.Start("ArcadeSpawner_WaveStart")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.WriteBool(isBossWave)
    net.Broadcast()

    net.Start("ArcadeSpawner_WaveInfo")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.Broadcast()
    
    if isBossWave then
        net.Start("ArcadeSpawner_BossWave")
        net.WriteInt(Spawner.CurrentWave, 16)
        net.Broadcast()
    end
end

function Spawner.HandleWaveComplete()
    local completionTime = CurTime() - (Spawner.WaveStartTime or CurTime())
    Spawner.UpdateDynamicDifficulty(completionTime)

    Spawner.WaveEnemiesRemaining = 0
    Spawner.WaveEnemiesSpawned = Spawner.WaveEnemiesTarget
    Spawner.SpawningEnabled = false

    net.Start("ArcadeSpawner_WaveInfo")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.WriteInt(0, 16)
    net.WriteInt(Spawner.WaveEnemiesTarget, 16)
    net.Broadcast()

    Spawner.LastSentRemaining = 0

    net.Start("ArcadeSpawner_WaveComplete")
    net.WriteInt(Spawner.CurrentWave, 16)
    net.Broadcast()

    timer.Simple(3, function()
        if Spawner.Active then
            Spawner.StartNextWave()
        end
    end)
end

function Spawner.UpdateDynamicDifficulty(completionTime)
    local expected = 25 + (Spawner.CurrentWave * 5)
    local diff = Spawner.DynamicDifficulty or 1.0

    if completionTime < expected * 0.75 then
        diff = math.min(diff + 0.1, 2.0)
    elseif completionTime > expected * 1.25 then
        diff = math.max(diff - 0.05, 0.5)
    end

    Spawner.DynamicDifficulty = diff
end

function Spawner.IsBossWave(wave)
    if not ArcadeSpawner.Config then return false end
    
    local bossConfig = ArcadeSpawner.Config.BossWaves
    if not bossConfig then return false end
    
    -- Check special boss waves
    if table.HasValue(bossConfig.SpecialWaves or {}, wave) then
        return true
    end
    
    -- Check interval boss waves
    local interval = bossConfig.Interval or 5
    return wave % interval == 0
end

function Spawner.ShouldSpawnBoss()
    if not Spawner.IsBossWave(Spawner.CurrentWave) then return false end
    
    -- Only spawn one boss per wave
    for _, enemy in pairs(Spawner.ActiveEnemies) do
        if IsValid(enemy) and enemy.RarityType == "Mythic" then
            return false
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
function Spawner.CalculateWaveTarget(wave)
    local baseEnemies = 8 + (#player.GetAll() * 2)
    local scalePerWave = 1.4
    local maxEnemies = 80

    local difficulty = Spawner.DynamicDifficulty or 1.0

    local target = math.floor((baseEnemies + (wave - 1) * scalePerWave) * difficulty)
    return math.min(target, maxEnemies)
end

function Spawner.SelectOptimalSpawnPoint()
    if #Spawner.SpawnPoints == 0 then return nil end

    -- Filter available points
    local availablePoints = {}
    local players = Spawner.LastPlayerPositions or {}

    for _, point in ipairs(Spawner.SpawnPoints) do
        if Spawner.IsSpawnPointAvailable(point.pos) then
            -- Add multiple entries based on quality for weighted selection
            local weight = math.max(math.floor(point.quality or 5), 1)

            -- Bias toward points closer to players but outside min distance
            for _, pPos in ipairs(players) do
                local dist = point.pos:Distance(pPos)
                if dist < 1000 then weight = weight + 2 end
                if dist < 600 then weight = weight + 1 end
            end

            for i = 1, weight do
                table.insert(availablePoints, point)
            end
        end
    end
    
    return #availablePoints > 0 and table.Random(availablePoints) or nil
end

function Spawner.IsSpawnPointAvailable(pos)
    -- Check for nearby entities
    local entities = ents.FindInSphere(pos, 100)
    for _, ent in pairs(entities) do
        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent.IsArcadeEnemy) then
            return false
        end
    end
    
    -- Check player distance
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            if pos:Distance(ply:GetPos()) < GetConVar("arcade_min_spawn_distance"):GetInt() then
                return false
            end
        end
    end
    
    return true
end

function Spawner.CleanupDeadEnemies()
    local alive = {}
    local removed = 0
    
    for _, enemy in ipairs(Spawner.ActiveEnemies) do
        if IsValid(enemy) and enemy:Alive() then
            table.insert(alive, enemy)
        else
            removed = removed + 1
        end
    end
    
    if removed > 0 then
        print("[Arcade Spawner] 🧹 Cleaned up " .. removed .. " dead enemies")
    end
    
    Spawner.ActiveEnemies = alive
end

function Spawner.GetMapBounds()
    if Spawner.MapBounds then return Spawner.MapBounds end
    
    local minBounds = Vector(math.huge, math.huge, math.huge)
    local maxBounds = Vector(-math.huge, -math.huge, -math.huge)
    
    -- Use NavMesh bounds if available
    local navAreas = navmesh.GetAllNavAreas()
    if navAreas and #navAreas > 0 then
        for _, area in ipairs(navAreas) do
            if IsValid(area) then
                local center = area:GetCenter()
                if center then
                    minBounds.x = math.min(minBounds.x, center.x - 800)
                    minBounds.y = math.min(minBounds.y, center.y - 800)
                    minBounds.z = math.min(minBounds.z, center.z - 300)
                    
                    maxBounds.x = math.max(maxBounds.x, center.x + 800)
                    maxBounds.y = math.max(maxBounds.y, center.y + 800)
                    maxBounds.z = math.max(maxBounds.z, center.z + 400)
                end
            end
        end
    end
    
    -- Fallback to entity bounds
    if minBounds.x == math.huge then
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) then
                local pos = ent:GetPos()
                minBounds.x = math.min(minBounds.x, pos.x - 1500)
                minBounds.y = math.min(minBounds.y, pos.y - 1500)
                minBounds.z = math.min(minBounds.z, pos.z - 400)
                
                maxBounds.x = math.max(maxBounds.x, pos.x + 1500)
                maxBounds.y = math.max(maxBounds.y, pos.y + 1500)
                maxBounds.z = math.max(maxBounds.z, pos.z + 400)
            end
        end
    end
    
    Spawner.MapBounds = {min = minBounds, max = maxBounds}
    return Spawner.MapBounds
end

-- ═══════════════════════════════════════════════════════════════
-- EVENT HOOKS
-- ═══════════════════════════════════════════════════════════════
hook.Add("OnNPCKilled", "ArcadeSpawner_EnemyKilled", function(npc, attacker, inflictor)
    if IsValid(npc) and npc.IsArcadeEnemy and Spawner.Active then
        Spawner.EnemiesKilled = Spawner.EnemiesKilled + 1
        if Spawner.WaveEnemiesKilled < Spawner.WaveEnemiesTarget then
            Spawner.WaveEnemiesKilled = Spawner.WaveEnemiesKilled + 1
            if Spawner.WaveEnemiesKilled > Spawner.WaveEnemiesTarget then
                Spawner.WaveEnemiesKilled = Spawner.WaveEnemiesTarget
            end
        end
        
        -- Handle XP if player killed
        local xp = 30
        if IsValid(attacker) and attacker:IsPlayer() then
            xp = 30 * (npc.XPMultiplier or 1.0)
            if ArcadeSpawner.UIManager then
                ArcadeSpawner.UIManager.GiveXP(attacker, xp)
            end
        end
        
        -- FIXED: Notify clients with comprehensive data

        local remaining = math.max(0, Spawner.WaveEnemiesTarget - Spawner.WaveEnemiesKilled)
        Spawner.WaveEnemiesRemaining = remaining

        net.Start("ArcadeSpawner_EnemyKilled")
        net.WriteInt(Spawner.EnemiesKilled, 32)        -- Total kills
        net.WriteInt(Spawner.CurrentWave, 16)          -- Current wave
        net.WriteInt(xp, 16)                           -- XP gained
        net.WriteBool(npc.RarityType == "Mythic")      -- Is boss
        net.WriteInt(remaining, 16)                    -- Remaining enemies
        net.Broadcast()
        
        print("[Arcade Spawner] Enemy killed! Total: " .. Spawner.EnemiesKilled ..
              " | Wave: " .. Spawner.CurrentWave ..
              " | Remaining: " .. remaining)
    end
end)

print("[Arcade Spawner] 🎮 Enhanced Spawner with Procedural Systems loaded!")