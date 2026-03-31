--[[
    Arcade Anomaly: Run State (Client)
    
    Client-side run state tracking.
--]]

AA.RunStateClient = AA.RunStateClient or {}
AA.RunStateClient.CurrentState = AA.Types.RunState.IDLE

-- Receive run state updates from server
hook.Add("AA_RunStateChanged", "AA_RunState_ClientTracker", function(state, data)
    AA.RunStateClient.CurrentState = state
end)

function AA.RunStateClient:GetCurrentState()
    return self.CurrentState
end

function AA.RunStateClient:IsRunning()
    return self.CurrentState == AA.Types.RunState.RUNNING
end

function AA.RunStateClient:IsIdle()
    return self.CurrentState == AA.Types.RunState.IDLE
end
