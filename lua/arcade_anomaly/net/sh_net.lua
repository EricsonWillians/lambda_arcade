--[[
    Arcade Anomaly: Networking
    
    Network message definitions and helpers.
--]]

AA.Net = AA.Net or {}

-- Network message identifiers
AA.Net.Messages = {
    -- Server to Client
    RUN_STATE_UPDATE = "AA_RunState",
    SCORE_UPDATE = "AA_ScoreUpdate",
    COMBO_UPDATE = "AA_ComboUpdate",
    ENEMY_SPAWN = "AA_EnemySpawn",
    ENEMY_DEATH = "AA_EnemyDeath",
    ELITE_WARNING = "AA_EliteWarning",
    FX_DISPATCH = "AA_FXDispatch",
    HUD_MESSAGE = "AA_HUDMessage",
    END_SCREEN = "AA_EndScreen",
    
    -- Loading & Progress
    LOADING_START = "AA_Loading_Start",
    LOADING_UPDATE = "AA_Loading_Update",
    LOADING_COMPLETE = "AA_Loading_Complete",
    
    -- Notifications
    TOAST_SHOW = "AA_Toast_Show",
    
    -- Client to Server
    START_RUN = "AA_StartRun",
    RESTART_RUN = "AA_RestartRun",
    REQUEST_SETTINGS = "AA_RequestSettings",
    CANCEL_LOADING = "AA_CancelLoading",
}

-- Initialize network strings
if SERVER then
    for _, msgName in pairs(AA.Net.Messages) do
        util.AddNetworkString(msgName)
    end
end

-- Helper: Send run state to all clients
function AA.Net.BroadcastRunState(state, data)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.RUN_STATE_UPDATE)
    net.WriteUInt(state, 4)
    net.WriteTable(data or {})
    net.Broadcast()
end

-- Helper: Send score update
function AA.Net.BroadcastScore(score, highScore)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.SCORE_UPDATE)
    net.WriteUInt(score, 32)
    net.WriteUInt(highScore, 32)
    net.Broadcast()
end

-- Helper: Send combo update
function AA.Net.BroadcastCombo(combo, multiplier, timeRemaining)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.COMBO_UPDATE)
    net.WriteUInt(combo, 16)
    net.WriteFloat(multiplier)
    net.WriteFloat(timeRemaining)
    net.Broadcast()
end

-- Helper: Send enemy spawn notification
function AA.Net.BroadcastEnemySpawn(entIndex, archetype, position, isElite)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.ENEMY_SPAWN)
    net.WriteUInt(entIndex, 16)
    net.WriteUInt(archetype, 4)
    net.WriteVector(position)
    net.WriteBool(isElite)
    net.Broadcast()
end

-- Helper: Send enemy death notification
function AA.Net.BroadcastEnemyDeath(entIndex, position, scoreValue, killedBy)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.ENEMY_DEATH)
    net.WriteUInt(entIndex, 16)
    net.WriteVector(position)
    net.WriteUInt(scoreValue, 16)
    if IsValid(killedBy) then
        net.WriteEntity(killedBy)
    else
        net.WriteEntity(NULL)
    end
    net.Broadcast()
end

-- Helper: Send elite warning
function AA.Net.BroadcastEliteWarning(position)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.ELITE_WARNING)
    net.WriteVector(position)
    net.Broadcast()
end

-- Helper: Dispatch FX
function AA.Net.DispatchFX(fxType, position, data)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.FX_DISPATCH)
    net.WriteUInt(fxType, 8)
    net.WriteVector(position)
    net.WriteTable(data or {})
    net.Broadcast()
end

-- Helper: Show end screen
function AA.Net.SendEndScreen(ply, runData)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.END_SCREEN)
    net.WriteTable(runData)
    net.Send(ply)
end

-- Helper: Start loading screen
function AA.Net.StartLoading(ply, title, message, cancellable)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.LOADING_START)
    net.WriteString(title or "LOADING")
    net.WriteString(message or "")
    net.WriteBool(cancellable or false)
    
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Helper: Update loading progress
function AA.Net.UpdateLoading(ply, progress, message, stage)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.LOADING_UPDATE)
    net.WriteFloat(progress or 0)
    net.WriteString(message or "")
    net.WriteString(stage or "")
    
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Helper: Complete loading
function AA.Net.CompleteLoading(ply)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.LOADING_COMPLETE)
    
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Helper: Show toast notification
function AA.Net.ShowToast(ply, message, toastType, duration)
    if not SERVER then return end
    
    net.Start(AA.Net.Messages.TOAST_SHOW)
    net.WriteString(message)
    net.WriteString(toastType or "INFO")
    net.WriteFloat(duration or 4)
    
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Client message handlers
if CLIENT then
    net.Receive(AA.Net.Messages.RUN_STATE_UPDATE, function()
        local state = net.ReadUInt(4)
        local data = net.ReadTable()
        
        hook.Run("AA_RunStateChanged", state, data)
    end)
    
    net.Receive(AA.Net.Messages.SCORE_UPDATE, function()
        local score = net.ReadUInt(32)
        local highScore = net.ReadUInt(32)
        
        hook.Run("AA_ScoreUpdated", score, highScore)
    end)
    
    net.Receive(AA.Net.Messages.COMBO_UPDATE, function()
        local combo = net.ReadUInt(16)
        local multiplier = net.ReadFloat()
        local timeRemaining = net.ReadFloat()
        
        hook.Run("AA_ComboUpdated", combo, multiplier, timeRemaining)
    end)
    
    net.Receive(AA.Net.Messages.ENEMY_SPAWN, function()
        local entIndex = net.ReadUInt(16)
        local archetype = net.ReadUInt(4)
        local position = net.ReadVector()
        local isElite = net.ReadBool()
        
        hook.Run("AA_EnemySpawned", entIndex, archetype, position, isElite)
    end)
    
    net.Receive(AA.Net.Messages.ENEMY_DEATH, function()
        local entIndex = net.ReadUInt(16)
        local position = net.ReadVector()
        local scoreValue = net.ReadUInt(16)
        local killedBy = net.ReadEntity()
        
        hook.Run("AA_EnemyDied", entIndex, position, scoreValue, killedBy)
    end)
    
    net.Receive(AA.Net.Messages.ELITE_WARNING, function()
        local position = net.ReadVector()
        hook.Run("AA_EliteWarning", position)
    end)
    
    net.Receive(AA.Net.Messages.FX_DISPATCH, function()
        local fxType = net.ReadUInt(8)
        local position = net.ReadVector()
        local data = net.ReadTable()
        
        hook.Run("AA_FXDispatch", fxType, position, data)
    end)
    
    net.Receive(AA.Net.Messages.END_SCREEN, function()
        local runData = net.ReadTable()
        hook.Run("AA_ShowEndScreen", runData)
    end)
    
    -- Client request functions
    function AA.Net.RequestStartRun()
        net.Start(AA.Net.Messages.START_RUN)
        net.SendToServer()
    end
    
    function AA.Net.RequestRestartRun()
        net.Start(AA.Net.Messages.RESTART_RUN)
        net.SendToServer()
    end
end

-- Server handlers
if SERVER then
    net.Receive(AA.Net.Messages.START_RUN, function(len, ply)
        print("[AA DEBUG] START_RUN network message received from " .. tostring(ply))
        if not IsValid(ply) then 
            print("[AA DEBUG] Player not valid")
            return 
        end
        if not AA or not AA.RunState or not AA.RunState.RequestStart then 
            print("[AA DEBUG] RunState not ready")
            return 
        end
        print("[AA DEBUG] Calling RequestStart...")
        AA.RunState:RequestStart(ply)
        print("[AA DEBUG] RequestStart returned")
    end)
    
    net.Receive(AA.Net.Messages.RESTART_RUN, function(len, ply)
        if not IsValid(ply) then return end
        if not AA or not AA.RunState or not AA.RunState.RequestRestart then return end
        AA.RunState:RequestRestart(ply)
    end)
end
