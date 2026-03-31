--[[
    Arcade Anomaly: Brute Enemy
    Slow, heavy enemy with powerful attacks and knockback
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self.Archetype = 3 -- BRUTE
    self.AIClass = "Brute"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.BRUTE
        
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        -- Slow but powerful
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.2
        
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = balance.AttackRange
        self.AttackCooldown = balance.AttackCooldown
        self.ScoreValue = balance.ScoreValue
    else
        self:SetHealth(250)
        self:SetMaxHealth(250)
        self.MoveSpeed = 110
        self.RunSpeed = 170
        self.Damage = 40
        self.AttackRange = 90
        self.AttackCooldown = 1.8
        self.ScoreValue = 300
    end
    
    -- Larger collision for brute
    self:SetCollisionBounds(Vector(-20, -20, 0), Vector(20, 20, 80))
    
    -- Slow turn speed for heavy feel
    self.TurnSpeed = 120
    
    -- Enrage state
    self.IsEnraged = false
end

function ENT:OnTakeDamage(dmg)
    -- Brutes get enraged at low health
    local healthPercent = self:Health() / self:GetMaxHealth()
    
    if healthPercent < 0.3 and not self.IsEnraged then
        self.IsEnraged = true
        self.RunSpeed = self.RunSpeed * 1.3
        self.Damage = self.Damage * 1.2
        
        -- Enrage effect
        self:SetColor(Color(255, 80, 80))
        
        self:EmitSound("npc/antlion_guard/angry3.wav", 85, 90, 1)
        
        local effect = EffectData()
        effect:SetOrigin(self:WorldSpaceCenter())
        effect:SetScale(2)
        util.Effect("cball_explode", effect)
    end
    
    -- Call base damage handling
    self.BaseClass.OnTakeDamage(self, dmg)
end
