--[[
    Arcade Anomaly: Shooter Projectile
--]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/weapons/w_bugbait.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(false)
        phys:SetMass(1)
    end
    
    self.Damage = 15
    self.Speed = 1800
    self.LifeTime = CurTime() + 3
    
    -- Launch towards target
    if IsValid(self.Target) then
        local targetVel = self.Target:GetVelocity()
        local dist = self:GetPos():DistTo(self.Target:GetPos())
        local lead = targetVel * (dist / self.Speed) * 0.6
        local aimPos = self.Target:WorldSpaceCenter() + lead
        local dir = (aimPos - self:GetPos()):GetNormalized()
        
        phys:SetVelocity(dir * self.Speed)
        self:SetAngles(dir:Angle())
    else
        phys:SetVelocity(self:GetForward() * self.Speed)
    end
    
    -- Trail
    util.SpriteTrail(self, 0, Color(100, 200, 255), false, 6, 1, 0.3, 0.5, "trails/laser.vmt")
    
    -- Muzzle flash
    local effect = EffectData()
    effect:SetOrigin(self:GetPos())
    effect:SetNormal(self:GetForward())
    util.Effect("MuzzleEffect", effect)
end

function ENT:Think()
    if CurTime() > self.LifeTime then
        self:Remove()
        return
    end
    
    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    local hitEnt = data.HitEntity
    
    if IsValid(hitEnt) and hitEnt:IsPlayer() then
        local dmg = DamageInfo()
        dmg:SetDamage(self.Damage or 15)
        dmg:SetDamageType(DMG_ENERGYBEAM)
        dmg:SetAttacker(self.Owner or self)
        dmg:SetInflictor(self)
        hitEnt:TakeDamageInfo(dmg)
        
        -- Blood
        local effect = EffectData()
        effect:SetOrigin(data.HitPos)
        effect:SetScale(1)
        util.Effect("BloodImpact", effect)
    end
    
    -- Impact effect
    local effect = EffectData()
    effect:SetOrigin(data.HitPos)
    effect:SetNormal(data.HitNormal)
    util.Effect("cball_explode", effect)
    
    self:Remove()
end
