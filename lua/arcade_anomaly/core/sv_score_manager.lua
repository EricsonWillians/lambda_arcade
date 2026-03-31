--[[
    Arcade Anomaly: Score Manager
    
    Handles scoring, combos, and run statistics.
--]]

AA.ScoreManager = AA.ScoreManager or {}

-- Current run data
AA.ScoreManager.CurrentRun = {
    score = 0,
    kills = 0,
    eliteKills = 0,
    combo = 0,
    comboTimer = 0,
    highestCombo = 0,
    multiplier = 1.0,
    startTime = 0,
}

-- Persistent data (loaded from file)
AA.ScoreManager.Persistent = {
    globalBest = 0,
    bestByMap = {},
}

function AA.ScoreManager:ResetRun()
    self.CurrentRun = {
        score = 0,
        kills = 0,
        eliteKills = 0,
        combo = 0,
        comboTimer = 0,
        highestCombo = 0,
        multiplier = 1.0,
        startTime = CurTime(),
    }
    
    -- Broadcast initial score
    self:BroadcastUpdate()
end

-- Score modification
function AA.ScoreManager:AddScore(amount, source)
    local multiplied = math.floor(amount * self.CurrentRun.multiplier)
    self.CurrentRun.score = math.min(
        self.CurrentRun.score + multiplied,
        AA.Types.Constants.MAX_SCORE
    )
    
    AA.Events.Emit(AA.Events.Names.SCORE_CHANGED, self.CurrentRun.score, multiplied, source)
    self:BroadcastUpdate()
    
    return multiplied
end

function AA.ScoreManager:OnEnemyKilled(enemy, killedBy)
    local archetype = enemy.Archetype
    local isElite = enemy.IsElite or false
    local balance = AA.Balance.Archetypes[AA.Types.ArchetypeNames[archetype]]
    
    if not balance then return end
    
    local baseScore = balance.ScoreValue
    
    -- Apply elite bonus
    if isElite then
        baseScore = baseScore + AA.Config.Score.EliteKillBonus
        self.CurrentRun.eliteKills = self.CurrentRun.eliteKills + 1
        AA.Events.Emit(AA.Events.Names.SCORE_EVENT, AA.Types.ScoreEvent.ELITE_KILLED, enemy)
    else
        AA.Events.Emit(AA.Events.Names.SCORE_EVENT, AA.Types.ScoreEvent.ENEMY_KILLED, enemy)
    end
    
    -- Increment kills
    self.CurrentRun.kills = self.CurrentRun.kills + 1
    
    -- Increase combo
    self:IncrementCombo(isElite)
    
    -- Add score
    local finalScore = self:AddScore(baseScore, "kill")
    
    return finalScore
end

-- Combo system
function AA.ScoreManager:IncrementCombo(isElite)
    local bonus = isElite and AA.Balance.Combo.EliteKillBonus or AA.Balance.Combo.KillBonus
    self.CurrentRun.combo = math.min(
        self.CurrentRun.combo + bonus,
        AA.Types.Constants.MAX_COMBO
    )
    
    -- Reset combo timer
    self.CurrentRun.comboTimer = AA.Balance.Combo.MaxTime
    
    -- Track highest combo
    if self.CurrentRun.combo > self.CurrentRun.highestCombo then
        self.CurrentRun.highestCombo = self.CurrentRun.combo
    end
    
    -- Update multiplier based on combo tiers
    self:UpdateMultiplier()
    
    AA.Events.Emit(AA.Events.Names.COMBO_CHANGED, self.CurrentRun.combo, self.CurrentRun.multiplier)
end

function AA.ScoreManager:UpdateMultiplier()
    local newMult = 1.0
    
    for tier, mult in pairs(AA.Balance.Combo.MultiplierTiers) do
        if self.CurrentRun.combo >= tier then
            newMult = mult
        end
    end
    
    self.CurrentRun.multiplier = newMult
end

function AA.ScoreManager:TickCombo(dt)
    if self.CurrentRun.combo <= 0 then return end
    
    self.CurrentRun.comboTimer = self.CurrentRun.comboTimer - dt
    
    if self.CurrentRun.comboTimer <= 0 then
        -- Combo expired
        self.CurrentRun.combo = 0
        self.CurrentRun.multiplier = 1.0
        self.CurrentRun.comboTimer = 0
        
        AA.Events.Emit(AA.Events.Names.COMBO_CHANGED, 0, 1.0)
        self:BroadcastUpdate()
    end
end

function AA.ScoreManager:GetComboTimeRemaining()
    return self.CurrentRun.comboTimer
end

-- Survival tick bonus
function AA.ScoreManager:OnSurvivalTick()
    self:AddScore(AA.Config.Score.SurvivalTick, "survival")
    AA.Events.Emit(AA.Events.Names.SCORE_EVENT, AA.Types.ScoreEvent.SURVIVAL_TICK)
end

-- Getters
function AA.ScoreManager:GetCurrentScore()
    return self.CurrentRun.score
end

function AA.ScoreManager:GetHighScore()
    local map = game.GetMap()
    local mapBest = self.Persistent.bestByMap[map] or 0
    return math.max(self.Persistent.globalBest, mapBest)
end

function AA.ScoreManager:SetHighScore(score)
    local map = game.GetMap()
    
    if score > self.Persistent.globalBest then
        self.Persistent.globalBest = score
    end
    
    if not self.Persistent.bestByMap[map] or score > self.Persistent.bestByMap[map] then
        self.Persistent.bestByMap[map] = score
    end
end

function AA.ScoreManager:GetKills()
    return self.CurrentRun.kills
end

function AA.ScoreManager:GetEliteKills()
    return self.CurrentRun.eliteKills
end

function AA.ScoreManager:GetCombo()
    return self.CurrentRun.combo
end

function AA.ScoreManager:GetHighestCombo()
    return self.CurrentRun.highestCombo
end

function AA.ScoreManager:GetMultiplier()
    return self.CurrentRun.multiplier
end

-- Broadcasting
function AA.ScoreManager:BroadcastUpdate()
    if not AA.Net then return end
    
    AA.Net.BroadcastScore(self.CurrentRun.score, self:GetHighScore())
    AA.Net.BroadcastCombo(
        self.CurrentRun.combo,
        self.CurrentRun.multiplier,
        self.CurrentRun.comboTimer
    )
end

-- Think hook for combo decay
hook.Add("Think", "AA_ScoreManager_Think", function()
    if not AA.RunState or not AA.RunState.IsRunning then return end
    if not AA.RunState:IsRunning() then return end
    
    AA.ScoreManager:TickCombo(FrameTime())
end)

-- Periodic survival score
timer.Create("AA_SurvivalTick", 1, 0, function()
    if AA and AA.RunState and AA.RunState.IsRunning then
        if AA.RunState:IsRunning() then
            AA.ScoreManager:OnSurvivalTick()
        end
    end
end)

-- Enemy death hook
hook.Add("AA_EnemyDied", "AA_Score_EnemyDeath", function(enemy, killer)
    if AA.ScoreManager and IsValid(enemy) then
        AA.ScoreManager:OnEnemyKilled(enemy, killer)
    end
end)
