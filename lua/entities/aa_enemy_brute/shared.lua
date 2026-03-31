--[[
    Arcade Anomaly: Brute Enemy (Shared)
--]]

ENT.Base = "aa_enemy_base"

ENT.PrintName = "Brute"
ENT.Category = "Arcade Anomaly"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SharedInitialize()
    if self.BaseClass and self.BaseClass.SharedInitialize then
        self.BaseClass.SharedInitialize(self)
    end
    
    if AA and AA.Types then
        self.Archetype = AA.Types.Archetype.BRUTE
    end
end
