--[[
    Arcade Anomaly: GOTHIC ARCADE Damage System
    
    Dark, bloody, arcade-style hit feedback with heavy metal aesthetics.
    Inspired by: Devil May Cry, Bayonetta, Doom, MadWorld
--]]

AA.DamagePopup = AA.DamagePopup or {}
local DP = AA.DamagePopup

-- Active popups storage
DP.Active = {}
DP.ComboPopups = {}
DP.BloodParticles = {}
DP.ComboCount = 0
DP.LastHitTime = 0

-- DARK GOTHIC METAL COLOR PALETTE
DP.Colors = {
    -- Damage tiers (dark to blood red)
    Normal      = Color(180, 180, 180),     -- Ash gray
    LightHit    = Color(220, 200, 200),     -- Pale flesh
    MediumHit   = Color(255, 120, 120),     -- Fresh wound
    HeavyHit    = Color(255, 60, 60),       -- Deep cut
    Critical    = Color(255, 20, 20),       -- Arterial spray
    Massacre    = Color(200, 0, 0),         -- Dark blood
    
    -- Kill confirmations (escalating intensity)
    Kill        = Color(255, 0, 0),         -- Blood red
    Slaughter   = Color(255, 50, 0),        -- Blood orange
    Annihilate  = Color(255, 100, 0),       -- Hellfire
    Obliterate  = Color(255, 0, 100),       -- Dark crimson
    Exterminate = Color(200, 0, 200),       -- Death purple
    
    -- Combo milestones (arcade style)
    Combo       = Color(180, 80, 255),      -- Neon purple
    MegaCombo   = Color(255, 215, 0),       -- Demon gold
    UltraCombo  = Color(0, 255, 255),       -- Soul cyan
    GodCombo    = Color(255, 255, 255),     -- Divine white
    
    -- Shadows and effects
    Shadow      = Color(10, 0, 0),          -- Deep blood shadow
    Blood       = Color(100, 0, 0),         -- Old blood
    Bone        = Color(240, 240, 230),     -- Bone white
}

-- GOTHIC ARCADE EXPRESSIONS (Heavy Metal / Dark Fantasy style)
DP.Expressions = {
    -- Damage suffixes
    DamageSmall   = "",
    DamageMedium  = "",
    DamageLarge   = "",
    DamageHuge    = "",
    
    -- Hit types (escalating violence)
    Hit       = "HIT",
    Smash     = "SMASH",
    Crush     = "CRUSH",
    Shatter   = "SHATTER",
    Devastate = "DEVASTATE",
    Decimate  = "DECIMATE",
    
    -- Critical/Status (bloody)
    Critical  = "CRITICAL",
    Brutal    = "BRUTAL",
    Savage    = "SAVAGE",
    Vicious   = "VICIOUS",
    Gore      = "GORE",
    Bloodbath = "BLOODBATH",
    Carnage   = "CARNAGE",
    
    -- Kill confirmations (escalating destruction)
    Kill       = "KILL",
    Execute    = "EXECUTE",
    Slaughter  = "SLAUGHTER",
    Massacre   = "MASSACRE",
    Annihilate = "ANNIHILATE",
    Obliterate = "OBLITERATE",
    Eradicate  = "ERADICATE",
    Exterminate = "EXTERMINATE",
    Genocide   = "GENOCIDE",
    
    -- Combo milestones (DMC/Bayonetta style)
    Combo3    = "SADISTIC!",
    Combo5    = "BRUTAL!",
    Combo10   = "SAVAGE!",
    Combo15   = "BLOODLUST!",
    Combo20   = "MAYHEM!",
    Combo25   = "CARNAGE!",
    Combo30   = "APOCALYPSE!",
    Combo50   = "GODLIKE!",
    Combo75   = "LEGENDARY!",
    Combo100  = "IMMORTAL!",
}

-- INITIALIZE FONTS - GOTHIC METAL STYLE
hook.Add("Initialize", "AA_DamagePopup_InitFonts", function()
    -- Main damage number - Heavy metal style
    surface.CreateFont("AA_Gothic_Damage", {
        font = "Impact",
        size = 52,
        weight = 900,
        antialias = true,
        outline = true,
        outline_thickness = 2,
    })
    
    -- Shadow/blur font
    surface.CreateFont("AA_Gothic_Damage_Blur", {
        font = "Impact",
        size = 52,
        weight = 900,
        antialias = true,
        blursize = 12,
    })
    
    -- Critical hit font
    surface.CreateFont("AA_Gothic_Critical", {
        font = "Impact",
        size = 72,
        weight = 900,
        antialias = true,
        outline = true,
    })
    
    -- Kill confirm font - Massive
    surface.CreateFont("AA_Gothic_Kill", {
        font = "Impact",
        size = 86,
        weight = 900,
        antialias = true,
        outline = true,
    })
    
    -- Expression text font (HIT, CRIT, etc)
    surface.CreateFont("AA_Gothic_Text", {
        font = "Arial Black",
        size = 36,
        weight = 900,
        antialias = true,
        outline = true,
    })
    
    -- Combo milestone font
    surface.CreateFont("AA_Gothic_Combo", {
        font = "Impact",
        size = 64,
        weight = 900,
        antialias = true,
        outline = true,
    })
    
    -- Small text for damage suffix
    surface.CreateFont("AA_Gothic_Small", {
        font = "Impact",
        size = 28,
        weight = 700,
        antialias = true,
    })
end)

-- Get expression based on damage/kill/crit/combo
function DP:GetExpression(damage, isKill, isCrit, combo)
    if isKill then
        if combo >= 50 then return DP.Expressions.Genocide
        elseif combo >= 30 then return DP.Expressions.Exterminate
        elseif combo >= 20 then return DP.Expressions.Obliterate
        elseif combo >= 15 then return DP.Expressions.Annihilate
        elseif combo >= 10 then return DP.Expressions.Massacre
        elseif combo >= 5 then return DP.Expressions.Slaughter
        elseif damage >= 100 then return DP.Expressions.Execute
        else return DP.Expressions.Kill end
    end
    
    if isCrit then
        if damage >= 150 then return DP.Expressions.Carnage
        elseif damage >= 100 then return DP.Expressions.Bloodbath
        elseif damage >= 75 then return DP.Expressions.Gore
        elseif damage >= 50 then return DP.Expressions.Vicious
        else return DP.Expressions.Critical end
    end
    
    if damage >= 200 then return DP.Expressions.Decimate
    elseif damage >= 150 then return DP.Expressions.Devastate
    elseif damage >= 100 then return DP.Expressions.Shatter
    elseif damage >= 75 then return DP.Expressions.Crush
    elseif damage >= 50 then return DP.Expressions.Smash
    elseif damage >= 25 then return DP.Expressions.Hit
    else return "" end
end

-- Get damage suffix with skulls for intensity
function DP:GetDamageSuffix(damage)
    if damage >= 200 then return ""
    elseif damage >= 100 then return ""
    elseif damage >= 50 then return ""
    else return "" end
end

-- Get color based on damage severity (dark gothic)
function DP:GetDamageColor(damage, isKill, isCrit, combo)
    if isKill then
        if combo >= 30 then return DP.Colors.Exterminate
        elseif combo >= 20 then return DP.Colors.Obliterate
        elseif combo >= 10 then return DP.Colors.Annihilate
        elseif combo >= 5 then return DP.Colors.Slaughter
        else return DP.Colors.Kill end
    end
    
    if isCrit then
        if damage >= 100 then return DP.Colors.Massacre
        elseif damage >= 75 then return DP.Colors.Critical
        else return DP.Colors.HeavyHit end
    end
    
    if damage >= 150 then return DP.Colors.Massacre
    elseif damage >= 100 then return DP.Colors.Critical
    elseif damage >= 75 then return DP.Colors.HeavyHit
    elseif damage >= 50 then return DP.Colors.MediumHit
    elseif damage >= 25 then return DP.Colors.LightHit
    else return DP.Colors.Normal end
end

-- Get combo milestone expression
function DP:GetComboExpression(combo)
    if combo >= 100 then return DP.Expressions.Combo100
    elseif combo >= 75 then return DP.Expressions.Combo75
    elseif combo >= 50 then return DP.Expressions.Combo50
    elseif combo >= 30 then return DP.Expressions.Combo30
    elseif combo >= 25 then return DP.Expressions.Combo25
    elseif combo >= 20 then return DP.Expressions.Combo20
    elseif combo >= 15 then return DP.Expressions.Combo15
    elseif combo >= 10 then return DP.Expressions.Combo10
    elseif combo >= 5 then return DP.Expressions.Combo5
    elseif combo >= 3 then return DP.Expressions.Combo3
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
    
    -- Calculate scale with dramatic scaling for kills/crits
    local baseScale = 0.8
    if isKill then baseScale = 1.6
    elseif isCrit then baseScale = 1.3
    elseif damage >= 100 then baseScale = 1.15
    elseif damage >= 50 then baseScale = 1.0
    end
    
    -- Combo scaling (more dramatic)
    baseScale = baseScale * (1 + math.min(combo * 0.025, 0.6))
    
    -- Create the popup
    local popup = {
        pos = pos + Vector(0, 0, 50) + VectorRand() * 20,
        damage = damage,
        isKill = isKill,
        isCrit = isCrit,
        combo = combo,
        
        -- Visuals
        scale = 0,
        targetScale = math.min(baseScale, 2.2),
        color = DP:GetDamageColor(damage, isKill, isCrit, combo),
        expression = DP:GetExpression(damage, isKill, isCrit, combo),
        suffix = DP:GetDamageSuffix(damage),
        
        -- Animation
        startTime = now,
        lifeTime = isKill and 2.2 or 1.4,
        alpha = 255,
        
        -- Physics (more violent)
        vel = Vector(
            math.random(-50, 50),
            math.random(-50, 50),
            math.random(90, 180)
        ),
        rotation = math.random(-25, 25),
        rotVel = math.random(-50, 50),
        
        -- Effects
        bounce = 0,
        shake = 0,
        pulse = 0,
    }
    
    table.insert(DP.Active, popup)
    
    -- Create blood splatter for big hits
    if damage >= 40 or isKill or isCrit then
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
    local count = isKill and 20 or math.floor(damage / 8)
    count = math.min(count, 25)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(60, 250)
        local p = {
            pos = pos + Vector(0, 0, 30),
            vel = Vector(
                math.cos(angle) * speed,
                math.sin(angle) * speed,
                math.random(60, 180)
            ),
            life = math.random(0.5, 1.0),
            start = CurTime(),
            size = math.random(4, 10),
            color = Color(
                math.random(200, 255),
                math.random(0, 40),
                math.random(0, 40),
                255
            )
        }
        table.insert(self.BloodParticles, p)
    end
end

-- Create combo milestone popup
function DP:CreateComboPopup(pos, combo, text)
    local popup = {
        pos = pos + Vector(0, 0, 90),
        text = text,
        combo = combo,
        startTime = CurTime(),
        lifeTime = 2.0,
        scale = 0,
        targetScale = 1.1 + math.min(combo * 0.025, 0.9),
        alpha = 255,
        vel = Vector(0, 0, 70),
    }
    
    -- Color based on combo level
    if combo >= 50 then popup.color = DP.Colors.GodCombo
    elseif combo >= 30 then popup.color = DP.Colors.UltraCombo
    elseif combo >= 15 then popup.color = DP.Colors.MegaCombo
    else popup.color = DP.Colors.Combo end
    
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
            -- Pop-in animation (more aggressive)
            if age < 0.06 then
                p.scale = p.targetScale * (age / 0.06) * 1.2
            elseif age < 0.12 then
                p.scale = p.targetScale * (1.2 - (age - 0.06) / 0.06 * 0.2)
            else
                p.scale = p.targetScale * (1 - progress * 0.1)
            end
            
            -- Bounce effect (more violent)
            p.bounce = math.abs(math.sin(age * 12)) * math.max(0, 1 - progress * 1.5) * 10
            
            -- Shake for criticals/kills (more intense)
            if p.isCrit or p.isKill then
                p.shake = math.sin(age * 30) * math.max(0, 1 - progress) * 5
            end
            
            -- Movement
            p.pos = p.pos + p.vel * ft
            p.vel.z = p.vel.z - 140 * ft
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
                p.scale = p.targetScale * (1 + math.sin(age * 7) * 0.1)
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
            p.vel.z = p.vel.z - 450 * ft
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
            local x = screen.x + math.sin(now * 35) * p.shake + p.rotation * 0.15
            local y = screen.y - p.bounce
            local scale = p.scale
            local alpha = p.alpha
            local color = Color(p.color.r, p.color.g, p.color.b, alpha)
            
            -- GOTHIC SHADOW LAYERS (deeper, bloodier)
            for i = 6, 1, -1 do
                local offset = i * 3 * scale
                draw.SimpleText(
                    p.damage,
                    p.isCrit and "AA_Gothic_Critical" or "AA_Gothic_Damage_Blur",
                    x + offset,
                    y + offset,
                    Color(15, 0, 0, alpha * 0.6),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- OUTER BLOOD GLOW for crits/kills
            if p.isCrit or p.isKill then
                for i = 1, 5 do
                    local glowAlpha = alpha * (0.3 - i * 0.05)
                    draw.SimpleText(
                        p.damage,
                        p.isKill and "AA_Gothic_Kill" or "AA_Gothic_Critical",
                        x,
                        y,
                        Color(255, 30, 30, glowAlpha),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            -- MAIN DAMAGE NUMBER
            local mainFont = p.isKill and "AA_Gothic_Kill" or 
                            (p.isCrit and "AA_Gothic_Critical" or "AA_Gothic_Damage")
            
            draw.SimpleText(
                p.damage,
                mainFont,
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            
            -- BONE-WHITE HIGHLIGHT (subtle)
            draw.SimpleText(
                p.damage,
                mainFont,
                x - 1,
                y - 1,
                Color(255, 255, 255, alpha * 0.3),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            
            -- GORE SUFFIX
            if p.suffix and p.suffix ~= "" then
                draw.SimpleText(
                    p.suffix,
                    "AA_Gothic_Small",
                    x + (p.isCrit and 55 or 40) * scale,
                    y + 10 * scale,
                    Color(200, 200, 200, alpha * 0.8),
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- EXPRESSION TEXT (HIT, CRITICAL, KILL, etc)
            if p.expression and p.expression ~= "" then
                local exprY = y - 55 * scale
                local exprColor = p.isKill and Color(255, 50, 0, alpha) or 
                                  (p.isCrit and Color(255, 80, 80, alpha) or Color(220, 220, 220, alpha))
                
                -- Shadow
                draw.SimpleText(
                    p.expression,
                    "AA_Gothic_Text",
                    x + 3,
                    exprY + 3,
                    Color(0, 0, 0, alpha * 0.8),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                
                -- Main expression with glow
                for i = 1, 3 do
                    draw.SimpleText(
                        p.expression,
                        "AA_Gothic_Text",
                        x,
                        exprY,
                        Color(exprColor.r, exprColor.g, exprColor.b, alpha * (0.4 - i * 0.1)),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
                
                draw.SimpleText(
                    p.expression,
                    "AA_Gothic_Text",
                    x,
                    exprY,
                    exprColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- COMBO COUNTER with skull style
            if p.combo > 1 then
                local comboText = "x" .. p.combo
                local comboColor = p.combo >= 20 and DP.Colors.GodCombo or
                                  (p.combo >= 10 and DP.Colors.UltraCombo or DP.Colors.Combo)
                comboColor = Color(comboColor.r, comboColor.g, comboColor.b, alpha)
                
                -- Shadow
                draw.SimpleText(
                    comboText,
                    "AA_Gothic_Text",
                    x + 2,
                    y + 38 * scale + 2,
                    Color(0, 0, 0, alpha * 0.7),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                
                -- Glow
                for i = 1, 2 do
                    draw.SimpleText(
                        comboText,
                        "AA_Gothic_Text",
                        x,
                        y + 38 * scale,
                        Color(comboColor.r, comboColor.g, comboColor.b, alpha * 0.4),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
                
                draw.SimpleText(
                    comboText,
                    "AA_Gothic_Text",
                    x,
                    y + 38 * scale,
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
            
            -- Shadow layers (darker)
            for i = 4, 1, -1 do
                draw.SimpleText(
                    p.text,
                    "AA_Gothic_Combo",
                    x + i * 4 * scale,
                    y + i * 4 * scale,
                    Color(0, 0, 0, alpha * 0.6),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- Intense glow for high combos
            if p.combo >= 10 then
                for i = 1, 4 do
                    draw.SimpleText(
                        p.text,
                        "AA_Gothic_Combo",
                        x,
                        y,
                        Color(color.r, color.g, color.b, alpha * 0.35),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            -- Main text
            draw.SimpleText(
                p.text,
                "AA_Gothic_Combo",
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            
            -- White highlight
            draw.SimpleText(
                p.text,
                "AA_Gothic_Combo",
                x - 1,
                y - 1,
                Color(255, 255, 255, alpha * 0.4),
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

print("[Arcade Anomaly]  GOTHIC ARCADE Damage System loaded!")
