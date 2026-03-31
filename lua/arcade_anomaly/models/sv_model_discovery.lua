--[[
    Arcade Anomaly: Military-Grade Workshop Model Discovery
    
    Comprehensive model scanning system that finds workshop models
    from all possible mount points and sources.
--]]

AA.ModelDiscovery = AA.ModelDiscovery or {}

-- Configuration
AA.ModelDiscovery.Config = {
    MaxModels = 1000,             -- Absolute max to prevent overflow
    MaxScanTime = 30,             -- Seconds before giving up
    ValidateModels = true,        -- Check if models actually load
    IncludeWorkshop = true,       -- Scan workshop addons
    IncludeLegacyAddons = true,   -- Scan legacy addons folder
    IncludeMountedGames = true,   -- Scan mounted games (HL2, EP1, etc)
    RecursiveDepth = 3,           -- How deep to scan directories
    LogLevel = 2,                 -- 0=none, 1=errors, 2=info, 3=verbose
}

-- SIMPLIFIED: Single pattern to find all humanoid models
AA.ModelDiscovery.Patterns = {
    {
        name = "All Humanoids",
        paths = {
            -- Player models (most workshop content)
            "models/player/",
            "models/players/",
            "models/characters/",
            "models/npcs/",
            -- Humanoid NPCs
            "models/humans/",
            "models/citizen/",
            -- Generic catch-alls
            "models/custom/",
            "models/workshop/",
        },
        tags = {"humanoid"},
        priority = 10
    },
}

-- Common model name patterns for classification
AA.ModelDiscovery.NamePatterns = {
    { pattern = "soldier", tags = {"soldier", "military"} },
    { pattern = "combine", tags = {"combine", "soldier"} },
    { pattern = "police", tags = {"police", "military"} },
    { pattern = "swat", tags = {"swat", "soldier"} },
    { pattern = "army", tags = {"army", "soldier"} },
    { pattern = "military", tags = {"military", "soldier"} },
    { pattern = "zombie", tags = {"undead", "zombie"} },
    { pattern = "zombine", tags = {"undead", "zombie", "combine"} },
    { pattern = "headcrab", tags = {"creature", "small"} },
    { pattern = "antlion", tags = {"creature", "alien"} },
    { pattern = "vortigaunt", tags = {"creature", "alien"} },
    { pattern = "strider", tags = {"machine", "large"} },
    { pattern = "synth", tags = {"machine", "creature"} },
    { pattern = "android", tags = {"machine", "humanoid"} },
    { pattern = "robot", tags = {"machine", "robot"} },
    { pattern = "mech", tags = {"machine", "large"} },
    { pattern = "drone", tags = {"machine", "small"} },
    { pattern = "turret", tags = {"machine"} },
    { pattern = "stalker", tags = {"hostile", "cyborg"} },
    { pattern = "hostage", tags = {"civilian"} },
    { pattern = "scientist", tags = {"civilian", "humanoid"} },
    { pattern = "citizen", tags = {"civilian", "humanoid"} },
    { pattern = "rebel", tags = {"rebel", "soldier"} },
    { pattern = "refugee", tags = {"civilian", "humanoid"} },
    { pattern = "medic", tags = {"medic", "humanoid"} },
    { pattern = "engineer", tags = {"engineer", "humanoid"} },
}

-- RELAXED: Only filter obvious non-character models
AA.ModelDiscovery.BlacklistPatterns = {
    "debris",
    "gib",
    "chunk",
    "shard",
    "wreckage",
}

-- Main discovery function - FIND ALL MODELS
function AA.ModelDiscovery:DiscoverAll()
    if not AA.ModelRegistry then return 0 end
    
    -- Prevent concurrent discovery runs
    if self.IsDiscovering then
        print("[AA Discovery] Discovery already in progress, skipping...")
        return 0
    end
    
    self.IsDiscovering = true
    
    local config = self.Config
    local startTime = SysTime()
    local foundCount = 0
    local totalSteps = 4 -- Number of scan stages
    local currentStep = 0
    
    print("[AA Discovery] Finding ALL models (animations optional)...")
    
    -- Notify clients that discovery is starting
    if AA.Net and AA.Net.StartLoading then
        AA.Net.StartLoading(nil, "DISCOVERING MODELS", "Scanning for workshop content...", false)
    end
    
    -- Scan all humanoid paths
    local paths = {
        "models/player/",
        "models/humans/",
        "models/characters/",
        "models/npcs/",
    }
    
    currentStep = currentStep + 1
    for i, path in ipairs(paths) do
        if SysTime() - startTime > config.MaxScanTime then break end
        
        -- Update progress
        local progress = ((currentStep - 1) / totalSteps + (i / #paths) * (1 / totalSteps)) * 100
        if AA.Net and AA.Net.UpdateLoading then
            AA.Net.UpdateLoading(nil, progress, "Scanning " .. path .. "...", string.format("STAGE %d/%d", currentStep, totalSteps))
        end
        
        local ok, count = pcall(function()
            return self:SimplePathScan(path, config)
        end)
        
        if ok and count and count > 0 then
            foundCount = foundCount + count
            print("[AA Discovery]   " .. path .. ": " .. count)
        end
    end
    
    -- Scan player subdirectories
    currentStep = currentStep + 1
    if foundCount < config.MaxModels then
        if AA.Net and AA.Net.UpdateLoading then
            AA.Net.UpdateLoading(nil, (currentStep / totalSteps) * 100, "Scanning player models...", string.format("STAGE %d/%d", currentStep, totalSteps))
        end
        
        local ok, count = pcall(function()
            return self:ScanPlayerSubdirs(config)
        end)
        if ok and count then
            foundCount = foundCount + count
        end
    end
    
    -- Scan workshop addons directly
    currentStep = currentStep + 1
    if foundCount < config.MaxModels then
        if AA.Net and AA.Net.UpdateLoading then
            AA.Net.UpdateLoading(nil, (currentStep / totalSteps) * 100, "Scanning workshop addons...", string.format("STAGE %d/%d", currentStep, totalSteps))
        end
        
        local ok, count = pcall(function()
            return self:ScanWorkshopAddonsDirect(config)
        end)
        if ok and count then
            foundCount = foundCount + count
        end
    end
    
    -- Final stage - building cache
    currentStep = currentStep + 1
    if AA.Net and AA.Net.UpdateLoading then
        AA.Net.UpdateLoading(nil, 95, "Building model cache...", string.format("STAGE %d/%d", currentStep, totalSteps))
    end
    
    print("[AA Discovery] Total found: " .. foundCount)
    
    -- Complete loading
    if AA.Net and AA.Net.CompleteLoading then
        AA.Net.CompleteLoading(nil)
    end
    
    -- Show toast notification
    if AA.Net and AA.Net.ShowToast then
        AA.Net.ShowToast(nil, string.format("Discovered %d workshop models!", foundCount), "SUCCESS", 5)
    end
    
    self.IsDiscovering = false
    return foundCount
end

-- Scan workshop addons from their physical location
function AA.ModelDiscovery:ScanWorkshopAddonsDirect(config)
    local count = 0
    print("[AA Discovery] Scanning workshop addons...")
    
    -- Workshop content path
    local workshopBase = "workshop/content/4000/"
    
    -- Get list of workshop addon IDs
    local _, addonIds = file.Find(workshopBase .. "*", "GAME")
    if not addonIds or #addonIds == 0 then
        print("[AA Discovery] No workshop addons found")
        return 0
    end
    
    print("[AA Discovery] Found " .. #addonIds .. " workshop addons")
    
    for _, addonId in ipairs(addonIds) do
        if count >= config.MaxModels then break end
        
        -- Try to find .mdl files in this addon
        local addonPath = workshopBase .. addonId .. "/"
        local files = file.Find(addonPath .. "*.mdl", "GAME")
        
        if files and #files > 0 then
            local addonCount = 0
            for _, f in ipairs(files) do
                if count >= config.MaxModels then break end
                
                local fullPath = addonPath .. f
                if util.IsValidModel(fullPath) then
                    if self:RegisterSimple(fullPath, config) then
                        count = count + 1
                        addonCount = addonCount + 1
                    end
                end
            end
            if addonCount > 0 then
                print("[AA Discovery]   Addon " .. addonId .. ": " .. addonCount .. " models")
            end
        end
        
        -- Also check for models/ subdirectory
        if count < config.MaxModels then
            local modelsPath = addonPath .. "models/"
            local subCount = self:ScanWorkshopModelsRecursive(modelsPath, config, 0)
            if subCount > 0 then
                count = count + subCount
                print("[AA Discovery]   Addon " .. addonId .. " models/: " .. subCount .. " models")
            end
        end
    end
    
    return count
end

-- Recursive scan of workshop addon models directory
function AA.ModelDiscovery:ScanWorkshopModelsRecursive(basePath, config, depth)
    if depth > 2 then return 0 end
    
    local count = 0
    local files, dirs = file.Find(basePath .. "*", "GAME")
    
    -- Scan .mdl files in this directory
    if files then
        for _, f in ipairs(files) do
            if count >= config.MaxModels then break end
            
            if string.sub(f, -4) == ".mdl" then
                local fullPath = basePath .. f
                if not self:IsBlacklisted(fullPath) and util.IsValidModel(fullPath) then
                    if self:RegisterSimple(fullPath, config) then
                        count = count + 1
                    end
                end
            end
        end
    end
    
    -- Recurse into subdirectories
    if dirs then
        for _, dir in ipairs(dirs) do
            if count >= config.MaxModels then break end
            
            local subPath = basePath .. dir .. "/"
            count = count + self:ScanWorkshopModelsRecursive(subPath, config, depth + 1)
        end
    end
    
    return count
end

-- ACCEPT ALL MODELS - animation handling is done at runtime
-- Workshop player models will appear static or T-posed but will work
function AA.ModelDiscovery:HasNPCAnimations(modelPath)
    return true -- Accept all models
end

-- Simple path scan - just find .mdl files
function AA.ModelDiscovery:SimplePathScan(basePath, config)
    local count = 0
    
    -- Scan this directory
    local files = file.Find(basePath .. "*.mdl", "GAME")
    if files then
        for _, f in ipairs(files) do
            if count >= config.MaxModels then break end
            
            local fullPath = basePath .. f
            if not self:IsBlacklisted(fullPath) then
                if not AA.ModelRegistry.Models[fullPath] and util.IsValidModel(fullPath) then
                    -- Simple registration - all get "humanoid" tag
                    if self:RegisterSimple(fullPath, config) then
                        count = count + 1
                    end
                end
            end
        end
    end
    
    -- Scan immediate subdirectories (one level only)
    local _, dirs = file.Find(basePath .. "*", "GAME")
    if dirs then
        for _, dir in ipairs(dirs) do
            if count >= config.MaxModels then break end
            
            local subPath = basePath .. dir .. "/"
            local subFiles = file.Find(subPath .. "*.mdl", "GAME")
            if subFiles then
                for _, f in ipairs(subFiles) do
                    if count >= config.MaxModels then break end
                    
                    local fullPath = subPath .. f
                    if not self:IsBlacklisted(fullPath) then
                        if not AA.ModelRegistry.Models[fullPath] and util.IsValidModel(fullPath) then
                            if self:RegisterSimple(fullPath, config) then
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end
    
    return count
end

-- Scan player/ subdirectories
function AA.ModelDiscovery:ScanPlayerSubdirs(config)
    local count = 0
    
    local _, dirs = file.Find("models/player/*", "GAME")
    if not dirs then return 0 end
    
    for _, dir in ipairs(dirs) do
        if count >= config.MaxModels then break end
        
        -- Skip vanilla directories
        if dir ~= "alyx" and dir ~= "breen" and dir ~= "eli" and 
           dir ~= "gman_high" and dir ~= "kleiner" and dir ~= "monk" and
           dir ~= "mossman" and dir ~= "odessa" and dir ~= "p2_chell" and
           dir ~= "police" and dir ~= "police_fem" then
            
            local path = "models/player/" .. dir .. "/"
            local files = file.Find(path .. "*.mdl", "GAME")
            if files then
                local dirCount = 0
                for _, f in ipairs(files) do
                    if count >= config.MaxModels then break end
                    
                    local fullPath = path .. f
                    if not self:IsBlacklisted(fullPath) then
                        if not AA.ModelRegistry.Models[fullPath] and util.IsValidModel(fullPath) then
                            if self:RegisterSimple(fullPath, config) then
                                count = count + 1
                                dirCount = dirCount + 1
                            end
                        end
                    end
                end
                if dirCount > 0 then
                    print("[AA Discovery]   models/player/" .. dir .. "/: " .. dirCount .. " models")
                end
            end
        end
    end
    
    return count
end

-- Simplified registration - ACCEPT ALL MODELS
function AA.ModelDiscovery:RegisterSimple(path, config)
    -- Already registered?
    if AA.ModelRegistry.Models[path] then return false end
    
    -- Validate model exists
    if not util.IsValidModel(path) then
        return false
    end
    
    -- Register with simple humanoid tag - NO ANIMATION CHECK
    AA.ModelRegistry:RegisterModel(path, {
        tags = {"humanoid"},
        approved = true,
        priority = 10,
        discovered = true,
        isFallback = false,
    })
    
    return true
end

-- Animation sequences required for enemy AI
AA.ModelDiscovery.RequiredSequences = {
    -- Need at least ONE of these for idle
    idle = {"idle_all", "idle", "Idle", "IDLE", "stand", "reference", "idle_subtle"},
    -- Need at least ONE of these for movement  
    move = {"run_all", "run", "Run", "walk_all", "walk", "Walk", "move_all", "run_all_01"},
}

-- DISABLED: Animation validation removed to prevent crashes
-- All valid models are accepted regardless of animations
function AA.ModelDiscovery:ValidateModelAnimations(modelPath)
    return true -- Always accept
end

-- Check if a model path matches any blacklist pattern
function AA.ModelDiscovery:IsBlacklisted(path)
    local lowerPath = string.lower(path)
    for _, pattern in ipairs(self.BlacklistPatterns) do
        if string.find(lowerPath, pattern, 1, true) then
            return true
        end
    end
    return false
end

-- Safer version of ScanPattern with individual model validation
function AA.ModelDiscovery:ScanPatternSafe(pattern, config)
    local count = 0
    local blacklistedModels = 0
    
    for _, path in ipairs(pattern.paths) do
        if count >= config.MaxModels then break end
        
        -- Find files safely
        local ok, files = pcall(file.Find, path .. "*.mdl", "GAME")
        if ok and files and #files > 0 then
            print(string.format("[AA Discovery]   Path '%s': found %d files", path, #files))
            for _, f in ipairs(files) do
                if count >= config.MaxModels then break end
                
                local fullPath = path .. f
                
                -- Check blacklist first
                if not self:IsBlacklisted(fullPath) then
                    -- Validate model before registering (no animation check - allow all valid models)
                    local valid, err = pcall(function()
                        if not AA.ModelRegistry.Models[fullPath] and util.IsValidModel(fullPath) then
                            self:RegisterFoundModel(fullPath, pattern.tags, pattern.priority, config)
                        end
                    end)
                    
                    if valid then
                        count = count + 1
                    end
                else
                    blacklistedModels = blacklistedModels + 1
                end
            end
        end
    end
    
    if blacklistedModels > 0 then
        print(string.format("[AA Discovery] Skipped %d blacklisted models", blacklistedModels))
    end
    
    return count
end

-- Scan a specific pattern group (original version)
function AA.ModelDiscovery:ScanPattern(pattern, config)
    local count = 0
    
    for _, path in ipairs(pattern.paths) do
        if count >= config.MaxModels then break end
        
        local files = file.Find(path .. "*.mdl", "GAME")
        if files then
            for _, f in ipairs(files) do
                if count >= config.MaxModels then break end
                
                local fullPath = path .. f
                if self:RegisterFoundModel(fullPath, pattern.tags, pattern.priority, config) then
                    count = count + 1
                end
            end
        end
        
        -- Check for subdirectories (one level)
        local _, dirs = file.Find(path .. "*", "GAME")
        if dirs then
            for _, dir in ipairs(dirs) do
                if count >= config.MaxModels then break end
                
                local subPath = path .. dir .. "/"
                local subFiles = file.Find(subPath .. "*.mdl", "GAME")
                if subFiles then
                    for _, f in ipairs(subFiles) do
                        if count >= config.MaxModels then break end
                        
                        local fullPath = subPath .. f
                        if self:RegisterFoundModel(fullPath, pattern.tags, pattern.priority, config) then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    
    if count > 0 then
        self:Log(3, "  Pattern '" .. pattern.name .. "': " .. count .. " models")
    end
    
    return count
end

-- Deep recursive scan
function AA.ModelDiscovery:DeepScan(basePath, depth, config)
    if depth >= config.RecursiveDepth then return 0 end
    
    local count = 0
    local blacklistedModels = 0
    local files, dirs = file.Find(basePath .. "*", "GAME")
    
    -- Check model files in current directory
    if files then
        for _, f in ipairs(files) do
            if count >= config.MaxModels then break end
            
            if string.sub(f, -4) == ".mdl" then
                local fullPath = basePath .. f
                
                -- Check blacklist first
                if not self:IsBlacklisted(fullPath) then
                    local tags = self:AutoClassify(fullPath)
                    
                    -- Register without animation validation - allow all valid models
                    if self:RegisterFoundModel(fullPath, tags, 1, config) then
                        count = count + 1
                    end
                else
                    blacklistedModels = blacklistedModels + 1
                end
            end
        end
    end
    
    -- Recurse into subdirectories
    if dirs and depth < config.RecursiveDepth then
        for _, dir in ipairs(dirs) do
            if count >= config.MaxModels then break end
            -- Skip common non-model directories
            if not self:IsExcludedDir(dir) then
                local subCount, subBlacklisted = self:DeepScan(basePath .. dir .. "/", depth + 1, config)
                count = count + subCount
                blacklistedModels = blacklistedModels + (subBlacklisted or 0)
            end
        end
    end
    
    if depth == 0 and blacklistedModels > 0 then
        print(string.format("[AA Discovery] DeepScan '%s': Skipped %d blacklisted models", basePath, blacklistedModels))
    end
    
    return count, blacklistedModels
end

-- DISABLED: Deep workshop scanning can cause crashes
-- Pattern-based scanning covers most workshop models
function AA.ModelDiscovery:ScanWorkshopAddons(config)
    return 0
end

-- Scan mounted games (HL2, EP1, EP2, etc)
function AA.ModelDiscovery:ScanMountedGames(config)
    local count = 0
    local blacklistedModels = 0
    
    -- These are the game content mounts
    local gamePaths = {
        "models/humans/group01/",
        "models/humans/group02/",
        "models/humans/group03/",
        "models/humans/group03m/",
        "models/humans/group04/",
        "models/humans/enhanced/",
    }
    
    for _, path in ipairs(gamePaths) do
        if count >= config.MaxModels then break end
        
        local files = file.Find(path .. "*.mdl", "GAME")
        if files then
            for _, f in ipairs(files) do
                if count >= config.MaxModels then break end
                
                local fullPath = path .. f
                
                -- Check blacklist first
                if not self:IsBlacklisted(fullPath) then
                    -- Register without animation validation - allow all valid models
                    if self:RegisterFoundModel(fullPath, {"humanoid"}, 5, config) then
                        count = count + 1
                    end
                else
                    blacklistedModels = blacklistedModels + 1
                end
            end
        end
    end
    
    if blacklistedModels > 0 then
        print(string.format("[AA Discovery] ScanMountedGames: Skipped %d blacklisted models", blacklistedModels))
    end
    
    return count
end

-- DISABLED: Deep scanning can cause crashes
-- Use pattern-based scanning only
function AA.ModelDiscovery:DeepScanAllModels(config)
    return 0
end

-- DISABLED: Deep workshop scanning can cause crashes
function AA.ModelDiscovery:ScanWorkshopDeep(config)
    return 0
end

-- Register a found model if valid
function AA.ModelDiscovery:RegisterFoundModel(path, tags, priority, config)
    -- Already registered?
    if AA.ModelRegistry.Models[path] then return false end
    
    -- Validate model
    if config.ValidateModels then
        if not util.IsValidModel(path) then
            return false
        end
    end
    
    -- Auto-classify based on name for additional tags
    local autoTags = self:AutoClassify(path)
    for _, tag in ipairs(autoTags) do
        if not table.HasValue(tags, tag) then
            table.insert(tags, tag)
        end
    end
    
    -- Register with ModelRegistry
    -- IMPORTANT: Set isFallback = false so these are prioritized over fallback models
    AA.ModelRegistry:RegisterModel(path, {
        tags = tags,
        approved = true,
        priority = priority,
        discovered = true,
        isFallback = false,
    })
    
    self:Log(3, "  Registered: " .. path)
    return true
end

-- Auto-classify a model based on its path/name
function AA.ModelDiscovery:AutoClassify(path)
    local tags = {}
    local lowerPath = string.lower(path)
    
    for _, pattern in ipairs(self.NamePatterns) do
        if string.find(lowerPath, pattern.pattern, 1, true) then
            for _, tag in ipairs(pattern.tags) do
                if not table.HasValue(tags, tag) then
                    table.insert(tags, tag)
                end
            end
        end
    end
    
    -- Check for common path patterns
    if string.find(lowerPath, "/player/", 1, true) then
        if not table.HasValue(tags, "player") then table.insert(tags, "player") end
    end
    
    if string.find(lowerPath, "/humans/", 1, true) or 
       string.find(lowerPath, "citizen", 1, true) or
       string.find(lowerPath, "refugee", 1, true) then
        if not table.HasValue(tags, "humanoid") then table.insert(tags, "humanoid") end
    end
    
    return tags
end

-- Check if directory should be excluded from scanning
function AA.ModelDiscovery:IsExcludedDir(dir)
    local excluded = {
        "effects", "particles", "materials", "sounds", 
        "maps", "scenes", "scripts", "gamemodes",
        "lua", "bin", "data", "download", "downloads",
        "save", "saves", "settings", "cache",
    }
    
    for _, ex in ipairs(excluded) do
        if string.lower(dir) == ex then return true end
    end
    
    return false
end

-- Check if directory is a vanilla HL2 directory
function AA.ModelDiscovery:IsVanillaDir(dir)
    -- NOTE: "player" is NOT vanilla - it contains workshop CS:S models!
    local vanilla = {
        "humans", "combine", "zombie", "antlion",
        "headcrab", "vortigaunt", "dog", "crow", "pigeon",
        "seagull", "airboat", "vehicle", "weapons", "items",
        "props", "gibs", "sprites", "editor", "w_missile",
        "shell", "police", "strider", "helicopter", "dropship",
        -- Weapon viewmodel/worldmodel directories
        "v_smg", "v_pistol", "v_357", "v_ar2", "v_crossbow",
        "v_crowbar", "v_grenade", "v_physcannon", "v_rpg",
        "v_shotgun", "v_stunbaton", "w_smg", "w_pistol",
        "w_357", "w_ar2", "w_crossbow", "w_crowbar",
        "w_grenade", "w_physcannon", "w_rpg", "w_shotgun",
    }
    
    local lowerDir = string.lower(dir)
    for _, v in ipairs(vanilla) do
        if lowerDir == v then return true end
    end
    
    -- Check if it's a weapon viewmodel/worldmodel directory
    if string.sub(lowerDir, 1, 2) == "v_" or string.sub(lowerDir, 1, 2) == "w_" then
        return true
    end
    
    return false
end

-- Logging helper
function AA.ModelDiscovery:Log(level, message)
    if self.Config.LogLevel >= level then
        local prefix = "[AA Discovery] "
        if level == 1 then prefix = "[AA Discovery ERROR] "
        elseif level == 3 then prefix = "[AA Discovery VERBOSE] "
        end
        print(prefix .. message)
    end
end

-- Statistics function
function AA.ModelDiscovery:GetStats()
    local stats = {
        total = 0,
        byTag = {},
        bySource = {},
    }
    
    for path, data in pairs(AA.ModelRegistry.Models) do
        if not data.isFallback then
            stats.total = stats.total + 1
            
            -- Count by tags
            for _, tag in ipairs(data.tags or {}) do
                stats.byTag[tag] = (stats.byTag[tag] or 0) + 1
            end
        end
    end
    
    return stats
end

-- Hook into InitPostEntity which runs after all addons are mounted
hook.Add("InitPostEntity", "AA_ModelDiscovery_InitPostEntity", function()
    print("[AA Discovery] InitPostEntity fired - scheduling discovery...")
    
    -- Wait for game to be fully ready
    timer.Simple(5, function()
        print("[AA Discovery] Timer fired, checking systems...")
        
        if not AA.ModelDiscovery then 
            print("[AA Discovery] ERROR: AA.ModelDiscovery not available")
            return 
        end
        if not AA.ModelRegistry then 
            print("[AA Discovery] ERROR: AA.ModelRegistry not available")
            return 
        end
        
        print("[AA Discovery] Starting model discovery...")
        
        -- Notify clients that discovery is starting
        if AA.Net and AA.Net.StartLoading then
            AA.Net.StartLoading(nil, "INITIALIZING", "Preparing model discovery...", false)
        end
        
        -- Wrap discovery in pcall to catch any errors
        local success, err = pcall(function()
            AA.ModelDiscovery:DiscoverAll()
        end)
        
        if success then
            local discovered = 0
            for path, data in pairs(AA.ModelRegistry.Models or {}) do
                if not data.isFallback then
                    discovered = discovered + 1
                end
            end
            print("[AA Discovery] Complete! Found " .. discovered .. " workshop models")
        else
            print("[AA Discovery] ERROR: " .. tostring(err))
            
            -- Notify clients of error
            if AA.Net then
                if AA.Net.CompleteLoading then
                    AA.Net.CompleteLoading(nil)
                end
                if AA.Net.ShowToast then
                    AA.Net.ShowToast(nil, "Model discovery failed! Check console.", "ERROR", 6)
                end
            end
            
            -- Reset flag on error
            AA.ModelDiscovery.IsDiscovering = false
        end
    end)
end)

-- DISABLED: Late discovery disabled
-- hook.Add("PostGamemodeLoaded", "AA_ModelDiscovery_PostLoad", function() ... end)

-- Console command for manual discovery trigger
concommand.Add("aa_discover_models", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("[AA] Triggering manual model discovery...")
    
    -- Show loading to triggering player
    if IsValid(ply) and AA.Net then
        AA.Net.StartLoading(ply, "DISCOVERING MODELS", "Manual scan initiated...", false)
    end
    
    local count = AA.ModelDiscovery:DiscoverAll()
    print("[AA] Discovery complete. Found " .. count .. " new models.")
    
    -- Complete loading for player
    if IsValid(ply) and AA.Net then
        AA.Net.CompleteLoading(ply)
        AA.Net.ShowToast(ply, string.format("Found %d models!", count), "SUCCESS", 4)
    end
end)

-- Console command for stats
concommand.Add("aa_model_stats", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local stats = AA.ModelDiscovery:GetStats()
    
    print("[AA] Model Discovery Statistics:")
    print("  Total discovered models: " .. stats.total)
    print("  Total registered models: " .. table.Count(AA.ModelRegistry.Models))
    print("")
    print("  Models by tag:")
    for tag, count in SortedPairs(stats.byTag) do
        print("    " .. tag .. ": " .. count)
    end
end)

-- Console command to test if a specific model exists
concommand.Add("aa_model_test", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_model_test <model_path>")
        return
    end
    
    print("[AA] Testing model: " .. path)
    print("  IsValidModel: " .. tostring(util.IsValidModel(path)))
    print("  File exists: " .. tostring(file.Exists(path, "GAME")))
    
    -- Try to get info
    local mdl = util.GetModelInfo(path)
    if mdl then
        print("  Model info available")
    else
        print("  No model info")
    end
end)

-- Command to list discovered models with tags
concommand.Add("aa_models_discovered", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("[AA] Discovered Workshop Models:")
    print(string.rep("=", 60))
    
    local count = 0
    for path, data in SortedPairs(AA.ModelRegistry.Models) do
        if not data.isFallback then
            count = count + 1
            local tags = table.concat(data.tags or {}, ", ")
            print(string.format("%3d. %s", count, path))
            print("     Tags: " .. tags)
        end
    end
    
    print(string.rep("=", 60))
    print("Total discovered: " .. count)
end)

-- Command to force use a specific model on next spawn
concommand.Add("aa_force_model", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_force_model <model_path>")
        print("       aa_force_model random  -- for random model")
        print("       aa_force_model default -- to clear")
        return
    end
    
    -- Store on player
    if IsValid(ply) then
        if path == "default" then
            ply.AA_ForcedModel = nil
            print("Cleared forced model")
        elseif path == "random" then
            ply.AA_ForcedModel = "RANDOM"
            print("Will use random workshop model")
        else
            -- Verify model
            if util.IsValidModel(path) then
                ply.AA_ForcedModel = path
                print("Forced model set to: " .. path)
            else
                print("Invalid model: " .. path)
            end
        end
    end
end)

-- Diagnostic command to test model selection
concommand.Add("aa_test_model_select", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    print("[AA] Testing model selection...")
    print(string.rep("=", 60))
    
    -- Count all model types
    local total = 0
    local fallbacks = 0
    local discovered = 0
    local approved = 0
    
    for path, data in pairs(AA.ModelRegistry.Models) do
        total = total + 1
        if data.isFallback then
            fallbacks = fallbacks + 1
        else
            discovered = discovered + 1
        end
        if data.approved and not data.blacklisted then
            approved = approved + 1
        end
    end
    
    print("Model Registry Statistics:")
    print("  Total registered: " .. total)
    print("  Fallback models: " .. fallbacks)
    print("  Discovered models: " .. discovered)
    print("  Approved (not blacklisted): " .. approved)
    print("")
    print("Will use workshop only: " .. tostring(discovered > 5))
    print("")
    
    -- Test selection
    if AA.ModelRegistry.GetModelForArchetype then
        print("Testing GetModelForArchetype for each archetype:")
        for archetype = 1, 6 do
            local modelData = AA.ModelRegistry:GetModelForArchetype(archetype, false)
            if modelData then
                local status = modelData.isFallback and "[FALLBACK]" or "[WORKSHOP]"
                print(string.format("  Archetype %d: %s %s", archetype, status, modelData.path))
            else
                print(string.format("  Archetype %d: NO MODEL", archetype))
            end
        end
    end
    
    print(string.rep("=", 60))
end)

-- Test animation sequences on a specific model
concommand.Add("aa_test_model_anims", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local modelPath = args[1]
    if not modelPath then
        print("Usage: aa_test_model_anims <model_path>")
        print("Example: aa_test_model_anims models/player/alyx.mdl")
        return
    end
    
    if not util.IsValidModel(modelPath) then
        print("[AA] Invalid model: " .. modelPath)
        return
    end
    
    print(string.format("[AA] Testing animations for: %s", modelPath))
    print(string.rep("=", 60))
    
    -- Create temp entity to check sequences
    local tempEnt = ents.Create("prop_dynamic")
    if not IsValid(tempEnt) then
        print("[AA] Failed to create test entity")
        return
    end
    
    tempEnt:SetModel(modelPath)
    
    local seqCount = tempEnt:GetSequenceCount()
    print(string.format("Total sequences: %d", seqCount))
    print("")
    
    -- Show first 20 sequences
    if seqCount > 0 then
        print("Available sequences:")
        for i = 0, math.min(seqCount - 1, 19) do
            local name = tempEnt:GetSequenceName(i) or "(none)"
            print(string.format("  [%d] %s", i, name))
        end
        if seqCount > 20 then
            print(string.format("  ... and %d more", seqCount - 20))
        end
        print("")
    end
    
    -- Check required sequences
    local requiredSeqs = {
        {"idle_all", "idle", "Idle", "IDLE", "stand", "reference"},
        {"run_all", "run", "Run", "walk_all", "walk", "Walk"},
        {"melee", "attack", "Attack", "swing", "slash"},
        {"pain", "Pain", "flinch", "hurt"},
        {"death", "Death", "die"}
    }
    
    local categoryNames = {"Idle", "Move", "Attack", "Pain", "Death"}
    
    print("Required sequence check:")
    for catIdx, seqList in ipairs(requiredSeqs) do
        local found = false
        local foundName = ""
        for _, seqName in ipairs(seqList) do
            local seqID = tempEnt:LookupSequence(seqName)
            if seqID and seqID > 0 then
                found = true
                foundName = seqName
                break
            end
        end
        
        local status = found and "[OK]" or "[MISSING]"
        local detail = found and ("Found: " .. foundName) or "No valid sequence"
        print(string.format("  %s %s: %s", status, categoryNames[catIdx], detail))
    end
    
    tempEnt:Remove()
    print(string.rep("=", 60))
end, nil, "Test animation sequences on a model")

-- Quick test for the last spawned enemy's model
concommand.Add("aa_test_last_enemy", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    -- Find last spawned enemy
    local lastEnemy = nil
    local lastSpawnTime = 0
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsArcadeAnomalyEnemy and ent.SpawnTime then
            if ent.SpawnTime > lastSpawnTime then
                lastSpawnTime = ent.SpawnTime
                lastEnemy = ent
            end
        end
    end
    
    if not IsValid(lastEnemy) then
        print("[AA] No enemies found")
        return
    end
    
    local modelPath = lastEnemy:GetModel()
    print(string.format("[AA] Testing last enemy model: %s", modelPath))
    
    -- Run the test on this model
    ply:ConCommand("aa_test_model_anims \"" .. modelPath .. "\"")
end, nil, "Test animations on the last spawned enemy's model")


-- Check what model the last spawned enemy is using
concommand.Add("aa_check_last_enemy", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    -- Find last spawned enemy
    local lastEnemy = nil
    local lastSpawnTime = 0
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsArcadeAnomalyEnemy and ent.SpawnTime then
            if ent.SpawnTime > lastSpawnTime then
                lastSpawnTime = ent.SpawnTime
                lastEnemy = ent
            end
        end
    end
    
    if not IsValid(lastEnemy) then
        print("[AA] No enemies found")
        return
    end
    
    local model = lastEnemy:GetModel()
    print("[AA] Last enemy model: " .. tostring(model))
    print("[AA] IsValidModel: " .. tostring(util.IsValidModel(model)))
    print("[AA] Entity class: " .. lastEnemy:GetClass())
    print("[AA] Entity ID: " .. lastEnemy:EntIndex())
    
    -- Check if model is in registry
    if AA.ModelRegistry.Models[model] then
        local data = AA.ModelRegistry.Models[model]
        print("[AA] In registry: YES")
        print("[AA] isFallback: " .. tostring(data.isFallback))
    else
        print("[AA] In registry: NO")
    end
end, nil, "Check the last spawned enemy's model")

-- DISABLED: Model discovery was finding workshop player models
-- that don't have NPC animations. Using fallback models only.
