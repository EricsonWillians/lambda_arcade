--[[
    Lambda Arcade: Enhanced Shooter AI
    Ranged enemy that maintains distance and fires visible projectiles
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

-- RANGED ATTACK - Fire projectile with warning and reduced accuracy
function AA.AI.Shooter:OnAttack(ent, target)
    if not IsValid(ent) or not IsValid(target) then return false end
    
    local data = ent.AIData
    if not data then return false end
    
    -- Check cooldown
    if CurTime() < (data.lastShotTime or 0) + (ent.AttackCooldown or 1.2) then
        return false -- Let default system handle waiting
    end
    
    -- Set attack state
    ent.InAttack = true
    data.lastShotTime = CurTime()
    ent.TargetSpeed = 0
    
    -- FACE TARGET AGGRESSIVELY - Keep facing during entire attack
    local targetPos = target:GetPos()
    ent:SetTargetYaw(targetPos)
    if ent.loco then
        ent.loco:FaceTowards(targetPos)
    end
    
    -- CHARGING PHASE - Visual warning before firing
    local chargeTime = 0.5
    
    -- Create charging effect and keep facing target
    for i = 1, 5 do
        if not IsValid(ent) or not IsValid(target) then
            ent.InAttack = false
            return true
        end
        
        -- Continuously face target during charge
        targetPos = target:GetPos()
        ent:SetTargetYaw(targetPos)
        if ent.loco then
            ent.loco:FaceTowards(targetPos)
        end
        
        -- Charging effect
        if i % 2 == 0 then
            local chargePos = ent:WorldSpaceCenter() + ent:GetForward() * 20
            local effect = EffectData()
            effect:SetOrigin(chargePos)
            effect:SetScale(2)
            util.Effect("cball_bounce", effect)
        end
        
        coroutine.wait(chargeTime / 5)
    end
    
    if not IsValid(ent) or not IsValid(target) then
        ent.InAttack = false
        return true
    end
    
    -- Face target one final time before firing
    targetPos = target:GetPos()
    ent:SetTargetYaw(targetPos)
    if ent.loco then
        ent.loco:FaceTowards(targetPos)
    end
    ent:SetAnimState(3) -- Attack animation
    
    -- FIRE PROJECTILE with poor accuracy
    self:FireProjectile(ent, target)
    
    -- Recovery time
    coroutine.wait(0.3)
    ent.InAttack = false
    
    return true -- We handled the attack
end

-- Fire a projectile at the target with inaccuracy
function AA.AI.Shooter:FireProjectile(ent, target)
    if not IsValid(ent) or not IsValid(target) then return end
    
    local startPos = ent:WorldSpaceCenter() + ent:GetForward() * 30 + Vector(0, 0, 10)
    
    -- Calculate aim with REDUCED ACCURACY (30% accuracy)
    local accuracy = 0.30
    local targetPos = target:WorldSpaceCenter()
    
    -- Add random spread based on accuracy
    local spread = VectorRand() * 100 * (1 - accuracy)
    targetPos = targetPos + spread
    
    -- Create projectile
    local projectile = ents.Create("aa_projectile_shooter")
    if IsValid(projectile) then
        projectile:SetPos(startPos)
        projectile:SetOwner(ent)
        projectile.Target = target
        projectile:Spawn()
        
        -- Sound
        sound.Play("weapons/ar2/npc_ar2_altfire.wav", startPos, 80, 100, 1)
    end
end

print("[Lambda Arcade] Enhanced Shooter AI initialized")
