--[[
    Arcade Anomaly: Model Registry
    
    Manages workshop model discovery, validation, and assignment.
    ANY installed model can be used for ANY archetype.
--]]

AA.ModelRegistry = AA.ModelRegistry or {}
AA.ModelRegistry.Models = {}
AA.ModelRegistry.AllModels = {} -- Flat list of all valid models
AA.ModelRegistry.Pools = {}

-- Initialize pools
function AA.ModelRegistry:Initialize()
    -- Create pools for each archetype
    for archetype, _ in pairs(AA.Types.ArchetypeNames) do
        self.Pools[archetype] = {}
    end
    
    -- Register fallback models (default HL2 models that always work)
    self:RegisterFallbackModels()
    
    -- Note: Discovery runs later via InitPostEntity hook
    -- Don't run discovery here - game isn't ready yet
    
    self.Initialized = true
    print("[AA ModelRegistry] Initialized with " .. table.Count(self.Models) .. " fallback models")
end

function AA.ModelRegistry:RegisterFallbackModels()
    -- PRIORITY ORDER: Workshop > Mounted Games > Fallback HL2
    -- These are built-in HL2 models that always work as ultimate fallback
    
    local vanillaModels = {
        -- GROUP 1: High Quality Character Models (Preferred for fresh installs)
        -- HL2 Citizens - most reliable with good animations
        { path = "models/Humans/Group01/male_01.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_02.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_03.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_04.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_05.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_06.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_07.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_08.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/male_09.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_01.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_02.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_03.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_04.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_06.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        { path = "models/Humans/Group01/female_07.mdl", tags = {"humanoid", "citizen"}, priority = 100 },
        
        -- Rebels (Group02) - more variety
        { path = "models/Humans/Group02/male_02.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        { path = "models/Humans/Group02/male_04.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        { path = "models/Humans/Group02/male_06.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        { path = "models/Humans/Group02/male_08.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        { path = "models/Humans/Group02/female_02.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        { path = "models/Humans/Group02/female_04.mdl", tags = {"humanoid", "rebel"}, priority = 95 },
        
        -- Combine Soldiers - excellent for military archetypes
        { path = "models/combine_soldier.mdl", tags = {"soldier", "combine", "military"}, priority = 90 },
        { path = "models/combine_soldier_prisonguard.mdl", tags = {"soldier", "combine", "military"}, priority = 90 },
        { path = "models/combine_super_soldier.mdl", tags = {"soldier", "combine", "military", "elite"}, priority = 85 },
        { path = "models/police.mdl", tags = {"soldier", "police", "military"}, priority = 90 },
        
        -- GROUP 2: Zombie Types (Good for undead archetypes)
        { path = "models/zombie/classic.mdl", tags = {"undead", "zombie", "brute"}, priority = 80 },
        { path = "models/zombie/fast_zombie.mdl", tags = {"undead", "zombie", "fast", "rusher"}, priority = 80 },
        { path = "models/zombie/poison.mdl", tags = {"undead", "zombie", "elite"}, priority = 75 },
        { path = "models/zombie/zombie_soldier.mdl", tags = {"undead", "zombie", "soldier"}, priority = 80 },
        
        -- GROUP 3: Creatures (Unique types)
        { path = "models/antlion.mdl", tags = {"creature", "alien", "fast"}, priority = 70 },
        { path = "models/antlion_guard.mdl", tags = {"creature", "alien", "large", "elite", "brute"}, scale = 0.7, priority = 65 },
        
        -- GROUP 4: CS:S Models (If mounted - better than HL2 for variety)
        { path = "models/player/ct_gign.mdl", tags = {"humanoid", "soldier", "military"}, priority = 110 },
        { path = "models/player/ct_gsg9.mdl", tags = {"humanoid", "soldier", "military"}, priority = 110 },
        { path = "models/player/ct_sas.mdl", tags = {"humanoid", "soldier", "military"}, priority = 110 },
        { path = "models/player/ct_urban.mdl", tags = {"humanoid", "soldier", "military"}, priority = 110 },
        { path = "models/player/t_arctic.mdl", tags = {"humanoid", "terrorist", "military"}, priority = 110 },
        { path = "models/player/t_guerilla.mdl", tags = {"humanoid", "terrorist", "military"}, priority = 110 },
        { path = "models/player/t_leet.mdl", tags = {"humanoid", "terrorist", "military"}, priority = 110 },
        { path = "models/player/t_phoenix.mdl", tags = {"humanoid", "terrorist", "military"}, priority = 110 },
        
        -- GROUP 5: Special/NPC Models
        { path = "models/alyx.mdl", tags = {"humanoid", "rebel", "elite"}, priority = 60 },
        { path = "models/barney.mdl", tags = {"humanoid", "soldier"}, priority = 60 },
        { path = "models/Eli.mdl", tags = {"humanoid", "citizen"}, priority = 60 },
        { path = "models/mossman.mdl", tags = {"humanoid", "citizen"}, priority = 60 },
        { path = "models/Kleiner.mdl", tags = {"humanoid", "scientist"}, priority = 60 },
        { path = "models/Monk.mdl", tags = {"humanoid", "rebel"}, priority = 60 },
        
        -- GROUP 6: Skeleton for visual variety
        { path = "models/player/skeleton.mdl", tags = {"undead", "skeleton"}, priority = 50 },
    }
    
    -- Register valid models only
    local registeredCount = 0
    
    for _, data in ipairs(vanillaModels) do
        -- Check if model actually exists
        if util.IsValidModel(data.path) then
            self:RegisterModel(data.path, {
                tags = data.tags,
                scale = data.scale,
                isFallback = false, -- These are proper vanilla models, not fallbacks
                isVanilla = true,
                approved = true,
                priority = data.priority or 50,
            })
            registeredCount = registeredCount + 1
        end
    end
    
    -- Register ultimate fallback only if nothing else worked
    if registeredCount == 0 then
        print("[AA ModelRegistry] WARNING: No vanilla models found! Using ultimate fallback.")
        self:RegisterModel("models/Humans/Group01/male_07.mdl", {
            tags = {"humanoid", "fallback"},
            isFallback = true,
            approved = true,
            priority = 1,
        })
    else
        print(string.format("[AA ModelRegistry] Registered %d vanilla HL2/CS:S models", registeredCount))
    end
end

function AA.ModelRegistry:DiscoverInstalledModels()
    -- This function is overridden by sv_model_discovery.lua
    -- It runs after InitPostEntity when the game is fully ready
    if AA.ModelDiscovery and AA.ModelDiscovery.DiscoverAll then
        AA.ModelDiscovery:DiscoverAll()
    else
        print("[AA ModelRegistry] ModelDiscovery module not loaded yet")
    end
end

function AA.ModelRegistry:RegisterModel(path, data)
    if not path or path == "" then return false end
    
    -- Check if model file exists
    if not util.IsValidModel(path) then
        return false
    end
    
    local modelData = {
        path = path,
        tags = data.tags or {},
        scale = data.scale or 1.0,
        isFallback = data.isFallback or false,
        approved = data.approved or false,
        blacklisted = data.blacklisted or false,
        validationResult = data.validationResult or AA.Types.ValidationResult.VALID,
        lastUsed = 0,
        useCount = 0,
    }
    
    self.Models[path] = modelData
    table.insert(self.AllModels, modelData)
    
    -- Add to all archetype pools (any model can be any archetype)
    for archetype, _ in pairs(AA.Types.ArchetypeNames) do
        table.insert(self.Pools[archetype], path)
    end
    
    return true
end

-- Check if a model is a vanilla HL2/CS:S model (boring)
function AA.ModelRegistry:IsVanillaModel(path)
    local lower = string.lower(path)
    
    -- HL2 human groups (group01, group02, etc.)
    if string.find(lower, "humans/group") then return true end
    if string.find(lower, "humans/enhanced") then return true end
    
    -- CS:S/HL2 player models in group folders
    if string.find(lower, "player/group0") then return true end
    if string.find(lower, "player/group03m") then return true end
    
    -- CS:S player models (arctic, gign, etc.)
    local cssModels = {
        "arctic", "gasmask", "guerilla", "leet", "phoenix", "riot",
        "gign", "gsg9", "sas", "urban", "swat",
        "dod_american", "dod_german",
        "corpse", "charple", "soldier_stripped",
        "hostage", "skeleton"
    }
    for _, name in ipairs(cssModels) do
        if string.find(lower, "/player/" .. name) then return true end
    end
    
    -- HL2 specific named player models
    local hl2Players = {
        "alyx", "breen", "eli", "gman", "gman_high",
        "kleiner", "monk", "mossman", "odessa", "p2_chell",
        "police", "police_fem", "magnusson", "barney",
        "zombie_classic", "zombie_fast", "zombie_poison",
        "skeleton", "chell"
    }
    for _, name in ipairs(hl2Players) do
        if string.find(lower, "/player/" .. name) then return true end
    end
    
    -- CS:S hostages
    if string.find(lower, "hostage") then return true end
    
    -- Combine/Zombie vanilla models
    if string.find(lower, "models/combine") and not string.find(lower, "models/combine_") then return true end
    if string.find(lower, "models/zombie/") then return true end
    
    return false
end

function AA.ModelRegistry:GetModelForArchetype(archetype, isElite)
    -- Build list of valid models by category
    local workshop = {}      -- User's workshop addons (highest priority)
    local vanilla = {}       -- HL2/CS:S vanilla models (medium priority)
    local fallbacks = {}     -- Absolute fallback models (lowest priority)
    
    for path, model in pairs(self.Models) do
        if model.approved and not model.blacklisted then
            if model.isFallback then
                table.insert(fallbacks, model)
            elseif model.isVanilla then
                table.insert(vanilla, model)
            else
                table.insert(workshop, model)
            end
        end
    end
    
    print(string.format("[AA ModelSelect] Workshop: %d, Vanilla: %d, Fallbacks: %d", 
        #workshop, #vanilla, #fallbacks))
    
    local selected = nil
    local source = ""
    
    -- PRIORITY 1: Workshop models (if we have enough variety)
    if #workshop >= 3 then
        -- Pick random workshop model
        selected = workshop[math.random(1, #workshop)]
        source = "WORKSHOP"
        
    -- PRIORITY 2: Mix of workshop and vanilla (if some workshop exists)
    elseif #workshop > 0 and #vanilla > 0 then
        -- 70% chance to pick workshop, 30% vanilla
        if math.random() < 0.7 then
            selected = workshop[math.random(1, #workshop)]
            source = "WORKSHOP"
        else
            selected = vanilla[math.random(1, #vanilla)]
            source = "VANILLA"
        end
        
    -- PRIORITY 3: Workshop only (limited but exists)
    elseif #workshop > 0 then
        selected = workshop[math.random(1, #workshop)]
        source = "WORKSHOP"
        
    -- PRIORITY 4: Vanilla HL2/CS:S models (fresh install scenario)
    elseif #vanilla > 0 then
        selected = vanilla[math.random(1, #vanilla)]
        source = "VANILLA"
        
    -- PRIORITY 5: Ultimate fallback (emergency)
    elseif #fallbacks > 0 then
        selected = fallbacks[math.random(1, #fallbacks)]
        source = "FALLBACK"
        
    -- PRIORITY 6: Create emergency fallback
    else
        print("[AA ModelSelect] NO MODELS AVAILABLE! Using emergency fallback.")
        return self:GetUltimateFallback()
    end
    
    print(string.format("[AA ModelSelect] Using %s: %s", source, selected.path))
    
    -- Update usage stats
    selected.lastUsed = CurTime()
    selected.useCount = (selected.useCount or 0) + 1
    
    return selected
end

function AA.ModelRegistry:GetUltimateFallback()
    return {
        path = "models/Humans/Group01/male_07.mdl",
        archetypes = { AA.Types.Archetype.CHASER },
        tags = { "humanoid", "fallback" },
        scale = 1.0,
        isFallback = true,
        approved = true,
    }
end

function AA.ModelRegistry:GetModelsByTag(tag)
    local result = {}
    for path, data in pairs(self.Models) do
        local hasTag = false
        for _, t in ipairs(data.tags or {}) do
            if t == tag then
                hasTag = true
                break
            end
        end
        if hasTag then
            table.insert(result, data)
        end
    end
    return result
end

function AA.ModelRegistry:BlacklistModel(path)
    if self.Models[path] then
        self.Models[path].blacklisted = true
        self.Models[path].approved = false
        
        -- Update cache
        if AA.ModelCache then
            AA.ModelCache:Blacklist(path)
        end
        
        return true
    end
    return false
end

function AA.ModelRegistry:ApproveModel(path)
    if self.Models[path] then
        self.Models[path].approved = true
        self.Models[path].blacklisted = false
        self.Models[path].validationResult = AA.Types.ValidationResult.VALID
        
        -- Update cache
        if AA.ModelCache then
            AA.ModelCache:Approve(path)
        end
        
        return true
    end
    return false
end

-- Admin commands
concommand.Add("aa_model_add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_model_add <model_path>")
        return
    end
    
    if AA.ModelRegistry:RegisterModel(path, {
        tags = { "custom" },
        approved = true,
    }) then
        print("[AA] Added model: " .. path)
    else
        print("[AA] Failed to add model (may not exist): " .. path)
    end
end)

concommand.Add("aa_model_blacklist", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_model_blacklist <model_path>")
        return
    end
    
    AA.ModelRegistry:BlacklistModel(path)
    print("[AA] Blacklisted model: " .. path)
end)

concommand.Add("aa_model_list", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("[AA] Registered models:")
    for path, data in pairs(AA.ModelRegistry.Models) do
        local status = data.approved and "[APPROVED]" or "[PENDING]"
        if data.blacklisted then status = "[BLACKLISTED]" end
        if data.isFallback then status = "[FALLBACK]" end
        
        print(string.format("  %s %s (used %d times)", status, path, data.useCount))
    end
end)

-- Initialize on startup
hook.Add("Initialize", "AA_ModelRegistry_Init", function()
    AA.ModelRegistry:Initialize()
end)

-- Test if a model has proper NPC animations
concommand.Add("aa_test_model_anims", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_test_model_anims <model_path>")
        return
    end
    
    if not util.IsValidModel(path) then
        print("[AA] Invalid model: " .. path)
        return
    end
    
    print("[AA] Testing animations for: " .. path)
    
    -- Create test entity
    local ent = ents.Create("prop_dynamic")
    if not IsValid(ent) then
        print("[AA] Failed to create test entity")
        return
    end
    
    ent:SetModel(path)
    
    -- Check for required sequences
    local required = {"idle_all", "idle", "run_all", "run", "walk_all", "walk"}
    local found = {}
    
    for _, seq in ipairs(required) do
        local id = ent:LookupSequence(seq)
        if id and id > 0 then
            table.insert(found, seq)
        end
    end
    
    ent:Remove()
    
    print("[AA] Found " .. #found .. "/" .. #required .. " sequences")
    print("[AA] Available: " .. table.concat(found, ", "))
    
    if #found < 2 then
        print("[AA] WARNING: Model may not work properly as NPC!")
    else
        print("[AA] Model should work as NPC")
    end
end, nil, "Test if a model has NPC animations")

-- Auto-run discovery after game is fully loaded
hook.Add("InitPostEntity", "AA_ModelDiscovery", function()
    print("[AA ModelRegistry] InitPostEntity - Starting model discovery...")
    AA.ModelRegistry:DiscoverInstalledModels()
end)
