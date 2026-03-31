--[[
    Arcade Anomaly: Elite AI
    Enhanced enemy
--]]

AA.AI.Elite = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Elite:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 250
    ent.RunSpeed = ent.RunSpeed or 320
    ent.AttackRange = ent.AttackRange or 96
    ent.AttackCooldown = ent.AttackCooldown or 0.5
    ent.AttackWindup = ent.AttackWindup or 0.15
    ent.Damage = ent.Damage or 40
end
