--[[
    Arcade Anomaly: ULTRA Enhanced Menus
    Modern UX with dark gothic theme, consistent with end screen
--]]

AA.Menus = AA.Menus or {}
AA.Menus.ActivePanel = nil
AA.Menus.MenuAlpha = 0
AA.Menus.Particles = {}
AA.Menus.Colors = {
    bgDark      = Color(8, 8, 12),
    bgPanel     = Color(20, 20, 28),
    bgPanelAlt  = Color(28, 28, 38),
    border      = Color(60, 60, 70),
    borderLight = Color(80, 160, 255),
    textMain    = Color(255, 255, 255),
    textDim     = Color(180, 180, 190),
    textDark    = Color(120, 120, 130),
    accentRed   = Color(220, 60, 60),
    accentGold  = Color(255, 200, 80),
    accentBlue  = Color(80, 160, 255),
    accentGreen = Color(80, 200, 120),
}

-- Create background particles for menu
function AA.Menus:CreateParticles()
    self.Particles = {}
    for i = 1, 40 do
        table.insert(self.Particles, {
            x = math.random(0, ScrW()),
            y = math.random(0, ScrH()),
            size = math.random(1, 4),
            speed = math.random(15, 40),
            alpha = math.random(30, 80),
        })
    end
end

function AA.Menus:DrawParticles()
    if #self.Particles == 0 then
        self:CreateParticles()
    end
    
    local w, h = ScrW(), ScrH()
    local C = self.Colors
    
    for _, p in ipairs(self.Particles) do
        p.y = p.y - p.speed * FrameTime()
        if p.y < -10 then
            p.y = h + 10
            p.x = math.random(0, w)
        end
        
        surface.SetDrawColor(C.accentRed.r, C.accentRed.g, C.accentRed.b, p.alpha)
        surface.DrawRect(p.x, p.y, p.size, p.size)
    end
end

-- Main Start Menu - Enhanced UX
function AA.Menus:ShowStartMenu()
    -- Close any existing menu
    if IsValid(self.ActivePanel) then
        self.ActivePanel:Remove()
    end
    
    local C = self.Colors
    local frame = vgui.Create("DFrame")
    self.ActivePanel = frame
    
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDraggable(false)
    
    -- Animation variables
    frame.AnimTime = 0
    frame.ButtonHover = {}
    
    frame.Paint = function(self, w, h)
        self.AnimTime = self.AnimTime + FrameTime()
        local t = self.AnimTime
        
        -- Solid dark background
        surface.SetDrawColor(C.bgDark)
        surface.DrawRect(0, 0, w, h)
        
        -- Subtle grid pattern
        surface.SetDrawColor(25, 25, 35, 100)
        local gridSize = 50
        for x = 0, w, gridSize do
            surface.DrawLine(x, 0, x, h)
        end
        for y = 0, h, gridSize do
            surface.DrawLine(0, y, w, y)
        end
        
        -- Particles
        AA.Menus:DrawParticles()
        
        -- Vignette
        for i = 1, 4 do
            surface.SetDrawColor(0, 0, 0, 40 - i * 8)
            surface.DrawRect(0, 0, w, h * 0.08 * i)
            surface.DrawRect(0, h * (1 - 0.08 * i), w, h * 0.08 * i)
        end
        
        -- Title section
        local titleY = h * 0.15
        
        -- Main title with glow
        local glow = math.abs(math.sin(t * 1.5)) * 30
        draw.SimpleText("LAMBDA ARCADE", "AA_Title_Glow", w/2 + 2, titleY + 2, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER)
        draw.SimpleText("LAMBDA ARCADE", "AA_Title_Glow", w/2, titleY, Color(C.accentRed.r, C.accentRed.g, C.accentRed.b, 80 + glow), TEXT_ALIGN_CENTER)
        draw.SimpleText("LAMBDA ARCADE", "AA_Title", w/2, titleY, C.textMain, TEXT_ALIGN_CENTER)
        
        -- Subtitle
        draw.SimpleText("ENDLESS ARCADE COMBAT", "AA_Subtitle", w/2, titleY + 70, C.textDim, TEXT_ALIGN_CENTER)
        
        -- Decorative line
        surface.SetDrawColor(C.accentRed.r, C.accentRed.g, C.accentRed.b, 150)
        surface.DrawRect(w/2 - 150, titleY + 95, 300, 2)
        
        -- Version info
        draw.SimpleText("v" .. (AA.Version or "1.0"), "AA_Tiny", w - 20, h - 20, C.textDark, TEXT_ALIGN_RIGHT)
    end
    
    -- Button configuration
    local btnWidth, btnHeight = 300, 65
    local btnX = ScrW()/2 - btnWidth/2
    local startY = ScrH() * 0.38
    local btnSpacing = 75
    
    -- START BUTTON (Primary)
    local startBtn = vgui.Create("DButton", frame)
    startBtn:SetSize(btnWidth, btnHeight)
    startBtn:SetPos(btnX, startY)
    startBtn:SetText("")
    
    startBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        local time = frame.AnimTime
        
        -- Glow on hover
        if hover then
            local glow = math.abs(math.sin(time * 6)) * 20
            surface.SetDrawColor(C.accentRed.r, C.accentRed.g, C.accentRed.b, 40 + glow)
            surface.DrawRect(-4, -4, w + 8, h + 8)
        end
        
        -- Background
        local bgColor = hover and Color(200, 60, 60) or C.accentRed
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)
        
        -- Inner shine on hover
        if hover then
            surface.SetDrawColor(255, 120, 120, 80)
            surface.DrawRect(0, h * 0.35, w, h * 0.3)
        end
        
        -- Border
        surface.SetDrawColor(255, 255, 255, hover and 200 or 120)
        surface.DrawOutlinedRect(0, 0, w, h, hover and 2 or 1)
        
        -- Text
        local textY = h/2
        if hover then
            draw.SimpleText("START RUN", "AA_Medium_Glow", w/2, textY, Color(255, 255, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("START RUN", "AA_Medium", w/2, textY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    startBtn.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        AA.Toast:Info("Starting run...", 2)
        startBtn:SetEnabled(false)
        AA.Net.RequestStartRun()
        timer.Simple(0.3, function()
            if IsValid(frame) then frame:Close() end
        end)
    end
    
    -- HOW TO PLAY BUTTON
    local helpBtn = vgui.Create("DButton", frame)
    helpBtn:SetSize(220, 50)
    helpBtn:SetPos(ScrW()/2 - 110, startY + btnSpacing)
    helpBtn:SetText("")
    
    helpBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and C.bgPanelAlt or C.bgPanel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(hover and C.borderLight or C.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("HOW TO PLAY", "AA_Small", w/2, h/2, hover and C.textMain or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    helpBtn.DoClick = function()
        surface.PlaySound("buttons/button9.wav")
        AA.Menus:ShowHelp(frame)
    end
    
    -- KEY BINDINGS BUTTON
    local bindsBtn = vgui.Create("DButton", frame)
    bindsBtn:SetSize(220, 50)
    bindsBtn:SetPos(ScrW()/2 - 110, startY + btnSpacing * 1.7)
    bindsBtn:SetText("")
    
    bindsBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and C.bgPanelAlt or C.bgPanel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(hover and C.borderLight or C.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("CONTROLS", "AA_Small", w/2, h/2, hover and C.textMain or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    bindsBtn.DoClick = function()
        surface.PlaySound("buttons/button9.wav")
        AA.Menus:ShowControls(frame)
    end
    
    -- TEST SPAWN BUTTON
    local testBtn = vgui.Create("DButton", frame)
    testBtn:SetSize(180, 40)
    testBtn:SetPos(ScrW()/2 - 90, startY + btnSpacing * 2.5)
    testBtn:SetText("")
    
    testBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(40, 40, 50)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 80, 90, hover and 150 or 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("TEST SPAWN", "AA_Tiny", w/2, h/2, hover and C.textDim or C.textDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    testBtn.DoClick = function()
        surface.PlaySound("buttons/button9.wav")
        LocalPlayer():ConCommand("aa_force_spawn 1")
        frame:Close()
    end
    
    -- CLOSE BUTTON
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(120, 35)
    closeBtn:SetPos(ScrW()/2 - 60, startY + btnSpacing * 3.2)
    closeBtn:SetText("")
    
    closeBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(35, 35, 40)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 80, 90, hover and 120 or 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("CLOSE", "AA_Tiny", w/2, h/2, hover and Color(200, 200, 200) or C.textDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    closeBtn.DoClick = function()
        surface.PlaySound("buttons/button6.wav")
        frame:Close()
    end
    
    -- Quick tips at bottom
    local tipPanel = vgui.Create("DPanel", frame)
    tipPanel:SetSize(400, 40)
    tipPanel:SetPos(ScrW()/2 - 200, ScrH() - 60)
    tipPanel.Paint = function(self, w, h)
        -- Tip background
        surface.SetDrawColor(C.bgPanel.r, C.bgPanel.g, C.bgPanel.b, 200)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        -- Rotating tips
        local tips = {
            "Tip: Build combos to multiply your score",
            "Tip: Elite enemies drop bonus points",
            "Tip: Press Q anytime to open this menu",
            "Tip: Dodge shooter projectiles for survival",
            "Tip: Use your speed boost to escape hordes",
        }
        local tipIndex = math.floor(frame.AnimTime / 4) % #tips + 1
        draw.SimpleText(tips[tipIndex], "AA_Tiny", w/2, h/2, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Enhanced Help/Instructions Panel
function AA.Menus:ShowHelp(parent)
    local C = self.Colors
    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 600)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDraggable(true)
    
    if IsValid(parent) then
        parent:SetVisible(false)
        frame.OnClose = function() parent:SetVisible(true) end
    end
    
    frame.Paint = function(self, w, h)
        -- Background
        surface.SetDrawColor(C.bgDark)
        surface.DrawRect(0, 0, w, h)
        
        -- Border
        surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Header bar
        surface.SetDrawColor(C.bgPanel)
        surface.DrawRect(0, 0, w, 60)
        surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 100)
        surface.DrawRect(0, 60, w, 1)
        
        -- Title
        draw.SimpleText("HOW TO PLAY", "AA_Large", w/2, 30, C.accentRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Tab panel for organization
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:SetPos(10, 70)
    sheet:SetSize(680, 480)
    
    -- Style the tabs
    sheet.Paint = function(self, w, h)
        surface.SetDrawColor(C.bgPanel)
        surface.DrawRect(0, 20, w, h - 20)
    end
    
    -- OVERVIEW TAB
    local overview = vgui.Create("DPanel")
    overview.Paint = function() end
    
    local overviewText = vgui.Create("DLabel", overview)
    overviewText:SetPos(20, 20)
    overviewText:SetSize(640, 400)
    overviewText:SetFont("AA_Small")
    overviewText:SetTextColor(C.textDim)
    overviewText:SetWrap(true)
    overviewText:SetText([[Welcome to Lambda Arcade - an endless survival combat experience.

OBJECTIVE:
Survive against endless waves of procedurally spawned enemies. Build combos to multiply your score and compete for the high score!

GAME FLOW:
1. Start a run from this menu
2. Enemies spawn in waves of increasing difficulty
3. Kill enemies to build combo multipliers
4. Survive as long as possible
5. Beat your personal best!

The game features 6 different enemy archetypes, each with unique behaviors and threats. Learning their patterns is key to survival.

Good luck, survivor.]])
    
    sheet:AddSheet("Overview", overview, "icon16/information.png")
    
    -- ENEMIES TAB
    local enemies = vgui.Create("DPanel")
    enemies.Paint = function() end
    
    local enemyList = vgui.Create("DScrollPanel", enemies)
    enemyList:SetPos(10, 10)
    enemyList:SetSize(660, 420)
    enemyList.Paint = function() end
    
    local enemyData = {
        {name = "CHASER", icon = "●", color = C.textDim, desc = "Basic melee enemy. Moderate speed and health. Standard cannon fodder.", threat = "Low"},
        {name = "RUSHER", icon = "▲", color = C.accentGold, desc = "Fast enemy with burst speed. Closes distance quickly. Prioritize these.", threat = "Medium"},
        {name = "BRUTE", icon = "■", color = C.accentRed, desc = "Slow but powerful tank. High health and damage. Keep distance.", threat = "High"},
        {name = "SHOOTER", icon = "◆", color = C.accentBlue, desc = "Ranged enemy with projectiles. Watch for the charge-up glow.", threat = "Medium"},
        {name = "EXPLODER", icon = "★", color = Color(255, 100, 0), desc = "Explodes on death or contact. Maintain distance at all costs!", threat = "High"},
        {name = "ELITE", icon = "✦", color = Color(200, 50, 255), desc = "Enhanced enemy with special abilities. Drops bonus points and loot.", threat = "Very High"},
    }
    
    for i, enemy in ipairs(enemyData) do
        local y = (i - 1) * 70
        local panel = vgui.Create("DPanel", enemyList)
        panel:SetPos(0, y)
        panel:SetSize(640, 65)
        panel.Paint = function(self, w, h)
            -- Background
            surface.SetDrawColor(C.bgPanelAlt)
            surface.DrawRect(0, 0, w, h)
            
            -- Left accent bar
            surface.SetDrawColor(enemy.color)
            surface.DrawRect(0, 0, 4, h)
            
            -- Border
            surface.SetDrawColor(C.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        local icon = vgui.Create("DLabel", panel)
        icon:SetPos(15, 10)
        icon:SetSize(30, 30)
        icon:SetFont("AA_Medium")
        icon:SetTextColor(enemy.color)
        icon:SetText(enemy.icon)
        
        local name = vgui.Create("DLabel", panel)
        name:SetPos(50, 8)
        name:SetSize(150, 25)
        name:SetFont("AA_Small")
        name:SetTextColor(enemy.color)
        name:SetText(enemy.name)
        
        local threat = vgui.Create("DLabel", panel)
        threat:SetPos(200, 10)
        threat:SetSize(100, 20)
        threat:SetFont("AA_Tiny")
        threat:SetTextColor(enemy.color)
        threat:SetText("Threat: " .. enemy.threat)
        
        local desc = vgui.Create("DLabel", panel)
        desc:SetPos(50, 32)
        desc:SetSize(580, 30)
        desc:SetFont("AA_Tiny")
        desc:SetTextColor(C.textDim)
        desc:SetText(enemy.desc)
    end
    
    sheet:AddSheet("Enemies", enemies, "icon16/user_suit.png")
    
    -- SCORING TAB
    local scoring = vgui.Create("DPanel")
    scoring.Paint = function() end
    
    local scoreText = vgui.Create("DLabel", scoring)
    scoreText:SetPos(20, 20)
    scoreText:SetSize(640, 400)
    scoreText:SetFont("AA_Small")
    scoreText:SetTextColor(C.textDim)
    scoreText:SetWrap(true)
    scoreText:SetText([[SCORING SYSTEM:

• Base Points: Each kill awards points based on enemy type
• Combo Multiplier: Build combo by killing enemies quickly
  - 5+ combo: 1.5x multiplier
  - 10+ combo: 2.0x multiplier  
  - 20+ combo: 3.0x multiplier
  - 50+ combo: 5.0x multiplier

• Elite Bonus: Elite kills grant +50% bonus points
• Survival Bonus: Points awarded every 30 seconds survived

COMBO SYSTEM:
Your combo timer resets after 2.5 seconds without a kill. Keep the pressure on to maintain high multipliers!

ENEMY POINT VALUES:
• Chaser: 100 points
• Rusher: 150 points
• Brute: 300 points
• Shooter: 200 points
• Exploder: 250 points
• Elite: 1000 points (500 bonus)

PERSONAL BEST:
Beat your high score to unlock recognition on the end screen.]])
    
    sheet:AddSheet("Scoring", scoring, "icon16/coins.png")
    
    -- Back button
    local backBtn = vgui.Create("DButton", frame)
    backBtn:SetSize(140, 40)
    backBtn:SetPos(280, 555)
    backBtn:SetText("")
    
    backBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and C.accentRed or Color(150, 40, 40))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, hover and 200 or 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("BACK", "AA_Small", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    backBtn.DoClick = function()
        surface.PlaySound("buttons/button6.wav")
        frame:Close()
    end
end

-- Controls/Bindings Panel
function AA.Menus:ShowControls(parent)
    local C = self.Colors
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 450)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDraggable(true)
    
    if IsValid(parent) then
        parent:SetVisible(false)
        frame.OnClose = function() parent:SetVisible(true) end
    end
    
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(C.bgDark)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Header
        surface.SetDrawColor(C.bgPanel)
        surface.DrawRect(0, 0, w, 60)
        draw.SimpleText("CONTROLS", "AA_Large", w/2, 30, C.accentBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(20, 80)
    scroll:SetSize(460, 300)
    
    local controls = {
        {key = "W A S D", action = "Movement"},
        {key = "SPACE", action = "Jump"},
        {key = "MOUSE1", action = "Fire Weapon"},
        {key = "MOUSE2", action = "Alt Fire / Zoom"},
        {key = "R", action = "Reload"},
        {key = "1-6", action = "Weapon Slots"},
        {key = "Q", action = "Open Menu (when not in run)"},
        {key = "F1", action = "Show Help"},
        {key = "~ / Console", action = "Open Console for commands"},
    }
    
    for i, ctrl in ipairs(controls) do
        local y = (i - 1) * 35
        local panel = vgui.Create("DPanel", scroll)
        panel:SetPos(0, y)
        panel:SetSize(440, 32)
        panel.Paint = function(self, w, h)
            -- Alternating background
            if i % 2 == 0 then
                surface.SetDrawColor(C.bgPanelAlt)
                surface.DrawRect(0, 0, w, h)
            end
            
            -- Key
            surface.SetDrawColor(C.bgPanel)
            surface.DrawRect(5, 3, 120, 26)
            surface.SetDrawColor(C.border)
            surface.DrawOutlinedRect(5, 3, 120, 26, 1)
            
            draw.SimpleText(ctrl.key, "AA_Small", 65, 16, C.accentBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(ctrl.action, "AA_Small", 140, 16, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Console commands section
    local cmdLabel = vgui.Create("DLabel", frame)
    cmdLabel:SetPos(20, 390)
    cmdLabel:SetSize(460, 20)
    cmdLabel:SetFont("AA_Tiny")
    cmdLabel:SetTextColor(C.textDark)
    cmdLabel:SetText("CONSOLE COMMANDS:")
    
    local cmdText = vgui.Create("DLabel", frame)
    cmdText:SetPos(20, 410)
    cmdText:SetSize(460, 40)
    cmdText:SetFont("AA_Tiny")
    cmdText:SetTextColor(C.textDim)
    cmdText:SetWrap(true)
    cmdText:SetText("aa_start - Start a run | aa_stop - End run | aa_menu - Open menu | aa_force_spawn [1-6] - Spawn enemy")
    
    -- Back button
    local backBtn = vgui.Create("DButton", frame)
    backBtn:SetSize(120, 35)
    backBtn:SetPos(190, 400)
    backBtn:SetText("")
    
    backBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and C.accentBlue or Color(40, 80, 150))
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("BACK", "AA_Small", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    backBtn.DoClick = function()
        surface.PlaySound("buttons/button6.wav")
        frame:Close()
    end
end

-- Show menu on spawn if not in active run
hook.Add("PlayerSpawn", "AA_Menus_Spawn", function(ply)
    if ply ~= LocalPlayer() then return end
    
    timer.Simple(1.5, function()
        local state = AA.Types.RunState.IDLE
        if AA.RunStateClient and AA.RunStateClient.GetCurrentState then
            state = AA.RunStateClient:GetCurrentState()
        end
        
        if state == AA.Types.RunState.IDLE then
            AA.Menus:ShowStartMenu()
        end
    end)
end)

-- Also show on initial game load
hook.Add("InitPostEntity", "AA_Menus_Init", function()
    timer.Simple(3.0, function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local state = AA.Types.RunState.IDLE
        if AA.RunStateClient and AA.RunStateClient.GetCurrentState then
            state = AA.RunStateClient:GetCurrentState()
        end
        
        if ply:Alive() and state == AA.Types.RunState.IDLE then
            AA.Menus:ShowStartMenu()
        end
    end)
end)

-- Console command
concommand.Add("aa_menu", function()
    AA.Menus:ShowStartMenu()
end)

-- Bind key to open menu
hook.Add("PlayerBindPress", "AA_Menu_Bind", function(ply, bind, pressed)
    if bind == "+menu" and pressed then
        local state = AA.RunStateClient and AA.RunStateClient:GetCurrentState() or AA.Types.RunState.IDLE
        if state == AA.Types.RunState.IDLE or state == AA.Types.RunState.RUN_SUMMARY then
            AA.Menus:ShowStartMenu()
            return true
        end
    end
end)
