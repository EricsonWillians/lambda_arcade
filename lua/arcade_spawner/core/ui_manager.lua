-- UI and player progression management

ArcadeSpawner.UIManager = ArcadeSpawner.UIManager or {}
local UIManager = ArcadeSpawner.UIManager

-- Player data storage
UIManager.PlayerData = {}

-- Network strings
util.AddNetworkString("ArcadeSpawner_PlayerXP")
util.AddNetworkString("ArcadeSpawner_LevelUp")
util.AddNetworkString("ArcadeSpawner_DamageNumber")
util.AddNetworkString("AA_DamagePopup")  -- Arcade style damage numbers

-- Initialize player data
function UIManager.InitializePlayer(ply)
    if not IsValid(ply) then return end
    
    UIManager.PlayerData[ply:SteamID()] = {
        xp = 0,
        level = 1,
        kills = 0,
        totalDamage = 0
    }
end

-- Give XP to player
function UIManager.GiveXP(ply, amount)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if not UIManager.PlayerData[steamID] then
        UIManager.InitializePlayer(ply)
    end
    
    local data = UIManager.PlayerData[steamID]
    data.xp = data.xp + amount
    
    -- Check for level up
    local requiredXP = UIManager.GetRequiredXP(data.level)
    if data.xp >= requiredXP then
        data.level = data.level + 1
        data.xp = data.xp - requiredXP
        
        -- Notify level up
        net.Start("ArcadeSpawner_LevelUp")
        net.WriteInt(data.level, 16)
        net.Send(ply)
        
        -- Give level up benefits
        UIManager.ApplyLevelUpBenefits(ply, data.level)
    end
    
    -- Send XP update
    net.Start("ArcadeSpawner_PlayerXP")
    net.WriteInt(data.xp, 32)
    net.WriteInt(data.level, 16)
    net.WriteInt(UIManager.GetRequiredXP(data.level), 32)
    net.Send(ply)
end

-- Calculate required XP for next level
function UIManager.GetRequiredXP(level)
    return math.floor(100 * math.pow(1.2, level - 1))
end

-- Apply level up benefits
function UIManager.ApplyLevelUpBenefits(ply, level)
    if not IsValid(ply) then return end
    
    -- Increase max health
    local newHealth = 100 + (level - 1) * 5
    ply:SetMaxHealth(newHealth)
    ply:SetHealth(newHealth)
    
    -- Increase max armor
    local newArmor = (level - 1) * 2
    ply:SetArmor(math.min(100, newArmor))
    
    -- Apply speed boost every level (cumulative bonus)
    local speedMultiplier = 1 + (level * 0.04)
    ply:SetWalkSpeed(250 * speedMultiplier)
    ply:SetRunSpeed(450 * speedMultiplier)
    
    -- Cap max speed to prevent insanity
    if ply:GetRunSpeed() > 700 then
        ply:SetRunSpeed(700)
        ply:SetWalkSpeed(400)
    end
end

-- Show damage number (arcade style)
function UIManager.ShowDamageNumber(pos, damage, isKill)
    -- Send arcade-style damage popup
    net.Start("AA_DamagePopup")
    net.WriteVector(pos)
    net.WriteUInt(damage, 16)
    
    local flags = 0
    if isKill then flags = bit.bor(flags, 1) end
    if damage > 50 then flags = bit.bor(flags, 2) end  -- Critical hit
    net.WriteUInt(flags, 8)
    
    net.Broadcast()
end

-- Get player data
function UIManager.GetPlayerData(ply)
    if not IsValid(ply) then return nil end
    
    local steamID = ply:SteamID()
    if not UIManager.PlayerData[steamID] then
        UIManager.InitializePlayer(ply)
    end
    
    return UIManager.PlayerData[steamID]
end

-- Hook into player events
hook.Add("PlayerInitialSpawn", "ArcadeSpawner_InitPlayer", function(ply)
    UIManager.InitializePlayer(ply)
end)

-- Set improved base speeds on player spawn
hook.Add("PlayerSpawn", "ArcadeSpawner_SetSpeed", function(ply)
    if not IsValid(ply) then return end
    
    -- Only apply to real players (not bots)
    if not ply:IsPlayer() then return end
    
    -- Get player level for speed calculation
    local data = UIManager.GetPlayerData(ply)
    local level = data and data.level or 1
    
    -- Apply level-based speed boost
    local speedMultiplier = 1 + (level * 0.04)
    ply:SetWalkSpeed(250 * speedMultiplier)
    ply:SetRunSpeed(450 * speedMultiplier)
    
    -- Cap max speed
    if ply:GetRunSpeed() > 700 then
        ply:SetRunSpeed(700)
        ply:SetWalkSpeed(400)
    end
    
    -- Give default HL2 weapons if player has none (fix for hidden/missing weapons)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        -- Check if player has any weapons
        local hasWeapons = false
        for _, weapon in ipairs(ply:GetWeapons()) do
            if IsValid(weapon) then
                hasWeapons = true
                break
            end
        end
        
        -- If no weapons, give default loadout
        if not hasWeapons then
            ply:Give("weapon_crowbar")
            ply:Give("weapon_pistol")
            ply:GiveAmmo(54, "Pistol", true)
        end
    end)
end)

hook.Add("PlayerDisconnected", "ArcadeSpawner_CleanupPlayer", function(ply)
    -- Could save data to file here for persistence
    -- For now, just clean up
    local steamID = ply:SteamID()
    if UIManager.PlayerData[steamID] then
        UIManager.PlayerData[steamID] = nil
    end
end)

-- Track damage dealt to enemies for accurate kill detection
UIManager.DamageTracker = {}

-- Hook into damage events for damage numbers
hook.Add("EntityTakeDamage", "ArcadeSpawner_DamageNumbers", function(target, dmginfo)
    -- Check if target is an Arcade Anomaly enemy (has Archetype property)
    if IsValid(target) and target.Archetype then
        local damage = math.floor(dmginfo:GetDamage())
        local currentHealth = target:Health()
        local maxHealth = target:GetMaxHealth()
        
        -- Track damage dealt to this enemy
        local entIndex = target:EntIndex()
        UIManager.DamageTracker[entIndex] = (UIManager.DamageTracker[entIndex] or 0) + damage
        
        -- Only show KILL if health is actually low enough AND it's a significant hit
        -- For high-HP enemies (brutes, elites), we need to be more careful
        local predictedHealth = currentHealth - damage
        local isKill = predictedHealth <= 0
        
        -- For enemies with >100 HP, only show KILL on the final blow
        -- This prevents false KILL messages on tanky enemies
        if maxHealth > 100 and predictedHealth > -50 then
            -- Don't show KILL unless they're definitely dead
            isKill = predictedHealth <= 0 and damage >= currentHealth * 0.5
        end
        
        UIManager.ShowDamageNumber(target:GetPos() + Vector(0, 0, 50), damage, isKill)
        
        -- Track damage for player
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() then
            local data = UIManager.GetPlayerData(attacker)
            if data then
                data.totalDamage = data.totalDamage + damage
                if isKill then
                    data.kills = data.kills + 1
                end
            end
        end
    end
end)

-- Clean up damage tracker when enemies are removed
hook.Add("EntityRemoved", "ArcadeSpawner_CleanupDamageTracker", function(ent)
    if ent and ent.Archetype then
        UIManager.DamageTracker[ent:EntIndex()] = nil
    end
end)