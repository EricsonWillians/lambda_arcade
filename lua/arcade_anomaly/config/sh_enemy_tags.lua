--[[
    Arcade Anomaly: Model Tag Definitions
    
    Defines classification tags for workshop models.
--]]

AA.Tags = AA.Tags or {}

-- Archetype compatibility tags
AA.Tags.ArchetypeCompatibility = {
    CHASER = {"humanoid", "undead", "soldier", "creature"},
    RUSHER = {"beast", "creature", "fast"},
    BRUTE = {"large", "heavy", "machine", "tank"},
    SHOOTER = {"humanoid", "soldier", "robot", "armed"},
    EXPLODER = {"unstable", "creature", "machine", "volatile"},
    ELITE = {"commander", "elite", "boss", "hero"},
}

-- Visual/style tags for themed packs
AA.Tags.Themes = {
    MILITARY = {"soldier", "military", "tactical", "armed", "combine"},
    UNDEAD = {"zombie", "undead", "corpse", "ghoul", "skeleton"},
    MACHINE = {"robot", "machine", "mech", "android", "synth"},
    BEAST = {"animal", "creature", "monster", "alien", "wolf"},
    OCCULT = {"demon", "cultist", "ritual", "shadow", "dark"},
    SCIFI = {"alien", "space", "futuristic", "energy", "plasma"},
}

-- Movement style tags
AA.Tags.Movement = {
    HUMANOID = "humanoid",      -- Upright, bipedal
    QUADRUPED = "quadruped",    -- Four-legged
    SERPENTINE = "serpentine",  -- Snake-like
    HOVER = "hover",            -- Floating/flying
    ROLLING = "rolling",        -- Wheeled/spherical
}

-- Animation quality tags
AA.Tags.Animation = {
    FULL = "full",              -- Full animation set
    BASIC = "basic",            -- Basic walk/idle
    STATIC = "static",          -- Minimal/no animation
    BROKEN = "broken",          -- Known broken sequences
}

-- Quality tiers
AA.Tags.Quality = {
    APPROVED = "approved",
    PENDING = "pending",
    REJECTED = "rejected",
    BLACKLISTED = "blacklisted",
}
