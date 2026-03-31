--[[
    Lambda Arcade
    Main Initialization File
    
    This file loads all server-side and shared modules.
    For clientside initialization, see aa_client_init.lua
--]]

-- Define global table early
AA = AA or {}
AA.Version = "0.1.0"
AA.Debug = false

-- Realm detection
local function IsServer() return SERVER end
local function IsClient() return CLIENT end

-- Module loader helper
function AA.Include(path, realm)
    realm = realm or "SHARED"
    
    if realm == "SERVER" and not SERVER then return end
    if realm == "CLIENT" and not CLIENT then return end
    
    local fullPath = "arcade_anomaly/" .. path .. ".lua"
    
    if SERVER and realm == "CLIENT" then
        AddCSLuaFile(fullPath)
    elseif SERVER and realm == "SHARED" then
        AddCSLuaFile(fullPath)
    end
    
    if (SERVER and (realm == "SERVER" or realm == "SHARED")) or
       (CLIENT and (realm == "CLIENT" or realm == "SHARED")) then
        include(fullPath)
        
        if AA.Debug then
            print("[AA] Loaded: " .. fullPath)
        end
    end
end

-- Load order matters
local loadOrder = {
    -- Config (Shared)
    {"config/sh_config", "SHARED"},
    {"config/sh_balance", "SHARED"},
    {"config/sh_enemy_tags", "SHARED"},
    
    -- Core Shared
    {"core/sh_types", "SHARED"},
    {"core/sh_util", "SHARED"},
    {"core/sh_events", "SHARED"},
    
    -- Networking (Shared)
    {"net/sh_net", "SHARED"},
    
    -- FX Definitions (Shared)
    {"fx/sh_fx_defs", "SHARED"},
    
    -- Core Server
    {"core/sv_run_state", "SERVER"},
    {"core/sv_score_manager", "SERVER"},
    {"core/sv_map_analyzer", "SERVER"},
    {"core/sv_game_director", "SERVER"},
    {"core/sv_spawn_manager", "SERVER"},
    {"core/sv_enemy_manager", "SERVER"},
    {"core/sv_persistence", "SERVER"},
    
    -- AI (Server only)
    {"ai/sv_navigation", "SERVER"},
    {"ai/sv_stuck_recovery", "SERVER"},
    {"ai/sv_ai_base", "SERVER"},
    {"ai/sv_ai_chaser", "SERVER"},
    {"ai/sv_ai_rusher", "SERVER"},
    {"ai/sv_ai_brute", "SERVER"},
    {"ai/sv_ai_shooter", "SERVER"},
    {"ai/sv_ai_exploder", "SERVER"},
    {"ai/sv_ai_elite", "SERVER"},
    
    -- Model Discovery & Registry (Server)
    -- IMPORTANT: Registry MUST load before Discovery
    {"models/sh_model_tags", "SHARED"},
    {"models/sv_model_registry", "SERVER"},
    {"models/sv_model_discovery", "SERVER"}, -- Military-grade discovery
    {"models/sv_model_validation", "SERVER"},
    {"models/sv_model_cache", "SERVER"},
    
    -- FX (Server)
    {"fx/sv_fx_dispatch", "SERVER"},
    {"fx/sv_gore", "SERVER"},
    
    -- Loot System
    {"core/sv_loot", "SERVER"},
    
    -- Core Client
    {"core/cl_run_state", "CLIENT"},
    {"core/cl_hud", "CLIENT"},
    {"core/cl_menus", "CLIENT"},

    
    -- FX (Client)
    {"fx/cl_fx", "CLIENT"},
    {"fx/cl_hit_feedback", "CLIENT"},
    {"fx/cl_arcade_damage", "CLIENT"},  -- Capcom/JRPG style damage numbers
    
    -- UI (Client)
    {"ui/cl_fonts", "CLIENT"},
    {"ui/cl_loading", "CLIENT"},
    {"ui/cl_toast", "CLIENT"},
    {"ui/cl_endscreen", "CLIENT"},

}

-- Execute load order
for _, entry in ipairs(loadOrder) do
    AA.Include(entry[1], entry[2])
end

-- Post-initialization
hook.Add("Initialize", "AA_Initialize", function()
    if SERVER then
        AA.Persistence:LoadAll()
        print("[Arcade Anomaly] Server initialized v" .. AA.Version)
    end
end)

-- Entities are auto-loaded from lua/entities/ by GMod
-- We keep copies in arcade_anomaly/entities/entities/ for organization

print("[Arcade Anomaly] Core modules loaded")
