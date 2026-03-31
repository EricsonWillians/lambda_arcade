--[[
    Arcade Anomaly: Exploder AI
    Explodes on contact or death
--]]

AA.AI.Exploder = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Exploder:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 220
    ent.RunSpeed = ent.RunSpeed or 320
    ent.AttackRange = ent.AttackRange or 80
    ent.AttackCooldown = ent.AttackCooldown or 0.1
    ent.Damage = ent.Damage or 60
    ent.ExplosionRadius = 200
end

-- Override attack to explode
function AA.AI.Exploder:OnAttack(ent, target)
    if ent.Explode then
        ent:Explode()
    end
    return true
end

-- Override death to explode
function AA.AI.Exploder:OnDeath(ent, attacker)
    if ent.Explode then
        ent:Explode()
    end
    return true
end
