--[[
    Arcade Anomaly: Rusher AI
    Fast enemy with burst speed
--]]

AA.AI.Rusher = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Rusher:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 220
    ent.RunSpeed = ent.RunSpeed or 350
    ent.AttackRange = ent.AttackRange or 60
    ent.AttackCooldown = ent.AttackCooldown or 0.6
    ent.AttackWindup = ent.AttackWindup or 0.15
    ent.Damage = ent.Damage or 12
end
