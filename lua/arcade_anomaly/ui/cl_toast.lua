--[[
    Lambda Arcade: Toast Notification System
    Shows async feedback, events, and status updates
--]]

AA.Toast = AA.Toast or {}
AA.Toast.Active = {}
AA.Toast.Queue = {}
AA.Toast.Config = {
    MaxActive = 5,
    MaxQueue = 20,
    DefaultDuration = 4,
    FadeInTime = 0.3,
    FadeOutTime = 0.5,
    SlideInTime = 0.2,
    StackOffset = 75,
    Position = "top_right", -- "top_right", "top_left", "bottom_right", "bottom_left", "center"
}

-- Toast types with colors and icons
AA.Toast.Types = {
    INFO = {
        color = Color(0, 150, 255),
        icon = "i",
        sound = "ui/buttonrollover.wav",
    },
    SUCCESS = {
        color = Color(50, 255, 100),
        icon = "✓",
        sound = "ui/buttonclickrelease.wav",
    },
    WARNING = {
        color = Color(255, 200, 0),
        icon = "!",
        sound = "buttons/button10.wav",
    },
    ERROR = {
        color = Color(255, 50, 50),
        icon = "✕",
        sound = "buttons/button8.wav",
    },
    ACHIEVEMENT = {
        color = Color(255, 215, 0),
        icon = "★",
        sound = "ui/achievement_earned.wav",
    },
    SPAWN = {
        color = Color(255, 100, 100),
        icon = "⚔",
        sound = "ui/hint.wav",
    },
    SCORE = {
        color = Color(255, 180, 0),
        icon = "+",
        sound = "buttons/blip1.wav",
    },
}

-- Show a toast notification
function AA.Toast:Show(message, toastType, duration, options)
    options = options or {}
    toastType = toastType or "INFO"
    duration = duration or self.Config.DefaultDuration
    
    local typeData = self.Types[toastType] or self.Types.INFO
    
    local toast = {
        id = CurTime() .. math.random(),
        message = message,
        type = toastType,
        typeData = typeData,
        duration = duration,
        spawnTime = CurTime(),
        fadeIn = 0,
        fadeOut = 0,
        offset = 0,
        options = options,
    }
    
    -- Play sound
    if typeData.sound and not options.mute then
        surface.PlaySound(typeData.sound)
    end
    
    -- Add to active or queue
    if #self.Active < self.Config.MaxActive then
        table.insert(self.Active, 1, toast)
    else
        -- Add to queue
        if #self.Queue < self.Config.MaxQueue then
            table.insert(self.Queue, toast)
        else
            -- Remove oldest from queue
            table.remove(self.Queue, 1)
            table.insert(self.Queue, toast)
        end
    end
    
    hook.Run("AA_ToastShown", toast)
    return toast.id
end

-- Quick show functions
function AA.Toast:Info(message, duration)
    return self:Show(message, "INFO", duration)
end

function AA.Toast:Success(message, duration)
    return self:Show(message, "SUCCESS", duration)
end

function AA.Toast:Warning(message, duration)
    return self:Show(message, "WARNING", duration)
end

function AA.Toast:Error(message, duration)
    return self:Show(message, "ERROR", duration)
end

function AA.Toast:Achievement(message, duration)
    return self:Show(message, "ACHIEVEMENT", duration or 6)
end

function AA.Toast:Spawn(message, duration)
    return self:Show(message, "SPAWN", duration or 3)
end

function AA.Toast:Score(message, points, duration)
    local text = points and string.format("%s (+%d PTS)", message, points) or message
    return self:Show(text, "SCORE", duration)
end

-- Remove a specific toast
function AA.Toast:Remove(id)
    for i, toast in ipairs(self.Active) do
        if toast.id == id then
            toast.fadeOut = CurTime()
            return true
        end
    end
    return false
end

-- Clear all toasts
function AA.Toast:Clear()
    self.Active = {}
    self.Queue = {}
end

-- Main paint hook
hook.Add("HUDPaint", "AA_Toast_Paint", function()
    AA.Toast:Draw()
end)

-- Draw all active toasts
function AA.Toast:Draw()
    local now = CurTime()
    local config = self.Config
    
    -- Process active toasts
    for i = #self.Active, 1, -1 do
        local toast = self.Active[i]
        local age = now - toast.spawnTime
        
        -- Calculate fade states
        if age < config.FadeInTime then
            toast.fadeIn = age / config.FadeInTime
        else
            toast.fadeIn = 1
        end
        
        if age > toast.duration - config.FadeOutTime then
            toast.fadeOut = (age - (toast.duration - config.FadeOutTime)) / config.FadeOutTime
        end
        
        -- Remove expired toasts
        if age >= toast.duration then
            table.remove(self.Active, i)
            
            -- Pull from queue
            if #self.Queue > 0 then
                local nextToast = table.remove(self.Queue, 1)
                nextToast.spawnTime = now
                table.insert(self.Active, 1, nextToast)
            end
        else
            -- Calculate position
            local targetOffset = (i - 1) * config.StackOffset
            toast.offset = Lerp(FrameTime() * 10, toast.offset, targetOffset)
            
            -- Draw the toast
            self:DrawToast(toast, i)
        end
    end
end

-- Draw a single toast
function AA.Toast:DrawToast(toast, index)
    local w, h = 320, 60
    local padding = 10
    local config = self.Config
    
    -- Calculate position based on config
    local x, y
    local marginX, marginY = 20, 20
    
    if config.Position == "top_right" then
        x = ScrW() - w - marginX
        y = marginY + toast.offset
    elseif config.Position == "top_left" then
        x = marginX
        y = marginY + toast.offset
    elseif config.Position == "bottom_right" then
        x = ScrW() - w - marginX
        y = ScrH() - h - marginY - toast.offset
    elseif config.Position == "bottom_left" then
        x = marginX
        y = ScrH() - h - marginY - toast.offset
    else -- center
        x = (ScrW() - w) / 2
        y = (ScrH() / 3) + toast.offset
    end
    
    -- Slide in from side
    local slideOffset = (1 - toast.fadeIn) * 100
    if config.Position == "top_right" or config.Position == "bottom_right" then
        x = x + slideOffset
    else
        x = x - slideOffset
    end
    
    -- Calculate alpha
    local alpha = (1 - toast.fadeOut) * 255
    
    -- Toast background
    local bgColor = Color(15, 15, 20, 240 * (alpha / 255))
    surface.SetDrawColor(bgColor)
    surface.DrawRect(x, y, w, h)
    
    -- Colored accent bar on left
    local accentColor = Color(
        toast.typeData.color.r,
        toast.typeData.color.g,
        toast.typeData.color.b,
        alpha
    )
    surface.SetDrawColor(accentColor)
    surface.DrawRect(x, y, 4, h)
    
    -- Border
    surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, 50)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    
    -- Icon circle
    local iconX = x + 30
    local iconY = y + h / 2
    surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, 30)
    surface.DrawCircle(iconX, iconY, 20, 16)
    surface.SetDrawColor(accentColor)
    surface.DrawOutlinedRect(iconX - 20, iconY - 20, 40, 40, 1)
    
    -- Icon text
    draw.SimpleText(toast.typeData.icon, "AA_Medium", iconX, iconY, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Message text
    local textX = x + 65
    local textY = y + h / 2
    local textColor = Color(255, 255, 255, alpha)
    
    -- Truncate if too long
    local msg = toast.message
    if #msg > 40 then
        msg = string.sub(msg, 1, 37) .. "..."
    end
    
    draw.SimpleText(msg, "AA_Small", textX, textY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Progress bar (time remaining)
    local timeLeft = math.max(0, toast.duration - (CurTime() - toast.spawnTime))
    local progress = timeLeft / toast.duration
    local barW = w - 65 - padding
    local barH = 3
    
    surface.SetDrawColor(30, 30, 35, alpha)
    surface.DrawRect(textX, y + h - 10, barW, barH)
    
    surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, alpha * 0.7)
    surface.DrawRect(textX, y + h - 10, barW * progress, barH)
end

-- Draw helper for circle
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

-- Network receivers for server events
net.Receive("AA_Toast_Show", function()
    local message = net.ReadString()
    local toastType = net.ReadString()
    local duration = net.ReadFloat()
    
    AA.Toast:Show(message, toastType, duration)
end)

-- Hook into game events
hook.Add("AA_EnemySpawned", "AA_Toast_EnemySpawn", function(entIndex, archetype, position, isElite)
    if not AA.Config or not AA.Config.UI or AA.Config.UI.ShowSpawnNotifications ~= false then
        local archetypeName = AA.Types and AA.Types.ArchetypeNames and AA.Types.ArchetypeNames[archetype] or "Enemy"
        local message = isElite and "Elite " .. archetypeName .. " appeared!" or archetypeName .. " spotted!"
        AA.Toast:Spawn(message, 3)
    end
end)

hook.Add("AA_RunStateChanged", "AA_Toast_RunState", function(state, data)
    if state == AA.Types.RunState.RUNNING then
        AA.Toast:Success("Run started! Good luck!", 4)
    elseif state == AA.Types.RunState.PLAYER_DEAD then
        AA.Toast:Error("You died! Run complete.", 5)
    elseif state == AA.Types.RunState.PREPARING_MAP then
        AA.Toast:Info("Preparing map...", 3)
    end
end)

hook.Add("AA_HighScoreBeaten", "AA_Toast_HighScore", function(newScore, oldScore)
    AA.Toast:Achievement(string.format("NEW HIGH SCORE: %d!", newScore), 8)
end)

-- Console commands
concommand.Add("aa_toast_test", function()
    local types = {"INFO", "SUCCESS", "WARNING", "ERROR", "ACHIEVEMENT", "SPAWN", "SCORE"}
    
    for i, toastType in ipairs(types) do
        timer.Simple(i * 0.5, function()
            AA.Toast:Show("Test notification for " .. toastType, toastType, 5)
        end)
    end
end)

concommand.Add("aa_toast_clear", function()
    AA.Toast:Clear()
end)

print("[Lambda Arcade] Toast notification system initialized")
