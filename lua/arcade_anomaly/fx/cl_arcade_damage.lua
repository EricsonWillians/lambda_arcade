--[[
    Arcade Anomaly: Capcom/JRPG Style Gothic Damage Numbers
    
    Japanese arcade style hit points with goth/bloody aesthetic.
    Features dynamic scaling, bouncing animations, blood splatters, and combo multipliers.
--]]

AA.DamagePopup = AA.DamagePopup or {}
local DP = AA.DamagePopup

-- Active popups
DP.Active = {}
DP.ComboCount = 0
DP.ComboTimer = 0
DP.LastHitTime = 0
DP.ComboMultiplier = 1

-- Gothic color palette
DP.Colors = {
    Normal = Color(220, 220, 220),      -- White-ish gray
    Critical = Color(200, 50, 50),       -- Blood red
    Kill = Color(255, 60, 60),           -- Bright blood red
    Combo = Color(180, 80, 200),         -- Purple
    MegaCombo = Color(255, 200, 50),     -- Gold
    Shadow = Color(20, 5, 5),            -- Dark blood shadow
    Blood = Color(139, 0, 0),            -- Dark red
}

-- Japanese text for arcade feel
DP.JPText = {
    Damage = "",
    Kill = "",
    Critical = "",
    Combo = "",
    Mega = ""
}

-- Initialize fonts
hook.Add("Initialize", "AA_DamagePopup_InitFonts", function()
    -- Gothic damage number fonts
    surface.CreateFont("AA_Damage_Gothic", {
        font = "Consolas",  -- Monospace for JRPG feel
        size = 48,
        weight = 900,
        antialias = true,
        outline = false,
        shadow = false
    })
    
    surface.CreateFont("AA_Damage_Gothic_Shadow", {
        font = "Consolas",
        size = 48,
        weight = 900,
        antialias = true,
        outline = false,
        blursize = 8
    })
    
    surface.CreateFont("AA_Damage_Critical", {
        font = "Trebuchet MS",
        size = 64,
        weight = 1000,
        antialias = true,
        italic = true
    })
    
    surface.CreateFont("AA_Damage_Combo", {
        font = "Arial Black",
        size = 36,
        weight = 900,
        antialias = true,
        outline = true
    })
    
    surface.CreateFont("AA_Damage_Kill", {
        font = "Impact",
        size = 72,
        weight = 900,
        antialias = true,
        outline = false
    })
end)

-- Create a damage popup
function DP.Create(pos, damage, isKill, isCrit, comboCount)
    local now = CurTime()
    
    -- Update combo system
    if now - DP.LastHitTime < 2.0 then
        DP.ComboCount = DP.ComboCount + 1
        DP.ComboMultiplier = math.min(1 + (DP.ComboCount * 0.1), 3.0)
    else
        DP.ComboCount = 1
        DP.ComboMultiplier = 1
    end
    DP.LastHitTime = now
    
    -- Calculate popup properties
    local popup = {
        pos = pos + VectorRand() * 10,  -- Slight random offset
        basePos = pos,
        damage = damage,
        isKill = isKill,
        isCrit = isCrit,
        combo = DP.ComboCount,
        multiplier = DP.ComboMultiplier,
        
        -- Animation properties
        startTime = now,
        lifeTime = isKill and 2.0 or (isCrit and 1.5 or 1.0),
        scale = 0,
        targetScale = DP:GetScale(damage, isKill, isCrit),
        
        -- Physics
        velocity = Vector(
            math.random(-30, 30),
            math.random(-30, 30),
            math.random(60, 120)
        ),
        rotation = math.random(-15, 15),
        rotVelocity = math.random(-30, 30),
        
        -- Visual state
        alpha = 255,
        shake = 0,
        bounce = 0,
        bloodSplatter = isKill or (damage > 50),
        
        -- Color
        color = DP:GetColor(damage, isKill, isCrit, DP.ComboCount),
        glowIntensity = isCrit and 1 or 0.5,
    }
    
    table.insert(DP.Active, popup)
    
    -- Create blood splatter effect for big hits
    if popup.bloodSplatter then
        DP:CreateBloodSplatter(pos, damage)
    end
    
    -- Create combo popup for milestones
    if DP.ComboCount > 0 and DP.ComboCount % 5 == 0 then
        DP:CreateComboPopup(pos, DP.ComboCount)
    end
end

-- Get scale based on damage and hit type
function DP:GetScale(damage, isKill, isCrit)
    local base = 0.8
    
    if isKill then
        base = 1.5
    elseif isCrit then
        base = 1.3
    elseif damage > 100 then
        base = 1.2
    elseif damage > 50 then
        base = 1.0
    end
    
    -- Cap scale
    return math.min(base, 2.0)
end

-- Get color based on hit type
function DP:GetColor(damage, isKill, isCrit, combo)
    if isKill then
        return DP.Colors.Kill
    elseif isCrit then
        return DP.Colors.Critical
    elseif combo >= 10 then
        return DP.Colors.MegaCombo
    elseif combo >= 5 then
        return DP.Colors.Combo
    elseif damage > 50 then
        return Color(255, 150, 150)
    else
        return DP.Colors.Normal
    end
end

-- Create blood splatter particles
function DP:CreateBloodSplatter(pos, damage)
    local intensity = math.min(damage / 50, 3)
    
    -- Create clientside blood particles
    for i = 1, math.floor(intensity * 5) do
        local dir = VectorRand()
        dir.z = math.abs(dir.z) + 0.3
        dir:Normalize()
        
        local speed = math.random(100, 300)
        local particle = {
            pos = pos,
            vel = dir * speed,
            life = math.random(0.3, 0.8),
            start = CurTime(),
            size = math.random(3, 8),
            color = Color(
                math.random(150, 200),
                math.random(10, 30),
                math.random(10, 30),
                255
            )
        }
        
        if not self.BloodParticles then self.BloodParticles = {} end
        table.insert(self.BloodParticles, particle)
    end
end

-- Create combo milestone popup
function DP:CreateComboPopup(pos, combo)
    local popup = {
        pos = pos + Vector(0, 0, 50),
        text = combo .. " " .. self.JPText.Combo,
        isCombo = true,
        startTime = CurTime(),
        lifeTime = 1.5,
        scale = 0,
        targetScale = 1.2,
        velocity = Vector(0, 0, 80),
        alpha = 255,
        color = combo >= 10 and self.Colors.MegaCombo or self.Colors.Combo,
    }
    
    if not self.ComboPopups then self.ComboPopups = {} end
    table.insert(self.ComboPopups, popup)
end

-- Think hook for updating popups
hook.Add("Think", "AA_DamagePopup_Think", function()
    local ft = FrameTime()
    local now = CurTime()
    
    -- Reset combo if expired
    if now - DP.LastHitTime > 2.5 then
        if DP.ComboCount > 0 then
            DP.ComboCount = 0
            DP.ComboMultiplier = 1
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
            -- Scale animation (pop in then settle)
            if age < 0.1 then
                p.scale = p.targetScale * (age / 0.1)
            elseif age < 0.2 then
                p.scale = p.targetScale * (1 + (0.2 - age) * 2)
            else
                p.scale = p.targetScale * (1 - progress * 0.2)
            end
            
            -- Bounce animation
            p.bounce = math.abs(math.sin(age * 8)) * math.max(0, 1 - progress * 2) * 10
            
            -- Shake for criticals
            if p.isCrit then
                p.shake = math.sin(age * 30) * math.max(0, 1 - progress * 2) * 5
            end
            
            -- Movement
            p.pos = p.pos + p.velocity * ft
            p.velocity.z = p.velocity.z - 100 * ft  -- Gravity
            p.rotation = p.rotation + p.rotVelocity * ft
            
            -- Fade out
            if progress > 0.7 then
                p.alpha = 255 * (1 - (progress - 0.7) / 0.3)
            end
        end
    end
    
    -- Update combo popups
    if DP.ComboPopups then
        for i = #DP.ComboPopups, 1, -1 do
            local p = DP.ComboPopups[i]
            local age = now - p.startTime
            local progress = age / p.lifeTime
            
            if progress >= 1 then
                table.remove(DP.ComboPopups, i)
            else
                -- Pop in
                if age < 0.15 then
                    p.scale = p.targetScale * math.sin(age / 0.15 * math.pi * 0.5)
                else
                    p.scale = p.targetScale * (1 + math.sin(age * 5) * 0.1)
                end
                
                p.pos = p.pos + p.velocity * ft
                p.alpha = 255 * (1 - progress)
            end
        end
    end
    
    -- Update blood particles
    if DP.BloodParticles then
        for i = #DP.BloodParticles, 1, -1 do
            local p = DP.BloodParticles[i]
            local age = now - p.start
            
            if age > p.life then
                table.remove(DP.BloodParticles, i)
            else
                p.pos = p.pos + p.vel * ft
                p.vel.z = p.vel.z - 500 * ft  -- Heavy gravity
                
                -- Fade
                local progress = age / p.life
                p.color.a = 255 * (1 - progress)
            end
        end
    end
end)

-- Draw hook
hook.Add("PostDrawTranslucentRenderables", "AA_DamagePopup_Draw3D", function()
    cam.Start3D2D(EyePos(), EyeAngles(), 1)
        cam.End3D2D()
    cam.End3D()
end)

hook.Add("HUDPaint", "AA_DamagePopup_Draw", function()
    local now = CurTime()
    
    -- Draw damage popups
    for _, p in ipairs(DP.Active) do
        local screen = p.pos:ToScreen()
        if screen.visible then
            local x = screen.x + math.sin(now * 20) * p.shake
            local y = screen.y + math.cos(now * 15) * p.shake - p.bounce
            local scale = p.scale
            local alpha = p.alpha
            local color = Color(p.color.r, p.color.g, p.color.b, alpha)
            
            -- Draw multiple shadow layers for depth (gothic look)
            for i = 4, 1, -1 do
                local offset = i * 2 * scale
                draw.SimpleText(
                    p.damage,
                    p.isCrit and "AA_Damage_Critical" or "AA_Damage_Gothic_Shadow",
                    x + offset,
                    y + offset,
                    Color(20, 0, 0, alpha * 0.6),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- Outer glow for crits
            if p.isCrit then
                for i = 1, 3 do
                    local glowAlpha = alpha * (0.3 - i * 0.08)
                    draw.SimpleText(
                        p.damage,
                        "AA_Damage_Critical",
                        x,
                        y,
                        Color(255, 100, 100, glowAlpha),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            -- Main number
            local font = p.isKill and "AA_Damage_Kill" or 
                         (p.isCrit and "AA_Damage_Critical" or "AA_Damage_Gothic")
            
            draw.SimpleText(
                p.damage,
                font,
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            
            -- Japanese suffix
            local suffix = p.isKill and DP.JPText.Kill or DP.JPText.Damage
            local suffixColor = Color(255, 255, 255, alpha * 0.9)
            
            draw.SimpleText(
                suffix,
                "AA_Damage_Combo",
                x + (p.isCrit and 40 or 30) * scale,
                y + 5 * scale,
                suffixColor,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
            
            -- Combo multiplier indicator
            if p.combo > 1 then
                local comboText = "x" .. p.combo
                local comboColor = p.combo >= 10 and DP.Colors.MegaCombo or DP.Colors.Combo
                comboColor = Color(comboColor.r, comboColor.g, comboColor.b, alpha)
                
                draw.SimpleText(
                    comboText,
                    "AA_Damage_Combo",
                    x,
                    y - 40 * scale,
                    comboColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
    
    -- Draw combo popups
    if DP.ComboPopups then
        for _, p in ipairs(DP.ComboPopups) do
            local screen = p.pos:ToScreen()
            if screen.visible then
            
            local x, y = screen.x, screen.y
            local scale = p.scale
            local alpha = p.alpha
            local color = Color(p.color.r, p.color.g, p.color.b, alpha)
            
            -- Shadow
            for i = 3, 1, -1 do
                draw.SimpleText(
                    p.text,
                    "AA_Damage_Kill",
                    x + i * 3 * scale,
                    y + i * 3 * scale,
                    Color(0, 0, 0, alpha * 0.5),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            
            -- Main combo text
            draw.SimpleText(
                p.text,
                "AA_Damage_Kill",
                x,
                y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
            end
        end
    end
    
    -- Draw blood particles
    if DP.BloodParticles then
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
    end
end)

-- Network receiver
net.Receive("AA_DamagePopup", function()
    local pos = net.ReadVector()
    local damage = net.ReadUInt(16)
    local flags = net.ReadUInt(8)
    
    local isKill = bit.band(flags, 1) ~= 0
    local isCrit = bit.band(flags, 2) ~= 0
    
    DP.Create(pos, damage, isKill, isCrit, DP.ComboCount)
end)

-- Alternative: Hook into existing damage number network
hook.Add("ArcadeSpawner_DamageNumber", "AA_ArcadeDamage_Override", function(pos, damage, isKill)
    -- Override the old system with arcade style
    local isCrit = damage > 50
    DP.Create(pos, damage, isKill, isCrit, DP.ComboCount)
    return true  -- Block old system
end)

print("[Arcade Anomaly]  Damage popup system loaded!")
