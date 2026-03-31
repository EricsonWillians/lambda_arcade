--[[
    Arcade Anomaly: Persistence Manager
    
    Handles saving/loading of high scores, settings, and model cache.
--]]

AA.Persistence = AA.Persistence or {}

-- Ensure data directory exists
function AA.Persistence:EnsureDataPath()
    if not file.Exists(AA.Config.DataPath, "DATA") then
        file.CreateDir(AA.Config.DataPath)
    end
end

function AA.Persistence:GetFullPath(filename)
    return AA.Config.DataPath .. "/" .. filename
end

-- JSON serialization with error handling
function AA.Persistence:Serialize(data)
    return util.TableToJSON(data, true)
end

function AA.Persistence:Deserialize(str)
    if not str or str == "" then return nil end
    return util.JSONToTable(str)
end

-- Generic save/load
function AA.Persistence:Save(filename, data)
    self:EnsureDataPath()
    local path = self:GetFullPath(filename)
    local json = self:Serialize(data)
    
    file.Write(path, json)
    
    if AA.Debug then
        print("[AA Persistence] Saved: " .. filename)
    end
end

function AA.Persistence:Load(filename, default)
    local path = self:GetFullPath(filename)
    
    if not file.Exists(path, "DATA") then
        return default or {}
    end
    
    local json = file.Read(path, "DATA")
    local data = self:Deserialize(json)
    
    if data == nil then
        print("[AA Persistence] Warning: Failed to parse " .. filename)
        return default or {}
    end
    
    if AA.Debug then
        print("[AA Persistence] Loaded: " .. filename)
    end
    
    return data
end

-- High Scores
function AA.Persistence:SaveHighScores()
    if not AA.ScoreManager then return end
    
    local data = {
        global_best = AA.ScoreManager.Persistent.globalBest,
        best_by_map = AA.ScoreManager.Persistent.bestByMap,
    }
    
    self:Save(AA.Config.HighscoreFile, data)
end

function AA.Persistence:LoadHighScores()
    local data = self:Load(AA.Config.HighscoreFile, {
        global_best = 0,
        best_by_map = {},
    })
    
    if AA.ScoreManager then
        AA.ScoreManager.Persistent.globalBest = data.global_best or 0
        AA.ScoreManager.Persistent.bestByMap = data.best_by_map or {}
    end
end

-- Settings
function AA.Persistence:SaveSettings(settings)
    self:Save(AA.Config.SettingsFile, settings)
end

function AA.Persistence:LoadSettings()
    return self:Load(AA.Config.SettingsFile, {
        -- Default settings
        difficulty = "normal",
        hudStyle = "default",
        soundVolume = 1.0,
        musicVolume = 0.5,
        screenShake = true,
        showDamageNumbers = true,
    })
end

-- Model Cache
function AA.Persistence:SaveModelCache(cache)
    self:Save(AA.Config.ModelCacheFile, cache)
end

function AA.Persistence:LoadModelCache()
    return self:Load(AA.Config.ModelCacheFile, {
        validated = {},
        rejected = {},
        blacklist = {},
        lastUpdate = 0,
    })
end

-- Bulk load at startup
function AA.Persistence:LoadAll()
    self:LoadHighScores()
    
    if AA.ModelCache then
        local cache = self:LoadModelCache()
        AA.ModelCache:SetData(cache)
    end
    
    -- Load settings for each player
    -- (Settings are per-player, so this is handled differently)
end

-- ConVars for player settings
CreateConVar("aa_difficulty", "normal", FCVAR_ARCHIVE, "Game difficulty")
CreateConVar("aa_hud_style", "default", FCVAR_ARCHIVE, "HUD visual style")
CreateConVar("aa_screenshake", "1", FCVAR_ARCHIVE, "Enable screen shake effects")

-- Admin commands for persistence
concommand.Add("aa_reset_highscores", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    if AA.ScoreManager then
        AA.ScoreManager.Persistent.globalBest = 0
        AA.ScoreManager.Persistent.bestByMap = {}
    end
    
    AA.Persistence:SaveHighScores()
    print("[AA] High scores reset")
end)

concommand.Add("aa_export_data", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local data = {
        highscores = AA.Persistence:Load(AA.Config.HighscoreFile),
        settings = AA.Persistence:Load(AA.Config.SettingsFile),
        modelCache = AA.Persistence:Load(AA.Config.ModelCacheFile),
        exportTime = os.time(),
    }
    
    local json = util.TableToJSON(data, true)
    file.Write(AA.Config.DataPath .. "/export_" .. os.time() .. ".json", json)
    
    print("[AA] Data exported")
end)
