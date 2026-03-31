--[[
    Arcade Anomaly: Balance Values
    
    All gameplay balance values in one place for easy tuning.
--]]

AA.Balance = AA.Balance or {}

-- Enemy Archetype Profiles
AA.Balance.Archetypes = {
    CHASER = {
        Name = "Chaser",
        Health = {80, 120},           -- Min, Max
        Speed = {180, 220},           -- Units per second
        Damage = {10, 15},            -- Per hit
        AttackRange = 64,
        AttackCooldown = 0.8,
        ScoreValue = 100,
        ThreatLevel = 1,
    },
    RUSHER = {
        Name = "Rusher",
        Health = {60, 90},
        Speed = {280, 340},
        Damage = {8, 12},
        AttackRange = 56,
        AttackCooldown = 0.5,
        ScoreValue = 150,
        ThreatLevel = 2,
    },
    BRUTE = {
        Name = "Brute",
        Health = {200, 300},
        Speed = {120, 140},
        Damage = {25, 40},
        AttackRange = 80,
        AttackCooldown = 1.5,
        ScoreValue = 300,
        ThreatLevel = 3,
    },
    SHOOTER = {
        Name = "Shooter",
        Health = {50, 80},
        Speed = {140, 160},
        Damage = {12, 18},
        AttackRange = 800,
        AttackCooldown = 1.2,
        PreferredDistance = {400, 700},
        ScoreValue = 200,
        ThreatLevel = 2,
    },
    EXPLODER = {
        Name = "Exploder",
        Health = {40, 60},
        Speed = {200, 240},
        Damage = {50, 80},            -- Explosion damage
        AttackRange = 96,             -- Detonation range
        AttackCooldown = 0.1,
        ScoreValue = 250,
        ThreatLevel = 3,
        ExplosionRadius = 200,
    },
    ELITE = {
        Name = "Elite",
        Health = {500, 800},
        Speed = {200, 260},
        Damage = {30, 50},
        AttackRange = 96,
        AttackCooldown = 0.6,
        ScoreValue = 1000,
        EliteKillBonus = 500,
        ThreatLevel = 5,
        SpecialAbility = "phase_dash", -- Can briefly phase/dash
    },
}

-- Elite Modifiers
AA.Balance.EliteModifiers = {
    HealthMult = 2.5,
    DamageMult = 1.8,
    SpeedMult = 1.3,
    ScoreMult = 3.0,
}

-- Difficulty Scaling
AA.Balance.Difficulty = {
    -- Per minute multipliers
    HealthGrowth = 0.05,            -- 5% health increase per minute
    DamageGrowth = 0.03,            -- 3% damage increase per minute
    SpeedGrowth = 0.02,             -- 2% speed increase per minute (capped)
    SpawnRateGrowth = 0.05,         -- 5% faster spawns per minute
    EnemyCapGrowth = 0.5,           -- +0.5 enemy cap per minute
}

-- Map Analysis Settings
AA.Balance.MapAnalysis = {
    MinPlayableArea = 10000,        -- Minimum square units for valid map
    MaxSpawnPoints = 32,            -- Maximum spawn anchors to track
    AnchorCooldown = 5,             -- Seconds before anchor can be reused
    MinAnchorQuality = 0.3,         -- Quality threshold for spawn anchors
}

-- AI Settings
AA.Balance.AI = {
    ThinkInterval = 0.1,            -- Seconds between AI updates
    PathUpdateInterval = 0.5,       -- Seconds between path recalculation
    StuckCheckInterval = 1.0,       -- Seconds between stuck checks
    StuckThreshold = 32,            -- Units moved to not be considered stuck
    MaxStuckTime = 5,               -- Seconds before stuck recovery triggers
    TargetUpdateInterval = 0.5,     -- Seconds between target checks
    AttackPrediction = 0.1,         -- Seconds to predict player position
}

-- Stuck Recovery Tiers
AA.Balance.Recovery = {
    Tier1_RepathTime = 2,           -- Seconds before repath attempt
    Tier2_NudgeDistance = 32,       -- Units to nudge
    Tier3_RepositionRadius = 128,   -- Micro-reposition range
    Tier4_DespawnTime = 8,          -- Seconds before hard despawn
}

-- Combo System
AA.Balance.Combo = {
    MaxTime = 5.0,                  -- Seconds to maintain combo
    KillBonus = 1,                  -- Combo points per kill
    EliteKillBonus = 3,             -- Combo points per elite kill
    MultiplierTiers = {             -- Score multipliers at combo levels
        [5] = 1.5,
        [10] = 2.0,
        [20] = 3.0,
        [50] = 5.0,
    },
}
