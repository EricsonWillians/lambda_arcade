--[[
    Arcade Anomaly: Elite Enemy
    Powerful enemy with special abilities and enhanced AI
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self.Archetype = 6 -- ELITE
    self.AIClass = "Elite"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.ELITE
        
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.2
        
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = balance.AttackRange
        self.AttackCooldown = balance.AttackCooldown
        self.ScoreValue = balance.ScoreValue
    else
        self:SetHealth(650)
        self:SetMaxHealth(650)
        self.MoveSpeed = 230
        self.RunSpeed = 280
        self.Damage = 40
        self.AttackRange = 96
        self.AttackCooldown = 0.6
        self.ScoreValue = 1000
    end
    
    -- Elite appearance
    self:SetColor(Color(180, 100, 255))
end
