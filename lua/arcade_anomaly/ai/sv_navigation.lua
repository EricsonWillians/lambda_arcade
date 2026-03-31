--[[
    Arcade Anomaly: Navigation System
    Simple pathfinding
--]]

AA.Navigation = AA.Navigation or {}

function AA.Navigation:Initialize(ent)
    ent.NavData = {
        lastPathUpdate = 0,
        stuckCounter = 0,
        lastPos = ent:GetPos(),
    }
end

function AA.Navigation:Update(ent, target)
    if not IsValid(ent) or not IsValid(target) then return end
    
    if not ent.NavData then
        self:Initialize(ent)
    end
end

function AA.Navigation:MoveAlongPath(ent, target, speed)
    if not IsValid(ent) or not IsValid(target) then return end
    if not ent.loco then return end
    
    local goalPos = target:GetPos()
    local myPos = ent:GetPos()
    
    -- Simple direct approach
    ent.loco:Approach(goalPos, speed)
    ent.loco:SetDesiredSpeed(speed)
    ent.loco:FaceTowards(goalPos)
end
