--[[
    Lambda Arcade: Loading Screen System
    Shows progress for async operations like model discovery
--]]

AA.Loading = AA.Loading or {}
AA.Loading.Active = false
AA.Loading.Data = {
    title = "",
    message = "",
    progress = 0,
    subProgress = nil,
    stage = "",
    eta = nil,
    cancellable = false,
}
AA.Loading.History = {}
AA.Loading.AnimTime = 0

-- Colors
AA.Loading.Colors = {
    bg = Color(5, 5, 8, 255),
    panel = Color(15, 15, 20, 240),
    accent = Color(220, 60, 60),
    accentDim = Color(150, 40, 40),
    text = Color(255, 255, 255),
    textDim = Color(150, 150, 150),
    progressBg = Color(30, 30, 35, 255),
    progressFill = Color(220, 60, 60),
    progressGlow = Color(255, 100, 100, 100),
}

-- Show loading screen
function AA.Loading:Show(title, message, options)
    options = options or {}
    
    self.Active = true
    self.AnimTime = 0
    self.Data = {
        title = title or "LOADING",
        message = message or "",
        progress = options.progress or 0,
        subProgress = options.subProgress,
        stage = options.stage or "",
        eta = options.eta,
        cancellable = options.cancellable or false,
    }
    
    -- Disable mouse input unless cancellable
    if not self.Data.cancellable then
        gui.EnableScreenClicker(false)
    end
    
    -- Play sound
    surface.PlaySound("ui/buttonclickrelease.wav")
    
    hook.Run("AA_LoadingStarted", self.Data)
end

-- Update loading progress
function AA.Loading:Update(progress, message, stage)
    if not self.Active then return end
    
    self.Data.progress = math.Clamp(progress or self.Data.progress, 0, 100)
    if message then self.Data.message = message end
    if stage then self.Data.stage = stage end
    
    -- Calculate ETA if progress is moving
    if progress and progress > 0 and progress < 100 then
        -- Simple ETA based on progress rate
        local elapsed = self.AnimTime
        if elapsed > 0 then
            local rate = progress / elapsed
            local remaining = (100 - progress) / rate
            self.Data.eta = math.max(0, remaining)
        end
    end
    
    hook.Run("AA_LoadingUpdated", self.Data)
end

-- Update sub-progress (for multi-stage operations)
function AA.Loading:UpdateSubProgress(current, total, message)
    if not self.Active then return end
    
    self.Data.subProgress = {
        current = current,
        total = total,
        percent = (current / total) * 100
    }
    if message then self.Data.message = message end
end

-- Hide loading screen
function AA.Loading:Hide()
    if not self.Active then return end
    
    -- Store in history
    table.insert(self.History, {
        title = self.Data.title,
        completedAt = CurTime(),
    })
    
    self.Active = false
    gui.EnableScreenClicker(true)
    
    surface.PlaySound("ui/buttonrollover.wav")
    hook.Run("AA_LoadingComplete")
end

-- Check if loading is active
function AA.Loading:IsActive()
    return self.Active
end

-- Cancel operation (if cancellable)
function AA.Loading:Cancel()
    if not self.Active or not self.Data.cancellable then return end
    
    hook.Run("AA_LoadingCancelled", self.Data)
    self:Hide()
end

-- Main paint function
hook.Add("HUDPaint", "AA_Loading_Paint", function()
    if not AA.Loading.Active then return end
    
    AA.Loading.AnimTime = AA.Loading.AnimTime + FrameTime()
    AA.Loading:Draw()
end)

-- Block input during loading
hook.Add("PlayerBindPress", "AA_Loading_BlockInput", function(ply, bind, pressed)
    if AA.Loading.Active and not AA.Loading.Data.cancellable then
        -- Block most player inputs during loading
        local blocked = {
            ["+attack"] = true,
            ["+attack2"] = true,
            ["+jump"] = true,
            ["+duck"] = true,
            ["+forward"] = true,
            ["+back"] = true,
            ["+moveleft"] = true,
            ["+moveright"] = true,
            ["+use"] = true,
            ["+reload"] = true,
            ["+menu"] = true,
        }
        if blocked[bind] then
            return true
        end
    end
end)

-- Draw the loading screen
function AA.Loading:Draw()
    local w, h = ScrW(), ScrH()
    local t = self.AnimTime
    local data = self.Data
    local colors = self.Colors
    
    -- Fade in
    local fadeAlpha = math.min(t * 2, 1)
    
    -- Background with scanline effect
    surface.SetDrawColor(colors.bg.r, colors.bg.g, colors.bg.b, colors.bg.a * fadeAlpha)
    surface.DrawRect(0, 0, w, h)
    
    -- Animated grid background
    self:DrawGrid(w, h, t)
    
    -- Scanlines
    self:DrawScanlines(w, h, t)
    
    -- Main panel
    local panelW, panelH = 600, 320
    local panelX = (w - panelW) / 2
    local panelY = (h - panelH) / 2
    
    -- Panel slide-in animation
    local slideOffset = math.max(0, (1 - t * 3) * 50)
    panelY = panelY + slideOffset
    
    -- Panel background
    surface.SetDrawColor(colors.panel.r, colors.panel.g, colors.panel.b, colors.panel.a * fadeAlpha)
    surface.DrawRect(panelX, panelY, panelW, panelH)
    
    -- Panel border with glow
    local glow = math.abs(math.sin(t * 2)) * 30
    surface.SetDrawColor(colors.accent.r + glow, colors.accent.g, colors.accent.b, 200 * fadeAlpha)
    surface.DrawOutlinedRect(panelX, panelY, panelW, panelH, 2)
    
    -- Title
    local titleY = panelY + 40
    draw.SimpleText(data.title, "AA_Title", w / 2, titleY, colors.accent, TEXT_ALIGN_CENTER)
    
    -- Decorative line under title
    surface.SetDrawColor(colors.accent.r, colors.accent.g, colors.accent.b, 150)
    surface.DrawRect(panelX + 50, titleY + 40, panelW - 100, 2)
    
    -- Stage indicator
    local stageY = titleY + 70
    if data.stage and data.stage ~= "" then
        draw.SimpleText(data.stage:upper(), "AA_Label", w / 2, stageY, colors.textDim, TEXT_ALIGN_CENTER)
    end
    
    -- Main message
    local msgY = stageY + 35
    draw.SimpleText(data.message, "AA_Medium", w / 2, msgY, colors.text, TEXT_ALIGN_CENTER)
    
    -- Progress bar background
    local barY = msgY + 60
    local barW, barH = 500, 24
    local barX = (w - barW) / 2
    
    surface.SetDrawColor(colors.progressBg.r, colors.progressBg.g, colors.progressBg.b)
    surface.DrawRect(barX, barY, barW, barH)
    
    -- Progress bar fill with animation
    local targetProgress = data.progress / 100
    local fillW = barW * targetProgress
    
    -- Animated fill effect
    local pulse = math.abs(math.sin(t * 4)) * 10
    surface.SetDrawColor(colors.progressFill.r + pulse, colors.progressFill.g, colors.progressFill.b)
    surface.DrawRect(barX, barY, fillW, barH)
    
    -- Progress bar glow
    if fillW > 0 then
        surface.SetDrawColor(colors.progressGlow.r, colors.progressGlow.g, colors.progressGlow.b, colors.progressGlow.a)
        surface.DrawRect(barX + fillW - 20, barY - 2, 20, barH + 4)
    end
    
    -- Progress bar border
    surface.SetDrawColor(colors.accentDim.r, colors.accentDim.g, colors.accentDim.b)
    surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
    
    -- Percentage text
    local pctText = string.format("%d%%", math.floor(data.progress))
    draw.SimpleText(pctText, "AA_Mono", w / 2, barY + barH / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Sub-progress (for multi-stage operations)
    local subY = barY + 50
    if data.subProgress then
        local subW, subH = 400, 8
        local subX = (w - subW) / 2
        
        surface.SetDrawColor(colors.progressBg.r, colors.progressBg.g, colors.progressBg.b)
        surface.DrawRect(subX, subY, subW, subH)
        
        local subFillW = subW * (data.subProgress.percent / 100)
        surface.SetDrawColor(colors.accent.r, colors.accent.g, colors.accent.b, 200)
        surface.DrawRect(subX, subY, subFillW, subH)
        
        local subText = string.format("%d / %d", data.subProgress.current, data.subProgress.total)
        draw.SimpleText(subText, "AA_Tiny", w / 2, subY + 18, colors.textDim, TEXT_ALIGN_CENTER)
    end
    
    -- ETA display
    if data.eta and data.progress < 100 then
        local etaText = string.format("Estimated: %ds remaining", math.ceil(data.eta))
        draw.SimpleText(etaText, "AA_Tiny", w / 2, subY + 30, colors.textDim, TEXT_ALIGN_CENTER)
    end
    
    -- Cancel button (if cancellable)
    if data.cancellable then
        self:DrawCancelButton(w / 2, panelY + panelH - 50, t)
    end
    
    -- Activity indicator (spinning dots)
    self:DrawActivityIndicator(w - 60, h - 60, t)
end

-- Draw animated grid background
function AA.Loading:DrawGrid(w, h, t)
    surface.SetDrawColor(30, 30, 40, 50)
    local gridSize = 50
    local offset = (t * 20) % gridSize
    
    for x = -gridSize, w, gridSize do
        surface.DrawLine(x + offset, 0, x + offset, h)
    end
    for y = -gridSize, h, gridSize do
        surface.DrawLine(0, y + offset, w, y + offset)
    end
end

-- Draw scanline effect
function AA.Loading:DrawScanlines(w, h, t)
    local scanY = (t * 100) % h
    surface.SetDrawColor(255, 100, 100, 5)
    surface.DrawRect(0, scanY, w, 2)
    
    -- Vignette
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h * 0.15)
    surface.DrawRect(0, h * 0.85, w, h * 0.15)
end

-- Draw cancel button
function AA.Loading:DrawCancelButton(x, y, t)
    local w, h = 120, 35
    local mx, my = input.GetCursorPos()
    
    local hovered = mx >= x - w/2 and mx <= x + w/2 and my >= y - h/2 and my <= y + h/2
    
    local bgColor = hovered and Color(200, 50, 50) or Color(100, 30, 30)
    surface.SetDrawColor(bgColor)
    surface.DrawRect(x - w/2, y - h/2, w, h)
    
    surface.SetDrawColor(150, 150, 150)
    surface.DrawOutlinedRect(x - w/2, y - h/2, w, h, 1)
    
    draw.SimpleText("CANCEL", "AA_Small", x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Click handling
    if hovered and input.IsMouseDown(MOUSE_LEFT) and t > 0.5 then
        self:Cancel()
    end
end

-- Draw spinning activity indicator
function AA.Loading:DrawActivityIndicator(x, y, t)
    local radius = 15
    local dots = 8
    
    for i = 1, dots do
        local angle = (i / dots) * math.pi * 2 - t * 3
        local alpha = (i / dots) * 200 + 55
        local dx = x + math.cos(angle) * radius
        local dy = y + math.sin(angle) * radius
        
        surface.SetDrawColor(220, 60, 60, alpha)
        surface.DrawRect(dx - 2, dy - 2, 4, 4)
    end
end

-- Console commands for testing
concommand.Add("aa_loading_test", function()
    AA.Loading:Show("LOADING ASSETS", "Scanning workshop models...", { cancellable = true })
    
    -- Simulate progress
    local progress = 0
    timer.Create("AA_LoadingTest", 0.1, 100, function()
        progress = progress + math.random(1, 3)
        if progress >= 100 then
            progress = 100
            AA.Loading:Update(progress, "Complete!")
            timer.Simple(0.5, function()
                AA.Loading:Hide()
            end)
            timer.Remove("AA_LoadingTest")
        else
            local messages = {
                "Scanning workshop models...",
                "Validating model files...",
                "Building model cache...",
                "Optimizing for performance...",
            }
            local stage = math.floor(progress / 25) + 1
            AA.Loading:Update(progress, messages[stage], "STAGE " .. stage .. "/4")
        end
    end)
end)

concommand.Add("aa_loading_hide", function()
    AA.Loading:Hide()
end)

-- Network receiver for server-initiated loading
net.Receive("AA_Loading_Start", function()
    local title = net.ReadString()
    local message = net.ReadString()
    local cancellable = net.ReadBool()
    
    AA.Loading:Show(title, message, { cancellable = cancellable })
end)

net.Receive("AA_Loading_Update", function()
    local progress = net.ReadFloat()
    local message = net.ReadString()
    local stage = net.ReadString()
    
    AA.Loading:Update(progress, message ~= "" and message or nil, stage ~= "" and stage or nil)
end)

net.Receive("AA_Loading_Complete", function()
    AA.Loading:Hide()
end)

print("[Lambda Arcade] Loading screen system initialized")
