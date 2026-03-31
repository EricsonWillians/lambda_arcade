--[[
    Arcade Anomaly: Enhanced Menus
    Modern animated UI with arcade aesthetics
--]]

AA.Menus = AA.Menus or {}
AA.Menus.ActivePanel = nil
AA.Menus.MenuAlpha = 0
AA.Menus.Particles = {}

-- Create background particles for menu
function AA.Menus:CreateParticles()
    self.Particles = {}
    for i = 1, 30 do
        table.insert(self.Particles, {
            x = math.random(0, ScrW()),
            y = math.random(0, ScrH()),
            size = math.random(2, 6),
            speed = math.random(20, 60),
            alpha = math.random(50, 150),
        })
    end
end

function AA.Menus:DrawParticles()
    if #self.Particles == 0 then
        self:CreateParticles()
    end
    
    local w, h = ScrW(), ScrH()
    
    for _, p in ipairs(self.Particles) do
        p.y = p.y - p.speed * FrameTime()
        if p.y < -10 then
            p.y = h + 10
            p.x = math.random(0, w)
        end
        
        surface.SetDrawColor(200, 50, 50, p.alpha)
        surface.DrawRect(p.x, p.y, p.size, p.size)
    end
end

-- Main Start Menu
function AA.Menus:ShowStartMenu()
    -- Close any existing menu
    if IsValid(self.ActivePanel) then
        self.ActivePanel:Remove()
    end
    
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
        
        -- Dark background with gradient
        surface.SetDrawColor(5, 5, 8, 250)
        surface.DrawRect(0, 0, w, h)
        
        -- Grid pattern
        surface.SetDrawColor(30, 30, 40, 100)
        local gridSize = 40
        for x = 0, w, gridSize do
            surface.DrawLine(x, 0, x, h)
        end
        for y = 0, h, gridSize do
            surface.DrawLine(0, y, w, y)
        end
        
        -- Particles
        AA.Menus:DrawParticles()
        
        -- Scanline effect
        local scanY = (self.AnimTime * 100) % h
        surface.SetDrawColor(255, 100, 100, 10)
        surface.DrawRect(0, scanY, w, 2)
        
        -- Vignette
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, w, h * 0.15)
        surface.DrawRect(0, h * 0.85, w, h * 0.15)
        
        -- Title glow animation
        local glow = math.abs(math.sin(self.AnimTime * 2)) * 50
        
        -- Main title
        draw.SimpleText("LAMBDA ARCADE", "AA_Title_Glow", w/2, h * 0.2, Color(200, 50, 50, 100 + glow), TEXT_ALIGN_CENTER)
        draw.SimpleText("LAMBDA ARCADE", "AA_Title", w/2, h * 0.2, Color(220, 60, 60), TEXT_ALIGN_CENTER)
        
        -- Subtitle with typewriter effect
        local subtitle = "ENDLESS COMBAT"
        local revealChars = math.min(#subtitle, math.floor(self.AnimTime * 15))
        local revealed = string.sub(subtitle, 1, revealChars)
        draw.SimpleText(revealed, "AA_Subtitle", w/2, h * 0.28, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        
        -- Cursor blink
        if revealChars < #subtitle and math.floor(self.AnimTime * 3) % 2 == 0 then
            draw.SimpleText("_", "AA_Subtitle", w/2 + surface.GetTextSize(revealed, "AA_Subtitle")/2, h * 0.28, Color(200, 50, 50), TEXT_ALIGN_CENTER)
        end
        
        -- Decorative lines
        surface.SetDrawColor(200, 50, 50, 200)
        surface.DrawRect(w/2 - 200, h * 0.35, 400, 2)
        
        -- Instructions at bottom
        draw.SimpleText("Press Q for menu | Mouse to select", "AA_Tiny", w/2, h - 30, Color(100, 100, 100), TEXT_ALIGN_CENTER)
    end
    
    -- Start Button
    local startBtn = vgui.Create("DButton", frame)
    startBtn:SetSize(280, 70)
    startBtn:SetPos(ScrW()/2 - 140, ScrH() * 0.42)
    startBtn:SetText("")
    startBtn:SetFont("AA_Medium")
    startBtn:SetTextColor(color_white)
    
    startBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        local time = frame.AnimTime
        
        -- Glow effect
        if hover then
            local glow = math.abs(math.sin(time * 8)) * 30
            surface.SetDrawColor(220, 70, 70, 50 + glow)
            surface.DrawRect(-5, -5, w + 10, h + 10)
        end
        
        -- Background
        local bgColor = hover and Color(220, 70, 70) or Color(180, 50, 50)
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)
        
        -- Shine effect
        if hover then
            surface.SetDrawColor(255, 100, 100, 100)
            surface.DrawRect(0, h * 0.3, w, h * 0.4)
        end
        
        -- Border
        surface.SetDrawColor(255, 255, 255, hover and 200 or 100)
        surface.DrawOutlinedRect(0, 0, w, h, hover and 3 or 2)
        
        -- Text with glow
        if hover then
            draw.SimpleText("START RUN", "AA_Medium_Glow", w/2, h/2, Color(255, 255, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("START RUN", "AA_Medium", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    startBtn.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        
        -- Show feedback that request is being sent
        AA.Toast:Info("Starting run...", 2)
        
        -- Disable button temporarily
        startBtn:SetEnabled(false)
        
        -- Send request
        AA.Net.RequestStartRun()
        
        -- Close menu after brief delay
        timer.Simple(0.3, function()
            if IsValid(frame) then
                frame:Close()
            end
        end)
    end
    
    -- Secondary buttons container
    local btnY = ScrH() * 0.55
    local btnSpacing = 55
    
    -- Test Spawn Button
    local testBtn = vgui.Create("DButton", frame)
    testBtn:SetSize(220, 45)
    testBtn:SetPos(ScrW()/2 - 110, btnY)
    testBtn:SetText("")
    
    testBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        local bgColor = hover and Color(70, 70, 80) or Color(50, 50, 60)
        
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(150, 150, 150, hover and 200 or 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("TEST SPAWN", "AA_Small", w/2, h/2, hover and color_white or Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    testBtn.DoClick = function()
        surface.PlaySound("buttons/button9.wav")
        LocalPlayer():ConCommand("aa_force_spawn 1")
        frame:Close()
    end
    
    -- How to Play Button
    local helpBtn = vgui.Create("DButton", frame)
    helpBtn:SetSize(220, 45)
    helpBtn:SetPos(ScrW()/2 - 110, btnY + btnSpacing)
    helpBtn:SetText("")
    
    helpBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        local bgColor = hover and Color(70, 70, 80) or Color(50, 50, 60)
        
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(150, 150, 150, hover and 200 or 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("HOW TO PLAY", "AA_Small", w/2, h/2, hover and color_white or Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    helpBtn.DoClick = function()
        surface.PlaySound("buttons/button9.wav")
        AA.Menus:ShowHelp(frame)
    end
    
    -- Close Button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(150, 35)
    closeBtn:SetPos(ScrW()/2 - 75, btnY + btnSpacing * 2)
    closeBtn:SetText("")
    
    closeBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        
        surface.SetDrawColor(40, 40, 45)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(100, 100, 100, hover and 150 or 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("CLOSE", "AA_Tiny", w/2, h/2, hover and Color(200, 200, 200) or Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    closeBtn.DoClick = function()
        surface.PlaySound("buttons/button6.wav")
        frame:Close()
    end
end

-- Help/Instructions Panel
function AA.Menus:ShowHelp(parent)
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDraggable(false)
    
    if IsValid(parent) then
        parent:SetVisible(false)
        frame.OnClose = function() parent:SetVisible(true) end
    end
    
    frame.AnimTime = 0
    frame.Paint = function(self, w, h)
        self.AnimTime = self.AnimTime + FrameTime()
        
        -- Background
        surface.SetDrawColor(10, 10, 12, 245)
        surface.DrawRect(0, 0, w, h)
        
        -- Border
        surface.SetDrawColor(200, 50, 50, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Title
        draw.SimpleText("HOW TO PLAY", "AA_Large", w/2, 30, Color(220, 60, 60), TEXT_ALIGN_CENTER)
        
        -- Decorative line
        surface.SetDrawColor(200, 50, 50, 150)
        surface.DrawRect(w/2 - 150, 85, 300, 2)
    end
    
    -- Content panel
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetSize(560, 380)
    scroll:SetPos(20, 100)
    
    local content = [[
        <html>
        <head>
            <style>
                body { 
                    background: transparent; 
                    color: #ddd; 
                    font-family: 'Roboto', Arial, sans-serif; 
                    padding: 10px;
                    line-height: 1.6;
                }
                h1 { 
                    color: #dc3232; 
                    font-size: 24px;
                    border-bottom: 2px solid #dc3232;
                    padding-bottom: 10px;
                    margin-bottom: 20px;
                }
                h2 { 
                    color: #ffb400; 
                    font-size: 18px;
                    margin-top: 25px;
                }
                .enemy { 
                    margin: 15px 0; 
                    padding: 15px; 
                    background: rgba(40, 40, 50, 0.8); 
                    border-left: 3px solid #dc3232;
                }
                .enemy b {
                    color: #ffb400;
                    font-size: 16px;
                }
                .cmd { 
                    color: #888; 
                    font-family: monospace; 
                    background: rgba(60, 60, 70, 0.8); 
                    padding: 3px 8px;
                    border-radius: 3px;
                }
                .tip {
                    background: rgba(255, 180, 0, 0.1);
                    border: 1px solid rgba(255, 180, 0, 0.3);
                    padding: 15px;
                    margin: 20px 0;
                    border-radius: 5px;
                }
                ul {
                    margin: 10px 0;
                    padding-left: 25px;
                }
                li {
                    margin: 8px 0;
                }
            </style>
        </head>
        <body>
            <h1>LAMBDA ARCADE</h1>
            <p>Survive against endless waves of procedurally spawned enemies. Build combos to multiply your score and compete for the high score!</p>
            
            <h2>Controls</h2>
            <ul>
                <li>Type <span class="cmd">aa_menu</span> or press <span class="cmd">Q</span> to open the menu</li>
                <li>Type <span class="cmd">aa_start</span> to start a run</li>
                <li>Type <span class="cmd">aa_force_spawn [1-6]</span> to spawn test enemies</li>
            </ul>
            
            <h2>Enemy Types</h2>
            <div class="enemy"><b>Chaser (1)</b><br>Basic melee enemy. Moderate speed and health. The standard threat.</div>
            <div class="enemy"><b>Rusher (2)</b><br>Fast enemy with burst speed ability. Closes distance quickly.</div>
            <div class="enemy"><b>Brute (3)</b><br>Slow but powerful. High health and damage. Prioritize these.</div>
            <div class="enemy"><b>Shooter (4)</b><br>Ranged enemy. Maintains distance and fires projectiles.</div>
            <div class="enemy"><b>Exploder (5)</b><br>Explodes on death or contact. Keep your distance!</div>
            <div class="enemy"><b>Elite (6)</b><br>Enhanced enemy with special abilities and bonus points.</div>
            
            <div class="tip">
                <b>💀 Pro Tip:</b> Elite enemies drop bonus points and have a chance to spawn special loot. Risk vs reward!
            </div>
            
            <h2>Scoring</h2>
            <ul>
                <li>Kill enemies to build combo</li>
                <li>Higher combos multiply your score</li>
                <li>Elite kills give bonus points</li>
                <li>Survival time adds to score</li>
                <li>Breaking your personal best unlocks bragging rights</li>
            </ul>
        </body>
        </html>
    ]]
    
    local html = vgui.Create("DHTML", scroll)
    html:Dock(FILL)
    html:SetHTML(content)
    
    -- Back button
    local backBtn = vgui.Create("DButton", frame)
    backBtn:SetSize(120, 35)
    backBtn:SetPos(240, 445)
    backBtn:SetText("")
    
    backBtn.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and Color(200, 50, 50) or Color(150, 40, 40))
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
