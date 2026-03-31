-- addons/arcade_spawner/lua/autorun/arcade_spawner_init.lua
-- BULLETPROOF Auto-Initialization System v4.1

ArcadeSpawner = ArcadeSpawner or {}
ArcadeSpawner.Version = "4.1.0"
ArcadeSpawner.Initialized = false

print("==============================================")
print("[Arcade Spawner] BULLETPROOF Enhanced System v" .. ArcadeSpawner.Version)

-- ═══════════════════════════════════════════════════════════════
-- BULLETPROOF INITIALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function SafeInclude(path)
    local success, err = pcall(include, path)
    if not success then
        print("[Arcade Spawner] ERROR loading " .. path .. ": " .. tostring(err))
        return false
    end
    print("[Arcade Spawner] ✅ Loaded: " .. path)
    return true
end

local function ForceInitialize()
    if ArcadeSpawner.Initialized then return end
    
    print("[Arcade Spawner] 🚀 Force initializing BULLETPROOF system...")
    
    if SERVER then
        -- Server-side core systems with dependency order
        SafeInclude("arcade_spawner/core/config.lua")
        SafeInclude("arcade_spawner/core/enemy_manager.lua")
        SafeInclude("arcade_spawner/core/ui_manager.lua")
        SafeInclude("arcade_spawner/core/spawner.lua")
        
        -- Send client files
        AddCSLuaFile("arcade_spawner/client/hud.lua")
        AddCSLuaFile("arcade_spawner/client/health_bars.lua")
        AddCSLuaFile("arcade_spawner/client/effects.lua")
        AddCSLuaFile("arcade_spawner/client/damage_numbers.lua")
        AddCSLuaFile("arcade_spawner/core/config.lua")
        
        -- Create console variables with enhanced defaults
        CreateConVar("arcade_max_enemies", "50", FCVAR_ARCHIVE, "Maximum enemies at once")
        CreateConVar("arcade_min_spawn_distance", "400", FCVAR_ARCHIVE, "Minimum spawn distance from players")
        CreateConVar("arcade_debug_mode", "0", FCVAR_ARCHIVE, "Enable debug mode")
        CreateConVar("arcade_difficulty_scale", "1.6", FCVAR_ARCHIVE, "Global difficulty scaling")
        CreateConVar("arcade_ai_accuracy", "1.0", FCVAR_ARCHIVE, "AI accuracy multiplier")
        CreateConVar("arcade_spawn_rate", "0.8", FCVAR_ARCHIVE, "Enemy spawn interval")
        CreateConVar("arcade_workshop_validation", "1", FCVAR_ARCHIVE, "Enable workshop model validation")
        CreateConVar("arcade_auto_start", "0", FCVAR_ARCHIVE, "Automatically start session on map load")
        CreateConVar("arcade_auto_hud", "1", FCVAR_ARCHIVE, "Auto-initialize HUD on map load")
        CreateConVar("arcade_creepy_fx", "1", FCVAR_ARCHIVE, "Enable creepy ambience effects")
        SafeInclude("arcade_spawner/server/loot_system.lua")
        
        print("[Arcade Spawner] 🎮 Server systems initialized!")
    end
    
    if CLIENT then
        -- Client-side systems with auto-initialization
        SafeInclude("arcade_spawner/core/config.lua")
        SafeInclude("arcade_spawner/client/hud.lua")
        SafeInclude("arcade_spawner/client/health_bars.lua")
        SafeInclude("arcade_spawner/client/effects.lua")
        SafeInclude("arcade_spawner/client/damage_numbers.lua")

        CreateClientConVar("arcade_creepy_fx", "1", true, false, "Enable creepy ambience effects")
        
        print("[Arcade Spawner] 🎯 Client systems initialized!")
    end
    
    ArcadeSpawner.Initialized = true
    print("[Arcade Spawner] ✅ BULLETPROOF system initialized successfully!")
    print("==============================================")

    if SERVER and GetConVar("arcade_auto_start"):GetBool() and ArcadeSpawner.StartSession then
        timer.Simple(1, function()
            if not ArcadeSpawner.Spawner.Active then
                ArcadeSpawner.StartSession()
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MULTI-TRIGGER INITIALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

-- Primary initialization
hook.Add("Initialize", "ArcadeSpawner_BulletproofInit", ForceInitialize)

-- Backup initialization triggers
hook.Add("InitPostEntity", "ArcadeSpawner_PostInit", function()
    timer.Simple(1, ForceInitialize)
end)

-- Map change initialization
hook.Add("PostGamemodeLoaded", "ArcadeSpawner_GamemodeInit", function()
    timer.Simple(2, ForceInitialize)
end)

-- Player ready initialization (Client)
if CLIENT then
    hook.Add("OnEntityCreated", "ArcadeSpawner_ClientReady", function(ent)
        if not ArcadeSpawner.Initialized and IsValid(LocalPlayer()) then
            timer.Simple(0.5, ForceInitialize)
        end
    end)
    
    -- Network ready check
    timer.Create("ArcadeSpawner_NetworkReady", 3, 0, function()
        if not ArcadeSpawner.Initialized and LocalPlayer and IsValid(LocalPlayer()) then
            ForceInitialize()
            timer.Remove("ArcadeSpawner_NetworkReady")
        elseif ArcadeSpawner.Initialized then
            timer.Remove("ArcadeSpawner_NetworkReady")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ENHANCED CONSOLE COMMANDS
-- ═══════════════════════════════════════════════════════════════
if SERVER then
    concommand.Add("arcade_start", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("❌ Admin access required!")
            return
        end
        
        if not ArcadeSpawner.Initialized then
            ForceInitialize()
        end
        
        if ArcadeSpawner.StartSession then
            local success = ArcadeSpawner.StartSession()
            local msg = success and "✅ Session started!" or "❌ Failed to start session!"
            print("[Arcade Spawner] " .. msg)
            if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] " .. msg) end
        else
            local msg = "❌ Spawner system not loaded!"
            print("[Arcade Spawner] " .. msg)
            if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] " .. msg) end
        end
    end)
    
    concommand.Add("arcade_stop", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("❌ Admin access required!")
            return
        end
        
        if ArcadeSpawner.StopSession then
            ArcadeSpawner.StopSession()
            print("[Arcade Spawner] ✅ Session stopped!")
            if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] ✅ Session stopped!") end
        end
    end)
    
    concommand.Add("arcade_status", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        
        local spawner = ArcadeSpawner.Spawner
        local manager = ArcadeSpawner.EnemyManager
        local status = spawner and spawner.Active and "🟢 ACTIVE" or "🔴 INACTIVE"
        local enemies = spawner and #(spawner.ActiveEnemies or {}) or 0
        local wave = spawner and spawner.CurrentWave or 0
        local kills = spawner and spawner.EnemiesKilled or 0
        local spawnPoints = spawner and #(spawner.SpawnPoints or {}) or 0
        local validatedModels = manager and #(manager.ValidatedModels or {}) or 0
        local workshopModels = manager and #(manager.WorkshopModels or {}) or 0
        
        local report = {
            "==============================================",
            "[Arcade Spawner] 📊 ENHANCED STATUS REPORT v4.1",
            "System Status: " .. status,
            "Initialization: " .. (ArcadeSpawner.Initialized and "✅ Complete" or "❌ Pending"),
            "Active Enemies: " .. enemies,
            "Current Wave: " .. wave,
            "Total Kills: " .. kills,
            "Spawn Points: " .. spawnPoints,
            "Validated Models: " .. validatedModels,
            "Workshop Models: " .. workshopModels,
            "=============================================="
        }
        
        for _, line in ipairs(report) do
            print(line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end)
    
    concommand.Add("arcade_reload", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        
        if ArcadeSpawner.StopSession then
            ArcadeSpawner.StopSession()
        end
        
        ArcadeSpawner.Initialized = false
        timer.Simple(1, ForceInitialize)
        
        print("[Arcade Spawner] 🔄 System reloaded!")
        if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] 🔄 System reloaded!") end
    end)
    
    concommand.Add("arcade_validate_workshop", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        if ArcadeSpawner.EnemyManager and ArcadeSpawner.EnemyManager.AsyncScanWorkshopModels then
            ArcadeSpawner.EnemyManager.AsyncScanWorkshopModels()
            local msg = "🔍 Workshop scan started"
            print("[Arcade Spawner] " .. msg)
            if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] " .. msg) end
        end
    end)

    concommand.Add("arcade_rescan_models", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        if ArcadeSpawner.EnemyManager and ArcadeSpawner.EnemyManager.AsyncScanWorkshopModels then
            ArcadeSpawner.EnemyManager.AsyncScanWorkshopModels()
            local msg = "🔍 Workshop rescan started"
            print("[Arcade Spawner] " .. msg)
            if IsValid(ply) then ply:ChatPrint("[Arcade Spawner] " .. msg) end
        end
    end)
    
    concommand.Add("arcade_test_spawn", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        
        if not IsValid(ply) then return end
        
        if ArcadeSpawner.EnemyManager and ArcadeSpawner.EnemyManager.CreateEnemy then
            local pos = ply:GetPos() + ply:GetForward() * 200
            local enemy = ArcadeSpawner.EnemyManager.CreateEnemy(pos, 1, args[1])
            
            if IsValid(enemy) then
                local msg = "✅ Test enemy spawned: " .. (enemy.RarityType or "Common")
                print("[Arcade Spawner] " .. msg)
                ply:ChatPrint("[Arcade Spawner] " .. msg)
            else
                local msg = "❌ Failed to spawn test enemy"
                print("[Arcade Spawner] " .. msg)
                ply:ChatPrint("[Arcade Spawner] " .. msg)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- CLIENT CONSOLE COMMANDS
-- ═══════════════════════════════════════════════════════════════
if CLIENT then
    concommand.Add("arcade_hud_reload", function()
        if ArcadeSpawner.HUD then
            print("[Arcade Spawner] 🎯 Reloading HUD...")
            -- Force HUD reinitialization
            timer.Simple(0.1, function()
                if ForceInitialize then
                    ForceInitialize()
                end
            end)
        end
    end)
    
    concommand.Add("arcade_effects_test", function()
        if IsValid(LocalPlayer()) then
            local pos = LocalPlayer():GetPos() + Vector(0, 0, 50)
            
            -- Test spawn effect
            local effectData = EffectData()
            effectData:SetOrigin(pos)
            effectData:SetMagnitude(math.random(1, 6))
            util.Effect("arcade_spawn_effect", effectData)
            
            print("[Arcade Spawner] 🎆 Test effect triggered!")
        end
    end)
end

print("[Arcade Spawner] 🚀 BULLETPROOF initialization script v4.1 loaded!")