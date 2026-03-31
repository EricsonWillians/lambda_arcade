--[[
    Arcade Anomaly: Exploder Enemy
    Explodes on contact or death
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self.Archetype = 5 -- EXPLODER
    self.AIClass = "Exploder"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.EXPLODER
        
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.4
        
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = 80
        self.AttackCooldown = 0.1
        self.ScoreValue = balance.ScoreValue
    else
        self:SetHealth(70)
        self:SetMaxHealth(70)
        self.MoveSpeed = 220
        self.RunSpeed = 320
        self.Damage = 60
        self.AttackRange = 80
        self.AttackCooldown = 0.1
        self.ScoreValue = 250
    end
    
    self.ExplosionRadius = 200
    self.HasExploded = false
end

function ENT:Explode()
    if self.HasExploded then return end
    self.HasExploded = true
    
    local pos = self:GetPos()
    local radius = self.ExplosionRadius
    
    -- Damage
    for _, victim in ipairs(ents.FindInSphere(pos, radius)) do
        if IsValid(victim) and (victim:IsPlayer() or victim.Archetype) and victim ~= self then
            local dist = victim:GetPos():DistTo(pos)
            local falloff = 1 - math.min(dist / radius, 1)
            
            local dmg = DamageInfo()
            dmg:SetDamage(70 * falloff)
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(self)
            dmg:SetInflictor(self)
            victim:TakeDamageInfo(dmg)
        end
    end
    
    -- Effects
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetMagnitude(4)
    effect:SetScale(3)
    util.Effect("Explosion", effect)
    
    sound.Play("ambient/explosions/exp" .. math.random(2, 4) .. ".wav", pos, 90, 100, 1)
    util.ScreenShake(pos, 8, 15, 0.6, 1000)
    
    self:Remove()
end

function ENT:OnTakeDamage(dmg)
    -- Explode on death
    if self:Health() <= dmg:GetDamage() then
        self:DropLoot()
        self:Explode()
        return
    end
    
    -- Call base
    self.BaseClass.OnTakeDamage(self, dmg)
end
