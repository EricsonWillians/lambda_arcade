--[[
    Arcade Anomaly: Brute AI
    Slow heavy enemy
--]]

AA.AI.Brute = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Brute:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 130
    ent.RunSpeed = ent.RunSpeed or 180
    ent.AttackRange = ent.AttackRange or 90
    ent.AttackCooldown = ent.AttackCooldown or 1.5
    ent.AttackWindup = ent.AttackWindup or 0.4
    ent.Damage = ent.Damage or 35
end
