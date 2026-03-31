--[[
    Arcade Anomaly: FX Definitions
    
    Shared definitions for visual and audio effects.
--]]

AA.FX = AA.FX or {}

-- FX Types
AA.FX.Types = {
    SPAWN_DEFAULT = 1,
    SPAWN_ELITE = 2,
    DEATH_NORMAL = 3,
    DEATH_ELITE = 4,
    HIT_BLOOD = 5,
    HIT_SPARK = 6,
    HIT_SMOKE = 7,
    COMBO_MILESTONE = 8,
    SCORE_POPUP = 9,
    FOOTSTEP_HEAVY = 10,
    FOOTSTEP_LIGHT = 11,
}

-- FX Definitions (shared configuration)
AA.FX.Defs = {
    [AA.FX.Types.SPAWN_DEFAULT] = {
        duration = 0.5,
        sound = "ambient/levels/canals/toxic_slime_sizzle2.wav",
        particle = nil, -- Will use custom effect
        screenShake = { amp = 1, freq = 5, dur = 0.2 },
    },
    [AA.FX.Types.SPAWN_ELITE] = {
        duration = 1.0,
        sound = "npc/combine_soldier/vo/alert1.wav",
        particle = nil,
        screenShake = { amp = 3, freq = 10, dur = 0.4 },
        light = { color = Color(255, 50, 50), brightness = 2, size = 256, decay = 0.5 },
    },
    [AA.FX.Types.DEATH_NORMAL] = {
        duration = 0.3,
        sound = "physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav",
        particle = "blood_impact_red_01",
    },
    [AA.FX.Types.DEATH_ELITE] = {
        duration = 1.0,
        sound = "ambient/explosions/exp" .. math.random(1, 3) .. ".wav",
        particle = "explosion_huge",
        screenShake = { amp = 5, freq = 15, dur = 0.6 },
        light = { color = Color(255, 100, 0), brightness = 3, size = 512, decay = 1.0 },
    },
    [AA.FX.Types.HIT_BLOOD] = {
        duration = 0.1,
        particle = "blood_impact_red_01",
    },
    [AA.FX.Types.HIT_SPARK] = {
        duration = 0.1,
        particle = "impact_metal",
        sound = "physics/metal/metal_solid_impact_bullet" .. math.random(1, 4) .. ".wav",
    },
    [AA.FX.Types.HIT_SMOKE] = {
        duration = 0.5,
        particle = "smoke_gib_01",
    },
    [AA.FX.Types.COMBO_MILESTONE] = {
        duration = 0.5,
        sound = "buttons/button14.wav",
    },
}

-- Color palettes for FX
AA.FX.Colors = {
    Blood = Color(180, 20, 20),
    Elite = Color(255, 50, 50),
    Score = Color(255, 220, 100),
    Combo = Color(255, 180, 0),
    Danger = Color(220, 60, 60),
    Smoke = Color(50, 50, 50),
    Spark = Color(255, 200, 100),
}

-- Sound categories
AA.FX.Sounds = {
    UI = {
        SCORE = "buttons/button9.wav",
        COMBO = "buttons/button14.wav",
        START = "ambient/alarms/klaxon1.wav",
        GAMEOVER = "ambient/alarms/apc_alarm_pass1.wav",
    },
    ENEMY = {
        SPAWN = "ambient/levels/canals/toxic_slime_sizzle2.wav",
        ELITE_SPAWN = "npc/combine_soldier/vo/alert1.wav",
        STEP_HEAVY = "npc/dog/dog_footstep_run" .. math.random(1, 8) .. ".wav",
        STEP_LIGHT = "npc/fast_zombie/foot" .. math.random(1, 4) .. ".wav",
    },
    COMBAT = {
        HIT_GENERIC = "physics/flesh/flesh_impact_bullet",
        HIT_METAL = "physics/metal/metal_solid_impact_bullet",
        EXPLOSION = "ambient/explosions/exp",
    },
}
