--[[
    Arcade Anomaly: Model Tags (Shared)
    
    Tag definitions for model classification.
--]]

AA.ModelTags = AA.ModelTags or {}

-- Tag categories
AA.ModelTags.Categories = {
    ARCHETYPE = "archetype",     -- Which archetypes this model works for
    THEME = "theme",             -- Visual theme grouping
    MOVEMENT = "movement",       -- Movement style
    QUALITY = "quality",         -- Quality assessment
    APPROVAL = "approval",       -- Validation status
}

-- Tag values
AA.ModelTags.Values = {
    -- Archetype compatibility
    ARCHETYPE = {
        CHASER = "chaser",
        RUSHER = "rusher",
        BRUTE = "brute",
        SHOOTER = "shooter",
        EXPLODER = "exploder",
        ELITE = "elite",
        UNIVERSAL = "universal",
    },
    
    -- Visual themes
    THEME = {
        HUMANOID = "humanoid",
        BEAST = "beast",
        MACHINE = "machine",
        UNDEAD = "undead",
        SOLDIER = "soldier",
        CREATURE = "creature",
        DEMON = "demon",
        ROBOT = "robot",
        ALIEN = "alien",
    },
    
    -- Movement styles
    MOVEMENT = {
        BIPEDAL = "bipedal",
        QUADRUPED = "quadruped",
        SERPENTINE = "serpentine",
        HOVER = "hover",
        ROLLING = "rolling",
    },
    
    -- Quality levels
    QUALITY = {
        EXCELLENT = "excellent",
        GOOD = "good",
        AVERAGE = "average",
        POOR = "poor",
        BROKEN = "broken",
    },
    
    -- Approval status
    APPROVAL = {
        APPROVED = "approved",
        PENDING = "pending",
        REJECTED = "rejected",
        BLACKLISTED = "blacklisted",
    },
}

-- Get default tags for an archetype
function AA.ModelTags:GetDefaultTagsForArchetype(archetype)
    local defaults = {
        [AA.Types.Archetype.CHASER] = {
            AA.ModelTags.Values.ARCHETYPE.CHASER,
            AA.ModelTags.Values.THEME.HUMANOID,
            AA.ModelTags.Values.MOVEMENT.BIPEDAL,
        },
        [AA.Types.Archetype.RUSHER] = {
            AA.ModelTags.Values.ARCHETYPE.RUSHER,
            AA.ModelTags.Values.THEME.BEAST,
            AA.ModelTags.Values.MOVEMENT.QUADRUPED,
        },
        [AA.Types.Archetype.BRUTE] = {
            AA.ModelTags.Values.ARCHETYPE.BRUTE,
            AA.ModelTags.Values.THEME.CREATURE,
            AA.ModelTags.Values.MOVEMENT.BIPEDAL,
        },
        [AA.Types.Archetype.SHOOTER] = {
            AA.ModelTags.Values.ARCHETYPE.SHOOTER,
            AA.ModelTags.Values.THEME.SOLDIER,
            AA.ModelTags.Values.MOVEMENT.BIPEDAL,
        },
        [AA.Types.Archetype.EXPLODER] = {
            AA.ModelTags.Values.ARCHETYPE.EXPLODER,
            AA.ModelTags.Values.THEME.CREATURE,
            AA.ModelTags.Values.MOVEMENT.BIPEDAL,
        },
        [AA.Types.Archetype.ELITE] = {
            AA.ModelTags.Values.ARCHETYPE.ELITE,
            AA.ModelTags.Values.THEME.HUMANOID,
            AA.ModelTags.Values.MOVEMENT.BIPEDAL,
        },
    }
    
    return defaults[archetype] or {}
end
