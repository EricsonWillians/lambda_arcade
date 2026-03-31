--[[
    Arcade Anomaly: Map Analyzer
    
    Analyzes maps to find valid spawn points and determine combat zones.
--]]

AA.MapAnalyzer = AA.MapAnalyzer or {}
AA.MapAnalyzer.Anchors = {}
AA.MapAnalyzer.MapData = {}

-- Hull sizes for validation
local HULL_MINS = Vector(-16, -16, 0)
local HULL_MAXS = Vector(16, 16, 72)

function AA.MapAnalyzer:AnalyzeCurrentMap()
    self.Anchors = {}
    self.MapData = {
        name = game.GetMap(),
        playerSpawns = {},
        walkableArea = 0,
        opennessScore = 0,
        recommendedEnemyCap = AA.Config.Game.BaseEnemyCap,
        recommendedSpawnRadius = AA.Config.Game.MaxSpawnDistance,
    }
    
    print("[AA MapAnalyzer] Analyzing map: " .. self.MapData.name)
    
    -- Show loading to all players
    if AA.Net and AA.Net.StartLoading then
        AA.Net.StartLoading(nil, "ANALYZING MAP", "Finding spawn points...", false)
    end
    
    -- Find player spawn entities
    self:FindPlayerSpawns()
    
    if AA.Net and AA.Net.UpdateLoading then
        AA.Net.UpdateLoading(nil, 30, "Scanning for player spawns...")
    end
    
    -- Generate spawn anchors
    self:GenerateAnchors()
    
    if AA.Net and AA.Net.UpdateLoading then
        AA.Net.UpdateLoading(nil, 70, "Generating spawn anchors...")
    end
    
    -- Fallback: create basic anchors if none found
    if #self.Anchors == 0 then
        print("[AA MapAnalyzer] No anchors found, creating fallback spawns...")
        self:CreateFallbackAnchors()
    end
    
    if AA.Net and AA.Net.UpdateLoading then
        AA.Net.UpdateLoading(nil, 90, "Calculating map metrics...")
    end
    
    -- Calculate map metrics
    self:CalculateMetrics()
    
    print(string.format("[AA MapAnalyzer] Found %d anchors, openness: %.2f", 
        #self.Anchors, self.MapData.opennessScore))
    
    -- Complete loading
    if AA.Net and AA.Net.CompleteLoading then
        AA.Net.CompleteLoading(nil)
    end
    
    -- Show summary toast
    if AA.Net and AA.Net.ShowToast then
        AA.Net.ShowToast(nil, string.format("Map analyzed: %d spawn points found", #self.Anchors), "SUCCESS", 4)
    end
    
    AA.Events.Emit(AA.Events.Names.MAP_ANALYSIS_COMPLETE, self.MapData, self.Anchors)
end

function AA.MapAnalyzer:FindPlayerSpawns()
    local spawnClasses = {
        "info_player_start",
        "info_player_deathmatch",
        "info_player_counterterrorist",
        "info_player_terrorist",
        "info_player_combine",
        "info_player_rebel",
    }
    
    for _, class in ipairs(spawnClasses) do
        for _, ent in ipairs(ents.FindByClass(class)) do
            if IsValid(ent) then
                table.insert(self.MapData.playerSpawns, ent:GetPos())
            end
        end
    end
    
    -- If no player spawns found, use origin
    if #self.MapData.playerSpawns == 0 then
        table.insert(self.MapData.playerSpawns, Vector(0, 0, 64))
    end
end

function AA.MapAnalyzer:GenerateAnchors()
    local samplePoints = {}
    local center = self:GetMapCenter()
    local bounds = self:GetMapBounds()
    
    -- Grid-based sampling
    local gridSize = 256
    local sampleHeight = 64
    
    for x = bounds.mins.x, bounds.maxs.x, gridSize do
        for y = bounds.mins.y, bounds.maxs.y, gridSize do
            local pos = Vector(x, y, center.z)
            
            -- Find ground at this position
            local groundPos = self:FindGroundAt(pos)
            if groundPos then
                -- Check if it's a valid spawn point
                if self:IsValidSpawnAnchor(groundPos) then
                    table.insert(samplePoints, groundPos)
                end
            end
        end
    end
    
    -- Also sample around player spawns
    for _, spawnPos in ipairs(self.MapData.playerSpawns) do
        for i = 1, 8 do
            local offset = AA.Util.RandomPointOnRing(spawnPos, 400, 1500)
            local groundPos = self:FindGroundAt(offset)
            if groundPos and self:IsValidSpawnAnchor(groundPos) then
                table.insert(samplePoints, groundPos)
            end
        end
    end

    -- Validate and create anchors
    for _, pos in ipairs(samplePoints) do
        -- Check distance from all player spawns
        local minDist = math.huge
        local maxDist = 0
        
        for _, spawnPos in ipairs(self.MapData.playerSpawns) do
            local dist = pos:DistToSqr(spawnPos)
            minDist = math.min(minDist, dist)
            maxDist = math.max(maxDist, dist)
        end
        
        -- Only use points that are reasonably far from player spawns
        if minDist > (AA.Config.Game.MinSpawnDistance ^ 2) then
            local anchor = {
                position = pos,
                quality = self:CalculateAnchorQuality(pos),
                lastUsed = 0,
                successCount = 0,
                failureCount = 0,
                avgEngagementTime = 0,
                navReachable = self:CheckNavReachable(pos),
            }
            
            if anchor.quality >= AA.Balance.MapAnalysis.MinAnchorQuality then
                table.insert(self.Anchors, anchor)
                AA.Events.Emit(AA.Events.Names.ANCHOR_ADDED, anchor)
            end
        end
    end
    
    -- Sort by quality
    table.sort(self.Anchors, function(a, b) return a.quality > b.quality end)
    
    -- Limit to max anchors
    if #self.Anchors > AA.Balance.MapAnalysis.MaxSpawnPoints then
        for i = AA.Balance.MapAnalysis.MaxSpawnPoints + 1, #self.Anchors do
            self.Anchors[i] = nil
        end
    end
end

function AA.MapAnalyzer:CreateFallbackAnchors()
    -- Create simple fallback anchors around player spawns
    for _, spawnPos in ipairs(self.MapData.playerSpawns) do
        -- Create 4 anchors in cardinal directions
        local directions = {
            Vector(1, 0, 0),
            Vector(-1, 0, 0),
            Vector(0, 1, 0),
            Vector(0, -1, 0),
        }
        
        for _, dir in ipairs(directions) do
            for dist = 500, 1500, 500 do
                local pos = spawnPos + dir * dist
                local groundPos = self:FindGroundAt(pos)
                
                if groundPos and self:IsValidSpawnAnchor(groundPos) then
                    local anchor = {
                        position = groundPos,
                        quality = 0.5,
                        lastUsed = 0,
                        successCount = 0,
                        failureCount = 0,
                        avgEngagementTime = 0,
                        navReachable = self:CheckNavReachable(groundPos),
                    }
                    
                    table.insert(self.Anchors, anchor)
                    
                    if #self.Anchors >= 8 then return end -- Enough fallbacks
                end
            end
        end
    end
    
    -- Ultimate fallback: just use any valid point near player spawns
    if #self.Anchors == 0 then
        for _, spawnPos in ipairs(self.MapData.playerSpawns) do
            local anchor = {
                position = spawnPos + Vector(500, 0, 0),
                quality = 0.3,
                lastUsed = 0,
                successCount = 0,
                failureCount = 0,
                avgEngagementTime = 0,
                navReachable = false,
            }
            table.insert(self.Anchors, anchor)
        end
    end
end

function AA.MapAnalyzer:FindGroundAt(pos)
    local trace = util.TraceLine({
        start = pos + Vector(0, 0, 512),
        endpos = pos - Vector(0, 0, 512),
        mask = MASK_SOLID_BRUSHONLY,
    })
    
    if trace.Hit and not trace.HitSky then
        return trace.HitPos
    end
    
    return nil
end

function AA.MapAnalyzer:IsValidSpawnAnchor(pos)
    -- Hull trace to ensure space is clear
    local trace = util.TraceHull({
        start = pos + Vector(0, 0, 36),
        endpos = pos + Vector(0, 0, 36),
        mins = HULL_MINS,
        maxs = HULL_MAXS,
        mask = MASK_SOLID,
    })
    
    if trace.StartSolid or trace.AllSolid then
        return false
    end
    
    -- Check if there's ground beneath
    local groundTrace = util.TraceLine({
        start = pos + Vector(0, 0, 1),
        endpos = pos - Vector(0, 0, 32),
        mask = MASK_SOLID_BRUSHONLY,
    })
    
    if not groundTrace.Hit then
        return false
    end
    
    -- Check slope of ground
    if groundTrace.HitNormal.z < 0.7 then
        return false
    end
    
    return true
end

function AA.MapAnalyzer:CalculateAnchorQuality(pos)
    local quality = 1.0
    
    -- Prefer areas with some cover nearby
    local coverScore = self:CheckCoverNearby(pos)
    quality = quality + coverScore * 0.3
    
    -- Penalize being too far from player areas
    local minDist = math.huge
    for _, spawnPos in ipairs(self.MapData.playerSpawns) do
        local dist = pos:Distance(spawnPos)
        minDist = math.min(minDist, dist)
    end
    
    if minDist > 3000 then
        quality = quality - 0.3
    end
    
    -- Penalize being too close
    if minDist < 500 then
        quality = quality - 0.5
    end
    
    return math.Clamp(quality, 0, 1)
end

function AA.MapAnalyzer:CheckCoverNearby(pos)
    local directions = {
        Vector(1, 0, 0), Vector(-1, 0, 0),
        Vector(0, 1, 0), Vector(0, -1, 0),
    }
    
    local coverCount = 0
    for _, dir in ipairs(directions) do
        local trace = util.TraceLine({
            start = pos + Vector(0, 0, 48),
            endpos = pos + dir * 128 + Vector(0, 0, 48),
            mask = MASK_SOLID,
        })
        
        if trace.Hit then
            coverCount = coverCount + 1
        end
    end
    
    return coverCount / #directions
end

function AA.MapAnalyzer:CheckNavReachable(pos)
    -- Check if navmesh exists and if this area is reachable
    if not navmesh.IsLoaded() then
        return nil
    end
    
    local area = navmesh.GetNearestNavArea(pos)
    return IsValid(area)
end

function AA.MapAnalyzer:CalculateMetrics()
    -- Calculate map openness based on sample traces
    local openTraces = 0
    local totalTraces = 0
    
    for _, anchor in ipairs(self.Anchors) do
        for _, spawnPos in ipairs(self.MapData.playerSpawns) do
            local trace = util.TraceLine({
                start = anchor.position + Vector(0, 0, 48),
                endpos = spawnPos + Vector(0, 0, 48),
                mask = MASK_SOLID,
            })
            
            totalTraces = totalTraces + 1
            if not trace.Hit then
                openTraces = openTraces + 1
            end
        end
    end
    
    if totalTraces > 0 then
        self.MapData.opennessScore = openTraces / totalTraces
    end
    
    -- Adjust recommended enemy cap based on map size
    local bounds = self:GetMapBounds()
    local volume = (bounds.maxs.x - bounds.mins.x) * 
                   (bounds.maxs.y - bounds.mins.y) * 
                   (bounds.maxs.z - bounds.mins.z)
    
    -- Estimate playable area (rough heuristic)
    self.MapData.walkableArea = volume / 1000000 -- Normalize
    
    if self.MapData.walkableArea > 10 then
        self.MapData.recommendedEnemyCap = math.min(
            AA.Config.Game.BaseEnemyCap + 5,
            AA.Config.Game.MaxEnemyCap
        )
        self.MapData.recommendedSpawnRadius = 2500
    elseif self.MapData.walkableArea < 3 then
        self.MapData.recommendedEnemyCap = math.max(
            AA.Config.Game.BaseEnemyCap - 3,
            3
        )
        self.MapData.recommendedSpawnRadius = 1000
    end
end

function AA.MapAnalyzer:GetMapCenter()
    local bounds = self:GetMapBounds()
    return (bounds.mins + bounds.maxs) / 2
end

function AA.MapAnalyzer:GetMapBounds()
    -- Try to find world bounds
    local worldMins, worldMaxs = game.GetWorld():GetModelBounds()
    
    -- Fallback if world bounds are weird
    if not worldMins or worldMins == Vector(0, 0, 0) then
        worldMins = Vector(-4096, -4096, -1024)
        worldMaxs = Vector(4096, 4096, 1024)
    end
    
    return { mins = worldMins, maxs = worldMaxs }
end

-- Public API
function AA.MapAnalyzer:GetAnchors()
    return self.Anchors or {}
end

function AA.MapAnalyzer:GetRandomAnchor(preferQuality)
    if not self.Anchors or #self.Anchors == 0 then
        return nil
    end
    
    if preferQuality then
        -- Weighted random based on quality
        local totalQuality = 0
        for _, anchor in ipairs(self.Anchors) do
            totalQuality = totalQuality + anchor.quality
        end
        
        local roll = math.random() * totalQuality
        local current = 0
        
        for _, anchor in ipairs(self.Anchors) do
            current = current + anchor.quality
            if roll <= current then
                return anchor
            end
        end
    end
    
    return self.Anchors[math.random(1, #self.Anchors)]
end

function AA.MapAnalyzer:GetNearestAnchor(pos)
    local nearest = nil
    local nearestDist = math.huge
    
    for _, anchor in ipairs(self.Anchors) do
        local dist = pos:DistToSqr(anchor.position)
        if dist < nearestDist then
            nearestDist = dist
            nearest = anchor
        end
    end
    
    return nearest
end

function AA.MapAnalyzer:RecordAnchorResult(anchor, success, engagementTime)
    if not anchor then return end
    
    if success then
        anchor.successCount = anchor.successCount + 1
    else
        anchor.failureCount = anchor.failureCount + 1
    end
    
    -- Update average engagement time
    if engagementTime then
        if anchor.avgEngagementTime == 0 then
            anchor.avgEngagementTime = engagementTime
        else
            anchor.avgEngagementTime = (anchor.avgEngagementTime + engagementTime) / 2
        end
    end
    
    -- Deprioritize frequently failing anchors
    if anchor.failureCount > 5 and anchor.failureCount > anchor.successCount * 2 then
        anchor.quality = anchor.quality * 0.8
    end
    
    anchor.lastUsed = CurTime()
end

function AA.MapAnalyzer:GetMapData()
    return self.MapData
end
