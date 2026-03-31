--[[
    Arcade Anomaly: Shooter Enemy
    Ranged enemy with projectile attacks
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self.Archetype = 4 -- SHOOTER
    self.AIClass = "Shooter"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.SHOOTER
        
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        -- Moderate speed
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.3
        
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = 900
        self.AttackCooldown = balance.AttackCooldown
        self.ScoreValue = balance.ScoreValue
    else
        self:SetHealth(90)
        self:SetMaxHealth(90)
        self.MoveSpeed = 130
        self.RunSpeed = 180
        self.Damage = 14
        self.AttackRange = 900
        self.AttackCooldown = 1.0
        self.ScoreValue = 200
    end
end
