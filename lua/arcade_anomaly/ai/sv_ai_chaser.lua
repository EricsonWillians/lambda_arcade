--[[
    Arcade Anomaly: Chaser AI
    Basic melee enemy
--]]

AA.AI.Chaser = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Chaser:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 200
    ent.RunSpeed = ent.RunSpeed or 280
    ent.AttackRange = ent.AttackRange or 70
    ent.AttackCooldown = ent.AttackCooldown or 0.8
    ent.AttackWindup = ent.AttackWindup or 0.2
    ent.Damage = ent.Damage or 15
end
