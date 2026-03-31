-- addons/arcade_spawner/lua/arcade_spawner/core/config.lua
-- BULLETPROOF Enhanced Configuration System v4.1

if not ArcadeSpawner then ArcadeSpawner = {} end

ArcadeSpawner.Config = {
    -- ═══════════════════════════════════════════════════════════════
    -- CORE PERFORMANCE SETTINGS
    -- ═══════════════════════════════════════════════════════════════
    MaxEnemies = 50,
    SpawnRadius = 3000,
    MinSpawnDistance = 400,
    SpawnInterval = 0.8,
    DifficultyScale = 1.6,
    MaxWorkshopModels = 100,
    
    -- ═══════════════════════════════════════════════════════════════
    -- ENHANCED WORKSHOP MODEL VALIDATION
    -- ═══════════════════════════════════════════════════════════════
    WorkshopValidation = {
        MaxHealthThreshold = 2000,      -- Reject models with >2000 HP
        MinHealthThreshold = 25,        -- Reject models with <25 HP
        MaxModelSize = 150,             -- Maximum bounding box size
        BlacklistedKeywords = {
            "god", "admin", "boss", "titan", "giant", "mega", "super_soldier",
            "overpowered", "invincible", "immortal", "ultimate"
        },
        RequiredSequences = {           -- Must have basic animations
            "idle", "walk", "run"
        }
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- DYNAMIC DIFFICULTY SCALING (Enhanced Per Wave)
    -- ═══════════════════════════════════════════════════════════════
    WaveScaling = {
        HealthScale = 0.15,         -- +15% health per wave
        SpeedScale = 0.08,          -- +8% speed per wave
        AccuracyScale = 0.12,       -- +12% accuracy per wave
        ReactionScale = 0.10,       -- +10% reaction time per wave
        DamageScale = 0.18,         -- +18% damage per wave
        MaxHealthMultiplier = 8.0,  -- Cap at 800% health
        MaxSpeedMultiplier = 3.0,   -- Cap at 300% speed
        MaxAccuracyMultiplier = 4.0,-- Cap at 400% accuracy
        MaxDamageMultiplier = 5.0   -- Cap at 500% damage
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- ENHANCED ENEMY AI CONFIGURATION
    -- ═══════════════════════════════════════════════════════════════
    AISettings = {
        SearchRadius = 1500,
        ChaseRadius = 2000,
        AttackRadius = 300,
        FlankingChance = 0.25,      -- 25% chance to flank
        CoverSeekingChance = 0.30,  -- 30% chance to seek cover
        SquadTactics = true,
        LongRangeEngagement = 1800, -- Engage at 1800 units
        PathfindingAccuracy = 0.85, -- 85% pathfinding accuracy
        ReactionTimeBase = 0.3,     -- Base reaction time (seconds)
        AimPrediction = true        -- Enable aim prediction
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- BULLETPROOF NPC MODELS WITH VALIDATED ANIMATIONS
    -- ═══════════════════════════════════════════════════════════════
    SafeNPCModels = {
        -- Military Units (High Combat Effectiveness)
        {model = "models/combine_soldier.mdl", npc = "npc_combine_s", weight = 3.0, category = "military", accuracy = 0.85, health = 100},
        {model = "models/combine_super_soldier.mdl", npc = "npc_combine_s", weight = 4.0, category = "elite", accuracy = 0.95, health = 150},
        {model = "models/combine_soldier_prisonguard.mdl", npc = "npc_combine_s", weight = 3.5, category = "military", accuracy = 0.90, health = 120},
        
        -- Security Forces (Medium Combat Effectiveness)
        {model = "models/police.mdl", npc = "npc_metropolice", weight = 2.5, category = "security", accuracy = 0.75, health = 80},
        
        -- Resistance Fighters (Variable Combat Effectiveness)
        {model = "models/barney.mdl", npc = "npc_barney", weight = 2.8, category = "resistance", accuracy = 0.80, health = 90},
        {model = "models/alyx.mdl", npc = "npc_alyx", weight = 3.2, category = "resistance", accuracy = 0.88, health = 100},
        
        -- Creatures (Special Combat Behaviors)
        {model = "models/zombie/classic.mdl", npc = "npc_zombie", weight = 2.2, category = "zombie", accuracy = 0.40, health = 60},
        {model = "models/zombie/fast.mdl", npc = "npc_fastzombie", weight = 2.8, category = "zombie", accuracy = 0.30, health = 40},
        {model = "models/zombie/poison.mdl", npc = "npc_poisonzombie", weight = 4.0, category = "zombie", accuracy = 0.20, health = 200},
        {model = "models/antlion.mdl", npc = "npc_antlion", weight = 3.5, category = "creature", accuracy = 0.70, health = 80},
        {model = "models/antlion_guard.mdl", npc = "npc_antlionguard", weight = 8.0, category = "boss", accuracy = 0.85, health = 500}
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- ENHANCED RARITY SYSTEM
    -- ═══════════════════════════════════════════════════════════════
    RaritySystem = {
        ["Common"] = {
            chance = 35,
            color = Color(255, 255, 255),
            healthMultiplier = 1.0,
            speedMultiplier = 1.0,
            damageMultiplier = 1.0,
            accuracyMultiplier = 1.0,
            xpMultiplier = 1.0,
            prefix = ""
        },
        ["Uncommon"] = {
            chance = 25,
            color = Color(30, 255, 30),
            healthMultiplier = 1.4,
            speedMultiplier = 1.15,
            damageMultiplier = 1.25,
            accuracyMultiplier = 1.20,
            xpMultiplier = 1.8,
            prefix = "Veteran"
        },
        ["Rare"] = {
            chance = 20,
            color = Color(30, 144, 255),
            healthMultiplier = 2.0,
            speedMultiplier = 1.35,
            damageMultiplier = 1.60,
            accuracyMultiplier = 1.50,
            xpMultiplier = 3.0,
            prefix = "Elite"
        },
        ["Epic"] = {
            chance = 12,
            color = Color(138, 43, 226),
            healthMultiplier = 3.2,
            speedMultiplier = 1.60,
            damageMultiplier = 2.20,
            accuracyMultiplier = 2.00,
            xpMultiplier = 5.0,
            prefix = "Champion"
        },
        ["Legendary"] = {
            chance = 6,
            color = Color(255, 165, 0),
            healthMultiplier = 5.5,
            speedMultiplier = 2.00,
            damageMultiplier = 3.50,
            accuracyMultiplier = 3.00,
            xpMultiplier = 8.0,
            prefix = "LEGENDARY"
        },
        ["Mythic"] = {
            chance = 2,
            color = Color(255, 20, 147),
            healthMultiplier = 10.0,
            speedMultiplier = 2.50,
            damageMultiplier = 6.00,
            accuracyMultiplier = 4.50,
            xpMultiplier = 15.0,
            prefix = "★ MYTHIC ★"
        }
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- BOSS WAVE CONFIGURATION
    -- ═══════════════════════════════════════════════════════════════
    BossWaves = {
        Interval = 5,               -- Every 5 waves
        SpecialWaves = {10, 20, 30, 50, 75, 100},
        BossHealthMultiplier = 15.0,
        BossDamageMultiplier = 8.0,
        BossSpeedMultiplier = 1.8,
        BossAccuracyMultiplier = 5.0,
        BossXPMultiplier = 25.0
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- WEAPON LOADOUT SYSTEM (Procedural)
    -- ═══════════════════════════════════════════════════════════════
    WeaponLoadouts = {
        [1] = {"weapon_pistol"},                                    -- Wave 1-3
        [4] = {"weapon_pistol", "weapon_smg1"},                    -- Wave 4-7
        [8] = {"weapon_smg1", "weapon_shotgun"},                   -- Wave 8-12
        [13] = {"weapon_shotgun", "weapon_ar2"},                   -- Wave 13-18
        [19] = {"weapon_ar2", "weapon_crossbow"},                  -- Wave 19-25
        [26] = {"weapon_ar2", "weapon_crossbow", "weapon_rpg"}     -- Wave 26+
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- HUD CONFIGURATION (ASCII-Only)
    -- ═══════════════════════════════════════════════════════════════
    HUD = {
        AutoInitialize = true,      -- Force HUD initialization on map load
        InitializationDelay = 2,    -- Seconds to wait before forcing HUD
        DirectionalIndicators = {
            Up = "^",
            Down = "v", 
            Left = "<",
            Right = ">",
            UpLeft = "/",
            UpRight = "\\",
            DownLeft = "\\",
            DownRight = "/"
        },
        MaxIndicatorDistance = 2000,
        UpdateFrequency = 0.1,
        FontSizes = {
            Title = 28,
            Large = 22,
            Medium = 18,
            Small = 14,
            Tiny = 12
        }
    },
    
    -- ═══════════════════════════════════════════════════════════════
    -- ENHANCED EFFECTS CONFIGURATION
    -- ═══════════════════════════════════════════════════════════════
    Effects = {
        SpawnEffects = {
            ParticleCount = 25,
            Duration = 2.5,
            LightIntensity = 8,
            ScreenShakeRadius = 600,
            SoundVolume = 75
        },
        DeathEffects = {
            ParticleCount = 15,
            Duration = 2.0,
            SmokeIntensity = 150
        },
        LevelUpEffects = {
            SpiralParticles = 60,
            Duration = 3.0,
            GoldenIntensity = 12,
            ScreenEffectDuration = 0.8
        }
    }
}

-- Console variables for runtime adjustment
if SERVER then
    CreateConVar("arcade_difficulty_scale", "1.6", FCVAR_ARCHIVE, "Global difficulty scaling factor")
    CreateConVar("arcade_max_enemies", "50", FCVAR_ARCHIVE, "Maximum enemies at once")
    CreateConVar("arcade_ai_accuracy", "1.0", FCVAR_ARCHIVE, "AI accuracy multiplier")
    CreateConVar("arcade_spawn_rate", "0.8", FCVAR_ARCHIVE, "Enemy spawn interval")
    CreateConVar("arcade_workshop_validation", "1", FCVAR_ARCHIVE, "Enable workshop model validation")
end

print("[Arcade Spawner] ⚙️ Enhanced Configuration System v4.1 Loaded!")