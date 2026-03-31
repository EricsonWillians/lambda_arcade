--[[
    Arcade Anomaly: Model Cache
    
    Persistent cache for model validation results.
--]]

AA.ModelCache = AA.ModelCache or {}
AA.ModelCache.Data = {
    validated = {},
    rejected = {},
    blacklisted = {},
    lastUpdate = 0,
}

function AA.ModelCache:SetData(data)
    self.Data = data or {
        validated = {},
        rejected = {},
        blacklisted = {},
        lastUpdate = 0,
    }
end

function AA.ModelCache:GetData()
    return self.Data
end

function AA.ModelCache:Approve(path)
    self.Data.validated[path] = {
        approved = true,
        result = AA.Types.ValidationResult.VALID,
        timestamp = os.time(),
    }
    self.Data.rejected[path] = nil
    self.Data.blacklisted[path] = nil
    
    self:Save()
end

function AA.ModelCache:Reject(path, result)
    self.Data.rejected[path] = {
        approved = false,
        result = result,
        timestamp = os.time(),
    }
    
    self:Save()
end

function AA.ModelCache:Blacklist(path)
    self.Data.blacklisted[path] = {
        timestamp = os.time(),
    }
    self.Data.validated[path] = nil
    
    self:Save()
end

function AA.ModelCache:IsApproved(path)
    return self.Data.validated[path] ~= nil
end

function AA.ModelCache:IsRejected(path)
    return self.Data.rejected[path] ~= nil
end

function AA.ModelCache:IsBlacklisted(path)
    return self.Data.blacklisted[path] ~= nil
end

function AA.ModelCache:Save()
    if AA.Persistence then
        AA.Persistence:SaveModelCache(self.Data)
    end
end

function AA.ModelCache:Load()
    if AA.Persistence then
        local data = AA.Persistence:LoadModelCache()
        self:SetData(data)
    end
end

-- Initialize
hook.Add("Initialize", "AA_ModelCache_Init", function()
    AA.ModelCache:Load()
end)
