--[[
    Lambda Arcade: Base Enemy Entity (Server)
    Enhanced Animation & AI System with Search Behavior
--]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    -- Only set default model if one wasn't already set
    local currentModel = self:GetModel()
    if not currentModel or currentModel == "" then
        self:SetModel("models/Humans/Group01/male_07.mdl")
    end
    
    -- Call base nextbot initialize first
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
    
    -- Configure NextBot locomotion
    self.loco:SetStepHeight(35)
    self.loco:SetAcceleration(1500)
    self.loco:SetDeceleration(1000)
    self.loco:SetJumpHeight(60)
    
    -- Health
    self:SetHealth(100)
    self:SetMaxHealth(100)
    
    -- Network sync
    self:SetNW2Int("AnimState", 0)
    self:SetNW2Bool("IsElite", false)
    self:SetNW2Float("MoveSpeed", 0)
    
    -- Animation System
    self.AnimState = 0
    self.AnimStateTime = 0
    self.LastAnimState = -1
    self.CurrentSequence = -1
    self.DesiredPlaybackRate = 1.0
    
    -- Movement
    self.MoveSpeed = 200
    self.RunSpeed = 280
    self.WalkSpeed = 100
    self.CurrentSpeed = 0
    self.TargetSpeed = 0
    
    -- Combat Stats
    self.Damage = 15
    self.AttackRange = 64
    self.AttackCooldown = 0.8
    self.NextAttack = 0
    self.InAttack = false
    
    -- Rotation System - faster turning to face player
    self.CurrentYaw = self:GetAngles().yaw
    self.TargetYaw = self.CurrentYaw
    self.TurnSpeed = 720  -- 720 degrees per second = very fast turning
    
    -- Targeting & Search
    self.Target = nil
    self.LastTargetSearch = 0
    self.TargetSearchInterval = 0.3
    self.LoseTargetDist = 3000
    
    -- Search behavior
    self.SearchState = "none" -- none, chasing, searching, idle
    self.LastKnownTargetPos = Vector(0, 0, 0)
    self.LastSeenTargetTime = 0
    self.SearchStartTime = 0
    self.SearchPoints = {}
    self.CurrentSearchPoint = 1
    
    -- AI System
    self.AIClass = self.AIClass or "Chaser"
    self.AIInitialized = false
    
    -- Initialize animation
    self:SetupAnimation()
    
    -- Initialize AI immediately
    self:InitializeAI()
end

function ENT:SetupAnimation()
    self.AvailableSequences = nil
    self:CacheAvailableSequences()
    
    if self:HasAnimations() then
        local idleSeq = self:GetSequenceForState(0)
        if idleSeq >= 0 then
            self:SetSequence(idleSeq)
            self.CurrentSequence = idleSeq
        end
    end
end

function ENT:CacheAvailableSequences()
    if self.AvailableSequences then return self.AvailableSequences end
    
    self.AvailableSequences = {
        idle = {}, move = {}, attack = {}, pain = {}, death = {}, any = {}
    }
    
    local seqCount = self:GetSequenceCount()
    for i = 0, seqCount - 1 do
        local name = string.lower(self:GetSequenceName(i) or "")
        table.insert(self.AvailableSequences.any, i)
        
        if string.find(name, "idle") or string.find(name, "stand") then
            table.insert(self.AvailableSequences.idle, i)
        elseif string.find(name, "run") or string.find(name, "walk") then
            table.insert(self.AvailableSequences.move, i)
        elseif string.find(name, "attack") or string.find(name, "melee") then
            table.insert(self.AvailableSequences.attack, i)
        elseif string.find(name, "pain") or string.find(name, "flinch") then
            table.insert(self.AvailableSequences.pain, i)
        elseif string.find(name, "death") then
            table.insert(self.AvailableSequences.death, i)
        end
    end
    
    return self.AvailableSequences
end

function ENT:HasAnimations()
    return self.AvailableSequences and #self.AvailableSequences.any > 0
end

function ENT:GetSequenceForState(state)
    local seqs = {}
    if state == 0 then
        seqs = {"idle_all", "idle", "Idle", "IDLE", "stand", "reference"}
    elseif state == 1 then
        seqs = {"run_all", "run", "Run", "walk_all", "walk", "Walk"}
    elseif state == 2 then
        seqs = {"run_all", "run", "sprint"}
    elseif state == 3 then
        seqs = {"melee", "attack", "swing", "slash"}
    elseif state == 4 then
        seqs = {"pain", "flinch", "hurt"}
    elseif state == 5 then
        seqs = {"death", "die"}
    else
        return -1
    end
    
    for _, name in ipairs(seqs) do
        local id = self:LookupSequence(name)
        if id and id >= 0 then return id end
    end
    
    return -1
end

function ENT:SetAnimState(state)
    if self.AnimState ~= state then
        self.AnimState = state
        self.AnimStateTime = CurTime()
        self:SetNW2Int("AnimState", state)
        
        local seq = self:GetSequenceForState(state)
        if seq >= 0 then
            self.CurrentSequence = seq
            self:SetSequence(seq)
            self:ResetSequenceInfo()
        end
    end
end

function ENT:SetTargetYaw(targetPos)
    local dir = targetPos - self:GetPos()
    dir.z = 0
    if dir:LengthSqr() > 0.01 then
        self.TargetYaw = dir:Angle().yaw
    end
end

function ENT:UpdateRotation(dt)
    local diff = math.AngleDifference(self.TargetYaw, self.CurrentYaw)
    local maxTurn = self.TurnSpeed * dt
    
    if math.abs(diff) > maxTurn then
        diff = (diff > 0) and maxTurn or -maxTurn
    end
    
    self.CurrentYaw = self.CurrentYaw + diff
    self:SetAngles(Angle(0, self.CurrentYaw, 0))
end

-- Main Think
function ENT:Think()
    local dt = FrameTime()
    
    -- Smooth speed transition
    self.CurrentSpeed = math.Approach(
        self.CurrentSpeed,
        self.TargetSpeed,
        (self.CurrentSpeed < self.TargetSpeed and 400 or 800) * dt
    )
    
    -- Apply to locomotion
    if self.loco then
        self.loco:SetDesiredSpeed(self.CurrentSpeed)
    end
    
    -- Update rotation
    self:UpdateRotation(dt)
    
    -- Update animation rate
    if self.CurrentSpeed > 10 and self.AnimState == 1 then
        local rate = self.CurrentSpeed / self.MoveSpeed
        self:SetPlaybackRate(math.Clamp(rate, 0.8, 1.5))
    else
        self:SetPlaybackRate(1.0)
    end
    
    self:SetNW2Float("MoveSpeed", self.CurrentSpeed)
    
    -- Stuck detection
    self:CheckStuck()
    
    self:NextThink(CurTime())
    return true
end

function ENT:CheckStuck()
    if not self.StuckCheckTime then
        self.StuckCheckTime = 0
        self.LastStuckPos = self:GetPos()
        self.StuckCounter = 0
    end
    
    if CurTime() - self.StuckCheckTime < 0.5 then return end
    self.StuckCheckTime = CurTime()
    
    local dist = self:GetPos():DistToSqr(self.LastStuckPos)
    
    if self.TargetSpeed > 50 and dist < 100 then
        self.StuckCounter = (self.StuckCounter or 0) + 1
        
        if self.StuckCounter > 3 then
            self:Unstuck()
            self.StuckCounter = 0
        end
    else
        self.StuckCounter = 0
    end
    
    self.LastStuckPos = self:GetPos()
end

function ENT:Unstuck()
    if self.loco and self.loco:IsOnGround() then
        self.loco:Jump()
    end
    
    local vel = self:GetVelocity()
    vel.z = 300
    self:SetVelocity(vel)
    
    local nudge = Vector(math.random(-50, 50), math.random(-50, 50), 0)
    self:SetPos(self:GetPos() + nudge)
end

-- Main NextBot behaviour loop
function ENT:RunBehaviour()
    if not self.AIInitialized then
        self:InitializeAI()
    end
    
    self.CurrentYaw = self:GetAngles().yaw
    self.TargetYaw = self.CurrentYaw
    
    -- Main loop - this MUST use coroutine.wait() to work properly
    while true do
        if not IsValid(self) then return end
        
        -- Get target with LOS check
        local target, hasLOS = self:GetTargetPlayerWithLOS()
        
        if IsValid(target) then
            if hasLOS then
                self.SearchState = "chasing"
                self:ChaseTarget(target)
            else
                self.SearchState = "searching"
                self:SearchForTarget(target)
            end
        else
            -- No target - idle
            self.SearchState = "idle"
            self:SetAnimState(0)
            self.TargetSpeed = 0
            coroutine.wait(0.5)
        end
    end
end

function ENT:ChaseTarget(target)
    local distSqr = self:GetPos():DistToSqr(target:GetPos())
    local attackRangeSqr = (self.AttackRange or 64) ^ 2
    
    if distSqr <= attackRangeSqr then
        -- In attack range
        if CurTime() >= self.NextAttack and not self.InAttack then
            -- Check if AI wants to handle attack
            if self.AIClass and AA.AI and AA.AI[self.AIClass] and AA.AI[self.AIClass].OnAttack then
                if AA.AI[self.AIClass]:OnAttack(self, target) then
                    coroutine.wait(0.1)
                    return
                end
            end
            self:PerformAttack(target)
        else
            -- Face target and wait
            self:SetAnimState(0)
            self.TargetSpeed = 0
            self:SetTargetYaw(target:GetPos())
            coroutine.wait(0.1)
        end
    else
        -- Chase
        self:SetAnimState(1)
        self.TargetSpeed = self.RunSpeed
        
        -- ALWAYS face target aggressively
        local targetPos = target:GetPos()
        self:SetTargetYaw(targetPos)
        if self.loco then
            self.loco:FaceTowards(targetPos)
        end
        
        -- Use navigation if available
        if AA.Navigation then
            AA.Navigation:Update(self, targetPos, self.RunSpeed)
        else
            if self.loco then
                self.loco:Approach(targetPos, self.RunSpeed)
                self.loco:SetDesiredSpeed(self.RunSpeed)
            end
        end
        
        coroutine.wait(0.05)
    end
end

function ENT:SearchForTarget(target)
    local now = CurTime()
    
    -- Initialize search if just started
    if now - self.LastSeenTargetTime > 0.5 then
        if self.SearchStartTime == 0 then
            self.SearchStartTime = now
            self:GenerateSearchPoints()
        end
        
        -- Search for up to 10 seconds
        if now - self.SearchStartTime > 10 then
            -- Give up
            self.Target = nil
            self.SearchState = "idle"
            self.SearchStartTime = 0
            return
        end
        
        -- Look around search points
        local searchPoint = self.SearchPoints[self.CurrentSearchPoint]
        if searchPoint then
            local distToPoint = self:GetPos():DistToSqr(searchPoint)
            
            if distToPoint < 2500 then -- Within 50 units
                -- Reached point, look around
                self:SetAnimState(0)
                self.TargetSpeed = 0
                
                -- Look left
                self.TargetYaw = self.CurrentYaw - 45
                coroutine.wait(0.8)
                
                -- Look right  
                if IsValid(self) then
                    self.TargetYaw = self.CurrentYaw + 90
                    coroutine.wait(0.8)
                end
                
                -- Next point
                self.CurrentSearchPoint = self.CurrentSearchPoint + 1
            else
                -- Move to search point
                self:SetAnimState(1)
                self.TargetSpeed = self.MoveSpeed * 0.7 -- Walk while searching
                self:SetTargetYaw(searchPoint)
                
                if AA.Navigation then
                    AA.Navigation:Update(self, searchPoint, self.MoveSpeed * 0.7)
                else
                    if self.loco then
                        self.loco:Approach(searchPoint, self.MoveSpeed * 0.7)
                        self.loco:SetDesiredSpeed(self.MoveSpeed * 0.7)
                    end
                end
                
                coroutine.wait(0.1)
            end
        else
            -- No more points, give up
            self.Target = nil
            self.SearchState = "idle"
            self.SearchStartTime = 0
        end
    else
        -- Just lost sight, go to last known position
        self:SetAnimState(1)
        self.TargetSpeed = self.RunSpeed
        self:SetTargetYaw(self.LastKnownTargetPos)
        
        if AA.Navigation then
            AA.Navigation:Update(self, self.LastKnownTargetPos, self.RunSpeed)
        else
            if self.loco then
                self.loco:Approach(self.LastKnownTargetPos, self.RunSpeed)
                self.loco:SetDesiredSpeed(self.RunSpeed)
            end
        end
        
        coroutine.wait(0.05)
    end
end

function ENT:GenerateSearchPoints()
    self.SearchPoints = {}
    self.CurrentSearchPoint = 1
    
    local basePos = self.LastKnownTargetPos
    if basePos:LengthSqr() == 0 then
        basePos = self:GetPos() + self:GetForward() * 200
    end
    
    -- Generate 3-5 search points around last known position
    local numPoints = math.random(3, 5)
    for i = 1, numPoints do
        local angle = (i / numPoints) * math.pi * 2
        local dist = math.random(100, 300)
        local offset = Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
        
        local point = basePos + offset
        
        -- Make sure it's on ground
        local tr = util.TraceLine({
            start = point + Vector(0, 0, 100),
            endpos = point - Vector(0, 0, 200),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            point = tr.HitPos + Vector(0, 0, 10)
        end
        
        table.insert(self.SearchPoints, point)
    end
end

function ENT:InitializeAI()
    -- Initialize base AI
    if AA.AI and AA.AI.Base and AA.AI.Base.Initialize then
        AA.AI.Base.Initialize(AA.AI.Base, self)
    end
    
    -- Initialize archetype-specific AI
    if AA.AI and self.AIClass and AA.AI[self.AIClass] and AA.AI[self.AIClass].Initialize then
        AA.AI[self.AIClass].Initialize(AA.AI[self.AIClass], self)
    end
    
    self.AIInitialized = true
end

-- Get target with line of sight check
function ENT:GetTargetPlayerWithLOS()
    local now = CurTime()
    
    -- Find nearest player
    local players = player.GetAll()
    local bestTarget = nil
    local bestDist = math.huge
    local myPos = self:GetPos()
    
    for _, ply in ipairs(players) do
        if IsValid(ply) and ply:Alive() then
            local dist = myPos:DistToSqr(ply:GetPos())
            if dist < bestDist and dist < (self.LoseTargetDist * self.LoseTargetDist) then
                bestDist = dist
                bestTarget = ply
            end
        end
    end
    
    -- Check if we had a target but lost LOS
    if IsValid(self.Target) and IsValid(bestTarget) and self.Target ~= bestTarget then
        -- Check LOS to current target first
        if self:HasLineOfSight(self.Target) then
            bestTarget = self.Target
        end
    end
    
    -- Check LOS to best target
    local hasLOS = false
    if IsValid(bestTarget) then
        hasLOS = self:HasLineOfSight(bestTarget)
        
        if hasLOS then
            -- Can see target - update tracking
            self.LastKnownTargetPos = bestTarget:GetPos()
            self.LastSeenTargetTime = now
            self.SearchStartTime = 0 -- Reset search
        end
    end
    
    self.Target = bestTarget
    return bestTarget, hasLOS
end

function ENT:HasLineOfSight(target)
    if not IsValid(target) then return false end
    
    local trace = util.TraceLine({
        start = self:WorldSpaceCenter(),
        endpos = target:WorldSpaceCenter(),
        mask = MASK_SOLID,
        filter = self,
    })
    
    return not trace.Hit or trace.Entity == target
end

-- Old function for compatibility
function ENT:GetTargetPlayer()
    local target, _ = self:GetTargetPlayerWithLOS()
    return target
end

function ENT:PerformAttack(target)
    if not IsValid(target) or self.InAttack then return end
    
    -- Check if AI wants to override
    if AA and AA.AI and self.AIClass then
        local aiClass = AA.AI[self.AIClass]
        if aiClass and aiClass.OnAttack then
            if aiClass:OnAttack(self, target) then
                return
            end
        end
    end
    
    -- Default attack
    self.InAttack = true
    self.NextAttack = CurTime() + (self.AttackCooldown or 1.0)
    
    self:SetAnimState(3)
    self.TargetSpeed = 0
    
    local windup = self.AttackWindup or 0.2
    coroutine.wait(windup)
    
    if not IsValid(self) or not IsValid(target) then
        self.InAttack = false
        return
    end
    
    local distSqr = self:GetPos():DistToSqr(target:GetPos())
    local attackRange = (self.AttackRange or 64) * 1.5
    
    if distSqr <= attackRange * attackRange then
        local toTarget = (target:GetPos() - self:GetPos()):GetNormalized()
        self:SetVelocity(toTarget * 150 + Vector(0, 0, 50))
        
        local dmg = DamageInfo()
        dmg:SetDamage(self.Damage or 10)
        dmg:SetDamageType(DMG_SLASH)
        dmg:SetAttacker(self)
        dmg:SetInflictor(self)
        target:TakeDamageInfo(dmg)
        
        self:SpawnBloodEffect(target:GetPos())
    end
    
    coroutine.wait(0.3)
    self.InAttack = false
end

function ENT:SpawnBloodEffect(pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(2)
    util.Effect("BloodImpact", effect)
    
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 10),
        endpos = pos - Vector(0, 0, 50),
        mask = MASK_SOLID,
    })
    
    if tr.Hit then
        util.Decal("Blood", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end
end

function ENT:OnTakeDamage(dmg)
    if self:Health() <= 0 then return end
    
    local damage = dmg:GetDamage()
    local attacker = dmg:GetAttacker()
    
    -- Notify AI about damage
    if self.AIClass and AA.AI and AA.AI[self.AIClass] and AA.AI[self.AIClass].OnTakeDamage then
        local handled = AA.AI[self.AIClass]:OnTakeDamage(self, dmg, attacker)
        if handled then return end
    end
    
    -- Spawn blood
    self:SpawnBloodEffect(dmg:GetDamagePosition())
    
    -- Dispatch enhanced hit FX if available
    if AA and AA.FX and AA.FX.DispatchHit then
        AA.FX.DispatchHit(dmg:GetDamagePosition(), "blood", damage, attacker)
    end
    
    -- Check death
    if self:Health() <= damage then
        self:Die(attacker)
        return
    end
    
    -- Apply damage
    self:SetHealth(self:Health() - damage)
    
    -- Update AI last damage time
    if self.AIData then
        self.AIData.lastDamageTime = CurTime()
    end
    
    -- Pain animation
    self:SetAnimState(4)
    timer.Simple(0.3, function()
        if IsValid(self) then self:SetAnimState(0) end
    end)
    
    -- Stagger effect on heavy hits
    if damage >= 25 and self.loco then
        self.loco:SetVelocity((dmg:GetDamageForce() or Vector(0,0,0)) * 0.1)
    end
    
    -- Switch target if damaged by someone else
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= self.Target then
        local myPos = self:GetPos()
        local currentDist = math.huge
        if IsValid(self.Target) then
            local targetPos = self.Target:GetPos()
            if targetPos then
                currentDist = myPos:DistTo(targetPos)
            end
        end
        
        local attackerPos = attacker:GetPos()
        if attackerPos then
            local newDist = myPos:DistTo(attackerPos)
            
            -- Switch if new attacker is significantly closer
            if newDist < currentDist * 0.6 then
                self.Target = attacker
            end
        end
    end
    
    self.LastAttacker = attacker
end

-- Loot drop system
function ENT:DropLoot()
    local lootChance = 0.3
    
    if self.Archetype == 3 then lootChance = 0.5
    elseif self.Archetype == 6 then lootChance = 0.7
    elseif self.IsElite then lootChance = 0.6
    end
    
    if math.random() > lootChance then return end
    
    local pos = self:GetPos() + Vector(0, 0, 30)
    local dropType = math.random(1, 3)
    
    if dropType == 1 then
        local amount = math.random(10, 25)
        if self.Archetype == 3 then amount = math.random(25, 50) end
        if self.Archetype == 6 then amount = math.random(50, 100) end
        self:SpawnHealthPickup(pos, amount)
    elseif dropType == 2 then
        local amount = math.random(10, 25)
        if self.Archetype == 3 then amount = math.random(25, 50) end
        self:SpawnArmorPickup(pos, amount)
    else
        self:SpawnAmmoPickup(pos)
    end
end

function ENT:SpawnHealthPickup(pos, amount)
    local ent = ents.Create("item_healthvial")
    if IsValid(ent) then
        ent:SetPos(pos)
        ent:Spawn()
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), 100))
        end
        
        ent.AA_HealthAmount = amount
    end
end

function ENT:SpawnArmorPickup(pos, amount)
    local ent = ents.Create("item_battery")
    if IsValid(ent) then
        ent:SetPos(pos)
        ent:Spawn()
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), 100))
        end
        
        ent.AA_ArmorAmount = amount
    end
end

function ENT:SpawnAmmoPickup(pos)
    local ammoTypes = {"item_ammo_pistol", "item_ammo_smg1", "item_ammo_ar2", "item_box_buckshot"}
    local ammoClass = ammoTypes[math.random(1, #ammoTypes)]
    
    local ent = ents.Create(ammoClass)
    if IsValid(ent) then
        ent:SetPos(pos)
        ent:Spawn()
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), 100))
        end
    end
end

function ENT:Die(attacker)
    -- Check if AI wants to override
    if AA and AA.AI and self.AIClass then
        local aiClass = AA.AI[self.AIClass]
        if aiClass and aiClass.OnDeath then
            if aiClass:OnDeath(self, attacker) then
                return
            end
        end
    end
    
    -- ULTRA GORE DEATH EFFECTS
    if AA and AA.Gore then
        -- Different gore based on archetype and death type
        local intensity = 1
        if self.Archetype == 3 then intensity = 1.5 -- Brutes
        elseif self.Archetype == 6 then intensity = 2 -- Elites
        elseif self.IsElite then intensity = 1.8
        end
        
        -- Death explosion with gibs and blood everywhere
        AA.Gore:DeathExplosion(self:WorldSpaceCenter(), intensity, self.IsElite)
    end
    
    -- Drop loot using enhanced system
    if AA and AA.Loot then
        AA.Loot:DropFromEnemy(self, attacker)
    else
        -- Fallback to old system
        self:DropLoot()
    end
    
    -- Score
    if AA and AA.ScoreManager then
        AA.ScoreManager:OnEnemyKilled(self, attacker)
    end
    
    -- Legacy FX dispatch for client effects
    if AA and AA.FX and AA.FX.DispatchDeath then
        AA.FX.DispatchDeath(self:WorldSpaceCenter(), self.IsElite, attacker)
    end
    
    -- Create ragdoll with blood
    self:CreateRagdoll()
    
    -- Remove
    self:Remove()
end

function ENT:CreateRagdoll()
    local model = self:GetModel()
    if not model or model == "" then return end
    
    model = "models/player/skeleton.mdl"
    
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return end
    
    rag:SetModel(model)
    rag:SetPos(self:GetPos())
    rag:SetAngles(self:GetAngles())
    rag:Spawn()
    
    if not IsValid(rag) then return end
    
    rag:Activate()
    
    -- ULTRA BLOOD ON RAGDOLL
    local bloodIntensity = self.IsElite and 8 or 5
    for i = 1, bloodIntensity do
        local effect = EffectData()
        local offset = Vector(
            math.random(-30, 30), 
            math.random(-30, 30), 
            math.random(10, 60)
        )
        effect:SetOrigin(rag:GetPos() + offset)
        effect:SetScale(math.Rand(1, 2.5))
        util.Effect("BloodImpact", effect)
        
        -- Additional blood squirt for elites
        if self.IsElite and i <= 3 then
            local squirt = EffectData()
            squirt:SetOrigin(rag:GetPos() + offset)
            squirt:SetNormal(VectorRand())
            squirt:SetScale(2)
            util.Effect("bloodspray", squirt)
        end
    end
    
    -- Transfer velocity with more chaos
    local velocityMult = self.IsElite and 2 or 1
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            phys:SetVelocity(self:GetVelocity() + VectorRand() * (50 * velocityMult))
            phys:AddAngleVelocity(VectorRand() * (200 * velocityMult))
        end
    end
    
    -- Copy properties
    rag:SetMaterial(self:GetMaterial())
    rag:SetColor(self:GetColor())
    
    -- ENHANCED BLOOD TRAIL EFFECT
    local trailCount = self.IsElite and 20 or 12
    local trailInterval = self.IsElite and 0.3 or 0.5
    timer.Create("BloodTrail_" .. rag:EntIndex(), trailInterval, trailCount, function()
        if IsValid(rag) then
            -- Multiple blood impacts for trail
            for i = 1, (self.IsElite and 3 or 2) do
                local effect = EffectData()
                local trailOffset = Vector(
                    math.random(-20, 20), 
                    math.random(-20, 20), 
                    math.random(5, 40)
                )
                effect:SetOrigin(rag:GetPos() + trailOffset)
                effect:SetScale(math.Rand(0.8, 1.5))
                util.Effect("BloodImpact", effect)
            end
            
            -- Blood spray
            if math.random() < 0.4 then
                local spray = EffectData()
                spray:SetOrigin(rag:GetPos() + Vector(0, 0, 20))
                spray:SetNormal(VectorRand())
                spray:SetScale(1.5)
                util.Effect("bloodspray", spray)
            end
            
            -- Blood pool underneath
            local tr = util.TraceLine({
                start = rag:GetPos() + Vector(0, 0, 10),
                endpos = rag:GetPos() - Vector(0, 0, 50),
                mask = MASK_SOLID
            })
            
            if tr.Hit then
                util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
            end
        end
    end)
    
    -- Remove after delay (longer for elites)
    local removeDelay = self.IsElite and 25 or 15
    timer.Simple(removeDelay, function()
        if IsValid(rag) then
            timer.Remove("BloodTrail_" .. rag:EntIndex())
            
            -- Fade out effect
            local fadeAlpha = 255
            timer.Create("RagFade_" .. rag:EntIndex(), 0.1, 20, function()
                if IsValid(rag) then
                    fadeAlpha = fadeAlpha - 12
                    rag:SetColor(Color(255, 255, 255, math.max(0, fadeAlpha)))
                    if fadeAlpha <= 0 then
                        rag:Remove()
                    end
                end
            end)
        end
    end)
end
