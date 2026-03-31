--[[
    Arcade Anomaly: Type Definitions
    
    Enums, constants, and type definitions for the gamemode.
--]]

AA.Types = AA.Types or {}

-- Game State Machine
AA.Types.RunState = {
    IDLE = 0,
    PREPARING_MAP = 1,
    COUNTDOWN = 2,
    RUNNING = 3,
    PLAYER_DEAD = 4,
    RUN_SUMMARY = 5,
    RESTARTING = 6,
}

-- Enemy Archetypes
AA.Types.Archetype = {
    CHASER = 1,
    RUSHER = 2,
    BRUTE = 3,
    SHOOTER = 4,
    EXPLODER = 5,
    ELITE = 6,
}

AA.Types.ArchetypeNames = {
    [1] = "CHASER",
    [2] = "RUSHER",
    [3] = "BRUTE",
    [4] = "SHOOTER",
    [5] = "EXPLODER",
    [6] = "ELITE",
}

-- Animation States
AA.Types.AnimState = {
    IDLE = 0,
    MOVE = 1,
    SPRINT = 2,
    ATTACK = 3,
    PAIN = 4,
    DEATH = 5,
    SPECIAL = 6,
    SPAWN = 7,
}

-- AI Movement Modes
AA.Types.MoveMode = {
    IDLE = 0,
    CHASE = 1,
    STRAFE = 2,
    RETREAT = 3,
    SURROUND = 4,
}

-- Score Event Types
AA.Types.ScoreEvent = {
    ENEMY_KILLED = 1,
    ELITE_KILLED = 2,
    SURVIVAL_TICK = 3,
    COMBO_INCREASED = 4,
    WAVE_CLEARED = 5,
    SPECIAL_EVENT = 6,
}

-- Spawn Result Types
AA.Types.SpawnResult = {
    SUCCESS = 0,
    NO_VALID_ANCHOR = 1,
    TOO_CLOSE_TO_PLAYER = 2,
    COLLISION_FAIL = 3,
    ENEMY_CAP_REACHED = 4,
    COOLDOWN_ACTIVE = 5,
}

-- Recovery Tiers (anti-stuck)
AA.Types.RecoveryTier = {
    NONE = 0,
    REPATH = 1,
    NUDGE = 2,
    REPOSITION = 3,
    DESPAWN = 4,
}

-- FX Event Types
AA.Types.FXEvent = {
    SPAWN = 1,
    DEATH = 2,
    HIT = 3,
    ELITE_SPAWN = 4,
    COMBO_MILESTONE = 5,
    ELITE_DEATH = 6,
}

-- Model Validation Results
AA.Types.ValidationResult = {
    VALID = 0,
    MISSING_FILE = 1,
    INVALID_BOUNDS = 2,
    BROKEN_MATERIALS = 3,
    NO_SEQUENCES = 4,
    TOO_LARGE = 5,
    TOO_SMALL = 6,
    PERFORMANCE_HEAVY = 7,
}

-- Constants
AA.Types.Constants = {
    MAX_SCORE = 999999999,
    MAX_COMBO = 999,
    MAX_DIFFICULTY = 100,
    TICK_RATE = 66,  -- Source engine tick rate
}
