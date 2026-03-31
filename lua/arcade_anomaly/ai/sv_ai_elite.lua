--[[
    Lambda Arcade: Enhanced Elite AI
    Enhanced enemy that combines abilities from other types with unique elite modifiers
--]]

AA.AI.Elite = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Elite:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    -- Elite stats - significantly boosted
    ent.MoveSpeed = ent.MoveSpeed or 200
    ent.RunSpeed = ent.RunSpeed or 300
    ent.AttackRange = ent.AttackRange or 80
    ent.AttackCooldown = ent.AttackCooldown or 0.6 -- Faster attacks
    ent.AttackWindup = ent.AttackWindup or 0.15
    ent.Damage = ent.Damage or 25
    ent.Health = (ent:Health() or 100) * 1.5
    ent:SetMaxHealth(ent.Health)
    ent:SetHealth(ent.Health)
    
    -- Elite abilities
    ent.AIData.canPhase = true -- Brief invulnerability dash
    ent.AIData.canSummon = true -- Summon weaker minions
    ent.AIData.canRage = true -- Speed up when damaged
    ent.AIData.canHeal = true -- Regenerate health
    
    -- Cooldowns
    ent.AIData.phaseCooldown = 0
    ent.AIData.summonCooldown = 0
    ent.AIData.healCooldown = 0
    ent.AIData.rageTriggered = false
    
    -- Combat tracking
    ent.AIData.comboCounter = 0
    ent.AIData.maxCombo = 4
    ent.AIData.specialReady = true
end

function AA.AI.Elite:Think(ent)
    AA.AI.Base.Think(self, ent)
    
    local data = ent.AIData
    local target = ent.Target
    
    if not IsValid(target) then return end
    
    local now = CurTime()
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local distSqr = myPos:DistToSqr(targetPos)
    local dist = math.sqrt(distSqr)
    
    -- Health-based abilities
    local healthPercent = ent:Health() / ent:GetMaxHealth()
    
    -- Trigger rage at 50% health
    if healthPercent <= 0.5 and not data.rageTriggered and data.canRage then
        self:EnterRageMode(ent)
    end
    
    -- Regenerate health if not damaged recently
    if data.canHeal and now > (data.lastDamageTime or 0) + 5 and healthPercent < 1.0 then
        if now > data.healCooldown then
            self:RegenerateHealth(ent)
            data.healCooldown = now + 2 -- Heal every 2 seconds
        end
    end
    
    -- Use phase ability when in danger
    if data.canPhase and now > data.phaseCooldown then
        if healthPercent < 0.3 and math.random() < 0.3 then
            self:PhaseDash(ent, target)
            return
        end
    end
    
    -- Summon minions occasionally
    if data.canSummon and now > data.summonCooldown then
        if healthPercent < 0.7 and math.random() < 0.2 then
            self:SummonMinions(ent)
            data.summonCooldown = now + 15
        end
    end
    
    -- Combat logic
    local attackRangeSqr = (ent.AttackRange or 80) ^ 2
    
    if distSqr <= attackRangeSqr then
        -- In melee range
        if now >= (data.lastAttackTime or 0) + (ent.AttackCooldown or 0.6) then
            self:PerformEliteAttack(ent, target)
        else
            -- Elite combo - multiple quick attacks
            if data.comboCounter < data.maxCombo then
                self:PerformEliteAttack(ent, target)
            else
                -- Reset combo and dodge
                data.comboCounter = 0
                self:Evade(ent, target)
            end
        end
    else
        -- Outside range - aggressive chase with teleport
        ent:SetAnimState(2)
        ent.TargetSpeed = ent.RunSpeed or 300
        
        -- Occasional teleport closer
        if dist > 500 and data.specialReady and now > data.phaseCooldown then
            self:TeleportCloser(ent, target)
        end
        
        if AA.Navigation then
            AA.Navigation:Update(ent, targetPos, ent.RunSpeed or 300)
        else
            ent.loco:Approach(targetPos, ent.RunSpeed or 300)
            ent.loco:SetDesiredSpeed(ent.RunSpeed or 300)
            ent.loco:FaceTowards(targetPos)
        end
    end
end

function AA.AI.Elite:EnterRageMode(ent)
    local data = ent.AIData
    data.rageTriggered = true
    
    -- Visual and audio cue
    ent:SetColor(Color(255, 50, 50))
    ent:EmitSound("npc/zombie/zombie_alert" .. math.random(1, 3) .. ".wav", 85, 80)
    
    -- Boost stats
    ent.RunSpeed = (ent.RunSpeed or 300) * 1.3
    ent.AttackCooldown = (ent.AttackCooldown or 0.6) * 0.7
    ent.Damage = (ent.Damage or 25) * 1.2
    
    -- Effect
    if AA.FX and AA.FX.DispatchEffect then
        AA.FX.DispatchEffect(ent:GetPos(), "elite_rage")
    end
end

function AA.AI.Elite:RegenerateHealth(ent)
    local healAmount = ent:GetMaxHealth() * 0.05 -- 5% per tick
    local newHealth = math.min(ent:GetMaxHealth(), ent:Health() + healAmount)
    ent:SetHealth(newHealth)
    
    -- Visual heal effect
    local effect = EffectData()
    effect:SetOrigin(ent:GetPos())
    effect:SetScale(1)
    util.Effect("cball_bounce", effect)
end

function AA.AI.Elite:PhaseDash(ent, target)
    local data = ent.AIData
    
    data.phaseCooldown = CurTime() + 8 -- 8 second cooldown
    
    -- Direction to target
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local dir = (targetPos - myPos):GetNormalized()
    dir.z = 0
    
    -- Dash through target to flank
    local dashPos = targetPos + dir * 150
    
    -- Validate position
    local tr = util.TraceLine({
        start = dashPos + Vector(0, 0, 100),
        endpos = dashPos - Vector(0, 0, 200),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        dashPos = tr.HitPos + Vector(0, 0, 10)
        
        -- Phase effect at current position
        local effect = EffectData()
        effect:SetOrigin(myPos)
        util.Effect("cball_explode", effect)
        
        -- Teleport
        ent:SetPos(dashPos)
        
        -- Phase effect at new position
        effect:SetOrigin(dashPos)
        util.Effect("cball_explode", effect)
        
        -- Brief invulnerability
        ent.AIData.invulnerable = true
        timer.Simple(0.5, function()
            if IsValid(ent) then ent.AIData.invulnerable = nil end
        end)
    end
end

function AA.AI.Elite:TeleportCloser(ent, target)
    local data = ent.AIData
    
    data.specialReady = false
    data.phaseCooldown = CurTime() + 5
    
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local dir = (targetPos - myPos):GetNormalized()
    
    -- Teleport to just outside attack range
    local teleportDist = (ent.AttackRange or 80) + 50
    local teleportPos = targetPos - dir * teleportDist
    
    -- Validate
    local tr = util.TraceLine({
        start = teleportPos + Vector(0, 0, 100),
        endpos = teleportPos - Vector(0, 0, 200),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        teleportPos = tr.HitPos + Vector(0, 0, 10)
        
        -- Teleport effect
        local effect = EffectData()
        effect:SetOrigin(myPos)
        util.Effect("cball_explode", effect)
        
        ent:SetPos(teleportPos)
        
        effect:SetOrigin(teleportPos)
        util.Effect("cball_explode", effect)
    end
    
    -- Reset special after cooldown
    timer.Simple(10, function()
        if IsValid(ent) then
            ent.AIData.specialReady = true
        end
    end)
end

function AA.AI.Elite:SummonMinions(ent)
    local myPos = ent:GetPos()
    
    -- Visual effect
    local effect = EffectData()
    effect:SetOrigin(myPos)
    effect:SetScale(2)
    util.Effect("cball_bounce", effect)
    
    ent:EmitSound("npc/zombie/zombie_voice_idle" .. math.random(1, 6) .. ".wav", 75, 60)
    
    -- Summon 2-3 weak chasers
    local numMinions = math.random(2, 3)
    
    for i = 1, numMinions do
        timer.Simple(i * 0.3, function()
            if not IsValid(ent) then return end
            
            local offset = Vector(math.random(-100, 100), math.random(-100, 100), 0)
            local spawnPos = myPos + offset
            
            -- Ground the spawn position
            local tr = util.TraceLine({
                start = spawnPos + Vector(0, 0, 100),
                endpos = spawnPos - Vector(0, 0, 200),
                mask = MASK_SOLID,
            })
            
            if tr.Hit then
                spawnPos = tr.HitPos + Vector(0, 0, 10)
                
                -- Spawn minion
                local minion = ents.Create("aa_enemy_chaser")
                if IsValid(minion) then
                    minion:SetPos(spawnPos)
                    minion:SetHealth(30) -- Weak
                    minion:SetMaxHealth(30)
                    minion.Damage = 8
                    minion:Spawn()
                    
                    -- Visual spawn effect
                    local minionEffect = EffectData()
                    minionEffect:SetOrigin(spawnPos)
                    util.Effect("cball_explode", minionEffect)
                end
            end
        end)
    end
end

function AA.AI.Elite:PerformEliteAttack(ent, target)
    local data = ent.AIData
    
    data.lastAttackTime = CurTime()
    data.comboCounter = (data.comboCounter or 0) + 1
    
    ent:SetAnimState(3)
    ent.TargetSpeed = 0
    ent.InAttack = true
    
    -- Quick lunge
    if IsValid(target) and ent.loco then
        local toTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        ent.loco:SetVelocity(toTarget * 250 + Vector(0, 0, 50))
    end
    
    -- Deal damage after short windup
    timer.Simple(ent.AttackWindup or 0.15, function()
        if not IsValid(ent) or not IsValid(target) then
            ent.InAttack = false
            return
        end
        
        local distSqr = ent:GetPos():DistToSqr(target:GetPos())
        local range = (ent.AttackRange or 80) * 1.3
        
        if distSqr <= range * range then
            local dmg = DamageInfo()
            dmg:SetDamage(ent.Damage or 25)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(ent)
            dmg:SetInflictor(ent)
            target:TakeDamageInfo(dmg)
            
            -- Apply brief slow to target
            target.AA_Slowed = true
            timer.Simple(1.0, function()
                if IsValid(target) then target.AA_Slowed = nil end
            end)
        end
        
        timer.Simple(0.2, function()
            if IsValid(ent) then ent.InAttack = false end
        end)
    end)
end

function AA.AI.Elite:Evade(ent, target)
    if not ent.loco then return end
    
    local data = ent.AIData
    local myPos = ent:GetPos()
    local targetPos = target:GetPos()
    local awayDir = (myPos - targetPos):GetNormalized()
    
    -- Dodge to side
    local lateral = Vector(-awayDir.y, awayDir.x, 0) * (data.strafeDirection or 1)
    local dodgePos = myPos + lateral * 150 + awayDir * 100
    
    ent:SetAnimState(2)
    ent.TargetSpeed = ent.RunSpeed or 300
    
    ent.loco:Approach(dodgePos, ent.RunSpeed or 300)
    ent.loco:SetDesiredSpeed(ent.RunSpeed or 300)
end

function AA.AI.Elite:OnTakeDamage(ent, dmg, attacker)
    local data = ent.AIData
    
    -- Check invulnerability
    if data.invulnerable then
        return true -- Block damage
    end
    
    data.lastDamageTime = CurTime()
    
    -- Counter-attack chance
    if math.random() < 0.25 then
        timer.Simple(0.2, function()
            if IsValid(ent) and IsValid(attacker) then
                ent.Target = attacker
                self:PhaseDash(ent, attacker)
            end
        end)
    end
    
    return AA.AI.Base.OnTakeDamage(self, ent, dmg, attacker)
end

function AA.AI.Elite:OnDeath(ent, attacker)
    -- Explosion on death
    local myPos = ent:GetPos()
    local effect = EffectData()
    effect:SetOrigin(myPos)
    effect:SetRadius(150)
    util.Effect("Explosion", effect)
    
    -- Damage nearby
    local nearby = ents.FindInSphere(myPos, 150)
    for _, hit in ipairs(nearby) do
        if hit:IsPlayer() then
            local dmg = DamageInfo()
            dmg:SetDamage(20)
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(ent)
            hit:TakeDamageInfo(dmg)
        end
    end
    
    return false -- Let base handle normal death
end

print("[Lambda Arcade] Enhanced Elite AI initialized")
