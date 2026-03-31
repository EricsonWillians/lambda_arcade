--[[
    Arcade Anomaly: Run State Manager
    
    Manages the game flow state machine.
--]]

AA.RunState = AA.RunState or {}
AA.RunState.Current = AA.Types.RunState.IDLE
AA.RunState.Data = {}
AA.RunState.StartTime = 0
AA.RunState.Timer = nil

-- State transition
function AA.RunState:Transition(newState, data)
    local oldState = self.Current
    self.Current = newState
    self.Data = data or {}
    
    print(string.format("[AA] State: %s -> %s", 
        self:GetStateName(oldState), 
        self:GetStateName(newState)))
    
    -- Clear any existing timer from previous state
    if self.Timer then
        timer.Remove(self.Timer)
        self.Timer = nil
    end
    
    -- Notify clients
    if AA.Net and AA.Net.BroadcastRunState then
        AA.Net.BroadcastRunState(newState, self.Data)
    end
    
    -- Send toast notifications for important state changes
    if AA.Net and AA.Net.ShowToast then
        if newState == AA.Types.RunState.PREPARING_MAP then
            AA.Net.ShowToast(nil, "Preparing map and finding spawn points...", "INFO", 3)
        elseif newState == AA.Types.RunState.COUNTDOWN then
            AA.Net.ShowToast(nil, "Get ready! Countdown starting...", "WARNING", 2)
        elseif newState == AA.Types.RunState.RUNNING then
            AA.Net.ShowToast(nil, "FIGHT! Survive as long as you can!", "SUCCESS", 4)
        elseif newState == AA.Types.RunState.PLAYER_DEAD then
            AA.Net.ShowToast(nil, "You have fallen! Run complete.", "ERROR", 5)
        end
    end
    
    -- Emit event
    if AA.Events and AA.Events.Emit then
        AA.Events.Emit(AA.Events.Names.RUN_STATE_CHANGED, newState, oldState, self.Data)
    end
    
    -- Handle state entry
    self:OnStateEnter(newState)
end

function AA.RunState:GetStateName(state)
    for name, val in pairs(AA.Types.RunState) do
        if val == state then return name end
    end
    return "UNKNOWN"
end

-- State entry handlers
function AA.RunState:OnStateEnter(state)
    if state == AA.Types.RunState.PREPARING_MAP then
        self:OnPreparingMap()
    elseif state == AA.Types.RunState.COUNTDOWN then
        self:OnCountdown()
    elseif state == AA.Types.RunState.RUNNING then
        self:OnRunning()
    elseif state == AA.Types.RunState.PLAYER_DEAD then
        self:OnPlayerDead()
    elseif state == AA.Types.RunState.RUN_SUMMARY then
        self:OnRunSummary()
    elseif state == AA.Types.RunState.RESTARTING then
        self:OnRestarting()
    end
end

function AA.RunState:OnPreparingMap()
    -- Analyze map and prepare spawn points
    if AA.MapAnalyzer then
        AA.MapAnalyzer:AnalyzeCurrentMap()
    end
    
    -- Reset run data
    if AA.ScoreManager and AA.ScoreManager.ResetRun then
        AA.ScoreManager:ResetRun()
    end
    
    -- Cleanup any existing enemies
    if AA.EnemyManager then
        AA.EnemyManager:CleanupAll()
    end
    
    -- Clear spawn queue
    if AA.SpawnManager and AA.SpawnManager.SpawnQueue then
        AA.SpawnManager.SpawnQueue = {}
    end
    
    -- Clear timer
    if self.Timer then
        timer.Remove(self.Timer)
        self.Timer = nil
    end
    
    -- Transition to countdown after short delay
    local runState = AA.RunState
    timer.Simple(1.0, function()
        if runState and runState.Transition then
            runState:Transition(AA.Types.RunState.COUNTDOWN)
        end
    end)
end

function AA.RunState:OnCountdown()
    local countdown = AA.Config.Game.CountdownDuration or 3
    
    self.Timer = "AA_Countdown"
    timer.Create(self.Timer, 1, countdown, function()
        countdown = countdown - 1
        
        -- Notify clients of countdown tick
        if AA.Net and AA.Net.BroadcastRunState then
            AA.Net.BroadcastRunState(AA.Types.RunState.COUNTDOWN, { 
                timeRemaining = countdown,
                totalTime = AA.Config.Game.CountdownDuration or 3
            })
        end
        
        if countdown <= 0 then
            timer.Remove(self.Timer)
            self.Timer = nil
            if AA.RunState and AA.RunState.Transition then
                AA.RunState:Transition(AA.Types.RunState.RUNNING)
            end
        end
    end)
end

function AA.RunState:OnRunning()
    self.StartTime = CurTime()
    
    -- Notify systems that run has begun
    if AA.Events and AA.Events.Emit then
        AA.Events.Emit(AA.Events.Names.RUN_BEGIN)
    end
    
    -- Start the game director
    if AA.GameDirector and AA.GameDirector.StartRun then
        AA.GameDirector:StartRun()
    end
end

function AA.RunState:OnPlayerDead()
    local runTime = CurTime() - self.StartTime
    
    -- Capture final score data
    local finalScore = 0
    local highScore = 0
    local kills = 0
    local eliteKills = 0
    local highestCombo = 0
    
    if AA.ScoreManager then
        finalScore = AA.ScoreManager:GetCurrentScore()
        highScore = AA.ScoreManager:GetHighScore()
        kills = AA.ScoreManager:GetKills()
        eliteKills = AA.ScoreManager:GetEliteKills()
        highestCombo = AA.ScoreManager:GetHighestCombo()
    end
    
    -- Stop spawning
    if AA.GameDirector and AA.GameDirector.StopRun then
        AA.GameDirector:StopRun()
    end
    
    -- Clear enemies after delay
    timer.Simple(2.0, function()
        if AA.EnemyManager then
            AA.EnemyManager:CleanupAll()
        end
    end)
    
    -- Check for high score
    local beaten = finalScore > highScore
    if beaten and AA.ScoreManager then
        AA.ScoreManager:SetHighScore(finalScore)
        if AA.Persistence and AA.Persistence.SaveHighScores then
            AA.Persistence:SaveHighScores()
        end
        if AA.Events and AA.Events.Emit then
            AA.Events.Emit(AA.Events.Names.HIGHSCORE_BEATEN, finalScore, highScore)
        end
    end
    
    -- Prepare end screen data
    self.EndData = {
        finalScore = finalScore,
        highScore = highScore,
        beaten = beaten,
        runTime = runTime,
        kills = kills,
        eliteKills = eliteKills,
        highestCombo = highestCombo,
        map = game.GetMap(),
    }
    
    -- Transition to summary after delay
    timer.Simple(AA.Config.Game.RestartDelay, function()
        self:Transition(AA.Types.RunState.RUN_SUMMARY, self.EndData)
    end)
end

function AA.RunState:OnRunSummary()
    -- Send end screen to all players
    if AA.Net and AA.Net.SendEndScreen then
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                AA.Net.SendEndScreen(ply, self.EndData)
            end
        end
    end
end

function AA.RunState:OnRestarting()
    -- Cleanup and prepare for new run
    if AA.EnemyManager then
        AA.EnemyManager:CleanupAll()
    end
    
    -- Reset player state
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:Spawn()
        end
    end
    
    -- Go back to preparing map
    timer.Simple(0.5, function()
        self:Transition(AA.Types.RunState.PREPARING_MAP)
    end)
end

-- Public API
function AA.RunState:RequestStart(ply)
    if self.Current ~= AA.Types.RunState.IDLE and 
       self.Current ~= AA.Types.RunState.RUN_SUMMARY then
        return false
    end
    
    self:Transition(AA.Types.RunState.PREPARING_MAP)
    return true
end

function AA.RunState:RequestRestart(ply)
    if self.Current ~= AA.Types.RunState.RUN_SUMMARY then
        return false
    end
    
    self:Transition(AA.Types.RunState.RESTARTING)
    return true
end

function AA.RunState:OnPlayerDeath(ply)
    if self.Current == AA.Types.RunState.RUNNING then
        self:Transition(AA.Types.RunState.PLAYER_DEAD)
    end
end

function AA.RunState:GetCurrentState()
    return self.Current
end

function AA.RunState:IsRunning()
    return self.Current == AA.Types.RunState.RUNNING
end

function AA.RunState:GetRunTime()
    if not self:IsRunning() then return 0 end
    return CurTime() - self.StartTime
end

-- Player death hook
hook.Add("PlayerDeath", "AA_PlayerDeath", function(victim, inflictor, attacker)
    if AA and AA.RunState and AA.RunState.OnPlayerDeath then
        AA.RunState:OnPlayerDeath(victim)
    end
end)

-- Initialize
hook.Add("Initialize", "AA_RunState_Init", function()
    if AA and AA.RunState and AA.Types then
        AA.RunState.Current = AA.Types.RunState.IDLE
    end
end)
