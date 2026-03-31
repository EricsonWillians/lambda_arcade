--[[
    Lambda Arcade: Enhanced Brute AI
    Slow but powerful tank with charge ability and crowd control
--]]

AA.AI.Brute = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Brute:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Brute-specific stats
    ent.MoveSpeed = ent.MoveSpeed or 100
    ent.RunSpeed = ent.RunSpeed or 180
    ent.ChargeSpeed = ent.ChargeSpeed or 400
    ent.AttackRange = ent.AttackRange or 90
    ent.AttackCooldown = ent.AttackCooldown or 1.5
    ent.AttackWindup = ent.AttackWindup or 0.4
    ent.Damage = ent.Damage or 35
    ent.KnockbackPower = ent.KnockbackPower or 300
    
    -- Charge ability
    ent.AIData.chargeCooldown = 0
    ent.AIData.chargeTarget = nil
    ent.AIData.isCharging = false
    ent.AIData.chargeEndTime = 0
    ent.AIData.chargeHitEntities = {}
    ent.AIData.groundSlamReady = true
end

function AA.AI.Brute:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local now = CurTime()
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local dist = math.sqrt(distSqr)
    local attackRangeSqr = (ent.AttackRange or 90) ^ 2
    
    -- Handle charge state
    if data.isCharging then
        if now > data.chargeEndTime then
            -- Charge ended
            data.isCharging = false
            data.chargeCooldown = now + 6 -- 6 second cooldown
            ent:SetAnimState(0)
            
            -- Ground slam at end of charge
            if data.groundSlamReady then
                self:GroundSlam(ent)
            end
        else
            -- Continue charging
            self:ContinueCharge(ent)
        end
        return
    end
    
    -- Combat logic
    if distSqr <= attackRangeSqr then
        -- In melee range - heavy attack
        if now >= (data.lastAttackTime or 0) + (ent.AttackCooldown or 1.5) then
            self:PerformHeavyAttack(ent, target)
        else
            -- Face target and prepare
            ent:SetAnimState(0)
            ent.TargetSpeed = 0
            if ent.loco then
                ent.loco:FaceTowards(targetPos)
            end
        end
    else
        -- Outside range - approach or charge
        local canCharge = now > data.chargeCooldown and not data.isCharging
        local shouldCharge = canCharge and dist > 300 and dist < 800
        
        if shouldCharge and self:HasClearChargePath(ent, target) then
            -- Initiate charge
            self:StartCharge(ent, target)
        else
            -- Normal slow approach
            ent:SetAnimState(1)
            ent.TargetSpeed = ent.RunSpeed or 180
            
            if AA.Navigation then
                AA.Navigation:Update(ent, targetPos, ent.RunSpeed or 180)
            else
                ent.loco:Approach(targetPos, ent.RunSpeed or 180)
                ent.loco:SetDesiredSpeed(ent.RunSpeed or 180)
                ent.loco:FaceTowards(targetPos)
            end
        end
    end
end

function AA.AI.Brute:HasClearChargePath(ent, target)
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local dir = (targetPos - myPos):GetNormalized()
    
    -- Check if path is relatively clear
    local trace = util.TraceHull({
        start = myPos + Vector(0, 0, 36),
        endpos = myPos + Vector(0, 0, 36) + dir * 600,
        mins = Vector(-24, -24, 0),
        maxs = Vector(24, 24, 48),
        filter = ent,
        mask = MASK_SOLID,
    })
    
    -- Path is clear if we can get close to target
    return not trace.Hit or trace.Fraction > 0.7
end

function AA.AI.Brute:StartCharge(ent, target)
    local data = ent.AIData
    
    data.isCharging = true
    data.chargeTarget = target
    data.chargeEndTime = CurTime() + 3.0 -- 3 second charge
    data.chargeHitEntities = {}
    
    -- Windup animation
    ent:SetAnimState(0)
    ent.TargetSpeed = 0
    
    -- Visual warning
    if AA.FX and AA.FX.DispatchEffect then
        AA.FX.DispatchEffect(ent:GetPos(), "charge_windup")
    end
    
    -- Delayed charge start
    timer.Simple(0.5, function()
        if not IsValid(ent) then return end
        ent:SetAnimState(2) -- Sprint animation
        ent.TargetSpeed = ent.ChargeSpeed or 400
    end)
end

function AA.AI.Brute:ContinueCharge(ent)
    local data = ent.AIData
    if not data.chargeTarget then return end
    
    -- Move in charge direction
    local chargeDir = (data.chargeTarget:GetPos() - ent:GetPos()):GetNormalized()
    chargeDir.z = 0
    chargeDir:Normalize()
    
    ent.TargetSpeed = ent.ChargeSpeed or 400
    
    if ent.loco then
        -- Override normal movement with charge momentum
        ent.loco:SetVelocity(chargeDir * (ent.ChargeSpeed or 400))
        ent.loco:FaceTowards(ent:GetPos() + chargeDir * 100)
    end
    
    -- Damage anything in path
    self:CheckChargeCollisions(ent, chargeDir)
end

function AA.AI.Brute:CheckChargeCollisions(ent, direction)
    local data = ent.AIData
    local myPos = ent:GetPos()
    
    -- Find entities in charge path
    local nearby = ents.FindInBox(
        myPos - Vector(40, 40, 0),
        myPos + Vector(40, 40, 72)
    )
    
    for _, hitEnt in ipairs(nearby) do
        if hitEnt ~= ent and not data.chargeHitEntities[hitEnt] then
            if hitEnt:IsPlayer() and hitEnt:Alive() then
                data.chargeHitEntities[hitEnt] = true
                
                -- Deal charge damage with knockback
                local dmg = DamageInfo()
                dmg:SetDamage((ent.Damage or 35) * 1.5)
                dmg:SetDamageType(DMG_CRUSH)
                dmg:SetAttacker(ent)
                dmg:SetInflictor(ent)
                
                -- Add knockback
                local knockbackDir = (hitEnt:GetPos() - myPos):GetNormalized()
                knockbackDir.z = 0.3
                dmg:SetDamageForce(knockbackDir * (ent.KnockbackPower or 300))
                
                hitEnt:TakeDamageInfo(dmg)
                hitEnt:SetVelocity(knockbackDir * (ent.KnockbackPower or 300))
                
            elseif hitEnt:GetClass():find("enemy") and hitEnt ~= ent then
                -- Push other enemies aside (but don't damage allies)
                local pushDir = (hitEnt:GetPos() - myPos):GetNormalized()
                hitEnt:SetVelocity(pushDir * 200 + Vector(0, 0, 100))
            end
        end
    end
end

function AA.AI.Brute:PerformHeavyAttack(ent, target)
    local data = ent.AIData
    
    data.lastAttackTime = CurTime()
    ent:SetAnimState(3)
    ent.TargetSpeed = 0
    ent.InAttack = true
    
    -- Windup
    if ent.loco then
        ent.loco:FaceTowards(target:GetPos())
    end
    
    timer.Simple(ent.AttackWindup or 0.4, function()
        if not IsValid(ent) then 
            ent.InAttack = false
            return 
        end
        
        -- Heavy swing damage in arc
        local myPos = ent:GetPos()
        local myAngles = ent:GetAngles()
        
        -- Find all targets in attack arc
        local nearby = ents.FindInSphere(myPos, (ent.AttackRange or 90) * 1.2)
        
        for _, hitEnt in ipairs(nearby) do
            if hitEnt:IsPlayer() and hitEnt:Alive() then
                -- Check angle (60 degree arc in front)
                local toTarget = (hitEnt:GetPos() - myPos):GetNormalized()
                local forward = myAngles:Forward()
                local angleDiff = math.deg(math.acos(forward:Dot(toTarget)))
                
                if angleDiff < 60 then
                    local dmg = DamageInfo()
                    dmg:SetDamage(ent.Damage or 35)
                    dmg:SetDamageType(DMG_CLUB)
                    dmg:SetAttacker(ent)
                    dmg:SetInflictor(ent)
                    
                    -- Knockback
                    local knockbackDir = toTarget
                    knockbackDir.z = 0.2
                    dmg:SetDamageForce(knockbackDir * (ent.KnockbackPower or 300))
                    hitEnt:TakeDamageInfo(dmg)
                    hitEnt:SetVelocity(knockbackDir * (ent.KnockbackPower or 300))
                end
            end
        end
        
        timer.Simple(0.4, function()
            if IsValid(ent) then ent.InAttack = false end
        end)
    end)
end

function AA.AI.Brute:GroundSlam(ent)
    local myPos = ent:GetPos()
    
    -- Screen shake effect
    if AA.FX and AA.FX.DispatchEffect then
        AA.FX.DispatchEffect(myPos, "ground_slam")
    end
    
    -- Damage and slow nearby enemies
    local nearby = ents.FindInSphere(myPos, 300)
    
    for _, hitEnt in ipairs(nearby) do
        if hitEnt:IsPlayer() and hitEnt:Alive() then
            local dmg = DamageInfo()
            dmg:SetDamage(15)
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(ent)
            dmg:SetInflictor(ent)
            hitEnt:TakeDamageInfo(dmg)
            
            -- Apply slow (handled by effect system or external)
            hitEnt.AA_Slowed = true
            timer.Simple(2.0, function()
                if IsValid(hitEnt) then hitEnt.AA_Slowed = nil end
            end)
        end
    end
end

function AA.AI.Brute:OnTakeDamage(ent, dmg, attacker)
    AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
    
    -- Rage mechanic - speed up when damaged
    local healthPercent = ent:Health() / ent:GetMaxHealth()
    if healthPercent < 0.5 then
        ent.RunSpeed = 180 * (1.5 - healthPercent) -- Up to 50% faster
    end
end

print("[Lambda Arcade] Enhanced Brute AI initialized")
