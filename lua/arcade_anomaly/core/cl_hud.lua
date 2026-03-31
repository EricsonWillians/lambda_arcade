--[[
    Arcade Anomaly: Enhanced High-Contrast HUD
--]]

AA.HUD = AA.HUD or {}
AA.HUD.Data = {
    score = 0,
    highScore = 0,
    combo = 0,
    multiplier = 1.0,
    comboTime = 0,
    runState = AA.Types.RunState.IDLE,
    enemyCount = 0,
}

AA.HUD.Anims = {
    scorePulse = 0,
    comboPulse = 0,
    healthFlash = 0,
    damageIndicator = 0,
    lastHealth = 100,
}

AA.HUD.KillFeed = {}
AA.HUD.FloatingTexts = {}

-- Colors - HIGH CONTRAST
AA.HUD.Colors = {
    -- Backgrounds (dark, opaque)
    bgDark = Color(0, 0, 0, 220),
    bgPanel = Color(10, 10, 15, 200),
    bgTransparent = Color(0, 0, 0, 150),
    
    -- Health (bright, high contrast)
    healthHigh = Color(50, 255, 50),      -- Bright green
    healthMed = Color(255, 220, 0),        -- Bright yellow
    healthLow = Color(255, 40, 40),        -- Bright red
    healthCritical = Color(255, 0, 0),     -- Pure red
    
    -- UI Elements (vibrant)
    accent = Color(0, 200, 255),           -- Cyan
    accentHot = Color(255, 100, 0),        -- Orange/Red
    gold = Color(255, 215, 0),             -- Gold
    white = Color(255, 255, 255),
    black = Color(0, 0, 0),
    
    -- Threat levels
    threatLow = Color(100, 255, 100),
    threatMed = Color(255, 255, 0),
    threatHigh = Color(255, 50, 50),
}

-- Hook up network updates
hook.Add("AA_ScoreUpdated", "AA_HUD_Score", function(score, highScore)
    local oldScore = AA.HUD.Data.score
    AA.HUD.Data.score = score
    AA.HUD.Data.highScore = highScore
    if score > oldScore then
        AA.HUD.Anims.scorePulse = 1
    end
end)

hook.Add("AA_ComboUpdated", "AA_HUD_Combo", function(combo, multiplier, timeRemaining)
    local oldCombo = AA.HUD.Data.combo
    AA.HUD.Data.combo = combo
    AA.HUD.Data.multiplier = multiplier
    AA.HUD.Data.comboTime = timeRemaining
    if combo > oldCombo and combo > 1 then
        AA.HUD.Anims.comboPulse = 1
        AA.HUD:AddFloatingText("COMBO x" .. combo, ScrW()/2, ScrH() * 0.25, AA.HUD.Colors.gold)
    end
end)

hook.Add("AA_RunStateChanged", "AA_HUD_RunState", function(state, data)
    AA.HUD.Data.runState = state
end)

-- Hide default HUD (KEEP HL2 Health/Armor/Weapons)
local hideElements = {
    -- CHudHealth = true,     -- KEEP HL2 Health
    -- CHudBattery = true,    -- KEEP HL2 Armor/Suit
    -- CHudAmmo = true,       -- KEEP HL2 Ammo
    -- CHudSecondaryAmmo = true, -- KEEP HL2 Secondary Ammo
    CHudSuitPower = true,
    CHudPoisonDamageIndicator = true,
    CHudSquadStatus = true,
}

hook.Add("HUDShouldDraw", "AA_HUD_Hide", function(name)
    if AA.HUD.Hidden then return end
    local state = AA.HUD.Data.runState
    if state == AA.Types.RunState.RUNNING or state == AA.Types.RunState.COUNTDOWN then
        if hideElements[name] then return false end
    end
end)

-- Main HUD Paint
hook.Add("HUDPaint", "AA_HUD_Main", function()
    if AA.HUD.Hidden then return end
    
    local state = AA.HUD.Data.runState
    AA.HUD:DrawDamageVignette()
    
    if state ~= AA.Types.RunState.RUNNING and state ~= AA.Types.RunState.COUNTDOWN then
        return
    end
    
    local w, h = ScrW(), ScrH()
    
    -- Arcade-specific HUD elements (HL2 Health/Armor/Ammo remain visible)
    AA.HUD:DrawScore(w, h)
    AA.HUD:DrawCombo(w, h)
    AA.HUD:DrawThreatMeter(w, h)
    AA.HUD:DrawKillFeed(w, h)
    AA.HUD:DrawFloatingTexts(w, h)
    
    if state == AA.Types.RunState.COUNTDOWN then
        AA.HUD:DrawCountdown(w, h)
    end
    
    AA.HUD:UpdateAnims()
end)

function AA.HUD:UpdateAnims()
    local ft = FrameTime()
    self.Anims.scorePulse = math.max(0, self.Anims.scorePulse - ft * 3)
    self.Anims.comboPulse = math.max(0, self.Anims.comboPulse - ft * 4)
    self.Anims.healthFlash = math.max(0, self.Anims.healthFlash - ft * 5)
    self.Anims.damageIndicator = math.max(0, self.Anims.damageIndicator - ft * 2)
    
    local ply = LocalPlayer()
    if IsValid(ply) then
        local health = ply:Health()
        if health < self.Anims.lastHealth then
            self.Anims.damageIndicator = 0.6
            self.Anims.healthFlash = 1
        end
        self.Anims.lastHealth = health
    end
end

-- HIGH CONTRAST CIRCULAR HEALTH
function AA.HUD:DrawHighContrastHealth(w, h)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local health = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    if maxHealth <= 0 then maxHealth = 100 end
    local healthFrac = math.Clamp(health / maxHealth, 0, 1)
    local armor = ply:Armor()
    
    -- Position - bottom left, larger
    local x = w * 0.1
    local y = h * 0.88
    local radius = 65
    local barThickness = 12
    
    local colors = self.Colors
    
    -- Flash on low health
    local flashAlpha = 0
    if healthFrac < 0.25 then
        flashAlpha = math.abs(math.sin(CurTime() * 8)) * 80
    end
    
    -- Outer glow ring (when damaged or low health)
    if flashAlpha > 0 or self.Anims.healthFlash > 0 then
        local glowSize = radius + 15
        local glowAlpha = math.max(flashAlpha, self.Anims.healthFlash * 100)
        surface.SetDrawColor(255, 0, 0, glowAlpha)
        surface.DrawCircle(x, y, glowSize, 32)
    end
    
    -- Background circle (dark)
    surface.SetDrawColor(20, 20, 25, 240)
    surface.DrawCircle(x, y, radius, 32)
    
    -- Health color based on percentage
    local healthColor
    if healthFrac > 0.6 then
        healthColor = colors.healthHigh
    elseif healthFrac > 0.3 then
        healthColor = colors.healthMed
    elseif healthFrac > 0.15 then
        healthColor = colors.healthLow
    else
        healthColor = colors.healthCritical
    end
    
    -- Apply flash
    if flashAlpha > 0 then
        healthColor = Color(
            math.min(255, healthColor.r + flashAlpha * 2),
            healthColor.g,
            healthColor.b
        )
    end
    
    -- Draw health arc (thick ring)
    local segments = 48
    local arcAngle = healthFrac * 360
    
    for i = 0, segments - 1 do
        local angle = (i / segments) * 360 - 90
        local nextAngle = ((i + 1) / segments) * 360 - 90
        
        if angle <= arcAngle - 90 then
            local rad1 = math.rad(angle)
            local rad2 = math.rad(nextAngle)
            
            local x1 = x + math.cos(rad1) * (radius - barThickness/2)
            local y1 = y + math.sin(rad1) * (radius - barThickness/2)
            local x2 = x + math.cos(rad2) * (radius - barThickness/2)
            local y2 = y + math.sin(rad2) * (radius - barThickness/2)
            
            surface.SetDrawColor(healthColor)
            surface.DrawLine(x1, y1, x2, y2)
            
            -- Draw thick line by drawing multiple
            surface.SetDrawColor(healthColor.r, healthColor.g, healthColor.b, 200)
            surface.DrawLine(x1-1, y1, x2-1, y2)
            surface.DrawLine(x1+1, y1, x2+1, y2)
        end
    end
    
    -- Inner background for text
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawCircle(x, y, radius - barThickness - 3, 32)
    
    -- Health text - LARGE and CLEAR
    local hpText = tostring(health)
    draw.SimpleText(hpText, "AA_Health_Glow", x+2, y-5, Color(0,0,0,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(hpText, "AA_Health", x, y-5, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- HP label
    draw.SimpleText("HP", "AA_Tiny", x, y + 22, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Armor bar (outer ring)
    if armor > 0 then
        local armorRadius = radius + 10
        local armorFrac = math.Clamp(armor / 100, 0, 1)
        local armorColor = colors.accent
        local armorAngle = armorFrac * 360
        
        for i = 0, segments - 1 do
            local angle = (i / segments) * 360 - 90
            local nextAngle = ((i + 1) / segments) * 360 - 90
            
            if angle <= armorAngle - 90 then
                local rad1 = math.rad(angle)
                local rad2 = math.rad(nextAngle)
                
                local x1 = x + math.cos(rad1) * armorRadius
                local y1 = y + math.sin(rad1) * armorRadius
                local x2 = x + math.cos(rad2) * armorRadius
                local y2 = y + math.sin(rad2) * armorRadius
                
                surface.SetDrawColor(armorColor)
                surface.DrawLine(x1, y1, x2, y2)
            end
        end
        
        draw.SimpleText(armor, "AA_Tiny", x, y - radius - 15, armorColor, TEXT_ALIGN_CENTER)
    end
    
    -- Low health warning text
    if healthFrac < 0.25 then
        local warningAlpha = math.abs(math.sin(CurTime() * 6)) * 255
        draw.SimpleText("CRITICAL", "AA_Tiny", x, y + radius + 20, 
            Color(255, 0, 0, warningAlpha), TEXT_ALIGN_CENTER)
    end
end

function AA.HUD:DrawScore(w, h)
    local x = w * 0.5
    local y = h * 0.06
    local colors = self.Colors
    
    local pulse = math.sin(CurTime() * 10) * self.Anims.scorePulse * 5
    local scoreText = AA.Util and AA.Util.FormatScore(self.Data.score or 0) 
                      or string.format("%09d", self.Data.score or 0)
    
    -- Glow on score increase
    if self.Anims.scorePulse > 0.1 then
        draw.SimpleText(scoreText, "AA_Mono_Glow", x, y + pulse, 
            Color(colors.gold.r, colors.gold.g, colors.gold.b, 200 * self.Anims.scorePulse), 
            TEXT_ALIGN_CENTER)
    end
    
    -- Main score (bright white for contrast)
    draw.SimpleText(scoreText, "AA_Mono", x, y + pulse, colors.white, TEXT_ALIGN_CENTER)
    
    -- Best score indicator
    local bestY = y + 50
    if (self.Data.score or 0) >= (self.Data.highScore or 0) and self.Data.score > 0 then
        local flash = math.abs(math.sin(CurTime() * 8)) * 255
        draw.SimpleText("NEW RECORD!", "AA_Label", x, bestY, 
            Color(colors.gold.r, colors.gold.g, colors.gold.b, flash), TEXT_ALIGN_CENTER)
    else
        local bestText = "BEST: " .. (AA.Util and AA.Util.FormatScore(self.Data.highScore) 
                        or string.format("%09d", self.Data.highScore or 0))
        draw.SimpleText(bestText, "AA_Tiny", x, bestY, Color(120, 120, 120), TEXT_ALIGN_CENTER)
    end
end

function AA.HUD:DrawCombo(w, h)
    local combo = self.Data.combo or 0
    if combo <= 0 then return end
    
    local colors = self.Colors
    local x = w * 0.88
    local y = h * 0.15
    local mult = self.Data.multiplier or 1.0
    
    -- Color based on multiplier
    local color = colors.gold
    if mult >= 3.0 then
        color = colors.healthCritical
    elseif mult >= 2.0 then
        color = colors.healthMed
    end
    
    local pulse = math.sin(CurTime() * 15) * self.Anims.comboPulse * 3
    
    -- Glow
    if self.Anims.comboPulse > 0.1 then
        draw.SimpleText("x" .. combo, "AA_Large_Glow", x, y + pulse, 
            Color(color.r, color.g, color.b, 200 * self.Anims.comboPulse), TEXT_ALIGN_CENTER)
    end
    
    -- Combo text
    draw.SimpleText("x" .. combo, "AA_Large", x, y + pulse, color, TEXT_ALIGN_CENTER)
    draw.SimpleText("COMBO", "AA_Label", x, y - 35, Color(150, 150, 150), TEXT_ALIGN_CENTER)
    
    -- Multiplier
    if mult > 1.0 then
        draw.SimpleText("x" .. string.format("%.1f", mult), "AA_Medium", x, y + 55, color, TEXT_ALIGN_CENTER)
    end
    
    -- Timer bar
    local barWidth = 120
    local barHeight = 6
    local maxTime = 5.0
    local timerFrac = math.Clamp((self.Data.comboTime or 0) / maxTime, 0, 1)
    
    -- Bar background
    surface.SetDrawColor(30, 30, 35, 200)
    surface.DrawRect(x - barWidth / 2, y + 95, barWidth, barHeight)
    
    -- Bar fill (bright)
    surface.SetDrawColor(color.r, color.g, color.b, 255)
    surface.DrawRect(x - barWidth / 2, y + 95, barWidth * timerFrac, barHeight)
    
    -- Bar glow line
    surface.SetDrawColor(color.r, color.g, color.b, 150)
    surface.DrawRect(x - barWidth / 2, y + 94, barWidth * timerFrac, 2)
end

function AA.HUD:DrawThreatMeter(w, h)
    local enemyCount = self.Data.enemyCount or 0
    local maxEnemies = AA.Config.Game.MaxEnemyCap or 25
    local pressure = math.Clamp(enemyCount / maxEnemies, 0, 1)
    
    if pressure < 0.05 then return end
    
    local colors = self.Colors
    local x = w - 80
    local y = h * 0.5
    local width = 16
    local height = 180
    
    -- Background
    surface.SetDrawColor(10, 10, 15, 200)
    surface.DrawRect(x - width/2, y - height/2, width, height)
    
    -- Border
    surface.SetDrawColor(50, 50, 60, 255)
    surface.DrawOutlinedRect(x - width/2, y - height/2, width, height, 1)
    
    -- Fill color
    local fillColor = colors.threatLow
    if pressure > 0.33 then fillColor = colors.threatMed end
    if pressure > 0.66 then fillColor = colors.threatHigh end
    
    -- Pulse at high threat
    local pulse = 0
    if pressure > 0.8 then
        pulse = math.abs(math.sin(CurTime() * 10)) * 40
    end
    
    -- Fill bar (grows from bottom)
    local fillHeight = height * pressure
    surface.SetDrawColor(
        math.min(255, fillColor.r + pulse),
        fillColor.g,
        fillColor.b,
        255
    )
    surface.DrawRect(x - width/2 + 2, y + height/2 - fillHeight - 2, width - 4, fillHeight - 4)
    
    -- Label
    draw.SimpleText("THREAT", "AA_Label", x, y - height/2 - 15, Color(150, 150, 150), TEXT_ALIGN_CENTER)
    
    -- Percentage
    local pctText = math.floor(pressure * 100) .. "%"
    draw.SimpleText(pctText, "AA_Tiny", x, y + height/2 + 10, fillColor, TEXT_ALIGN_CENTER)
end

function AA.HUD:DrawKillFeed(w, h)
    local x = w - 20
    local y = h * 0.25
    local lineHeight = 28
    local colors = self.Colors
    
    for i, kill in ipairs(self.KillFeed) do
        local age = CurTime() - kill.time
        local alpha = math.max(0, 255 - age * 70)
        
        if alpha > 0 then
            local color = kill.elite and Color(255, 80, 80, alpha) or Color(220, 220, 220, alpha)
            local text = kill.elite and "★ " .. kill.text .. " (ELITE)" or kill.text
            
            draw.SimpleText(text, "AA_KillFeed", x, y + (i-1) * lineHeight, color, TEXT_ALIGN_RIGHT)
            
            -- Score popup
            if age < 0.5 then
                local scoreText = "+" .. kill.score
                local scoreAlpha = (0.5 - age) * 510
                draw.SimpleText(scoreText, "AA_Floating", x - 10, y + (i-1) * lineHeight - 20, 
                    Color(colors.gold.r, colors.gold.g, colors.gold.b, scoreAlpha), TEXT_ALIGN_RIGHT)
            end
        end
    end
    
    -- Clean old
    for i = #self.KillFeed, 1, -1 do
        if CurTime() - self.KillFeed[i].time > 4 then
            table.remove(self.KillFeed, i)
        end
    end
end

function AA.HUD:AddKillFeed(enemy)
    local enemyClass = enemy:GetClass() or "Unknown"
    local enemyName = string.gsub(enemyClass, "aa_enemy_", "")
    enemyName = string.upper(string.sub(enemyName, 1, 1)) .. string.sub(enemyName, 2)
    
    table.insert(self.KillFeed, {
        text = "Killed " .. enemyName,
        elite = enemy.IsElite or false,
        time = CurTime(),
        score = enemy.ScoreValue or 100,
    })
    
    while #self.KillFeed > 5 do
        table.remove(self.KillFeed, 1)
    end
end

function AA.HUD:AddFloatingText(text, x, y, color, duration)
    duration = duration or 1.5
    table.insert(self.FloatingTexts, {
        text = text,
        x = x,
        y = y,
        color = color or self.Colors.white,
        startTime = CurTime(),
        duration = duration,
    })
end

function AA.HUD:DrawFloatingTexts(w, h)
    for i = #self.FloatingTexts, 1, -1 do
        local ft = self.FloatingTexts[i]
        local age = CurTime() - ft.startTime
        
        if age > ft.duration then
            table.remove(self.FloatingTexts, i)
        else
            local progress = age / ft.duration
            local y = ft.y - progress * 50
            local alpha = math.max(0, 255 * (1 - progress))
            local scale = 1 + progress * 0.3
            
            local col = Color(ft.color.r, ft.color.g, ft.color.b, alpha)
            
            -- Shadow for contrast
            draw.SimpleText(ft.text, "AA_Floating_Big", ft.x+2, y+2, Color(0,0,0,alpha*0.5), TEXT_ALIGN_CENTER)
            draw.SimpleText(ft.text, "AA_Floating_Big", ft.x, y, col, TEXT_ALIGN_CENTER)
        end
    end
end

function AA.HUD:DrawCountdown(w, h)
    local x = w / 2
    local y = h / 2
    local colors = self.Colors
    local pulse = math.abs(math.sin(CurTime() * 4)) * 10
    
    -- Glow
    draw.SimpleText("GET READY", "AA_Countdown_Glow", x, y, 
        Color(colors.accent.r, colors.accent.g, colors.accent.b, 150 + pulse * 5), 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Main text
    draw.SimpleText("GET READY", "AA_Countdown", x, y, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Subtitle
    draw.SimpleText("SURVIVE THE HORDE", "AA_Small", x, y + 80, Color(150, 150, 150), TEXT_ALIGN_CENTER)
end

function AA.HUD:DrawDamageVignette()
    if self.Anims.damageIndicator <= 0 then return end
    
    local alpha = self.Anims.damageIndicator * 180
    local w, h = ScrW(), ScrH()
    
    -- Red vignette
    surface.SetDrawColor(200, 0, 0, alpha)
    
    -- Top
    surface.DrawRect(0, 0, w, h * 0.12)
    -- Bottom
    surface.DrawRect(0, h * 0.88, w, h * 0.12)
    -- Left
    surface.DrawRect(0, h * 0.12, w * 0.08, h * 0.76)
    -- Right
    surface.DrawRect(w * 0.92, h * 0.12, w * 0.08, h * 0.76)
end

-- Helper
function surface.DrawCircle(x, y, radius, segments)
    segments = segments or 32
    for i = 0, segments - 1 do
        local a1 = (i / segments) * math.pi * 2
        local a2 = ((i + 1) / segments) * math.pi * 2
        surface.DrawLine(
            x + math.cos(a1) * radius,
            y + math.sin(a1) * radius,
            x + math.cos(a2) * radius,
            y + math.sin(a2) * radius
        )
    end
end

-- Console commands
concommand.Add("aa_hud_toggle", function()
    AA.HUD.Hidden = not AA.HUD.Hidden
end)
