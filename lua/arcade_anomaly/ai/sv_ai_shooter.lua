--[[
    Arcade Anomaly: Shooter AI
    Ranged enemy
--]]

AA.AI.Shooter = setmetatable({}, { __index = AA.AI.Base })

function AA.AI.Shooter:Initialize(ent)
    AA.AI.Base.Initialize(self, ent)
    
    ent.MoveSpeed = ent.MoveSpeed or 150
    ent.RunSpeed = ent.RunSpeed or 200
    ent.AttackRange = ent.AttackRange or 800
    ent.AttackCooldown = ent.AttackCooldown or 1.2
    ent.AttackWindup = ent.AttackWindup or 0.3
    ent.Damage = ent.Damage or 15
end

-- Override attack for projectiles
function AA.AI.Shooter:OnAttack(ent, target)
    if not IsValid(target) then return true end
    
    ent.InAttack = true
    ent.NextAttack = CurTime() + ent.AttackCooldown
    ent:SetAnimState(3)
    ent.TargetSpeed = 0
    
    -- Windup
    timer.Simple(ent.AttackWindup, function()
        if not IsValid(ent) or not IsValid(target) then
            ent.InAttack = false
            return
        end
        
        -- Create projectile
        local proj = ents.Create("aa_projectile_shooter")
        if IsValid(proj) then
            proj:SetPos(ent:WorldSpaceCenter() + ent:GetForward() * 20)
            proj:SetOwner(ent)
            proj.Target = target
            proj.Damage = ent.Damage
            proj:Spawn()
        end
        
        ent.InAttack = false
    end)
    
    return true -- Override default
end
