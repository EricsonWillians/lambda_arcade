-- addons/arcade_spawner/lua/arcade_spawner/client/hud.lua
-- BULLETPROOF Enhanced HUD with Direction Indicators v5.0

if not ArcadeSpawner then ArcadeSpawner = {} end

local HUD = {}
HUD.PlayerData = {xp = 0, level = 1, requiredXP = 100}
HUD.SessionActive = false
HUD.SessionData = {
    enemiesKilled = 0,
    currentWave = 1,
    sessionTime = 0,
    startTime = 0,
    enemiesRemaining = 0,
    enemiesTarget = 10,
    isBossWave = false
}
HUD.Notifications = {}
HUD.FontsCreated = false
HUD.EnemyTracker = {}
HUD.Initialized = false
HUD.NetworkInitialized = false
HUD.DirectionIndicators = {}
HUD.LastDamageTime = {}
HUD.MaxTrackerDistance = 4000
HUD.AmbientSound = nil
HUD.WorkshopProgress = nil

function HUD.StartAmbience()
    if HUD.AmbientSound or not GetConVar("arcade_creepy_fx"):GetBool() then return end
    if not LocalPlayer or not IsValid(LocalPlayer()) then return end

    HUD.AmbientSound = CreateSound(LocalPlayer(), "ambient/halloween/ghosts.wav")
    if HUD.AmbientSound then
        HUD.AmbientSound:PlayEx(0.5, 90)
    end

    ArcadeSpawner.Effects = ArcadeSpawner.Effects or {}
    ArcadeSpawner.Effects.ScreenEffects.ambience = {
        effect = {
            ["$pp_colour_brightness"] = -0.05,
            ["$pp_colour_contrast"] = 1.1,
            ["$pp_colour_colour"] = 0.6
        },
        endTime = math.huge,
        fadeTime = 2
    }
end

function HUD.StopAmbience()
    if HUD.AmbientSound then
        HUD.AmbientSound:Stop()
        HUD.AmbientSound = nil
    end
    if ArcadeSpawner and ArcadeSpawner.Effects and ArcadeSpawner.Effects.ScreenEffects then
        ArcadeSpawner.Effects.ScreenEffects.ambience = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED AUTO-INITIALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function ForceInitializeHUD()
    if HUD.Initialized then return end
    
    print("[Arcade Spawner] 🎯 Force initializing HUD system...")
    
    HUD.CreateASCIIFonts()
    HUD.InitializeNetworking()
    HUD.SetupAutoUpdate()
    
    HUD.Initialized = true
    print("[Arcade Spawner] ✅ HUD system force initialized!")
end

-- Auto-initialize on multiple triggers
hook.Add("Initialize", "ArcadeSpawner_HUD_AutoInit", ForceInitializeHUD)
hook.Add("InitPostEntity", "ArcadeSpawner_HUD_PostInit", function()
    timer.Simple(1, ForceInitializeHUD)
end)

hook.Add("OnEntityCreated", "ArcadeSpawner_HUD_MapLoad", function(ent)
    if not HUD.Initialized and IsValid(LocalPlayer()) then
        timer.Simple(0.5, ForceInitializeHUD)
    end
end)

timer.Create("ArcadeSpawner_HUD_NetworkCheck", 5, 0, function()
    if not HUD.NetworkInitialized and LocalPlayer and IsValid(LocalPlayer()) then
        HUD.InitializeNetworking()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- BULLETPROOF FONT SYSTEM
-- ═══════════════════════════════════════════════════════════════
function HUD.CreateASCIIFonts()
    if HUD.FontsCreated then return end
    
    local fonts = {
        {"ArcadeHUD_Title", {font = "Courier New", size = 24, weight = 800, antialias = true, shadow = true}},
        {"ArcadeHUD_Large", {font = "Courier New", size = 24, weight = 700, antialias = true, shadow = true}},
        {"ArcadeHUD_Medium", {font = "Courier New", size = 16, weight = 600, antialias = true, shadow = true}},
        {"ArcadeHUD_Small", {font = "Courier New", size = 14, weight = 500, antialias = true}},
        {"ArcadeHUD_Mono", {font = "Courier New", size = 12, weight = 400, antialias = false}},
        {"ArcadeHUD_Direction", {font = "Arial", size = 18, weight = 800, antialias = true, shadow = true}}
    }
    
    for _, fontData in ipairs(fonts) do
        local success = pcall(function()
            surface.CreateFont(fontData[1], fontData[2])
        end)
        
        if not success then
            pcall(function()
                surface.CreateFont(fontData[1], {
                    font = "Arial",
                    size = fontData[2].size,
                    weight = fontData[2].weight,
                    antialias = true
                })
            end)
        end
    end
    
    HUD.FontsCreated = true
    print("[Arcade Spawner] 🔤 ASCII fonts created successfully!")
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED NETWORK HANDLING WITH PROPER TRACKING
-- ═══════════════════════════════════════════════════════════════
function HUD.InitializeNetworking()
    if HUD.NetworkInitialized then return end
    
    local networkHandlers = {
        ["ArcadeSpawner_SessionStart"] = function()
            HUD.SessionActive = true
            HUD.SessionData.startTime = CurTime()
            HUD.SessionData.enemiesKilled = 0
            HUD.SessionData.currentWave = 1
            HUD.SessionData.enemiesRemaining = net.ReadInt(16) or 10
            HUD.SessionData.enemiesTarget = HUD.SessionData.enemiesRemaining
            HUD.StartAmbience()
            HUD.AddNotification(">>> ARCADE MODE ACTIVATED <<<", Color(0, 255, 0), 4)
            print("[Arcade Spawner] 📡 Session started! Target: " .. HUD.SessionData.enemiesTarget)
        end,
        
        ["ArcadeSpawner_SessionEnd"] = function()
            local kills = net.ReadInt(32)
            local wave = net.ReadInt(16)
            local sessionTime = net.ReadInt(16)

            HUD.SessionActive = false
            HUD.StopAmbience()
            
            local minutes = math.floor(sessionTime / 60)
            local seconds = sessionTime % 60
            
            HUD.AddNotification(string.format(">>> SESSION END: %d KILLS, WAVE %d, TIME %d:%02d <<<", 
                               kills, wave, minutes, seconds), Color(255, 100, 100), 6)
            print("[Arcade Spawner] 📡 Session ended!")
        end,
        
        ["ArcadeSpawner_WaveStart"] = function()
            local wave = net.ReadInt(16)
            local target = net.ReadInt(16)
            local isBoss = net.ReadBool()

            HUD.SessionData.currentWave = wave
            HUD.SessionData.enemiesTarget = target
            HUD.SessionData.enemiesRemaining = target
            HUD.SessionData.isBossWave = isBoss

            if isBoss then
                HUD.AddNotification(">>> BOSS WAVE " .. wave .. " INCOMING! <<<", Color(255, 50, 50), 5)
            else
                HUD.AddNotification(">>> WAVE " .. wave .. " START: " .. target .. " ENEMIES <<<", Color(100, 150, 255), 3)
            end
            
            print("[Arcade Spawner] 📡 Wave " .. wave .. " started! Target: " .. target)
        end,

        ["ArcadeSpawner_WaveComplete"] = function()
            local wave = net.ReadInt(16)
            HUD.AddNotification(string.format(">>> WAVE %d COMPLETE <<<", wave), Color(100,255,100), 4)
            HUD.SessionData.enemiesRemaining = 0
            HUD.SessionData.currentWave = wave
            HUD.SessionData.waveCompleteTime = CurTime()
        end,
        
        ["ArcadeSpawner_EnemyKilled"] = function()
            local totalKills = net.ReadInt(32)
            local currentWave = net.ReadInt(16)
            local xp = net.ReadInt(16)
            local isBoss = net.ReadBool()
            local remaining = net.ReadInt(16)

            HUD.SessionData.enemiesKilled = totalKills
            HUD.SessionData.currentWave = currentWave
            HUD.SessionData.enemiesRemaining = remaining
            
            if isBoss then
                HUD.AddNotification(">>> BOSS DEFEATED! <<<", Color(255, 215, 0), 3)
            end
            
            print("[Arcade Spawner] 📡 Enemy killed! Remaining: " .. HUD.SessionData.enemiesRemaining)
        end,

        ["ArcadeSpawner_WaveInfo"] = function()
            local wave = net.ReadInt(16)
            local remaining = net.ReadInt(16)
            local target = net.ReadInt(16)
            HUD.SessionData.currentWave = wave
            HUD.SessionData.enemiesRemaining = remaining
            HUD.SessionData.enemiesTarget = target
        end,
        
        ["ArcadeSpawner_PlayerXP"] = function()
            HUD.PlayerData.xp = net.ReadInt(32)
            HUD.PlayerData.level = net.ReadInt(16)
            HUD.PlayerData.requiredXP = net.ReadInt(32)
        end,
        
        ["ArcadeSpawner_LevelUp"] = function()
            local newLevel = net.ReadInt(16)
            HUD.PlayerData.level = newLevel
            HUD.AddNotification(">>> LEVEL UP! NOW LEVEL " .. newLevel .. " <<<", Color(255, 215, 0), 4)
        end,

        ["ArcadeSpawner_WorkshopProgress"] = function()
            local count = net.ReadInt(16)
            local total = net.ReadInt(16)
            HUD.WorkshopProgress = {count = count, total = total, timestamp = CurTime()}
            if count >= total then
                timer.Simple(2, function()
                    if HUD.WorkshopProgress and HUD.WorkshopProgress.count >= HUD.WorkshopProgress.total then
                        HUD.WorkshopProgress = nil
                    end
                end)
            end
        end
    }
    
    for networkString, handler in pairs(networkHandlers) do
        net.Receive(networkString, function()
            local success, err = pcall(handler)
            if not success then
                print("[Arcade Spawner] Network error (" .. networkString .. "): " .. tostring(err))
            end
        end)
    end
    
    HUD.NetworkInitialized = true
    print("[Arcade Spawner] 📡 Network handlers initialized!")
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO-UPDATE SYSTEM
-- ═══════════════════════════════════════════════════════════════
function HUD.SetupAutoUpdate()
    timer.Create("ArcadeSpawner_HUD_Update", 0.1, 0, function()
        if HUD.SessionActive then
            HUD.UpdateEnemyTracker()
            HUD.UpdateDirectionIndicators()
            HUD.UpdateNotifications()
        end
    end)
    
    timer.Create("ArcadeSpawner_HUD_SessionTime", 1, 0, function()
        if HUD.SessionActive and HUD.SessionData.startTime > 0 then
            HUD.SessionData.sessionTime = math.floor(CurTime() - HUD.SessionData.startTime)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED ENEMY TRACKING WITH DIRECTION INDICATORS
-- ═══════════════════════════════════════════════════════════════
function HUD.UpdateEnemyTracker()
    if not HUD.SessionActive then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    HUD.EnemyTracker = {}
    local playerPos = ply:GetPos()
    local playerAng = ply:EyeAngles()
    
    for _, ent in pairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsArcadeEnemy and ent:Alive() then
            local enemyPos = ent:GetPos()
            local distance = playerPos:Distance(enemyPos)
            
            if distance <= HUD.MaxTrackerDistance then
                local direction = (enemyPos - playerPos):GetNormalized()
                local angle = math.deg(math.atan2(direction.y, direction.x))
                local relativeAngle = angle - playerAng.y
                relativeAngle = (relativeAngle + 180) % 360 - 180
                
                table.insert(HUD.EnemyTracker, {
                    entity = ent,
                    distance = distance,
                    angle = relativeAngle,
                    rarity = ent.RarityType or "Common",
                    position = enemyPos
                })
            end
        end
    end
    
    table.sort(HUD.EnemyTracker, function(a, b) return a.distance < b.distance end)
end

function HUD.UpdateDirectionIndicators()
    if not HUD.SessionActive then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    HUD.DirectionIndicators = {}
    
    -- Track damage sources (when shot)
    local playerHealth = ply:Health()
    local currentTime = CurTime()
    
    -- Check for recent damage
    if HUD.LastPlayerHealth and playerHealth < HUD.LastPlayerHealth then
        -- Player took damage, find nearest enemy for damage indicator
        if #HUD.EnemyTracker > 0 then
            local closest = HUD.EnemyTracker[1]
            if closest.distance <= HUD.MaxTrackerDistance then
                table.insert(HUD.DirectionIndicators, {
                    angle = closest.angle,
                    type = "damage",
                    intensity = 1.0,
                    endTime = currentTime + 2.0,
                    color = Color(255, 100, 100)
                })
            end
        end
    end
    HUD.LastPlayerHealth = playerHealth
    
    -- Add proximity indicators for close enemies
    for i, enemy in ipairs(HUD.EnemyTracker) do
        if i <= 6 and enemy.distance <= 800 then -- Only show closest 6 within 800 units
            local intensity = math.Clamp(1 - (enemy.distance / 800), 0.3, 1.0)
            local color = HUD.GetRarityColor(enemy.rarity)
            
            table.insert(HUD.DirectionIndicators, {
                angle = enemy.angle,
                type = "enemy",
                intensity = intensity,
                distance = enemy.distance,
                rarity = enemy.rarity,
                color = color,
                endTime = currentTime + 0.2
            })
        end
    end

    -- Always indicate the closest enemy
    if HUD.EnemyTracker[1] then
        local nearest = HUD.EnemyTracker[1]
        table.insert(HUD.DirectionIndicators, {
            angle = nearest.angle,
            type = "nearest",
            intensity = 1.0,
            distance = nearest.distance,
            rarity = nearest.rarity,
            color = HUD.GetRarityColor(nearest.rarity),
            endTime = currentTime + 0.2
        })
    end
    
    -- Clean up expired indicators
    for i = #HUD.DirectionIndicators, 1, -1 do
        if HUD.DirectionIndicators[i].endTime < currentTime then
            table.remove(HUD.DirectionIndicators, i)
        end
    end
end

function HUD.GetRarityColor(rarity)
    local colors = {
        ["Common"] = Color(255, 255, 255),
        ["Uncommon"] = Color(30, 255, 30),
        ["Rare"] = Color(30, 144, 255),
        ["Epic"] = Color(138, 43, 226),
        ["Legendary"] = Color(255, 165, 0),
        ["Mythic"] = Color(255, 20, 147)
    }
    return colors[rarity] or colors["Common"]
end

function HUD.GetDirectionalIndicator(angle)
    local normalizedAngle = (angle + 360) % 360
    
    if normalizedAngle >= 337.5 or normalizedAngle < 22.5 then
        return "▶"  -- Right
    elseif normalizedAngle >= 22.5 and normalizedAngle < 67.5 then
        return "◢"  -- Down-Right
    elseif normalizedAngle >= 67.5 and normalizedAngle < 112.5 then
        return "▼"  -- Down
    elseif normalizedAngle >= 112.5 and normalizedAngle < 157.5 then
        return "◣"  -- Down-Left
    elseif normalizedAngle >= 157.5 and normalizedAngle < 202.5 then
        return "◀"  -- Left
    elseif normalizedAngle >= 202.5 and normalizedAngle < 247.5 then
        return "◤"  -- Up-Left
    elseif normalizedAngle >= 247.5 and normalizedAngle < 292.5 then
        return "▲"  -- Up
    else
        return "◥"  -- Up-Right
    end
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
function HUD.AddNotification(text, color, duration)
    table.insert(HUD.Notifications, {
        text = text,
        color = color or Color(255, 255, 255),
        endTime = CurTime() + (duration or 3),
        startTime = CurTime(),
        alpha = 255
    })
end

function HUD.UpdateNotifications()
    local currentTime = CurTime()
    
    for i = #HUD.Notifications, 1, -1 do
        local notification = HUD.Notifications[i]
        
        if currentTime > notification.endTime then
            table.remove(HUD.Notifications, i)
        else
            local timeLeft = notification.endTime - currentTime
            if timeLeft < 0.5 then
                notification.alpha = (timeLeft / 0.5) * 255
            else
                notification.alpha = 255
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED DRAWING FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
function HUD.DrawMainInfo(scrW, scrH)
    if not scrW or not scrH then return end
    
    local padding = 20
    local boxWidth = 380
    local boxHeight = 160
    
    draw.RoundedBox(8, padding - 2, padding - 2, boxWidth + 4, boxHeight + 4, Color(80, 80, 100, 120))
    draw.RoundedBox(6, padding, padding, boxWidth, boxHeight, Color(10, 10, 20, 200))
    
    local pulse = math.sin(CurTime() * 2) * 0.3 + 0.7
    draw.RoundedBox(8, padding - 2, padding - 2, boxWidth + 4, 2, Color(100, 150, 255, 255 * pulse))
    
    draw.SimpleText("=== ARCADE MODE ===", "ArcadeHUD_Title", padding + 15, padding + 15, 
                   Color(255, 255, 255), TEXT_ALIGN_LEFT)
    
    local waveLabel = HUD.SessionData.isBossWave and "BOSS" or tostring(HUD.SessionData.currentWave)
    local waveColor = HUD.SessionData.isBossWave and Color(255, 60, 60) or Color(255, 215, 0)
    local waveText = string.format("WAVE: %s", waveLabel)
    draw.SimpleText(waveText, "ArcadeHUD_Medium", padding + 15, padding + 45,
                   waveColor, TEXT_ALIGN_LEFT)
    
    local killText = string.format("KILLS: %d", HUD.SessionData.enemiesKilled)
    draw.SimpleText(killText, "ArcadeHUD_Medium", padding + 15, padding + 70, 
                   Color(255, 150, 150), TEXT_ALIGN_LEFT)
    
    -- FIXED: Show remaining enemies properly
    local remainingText = string.format("REMAINING: %d/%d", 
                         HUD.SessionData.enemiesRemaining, HUD.SessionData.enemiesTarget)
    local remainingColor = HUD.SessionData.enemiesRemaining > 0 and Color(255, 100, 100) or Color(100, 255, 100)
    draw.SimpleText(remainingText, "ArcadeHUD_Medium", padding + 15, padding + 95, 
                   remainingColor, TEXT_ALIGN_LEFT)
    
    local sessionTime = HUD.SessionData.sessionTime
    local minutes = math.floor(sessionTime / 60)
    local seconds = sessionTime % 60
    local timeText = string.format("TIME: %02d:%02d", minutes, seconds)
    draw.SimpleText(timeText, "ArcadeHUD_Small", padding + 15, padding + 120, 
                   Color(200, 200, 200), TEXT_ALIGN_LEFT)
    
    -- Wave progress bar
    local progressWidth = boxWidth - 30
    local progressHeight = 8
    local progressX = padding + 15
    local progressY = padding + 140
    
    draw.RoundedBox(4, progressX, progressY, progressWidth, progressHeight, Color(30, 30, 40, 220))
    
    if HUD.SessionData.enemiesTarget > 0 then
        local progress = 1 - (HUD.SessionData.enemiesRemaining / HUD.SessionData.enemiesTarget)
        local fillWidth = progressWidth * math.Clamp(progress, 0, 1)
        
        if fillWidth > 0 then
            local barColor = Color(100, 255, 100)
            if progress < 0.5 then barColor = Color(255, 255, 100) end
            if progress < 0.25 then barColor = Color(255, 100, 100) end
            
            draw.RoundedBox(4, progressX, progressY, fillWidth, progressHeight, barColor)
        end
    end
end

function HUD.DrawPlayerInfo(scrW, scrH)
    if not scrW or not scrH then return end
    
    local padding = 20
    local boxWidth = 300
    local boxHeight = 100
    local x = scrW - boxWidth - padding
    local y = padding
    
    draw.RoundedBox(6, x, y, boxWidth, boxHeight, Color(0, 0, 0, 180))
    
    local levelText = string.format("LEVEL: %d", HUD.PlayerData.level)
    draw.SimpleText(levelText, "ArcadeHUD_Large", x + 15, y + 15, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    
    local barWidth = boxWidth - 30
    local barHeight = 20
    local barX = x + 15
    local barY = y + 50
    
    draw.RoundedBox(4, barX, barY, barWidth, barHeight, Color(30, 30, 30, 200))
    
    local fillPercent = math.Clamp(HUD.PlayerData.xp / HUD.PlayerData.requiredXP, 0, 1)
    local fillWidth = fillPercent * barWidth
    
    if fillWidth > 0 then
        local barPulse = math.sin(CurTime() * 4) * 20 + 180
        draw.RoundedBox(4, barX, barY, fillWidth, barHeight, Color(0, 150, 255, barPulse))
    end
    
    local xpText = string.format("XP: %d/%d", HUD.PlayerData.xp, HUD.PlayerData.requiredXP)
    draw.SimpleText(xpText, "ArcadeHUD_Small", barX + barWidth/2, barY + barHeight/2, 
                   Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED DIRECTION INDICATOR SYSTEM
-- ═══════════════════════════════════════════════════════════════
function HUD.DrawDirectionIndicators(scrW, scrH)
    if not HUD.SessionActive or #HUD.DirectionIndicators == 0 then return end
    
    local centerX = scrW / 2
    local centerY = scrH / 2
    local radius = 140
    
    for _, indicator in ipairs(HUD.DirectionIndicators) do
        local rad = math.rad(indicator.angle)
        local x = centerX + math.cos(rad) * radius
        local y = centerY + math.sin(rad) * radius
        
        local alpha = 255 * indicator.intensity
        local color = Color(indicator.color.r, indicator.color.g, indicator.color.b, alpha)
        
        if indicator.type == "damage" then
            -- Damage indicator (red arrow pointing to damage source)
            local arrow = HUD.GetDirectionalIndicator(indicator.angle)
            local pulseAlpha = math.sin(CurTime() * 12) * 100 + 155
            color = Color(255, 50, 50, pulseAlpha)
            
            -- Draw larger damage indicator
            draw.SimpleText(arrow, "ArcadeHUD_Large", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Draw warning ring
            draw.SimpleText("⚠", "ArcadeHUD_Medium", x, y - 30, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
        elseif indicator.type == "enemy" then
            -- Enemy proximity indicator
            local arrow = HUD.GetDirectionalIndicator(indicator.angle)
            
            -- Size based on rarity and distance
            local fontSize = "ArcadeHUD_Medium"
            if indicator.rarity == "Mythic" or indicator.rarity == "Legendary" then
                fontSize = "ArcadeHUD_Large"
            end
            
            draw.SimpleText(arrow, fontSize, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Distance text for close enemies
            if indicator.distance and indicator.distance <= 400 then
                local distText = string.format("%dm", math.floor(indicator.distance / 50))
                draw.SimpleText(distText, "ArcadeHUD_Small", x, y + 25,
                               Color(255, 255, 255, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        elseif indicator.type == "nearest" then
            local arrow = HUD.GetDirectionalIndicator(indicator.angle)
            local nx = centerX + math.cos(rad) * (radius - 30)
            local ny = centerY + math.sin(rad) * (radius - 30)
            draw.SimpleText(arrow, "ArcadeHUD_Large", nx, ny, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Center crosshair
    draw.SimpleText("+", "ArcadeHUD_Medium", centerX, centerY, Color(255, 255, 255, 150), 
                   TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Info text
    if #HUD.EnemyTracker > 0 then
        local closest = HUD.EnemyTracker[1]
        local infoText = string.format("CLOSEST: %s (%dm)", 
                        closest.rarity, math.floor(closest.distance / 50))
        draw.SimpleText(infoText, "ArcadeHUD_Small", centerX, centerY + radius + 40, 
                       Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function HUD.DrawHealthArmor(scrW, scrH)
    if not HUD.SessionActive then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local padding = 25
    local barWidth = 250
    local barHeight = 30
    local x = padding
    local y = scrH - padding - barHeight * 2 - 15
    
    -- Health bar
    local health = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    
    draw.RoundedBox(6, x - 2, y - 2, barWidth + 4, barHeight + 4, Color(120, 120, 120, 150))
    draw.RoundedBox(4, x, y, barWidth, barHeight, Color(20, 20, 20, 200))
    
    local healthPercent = math.Clamp(health / maxHealth, 0, 1)
    local healthWidth = barWidth * healthPercent
    
    local healthColor = Color(255, 0, 0)
    if healthPercent > 0.6 then
        healthColor = Color(0, 255, 0)
    elseif healthPercent > 0.3 then
        healthColor = Color(255, 255, 0)
    end
    
    if healthWidth > 0 then
        draw.RoundedBox(4, x, y, healthWidth, barHeight, healthColor)
    end
    
    local healthText = string.format("HP: %d/%d", health, maxHealth)
    draw.SimpleText(healthText, "ArcadeHUD_Medium", x + barWidth/2, y + barHeight/2, 
                   Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Armor bar
    local armor = ply:Armor()
    y = y + barHeight + 8
    
    draw.RoundedBox(6, x - 2, y - 2, barWidth + 4, barHeight + 4, Color(120, 120, 120, 150))
    draw.RoundedBox(4, x, y, barWidth, barHeight, Color(20, 20, 20, 200))
    
    if armor > 0 then
        local armorWidth = barWidth * (armor / 100)
        draw.RoundedBox(4, x, y, armorWidth, barHeight, Color(0, 150, 255))
    end
    
    local armorText = string.format("ARMOR: %d/100", armor)
    draw.SimpleText(armorText, "ArcadeHUD_Medium", x + barWidth/2, y + barHeight/2, 
                   Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function HUD.DrawNotifications(scrW, scrH)
    local y = 10
    
    for _, notification in ipairs(HUD.Notifications) do
        local alpha = notification.alpha or 255
        local color = Color(notification.color.r, notification.color.g, notification.color.b, alpha)
        
        draw.RoundedBox(4, scrW - 400, y, 390, 25, Color(0, 0, 0, alpha * 0.7))
        draw.SimpleText(notification.text, "ArcadeHUD_Medium", scrW - 205, y + 12, 
                       color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        y = y + 30
    end
end

function HUD.DrawWorkshopProgress(scrW, scrH)
    local prog = HUD.WorkshopProgress
    if not prog or prog.total == 0 then return end

    local w, h = 300, 18
    local x, y = scrW / 2 - w / 2, scrH - 60
    local pct = math.Clamp(prog.count / prog.total, 0, 1)

    draw.RoundedBox(4, x, y, w, h, Color(20, 20, 20, 220))
    draw.RoundedBox(4, x, y, w * pct, h, Color(100, 200, 255, 220))
    local txt = string.format("WORKSHOP MODELS %d/%d", prog.count, prog.total)
    draw.SimpleText(txt, "ArcadeHUD_Small", x + w / 2, y + h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN HUD HOOK
-- ═══════════════════════════════════════════════════════════════
hook.Add("HUDPaint", "ArcadeSpawner_Enhanced_HUD", function()
    if not HUD.Initialized then
        ForceInitializeHUD()
        return
    end
    
    if not HUD.SessionActive then return end
    
    local scrW, scrH = ScrW(), ScrH()
    if not scrW or not scrH then return end
    
    local success, err = pcall(function()
        HUD.DrawMainInfo(scrW, scrH)
        HUD.DrawPlayerInfo(scrW, scrH)
        HUD.DrawDirectionIndicators(scrW, scrH)
        HUD.DrawHealthArmor(scrW, scrH)
        HUD.DrawNotifications(scrW, scrH)
        HUD.DrawWorkshopProgress(scrW, scrH)
    end)
    
    if not success then
        print("[Arcade Spawner] HUD Error: " .. tostring(err))
    end
end)

-- Hide default HUD elements during session
hook.Add("HUDShouldDraw", "ArcadeSpawner_HideHUD", function(name)
    if HUD.SessionActive then
        local hideElements = {"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"}
        if table.HasValue(hideElements, name) then
            return false
        end
    end
end)

-- Force initialization on various events
hook.Add("Think", "ArcadeSpawner_HUD_Think", function()
    if not HUD.Initialized and LocalPlayer and IsValid(LocalPlayer()) then
        ForceInitializeHUD()
        hook.Remove("Think", "ArcadeSpawner_HUD_Think")
    end
end)

print("[Arcade Spawner] 🎯 Enhanced HUD with Direction Indicators v5.0 loaded!")