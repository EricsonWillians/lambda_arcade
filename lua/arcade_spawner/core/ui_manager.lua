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
end)

hook.Add("PlayerDisconnected", "ArcadeSpawner_CleanupPlayer", function(ply)
    -- Could save data to file here for persistence
    -- For now, just clean up
    local steamID = ply:SteamID()
    if UIManager.PlayerData[steamID] then
        UIManager.PlayerData[steamID] = nil
    end
end)

-- Hook into damage events for damage numbers
hook.Add("EntityTakeDamage", "ArcadeSpawner_DamageNumbers", function(target, dmginfo)
    if IsValid(target) and target.IsArcadeEnemy then
        local damage = math.floor(dmginfo:GetDamage())
        local isKill = (target:Health() - damage) <= 0
        
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