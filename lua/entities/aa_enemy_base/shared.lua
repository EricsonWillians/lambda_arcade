--[[
    Arcade Anomaly: Base Enemy Entity (Shared)
--]]

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

ENT.PrintName = "Arcade Anomaly Enemy"
ENT.Author = "Arcade Anomaly"
ENT.Category = "Arcade Anomaly"

ENT.Spawnable = false
ENT.AdminSpawnable = false

-- Properties that will be networked
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Archetype")
    self:NetworkVar("Bool", 0, "IsElite")
    self:NetworkVar("Float", 0, "HealthFraction")
end

-- Shared initialization
function ENT:SharedInitialize()
    self.Archetype = 1 -- CHASER default
    self.IsElite = false
    self.ScoreValue = 100
    self.DamageMult = 1.0
end
