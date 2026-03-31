--[[
    Arcade Anomaly: ULTRA HIGH CONTRAST End Screen
    
    Dark gothic theme with excellent readability.
    No excessive bright red - clean, sharp, professional.
--]]

AA.EndScreen = AA.EndScreen or {}
AA.EndScreen.Data = nil
AA.EndScreen.Visible = false
AA.EndScreen.AnimTime = 0
AA.EndScreen.StatReveals = {}

-- Color palette for HIGH CONTRAST
AA.EndScreen.Colors = {
    bgDark      = Color(8, 8, 12),          -- Almost black background
    bgPanel     = Color(20, 20, 28),        -- Dark panel
    bgPanelAlt  = Color(25, 25, 35),        -- Slightly lighter panel
    
    textMain    = Color(255, 255, 255),     -- Pure white
    textDim     = Color(180, 180, 190),     -- Dimmed text
    textDark    = Color(120, 120, 130),     -- Dark text
    
    accentGold  = Color(255, 200, 80),      -- Gold for high scores
    accentRed   = Color(220, 60, 60),       -- Muted red (not blinding)
    accentBlue  = Color(80, 160, 255),      -- Blue accent
    accentGreen = Color(80, 200, 120),      -- Green accent
    
    border      = Color(60, 60, 70),        -- Subtle border
    borderLight = Color(100, 100, 110),     -- Lighter border
    
    shadow      = Color(0, 0, 0, 220),      -- Strong shadow
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
    
    -- SOLID dark background (no transparency issues)
    surface.SetDrawColor(C.bgDark)
    surface.DrawRect(0, 0, w, h)
    
    -- Subtle radial gradient effect (dark vignette)
    for i = 1, 5 do
        local alpha = 30 - i * 5
        surface.SetDrawColor(0, 0, 0, alpha)
        surface.DrawRect(0, 0, w, h * 0.1 * i)
        surface.DrawRect(0, h * (1 - 0.1 * i), w, h * 0.1 * i)
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
        draw.SimpleText(titleText, "AA_End_Title", cx + 3, titleY + 3, Color(0, 0, 0, 200 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Glow
        draw.SimpleText(titleText, "AA_End_Title_Glow", cx, titleY, Color(255, 200, 80, 100 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Main text - GOLD
        draw.SimpleText(titleText, "AA_End_Title", cx, titleY, Color(C.accentGold.r, C.accentGold.g, C.accentGold.b, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Highlight
        draw.SimpleText(titleText, "AA_End_Title", cx - 1, titleY - 1, Color(255, 255, 200, 150 * titleAlpha), TEXT_ALIGN_CENTER)
    else
        -- DEFEAT - Run Complete
        local titleText = "RUN COMPLETE"
        
        -- Shadow
        draw.SimpleText(titleText, "AA_End_Title", cx + 3, titleY + 3, Color(0, 0, 0, 200 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Main text - WHITE (not blinding red)
        draw.SimpleText(titleText, "AA_End_Title", cx, titleY, Color(C.textMain.r, C.textMain.g, C.textMain.b, 255 * titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Subtle red underline
        if titleAlpha > 0.5 then
            surface.SetDrawColor(C.accentRed.r, C.accentRed.g, C.accentRed.b, 200)
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
        
        -- Score shadow
        draw.SimpleText(scoreText, "AA_End_Score", cx + 2, scoreY + 52, 
            Color(0, 0, 0, 200 * scoreAlpha), TEXT_ALIGN_CENTER)
        
        -- Score main - Gold if beaten, White if not
        local scoreColor = data.beaten and C.accentGold or C.textMain
        draw.SimpleText(scoreText, "AA_End_Score", cx, scoreY + 50, 
            Color(scoreColor.r, scoreColor.g, scoreColor.b, 255 * scoreAlpha), TEXT_ALIGN_CENTER)
        
        -- Score underline
        surface.SetDrawColor(C.borderLight.r, C.borderLight.g, C.borderLight.b, 150 * scoreAlpha)
        surface.DrawRect(cx - 100, scoreY + 95, 200, 2)
    end
    
    -- STATS GRID - Clean dark panels
    local statsY = scoreY + 140
    local statsReveal = math.max(0, (t - 0.8) * 1.5)
    
    local stats = {
        { label = "TIME", value = AA.Util and AA.Util.FormatTime(data.runTime) or string.format("%02d:%02d", math.floor(data.runTime/60), data.runTime%60), color = C.textMain },
        { label = "KILLS", value = tostring(data.kills), color = C.accentRed },
        { label = "ELITE KILLS", value = tostring(data.eliteKills), color = C.accentGold },
        { label = "MAX COMBO", value = "x" .. tostring(data.highestCombo), color = C.accentBlue },
    }
    
    for i, stat in ipairs(stats) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x = cx - 220 + col * 440
        local y = statsY + row * 90
        
        local statReveal = math.min(math.max(0, (statsReveal - (i - 1) * 0.1) * 2), 1)
        local statAlpha = statReveal
        
        if statReveal > 0 then
            -- Panel background
            surface.SetDrawColor(C.bgPanel.r, C.bgPanel.g, C.bgPanel.b, 240 * statAlpha)
            surface.DrawRect(x - 100, y, 200, 80)
            
            -- Panel border
            surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 200 * statAlpha)
            surface.DrawOutlinedRect(x - 100, y, 200, 80, 1)
            
            -- Label
            draw.SimpleText(stat.label, "AA_End_Label", x, y + 12, 
                Color(C.textDark.r, C.textDark.g, C.textDark.b, 255 * statAlpha), TEXT_ALIGN_CENTER)
            
            -- Value shadow
            draw.SimpleText(stat.value, "AA_End_Value", x + 2, y + 47, 
                Color(0, 0, 0, 150 * statAlpha), TEXT_ALIGN_CENTER)
            
            -- Value with custom color
            draw.SimpleText(stat.value, "AA_End_Value", x, y + 45, 
                Color(stat.color.r, stat.color.g, stat.color.b, 255 * statAlpha), TEXT_ALIGN_CENTER)
        end
    end
    
    -- PERSONAL BEST SECTION
    local bestY = statsY + 200
    local bestReveal = math.max(0, (t - 1.5) * 2)
    
    if bestReveal > 0 then
        local bestAlpha = math.min(bestReveal, 1)
        
        -- Divider line
        surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 100 * bestAlpha)
        surface.DrawRect(cx - 150, bestY - 20, 300, 1)
        
        local bestText = "PERSONAL BEST"
        local bestScore = AA.Util and AA.Util.FormatScore(data.highScore) or string.format("%09d", data.highScore)
        
        -- Label
        draw.SimpleText(bestText, "AA_End_Label", cx, bestY, 
            Color(C.textDim.r, C.textDim.g, C.textDim.b, 255 * bestAlpha), TEXT_ALIGN_CENTER)
        
        -- Best score
        draw.SimpleText(bestScore, "AA_End_Value", cx, bestY + 25, 
            Color(C.accentGold.r, C.accentGold.g, C.accentGold.b, 255 * bestAlpha), TEXT_ALIGN_CENTER)
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
    
    -- Button background
    if hovered then
        surface.SetDrawColor(80, 80, 90, 240 * alpha)
    else
        surface.SetDrawColor(C.bgPanelAlt.r, C.bgPanelAlt.g, C.bgPanelAlt.b, 240 * alpha)
    end
    surface.DrawRect(x - btnW/2, y, btnW, btnH)
    
    -- Border
    local borderColor = hovered and C.accentBlue or C.borderLight
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 255 * alpha)
    surface.DrawOutlinedRect(x - btnW/2, y, btnW, btnH, hovered and 3 or 2)
    
    -- Inner glow on hover
    if hovered then
        surface.SetDrawColor(100, 160, 255, 50 * alpha)
        surface.DrawRect(x - btnW/2 + 3, y + 3, btnW - 6, btnH - 6)
    end
    
    -- Button text
    local textColor = hovered and C.textMain or C.textDim
    draw.SimpleText("RESTART RUN", "AA_End_Button", x, y + btnH/2, 
        Color(textColor.r, textColor.g, textColor.b, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
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
