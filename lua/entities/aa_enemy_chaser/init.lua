--[[
    Arcade Anomaly: Chaser Enemy
    Balanced melee fighter with moderate speed and damage
--]]

AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    -- Set archetype before base init
    self.Archetype = 1 -- CHASER
    self.AIClass = "Chaser"
    
    -- Call base initialize
    self.BaseClass.Initialize(self)
    
    -- Apply balance values
    if AA and AA.Balance then
        local balance = AA.Balance.Archetypes.CHASER
        
        -- Health
        local health = balance.Health[1] + math.random(0, balance.Health[2] - balance.Health[1])
        self:SetHealth(health)
        self:SetMaxHealth(health)
        
        -- Movement - balanced
        self.MoveSpeed = balance.Speed[1] + math.random(0, balance.Speed[2] - balance.Speed[1])
        self.RunSpeed = self.MoveSpeed * 1.3
        
        -- Combat
        self.Damage = balance.Damage[1] + math.random(0, balance.Damage[2] - balance.Damage[1])
        self.AttackRange = balance.AttackRange
        self.AttackCooldown = balance.AttackCooldown
        self.ScoreValue = balance.ScoreValue
    else
        -- Fallback values
        self:SetHealth(100)
        self:SetMaxHealth(100)
        self.MoveSpeed = 180
        self.RunSpeed = 280
        self.Damage = 15
        self.AttackRange = 70
        self.AttackCooldown = 0.8
        self.ScoreValue = 100
    end
end
