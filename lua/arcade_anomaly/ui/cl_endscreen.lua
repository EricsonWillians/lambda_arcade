--[[
    Arcade Anomaly: Enhanced End Screen
    Victory/Defeat screen with arcade flair
--]]

AA.EndScreen = AA.EndScreen or {}
AA.EndScreen.Data = nil
AA.EndScreen.Visible = false
AA.EndScreen.AnimTime = 0
AA.EndScreen.StatReveals = {}

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
    
    -- Background fade in - LIGHTER for better contrast
    local bgAlpha = math.min(t * 255, 245)
    surface.SetDrawColor(15, 15, 22, bgAlpha)
    surface.DrawRect(0, 0, w, h)
    
    -- Animated grid - MORE VISIBLE
    surface.SetDrawColor(60, 60, 80, 120)
    local gridSize = 50
    local gridOffset = (t * 20) % gridSize
    for x = -gridSize, w, gridSize do
        surface.DrawLine(x + gridOffset, 0, x + gridOffset, h)
    end
    for y = -gridSize, h, gridSize do
        surface.DrawLine(0, y + gridOffset, w, y + gridOffset)
    end
    
    -- Vignette - STRONGER for text focus
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h * 0.25)
    surface.DrawRect(0, h * 0.75, w, h * 0.25)
    
    local cx = w / 2
    local startY = h * 0.12
    
    -- Title animation
    local titleY = startY
    local titleScale = math.min(t * 2, 1)
    local titleAlpha = math.min(t * 400, 255)
    
    if data.beaten then
        -- Victory effects
        local flash = math.abs(math.sin(t * 6)) * 50
        local titleText = "NEW HIGH SCORE!"
        
        -- Glow layers
        for i = 1, 3 do
            local glowSize = i * 8
            local glowAlpha = (100 - i * 25) + flash
            draw.SimpleText(titleText, "AA_Title_Glow", cx, titleY, Color(255, 200, 50, glowAlpha), TEXT_ALIGN_CENTER)
        end
        
        -- Main title
        local color = Color(255, 215, 0, titleAlpha)
        draw.SimpleText(titleText, "AA_Title", cx, titleY, color, TEXT_ALIGN_CENTER)
        
        -- Sparkles
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2 + t
            local dist = 200 + math.sin(t * 3 + i) * 30
            local sx = cx + math.cos(angle) * dist
            local sy = titleY + math.sin(angle) * 30
            local size = 4 + math.sin(t * 5 + i) * 2
            
            surface.SetDrawColor(255, 215, 0, 200)
            surface.DrawRect(sx - size/2, sy - size/2, size, size)
        end
    else
        -- Defeat - HIGH CONTRAST VERSION
        local titleText = "RUN COMPLETE"
        
        -- Multiple shadow layers for depth
        for i = 4, 1, -1 do
            local offset = i * 3
            draw.SimpleText(titleText, "AA_Title", cx + offset, titleY + offset, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER)
        end
        
        -- Outer glow pulse
        local glow = math.abs(math.sin(t * 4)) * 80 + 100
        draw.SimpleText(titleText, "AA_Title_Glow", cx, titleY, Color(255, 100, 100, glow), TEXT_ALIGN_CENTER)
        draw.SimpleText(titleText, "AA_Title_Glow", cx, titleY, Color(255, 80, 80, glow * 0.6), TEXT_ALIGN_CENTER)
        
        -- Main title - BRIGHTER RED
        draw.SimpleText(titleText, "AA_Title", cx, titleY, Color(255, 90, 90, titleAlpha), TEXT_ALIGN_CENTER)
        
        -- Inner highlight
        draw.SimpleText(titleText, "AA_Title", cx, titleY - 2, Color(255, 150, 150, titleAlpha * 0.7), TEXT_ALIGN_CENTER)
    end
    
    -- Final score section
    local scoreY = startY + 120
    local scoreReveal = math.max(0, (t - 0.5) * 2)
    
    if scoreReveal > 0 then
        draw.SimpleText("FINAL SCORE", "AA_Label", cx, scoreY, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        
        -- Score with counting animation
        local finalScore = math.floor(data.finalScore * math.min(scoreReveal, 1))
        local scoreText = AA.Util and AA.Util.FormatScore(finalScore) or string.format("%09d", finalScore)
        
        -- Score glow
        if data.beaten then
            local glow = math.abs(math.sin(t * 4)) * 30
            draw.SimpleText(scoreText, "AA_Huge_Glow", cx, scoreY + 50, Color(255, 180, 0, 100 + glow), TEXT_ALIGN_CENTER)
        end
        
        draw.SimpleText(scoreText, "AA_Huge", cx, scoreY + 50, color_white, TEXT_ALIGN_CENTER)
    end
    
    -- Stats grid - HIGH CONTRAST
    local statsY = scoreY + 150
    local statsReveal = math.max(0, (t - 1) * 1.5)
    
    local stats = {
        { label = "TIME", value = AA.Util and AA.Util.FormatTime(data.runTime) or string.format("%02d:%02d", math.floor(data.runTime/60), data.runTime%60) },
        { label = "KILLS", value = tostring(data.kills) },
        { label = "ELITE KILLS", value = tostring(data.eliteKills) },
        { label = "MAX COMBO", value = "x" .. tostring(data.highestCombo) },
    }
    
    for i, stat in ipairs(stats) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x = cx - 200 + col * 400
        local y = statsY + row * 80
        
        local statReveal = math.min(math.max(0, (statsReveal - (i - 1) * 0.1) * 2), 1)
        local statAlpha = math.floor(statReveal * 255)
        
        if statReveal > 0 then
            -- Box background - LIGHTER
            surface.SetDrawColor(35, 35, 45, statAlpha * 0.95)
            surface.DrawRect(x - 90, y - 10, 180, 70)
            
            -- Border - BRIGHTER
            surface.SetDrawColor(255, 100, 100, statAlpha * 0.6)
            surface.DrawOutlinedRect(x - 90, y - 10, 180, 70, 2)
            
            -- Inner shadow for text pop
            surface.SetDrawColor(0, 0, 0, statAlpha * 0.3)
            surface.DrawRect(x - 88, y - 8, 176, 25)
            
            -- Label - BRIGHTER
            draw.SimpleText(stat.label, "AA_Tiny", x, y, Color(200, 200, 200, statAlpha), TEXT_ALIGN_CENTER)
            
            -- Value with shadow for contrast
            draw.SimpleText(stat.value, "AA_Medium", x + 2, y + 27, Color(0, 0, 0, statAlpha * 0.8), TEXT_ALIGN_CENTER)
            draw.SimpleText(stat.value, "AA_Medium", x, y + 25, Color(255, 220, 220, statAlpha), TEXT_ALIGN_CENTER)
        end
    end
    
    -- High score comparison - HIGH CONTRAST
    local bestY = statsY + 180
    local bestReveal = math.max(0, (t - 2) * 1.5)
    
    if bestReveal > 0 then
        local bestAlpha = math.floor(math.min(bestReveal, 1) * 255)
        local bestText = "PERSONAL BEST: " .. (AA.Util and AA.Util.FormatScore(data.highScore) or string.format("%09d", data.highScore))
        
        -- Shadow
        draw.SimpleText(bestText, "AA_Small", cx + 2, bestY + 2, Color(0, 0, 0, bestAlpha * 0.8), TEXT_ALIGN_CENTER)
        -- Text - BRIGHTER
        draw.SimpleText(bestText, "AA_Small", cx, bestY, Color(220, 220, 220, bestAlpha), TEXT_ALIGN_CENTER)
    end
    
    -- Restart button
    local btnReveal = math.max(0, (t - 2.5) * 2)
    if btnReveal > 0 then
        self:DrawRestartButton(cx, h - 120, btnReveal)
    end
    
    -- Quick restart hint
    if t > 3 then
        local hintAlpha = math.abs(math.sin(t * 2)) * 150 + 50
        draw.SimpleText("Press JUMP or ATTACK to restart", "AA_Tiny", cx, h - 40, Color(100, 100, 100, hintAlpha), TEXT_ALIGN_CENTER)
    end
end

function AA.EndScreen:DrawRestartButton(x, y, reveal)
    local w, h = 240, 60
    local mx, my = input.GetCursorPos()
    
    local hovered = mx >= x - w/2 and mx <= x + w/2 and my >= y and my <= y + h
    
    local alpha = math.floor(reveal * 255)
    
    -- Glow effect on hover
    if hovered then
        local glow = math.abs(math.sin(self.AnimTime * 8)) * 40
        surface.SetDrawColor(220, 70, 70, (80 + glow) * reveal)
        surface.DrawRect(x - w/2 - 8, y - 8, w + 16, h + 16)
    end
    
    -- Button background
    local bgColor = hovered and Color(220, 70, 70, alpha) or Color(180, 50, 50, alpha)
    surface.SetDrawColor(bgColor)
    surface.DrawRect(x - w/2, y, w, h)
    
    -- Shine effect
    if hovered then
        surface.SetDrawColor(255, 100, 100, alpha * 0.5)
        surface.DrawRect(x - w/2, y + h * 0.3, w, h * 0.4)
    end
    
    -- Border
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawOutlinedRect(x - w/2, y, w, h, hovered and 3 or 2)
    
    -- Text
    local textColor = Color(255, 255, 255, alpha)
    if hovered then
        draw.SimpleText("RESTART", "AA_Medium_Glow", x, y + h/2, Color(255, 255, 255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    draw.SimpleText("RESTART", "AA_Medium", x, y + h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Click handling
    if hovered and input.IsMouseDown(MOUSE_LEFT) and self.AnimTime > 3 then
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
