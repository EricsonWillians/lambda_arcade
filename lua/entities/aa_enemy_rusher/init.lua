--[[
    Arcade Anomaly: Rusher Enemy
    Fast enemy with burst speed ability
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self.Archetype = 2 -- RUSHER
    self.AIClass = "Rusher"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.RUSHER
        
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        -- Fast movement
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.5
        
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = balance.AttackRange
        self.AttackCooldown = balance.AttackCooldown
        self.ScoreValue = balance.ScoreValue
    else
        self:SetHealth(80)
        self:SetMaxHealth(80)
        self.MoveSpeed = 220
        self.RunSpeed = 380
        self.Damage = 12
        self.AttackRange = 60
        self.AttackCooldown = 0.6
        self.ScoreValue = 150
    end
end
