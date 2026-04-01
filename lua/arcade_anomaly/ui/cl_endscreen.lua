--[[
    Arcade Anomaly: ULTRA HIGH CONTRAST End Screen
    
    Designed to be readable OVER GMod's default red death screen.
    Uses CYAN/TEAL accents (opposite of red on color wheel) for contrast.
    Solid black backgrounds completely hide the red tint.
--]]

AA.EndScreen = AA.EndScreen or {}
AA.EndScreen.Data = nil
AA.EndScreen.Visible = false
AA.EndScreen.AnimTime = 0
AA.EndScreen.StatReveals = {}

-- Color palette - OPTIMIZED FOR RED BACKGROUND
-- GMod's death screen is bright red, so we need colors that contrast with red
AA.EndScreen.Colors = {
    -- SOLID dark backgrounds - completely hide the red
    bgDark      = Color(0, 0, 0),           -- Pure black
    bgPanel     = Color(10, 10, 15),        -- Very dark, slight blue tint
    bgPanelAlt  = Color(15, 15, 22),        -- Slightly lighter
    
    -- Text: CYAN/WHITE contrasts with red background
    textMain    = Color(220, 255, 255),     -- Cyan-tinted white (counters red)
    textDim     = Color(160, 200, 210),     -- Dim cyan-gray
    textDark    = Color(100, 130, 140),     -- Dark cyan-gray
    
    -- Accents: CYAN/TEAL are opposite of red on color wheel
    accentCyan  = Color(0, 255, 255),       -- Bright cyan (high contrast on red)
    accentTeal  = Color(0, 200, 180),       -- Teal (readable on red)
    accentGold  = Color(255, 220, 100),     -- Yellow-gold (readable on red)
    accentRed   = Color(255, 100, 100),     -- Light red/pink (visible on dark red)
    accentBlue  = Color(100, 180, 255),     -- Sky blue
    accentGreen = Color(100, 255, 180),     -- Mint green
    
    border      = Color(0, 150, 150),       -- Cyan border (visible on red)
    borderLight = Color(0, 200, 200),       -- Light cyan border
    
    shadow      = Color(0, 0, 0, 255),      -- Solid black shadow
}

-- Create high contrast fonts
hook.Add("Initialize", "AA_EndScreen_InitFonts", function()
    surface.CreateFont("AA_End_Title", {
        font = "Impact",
        size = 72,
        weight = 900,
        antialias = true,
    })
    
    surface.CreateFont("AA_End_Title_Glow", {
        font = "Impact",
        size = 72,
        weight = 900,
        antialias = true,
        blursize = 12,
    })
    
    surface.CreateFont("AA_End_Score", {
        font = "Impact",
        size = 56,
        weight = 900,
        antialias = true,
    })
    
    surface.CreateFont("AA_End_Label", {
        font = "Arial",
        size = 18,
        weight = 600,
        antialias = true,
    })
    
    surface.CreateFont("AA_End_Value", {
        font = "Impact",
        size = 36,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("AA_End_Button", {
        font = "Impact",
        size = 28,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("AA_End_Small", {
        font = "Arial",
        size = 16,
        weight = 500,
        antialias = true,
    })
end)

-- Network handler
hook.Add("AA_ShowEndScreen", "AA_EndScreen_Show", function(data)
    AA.EndScreen.Data = data
    AA.EndScreen.Visible = true
    AA.EndScreen.AnimTime = 0
    AA.EndScreen.StatReveals = {}
    
    -- Play sound based on result
    if data.beaten then
        surface.PlaySound("ambient/levels/labs/c electric_explosion1.wav")
    else
        surface.PlaySound("buttons/button10.wav")
    end
    
    gui.EnableScreenClicker(true)
end)

hook.Add("HUDPaint", "AA_EndScreen_Paint", function()
    if not AA.EndScreen.Visible then return end
    AA.EndScreen.AnimTime = AA.EndScreen.AnimTime + FrameTime()
    AA.EndScreen:Draw()
end)

function AA.EndScreen:Draw()
    local w, h = ScrW(), ScrH()
    local data = self.Data
    if not data then return end
    
    local t = self.AnimTime
    local C = self.Colors
    
    -- COMPLETELY SOLID black background to hide GMod's red death screen
    -- Draw multiple layers to ensure no red bleeds through
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(C.bgDark)
    surface.DrawRect(0, 0, w, h)
    
    -- Dark vignette to blend edges
    for i = 1, 5 do
        local alpha = 40 - i * 6
        surface.SetDrawColor(0, 0, 5, alpha)
        surface.DrawRect(0, 0, w, h * 0.08 * i)
        surface.DrawRect(0, h * (1 - 0.08 * i), w, h * 0.08 * i)
    end
    
    local cx = w / 2
    local startY = h * 0.08
    
    -- TITLE SECTION
    local titleY = startY
    local titleAlpha = math.min(t * 3, 1)
    
    if data.beaten then
        -- VICTORY - High Score
        local titleText = "NEW HIGH SCORE!"
        
        -- Shadow
        draw.SimpleText(titleText, "AA_End_Title", cx + 3, titleY + 3, Color(0, 0, 0, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        draw.SimpleText(titleText, "AA_End_Title", cx + 4, titleY + 4, Color(0, 0, 0, 200 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Glow - CYAN (contrasts with red background)
        draw.SimpleText(titleText, "AA_End_Title_Glow", cx, titleY, Color(0, 255, 255, 120 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Main text - CYAN-GOLD (readable on red)
        draw.SimpleText(titleText, "AA_End_Title", cx, titleY, Color(C.accentCyan.r, C.accentCyan.g, C.accentCyan.b, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Highlight
        draw.SimpleText(titleText, "AA_End_Title", cx - 1, titleY - 1, Color(200, 255, 255, 180 * titleAlpha), TEXT_ALIGN_CENTER)
    else
        -- DEFEAT - Run Complete
        local titleText = "RUN COMPLETE"
        
        -- Multiple shadows for depth over red background
        draw.SimpleText(titleText, "AA_End_Title", cx + 4, titleY + 4, Color(0, 0, 0, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        draw.SimpleText(titleText, "AA_End_Title", cx + 3, titleY + 3, Color(0, 0, 0, 200 * titleAlpha), TEXT_ALIGN_CENTER)
        draw.SimpleText(titleText, "AA_End_Title", cx + 2, titleY + 2, Color(0, 0, 0, 150 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Main text - CYAN-TINTED WHITE (contrasts with red background)
        draw.SimpleText(titleText, "AA_End_Title", cx, titleY, Color(C.textMain.r, C.textMain.g, C.textMain.b, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Cyan underline (contrasts with red)
        if titleAlpha > 0.5 then
            surface.SetDrawColor(C.accentCyan.r, C.accentCyan.g, C.accentCyan.b, 200)
            surface.DrawRect(cx - 150, titleY + 80, 300, 3)
        end
    end
    
    -- FINAL SCORE SECTION
    local scoreY = startY + 120
    local scoreReveal = math.max(0, (t - 0.3) * 2)
    
    if scoreReveal > 0 then
        local scoreAlpha = math.min(scoreReveal, 1)
        
        -- Label
        draw.SimpleText("FINAL SCORE", "AA_End_Label", cx, scoreY, 
            Color(C.textDim.r, C.textDim.g, C.textDim.b, 255 * scoreAlpha), TEXT_ALIGN_CENTER)
        
        -- Score number
        local finalScore = math.floor(data.finalScore * math.min(scoreReveal, 1))
        local scoreText = AA.Util and AA.Util.FormatScore(finalScore) or string.format("%09d", finalScore)
        
        -- Score shadows - multiple for depth on red background
        draw.SimpleText(scoreText, "AA_End_Score", cx + 4, scoreY + 54, 
            Color(0, 0, 0, 255 * scoreAlpha), TEXT_ALIGN_CENTER)
        draw.SimpleText(scoreText, "AA_End_Score", cx + 2, scoreY + 52, 
            Color(0, 0, 0, 200 * scoreAlpha), TEXT_ALIGN_CENTER)
        
        -- Score main - Cyan-Gold if beaten, Cyan-White if not (both contrast with red)
        local scoreColor = data.beaten and C.accentCyan or C.textMain
        draw.SimpleText(scoreText, "AA_End_Score", cx, scoreY + 50, 
            Color(scoreColor.r, scoreColor.g, scoreColor.b, 255 * scoreAlpha), TEXT_ALIGN_CENTER)
        
        -- Score underline - cyan for contrast
        surface.SetDrawColor(C.accentCyan.r, C.accentCyan.g, C.accentCyan.b, 180 * scoreAlpha)
        surface.DrawRect(cx - 100, scoreY + 95, 200, 3)
    end
    
    -- STATS GRID - Clean dark panels
    local statsY = scoreY + 140
    local statsReveal = math.max(0, (t - 0.8) * 1.5)
    
    local stats = {
        { label = "TIME", value = AA.Util and AA.Util.FormatTime(data.runTime) or string.format("%02d:%02d", math.floor(data.runTime/60), data.runTime%60), color = C.textMain },
        { label = "KILLS", value = tostring(data.kills), color = C.accentCyan },      -- Cyan contrasts with red bg
        { label = "ELITE KILLS", value = tostring(data.eliteKills), color = C.accentGold },
        { label = "MAX COMBO", value = "x" .. tostring(data.highestCombo), color = C.accentTeal },
    }
    
    for i, stat in ipairs(stats) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x = cx - 220 + col * 440
        local y = statsY + row * 90
        
        local statReveal = math.min(math.max(0, (statsReveal - (i - 1) * 0.1) * 2), 1)
        local statAlpha = statReveal
        
        if statReveal > 0 then
            -- Panel background - COMPLETELY OPAQUE to hide red death screen
            surface.SetDrawColor(C.bgPanel.r, C.bgPanel.g, C.bgPanel.b, 255)
            surface.DrawRect(x - 100, y, 200, 80)
            
            -- Inner panel for depth
            surface.SetDrawColor(0, 0, 0, 100)
            surface.DrawRect(x - 95, y + 5, 190, 70)
            
            -- Panel border - cyan for contrast on red
            surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 255)
            surface.DrawOutlinedRect(x - 100, y, 200, 80, 2)
            
            -- Label
            draw.SimpleText(stat.label, "AA_End_Label", x, y + 12, 
                Color(C.textDark.r, C.textDark.g, C.textDark.b, 255 * statAlpha), TEXT_ALIGN_CENTER)
            
            -- Value shadows - multiple for depth on red background
            draw.SimpleText(stat.value, "AA_End_Value", x + 3, y + 48, 
                Color(0, 0, 0, 255 * statAlpha), TEXT_ALIGN_CENTER)
            draw.SimpleText(stat.value, "AA_End_Value", x + 2, y + 47, 
                Color(0, 0, 0, 200 * statAlpha), TEXT_ALIGN_CENTER)
            
            -- Value with custom color (cyan/teal for contrast)
            draw.SimpleText(stat.value, "AA_End_Value", x, y + 45, 
                Color(stat.color.r, stat.color.g, stat.color.b, 255 * statAlpha), TEXT_ALIGN_CENTER)
        end
    end
    
    -- PERSONAL BEST SECTION
    local bestY = statsY + 200
    local bestReveal = math.max(0, (t - 1.5) * 2)
    
    if bestReveal > 0 then
        local bestAlpha = math.min(bestReveal, 1)
        
        -- Divider line - cyan
        surface.SetDrawColor(C.accentCyan.r, C.accentCyan.g, C.accentCyan.b, 150 * bestAlpha)
        surface.DrawRect(cx - 150, bestY - 20, 300, 2)
        
        local bestText = "PERSONAL BEST"
        local bestScore = AA.Util and AA.Util.FormatScore(data.highScore) or string.format("%09d", data.highScore)
        
        -- Label
        draw.SimpleText(bestText, "AA_End_Label", cx, bestY, 
            Color(C.textDim.r, C.textDim.g, C.textDim.b, 255 * bestAlpha), TEXT_ALIGN_CENTER)
        
        -- Best score - cyan-teal for contrast on red
        draw.SimpleText(bestScore, "AA_End_Value", cx, bestY + 25, 
            Color(C.accentTeal.r, C.accentTeal.g, C.accentTeal.b, 255 * bestAlpha), TEXT_ALIGN_CENTER)
    end
    
    -- RESTART BUTTON - Clean and visible
    local btnReveal = math.max(0, (t - 2) * 2)
    if btnReveal > 0 then
        self:DrawRestartButton(cx, h - 100, btnReveal)
    end
    
    -- Quick restart hint
    if t > 3 then
        local hintAlpha = math.abs(math.sin(t * 2)) * 100 + 100
        draw.SimpleText("Press [JUMP] or [ATTACK] to restart", "AA_End_Small", cx, h - 35, 
            Color(C.textDark.r, C.textDark.g, C.textDark.b, hintAlpha), TEXT_ALIGN_CENTER)
    end
end

function AA.EndScreen:DrawRestartButton(x, y, reveal)
    local btnW, btnH = 280, 70
    local mx, my = input.GetCursorPos()
    local C = self.Colors
    
    local hovered = mx >= x - btnW/2 and mx <= x + btnW/2 and my >= y and my <= y + btnH
    local alpha = math.min(reveal, 1)
    
    -- Button background - OPAQUE
    if hovered then
        surface.SetDrawColor(20, 40, 45, 255)  -- Cyan-tinted dark
    else
        surface.SetDrawColor(C.bgPanelAlt.r, C.bgPanelAlt.g, C.bgPanelAlt.b, 255)
    end
    surface.DrawRect(x - btnW/2, y, btnW, btnH)
    
    -- Border - CYAN for contrast on red background
    local borderColor = hovered and C.accentCyan or C.borderLight
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 255)
    surface.DrawOutlinedRect(x - btnW/2, y, btnW, btnH, hovered and 4 or 2)
    
    -- Inner glow on hover - CYAN
    if hovered then
        surface.SetDrawColor(0, 255, 255, 60)
        surface.DrawRect(x - btnW/2 + 4, y + 4, btnW - 8, btnH - 8)
    end
    
    -- Button text - CYAN-TINTED WHITE
    local textColor = hovered and C.accentCyan or C.textMain
    draw.SimpleText("RESTART RUN", "AA_End_Button", x, y + btnH/2, 
        Color(textColor.r, textColor.g, textColor.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Click handling
    if hovered and input.IsMouseDown(MOUSE_LEFT) and self.AnimTime > 2.5 then
        self:OnRestartClicked()
    end
end

function AA.EndScreen:OnRestartClicked()
    self.Visible = false
    gui.EnableScreenClicker(false)
    
    surface.PlaySound("buttons/button14.wav")
    
    -- Show feedback
    AA.Toast:Info("Restarting run...", 2)
    
    -- Send restart request
    AA.Net.RequestRestartRun()
end

-- Hide on restart
hook.Add("AA_RunStateChanged", "AA_EndScreen_Hide", function(state)
    if state == AA.Types.RunState.PREPARING_MAP or 
       state == AA.Types.RunState.RESTARTING then
        AA.EndScreen.Visible = false
        AA.EndScreen.Data = nil
        gui.EnableScreenClicker(false)
    end
end)

-- Key handler for quick restart
hook.Add("PlayerBindPress", "AA_EndScreen_Binds", function(ply, bind, pressed)
    if not AA.EndScreen.Visible then return end
    if not pressed then return end
    
    if bind == "+jump" or bind == "+attack" then
        if AA.EndScreen.AnimTime > 2 then
            AA.EndScreen:OnRestartClicked()
            return true
        end
    end
end)
