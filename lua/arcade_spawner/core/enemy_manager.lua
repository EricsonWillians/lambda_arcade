-- addons/arcade_spawner/lua/arcade_spawner/core/enemy_manager.lua
-- BULLETPROOF Enemy Management with Workshop Model Validation v4.1

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.EnemyManager = ArcadeSpawner.EnemyManager or {}
local Manager = ArcadeSpawner.EnemyManager

if SERVER then
    util.AddNetworkString("ArcadeSpawner_WorkshopProgress")
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════
Manager.ValidatedModels = {}
Manager.BlacklistedModels = {}
Manager.WorkshopModels = {}
Manager.ActiveEnemies = {}
Manager.EnemyStats = {}
Manager.ValidationInProgress = false

-- Collect potential workshop models for validation
function Manager.CollectWorkshopModels()
    local workshopModels = {}

    local playerModels = list.Get("PlayerOptionsModel")
    local npcList = list.Get("NPC")

    if playerModels then
        for _, data in pairs(playerModels) do
            if data and data.Model then
                table.insert(workshopModels, {
                    model = data.Model,
                    source = "playermodel",
                    name = data.Name or "Unknown"
                })
            end
        end
    end

    if npcList then
        for className, data in pairs(npcList) do
            if data and data.Model and not Manager.IsVanillaModel(data.Model) then
                local entInfo = scripted_ents.GetStored(className)
                local npcClass = className
                if not entInfo then
                    npcClass = nil -- treat as generic model if entity not registered
                end
                table.insert(workshopModels, {
                    model = data.Model,
                    npc = npcClass,
                    source = "npc",
                    name = data.Name or className
                })
            end
        end
    end

    -- Recursively search the models folder for additional .mdl files
    local maxModels = ArcadeSpawner.Config.MaxWorkshopModels or 100
    local function AddModelsFromPath(path, depth)
        depth = depth or 0
        if depth > 5 or #workshopModels >= maxModels then return end

        local files, dirs = file.Find(path .. "*.mdl", "GAME")
        for _, f in ipairs(files) do
            if #workshopModels >= maxModels then return end
            local modelPath = path .. f
            if not Manager.IsVanillaModel(modelPath) then
                table.insert(workshopModels, {
                    model = modelPath,
                    source = "filesystem",
                    name = modelPath
                })
            end
        end

        local _, subdirs = file.Find(path .. "*", "GAME")
        for _, d in ipairs(subdirs) do
            if d ~= "." and d ~= ".." then
                AddModelsFromPath(path .. d .. "/", depth + 1)
                if #workshopModels >= maxModels then return end
            end
        end
    end

    AddModelsFromPath("models/")

    return workshopModels
end

-- Asynchronous scan to avoid hitches
function Manager.AsyncScanWorkshopModels()
    if Manager.ValidationInProgress then return end
    Manager.ValidationInProgress = true

    print("[Arcade Spawner] 🔍 Async scanning workshop models...")

    local workshopModels = Manager.CollectWorkshopModels()
    local index = 1
    local validated, rejected = 0, 0
    local total = #workshopModels

    net.Start("ArcadeSpawner_WorkshopProgress")
    net.WriteInt(0, 16)
    net.WriteInt(total, 16)
    net.Broadcast()

    timer.Create("ArcadeSpawner_WorkshopScan", 0.1, 0, function()
        local data = workshopModels[index]
        if not data then
            print("[Arcade Spawner] ✅ Workshop validation complete: " .. validated .. " validated, " .. rejected .. " rejected")
            Manager.ValidationInProgress = false
            timer.Remove("ArcadeSpawner_WorkshopScan")

            net.Start("ArcadeSpawner_WorkshopProgress")
            net.WriteInt(total, 16)
            net.WriteInt(total, 16)
            net.Broadcast()
            return
        end

        if validated < ArcadeSpawner.Config.MaxWorkshopModels then
            local result = Manager.ValidateWorkshopModel(data)
            if result.valid then
                table.insert(Manager.WorkshopModels, result.data)
                validated = validated + 1
            else
                rejected = rejected + 1
                print("[Arcade Spawner] ❌ Rejected: " .. data.model .. " (" .. result.reason .. ")")
            end
        end

        index = index + 1

        net.Start("ArcadeSpawner_WorkshopProgress")
        net.WriteInt(math.min(validated + rejected, total), 16)
        net.WriteInt(total, 16)
        net.Broadcast()

    end)
end

-- ═══════════════════════════════════════════════════════════════
-- BULLETPROOF WORKSHOP MODEL VALIDATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Manager.ScanWorkshopModels()
    if Manager.ValidationInProgress then return end
    Manager.ValidationInProgress = true
    
    print("[Arcade Spawner] 🔍 Scanning workshop models for validation...")

    local workshopModels = Manager.CollectWorkshopModels()

    print("[Arcade Spawner] 📦 Found " .. #workshopModels .. " potential workshop models")
    
    -- Validate each model
    local validated = 0
    local rejected = 0
    
    for _, modelData in ipairs(workshopModels) do
        if validated >= ArcadeSpawner.Config.MaxWorkshopModels then break end
        
        local validationResult = Manager.ValidateWorkshopModel(modelData)
        if validationResult.valid then
            table.insert(Manager.WorkshopModels, validationResult.data)
            validated = validated + 1
        else
            rejected = rejected + 1
            print("[Arcade Spawner] ❌ Rejected: " .. modelData.model .. " (" .. validationResult.reason .. ")")
        end
    end
    
    print("[Arcade Spawner] ✅ Workshop validation complete: " .. validated .. " validated, " .. rejected .. " rejected")
    Manager.ValidationInProgress = false
    
    return validated
end

function Manager.ValidateWorkshopModel(modelData)
    if not modelData or not modelData.model then
        return {valid = false, reason = "Invalid model data"}
    end
    
    local model = modelData.model
    local config = ArcadeSpawner.Config.WorkshopValidation
    
    -- Basic model validation
    if not Manager.ValidateModel(model) then
        return {valid = false, reason = "Model file invalid"}
    end
    
    -- Check for blacklisted keywords
    local modelLower = string.lower(model)
    for _, keyword in ipairs(config.BlacklistedKeywords) do
        if string.find(modelLower, string.lower(keyword)) then
            return {valid = false, reason = "Contains blacklisted keyword: " .. keyword}
        end
    end
    
    -- Create temporary entity to test model properties
    local testResult = Manager.TestModelProperties(model)
    if not testResult.valid then
        return {valid = false, reason = testResult.reason}
    end
    
    -- Determine appropriate NPC class
    local npcClass = Manager.DetermineNPCClass(modelData, testResult)
    
    return {
        valid = true,
        data = {
            model = model,
            npc = npcClass,
            category = "workshop",
            weight = Manager.CalculateModelWeight(testResult),
            accuracy = Manager.CalculateModelAccuracy(testResult),
            health = testResult.health,
            source = "workshop",
            validated = true,
            properties = testResult
        }
    }
end

function Manager.TestModelProperties(model)
    local success, result = pcall(function()
        -- Create temporary entity for testing
        local testEnt = ents.Create("prop_physics")
        if not IsValid(testEnt) then
            return {valid = false, reason = "Cannot create test entity"}
        end
        
        testEnt:SetModel(model)
        testEnt:Spawn()
        
        if not IsValid(testEnt) then
            return {valid = false, reason = "Model failed to spawn"}
        end
        
        -- Get model properties
        local mins, maxs = testEnt:GetModelBounds()
        local size = (maxs - mins):Length()
        local mass = testEnt:GetPhysicsObject():IsValid() and testEnt:GetPhysicsObject():GetMass() or 100
        
        -- Estimate health based on size and mass
        local estimatedHealth = math.Clamp(math.floor((size + mass) / 10), 50, 500)
        
        -- Check sequences
        local hasBasicSequences = Manager.CheckRequiredSequences(testEnt)
        
        -- Clean up
        testEnt:Remove()
        
        -- Validation checks
        local config = ArcadeSpawner.Config.WorkshopValidation
        
        if size > config.MaxModelSize then
            return {valid = false, reason = "Model too large: " .. math.floor(size)}
        end
        
        if estimatedHealth > config.MaxHealthThreshold then
            return {valid = false, reason = "Health too high: " .. estimatedHealth}
        end
        
        if estimatedHealth < config.MinHealthThreshold then
            return {valid = false, reason = "Health too low: " .. estimatedHealth}
        end
        
        if not hasBasicSequences then
            return {valid = false, reason = "Missing required animations"}
        end
        
        return {
            valid = true,
            size = size,
            mass = mass,
            health = estimatedHealth,
            sequences = hasBasicSequences
        }
    end)
    
    if not success then
        return {valid = false, reason = "Testing error: " .. tostring(result)}
    end
    
    return result
end

function Manager.CheckRequiredSequences(ent)
    if not IsValid(ent) then return false end

    local idleSeqs = {"idle", "idle_all", "Idle01", "ACT_IDLE"}
    local moveSeqs = {"walk", "run", "walk_all", "run_all"}

    local hasIdle = false
    local hasMove = false

    for _, seq in ipairs(idleSeqs) do
        if ent:LookupSequence(seq) >= 0 then
            hasIdle = true
            break
        end
    end

    for _, seq in ipairs(moveSeqs) do
        if ent:LookupSequence(seq) >= 0 then
            hasMove = true
            break
        end
    end

    return hasIdle and hasMove
end

function Manager.DetermineNPCClass(modelData, testResult)
    -- Use provided NPC class if available
    if modelData.npc then
        return modelData.npc
    end
    
    -- Determine based on model characteristics
    local health = testResult.health
    local size = testResult.size
    
    if health >= 300 then
        return "npc_combine_s" -- Heavy unit
    elseif health >= 150 then
        return "npc_metropolice" -- Medium unit
    elseif size < 50 then
        return "npc_citizen" -- Small/civilian
    else
        return "npc_barney" -- Default humanoid
    end
end

function Manager.CalculateModelWeight(testResult)
    local baseWeight = 2.0
    local health = testResult.health
    
    if health >= 300 then
        return baseWeight + 2.0
    elseif health >= 150 then
        return baseWeight + 1.0
    else
        return baseWeight
    end
end

function Manager.CalculateModelAccuracy(testResult)
    local baseAccuracy = 0.70
    local health = testResult.health
    
    -- Higher health models are assumed to be more skilled
    if health >= 300 then
        return baseAccuracy + 0.15
    elseif health >= 150 then
        return baseAccuracy + 0.10
    else
        return baseAccuracy
    end
end

function Manager.IsVanillaModel(model)
    local vanillaModels = {
        "models/combine_soldier.mdl",
        "models/combine_super_soldier.mdl",
        "models/police.mdl",
        "models/barney.mdl",
        "models/alyx.mdl",
        "models/zombie/classic.mdl",
        "models/zombie/fast.mdl",
        "models/zombie/poison.mdl",
        "models/antlion.mdl",
        "models/antlion_guard.mdl"
    }
    
    return table.HasValue(vanillaModels, model)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED MODEL CACHE BUILDING
-- ═══════════════════════════════════════════════════════════════
function Manager.BuildSafeModelCache()
    Manager.ValidatedModels = {}
    
    if not ArcadeSpawner.Config or not ArcadeSpawner.Config.SafeNPCModels then
        print("[Arcade Spawner] ❌ Config not available for model validation!")
        return false
    end
    
    local validCount = 0
    
    -- Add vanilla models first
    for _, modelData in ipairs(ArcadeSpawner.Config.SafeNPCModels) do
        local valid = Manager.ValidateModel(modelData.model)
        if not valid then
            print("[Arcade Spawner] ⚠️ Invalid vanilla model: " .. modelData.model)
        end
        table.insert(Manager.ValidatedModels, {
            model = modelData.model,
            npc = modelData.npc,
            category = modelData.category,
            weight = modelData.weight or 1.0,
            accuracy = modelData.accuracy or 0.70,
            health = modelData.health or 100,
            source = "config",
            validated = valid
        })
        validCount = validCount + 1
    end
    
    -- Add validated workshop models if enabled
    if GetConVar("arcade_workshop_validation"):GetBool() then
        local workshopCount = Manager.ScanWorkshopModels()
        for _, workshopModel in ipairs(Manager.WorkshopModels) do
            table.insert(Manager.ValidatedModels, workshopModel)
            validCount = validCount + 1
        end
        print("[Arcade Spawner] 📦 Added " .. workshopCount .. " workshop models")
    end
    
    print("[Arcade Spawner] ✅ Validated " .. validCount .. " total models")
    return validCount > 0
end

function Manager.ValidateModel(modelPath)
    if not modelPath or modelPath == "" then return false end
    if Manager.BlacklistedModels[modelPath] then return false end

    local success = pcall(function()
        if not util.IsValidModel(modelPath) then error("Invalid model") end
        if not file.Exists(modelPath, "GAME") then error("File not found") end

        local testEnt = ents.Create("prop_physics")
        if not IsValid(testEnt) then error("Failed entity") end

        testEnt:SetModel(modelPath)
        testEnt:Spawn()

        local idle = testEnt:LookupSequence("idle")
        if idle < 0 then idle = testEnt:SelectWeightedSequence(ACT_IDLE) end
        local walk = testEnt:LookupSequence("walk")
        if walk < 0 then walk = testEnt:SelectWeightedSequence(ACT_WALK) end

        testEnt:Remove()

        if idle < 0 or walk < 0 then
            error("Missing basic animations")
        end
    end)

    if not success then
        Manager.BlacklistedModels[modelPath] = true
    end

    return success
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED ENEMY CREATION WITH OVERPOWERED CHECKS
-- ═══════════════════════════════════════════════════════════════
function Manager.CreateEnemy(pos, wave, forceRarity)
    if not pos or not isvector(pos) then return nil end
    
    -- Ensure models are available
    if #Manager.ValidatedModels == 0 then
        Manager.BuildSafeModelCache()
        if #Manager.ValidatedModels == 0 then
            print("[Arcade Spawner] ❌ No validated models available!")
            return nil
        end
    end
    
    local enemy = nil
    local maxAttempts = 5
    
    for attempt = 1, maxAttempts do
        enemy = Manager.CreateAdvancedEnemy(pos, wave, forceRarity, attempt)
        Manager.EnhanceEnemyCombat(enemy)
        if IsValid(enemy) then
            -- Final overpowered check
            if Manager.IsEnemyOverpowered(enemy, wave) then
                print("[Arcade Spawner] ⚠️ Enemy too overpowered for wave " .. wave .. ", adjusting...")
                Manager.BalanceEnemyForWave(enemy, wave)
            end
            break
        end
    end
    
    if IsValid(enemy) then
        -- Track enemy
        table.insert(Manager.ActiveEnemies, enemy)
        Manager.EnemyStats[enemy:EntIndex()] = {
            spawnTime = CurTime(),
            wave = wave,
            rarity = enemy.RarityType or "Common"
        }
        
        return enemy
    end
    
    return nil
end

function Manager.IsEnemyOverpowered(enemy, wave)
    if not IsValid(enemy) or not wave then return false end
    
    local health = enemy:GetMaxHealth()
    local expectedMaxHealth = 100 + (wave * 50) -- Base scaling expectation
    
    -- Check if enemy health is way beyond wave expectations
    if health > expectedMaxHealth * 3 then
        return true
    end
    
    -- Check workshop model properties if available
    if enemy.ModelData and enemy.ModelData.source == "workshop" then
        local originalHealth = enemy.ModelData.health or 100
        if originalHealth > ArcadeSpawner.Config.WorkshopValidation.MaxHealthThreshold then
            return true
        end
    end
    
    return false
end

function Manager.BalanceEnemyForWave(enemy, wave)
    if not IsValid(enemy) then return end
    
    -- Calculate appropriate health for current wave
    local maxAllowedHealth = 100 + (wave * 40)
    local currentHealth = enemy:GetMaxHealth()
    
    if currentHealth > maxAllowedHealth then
        enemy:SetMaxHealth(maxAllowedHealth)
        enemy:SetHealth(maxAllowedHealth)
        print("[Arcade Spawner] 🔧 Balanced enemy health: " .. currentHealth .. " -> " .. maxAllowedHealth)
    end
    
    -- Adjust damage multiplier if too high
    if enemy.DamageMultiplier and enemy.DamageMultiplier > 3.0 then
        enemy.DamageMultiplier = math.min(enemy.DamageMultiplier, 1.5 + (wave * 0.1))
        print("[Arcade Spawner] 🔧 Balanced enemy damage multiplier")
    end
end

function Manager.CreateAdvancedEnemy(pos, wave, forceRarity, attempt)
    local enemy = nil
    
    local success, errorMsg = pcall(function()
        -- Select model intelligently
        local modelData = Manager.SelectBalancedModel(wave, attempt)
        if not modelData then 
            error("No suitable model found")
            return
        end
        
        -- ENHANCED: Position validation before entity creation
        local spawnPos = Manager.ValidateSpawnPosition(pos, attempt)
        if not spawnPos then 
            error("No valid spawn position found")
            return
        end
        
        -- Create NPC with validation and graceful fallback
        local npcClass = modelData.npc or "npc_citizen"
        local entInfo = scripted_ents.GetStored(npcClass)
        if not entInfo then
            if list.Get("NPC")[npcClass] then
                print("[Arcade Spawner] ⚠️ NPC class '" .. npcClass .. "' not registered, using npc_citizen")
            else
                print("[Arcade Spawner] ⚠️ Invalid NPC class '" .. npcClass .. "', using npc_citizen")
            end
            npcClass = "npc_citizen"
        end

        enemy = ents.Create(npcClass)
        if not IsValid(enemy) then
            error("Failed to create entity: " .. npcClass)
            return
        end
        
        -- CRITICAL: Set position BEFORE model to prevent stuck spawns
        enemy:SetPos(spawnPos)
        enemy:SetAngles(Angle(0, math.random(0, 360), 0))
        
        -- Set model with validation
        if not util.IsValidModel(modelData.model) then
            error("Invalid model: " .. modelData.model)
            return
        end
        
        enemy:SetModel(modelData.model)
        enemy:Spawn()
        enemy:Activate()

        -- Validate animation sequences to avoid T-poses
        local idleSeq = enemy:SelectWeightedSequence(ACT_IDLE)
        if idleSeq <= 0 then
            print("[Arcade Spawner] ⚠️ Missing idle sequence for " .. modelData.model)
            SafeRemoveEntity(enemy)
            enemy = nil
            error("Model missing idle sequence")
        end
        
        -- IMMEDIATE validation after spawn
        if not IsValid(enemy) or not enemy:Alive() then
            error("Enemy failed validation after spawn")
            return
        end
        
        -- Mark as arcade enemy FIRST
        enemy.IsArcadeEnemy = true
        enemy.ModelData = modelData
        enemy.SpawnTime = CurTime()
        enemy.WaveLevel = wave or 1
        
        -- Apply rarity and scaling
        local rarity = forceRarity or Manager.DetermineRarity(wave)
        enemy.RarityType = rarity
        Manager.ApplyDynamicScaling(enemy, rarity, wave)
        
        -- FIXED: Setup relationships BEFORE AI
        Manager.SetupEnemyRelationships(enemy)
        
        -- Setup advanced AI
        Manager.SetupAdvancedAI(enemy)
        
        -- Apply weapon loadout
        Manager.ApplyWeaponLoadout(enemy, wave)
        
        print("[Arcade Spawner] ✅ Created " .. rarity .. " " .. modelData.category .. " (Wave " .. wave .. ")")
    end)
    
    if not success then
        print("[Arcade Spawner] ❌ Enemy creation failed: " .. tostring(errorMsg))
        if IsValid(enemy) then
            SafeRemoveEntity(enemy)
            enemy = nil
        end
    end
    
    return enemy
end

function Manager.SelectBalancedModel(wave, attempt)
    if #Manager.ValidatedModels == 0 then return nil end
    
    -- Filter models appropriate for current wave
    local suitableModels = {}
    
    for _, model in ipairs(Manager.ValidatedModels) do
        local modelHealth = model.health or 100
        local waveMaxHealth = 100 + (wave * 60) -- Expected max health for wave
        
        -- Prefer models that aren't too overpowered for current wave
        if modelHealth <= waveMaxHealth * 1.5 then
            table.insert(suitableModels, model)
        end
    end
    
    -- If no suitable models found (shouldn't happen), use all
    if #suitableModels == 0 then
        suitableModels = Manager.ValidatedModels
    end
    
    -- Prefer military units for higher waves
    if wave >= 15 and attempt <= 2 then
        for _, model in ipairs(suitableModels) do
            if model.category == "military" or model.category == "elite" then
                return model
            end
        end
    end
    
    return table.Random(suitableModels)
end

-- ═══════════════════════════════════════════════════════════════
-- DYNAMIC DIFFICULTY SCALING SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Manager.ApplyDynamicScaling(enemy, rarity, wave)
    if not IsValid(enemy) or not ArcadeSpawner.Config then return end
    
    local config = ArcadeSpawner.Config
    local rarityData = config.RaritySystem[rarity] or config.RaritySystem["Common"]
    local waveScaling = config.WaveScaling
    local difficulty = (ArcadeSpawner.Spawner and ArcadeSpawner.Spawner.DynamicDifficulty) or 1.0
    
    -- Calculate wave multipliers with caps
    local waveHealthMult = math.min(1 + ((wave - 1) * waveScaling.HealthScale), waveScaling.MaxHealthMultiplier) * difficulty
    local waveSpeedMult = math.min(1 + ((wave - 1) * waveScaling.SpeedScale), waveScaling.MaxSpeedMultiplier) * difficulty
    local waveAccuracyMult = math.min(1 + ((wave - 1) * waveScaling.AccuracyScale), waveScaling.MaxAccuracyMultiplier) * difficulty
    local waveDamageMult = math.min(1 + ((wave - 1) * waveScaling.DamageScale), waveScaling.MaxDamageMultiplier) * difficulty
    
    pcall(function()
        -- Health scaling with workshop model consideration
        local baseHealth = enemy.ModelData.health or math.max(enemy:GetMaxHealth(), 50)
        local finalHealth = math.floor(baseHealth * rarityData.healthMultiplier * waveHealthMult)
        
        -- Cap health for balance
        local maxHealthForWave = 150 + (wave * 75)
        finalHealth = math.min(finalHealth, maxHealthForWave)
        
        enemy:SetMaxHealth(finalHealth)
        enemy:SetHealth(finalHealth)
        enemy:SetNWInt("ArcadeMaxHP", finalHealth)
        
        -- Color and visual scaling
        enemy:SetColor(rarityData.color)
        
        -- Store multipliers for AI system
        enemy.SpeedMultiplier = rarityData.speedMultiplier * waveSpeedMult
        enemy.DamageMultiplier = rarityData.damageMultiplier * waveDamageMult
        enemy.AccuracyMultiplier = rarityData.accuracyMultiplier * waveAccuracyMult
        enemy.XPMultiplier = rarityData.xpMultiplier
        
        -- Enhanced stats
        enemy.BaseAccuracy = (enemy.ModelData.accuracy or 0.70) * enemy.AccuracyMultiplier
        enemy.ReactionTime = math.max(0.1, config.AISettings.ReactionTimeBase / waveAccuracyMult)
        enemy.SearchRadius = config.AISettings.SearchRadius
        enemy.ChaseRadius = config.AISettings.ChaseRadius
        enemy.AttackRadius = config.AISettings.AttackRadius
        
        print("[Arcade Spawner] Applied scaling: Health=" .. finalHealth .. 
              ", Speed=" .. string.format("%.2f", enemy.SpeedMultiplier) ..
              ", Accuracy=" .. string.format("%.2f", enemy.BaseAccuracy))
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- PROCEDURAL WEAPON LOADOUT SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Manager.ApplyWeaponLoadout(enemy, wave)
    if not IsValid(enemy) or not ArcadeSpawner.Config then return end
    
    -- Only apply to humanoid NPCs
    local humanoidClasses = {"npc_combine_s", "npc_metropolice", "npc_citizen", "npc_barney", "npc_alyx"}
    if not table.HasValue(humanoidClasses, enemy:GetClass()) then return end
    
    local config = ArcadeSpawner.Config
    local weaponSet = nil
    
    -- Find appropriate weapon set for wave
    for waveThreshold = wave, 1, -1 do
        if config.WeaponLoadouts[waveThreshold] then
            weaponSet = config.WeaponLoadouts[waveThreshold]
            break
        end
    end
    
    if not weaponSet then
        weaponSet = {"weapon_pistol"} -- Fallback
    end
    
    -- Randomly select weapon from set
    local selectedWeapon = table.Random(weaponSet)
    
    pcall(function()
        enemy:Give(selectedWeapon)
        enemy:SelectWeapon(selectedWeapon)
        
        -- Enhanced ammo for higher waves
        if wave >= 10 then
            enemy:SetKeyValue("additionalammo", "1000")
        end
        
        print("[Arcade Spawner] Armed enemy with " .. selectedWeapon .. " (Wave " .. wave .. ")")
    end)
end

function Manager.EnhanceEnemyCombat(enemy)
    if not IsValid(enemy) then return end
    
    pcall(function()
        -- Assign unique squad to prevent conflicts
        local squadID = "arcade_squad_" .. enemy:EntIndex()
        enemy:SetKeyValue("squadname", squadID)
        enemy:SetKeyValue("wakesquad", "1")
        enemy:SetKeyValue("sleepstate", "0")
        enemy:SetKeyValue("spawnflags", "256") -- Long range wake
        
        -- Enhanced reaction time
        local reactionTime = enemy.ReactionTime or 0.3
        enemy:SetKeyValue("reacttodamage", tostring(math.max(0.1, reactionTime)))
        
        -- FIXED: Safe movement speed setting with validation
        if enemy.SpeedMultiplier and enemy.SpeedMultiplier > 1.0 then
            local speed = 300 * enemy.SpeedMultiplier
            
            -- Check if enemy has SetMoveSpeed method (not all NPCs do)
            if enemy.SetMoveSpeed then
                local success = pcall(function()
                    enemy:SetMoveSpeed(speed)
                end)
                if success then
                    pcall(function() enemy:SetWalkSpeed(speed * 0.8) end)
                end
            end
            
            -- Alternative method for NPCs without SetMoveSpeed
            if not enemy.SetMoveSpeed or enemy:GetClass() == "npc_zombie" then
                pcall(function()
                    enemy:SetKeyValue("speed", tostring(speed))
                    enemy:SetKeyValue("walkspeed", tostring(speed * 0.8))
                end)
            end
        end
        
        -- Force player targeting
        enemy:AddRelationship("player D_HT 99")
        
        print("[Arcade Spawner] ⚡ Enhanced combat for " .. (enemy.RarityType or "Common") .. " enemy")
    end)
end

-- Comprehensive relationship management
function Manager.SetupEnemyRelationships(enemy)
    if not IsValid(enemy) then return end
    
    pcall(function()
        -- Clear all existing relationships first
        enemy:ClearEnemyMemory()
        
        -- Set primary target: ALL PLAYERS
        for _, ply in pairs(player.GetAll()) do
            if IsValid(ply) then
                enemy:AddEntityRelationship(ply, D_HT, 99)
            end
        end
        
        -- Make ALL arcade enemies neutral to each other
        for _, ent in pairs(ents.GetAll()) do
            if IsValid(ent) and ent.IsArcadeEnemy and ent ~= enemy then
                enemy:AddEntityRelationship(ent, D_NU, 0)
                ent:AddEntityRelationship(enemy, D_NU, 0)
            end
        end
        
        -- Set base relationships
        enemy:SetKeyValue("relationship", "player D_HT 99")
        enemy:SetKeyValue("relationship", "npc_* D_NU 0")
        
        -- Assign UNIQUE squad to prevent conflicts
        local uniqueSquad = "arcade_unique_" .. enemy:EntIndex() .. "_" .. math.random(1000, 9999)
        enemy:SetKeyValue("squadname", uniqueSquad)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED AI SYSTEM WITH SQUAD TACTICS
-- ═══════════════════════════════════════════════════════════════
function Manager.SetupAdvancedAI(enemy)
    if not IsValid(enemy) then return end
    
    pcall(function()
        -- Basic relationships
        enemy:AddRelationship("player D_HT 99")
        
        -- Advanced AI properties
        enemy.LastPlayerSeen = 0
        enemy.LastKnownPlayerPos = Vector()
        enemy.CoverPosition = nil
        enemy.FlankingTarget = nil
        enemy.SquadRole = Manager.AssignSquadRole(enemy)
        enemy.AimPredictionEnabled = ArcadeSpawner.Config.AISettings.AimPrediction
        enemy.LastPosition = enemy:GetPos()
        enemy.StuckCounter = 0
        enemy.NextPatrolUpdate = CurTime() + math.Rand(0.5, 1.0)
        
        -- Movement speed enhancement
        if enemy.SpeedMultiplier then
            local moveSpeed = 200 * enemy.SpeedMultiplier
            enemy:SetMoveSpeed(moveSpeed)
            enemy:SetWalkSpeed(moveSpeed * 0.7)
        end
        
        -- Start AI thinking
        timer.Simple(0.5, function()
            if IsValid(enemy) then
                Manager.StartAdvancedAI(enemy)
            end
        end)
    end)
end

function Manager.StartAdvancedAI(enemy)
    if not IsValid(enemy) then return end
    
    local thinkID = "ArcadeSpawner_AdvancedAI_" .. enemy:EntIndex()
    
    timer.Create(thinkID, 0.2, 0, function()
        if not IsValid(enemy) or not enemy:Alive() then
            timer.Remove(thinkID)
            return
        end
        
        Manager.AdvancedAIThink(enemy)
    end)
end

function Manager.AdvancedAIThink(enemy)
    if not IsValid(enemy) then return end
    
    local nearestPlayer = Manager.FindNearestPlayer(enemy)
    if not IsValid(nearestPlayer) then return end
    
    local enemyPos = enemy:GetPos()
    local playerPos = nearestPlayer:GetPos()
    local distance = enemyPos:Distance(playerPos)
    
    -- Check if enemy can see player
    local canSeePlayer = Manager.CanSeePlayer(enemy, nearestPlayer)
    
    if canSeePlayer then
        enemy.LastPlayerSeen = CurTime()
        enemy.LastKnownPlayerPos = playerPos
    end

    -- Proactively seek players if none spotted recently
    if not canSeePlayer and CurTime() - (enemy.LastPlayerSeen or 0) > 4 then
        enemy.LastPlayerSeen = CurTime()
        local seek = Manager.GetRandomPatrolPoint(enemy)
        if seek then Manager.MoveToPosition(enemy, seek) end
    end
    
    -- Squad tactics decision making
    local behavior = Manager.DetermineSquadBehavior(enemy, nearestPlayer, distance, canSeePlayer)
    Manager.ExecuteAIBehavior(enemy, behavior, nearestPlayer)

    -- Encourage wandering if idle for too long
    enemy.LastMoveCheck = enemy.LastMoveCheck or CurTime()
    enemy.LastCheckedPos = enemy.LastCheckedPos or enemyPos
    if enemy:GetPos():Distance(enemy.LastCheckedPos) < 10 then
        if CurTime() - enemy.LastMoveCheck > 1.5 then
            local patrol = Manager.GetRandomPatrolPoint(enemy)
            if patrol then Manager.MoveToPosition(enemy, patrol) end
            enemy.LastMoveCheck = CurTime()
        end
    else
        enemy.LastCheckedPos = enemy:GetPos()
        enemy.LastMoveCheck = CurTime()
    end
    
    -- Anti-stuck system
    Manager.CheckAndHandleStuck(enemy)
end

-- ═══════════════════════════════════════════════════════════════
-- SQUAD TACTICS & BEHAVIOR SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Manager.AssignSquadRole(enemy)
    local roles = {"assault", "flank", "support", "sniper"}
    local weights = {0.4, 0.25, 0.25, 0.1} -- Assault most common
    
    local roll = math.random()
    local cumulative = 0
    
    for i, weight in ipairs(weights) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return roles[i]
        end
    end
    
    return "assault"
end

function Manager.DetermineSquadBehavior(enemy, player, distance, canSeePlayer)
    local config = ArcadeSpawner.Config.AISettings
    
    -- Long-range engagement
    if distance > config.LongRangeEngagement and canSeePlayer then
        return "long_range_attack"
    end
    
    -- Close quarters combat
    if distance < config.AttackRadius then
        return "close_combat"
    end
    
    -- Squad role-based behavior
    if enemy.SquadRole == "flank" and math.random() < config.FlankingChance then
        return "flank"
    elseif enemy.SquadRole == "support" and math.random() < config.CoverSeekingChance then
        return "seek_cover"
    elseif distance < config.ChaseRadius then
        return "chase"
    elseif enemy.LastKnownPlayerPos and CurTime() - enemy.LastPlayerSeen < 5 then
        if enemy.LastKnownPlayerPos == vector_origin then
            return "patrol"
        end
        return "search"
    else
        return "patrol"
    end
end

function Manager.ExecuteAIBehavior(enemy, behavior, player)
    if not IsValid(enemy) or not IsValid(player) then return end
    
    pcall(function()
        if behavior == "long_range_attack" then
            -- Enhanced long-range combat
            enemy:SetEnemy(player)
            enemy:SetSchedule(SCHED_RANGE_ATTACK1)
            Manager.EnhanceAiming(enemy, player)
            
        elseif behavior == "close_combat" then
            enemy:SetEnemy(player)
            enemy:SetSchedule(SCHED_MELEE_ATTACK1)
            
        elseif behavior == "flank" then
            local flankPos = Manager.CalculateFlankingPosition(enemy, player)
            if flankPos then
                Manager.MoveToPosition(enemy, flankPos)
                enemy:SetEnemy(player)
            end
            
        elseif behavior == "seek_cover" then
            local coverPos = Manager.FindCoverPosition(enemy, player)
            if coverPos then
                Manager.MoveToPosition(enemy, coverPos)
            end
            
        elseif behavior == "chase" then
            enemy:SetEnemy(player)
            enemy:SetSchedule(SCHED_CHASE_ENEMY)
            
        elseif behavior == "search" then
            if enemy.LastKnownPlayerPos and enemy.LastKnownPlayerPos ~= vector_origin then
                Manager.MoveToPosition(enemy, enemy.LastKnownPlayerPos)
            else
                enemy:SetSchedule(SCHED_IDLE_WANDER)
            end
        elseif behavior == "patrol" then
            if not enemy.NextPatrolUpdate or CurTime() >= enemy.NextPatrolUpdate then
                local patrolPos = Manager.GetRandomPatrolPoint(enemy)
                if patrolPos then
                    Manager.MoveToPosition(enemy, patrolPos)
                end
                enemy.NextPatrolUpdate = CurTime() + 3
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED AIMING & ACCURACY SYSTEM
-- ═══════════════════════════════════════════════════════════════
function Manager.EnhanceAiming(enemy, player)
    if not IsValid(enemy) or not IsValid(player) then return end
    
    -- Calculate aim prediction
    if enemy.AimPredictionEnabled then
        local playerVel = player:GetVelocity()
        local distance = enemy:GetPos():Distance(player:GetPos())
        local travelTime = distance / 1000 -- Assume projectile speed
        
        local predictedPos = player:GetPos() + (playerVel * travelTime)
        
        -- Apply accuracy modifier
        local accuracy = enemy.BaseAccuracy or 0.70
        local aimOffset = VectorRand() * (100 * (1 - accuracy))
        local finalAimPos = predictedPos + aimOffset
        
        -- Set aim target
        enemy:SetTarget(finalAimPos)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
function Manager.CanSeePlayer(enemy, player)
    if not IsValid(enemy) or not IsValid(player) then return false end
    
    local trace = util.TraceLine({
        start = enemy:GetShootPos(),
        endpos = player:GetShootPos(),
        filter = {enemy, player},
        mask = MASK_SHOT
    })
    
    return not trace.Hit or trace.Entity == player
end

function Manager.FindNearestPlayer(enemy)
    if not IsValid(enemy) then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local dist = enemy:GetPos():Distance(ply:GetPos())
            if dist < nearestDist then
                nearestDist = dist
                nearest = ply
            end
        end
    end
    
    return nearest
end

function Manager.SelectOptimalModel(wave, attempt)
    if #Manager.ValidatedModels == 0 then return nil end
    
    -- Prefer military units for higher waves
    if wave >= 15 and attempt <= 2 then
        for _, model in ipairs(Manager.ValidatedModels) do
            if model.category == "military" or model.category == "elite" then
                return model
            end
        end
    end
    
    return table.Random(Manager.ValidatedModels)
end

function Manager.ValidateSpawnPosition(pos, attempt)
    local searchRadius = 80 + (attempt * 40)
    local maxAttempts = 12
    
    -- Test original position first with enhanced checks
    if Manager.IsPositionValidAdvanced(pos) then
        return pos
    end
    
    -- Systematic search pattern
    for radius = searchRadius, searchRadius * 3, searchRadius do
        for angle = 0, 315, 45 do
            local rad = math.rad(angle)
            local offset = Vector(
                math.cos(rad) * radius,
                math.sin(rad) * radius,
                0
            )
            
            local testPos = pos + offset
            
            -- Try multiple heights
            for zOffset = 0, 150, 30 do
                local heightAdjustedPos = Vector(testPos.x, testPos.y, testPos.z + zOffset)
                
                if Manager.IsPositionValidAdvanced(heightAdjustedPos) then
                    return heightAdjustedPos
                end
            end
        end
    end
    
    print("[Arcade Spawner] ⚠️ Could not find valid spawn position after " .. maxAttempts .. " attempts")
    return nil
end

function Manager.IsPositionValidAdvanced(pos)
    if not pos or not isvector(pos) then return false end
    
    -- Enhanced collision checking
    local hullTrace = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if hullTrace.StartSolid or hullTrace.AllSolid then return false end
    
    -- Ground validation with multiple attempts
    local groundFound = false
    local finalPos = pos
    
    for i = 1, 5 do
        local startHeight = pos.z + (i * 20)
        local groundTrace = util.TraceLine({
            start = Vector(pos.x, pos.y, startHeight),
            endpos = Vector(pos.x, pos.y, pos.z - 300),
            mask = MASK_SOLID_BRUSHONLY
        })
        
        if groundTrace.Hit then
            finalPos = groundTrace.HitPos + Vector(0, 0, 18)
            groundFound = true
            break
        end
    end
    
    if not groundFound then return false end
    
    -- Final validation at ground level
    local finalTrace = util.TraceHull({
        start = finalPos,
        endpos = finalPos + Vector(0, 0, 1),
        mins = Vector(-20, -20, 0),
        maxs = Vector(20, 20, 72),
        mask = MASK_SOLID
    })
    
    return not finalTrace.StartSolid
end

-- Simple alias for general validity checks
Manager.IsPositionValid = Manager.IsPositionValidAdvanced

function Manager.DetermineRarity(wave)
    local roll = math.random(1, 100)
    local waveBonus = math.min(wave * 2, 30) -- Increase rare spawns with wave
    roll = math.max(roll - waveBonus, 1)
    
    if roll <= 2 then return "Mythic"
    elseif roll <= 8 then return "Legendary"
    elseif roll <= 20 then return "Epic"
    elseif roll <= 40 then return "Rare"
    elseif roll <= 65 then return "Uncommon"
    else return "Common" end
end

-- Enhanced position calculation functions
function Manager.CalculateFlankingPosition(enemy, player)
    local playerPos = player:GetPos()
    local enemyPos = enemy:GetPos()
    
    -- Calculate perpendicular flanking positions
    local dirToPlayer = (playerPos - enemyPos):GetNormalized()
    local rightFlank = enemyPos + dirToPlayer:Cross(Vector(0, 0, 1)) * 300
    local leftFlank = enemyPos + dirToPlayer:Cross(Vector(0, 0, -1)) * 300
    
    -- Choose best flanking position
    if Manager.IsPositionValid(rightFlank) then
        return rightFlank
    elseif Manager.IsPositionValid(leftFlank) then
        return leftFlank
    end
    
    return nil
end

function Manager.FindCoverPosition(enemy, player)
    local enemyPos = enemy:GetPos()
    local playerPos = player:GetPos()
    
    -- Find position behind cover
    local dirFromPlayer = (enemyPos - playerPos):GetNormalized()
    local coverPos = enemyPos + dirFromPlayer * 200
    
    if Manager.IsPositionValid(coverPos) then
        return coverPos
    end
    
    return nil
end

function Manager.MoveToPosition(enemy, targetPos)
    if not IsValid(enemy) or not targetPos then return end
    
    pcall(function()
        enemy:SetLastPosition(targetPos)
        enemy:SetSchedule(SCHED_FORCED_GO_RUN)
    end)
end

function Manager.GetRandomPatrolPoint(enemy)
    local players = player.GetAll()
    if #players > 0 then
        local ply = table.Random(players)
        local navs = navmesh.Find(ply:GetPos(), 2500, 20, 200, 6000)

        if navs and #navs > 0 then
            local area = table.Random(navs)
            return area:GetRandomPoint()
        end
        local offset = VectorRand() * math.random(600, 1400)

        local pos = ply:GetPos() + offset
        if Manager.IsPositionValid(pos) then return pos end
    end

    local areas = navmesh.GetAllNavAreas()
    if areas and #areas > 0 then
        local area = table.Random(areas)
        return area:GetCenter()
    end

    local offset = Vector(math.random(-800,800), math.random(-800,800), 0)
  
    return enemy:GetPos() + offset
end

function Manager.CheckAndHandleStuck(enemy)
    if not IsValid(enemy) then return end
    
    local currentPos = enemy:GetPos()
    
    if currentPos:Distance(enemy.LastPosition) < 30 then
        enemy.StuckCounter = enemy.StuckCounter + 1
        
        if enemy.StuckCounter >= 10 then -- Stuck for 2 seconds
            Manager.UnstuckEnemy(enemy)
            enemy.StuckCounter = 0
        end
    else
        enemy.StuckCounter = 0
    end
    
    enemy.LastPosition = currentPos
end

function Manager.UnstuckEnemy(enemy)
    if not IsValid(enemy) then return end
    
    local pos = enemy:GetPos()
    local attempts = {
        pos + Vector(120, 0, 0),
        pos + Vector(-120, 0, 0),
        pos + Vector(0, 120, 0),
        pos + Vector(0, -120, 0),
        pos + Vector(120, 120, 50),
        pos + Vector(-120, -120, 50)
    }
    
    for _, testPos in ipairs(attempts) do
        if Manager.IsPositionValid(testPos) then
            enemy:SetPos(testPos)
            print("[Arcade Spawner] Unstuck enemy")
            break
        end
    end
end

-- Clear all enemies
function Manager.ClearAllEnemies()
    local cleared = 0
    for _, ent in pairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsArcadeEnemy then
            local entIndex = ent:EntIndex()
            timer.Remove("ArcadeSpawner_AdvancedAI_" .. entIndex)
            ent:Remove()
            cleared = cleared + 1
        end
    end
    
    Manager.ActiveEnemies = {}
    Manager.EnemyStats = {}
    
    return cleared
end

-- Initialize on map load
hook.Add("InitPostEntity", "ArcadeSpawner_EnemyManager", function()
    timer.Simple(2, function()
        Manager.BuildSafeModelCache()
    end)
end)

print("[Arcade Spawner] 🤖 Advanced Enemy Manager with Workshop Validation v4.1 loaded!")