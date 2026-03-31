--[[
    Arcade Anomaly: Utility Functions
    
    Shared utility functions used across the gamemode.
--]]

AA.Util = AA.Util or {}

-- Math utilities
function AA.Util.Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function AA.Util.Lerp(t, a, b)
    return a + (b - a) * t
end

function AA.Util.LerpVector(t, a, b)
    return Vector(
        AA.Util.Lerp(t, a.x, b.x),
        AA.Util.Lerp(t, a.y, b.y),
        AA.Util.Lerp(t, a.z, b.z)
    )
end

function AA.Util.DistanceSqr(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function AA.Util.Distance(a, b)
    return math.sqrt(AA.Util.DistanceSqr(a, b))
end

function AA.Util.Direction(from, to)
    local dir = to - from
    dir:Normalize()
    return dir
end

function AA.Util.RandomPointInCircle(center, radius)
    local angle = math.random() * math.pi * 2
    local dist = math.sqrt(math.random()) * radius
    return Vector(
        center.x + math.cos(angle) * dist,
        center.y + math.sin(angle) * dist,
        center.z
    )
end

function AA.Util.RandomPointOnRing(center, minRadius, maxRadius)
    local angle = math.random() * math.pi * 2
    local dist = minRadius + math.random() * (maxRadius - minRadius)
    return Vector(
        center.x + math.cos(angle) * dist,
        center.y + math.sin(angle) * dist,
        center.z
    )
end

-- Vector utilities
function AA.Util.FlattenVector(vec)
    return Vector(vec.x, vec.y, 0)
end

function AA.Util.VectorMaxComponent(vec)
    return math.max(math.abs(vec.x), math.abs(vec.y), math.abs(vec.z))
end

-- Random utilities
function AA.Util.WeightedRandom(choices)
    -- choices = {{item = x, weight = y}, ...}
    local totalWeight = 0
    for _, choice in ipairs(choices) do
        totalWeight = totalWeight + choice.weight
    end
    
    local roll = math.random() * totalWeight
    local current = 0
    
    for _, choice in ipairs(choices) do
        current = current + choice.weight
        if roll <= current then
            return choice.item
        end
    end
    
    return choices[#choices].item
end

function AA.Util.RandomFromTable(tbl)
    local keys = table.GetKeys(tbl)
    if #keys == 0 then return nil end
    return tbl[keys[math.random(1, #keys)]]
end

-- Table utilities
function AA.Util.TableFilter(tbl, predicate)
    local result = {}
    for _, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

function AA.Util.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function AA.Util.ShuffleTable(tbl)
    local n = #tbl
    while n > 1 do
        local k = math.random(n)
        tbl[n], tbl[k] = tbl[k], tbl[n]
        n = n - 1
    end
    return tbl
end

-- Time utilities
function AA.Util.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

function AA.Util.FormatScore(score)
    return string.format("%09d", math.min(score, AA.Types.Constants.MAX_SCORE))
end

-- Trace utilities
function AA.Util.TraceLine(from, to, filter, mask)
    mask = mask or MASK_SOLID
    return util.TraceLine({
        start = from,
        endpos = to,
        filter = filter,
        mask = mask,
    })
end

function AA.Util.TraceHull(from, to, mins, maxs, filter, mask)
    mask = mask or MASK_SOLID
    return util.TraceHull({
        start = from,
        endpos = to,
        mins = mins,
        maxs = maxs,
        filter = filter,
        mask = mask,
    })
end

function AA.Util.FindGroundPosition(pos, downDist, upDist)
    downDist = downDist or 256
    upDist = upDist or 32
    
    -- Trace down to find ground
    local traceDown = util.TraceLine({
        start = pos + Vector(0, 0, upDist),
        endpos = pos - Vector(0, 0, downDist),
        mask = MASK_SOLID_BRUSHONLY,
    })
    
    if traceDown.Hit then
        return traceDown.HitPos
    end
    
    return nil
end

function AA.Util.IsPositionValidSpawn(pos, hullMins, hullMaxs)
    hullMins = hullMins or Vector(-16, -16, 0)
    hullMaxs = hullMaxs or Vector(16, 16, 72)
    
    -- Check if area is clear
    local trace = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = hullMins,
        maxs = hullMaxs,
        mask = MASK_SOLID,
    })
    
    if trace.StartSolid or trace.AllSolid then
        return false
    end
    
    -- Check ground
    local groundTrace = util.TraceLine({
        start = pos,
        endpos = pos - Vector(0, 0, 128),
        mask = MASK_SOLID_BRUSHONLY,
    })
    
    if not groundTrace.Hit then
        return false
    end
    
    return true
end

-- Entity utilities
function AA.Util.GetAlivePlayers()
    local alive = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            table.insert(alive, ply)
        end
    end
    return alive
end

function AA.Util.GetNearestPlayer(pos, filter)
    local nearest = nil
    local nearestDist = math.huge
    
    for _, ply in ipairs(AA.Util.GetAlivePlayers()) do
        if not filter or not filter(ply) then
            local dist = pos:DistToSqr(ply:GetPos())
            if dist < nearestDist then
                nearestDist = dist
                nearest = ply
            end
        end
    end
    
    return nearest, nearestDist
end

function AA.Util.IsTargetValid(ent)
    return IsValid(ent) and ent:IsPlayer() and ent:Alive()
end

-- Color utilities
function AA.Util.ColorLerp(t, c1, c2)
    return Color(
        AA.Util.Lerp(t, c1.r, c2.r),
        AA.Util.Lerp(t, c1.g, c2.g),
        AA.Util.Lerp(t, c1.b, c2.b),
        AA.Util.Lerp(t, c1.a or 255, c2.a or 255)
    )
end

function AA.Util.ColorWithAlpha(color, alpha)
    return Color(color.r, color.g, color.b, alpha)
end

-- Debug utilities
function AA.Util.DrawDebugSphere(pos, radius, color, duration)
    debugoverlay.Sphere(pos, radius, duration or 0.1, color or Color(255, 255, 255), false)
end

function AA.Util.DrawDebugLine(from, to, color, duration)
    debugoverlay.Line(from, to, duration or 0.1, color or Color(255, 255, 255), false)
end

function AA.Util.DrawDebugText(pos, text, color, duration)
    debugoverlay.Text(pos, text, duration or 0.1)
end
