-- addons/arcade_spawner/lua/arcade_spawner/client/effects.lua
-- BULLETPROOF Enhanced Effects System v4.1

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.Effects = ArcadeSpawner.Effects or {}
local Effects = ArcadeSpawner.Effects

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════
Effects.ParticleCache = {}
Effects.DynamicLights = {}
Effects.ScreenEffects = {}
Effects.SoundCache = {}
Effects.LastEffectTime = {}

-- ═══════════════════════════════════════════════════════════════
-- SAFE EFFECT UTILITIES
-- ═══════════════════════════════════════════════════════════════
local function SafeGetOrigin(data)
    if not data then return Vector(0, 0, 0) end
    
    local origin = nil
    if data.GetOrigin then
        local success, result = pcall(function() return data:GetOrigin() end)
        if success and result then origin = result end
    end
    
    if not origin and data.GetPos then
        local success, result = pcall(function() return data:GetPos() end)
        if success and result then origin = result end
    end
    
    if not origin and data.Pos then
        origin = data.Pos
    end
    
    return origin or Vector(0, 0, 0)
end

-- Enhanced particle emitter with caching
local function CreateSafeEmitter(pos, maxParticles)
    if not pos or not isvector(pos) then return nil end
    
    local cacheKey = tostring(math.floor(pos.x/100)) .. "_" .. tostring(math.floor(pos.y/100))
    local currentTime = CurTime()
    
    -- Rate limiting
    if Effects.LastEffectTime[cacheKey] and (currentTime - Effects.LastEffectTime[cacheKey]) < 0.1 then
        return nil
    end
    Effects.LastEffectTime[cacheKey] = currentTime
    
    local success, emitter = pcall(ParticleEmitter, pos)
    if success and emitter then
        -- Only SetNearClip is available on the emitter
        emitter:SetNearClip(24, 32)
        
        -- Auto-cleanup
        timer.Simple(5, function()
            if emitter then
                emitter:Finish()
            end
        end)
        
        return emitter
    end
    
    return nil
end

-- Enhanced dynamic light with performance optimization
local function CreateEnhancedLight(pos, color, brightness, size, decay, lifetime)
    if not pos or not isvector(pos) then return nil end
    
    -- Limit concurrent lights
    if #Effects.DynamicLights >= 20 then
        -- Remove oldest light
        local oldest = table.remove(Effects.DynamicLights, 1)
        if oldest and oldest.light then
            oldest.light.dietime = CurTime()
        end
    end
    
    local success, dlight = pcall(function()
        return DynamicLight(math.random(1000, 99999))
    end)
    
    if success and dlight then
        dlight.pos = pos
        dlight.r = color.r or 255
        dlight.g = color.g or 255
        dlight.b = color.b or 255
        dlight.brightness = brightness or 8
        dlight.size = size or 300
        dlight.decay = decay or 1000
        dlight.dietime = CurTime() + (lifetime or 1.0)
        
        table.insert(Effects.DynamicLights, {
            light = dlight,
            endTime = dlight.dietime,
            startTime = CurTime()
        })
        
        return dlight
    end
    
    return nil
end

-- Safe sound playing with caching
local function PlaySafeSound(soundPath, pos, level, pitch)
    if not soundPath or not pos then return end
    
    -- Cache check
    local soundKey = soundPath .. "_" .. tostring(math.floor(CurTime() * 10))
    if Effects.SoundCache[soundKey] then return end
    Effects.SoundCache[soundKey] = true
    
    -- Clean cache periodically
    timer.Simple(1, function()
        Effects.SoundCache[soundKey] = nil
    end)
    
    local success = pcall(function()
        if file.Exists("sound/" .. soundPath, "GAME") then
            sound.Play(soundPath, pos, level or 75, pitch or 100)
        end
    end)
    
    if not success then
        print("[Arcade Spawner] Sound error: " .. soundPath)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED SPAWN EFFECTS
-- ═══════════════════════════════════════════════════════════════
local function EnhancedSpawnEffect(data)
    local pos = SafeGetOrigin(data)
    if not pos or not isvector(pos) then return end
    
    local rarity = data.GetMagnitude and data:GetMagnitude() or 1
    
    local colors = {
        [1] = Color(255, 255, 255), -- Common
        [2] = Color(30, 255, 30),   -- Uncommon
        [3] = Color(30, 144, 255),  -- Rare
        [4] = Color(138, 43, 226),  -- Epic
        [5] = Color(255, 165, 0),   -- Legendary
        [6] = Color(255, 20, 147)   -- Mythic
    }
    
    local effectColor = colors[rarity] or colors[1]
    local intensity = 15 + (rarity * 5)
    
    -- Enhanced particle system with multiple layers
    local emitter = CreateSafeEmitter(pos, 100)
    if emitter then
        -- Core explosion particles
        for i = 1, 20 + intensity do
            local particle = emitter:Add("effects/spark", pos + VectorRand() * 60)
            if particle then
                particle:SetVelocity(VectorRand() * 120 + Vector(0, 0, 40))
                particle:SetLifeTime(0)
                particle:SetDieTime(2.5)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(6)
                particle:SetEndSize(2)
                particle:SetColor(effectColor.r, effectColor.g, effectColor.b)
                particle:SetGravity(Vector(0, 0, -100))
                particle:SetAirResistance(40)
            end
        end
        
        -- Ring effect for rare+ enemies
        if rarity >= 3 then
            for i = 1, 16 do
                local angle = (i / 16) * math.pi * 2
                local ringPos = pos + Vector(math.cos(angle) * 40, math.sin(angle) * 40, 0)
                
                local particle = emitter:Add("effects/yellowflare", ringPos)
                if particle then
                    particle:SetVelocity(Vector(math.cos(angle) * 60, math.sin(angle) * 60, 20))
                    particle:SetLifeTime(0)
                    particle:SetDieTime(1.5)
                    particle:SetStartAlpha(200)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(4)
                    particle:SetEndSize(1)
                    particle:SetColor(effectColor.r, effectColor.g, effectColor.b)
                end
            end
        end
        
        -- Mythic spiral effect
        if rarity >= 6 then
            for i = 1, 30 do
                local spiralAngle = (i / 30) * math.pi * 4
                local spiralRadius = (i / 30) * 80
                local spiralPos = pos + Vector(
                    math.cos(spiralAngle) * spiralRadius,
                    math.sin(spiralAngle) * spiralRadius,
                    (i / 30) * 60
                )
                
                local particle = emitter:Add("effects/yellowflare", spiralPos)
                if particle then
                    particle:SetVelocity(Vector(0, 0, 50))
                    particle:SetLifeTime(0)
                    particle:SetDieTime(2.0)
                    particle:SetStartAlpha(255)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(8)
                    particle:SetEndSize(3)
                    particle:SetColor(255, 20, 147)
                end
            end
        end
    end
    
    -- Enhanced lighting with pulsing
    local lightDuration = 1.5 + (rarity * 0.3)
    CreateEnhancedLight(pos, effectColor, 6 + intensity/5, 150 + intensity*3, 600, lightDuration)
    
    -- Secondary light for high rarity
    if rarity >= 4 then
        timer.Simple(0.5, function()
            CreateEnhancedLight(pos + Vector(0, 0, 30), effectColor, 4, 100, 800, 1.0)
        end)
    end
    
    -- Screen shake based on rarity and distance
    if LocalPlayer and IsValid(LocalPlayer()) then
        local distance = pos:Distance(LocalPlayer():GetPos())
        if distance < 800 then
            local shakeIntensity = ((800 - distance) / 800) * (0.3 + rarity * 0.1)
            util.ScreenShake(pos, shakeIntensity, 3, 0.8 + rarity * 0.2, 400 + rarity * 100)
        end
    end
    
    -- Enhanced audio with rarity-based sounds
    local spawnSounds = {
        [1] = {"ambient/energy/zap1.wav"},
        [2] = {"ambient/energy/zap2.wav", "buttons/button15.wav"},
        [3] = {"ambient/energy/zap3.wav", "ambient/levels/labs/electric_explosion1.wav"},
        [4] = {"ambient/energy/zap5.wav", "ambient/levels/labs/electric_explosion2.wav"},
        [5] = {"ambient/energy/zap7.wav", "ambient/levels/labs/electric_explosion3.wav"},
        [6] = {"ambient/energy/zap9.wav", "ambient/levels/labs/electric_explosion4.wav"}
    }
    
    local soundList = spawnSounds[rarity] or spawnSounds[1]
    local selectedSound = table.Random(soundList)
    PlaySafeSound(selectedSound, pos, 75 + intensity, math.random(90, 110))
    
    -- Rare+ enemies get additional sound effects
    if rarity >= 3 then
        timer.Simple(0.3, function()
            PlaySafeSound("ambient/energy/newspark04.wav", pos, 60, math.random(120, 140))
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EPIC LEVEL UP EFFECTS
-- ═══════════════════════════════════════════════════════════════
local function EpicLevelUpEffect(data)
    local pos = SafeGetOrigin(data)
    if not pos or not isvector(pos) then return end
    
    local level = data.GetMagnitude and data:GetMagnitude() or 1
    
    local emitter = CreateSafeEmitter(pos, 150)
    if emitter then
        -- Golden spiral effect
        for i = 1, 60 do
            local angle = (i / 60) * math.pi * 6
            local radius = 20 + (i / 60) * 50
            local height = (i / 60) * 80
            
            local spiralPos = pos + Vector(
                math.cos(angle) * radius,
                math.sin(angle) * radius,
                height
            )
            
            local particle = emitter:Add("effects/yellowflare", spiralPos)
            if particle then
                particle:SetVelocity(Vector(0, 0, 100) + VectorRand() * 30)
                particle:SetLifeTime(0)
                particle:SetDieTime(3.0)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(8)
                particle:SetEndSize(2)
                particle:SetColor(255, 215, 0)
                particle:SetGravity(Vector(0, 0, -20))
            end
        end
        
        -- Star burst effect
        for i = 1, 24 do
            local burstAngle = (i / 24) * math.pi * 2
            local burstPos = pos + Vector(math.cos(burstAngle) * 60, math.sin(burstAngle) * 60, 30)
            
            local particle = emitter:Add("effects/yellowflare", burstPos)
            if particle then
                particle:SetVelocity(Vector(math.cos(burstAngle) * 150, math.sin(burstAngle) * 150, 50))
                particle:SetLifeTime(0)
                particle:SetDieTime(2.0)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(6)
                particle:SetEndSize(1)
                particle:SetColor(255, 255, 100)
            end
        end
    end
    
    -- Epic lighting sequence
    CreateEnhancedLight(pos + Vector(0, 0, 30), Color(255, 215, 0), 12, 400, 200, 3.0)
    
    timer.Simple(0.5, function()
        CreateEnhancedLight(pos, Color(255, 255, 150), 8, 300, 300, 2.0)
    end)
    
    timer.Simple(1.0, function()
        CreateEnhancedLight(pos + Vector(0, 0, 15), Color(255, 200, 50), 6, 250, 400, 1.5)
    end)
    
    -- Enhanced screen effect
    if LocalPlayer and IsValid(LocalPlayer()) then
        local distance = pos:Distance(LocalPlayer():GetPos())
        if distance < 800 then
            Effects.ScreenEffects.levelup = {
                effect = {
                    ["$pp_colour_brightness"] = 0.15,
                    ["$pp_colour_contrast"] = 1.2,
                    ["$pp_colour_colour"] = 1.1
                },
                endTime = CurTime() + 0.8,
                fadeTime = 0.8
            }
            
            util.ScreenShake(pos, 1.5, 8, 1.5, 600)
        end
    end
    
    -- Epic sound sequence
    PlaySafeSound("buttons/button14.wav", pos, 90, 120)
    timer.Simple(0.3, function()
        PlaySafeSound("ambient/energy/newspark07.wav", pos, 80, 110)
    end)
    timer.Simple(0.8, function()
        PlaySafeSound("ambient/energy/zap2.wav", pos, 70, 130)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED DEATH EFFECTS
-- ═══════════════════════════════════════════════════════════════
local function EnhancedDeathEffect(data)
    local pos = SafeGetOrigin(data)
    if not pos or not isvector(pos) then return end
    
    local rarity = data.GetMagnitude and data:GetMagnitude() or 1
    
    local emitter = CreateSafeEmitter(pos, 60)
    if emitter then
        -- Smoke particles
        for i = 1, 15 + rarity * 3 do
            local particle = emitter:Add("particle/particle_smokegrenade", pos + Vector(0, 0, 20) + VectorRand() * 25)
            if particle then
                particle:SetVelocity(VectorRand() * 80)
                particle:SetLifeTime(0)
                particle:SetDieTime(2.0)
                particle:SetStartAlpha(150)
                particle:SetEndAlpha(0)
                particle:SetStartSize(6)
                particle:SetEndSize(20)
                particle:SetColor(100, 100, 100)
                particle:SetGravity(Vector(0, 0, -60))
            end
        end
        
        -- Blood/energy effect for higher rarity
        if rarity >= 3 then
            for i = 1, rarity * 2 do
                local particle = emitter:Add("effects/spark", pos + VectorRand() * 30)
                if particle then
                    particle:SetVelocity(VectorRand() * 100)
                    particle:SetLifeTime(0)
                    particle:SetDieTime(1.5)
                    particle:SetStartAlpha(200)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(4)
                    particle:SetEndSize(1)
                    particle:SetColor(255, 50, 50)
                end
            end
        end
    end
    
    -- Death lighting
    if rarity >= 3 then
        CreateEnhancedLight(pos, Color(255, 100, 100), 4, 150, 1200, 1.0)
    end
    
    -- Death sounds
    local deathSounds = {
        "physics/body/body_medium_break2.wav",
        "ambient/energy/spark1.wav",
        "physics/body/body_medium_impact_soft2.wav"
    }
    
    if rarity >= 4 then
        table.insert(deathSounds, "ambient/energy/newspark05.wav")
        table.insert(deathSounds, "ambient/levels/labs/electric_explosion1.wav")
    end
    
    local selectedSound = table.Random(deathSounds)
    PlaySafeSound(selectedSound, pos, 70, math.random(80, 120))
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED ENEMY GLOW SYSTEM
-- ═══════════════════════════════════════════════════════════════
hook.Add("PostDrawOpaqueRenderables", "ArcadeSpawner_EnhancedGlow", function()
    local success, err = pcall(function()
        local currentTime = CurTime()
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent.IsArcadeEnemy and ent.RarityType and ent.RarityType ~= "Common" then
                local glowColors = {
                    ["Uncommon"] = {color = Color(30, 255, 30), intensity = 15},
                    ["Rare"] = {color = Color(30, 144, 255), intensity = 25},
                    ["Epic"] = {color = Color(138, 43, 226), intensity = 35},
                    ["Legendary"] = {color = Color(255, 165, 0), intensity = 50},
                    ["Mythic"] = {color = Color(255, 20, 147), intensity = 75}
                }
                
                local glowData = glowColors[ent.RarityType]
                if glowData and render and render.SetMaterial then
                    local mat = Material("sprites/light_glow02_add")
                    if mat and not mat:IsError() then
                        render.SetMaterial(mat)
                        
                        local glowPos = ent:GetPos() + Vector(0, 0, 40)
                        
                        -- Enhanced pulsing calculation
                        local basePulse = math.sin(currentTime * 3) * 0.3 + 0.7
                        local rarityPulse = 1.0
                        
                        if ent.RarityType == "Mythic" then
                            rarityPulse = math.sin(currentTime * 8) * 0.5 + 1.0
                        elseif ent.RarityType == "Legendary" then
                            rarityPulse = math.sin(currentTime * 6) * 0.3 + 1.0
                        end
                        
                        local finalIntensity = glowData.intensity * basePulse * rarityPulse
                        
                        render.DrawSprite(glowPos, finalIntensity, finalIntensity, glowData.color)
                        
                        -- Additional ring effect for Mythic
                        if ent.RarityType == "Mythic" then
                            local ringIntensity = finalIntensity * 0.6
                            render.DrawSprite(glowPos, ringIntensity + 20, ringIntensity + 20, Color(255, 255, 255, 100))
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        print("[Arcade Spawner] Glow rendering error: " .. tostring(err))
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SCREEN EFFECTS MANAGEMENT
-- ═══════════════════════════════════════════════════════════════
hook.Add("RenderScreenspaceEffects", "ArcadeSpawner_ScreenEffects", function()
    for effectName, effectData in pairs(Effects.ScreenEffects) do
        if effectData and effectData.effect and effectData.endTime > CurTime() then
            local timeLeft = effectData.endTime - CurTime()
            local fadeTime = effectData.fadeTime or 1.0
            local alpha = math.min(1, timeLeft / fadeTime)
            
            local modifiedEffect = {}
            for key, value in pairs(effectData.effect) do
                if type(value) == "number" then
                    modifiedEffect[key] = value * alpha
                else
                    modifiedEffect[key] = value
                end
            end
            
            DrawColorModify(modifiedEffect)
        elseif effectData and effectData.endTime <= CurTime() then
            Effects.ScreenEffects[effectName] = nil
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EFFECT REGISTRATION
-- ═══════════════════════════════════════════════════════════════
if effects then
    effects.Register({
        Init = function(data)
            local success, err = pcall(EnhancedSpawnEffect, data)
            if not success then
                print("[Arcade Spawner] Spawn effect error: " .. tostring(err))
            end
        end,
        Think = function() end,
        Render = function() end
    }, "arcade_spawn_effect")

    effects.Register({
        Init = function(data)
            local success, err = pcall(EpicLevelUpEffect, data)
            if not success then
                print("[Arcade Spawner] Level up effect error: " .. tostring(err))
            end
        end,
        Think = function() end,
        Render = function() end
    }, "arcade_levelup_effect")

    effects.Register({
        Init = function(data)
            local success, err = pcall(EnhancedDeathEffect, data)
            if not success then
                print("[Arcade Spawner] Death effect error: " .. tostring(err))
            end
        end,
        Think = function() end,
        Render = function() end
    }, "arcade_death_effect")
end

-- Enhanced enemy death effect hook
hook.Add("OnEntityKilled", "ArcadeSpawner_DeathEffect", function(ent, inflictor, attacker)
    if IsValid(ent) and ent.IsArcadeEnemy then
        local pos = ent:GetPos()
        local rarity = 1
        
        if ent.RarityType then
            local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
            for i, rarityName in ipairs(rarities) do
                if ent.RarityType == rarityName then
                    rarity = i
                    break
                end
            end
        end
        
        local effectData = EffectData()
        effectData:SetOrigin(pos)
        effectData:SetMagnitude(rarity)
        util.Effect("arcade_death_effect", effectData)
    end
end)

-- Enhanced cleanup timer
timer.Create("ArcadeSpawner_EffectsCleanup", 5, 0, function()
    local currentTime = CurTime()
    
    -- Clean up dynamic lights
    for i = #Effects.DynamicLights, 1, -1 do
        local lightData = Effects.DynamicLights[i]
        if lightData.endTime <= currentTime then
            table.remove(Effects.DynamicLights, i)
        end
    end
    
    -- Clean up sound cache
    for key, _ in pairs(Effects.SoundCache) do
        Effects.SoundCache[key] = nil
    end
    
    -- Clean up old effect timers
    for key, time in pairs(Effects.LastEffectTime) do
        if (currentTime - time) > 60 then
            Effects.LastEffectTime[key] = nil
        end
    end
end)

print("[Arcade Spawner] 🎆 BULLETPROOF Enhanced Effects System v4.1 loaded!")