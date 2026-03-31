--[[
    Arcade Anomaly: Event System
    
    Simple event bus for decoupled system communication.
--]]

AA.Events = AA.Events or {}
AA.Events.listeners = AA.Events.listeners or {}

-- Subscribe to an event
function AA.Events.Subscribe(eventName, callback)
    AA.Events.listeners[eventName] = AA.Events.listeners[eventName] or {}
    table.insert(AA.Events.listeners[eventName], callback)
    
    -- Return unsubscribe function
    return function()
        AA.Events.Unsubscribe(eventName, callback)
    end
end

-- Unsubscribe from an event
function AA.Events.Unsubscribe(eventName, callback)
    if not AA.Events.listeners[eventName] then return end
    
    for i, cb in ipairs(AA.Events.listeners[eventName]) do
        if cb == callback then
            table.remove(AA.Events.listeners[eventName], i)
            return
        end
    end
end

-- Emit an event
function AA.Events.Emit(eventName, ...)
    if not AA.Events.listeners[eventName] then return end
    
    for _, callback in ipairs(AA.Events.listeners[eventName]) do
        local success, err = pcall(callback, ...)
        if not success then
            print("[AA Events] Error in handler for " .. eventName .. ": " .. err)
        end
    end
end

-- Event names (for reference and autocomplete)
AA.Events.Names = {
    -- Run lifecycle
    RUN_START = "RunStart",
    RUN_COUNTDOWN = "RunCountdown",
    RUN_BEGIN = "RunBegin",
    RUN_END = "RunEnd",
    RUN_RESTART = "RunRestart",
    
    -- Enemy lifecycle
    ENEMY_SPAWN = "EnemySpawn",
    ENEMY_DEATH = "EnemyDeath",
    ENEMY_STUCK = "EnemyStuck",
    ENEMY_RECOVERED = "EnemyRecovered",
    
    -- Combat
    PLAYER_DAMAGE = "PlayerDamage",
    ENEMY_DAMAGE = "EnemyDamage",
    PLAYER_DEATH = "PlayerDeath",
    
    -- Score
    SCORE_CHANGED = "ScoreChanged",
    COMBO_CHANGED = "ComboChanged",
    HIGHSCORE_BEATEN = "HighscoreBeaten",
    
    -- Map
    MAP_ANALYSIS_START = "MapAnalysisStart",
    MAP_ANALYSIS_COMPLETE = "MapAnalysisComplete",
    ANCHOR_ADDED = "AnchorAdded",
    
    -- FX
    FX_DISPATCH = "FXDispatch",
    SOUND_PLAY = "SoundPlay",
}
