--[[
    Lambda Arcade: Ultra Gore System
    Maximum blood, guts, and satisfying violence
--]]

AA.Gore = AA.Gore or {}

-- Configuration
AA.Gore.Config = {
    BloodDecals = true,
    BloodSpray = true,
    Gibs = true,
    BloodPool = true,
    ScreenBlood = true,
    MaxBloodDecals = 50,
    MaxGibs = 20,
}

-- Blood decal types
AA.Gore.BloodDecals = {
    "Blood",
    "BloodLarge", 
    "BloodSmall",
}

-- Gib models (Vanilla HL2 only - these actually exist)
AA.Gore.GibModels = {
    "models/gibs/hgibs.mdl",
    "models/gibs/hgibs_scapula.mdl",
    "models/gibs/hgibs_spine.mdl",
    "models/gibs/hgibs_rib.mdl",
    -- Using generic debris as fallback for missing models
    "models/props_debris/concrete_chunk01a.mdl",
    "models/props_debris/concrete_chunk02a.mdl",
    "models/props_debris/concrete_chunk03a.mdl",
    "models/props_debris/concrete_chunk04a.mdl",
    "models/props_debris/concrete_chunk05a.mdl",
    "models/props_debris/concrete_chunk06a.mdl",
}

-- Enhanced blood spray on damage
function AA.Gore:SpawnBloodSpray(pos, normal, intensity)
    intensity = intensity or 1
    
    -- Main impact blood
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(normal or Vector(0,0,1))
    effect:SetScale(math.random(3, 5) * intensity)
    util.Effect("BloodImpact", effect)
    
    -- Multiple blood sprays in cone pattern
    for i = 1, 5 * intensity do
        local sprayDir = (normal or Vector(0,0,1)) + VectorRand() * 0.5
        sprayDir:Normalize()
        
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 10)
        eff:SetNormal(sprayDir)
        eff:SetScale(math.random(1, 3))
        util.Effect("HL2BloodSpray", eff)
    end
    
    -- Blood mist
    for i = 1, 3 * intensity do
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 20)
        eff:SetScale(0.5)
        util.Effect("cball_bounce", eff)
    end
end

-- Create blood pool on ground
function AA.Gore:SpawnBloodPool(pos, size)
    size = size or 1
    
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 50),
        endpos = pos - Vector(0, 0, 100),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        -- Multiple overlapping decals for pool effect
        for i = 1, 3 * size do
            local offset = VectorRand() * math.random(10, 40) * size
            local decalPos = tr.HitPos + offset
            local decalType = math.random() > 0.3 and "BloodLarge" or "Blood"
            
            util.Decal(decalType, decalPos + tr.HitNormal, decalPos - tr.HitNormal)
        end
        
        -- Add blood drip particles falling to ground
        for i = 1, 10 * size do
            local dripPos = pos + VectorRand() * 30
            local effect = EffectData()
            effect:SetOrigin(dripPos)
            effect:SetNormal(Vector(0,0,-1))
            effect:SetScale(0.5)
            util.Effect("bloodspray", effect)
        end
    end
end

-- Spawn gibs (meat chunks)
function AA.Gore:SpawnGibs(pos, count, velocity)
    count = math.min(count, AA.Gore.Config.MaxGibs)
    velocity = velocity or Vector(0,0,200)
    
    for i = 1, count do
        local gibModel = self.GibModels[math.random(1, #self.GibModels)]
        
        local gib = ents.Create("prop_physics")
        if IsValid(gib) then
            gib:SetModel(gibModel)
            gib:SetPos(pos + VectorRand() * 20)
            gib:SetAngles(AngleRand())
            gib:SetMaterial("models/flesh") -- Make it look like meat
            gib:SetColor(Color(150, 50, 50))
            gib:Spawn()
            
            -- Random velocity with upward bias
            local vel = velocity + VectorRand() * math.random(100, 400)
            vel.z = math.abs(vel.z) + math.random(100, 300)
            
            local phys = gib:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(vel)
                -- Add angular velocity safely
                local angVel = VectorRand() * math.random(200, 800)
                phys:AddAngleVelocity(angVel)
                phys:SetMaterial("flesh")
            end
            
            -- Leave blood trail as it flies
            local startTime = CurTime()
            hook.Add("Think", "GibBloodTrail_" .. gib:EntIndex(), function()
                if not IsValid(gib) then
                    hook.Remove("Think", "GibBloodTrail_" .. gib:EntIndex())
                    return
                end
                
                if CurTime() - startTime > 3 then
                    hook.Remove("Think", "GibBloodTrail_" .. gib:EntIndex())
                    return
                end
                
                -- Small chance to leave blood decal
                if math.random() < 0.1 then
                    local tr = util.TraceLine({
                        start = gib:GetPos(),
                        endpos = gib:GetPos() - Vector(0,0,20),
                        mask = MASK_SOLID,
                    })
                    if tr.Hit then
                        util.Decal("BloodSmall", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
                    end
                end
            end)
            
            -- Fade out and remove after 10 seconds
            timer.Simple(10, function()
                if IsValid(gib) then
                    -- Fade effect
                    local fadeTime = 2
                    local start = CurTime()
                    
                    hook.Add("Think", "GibFade_" .. gib:EntIndex(), function()
                        if not IsValid(gib) then
                            hook.Remove("Think", "GibFade_" .. gib:EntIndex())
                            return
                        end
                        
                        local progress = (CurTime() - start) / fadeTime
                        if progress >= 1 then
                            gib:Remove()
                            hook.Remove("Think", "GibFade_" .. gib:EntIndex())
                        else
                            local alpha = 255 * (1 - progress)
                            local col = gib:GetColor()
                            gib:SetColor(Color(col.r, col.g, col.b, alpha))
                        end
                    end)
                end
            end)
        end
    end
end

-- Massive death explosion (for elite/big enemies)
function AA.Gore:DeathExplosion(pos, intensity, isElite)
    intensity = intensity or 1
    
    -- Screen shake
    util.ScreenShake(pos, 5 * intensity, 15, 0.5, 1000)
    
    -- Blood explosion effects
    for i = 1, 20 * intensity do
        local angle = math.random() * math.pi * 2
        local dist = math.random(20, 100) * intensity
        local height = math.random(0, 80) * intensity
        local offset = Vector(
            math.cos(angle) * dist,
            math.sin(angle) * dist,
            height
        )
        
        local effect = EffectData()
        effect:SetOrigin(pos + offset)
        effect:SetScale(math.random(3, 6))
        util.Effect("BloodImpact", effect)
    end
    
    -- Blood spray upward (using vanilla HL2 effect)
    for i = 1, 10 * intensity do
        local eff = EffectData()
        eff:SetOrigin(pos)
        eff:SetNormal(Vector(0,0,1) + VectorRand() * 0.3)
        eff:SetScale(math.random(2, 5))
        util.Effect("bloodspray", eff)
    end
    
    -- Massive blood pool
    self:SpawnBloodPool(pos, 2 * intensity)
    
    -- Blood decals everywhere
    for i = 1, 20 * intensity do
        local angle = math.random() * math.pi * 2
        local dist = math.random(30, 200) * intensity
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
    
    -- Spawn gibs
    local gibCount = math.random(5, 10) * intensity
    if isElite then gibCount = gibCount * 2 end
    self:SpawnGibs(pos, gibCount, Vector(0,0,300))
    
    -- Sounds
    sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", pos, 85, math.random(70, 90), 1)
    sound.Play("ambient/explosions/exp" .. math.random(1,4) .. ".wav", pos, 80, math.random(90, 110), 0.8)
    
    -- Dynamic light flash
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "255 50 50 200")
        light:SetKeyValue("brightness", "10")
        light:SetKeyValue("distance", "512")
        light:SetPos(pos)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        light:Fire("Kill", "", 0.3)
    end
end

-- Chainsaw/melee hit effect
function AA.Gore:MeleeHitEffect(pos, normal, damage)
    -- Close-range blood spray
    for i = 1, 10 do
        local sprayDir = normal + VectorRand() * 0.8
        sprayDir:Normalize()
        
        local eff = EffectData()
        eff:SetOrigin(pos + VectorRand() * 5)
        eff:SetNormal(sprayDir)
        eff:SetScale(math.random(2, 4))
        util.Effect("bloodspray", eff)
    end
    
    -- Massive blood splatter on nearby surfaces
    for i = 1, 8 do
        local tr = util.TraceLine({
            start = pos,
            endpos = pos + VectorRand() * 100,
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
        end
    end
    
    -- Blood chunks
    self:SpawnGibs(pos, math.random(2, 4), normal * 200)
end

-- Wall splatter from projectile hits
function AA.Gore:WallSplatter(pos, normal, intensity)
    intensity = intensity or 1
    
    -- Main splatter
    for i = 1, 5 * intensity do
        local offset = normal * math.random(5, 30)
        local decalPos = pos + offset
        
        local tr = util.TraceLine({
            start = decalPos + normal * 10,
            endpos = decalPos - normal * 10,
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            local decalType = math.random() > 0.5 and "BloodLarge" or "Blood"
            util.Decal(decalType, tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
        end
    end
    
    -- Drip effect
    for i = 1, 3 * intensity do
        timer.Simple(math.random() * 0.5, function()
            local dripPos = pos + VectorRand() * 20
            local effect = EffectData()
            effect:SetOrigin(dripPos)
            effect:SetNormal(Vector(0,0,-1))
            effect:SetScale(0.5)
            util.Effect("bloodspray", effect)
        end)
    end
end

print("[Lambda Arcade] Ultra Gore System initialized")
