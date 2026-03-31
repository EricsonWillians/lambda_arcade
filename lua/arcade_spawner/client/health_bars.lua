-- addons/arcade_spawner/lua/arcade_spawner/client/health_bars.lua
-- PROFESSIONAL Enemy Health Bar System v1.0

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.HealthBars = ArcadeSpawner.HealthBars or {}
local HealthBars = ArcadeSpawner.HealthBars

-- Configuration
local HEALTH_BAR_CONFIG = {
    width = 60,
    height = 8,
    offset = Vector(0, 0, 85),
    maxDistance = 1500,
    fadeDistance = 1200,
    updateRate = 0.1,
    
    -- Colors
    healthColors = {
        high = Color(50, 255, 50),
        medium = Color(255, 255, 50),
        low = Color(255, 50, 50),
        background = Color(20, 20, 20, 180),
        border = Color(255, 255, 255, 100)
    },
    
    -- Rarity effects
    rarityEffects = {
        ["Mythic"] = {pulsing = true, glow = true, particles = true},
        ["Legendary"] = {pulsing = true, glow = true},
        ["Epic"] = {pulsing = true},
        ["Rare"] = {glow = true},
        ["Uncommon"] = {},
        ["Common"] = {}
    }
}

-- Cached data
HealthBars.EnemyCache = {}
HealthBars.LastUpdate = 0

-- Update enemy cache
local function UpdateEnemyCache()
    local currentTime = CurTime()
    if currentTime - HealthBars.LastUpdate < HEALTH_BAR_CONFIG.updateRate then return end
    HealthBars.LastUpdate = currentTime
    
    HealthBars.EnemyCache = {}
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local playerPos = ply:GetPos()
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsArcadeEnemy and ent:Alive() then
            local distance = playerPos:Distance(ent:GetPos())
            
            if distance <= HEALTH_BAR_CONFIG.maxDistance then
                local maxHealth = ent:GetNWInt("ArcadeMaxHP", ent:GetMaxHealth())
                if maxHealth <= 0 then
                    maxHealth = ent:GetMaxHealth()
                end
                if maxHealth <= 0 then maxHealth = 100 end
                maxHealth = math.max(maxHealth, ent:Health(), 1)

                local health = math.Clamp(ent:Health(), 0, maxHealth)

                if health > 0 then
                    table.insert(HealthBars.EnemyCache, {
                        entity = ent,
                        distance = distance,
                        health = health,
                        maxHealth = maxHealth,
                        healthPercent = math.Clamp(health / maxHealth, 0, 1),
                        rarity = ent.RarityType or "Common",
                        position = ent:GetPos() + HEALTH_BAR_CONFIG.offset
                    })
                end
            end
        end
    end
    
    -- Sort by distance for proper rendering order
    table.sort(HealthBars.EnemyCache, function(a, b) return a.distance < b.distance end)
end

-- Get health bar color
local function GetHealthColor(healthPercent)
    local colors = HEALTH_BAR_CONFIG.healthColors
    
    if healthPercent > 0.6 then
        return colors.high
    elseif healthPercent > 0.3 then
        return colors.medium
    else
        return colors.low
    end
end

-- Get rarity color
local function GetRarityColor(rarity)
    local rarityColors = {
        ["Common"] = Color(255, 255, 255),
        ["Uncommon"] = Color(30, 255, 30),
        ["Rare"] = Color(30, 144, 255),
        ["Epic"] = Color(138, 43, 226),
        ["Legendary"] = Color(255, 165, 0),
        ["Mythic"] = Color(255, 20, 147)
    }
    return rarityColors[rarity] or rarityColors["Common"]
end

-- Draw individual health bar
local function DrawHealthBar(enemyData)
    local pos = enemyData.position
    local screenPos = pos:ToScreen()
    
    if screenPos.visible == false then return end
    
    local distance = enemyData.distance
    local alpha = 255
    
    -- Fade based on distance
    if distance > HEALTH_BAR_CONFIG.fadeDistance then
        alpha = math.Clamp(255 * (1 - (distance - HEALTH_BAR_CONFIG.fadeDistance) / 
                          (HEALTH_BAR_CONFIG.maxDistance - HEALTH_BAR_CONFIG.fadeDistance)), 0, 255)
    end
    
    local x = screenPos.x - HEALTH_BAR_CONFIG.width / 2
    local y = screenPos.y - HEALTH_BAR_CONFIG.height / 2
    local w = HEALTH_BAR_CONFIG.width
    local h = HEALTH_BAR_CONFIG.height
    
    -- Rarity effects
    local rarity = enemyData.rarity
    local rarityEffects = HEALTH_BAR_CONFIG.rarityEffects[rarity] or {}
    local currentTime = CurTime()
    
    -- Pulsing effect for high-tier enemies
    if rarityEffects.pulsing then
        local pulse = math.sin(currentTime * 4) * 0.3 + 0.7
        alpha = alpha * pulse
        w = w * (1 + pulse * 0.1)
        h = h * (1 + pulse * 0.1)
        x = screenPos.x - w / 2
        y = screenPos.y - h / 2
    end
    
    -- Glow effect
    if rarityEffects.glow then
        local glowSize = 4
        local glowColor = GetRarityColor(rarity)
        glowColor.a = alpha * 0.3
        
        draw.RoundedBox(4, x - glowSize, y - glowSize, w + glowSize * 2, h + glowSize * 2, glowColor)
    end
    
    -- Background
    local bgColor = HEALTH_BAR_CONFIG.healthColors.background
    bgColor.a = alpha * 0.8
    draw.RoundedBox(2, x, y, w, h, bgColor)
    
    -- Border
    local borderColor = HEALTH_BAR_CONFIG.healthColors.border
    borderColor.a = alpha * 0.6
    draw.RoundedBox(2, x - 1, y - 1, w + 2, h + 2, borderColor)
    
    -- Health fill
    local healthWidth = w * enemyData.healthPercent
    if healthWidth > 0 then
        local healthColor = GetHealthColor(enemyData.healthPercent)
        healthColor.a = alpha
        draw.RoundedBox(2, x, y, healthWidth, h, healthColor)
    end
    
    -- Rarity indicator stripe
    if rarity ~= "Common" then
        local rarityColor = GetRarityColor(rarity)
        rarityColor.a = alpha * 0.8
        draw.RoundedBox(0, x, y - 3, w, 2, rarityColor)
    end

    -- Hitpoint text
    local hpText = string.format("%d/%d", enemyData.health, enemyData.maxHealth)
    draw.SimpleText(hpText, "ArcadeHUD_Large", x + w / 2, y - 15,

                   Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    
    -- Damage indicators (optional)
    if enemyData.healthPercent < 0.3 then
        -- Critical health warning
        local warningAlpha = math.sin(currentTime * 8) * 127 + 128
        local warningColor = Color(255, 0, 0, warningAlpha * (alpha / 255))
        draw.RoundedBox(2, x - 2, y - 2, w + 4, h + 4, warningColor)
    end
end

-- Main rendering hook
hook.Add("HUDPaint", "ArcadeSpawner_HealthBars", function()
    UpdateEnemyCache()
    
    if #HealthBars.EnemyCache == 0 then return end
    
    -- Draw all health bars
    for _, enemyData in ipairs(HealthBars.EnemyCache) do
        local success, err = pcall(DrawHealthBar, enemyData)
        if not success then
            print("[Arcade Spawner] Health bar error: " .. tostring(err))
        end
    end
end)

print("[Arcade Spawner] 💊 Professional Health Bars v1.0 loaded!")