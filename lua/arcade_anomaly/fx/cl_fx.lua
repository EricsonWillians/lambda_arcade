--[[
    Arcade Anomaly: FX Client 2.0
    
    Enhanced visual effects with better gore and impact.
--]]

AA.FX.Client = AA.FX.Client or {}

-- Add new FX types
AA.FX.Types = AA.FX.Types or {}
AA.FX.Types.HIT_CRITICAL = 7
AA.FX.Types.GIB_EXPLOSION = 8

-- Network handler
hook.Add("AA_FXDispatch", "AA_FX_Handler", function(fxType, position, data)
    AA.FX.Client:Dispatch(fxType, position, data)
end)

function AA.FX.Client:Dispatch(fxType, position, data)
    if fxType == AA.FX.Types.SPAWN_DEFAULT then
        self:SpawnDefault(position)
    elseif fxType == AA.FX.Types.SPAWN_ELITE then
        self:SpawnElite(position)
    elseif fxType == AA.FX.Types.DEATH_NORMAL then
        self:DeathNormal(position)
    elseif fxType == AA.FX.Types.DEATH_ELITE then
        self:DeathElite(position, data)
    elseif fxType == AA.FX.Types.HIT_BLOOD then
        self:HitBlood(position, data)
    elseif fxType == AA.FX.Types.HIT_SPARK then
        self:HitSpark(position)
    elseif fxType == AA.FX.Types.HIT_CRITICAL then
        self:HitCritical(position)
    elseif fxType == AA.FX.Types.GIB_EXPLOSION then
        self:GibExplosion(position, data)
    end
end

function AA.FX.Client:SpawnDefault(pos)
    -- Dust puff
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1)
    util.Effect("WheelDust", effect)
    
    -- Small particles
    for i = 1, 5 do
        local particle = Vector(
            pos.x + math.random(-20, 20),
            pos.y + math.random(-20, 20),
            pos.z + math.random(0, 30)
        )
        
        local eff = EffectData()
        eff:SetOrigin(particle)
        eff:SetScale(0.5)
        util.Effect("cball_bounce", eff)
    end
end

function AA.FX.Client:SpawnElite(pos)
    -- Large explosion effect
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(3)
    util.Effect("cball_explode", effect)
    
    -- Light flash
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 50
        dlight.b = 50
        dlight.brightness = 5
        dlight.Decay = 2000
        dlight.Size = 256
        dlight.DieTime = CurTime() + 0.5
    end
    
    -- Particles
    for i = 1, 10 do
        local eff = EffectData()
        eff:SetOrigin(pos + Vector(0, 0, 32))
        eff:SetScale(2)
        util.Effect("cball_bounce", eff)
    end
    
    -- Energy particles (replaced smoke with non-persistent effect)
    for i = 1, 5 do
        local eff = EffectData()
        eff:SetOrigin(pos + Vector(math.random(-30, 30), math.random(-30, 30), math.random(0, 50)))
        eff:SetScale(1)
        util.Effect("cball_bounce", eff)
    end
end

function AA.FX.Client:DeathNormal(pos)
    -- Blood effect
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1)
    util.Effect("BloodImpact", effect)
    
    -- Blood particles
    for i = 1, 5 do
        local offset = Vector(
            math.random(-15, 15),
            math.random(-15, 15),
            math.random(10, 40)
        )
        
        local eff = EffectData()
        eff:SetOrigin(pos + offset)
        eff:SetScale(1)
        util.Effect("bloodspray", eff)
    end
    
    -- Ground blood
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 10),
        endpos = pos - Vector(0, 0, 50),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end
end

function AA.FX.Client:DeathElite(pos, data)
    -- Large explosion
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetMagnitude(3)
    effect:SetScale(3)
    util.Effect("Explosion", effect)
    
    -- Multiple blood sprays
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local height = math.random(0, 60)
        local offset = Vector(
            math.cos(angle) * math.random(20, 50),
            math.sin(angle) * math.random(20, 50),
            height
        )
        
        local eff = EffectData()
        eff:SetOrigin(pos + offset)
        eff:SetNormal(offset:GetNormalized())
        eff:SetScale(math.random(2, 4))
        util.Effect("bloodspray", eff)
    end
    
    -- Fire particles
    for i = 1, 8 do
        local eff = EffectData()
        eff:SetOrigin(pos + Vector(math.random(-30, 30), math.random(-30, 30), math.random(0, 50)))
        util.Effect("cball_explode", eff)
    end
    
    -- Dynamic light
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 100
        dlight.b = 100
        dlight.brightness = 10
        dlight.Decay = 3000
        dlight.Size = 400
        dlight.DieTime = CurTime() + 0.8
    end
    
    -- Blood mist
    for i = 1, 10 do
        local mistPos = pos + VectorRand() * 40
        local eff = EffectData()
        eff:SetOrigin(mistPos)
        eff:SetScale(0.5)
        util.Effect("cball_bounce", eff)
    end
end

function AA.FX.Client:HitBlood(pos, data)
    local damage = data and data.damage or 10
    
    -- Scale effect by damage
    local scale = math.min(damage / 10, 3)
    
    -- Main impact
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(scale)
    util.Effect("BloodImpact", effect)
    
    -- Additional spray for heavy hits
    if damage >= 20 then
        for i = 1, 3 do
            local eff = EffectData()
            eff:SetOrigin(pos + VectorRand() * 10)
            eff:SetScale(scale * 0.5)
            util.Effect("bloodspray", eff)
        end
    end
end

function AA.FX.Client:HitSpark(pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1)
    util.Effect("cball_bounce", effect)
    
    -- Sparks
    local eff = EffectData()
    eff:SetOrigin(pos)
    eff:SetNormal(Vector(0, 0, 1))
    util.Effect("ManhackSparks", eff)
    
    -- Additional sparks
    for i = 1, 5 do
        local sparkPos = pos + VectorRand() * 5
        local spawneff = EffectData()
        spawneff:SetOrigin(sparkPos)
        spawneff:SetNormal(VectorRand())
        util.Effect("ManhackSparks", spawneff)
    end
end

function AA.FX.Client:HitCritical(pos)
    -- Bright flash
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 200
        dlight.b = 50
        dlight.brightness = 8
        dlight.Decay = 4000
        dlight.Size = 200
        dlight.DieTime = CurTime() + 0.3
    end
    
    -- Critical spark effect
    for i = 1, 8 do
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 20)
        eff:SetScale(2)
        util.Effect("cball_explode", eff)
    end
    
    -- Blood spray upward
    local eff = EffectData()
    eff:SetOrigin(pos)
    eff:SetNormal(Vector(0, 0, 1))
    eff:SetScale(4)
    util.Effect("HL2BloodSpray", eff)
end

function AA.FX.Client:GibExplosion(pos, data)
    local intensity = data and data.intensity or 1
    
    -- Massive explosion
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetMagnitude(4 * intensity)
    effect:SetScale(4 * intensity)
    util.Effect("Explosion", effect)
    
    -- Fire ring
    for i = 1, 16 * intensity do
        local angle = (i / (16 * intensity)) * math.pi * 2
        local dist = math.random(30, 80)
        local firePos = pos + Vector(
            math.cos(angle) * dist,
            math.sin(angle) * dist,
            math.random(0, 30)
        )
        
        local eff = EffectData()
        eff:SetOrigin(firePos)
        eff:SetScale(2)
        util.Effect("cball_explode", eff)
    end
    
    -- Blood everywhere
    for i = 1, 20 * intensity do
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 60)
        eff:SetScale(math.random(2, 4))
        eff:SetNormal(VectorRand())
        util.Effect("BloodImpact", eff)
    end
    
    -- Huge blood sprays
    for i = 1, 8 do
        local angle = math.random() * math.pi * 2
        local eff = EffectData()
        eff:SetOrigin(pos)
        eff:SetNormal(Vector(math.cos(angle), math.sin(angle), math.random(0.5, 1)))
        eff:SetScale(5)
        util.Effect("bloodspray", eff)
    end
    
    -- Dynamic light
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 80
        dlight.b = 80
        dlight.brightness = 15 * intensity
        dlight.Decay = 5000
        dlight.Size = 600
        dlight.DieTime = CurTime() + 1.0
    end
    
    -- Explosion sparks (replaced smoke)
    for i = 1, 10 do
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 50 + Vector(0, 0, 30))
        eff:SetScale(2)
        util.Effect("cball_explode", eff)
    end
end

-- Ambient blood effects for atmosphere
hook.Add("Think", "AA_AmbientBlood", function()
    -- Rare random blood drips from ceiling in gore areas
    -- This could be expanded based on map location
end)
