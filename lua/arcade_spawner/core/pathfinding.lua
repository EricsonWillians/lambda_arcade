-- Pathfinding and map analysis utilities

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.Pathfinding = ArcadeSpawner.Pathfinding or {}
local Pathfinding = ArcadeSpawner.Pathfinding

Pathfinding.MapBounds = nil
Pathfinding.NavMesh = {}

-- Get map boundaries
function Pathfinding.GetMapBounds()
    if Pathfinding.MapBounds then
        return Pathfinding.MapBounds
    end
    
    local minBounds = Vector(math.huge, math.huge, math.huge)
    local maxBounds = Vector(-math.huge, -math.huge, -math.huge)
    
    -- Scan through world brushes to find boundaries
    for _, ent in ipairs(ents.FindByClass("worldspawn")) do
        local obbMins, obbMaxs = ent:GetModelBounds()
        
        minBounds.x = math.min(minBounds.x, obbMins.x)
        minBounds.y = math.min(minBounds.y, obbMins.y)
        minBounds.z = math.min(minBounds.z, obbMins.z)
        
        maxBounds.x = math.max(maxBounds.x, obbMaxs.x)
        maxBounds.y = math.max(maxBounds.y, obbMaxs.y)
        maxBounds.z = math.max(maxBounds.z, obbMaxs.z)
    end
    
    -- Fallback method: use all entities
    if minBounds.x == math.huge then
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) then
                local pos = ent:GetPos()
                minBounds.x = math.min(minBounds.x, pos.x - 1000)
                minBounds.y = math.min(minBounds.y, pos.y - 1000)
                minBounds.z = math.min(minBounds.z, pos.z - 500)
                
                maxBounds.x = math.max(maxBounds.x, pos.x + 1000)
                maxBounds.y = math.max(maxBounds.y, pos.y + 1000)
                maxBounds.z = math.max(maxBounds.z, pos.z + 500)
            end
        end
    end
    
    Pathfinding.MapBounds = {
        min = minBounds,
        max = maxBounds
    }
    
    return Pathfinding.MapBounds
end

-- Check if a position is valid for spawning
function Pathfinding.IsPositionValid(pos)
    -- Check if position is in solid
    local trace = util.TraceLine({
        start = pos,
        endpos = pos,
        mask = MASK_SOLID
    })
    
    if trace.StartSolid then
        return false
    end
    
    -- Check if there's ground below
    trace = util.TraceLine({
        start = pos,
        endpos = pos - Vector(0, 0, 200),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if not trace.Hit then
        return false
    end
    
    -- Check if there's enough space above
    trace = util.TraceLine({
        start = pos,
        endpos = pos + Vector(0, 0, 72), -- Player height
        mask = MASK_SOLID
    })
    
    if trace.Hit and trace.Fraction < 1 then
        return false
    end
    
    -- Check for water
    if util.PointContents(pos) == CONTENTS_WATER then
        return false
    end
    
    return true
end

-- Find path between two points (simplified)
function Pathfinding.FindPath(startPos, endPos)
    -- Simple line of sight check first
    local trace = util.TraceLine({
        start = startPos + Vector(0, 0, 18),
        endpos = endPos + Vector(0, 0, 18),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if not trace.Hit then
        return {startPos, endPos}
    end
    
    -- If direct path is blocked, return a simple waypoint path
    local midPoint = (startPos + endPos) / 2
    midPoint.z = midPoint.z + 100 -- Go up to avoid obstacles
    
    return {startPos, midPoint, endPos}
end

-- Build a simple navigation mesh for the map
function Pathfinding.BuildNavMesh()
    -- Ensure Config exists before using it
    if not ArcadeSpawner.Config or not ArcadeSpawner.Config.MapAnalysis then
        print("[Arcade Spawner] Config not loaded, skipping NavMesh build")
        return
    end
    
    local bounds = Pathfinding.GetMapBounds()
    local resolution = ArcadeSpawner.Config.MapAnalysis.ScanResolution
    
    Pathfinding.NavMesh = {}
    
    for x = bounds.min.x, bounds.max.x, resolution do
        for y = bounds.min.y, bounds.max.y, resolution do
            local testPos = Vector(x, y, bounds.max.z)
            
            -- Trace down to find ground
            local trace = util.TraceLine({
                start = testPos,
                endpos = Vector(x, y, bounds.min.z),
                mask = MASK_SOLID_BRUSHONLY
            })
            
            if trace.Hit then
                local groundPos = trace.HitPos + Vector(0, 0, 18)
                
                if Pathfinding.IsPositionValid(groundPos) then
                    local nodeKey = math.floor(x / resolution) .. "_" .. math.floor(y / resolution)
                    Pathfinding.NavMesh[nodeKey] = {
                        pos = groundPos,
                        connections = {}
                    }
                end
            end
        end
    end
    
    -- Connect nearby nodes
    local connectionRadius = resolution * 1.5
    for key1, node1 in pairs(Pathfinding.NavMesh) do
        for key2, node2 in pairs(Pathfinding.NavMesh) do
            if key1 ~= key2 then
                local dist = node1.pos:Distance(node2.pos)
                if dist <= connectionRadius then
                    -- Check line of sight
                    local trace = util.TraceLine({
                        start = node1.pos,
                        endpos = node2.pos,
                        mask = MASK_SOLID_BRUSHONLY
                    })
                    
                    if not trace.Hit then
                        table.insert(node1.connections, key2)
                    end
                end
            end
        end
    end
    
    print("[Arcade Spawner] Built navigation mesh with " .. table.Count(Pathfinding.NavMesh) .. " nodes")
end

-- Get nearest navigation node to a position
function Pathfinding.GetNearestNode(pos)
    local nearestKey = nil
    local nearestDist = math.huge
    
    for key, node in pairs(Pathfinding.NavMesh) do
        local dist = pos:Distance(node.pos)
        if dist < nearestDist then
            nearestDist = dist
            nearestKey = key
        end
    end
    
    return nearestKey, nearestDist
end

-- Initialize pathfinding when map loads
hook.Add("InitPostEntity", "ArcadeSpawner_BuildNavMesh", function()
    timer.Simple(5, function() -- Delay to let map fully load
        if ArcadeSpawner.Config then
            Pathfinding.BuildNavMesh()
        end
    end)
end)

print("[Arcade Spawner] Pathfinding system loaded!")