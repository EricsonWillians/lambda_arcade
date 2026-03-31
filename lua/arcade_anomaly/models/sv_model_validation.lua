--[[
    Arcade Anomaly: Model Validation
    
    Validates workshop models for usability.
--]]

AA.ModelValidation = AA.ModelValidation or {}

function AA.ModelValidation:ValidateModel(path)
    if not path or path == "" then
        return AA.Types.ValidationResult.MISSING_FILE
    end
    
    -- Check if file exists
    if not file.Exists(path, "GAME") then
        return AA.Types.ValidationResult.MISSING_FILE
    end
    
    -- Try to create a test entity to validate the model
    local result = self:TestModelEntity(path)
    
    return result
end

function AA.ModelValidation:TestModelEntity(path)
    -- Create a temporary entity to test the model
    local testEnt = ents.Create("prop_dynamic")
    if not IsValid(testEnt) then
        return AA.Types.ValidationResult.PERFORMANCE_HEAVY
    end
    
    testEnt:SetModel(path)
    
    -- Check if model loaded
    if testEnt:GetModel() ~= path then
        testEnt:Remove()
        return AA.Types.ValidationResult.MISSING_FILE
    end
    
    -- Check bounds
    local mins, maxs = testEnt:GetModelBounds()
    if not mins or not maxs then
        testEnt:Remove()
        return AA.Types.ValidationResult.INVALID_BOUNDS
    end
    
    local size = maxs - mins
    local maxDim = math.max(size.x, size.y, size.z)
    
    -- Reject absurd sizes
    if maxDim > 1000 then
        testEnt:Remove()
        return AA.Types.ValidationResult.TOO_LARGE
    end
    
    if maxDim < 10 then
        testEnt:Remove()
        return AA.Types.ValidationResult.TOO_SMALL
    end
    
    -- Check for sequences
    local seqCount = testEnt:GetSequenceCount()
    if seqCount <= 0 then
        testEnt:Remove()
        return AA.Types.ValidationResult.NO_SEQUENCES
    end
    
    -- Check for valid sequences
    local hasIdle = false
    local hasMove = false
    
    for i = 0, seqCount - 1 do
        local name = testEnt:GetSequenceName(i)
        if name then
            name = string.lower(name)
            if string.find(name, "idle") then hasIdle = true end
            if string.find(name, "run") or string.find(name, "walk") then hasMove = true end
        end
    end
    
    testEnt:Remove()
    
    -- Require at least idle
    if not hasIdle then
        return AA.Types.ValidationResult.NO_SEQUENCES
    end
    
    return AA.Types.ValidationResult.VALID
end

function AA.ModelValidation:ValidateBatch(paths, progressCallback)
    local results = {}
    local total = #paths
    
    for i, path in ipairs(paths) do
        local result = self:ValidateModel(path)
        results[path] = result
        
        if progressCallback then
            progressCallback(i, total, path, result)
        end
    end
    
    return results
end

function AA.ModelValidation:AutoTagModel(path, modelData)
    -- Automatically assign tags based on model characteristics
    local tags = {}
    
    -- Name-based heuristics
    local lowerPath = string.lower(path)
    
    if string.find(lowerPath, "zombie") or string.find(lowerPath, "undead") then
        table.insert(tags, "undead")
    end
    
    if string.find(lowerPath, "combine") or string.find(lowerPath, "soldier") then
        table.insert(tags, "soldier")
    end
    
    if string.find(lowerPath, "robot") or string.find(lowerPath, "mech") then
        table.insert(tags, "machine")
    end
    
    if string.find(lowerPath, "creature") or string.find(lowerPath, "monster") then
        table.insert(tags, "creature")
    end
    
    -- Size-based heuristics (requires bounds to be set)
    -- Note: bounds must be set externally, e.g. during model discovery
    if modelData.bounds and modelData.bounds.maxs and modelData.bounds.mins then
        local size = modelData.bounds.maxs - modelData.bounds.mins
        local volume = size.x * size.y * size.z
        
        if volume > 100000 then
            table.insert(tags, "large")
            table.insert(tags, "brute")
        elseif volume < 20000 then
            table.insert(tags, "small")
            table.insert(tags, "rusher")
        end
    end
    
    return tags
end

-- Admin command for manual validation
concommand.Add("aa_model_validate", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local path = args[1]
    if not path then
        print("Usage: aa_model_validate <model_path>")
        return
    end
    
    print("[AA] Validating: " .. path)
    local result = AA.ModelValidation:ValidateModel(path)
    
    local resultNames = {}
    for name, val in pairs(AA.Types.ValidationResult) do
        resultNames[val] = name
    end
    
    print("[AA] Result: " .. (resultNames[result] or "UNKNOWN"))
    
    if result == AA.Types.ValidationResult.VALID then
        AA.ModelRegistry:ApproveModel(path)
    end
end)
