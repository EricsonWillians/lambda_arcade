--[[
    Arcade Anomaly: Main Configuration
--]]

AA.Config = AA.Config or {}

-- Game Settings
AA.Config.Game = {
    -- Run timing
    CountdownDuration = 3,          -- Seconds before run starts
    RestartDelay = 2,               -- Seconds before restart available after death
    
    -- Difficulty scaling
    BaseEnemyCap = 8,               -- Starting max active enemies
    MaxEnemyCap = 25,               -- Absolute maximum enemies
    DifficultyScaleInterval = 30,   -- Seconds between difficulty increases
    
    -- Spawn settings
    MinSpawnDistance = 400,         -- Minimum spawn distance from player
    MaxSpawnDistance = 2000,        -- Maximum spawn distance from player
    SpawnIntervalBase = 2.0,        -- Base seconds between spawn attempts
    SpawnIntervalMin = 0.5,         -- Fastest spawn rate
    
    -- Elite settings
    EliteChanceBase = 0.05,         -- Base 5% elite chance
    EliteChanceMax = 0.25,          -- Max 25% elite chance
    EliteMinDifficulty = 2,         -- Minutes before elites can spawn
}

-- Score Settings
AA.Config.Score = {
    KillBase = 100,
    EliteKillBonus = 500,
    SurvivalTick = 1,               -- Per second
    ComboMultiplierMax = 10,
    ComboDecayRate = 0.5,           -- Combo points lost per second of inactivity
    ComboKillBonus = 50,            -- Bonus per combo level
}

-- UI Settings
AA.Config.UI = {
    PrimaryColor = Color(200, 50, 50),
    SecondaryColor = Color(30, 30, 35),
    AccentColor = Color(255, 180, 0),
    TextColor = Color(240, 240, 240),
    DangerColor = Color(220, 60, 60),
    
    -- HUD positions (relative to screen)
    ScoreX = 0.5,
    ScoreY = 0.05,
    ComboX = 0.5,
    ComboY = 0.12,
    HealthX = 0.05,
    HealthY = 0.9,
}

-- Debug Settings
AA.Config.Debug = {
    ShowSpawnAnchors = false,
    ShowNavigationPaths = false,
    ShowStuckRecovery = false,
    PrintEnemyStates = false,
    ValidateModelsOnLoad = true,
}

-- Persistence Paths
AA.Config.DataPath = "arcade_anomaly"
AA.Config.HighscoreFile = "highscores.json"
AA.Config.SettingsFile = "settings.json"
AA.Config.ModelCacheFile = "model_cache.json"
