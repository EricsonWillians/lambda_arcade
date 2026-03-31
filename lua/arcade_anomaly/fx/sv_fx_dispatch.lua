--[[
    Arcade Anomaly: FX Dispatch (Server) 2.0
    
    Enhanced server-side FX coordination with better gore.
--]]

AA.FX = AA.FX or {}

function AA.FX.DispatchSpawn(pos, isElite)
    if not AA.FX.Types then return end
    local fxType = isElite and AA.FX.Types.SPAWN_ELITE or AA.FX.Types.SPAWN_DEFAULT
    AA.Net.DispatchFX(fxType, pos, { isElite = isElite })
    
    -- Server-side effects
    if isElite then
        util.ScreenShake(pos, 3, 10, 0.4, 1000)
        sound.Play("npc/combine_soldier/vo/alert1.wav", pos, 75, 100, 1)
        
        -- Red glow
        local light = ents.Create("light_dynamic")
        if IsValid(light) then
            light:SetKeyValue("_light", "255 50 50 200")
            light:SetKeyValue("brightness", "5")
            light:SetKeyValue("distance", "256")
            light:SetPos(pos)
            light:Spawn()
            light:Fire("TurnOn", "", 0)
            light:Fire("Kill", "", 0.5)
        end
    else
        sound.Play("ambient/levels/canals/toxic_slime_sizzle2.wav", pos, 65, math.random(90, 110), 0.5)
    end
end

function AA.FX.DispatchDeath(pos, isElite, attacker)
    if not AA.FX.Types then return end
    local fxType = isElite and AA.FX.Types.DEATH_ELITE or AA.FX.Types.DEATH_NORMAL
    AA.Net.DispatchFX(fxType, pos, { isElite = isElite, attacker = attacker })
    
    -- Server-side effects
    if isElite then
        -- Massive screen shake
        util.ScreenShake(pos, 8, 20, 0.8, 2000)
        
        -- Explosion sound
        sound.Play("ambient/explosions/exp" .. math.random(1, 4) .. ".wav", pos, 85, 100, 1)
        sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", pos, 75, 80, 1)
        
        -- Knockback damage (visual only)
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetDamage(0)
        util.BlastDamageInfo(dmg, pos, 250)
        
        -- Blood decals in radius
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local dist = math.random(50, 150)
            local decalPos = pos + Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
            
            local tr = util.TraceLine({
                start = decalPos + Vector(0, 0, 50),
                endpos = decalPos - Vector(0, 0, 50),
                mask = MASK_SOLID,
            })
            
            if tr.Hit then
                util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
            end
        end
        
        -- Dynamic light
        local light = ents.Create("light_dynamic")
        if IsValid(light) then
            light:SetKeyValue("_light", "255 100 100 200")
            light:SetKeyValue("brightness", "8")
            light:SetKeyValue("distance", "512")
            light:SetPos(pos)
            light:Spawn()
            light:Fire("TurnOn", "", 0)
            light:Fire("Kill", "", 1.0)
        end
    else
        -- Normal death
        util.ScreenShake(pos, 2, 5, 0.3, 500)
        sound.Play("physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav", pos, 70, math.random(95, 105), 0.7)
        
        -- Blood decals
        for i = 1, 3 do
            local angle = math.random() * math.pi * 2
            local dist = math.random(20, 60)
            local decalPos = pos + Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
            
            local tr = util.TraceLine({
                start = decalPos + Vector(0, 0, 30),
                endpos = decalPos - Vector(0, 0, 30),
                mask = MASK_SOLID,
            })
            
            if tr.Hit then
                util.Decal("Blood", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
            end
        end
    end
end

function AA.FX.DispatchHit(pos, hitType, damage, attacker)
    if not AA.FX.Types then return end
    hitType = hitType or "blood"
    damage = damage or 10
    
    local fxType = AA.FX.Types.HIT_BLOOD
    if hitType == "metal" then
        fxType = AA.FX.Types.HIT_SPARK
    elseif hitType == "smoke" then
        fxType = AA.FX.Types.HIT_SMOKE
    end
    
    AA.Net.DispatchFX(fxType, pos, { hitType = hitType, damage = damage })
    
    -- Server-side hit effects based on damage
    if damage >= 30 then
        -- Heavy hit
        util.ScreenShake(pos, damage / 20, 10, 0.1, 300)
    end
end

function AA.FX.DispatchComboMilestone(pos, comboLevel)
    AA.Net.DispatchFX(AA.FX.Types.COMBO_MILESTONE, pos, { combo = comboLevel })
    
    -- Server-side combo effects
    local pitch = 100 + comboLevel * 5
    sound.Play("buttons/blip1.wav", pos, 65, pitch, 0.5)
    
    if comboLevel >= 10 then
        util.ScreenShake(pos, comboLevel / 5, 5, 0.2, 400)
    end
end

-- New: Dispatch critical hit
function AA.FX.DispatchCriticalHit(pos)
    if not AA.FX.Types then return end
    AA.Net.DispatchFX(AA.FX.Types.HIT_CRITICAL, pos, {})
    
    -- Screen shake for critical
    util.ScreenShake(pos, 4, 15, 0.15, 400)
    sound.Play("buttons/button10.wav", pos, 70, 80, 0.6)
end

-- New: Dispatch gib explosion (for explosive deaths)
function AA.FX.DispatchGibExplosion(pos, intensity)
    intensity = intensity or 1
    
    -- Massive effects
    util.ScreenShake(pos, 5 * intensity, 20, 0.5, 1000)
    
    sound.Play("ambient/explosions/exp" .. math.random(1, 4) .. ".wav", pos, 85, math.random(90, 110), 1)
    sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", pos, 80, 70, 1)
    
    -- Blood everywhere
    for i = 1, 15 * intensity do
        local angle = math.random() * math.pi * 2
        local dist = math.random(30, 200)
        local height = math.random(-20, 100)
        local decalPos = pos + Vector(math.cos(angle) * dist, math.sin(angle) * dist, height)
        
        local tr = util.TraceLine({
            start = decalPos + Vector(0, 0, 50),
            endpos = decalPos - Vector(0, 0, 100),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            local decalType = math.random() > 0.5 and "BloodLarge" or "Blood"
            util.Decal(decalType, tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
        end
    end
    
    -- Knockback
    local dmg = DamageInfo()
    dmg:SetDamageType(DMG_BLAST)
    dmg:SetDamage(0)
    util.BlastDamageInfo(dmg, pos, 300 * intensity)
    
    -- Dispatch to clients
    AA.Net.DispatchFX(AA.FX.Types.GIB_EXPLOSION, pos, { intensity = intensity })
end
