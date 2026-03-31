--[[
    Lambda Arcade: Enhanced Exploder AI
    Fragile enemy that charges at players and explodes on contact or death
--]]

AA.AI.Exploder = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Exploder:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Exploder-specific stats
    ent.MoveSpeed = ent.MoveSpeed or 160
    ent.RunSpeed = ent.RunSpeed or 260
    ent.SprintSpeed = ent.SprintSpeed or 350
    ent.AttackRange = ent.AttackRange or 50 -- Explosion range
    ent.Damage = ent.Damage or 40
    ent.ExplosionRadius = ent.ExplosionRadius or 250
    ent.FuseTime = ent.FuseTime or 0.5 -- Time before explosion after triggering
    ent.Health = math.min(ent:Health(), 50) -- Fragile
    
    -- AI data
    ent.AIData.primed = false
    ent.AIData.primeTime = 0
    ent.AIData.isCharging = false
    ent.AIData.beepInterval = 0.5
    ent.AIData.lastBeep = 0
    ent.AIData.chainReactionRadius = 300 -- Can trigger other exploders
end

function AA.AI.Exploder:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local now = CurTime()
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local dist = math.sqrt(distSqr)
    local explosionRange = (ent.AttackRange or 50)
    
    -- Handle primed state (about to explode)
    if data.primed then
        -- Beep faster as fuse runs out
        local fuseProgress = (now - data.primeTime) / (ent.FuseTime or 0.5)
        local beepRate = math.max(0.05, 0.3 * (1 - fuseProgress))
        
        if now - data.lastBeep > beepRate then
            data.lastBeep = now
            self:Beep(ent, 1 + fuseProgress) -- Louder as it gets closer
        end
        
        -- Check if fuse complete
        if now >= data.primeTime + (ent.FuseTime or 0.5) then
            self:Explode(ent)
        end
        
        -- Keep moving toward target while primed
        ent:SetAnimState(2) -- Sprint
        ent.TargetSpeed = ent.SprintSpeed or 350
        
        if AA.Navigation then
            AA.Navigation:Update(ent, targetPos, ent.SprintSpeed or 350)
        else
            ent.loco:Approach(targetPos, ent.SprintSpeed or 350)
            ent.loco:SetDesiredSpeed(ent.SprintSpeed or 350)
        end
        
        return
    end
    
    -- Check for chain reaction from nearby exploding exploders
    if self:CheckChainReaction(ent) then
        self:PrimeExplosion(ent)
        return
    end
    
    -- Combat logic
    if dist <= explosionRange then
        -- In explosion range - prime and explode
        self:PrimeExplosion(ent)
    elseif dist <= explosionRange * 2 then
        -- Close - charge at high speed
        data.isCharging = true
        ent:SetAnimState(2)
        ent.TargetSpeed = ent.SprintSpeed or 350
        
        if AA.Navigation then
            AA.Navigation:Update(ent, targetPos, ent.SprintSpeed or 350)
        else
            ent.loco:Approach(targetPos, ent.SprintSpeed or 350)
            ent.loco:SetDesiredSpeed(ent.SprintSpeed or 350)
        end
    else
        -- Further away - approach normally
        data.isCharging = false
        ent:SetAnimState(1)
        ent.TargetSpeed = ent.RunSpeed or 260
        
        if AA.Navigation then
            AA.Navigation:Update(ent, targetPos, ent.RunSpeed or 260)
        else
            ent.loco:Approach(targetPos, ent.RunSpeed or 260)
            ent.loco:SetDesiredSpeed(ent.RunSpeed or 260)
        end
    end
end

function AA.AI.Exploder:CheckChainReaction(ent)
    local myPos = ent:GetPos()
    local nearby = ents.FindInSphere(myPos, ent.AIData.chainReactionRadius)
    
    for _, other in ipairs(nearby) do
        if other ~= ent and other:GetClass():find("exploder") then
            local otherData = other.AIData
            if otherData and otherData.primed then
                -- Another exploder is about to blow - chain react
                return true
            end
        end
    end
    
    return false
end

function AA.AI.Exploder:PrimeExplosion(ent)
    local data = ent.AIData
    
    if data.primed then return end
    
    data.primed = true
    data.primeTime = CurTime()
    data.lastBeep = CurTime()
    
    -- Visual warning
    ent:SetColor(Color(255, 100, 100))
    
    -- Initial beep
    self:Beep(ent, 1)
    
    -- Visual effect
    if AA.FX and AA.FX.DispatchEffect then
        AA.FX.DispatchEffect(ent:GetPos(), "exploder_prime")
    end
end

function AA.AI.Exploder:Beep(ent, intensity)
    local pitch = 100 + (intensity * 50)
    ent:EmitSound("buttons/blip1.wav", 75, pitch, 0.5)
    
    -- Flash effect
    timer.Simple(0.05, function()
        if IsValid(ent) then
            ent:SetColor(Color(255, 255, 255))
            timer.Simple(0.05, function()
                if IsValid(ent) then
                    ent:SetColor(Color(255, 100, 100))
                end
            end)
        end
    end)
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
                elseif hitEnt:GetClass():find("enemy") and hitEnt ~= ent then
                    -- Damage other enemies (but less)
                    hitEnt:TakeDamage(finalDamage * 0.5, attacker or ent, ent)
                end
            end
        end
    end
    
    -- Create scorch mark
    local tr = util.TraceLine({
        start = myPos + Vector(0, 0, 10),
        endpos = myPos - Vector(0, 0, 50),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end
    
    -- Remove self
    ent:Remove()
end

function AA.AI.Exploder:OnAttack(ent, target)
    -- Override normal attack with explosion
    self:PrimeExplosion(ent)
    return true -- Override default
end

function AA.AI.Exploder:OnDeath(ent, attacker)
    -- Explode on death
    if ent.AIData and not ent.AIData.primed then
        self:Explode(ent, attacker)
    end
    return true -- Override default death
end

function AA.AI.Exploder:OnTakeDamage(ent, dmg, attacker)
    -- Prime explosion when damaged below threshold
    if ent:Health() - dmg:GetDamage() <= 15 then
        self:PrimeExplosion(ent)
    end
    
    return AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
end

print("[Lambda Arcade] Enhanced Exploder AI initialized")
