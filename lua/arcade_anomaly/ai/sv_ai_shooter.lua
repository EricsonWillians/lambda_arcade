--[[
    Lambda Arcade: Enhanced Shooter AI
    Ranged enemy that maintains distance and finds cover
--]]

AA.AI.Shooter = {}

function AA.AI.Shooter:Initialize(ent)
    -- Shooter-specific stats
    ent.PreferredDistance = ent.PreferredDistance or 600
    ent.MinDistance = ent.MinDistance or 300
    ent.MaxDistance = ent.MaxDistance or 1200
    
    -- AI data
    if ent.AIData then
        ent.AIData.lastShotTime = 0
        ent.AIData.shotsInBurst = 0
        ent.AIData.maxBurstSize = 3
        ent.AIData.coverTarget = nil
        ent.AIData.isInCover = false
    end
end

function AA.AI.Shooter:OnTakeDamage(ent, dmg, attacker)
    -- Seek cover when hit
    local data = ent.AIData
    if data and not data.isInCover then
        -- Signal to main behavior that we want cover
        data.wantCover = true
    end
    
    return false
end

print("[Lambda Arcade] Enhanced Shooter AI initialized")
