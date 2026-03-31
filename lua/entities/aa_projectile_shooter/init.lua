--[[
    Arcade Anomaly: ULTRA VISIBLE Shooter Projectile
    
    Severely enhanced visibility with bright colors, large models, and trail effects.
    Players should NEVER miss seeing these coming.
--]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    -- Use a VERY visible model - energy ball
    self:SetModel("models/Items/combine_rifle_ammo01.mdl")
    
    -- Use smaller collision box for fair gameplay (visual size separate)
    self:PhysicsInitSphere(8, "default_silent")  -- Small 8-unit sphere collision
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    -- Large visual size for visibility, but separate from collision
    self:SetModelScale(2.5)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(false)
        phys:SetMass(1)
    end
    
    self.Damage = 15
    self.Speed = 1800
    self.LifeTime = CurTime() + 3
    
    -- Launch towards target with prediction
    if IsValid(self.Target) then
        local targetVel = self.Target:GetVelocity()
        local dist = self:GetPos():Distance(self.Target:GetPos())
        local lead = targetVel * (dist / self.Speed) * 0.6
        local aimPos = self.Target:WorldSpaceCenter() + lead
        local dir = (aimPos - self:GetPos()):GetNormalized()
        
        phys:SetVelocity(dir * self.Speed)
        self:SetAngles(dir:Angle())
    else
        phys:SetVelocity(self:GetForward() * self.Speed)
    end
    
    -- ULTRA VISIBLE TRAIL - thick, bright, long-lasting
    util.SpriteTrail(self, 0, Color(100, 200, 255), false, 
        20,  -- Start width (visible but not huge)
        6,   -- End width
        0.4, -- Lifetime
        0.5, -- Texture scale
        "trails/laser.vmt"
    )
    
    -- Secondary red trail for contrast
    util.SpriteTrail(self, 0, Color(255, 100, 100), false,
        12,
        3,
        0.3,
        0.5,
        "trails/plasma.vmt"
    )
    
    -- Bright dynamic light
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "100 200 255 255")
        light:SetKeyValue("brightness", "8")
        light:SetKeyValue("distance", "256")
        light:SetParent(self)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        self.Light = light
    end
    
    -- Muzzle flash
    local effect = EffectData()
    effect:SetOrigin(self:GetPos())
    effect:SetNormal(self:GetForward())
    effect:SetScale(3)
    util.Effect("MuzzleEffect", effect)
    
    -- Loud spawn sound
    sound.Play("weapons/ar2/npc_ar2_altfire.wav", self:GetPos(), 85, 100, 1)
end

function ENT:Think()
    if CurTime() > self.LifeTime then
        self:Remove()
        return
    end
    
    -- Update light position
    if IsValid(self.Light) then
        self.Light:SetPos(self:GetPos())
    end
    
    -- Spark effects while flying
    if math.random() < 0.3 then
        local effect = EffectData()
        effect:SetOrigin(self:GetPos())
        effect:SetNormal(VectorRand())
        effect:SetScale(1)
        util.Effect("cball_bounce", effect)
    end
    
    -- Proximity check for players (for smoother hit detection)
    -- Only check if physics collision didn't catch it
    local pos = self:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local dist = pos:Distance(ply:GetPos())
            if dist < 40 then  -- Close enough to count as hit
                -- Apply damage
                local dmg = DamageInfo()
                dmg:SetDamage(self.Damage or 15)
                dmg:SetDamageType(DMG_ENERGYBEAM)
                dmg:SetAttacker(self.Owner or self)
                dmg:SetInflictor(self)
                ply:TakeDamageInfo(dmg)
                
                -- Effects
                local effect = EffectData()
                effect:SetOrigin(ply:GetPos())
                effect:SetScale(2)
                util.Effect("BloodImpact", effect)
                
                -- Remove projectile
                if IsValid(self.Light) then
                    self.Light:Remove()
                end
                self:Remove()
                return
            end
        end
    end
    
    self:NextThink(CurTime() + 0.05)
    return true
end

function ENT:PhysicsCollide(data, phys)
    local hitEnt = data.HitEntity
    local hitPos = data.HitPos
    
    if IsValid(hitEnt) and hitEnt:IsPlayer() then
        local dmg = DamageInfo()
        dmg:SetDamage(self.Damage or 15)
        dmg:SetDamageType(DMG_ENERGYBEAM)
        dmg:SetAttacker(self.Owner or self)
        dmg:SetInflictor(self)
        hitEnt:TakeDamageInfo(dmg)
        
        -- Blood effect
        local effect = EffectData()
        effect:SetOrigin(hitPos)
        effect:SetScale(2)
        util.Effect("BloodImpact", effect)
    end
    
    -- MASSIVE impact effect
    local effect = EffectData()
    effect:SetOrigin(hitPos)
    effect:SetNormal(data.HitNormal)
    effect:SetScale(4)
    util.Effect("cball_explode", effect)
    
    -- Secondary explosion
    local exp = EffectData()
    exp:SetOrigin(hitPos)
    exp:SetMagnitude(2)
    util.Effect("Explosion", exp)
    
    -- Impact sound
    sound.Play("weapons/ar2/ar2_altfire.wav", hitPos, 80, math.random(90, 110), 1)
    
    -- Remove light
    if IsValid(self.Light) then
        self.Light:Remove()
    end
    
    self:Remove()
end

function ENT:OnRemove()
    if IsValid(self.Light) then
        self.Light:Remove()
    end
end
