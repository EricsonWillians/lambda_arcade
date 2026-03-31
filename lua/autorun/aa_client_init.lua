--[[
    Lambda Arcade
    Client Initialization
    
    This file ensures clientside assets are loaded.
--]]

if SERVER then
    -- AddCSLuaFile() is handled by aa_init.lua
    return
end

-- Client-specific initialization
hook.Add("Initialize", "AA_ClientInit", function()
    print("[Arcade Anomaly] Client initialized")
end)
