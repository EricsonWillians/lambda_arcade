--[[
    Arcade Anomaly: ULTRA Japanese Arcade Style Damage System
    
    Severely improved Capcom/JRPG style hit feedback with:
    - Real Japanese kanji/katakana expressions
    - Dynamic sizing and violent animations
    - Blood splatter effects
    - Combo system with milestone announcements
    - Gothic bloody aesthetic
--]]

AA.DamagePopup = AA.DamagePopup or {}
local DP = AA.DamagePopup

-- Active popups storage
DP.Active = {}
DP.ComboPopups = {}
DP.BloodParticles = {}
DP.ComboCount = 0
DP.LastHitTime = 0

-- GOTHIC BLOODY COLOR PALETTE
DP.Colors = {
    Normal      = Color(240, 240, 240),     -- Bone white
    LightHit    = Color(200, 200, 220),     -- Light gray
    MediumHit   = Color(255, 150, 150),     -- Pink
    HeavyHit    = Color(255, 80, 80),       -- Light red
    Critical    = Color(255, 30, 30),       -- Blood red
    Kill        = Color(255, 0, 0),         -- Pure red
    Lethal      = Color(180, 0, 0),         -- Dark blood
    Combo       = Color(200, 100, 255),     -- Purple
    MegaCombo   = Color(255, 215, 0),       -- Gold
    UltraCombo  = Color(0, 255, 255),       -- Cyan
    Shadow      = Color(30, 0, 0),          -- Dark blood shadow
    Blood       = Color(139, 0, 0),         -- Dark red
}

-- JAPANESE ARCADE EXPRESSIONS (Using ASCII art / stylized text for compatibility)
DP.JP = {
    -- Damage suffixes (stylized)
    DamageSmall   = " dmg",
    DamageMedium  = " DMG", 
    DamageLarge   = " DMG!!",
    DamageHuge    = " MAXDMG",
    
    -- Hit types (stylized like Japanese arcade)
    Hit       = "HIT!",
    Smash     = "SMASH!",
    Crash     = "CRASH!",
    Slash     = "SLASH!",
    
    -- Critical/Status
    Critical  = "CRIT!!",
    Fatal     = "FATAL!",
    Destroy   = "DESTROY!",
    
    -- Kill confirmations
    Kill      = "KILL!",
    Slain     = "SLAIN!",
    Obliterate = "OBLITERATE!",
    Annihilate = "ANNIHILATE!",
    
    -- Combo milestones (Capcom style)
    Combo3    = "NICE!",
    Combo5    = "GOOD!",
    Combo10   = "GREAT!",
    Combo15   = "AWESOME!",
    Combo20   = "EXCELLENT!",
    Combo25   = "FANTASTIC!",
    Combo30   = "UNBELIEVABLE!",
    Combo50   = "GODLIKE!",
    Combo100  = "LEGENDARY!",
}

-- INITIALIZE FONTS - ARCADE STYLE (Bold, high contrast)
hook.Add("Initialize", "AA_DamagePopup_InitFonts", function()
    -- Main damage number font - BOLD arcade style
    surface.CreateFont("AA_JP_Damage", {
        font = "Impact",
        size = 48,
        weight = 900,
        antialias = true,
        outline = false,
    })
    
    -- Shadow/blur font
    surface.CreateFont("AA_JP_Damage_Blur", {
        font = "Impact",
        size = 48,
        weight = 900,
        antialias = true,
        blursize = 8,
    })
    
    -- Critical hit font - larger, more dramatic
    surface.CreateFont("AA_JP_Critical", {
        font = "Impact",
        size = 64,
        weight = 900,
        antialias = true,
        italic = false,
    })
    
    -- Kill confirm font
    surface.CreateFont("AA_JP_Kill", {
        font = "Impact",
        size = 72,
        weight = 900,
        antialias = true,
    })
    
    -- Expression text font (HIT, CRIT, etc)
    surface.CreateFont("AA_JP_Text", {
        font = "Arial Black",
        size = 32,
        weight = 900,
        antialias = true,
        outline = true,
    })
    
    -- Combo milestone font
    surface.CreateFont("AA_JP_Combo", {
        font = "Impact",
        size = 52,
        weight = 900,
        antialias = true,
    })
end)

-- Get the appropriate expression based on damage and context
function DP:GetExpression(damage, isKill, isCrit, combo)
    if isKill then
        if combo >= 20 then return DP.JP.Annihilate
        elseif combo >= 10 then return DP.JP.Obliterate
        elseif combo >= 5 then return DP.JP.Slain
        else return DP.JP.Kill end
    end
    
    if isCrit then
        return DP.JP.Critical
    end
    
    if damage >= 100 then return DP.JP.Smash
    elseif damage >= 50 then return DP.JP.Crash
    elseif damage >= 25 then return DP.JP.Hit
    else return "" end
end

-- Get the damage suffix
function DP:GetDamageSuffix(damage)
    if damage >= 200 then return DP.JP.DamageHuge
    elseif damage >= 100 then return DP.JP.DamageLarge
    elseif damage >= 50 then return DP.JP.DamageMedium
    else return DP.JP.DamageSmall end
end

-- Get color based on damage severity
function DP:GetDamageColor(damage, isKill, isCrit, combo)
    if isKill then
        if combo >= 15 then return DP.Colors.UltraCombo
        elseif combo >= 10 then return DP.Colors.MegaCombo
        else return DP.Colors.Kill end
    end
    
    if isCrit then return DP.Colors.Critical end
    if damage >= 100 then return DP.Colors.HeavyHit
    elseif damage >= 50 then return DP.Colors.MediumHit
    elseif damage >= 25 then return DP.Colors.LightHit
    else return DP.Colors.Normal end
end

-- Get combo milestone expression
function DP:GetComboExpression(combo)
    if combo >= 100 then return DP.JP.Combo100
    elseif combo >= 50 then return DP.JP.Combo50
    elseif combo >= 30 then return DP.JP.Combo30
    elseif combo >= 25 then return DP.JP.Combo25
    elseif combo >= 20 then return DP.JP.Combo20
    elseif combo >= 15 then return DP.JP.Combo15
    elseif combo >= 10 then return DP.JP.Combo10
    elseif combo >= 5 then return DP.JP.Combo5
    elseif combo >= 3 then return DP.JP.Combo3
    else return nil end
end

-- CREATE A DAMAGE POPUP
function DP.Create(pos, damage, isKill, isCrit)
    local now = CurTime()
    
    -- Update combo counter
    if now - DP.LastHitTime < 2.5 then
        DP.ComboCount = DP.ComboCount + 1
    else
        DP.ComboCount = 1
    end
    DP.LastHitTime = now
    
    local combo = DP.ComboCount
    
    -- Calculate scale based on damage and context
    local baseScale = 0.7
    if isKill then baseScale = 1.4
    elseif isCrit then baseScale = 1.2
    elseif damage >= 100 then baseScale = 1.1
    elseif damage >= 50 then baseScale = 0.9
    end
    
    -- Combo scaling
    baseScale = baseScale * (1 + math.min(combo * 0.02, 0.5))
    
    -- Create the popup
    local popup = {
        pos = pos + Vector(0, 0, 50) + VectorRand() * 15,
        damage = damage,
        isKill = isKill,
        isCrit = isCrit,
        combo = combo,
        
        -- Visuals
        scale = 0,
        targetScale = math.min(baseScale, 2.0),
        color = DP:GetDamageColor(damage, isKill, isCrit, combo),
        expression = DP:GetExpression(damage, isKill, isCrit, combo),
        suffix = DP:GetDamageSuffix(damage),
        
        -- Animation
        startTime = now,
        lifeTime = isKill and 2.0 or 1.2,
        alpha = 255,
        
        -- Physics
        vel = Vector(
            math.random(-40, 40),
            math.random(-40, 40),
            math.random(80, 150)
        ),
        rotation = math.random(-20, 20),
        rotVel = math.random(-40, 40),
        
        -- Effects
        bounce = 0,
        shake = 0,
        pulse = 0,
    }
    
    table.insert(DP.Active, popup)
    
    -- Create blood splatter for big hits
    if damage >= 50 or isKill then
        DP:CreateBloodSplatter(pos, damage, isKill)
    end
    
    -- Create combo milestone popup
    local comboExpr = DP:GetComboExpression(combo)
    if comboExpr and combo % 5 == 0 then
        DP:CreateComboPopup(pos, combo, comboExpr)
    end
end

-- Create blood splatter particles
function DP:CreateBloodSplatter(pos, damage, isKill)
    local count = isKill and 15 or math.floor(damage / 10)
    count = math.min(count, 20)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 200)
        local p = {
            pos = pos + Vector(0, 0, 30),
            vel = Vector(
                math.cos(angle) * speed,
                math.sin(angle) * speed,
                math.random(50, 150)
            ),
            life = math.random(0.4, 0.8),
            start = CurTime(),
            size = math.random(3, 8),
            color = Color(
                math.random(180, 220),
                math.random(0, 30),
                math.random(0, 30),
                255
            )
        }
        table.insert(self.BloodParticles, p)
    end
end

-- Create combo milestone popup
function DP:CreateComboPopup(pos, combo, text)
    local popup = {
        pos = pos + Vector(0, 0, 80),
        text = text,
        combo = combo,
        startTime = CurTime(),
        lifeTime = 1.8,
        scale = 0,
        targetScale = 1.0 + math.min(combo * 0.02, 0.8),
        alpha = 255,
        vel = Vector(0, 0, 60),
    }
    
    -- Color based on combo level
    if combo >= 50 then popup.color = DP.Colors.UltraCombo
    elseif combo >= 25 then popup.color = DP.Colors.MegaCombo
    elseif combo >= 10 then popup.color = DP.Colors.Combo
    else popup.color = DP.Colors.Normal end
    
    table.insert(self.ComboPopups, popup)
end

-- UPDATE LOOP
hook.Add("Think", "AA_DamagePopup_Think", function()
    local ft = FrameTime()
    local now = CurTime()
    
    -- Reset combo if expired
    if now - DP.LastHitTime > 3.0 then
        if DP.ComboCount > 0 then
            DP.ComboCount = 0
        end
    end
    
    -- Update damage popups
    for i = #DP.Active, 1, -1 do
        local p = DP.Active[i]
        local age = now - p.startTime
        local progress = age / p.lifeTime
        
        if progress >= 1 then
            table.remove(DP.Active, i)
        else
            -- Pop-in animation
            if age < 0.08 then
                p.scale = p.targetScale * (age / 0.08)
            elseif age < 0.15 then
                p.scale = p.targetScale * (1.15 - (age - 0.08) / 0.07 * 0.15)
            else
                p.scale = p.targetScale * (1 - progress * 0.15)
            end
            
            -- Bounce effect
            p.bounce = math.abs(math.sin(age * 10)) * math.max(0, 1 - progress * 1.5) * 8
            
            -- Shake for criticals/kills
            if p.isCrit or p.isKill then
                p.shake = math.sin(age * 25) * math.max(0, 1 - progress) * 4
            end
            
            -- Movement
            p.pos = p.pos + p.vel * ft
            p.vel.z = p.vel.z - 120 * ft
            p.rotation = p.rotation + p.rotVel * ft
            
            -- Fade out
            if progress > 0.7 then
                p.alpha = 255 * (1 - (progress - 0.7) / 0.3)
            end
        end
    end
    
    -- Update combo popups
    for i = #DP.ComboPopups, 1, -1 do
        local p = DP.ComboPopups[i]
        local age = now - p.startTime
        local progress = age / p.lifeTime
        
        if progress >= 1 then
            table.remove(DP.ComboPopups, i)
        else
            if age < 0.1 then
                p.scale = p.targetScale * (age / 0.1)
            else
                p.scale = p.targetScale * (1 + math.sin(age * 6) * 0.08)
            end
            
            p.pos = p.pos + p.vel * ft
            p.alpha = 255 * (1 - progress)
        end
    end
    
    -- Update blood particles
    for i = #DP.BloodParticles, 1, -1 do
        local p = DP.BloodParticles[i]
        local age = now - p.start
        
        if age > p.life then
            table.remove(DP.BloodParticles, i)
        else
            p.pos = p.pos + p.vel * ft
            p.vel.z = p.vel.z - 400 * ft
            p.color.a = 255 * (1 - age / p.life)
        end
    end
end)

-- DRAW LOOP
hook.Add("HUDPaint", "AA_DamagePopup_Draw", function()
    local now = CurTime()
    
    -- Draw damage popups
    for _, p in ipairs(DP.Active) do
        local screen = p.pos:ToScreen()
        if screen.visible then
            local x = screen.x + math.sin(now * 30) * p.shake + p.rotation * 0.1
            local y = screen.y - p.bounce
            local scale = p.scale
            local alpha = p.alpha
            local color = Color(p.color.r, p.color.g, p.color.b, alpha)
            
            -- GOTHIC SHADOW LAYERS (for depth)
            for i = 5, 1, -1 do
                local offset = i * 2.5 * scale
                draw.SimpleText(
                    p.damage,
                    p.isCrit and "AA_JP_Critical" or "AA_JP_Damage_Blur",
                    x + offset,
                    y + offset,
                    Color(20, 0, 0, alpha * 0.5),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- OUTER GLOW for crits/kills
            if p.isCrit or p.isKill then
                for i = 1, 4 do
                    local glowAlpha = alpha * (0.25 - i * 0.05)
                    draw.SimpleText(
                        p.damage,
                        p.isKill and "AA_JP_Kill" or "AA_JP_Critical",
                        x,
                        y,
                        Color(255, 50, 50, glowAlpha),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            -- MAIN DAMAGE NUMBER
            local mainFont = p.isKill and "AA_JP_Kill" or 
                            (p.isCrit and "AA_JP_Critical" or "AA_JP_Damage")
            
            draw.SimpleText(
                p.damage,
                mainFont,
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            
            -- JAPANESE SUFFIX
            if p.suffix and p.suffix ~= "" then
                draw.SimpleText(
                    p.suffix,
                    "AA_JP_Text",
                    x + (p.isCrit and 50 or 35) * scale,
                    y + 8 * scale,
                    Color(255, 255, 255, alpha * 0.9),
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- EXPRESSION TEXT (Critical, Kill, etc)
            if p.expression and p.expression ~= "" then
                local exprY = y - 45 * scale
                local exprColor = p.isKill and Color(255, 200, 50, alpha) or Color(255, 100, 100, alpha)
                
                -- Shadow
                draw.SimpleText(
                    p.expression,
                    "AA_JP_Text",
                    x + 2,
                    exprY + 2,
                    Color(0, 0, 0, alpha * 0.7),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                
                -- Main expression
                draw.SimpleText(
                    p.expression,
                    "AA_JP_Text",
                    x,
                    exprY,
                    exprColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- COMBO COUNTER
            if p.combo > 1 then
                local comboText = p.combo .. " COMBO"
                local comboColor = p.combo >= 20 and DP.Colors.UltraCombo or
                                  (p.combo >= 10 and DP.Colors.MegaCombo or DP.Colors.Combo)
                comboColor = Color(comboColor.r, comboColor.g, comboColor.b, alpha)
                
                -- Shadow
                draw.SimpleText(
                    comboText,
                    "AA_JP_Text",
                    x + 2,
                    y + 32 * scale + 2,
                    Color(0, 0, 0, alpha * 0.6),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                
                draw.SimpleText(
                    comboText,
                    "AA_JP_Text",
                    x,
                    y + 32 * scale,
                    comboColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
    
    -- Draw combo milestone popups
    for _, p in ipairs(DP.ComboPopups) do
        local screen = p.pos:ToScreen()
        if screen.visible then
            local x, y = screen.x, screen.y
            local scale = p.scale
            local alpha = p.alpha
            local color = Color(p.color.r, p.color.g, p.color.b, alpha)
            
            -- Shadow layers
            for i = 3, 1, -1 do
                draw.SimpleText(
                    p.text,
                    "AA_JP_Combo",
                    x + i * 3 * scale,
                    y + i * 3 * scale,
                    Color(0, 0, 0, alpha * 0.5),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- Glow for high combos
            if p.combo >= 10 then
                for i = 1, 3 do
                    draw.SimpleText(
                        p.text,
                        "AA_JP_Combo",
                        x,
                        y,
                        Color(color.r, color.g, color.b, alpha * 0.3),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            -- Main text
            draw.SimpleText(
                p.text,
                "AA_JP_Combo",
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    end
    
    -- Draw blood particles
    for _, p in ipairs(DP.BloodParticles) do
        local screen = p.pos:ToScreen()
        if screen.visible then
            surface.SetDrawColor(p.color)
            surface.DrawRect(
                screen.x - p.size/2,
                screen.y - p.size/2,
                p.size,
                p.size
            )
        end
    end
end)

-- NETWORK RECEIVERS
net.Receive("AA_DamagePopup", function(len)
    local pos = net.ReadVector()
    local damage = net.ReadUInt(16)
    local flags = net.ReadUInt(8)
    
    -- Manual bit check for Lua 5.1 compatibility
    local isKill = flags % 2 >= 1
    local isCrit = math.floor(flags / 2) % 2 >= 1
    
    DP.Create(pos, damage, isKill, isCrit)
end)

net.Receive("ArcadeSpawner_DamageNumber", function(len)
    local pos = net.ReadVector()
    local damage = net.ReadInt(16)
    local isKill = net.ReadBool()
    
    local isCrit = damage > 50
    DP.Create(pos, damage, isKill, isCrit)
end)

print("[Arcade Anomaly]  ULTRA Japanese Damage System loaded!")
