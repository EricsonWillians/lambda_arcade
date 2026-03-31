--[[
    Arcade Anomaly: Spawn Manager
    
    Handles spawning enemies using the director's budget and validated anchors.
--]]

AA.SpawnManager = AA.SpawnManager or {}
AA.SpawnManager.SpawnQueue = {}
AA.SpawnManager.LastSpawnTime = 0
AA.SpawnManager.SpawnInterval = 2.0

-- Spawn an enemy of a specific archetype
function AA.SpawnManager:SpawnEnemy(archetype, anchorOverride)
    -- Wrap entire spawn in pcall for crash protection
    local ok, result, errCode = pcall(function()
        return self:SpawnEnemyInternal(archetype, anchorOverride)
    end)
    
    if not ok then
        print("[AA SpawnManager] CRASH PREVENTED: " .. tostring(result))
        
        -- Notify admins of spawn failure
        if AA.Net and AA.Net.ShowToast then
            for _, ply in ipairs(player.GetAll()) do
                if ply:IsAdmin() then
                    AA.Net.ShowToast(ply, "Enemy spawn crashed! Check console.", "ERROR", 5)
                end
            end
        end
        
        return nil, 3 -- COLLISION_FAIL
    end
    
    return result, errCode
end

-- Internal spawn function (protected by pcall wrapper)
function AA.SpawnManager:SpawnEnemyInternal(archetype, anchorOverride)
    -- Safety checks
    if not AA.RunState or not AA.RunState.IsRunning then
        return nil, 5 -- COOLDOWN_ACTIVE
    end
    
    if not AA.RunState:IsRunning() then
        return nil, 5 -- COOLDOWN_ACTIVE
    end
    
    if not AA.EnemyManager or not AA.GameDirector then
        return nil, 4 -- ENEMY_CAP_REACHED (closest error)
    end
    
    -- Check enemy cap
    if AA.EnemyManager:GetAliveCount() >= AA.GameDirector:GetCurrentEnemyCap() then
        return nil, 4 -- ENEMY_CAP_REACHED
    end
    
    -- Get or find anchor
    local anchor = anchorOverride
    if not anchor then
        anchor = self:FindValidAnchor()
    end
    
    if not anchor then
        return nil, 1 -- NO_VALID_ANCHOR
    end
    
    -- Validate spawn position
    local spawnPos = self:CalculateSpawnPosition(anchor)
    if not spawnPos then
        return nil, 3 -- COLLISION_FAIL
    end
    
    -- Check player distance
    if not self:IsValidPlayerDistance(spawnPos) then
        return nil, 2 -- TOO_CLOSE_TO_PLAYER
    end
    
    -- Get model before creating entity
    local modelData = nil
    if AA.ModelRegistry then
        modelData = AA.ModelRegistry:GetModelForArchetype(archetype, false)
    end
    
    -- Check if admin has forced a specific model
    local forcedModel = self:GetForcedModel()
    if forcedModel then
        modelData = { path = forcedModel, scale = 1.0, isFallback = false }
    end
    
    -- Create the enemy entity
    local enemy = self:CreateEnemyEntity(archetype, spawnPos, modelData)
    if not IsValid(enemy) then
        return nil, 3 -- COLLISION_FAIL
    end
    
    -- Configure the enemy (without re-setting model)
    self:ConfigureEnemy(enemy, archetype, anchor)
    
    -- Notify systems
    if AA.EnemyManager and AA.EnemyManager.RegisterEnemy then
        AA.EnemyManager:RegisterEnemy(enemy)
    end
    
    if AA.Net and AA.Net.BroadcastEnemySpawn then
        AA.Net.BroadcastEnemySpawn(enemy:EntIndex(), archetype, spawnPos, enemy.IsElite or false)
    end
    
    -- FX
    if AA.FX and AA.FX.DispatchSpawn then
        AA.FX.DispatchSpawn(spawnPos, enemy.IsElite)
    end
    
    -- Record anchor usage
    if AA.MapAnalyzer and AA.MapAnalyzer.RecordAnchorResult then
        AA.MapAnalyzer:RecordAnchorResult(anchor, true)
    end
    
    self.LastSpawnTime = CurTime()
    
    return enemy, 0 -- SUCCESS
end

function AA.SpawnManager:FindValidAnchor()
    if not AA.MapAnalyzer or not AA.MapAnalyzer.GetAnchors then return nil end
    
    local anchors = AA.MapAnalyzer:GetAnchors()
    if #anchors == 0 then return nil end
    
    -- Filter by cooldown
    local now = CurTime()
    local validAnchors = {}
    local cooldown = 30 -- default
    
    if AA.Balance and AA.Balance.MapAnalysis and AA.Balance.MapAnalysis.AnchorCooldown then
        cooldown = AA.Balance.MapAnalysis.AnchorCooldown
    end
    
    for _, anchor in ipairs(anchors) do
        if now - anchor.lastUsed >= cooldown then
            table.insert(validAnchors, anchor)
        end
    end
    
    if #validAnchors == 0 then
        -- Fallback: use any anchor with lower quality
        if AA.MapAnalyzer.GetRandomAnchor then
            return AA.MapAnalyzer:GetRandomAnchor(true)
        end
        return nil
    end
    
    -- Weighted random by quality
    local totalQuality = 0
    for _, anchor in ipairs(validAnchors) do
        totalQuality = totalQuality + anchor.quality
    end
    
    local roll = math.random() * totalQuality
    local current = 0
    
    for _, anchor in ipairs(validAnchors) do
        current = current + anchor.quality
        if roll <= current then
            return anchor
        end
    end
    
    return validAnchors[1]
end

function AA.SpawnManager:CalculateSpawnPosition(anchor)
    local basePos = anchor.position
    
    -- Add some randomness to prevent stacking
    local offset = Vector(
        math.random(-64, 64),
        math.random(-64, 64),
        0
    )
    
    local spawnPos = basePos + offset
    
    -- Verify the position is still valid
    if not AA.MapAnalyzer:IsValidSpawnAnchor(spawnPos) then
        -- Try base position
        if AA.MapAnalyzer:IsValidSpawnAnchor(basePos) then
            return basePos
        end
        return nil
    end
    
    return spawnPos
end

function AA.SpawnManager:IsValidPlayerDistance(pos)
    for _, ply in ipairs(AA.Util.GetAlivePlayers()) do
        local dist = ply:GetPos():DistToSqr(pos)
        if dist < (AA.Config.Game.MinSpawnDistance ^ 2) then
            return false
        end
        
        -- Check line of sight
        if dist < (AA.Config.Game.MinSpawnDistance * 2) ^ 2 then
            local trace = util.TraceLine({
                start = ply:EyePos(),
                endpos = pos + Vector(0, 0, 48),
                mask = MASK_SOLID,
            })
            
            if not trace.Hit then
                -- Player can see this spot, don't spawn here
                return false
            end
        end
    end
    
    return true
end

function AA.SpawnManager:CreateEnemyEntity(archetype, pos, modelData)
    if not AA.Types or not AA.Types.ArchetypeNames then
        return nil
    end
    
    local archetypeName = AA.Types.ArchetypeNames[archetype]
    if not archetypeName then 
        return nil 
    end
    
    -- Determine entity class based on archetype
    local className = "aa_enemy_" .. string.lower(archetypeName)
    
    -- Create entity
    local enemy = ents.Create(className)
    if not IsValid(enemy) then
        return nil
    end
    
    enemy:SetPos(pos)
    enemy:SetAngles(Angle(0, math.random(0, 360), 0))
    
    -- Set model BEFORE spawning if available
    if modelData and modelData.path then
        -- Validate model exists
        if util.IsValidModel(modelData.path) then
            enemy:SetModel(modelData.path)
            enemy.ModelData = modelData
        else
            enemy:SetModel("models/Humans/Group01/male_07.mdl")
            enemy.ModelData = {path = "models/Humans/Group01/male_07.mdl", scale = 1.0}
        end
    end
    
    -- Spawn with error handling
    local ok, err = pcall(function()
        enemy:Spawn()
        enemy:Activate()
    end)
    
    if not ok then
        print("[AA SpawnManager] Spawn/Activate failed: " .. tostring(err))
        if IsValid(enemy) then enemy:Remove() end
        return nil
    end
    
    -- Verify entity is still valid after spawn
    if not IsValid(enemy) then
        return nil
    end
    
    -- Initialize animation system AFTER spawn (needs entity to be fully created)
    if enemy.SetupAnimation then
        local ok2, err2 = pcall(function()
            enemy:SetupAnimation()
        end)
        if not ok2 then
            -- Animation errors are non-fatal
        end
    end
    
    return enemy
end

function AA.SpawnManager:ConfigureEnemy(enemy, archetype, anchor)
    -- Set base properties
    enemy.Archetype = archetype
    enemy.SpawnAnchor = anchor
    enemy.SpawnTime = CurTime()
    
    -- Determine if elite
    local eliteChance = AA.GameDirector:GetEliteChance()
    enemy.IsElite = math.random() < eliteChance
    
    -- Apply difficulty scaling
    local runTime = AA.RunState:GetRunTime() / 60 -- minutes
    local diff = AA.Balance and AA.Balance.Difficulty
    
    if diff then
        -- Scale health
        local healthMult = 1 + (runTime * diff.HealthGrowth)
        if enemy.IsElite then
            healthMult = healthMult * AA.Balance.EliteModifiers.HealthMult
        end
        enemy:SetHealth(enemy:Health() * healthMult)
        enemy:SetMaxHealth(enemy:GetMaxHealth() * healthMult)
        
        -- Scale damage
        enemy.DamageMult = 1 + (runTime * diff.DamageGrowth)
        if enemy.IsElite then
            enemy.DamageMult = enemy.DamageMult * AA.Balance.EliteModifiers.DamageMult
        end
    end
    
    -- Model already set before Spawn(), apply scale and elite status here
    if enemy.ModelData then
        local modelData = enemy.ModelData
        
        -- Apply scale if specified
        if modelData.scale and modelData.scale ~= 1.0 then
            local scale = modelData.scale
            enemy:SetModelScale(scale, 0)
            -- Adjust collision bounds proportionally
            local mins, maxs = enemy:GetCollisionBounds()
            enemy:SetCollisionBounds(mins * scale, maxs * scale)
        end
        
        -- Reset animation system for new model
        if enemy.SetupAnimation then
            local ok, err = pcall(function()
                enemy:SetupAnimation()
            end)
            if not ok then
                print("[AA SpawnManager] SetupAnimation warning: " .. tostring(err))
            end
        end
    end
end

-- Get forced model from any admin player
function AA.SpawnManager:GetForcedModel()
    for _, ply in ipairs(player.GetAll()) do
        if ply.AA_ForcedModel then
            if ply.AA_ForcedModel == "RANDOM" then
                -- Pick a random discovered model
                if not AA.ModelRegistry or not AA.ModelRegistry.Models then return nil end
                
                local discovered = {}
                for path, data in pairs(AA.ModelRegistry.Models) do
                    if not data.isFallback and data.approved then
                        table.insert(discovered, path)
                    end
                end
                
                if #discovered > 0 then
                    return discovered[math.random(1, #discovered)]
                end
            else
                return ply.AA_ForcedModel
            end
        end
    end
    return nil
end

-- Get random workshop model (for testing)
function AA.SpawnManager:GetRandomWorkshopModel()
    local discovered = {}
    for path, data in pairs(AA.ModelRegistry.Models) do
        if not data.isFallback and data.approved then
            table.insert(discovered, data)
        end
    end
    
    if #discovered > 0 then
        return discovered[math.random(1, #discovered)]
    end
    
    return AA.ModelRegistry:GetUltimateFallback()
end

-- Spawn queue management
function AA.SpawnManager:QueueSpawn(archetype, priority)
    priority = priority or 0
    table.insert(self.SpawnQueue, {
        archetype = archetype,
        priority = priority,
        queuedAt = CurTime(),
    })
    
    -- Sort by priority
    table.sort(self.SpawnQueue, function(a, b)
        return a.priority > b.priority
    end)
end

function AA.SpawnManager:ProcessQueue()
    if #self.SpawnQueue == 0 then return end
    
    -- Safety check: only process if run is active
    if not AA.RunState or not AA.RunState:IsRunning() then
        self.SpawnQueue = {}
        return
    end
    
    local now = CurTime()
    if now - self.LastSpawnTime < self:GetSpawnInterval() then
        return
    end
    
    -- Get highest priority spawn
    local spawn = table.remove(self.SpawnQueue, 1)
    
    -- Check if too old
    if now - spawn.queuedAt > 10 then
        return self:ProcessQueue() -- Try next
    end
    
    print("[AA DEBUG] Spawning enemy of archetype: " .. tostring(spawn.archetype))
    local result = self:SpawnEnemy(spawn.archetype)
    print("[AA DEBUG] SpawnEnemy returned: " .. tostring(result))
    return result
end

function AA.SpawnManager:GetSpawnInterval()
    local base = self.SpawnInterval
    local runTime = AA.RunState:GetRunTime() / 60
    local reduction = 0
    if AA.Balance and AA.Balance.Difficulty then
        reduction = runTime * AA.Balance.Difficulty.SpawnRateGrowth
    end
    
    return math.max(
        base * (1 - reduction),
        AA.Config.Game.SpawnIntervalMin
    )
end

function AA.SpawnManager:SetSpawnInterval(interval)
    self.SpawnInterval = math.max(interval, AA.Config.Game.SpawnIntervalMin)
end

-- Think hook
hook.Add("Think", "AA_SpawnManager_Think", function()
    if not AA.RunState or not AA.RunState:IsRunning() then return end
    if not AA.SpawnManager then return end
    
    AA.SpawnManager:ProcessQueue()
end)

-- Debug command
concommand.Add("aa_force_spawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local archetype = tonumber(args[1]) or AA.Types.Archetype.CHASER
    print("[AA] Attempting to spawn archetype: " .. tostring(archetype))
    
    local enemy, result = AA.SpawnManager:SpawnEnemy(archetype)
    
    if IsValid(enemy) then
        print("[AA] Spawned: " .. tostring(enemy) .. " at " .. tostring(enemy:GetPos()))
        ply:ChatPrint("Spawned: " .. enemy:GetClass())
    else
        print("[AA] Spawn failed: " .. tostring(result))
        ply:ChatPrint("Spawn failed: " .. tostring(result))
    end
end)

-- Start run command
concommand.Add("aa_start", function(ply)
    if not IsValid(ply) then return end
    
    print("[AA] Manual run start requested by " .. ply:Nick())
    AA.RunState:RequestStart(ply)
end)

-- Debug: Test model selection
concommand.Add("aa_test_model_selection", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("[AA] Testing model selection (10 iterations):")
    print(string.rep("-", 60))
    
    local archetype = tonumber(args[1]) or 1
    local useCounts = {}
    
    for i = 1, 10 do
        local model = AA.ModelRegistry:GetModelForArchetype(archetype, false)
        if model then
            local path = model.path
            useCounts[path] = (useCounts[path] or 0) + 1
            print(string.format("%2d. %s", i, path))
        end
    end
    
    print(string.rep("-", 60))
    print("Summary:")
    for path, count in SortedPairs(useCounts) do
        local isFallback = ""
        if AA.ModelRegistry.Models[path] and AA.ModelRegistry.Models[path].isFallback then
            isFallback = " [FALLBACK]"
        end
        print(string.format("  %dx %s%s", count, path, isFallback))
    end
end)

-- Debug: Show model pool for archetype
concommand.Add("aa_model_pool", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local archetype = tonumber(args[1]) or 1
    local archetypeName = AA.Types.ArchetypeNames[archetype] or "UNKNOWN"
    
    print("[AA] Model pool for " .. archetypeName .. " (archetype " .. archetype .. "):")
    print(string.rep("=", 60))
    
    local approved = 0
    local fallback = 0
    local discovered = 0
    
    for path, data in SortedPairs(AA.ModelRegistry.Models) do
        if data.approved and not data.blacklisted then
            if data.isFallback then
                fallback = fallback + 1
                print("[F] " .. path)
            else
                discovered = discovered + 1
                local tags = table.concat(data.tags or {}, ", ")
                print("[W] " .. path .. " (" .. tags .. ")")
            end
            approved = approved + 1
        end
    end
    
    print(string.rep("=", 60))
    print(string.format("Total: %d approved (%d workshop, %d fallback)", approved, discovered, fallback))
end)
