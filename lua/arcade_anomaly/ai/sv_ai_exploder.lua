--[[
    Lambda Arcade: Enhanced Exploder AI
    Fragile enemy that explodes on contact or death
--]]

AA.AI.Exploder = {}

function AA.AI.Exploder:Initialize(ent)
    -- Exploder-specific stats
    ent.FuseTime = ent.FuseTime or 0.5
    
    -- AI data
    if ent.AIData then
        ent.AIData.primed = false
        ent.AIData.primeTime = 0
    end
end

function AA.AI.Exploder:OnAttack(ent, target)
    -- Prime for explosion when in range
    local data = ent.AIData
    if data and not data.primed then
        data.primed = true
        data.primeTime = CurTime()
        ent:SetColor(Color(255, 100, 100))
    end
    
    return true -- Override default attack
end

function AA.AI.Exploder:OnDeath(ent, attacker)
    -- Explode on death
    local data = ent.AIData
    if data and not data.primed then
        -- Call explode function after short delay
        timer.Simple(0, function()
            if IsValid(ent) then
                self:Explode(ent, attacker)
            end
        end)
    end
    
    return true -- Override default death
end

function AA.AI.Exploder:Explode(ent, attacker)
    if not IsValid(ent) then return end
    
    local myPos = ent:GetPos()
    local radius = ent.ExplosionRadius or 250
    local damage = ent.Damage or 40
    
    -- Visual effect
    local effect = EffectData()
    effect:SetOrigin(myPos)
    effect:SetRadius(radius)
    util.Effect("Explosion", effect)
    
    -- Screen shake
    util.ScreenShake(myPos, 10, 5, 1, radius * 2)
    
    -- Sound
    ent:EmitSound("weapons/explode" .. math.random(3, 5) .. ".wav", 85, 100)
    
    -- Damage entities
    local nearby = ents.FindInSphere(myPos, radius)
    
    for _, hitEnt in ipairs(nearby) do
        if hitEnt ~= ent then
            local dist = hitEnt:GetPos():DistTo(myPos)
            local falloff = math.max(0, 1 - (dist / radius))
            local finalDamage = damage * falloff
            
            if finalDamage > 0 then
                if hitEnt:IsPlayer() then
                    local dmg = DamageInfo()
                    dmg:SetDamage(finalDamage)
                    dmg:SetDamageType(DMG_BLAST)
                    dmg:SetAttacker(attacker or ent)
                    dmg:SetInflictor(ent)
                    
                    -- Knockback
                    local knockDir = (hitEnt:GetPos() - myPos):GetNormalized()
                    knockDir.z = 0.3
                    dmg:SetDamageForce(knockDir * finalDamage * 10)
                    
                    hitEnt:TakeDamageInfo(dmg)
                end
            end
        end
    end
    
    -- Remove self
    ent:Remove()
end

function AA.AI.Exploder:OnTakeDamage(ent, dmg, attacker)
    -- Prime explosion when damaged below threshold
    if ent:Health() - dmg:GetDamage() <= 15 then
        local data = ent.AIData
        if data and not data.primed then
            data.primed = true
            data.primeTime = CurTime()
        end
    end
    
    return false
end

print("[Lambda Arcade] Enhanced Exploder AI initialized")
