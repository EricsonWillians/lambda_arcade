--[[
    Arcade Anomaly: Elite Enemy (Shared)
--]]

ENT.Base = "aa_enemy_base"

ENT.PrintName = "Elite"
ENT.Category = "Arcade Anomaly"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SharedInitialize()
    if self.BaseClass and self.BaseClass.SharedInitialize then
        self.BaseClass.SharedInitialize(self)
    end
    
    if AA and AA.Types then
        self.Archetype = AA.Types.Archetype.ELITE
    end
    self.IsElite = true
end
