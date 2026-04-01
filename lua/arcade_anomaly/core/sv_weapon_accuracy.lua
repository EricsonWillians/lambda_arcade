--[[
    SV_WEAPON_ACCURACY - Hitscan Accuracy Enhancement System
    
    Improves weapon accuracy by modifying bullet spread/cone on weapon pickup/equip.
    Provides consistent, satisfying hitscan performance across all vanilla HL2 weapons.
]]

AA = AA or {}
AA.WeaponAccuracy = AA.WeaponAccuracy or {}

-- Accuracy configuration
AA.WeaponAccuracy.Config = {
    -- Base accuracy multiplier (lower = more accurate)
    -- 0 = perfect accuracy, 1 = vanilla, >1 = less accurate
    baseAccuracyMult = 0.15,  -- 85% reduction in spread (very tight)
    
    -- Level-based accuracy improvement
    levelAccuracyBonus = 0.02, -- -2% spread per level (capped)
    maxAccuracyBonus = 0.10,   -- Max 50% additional reduction (0.15 - 0.10 = 0.05)
    
    -- Weapon-specific overrides (spread multipliers)
    weaponOverrides = {
        -- Pistols - very accurate
        ["weapon_pistol"] = 0.08,
        ["weapon_357"] = 0.05,
        
        -- SMGs - accurate bursts
        ["weapon_smg1"] = 0.12,
        
        -- Rifles - very accurate
        ["weapon_ar2"] = 0.06,
        ["weapon_crossbow"] = 0.0, -- Perfect accuracy
        
        -- Shotguns - tighter spread
        ["weapon_shotgun"] = 0.40,
        
        -- Explosives - no change needed
        ["weapon_rpg"] = 0.0,
        ["weapon_frag"] = 0.0,
        ["weapon_slam"] = 0.0,
        
        -- Melee - no change
        ["weapon_crowbar"] = 0.0,
        ["weapon_stunstick"] = 0.0,
    },
    
    -- Backup original values (for restore if needed)
    originalValues = {}
}

-- Cache for processed weapons
AA.WeaponAccuracy.ProcessedWeapons = {}

--[[
    Apply accuracy improvements to a weapon
]]
function AA.WeaponAccuracy.ImproveWeapon(weapon, playerLevel)
    if not IsValid(weapon) then return end
    
    local class = weapon:GetClass()
    local config = AA.WeaponAccuracy.Config
    
    -- Skip if already processed this session
    if AA.WeaponAccuracy.ProcessedWeapons[weapon] then return end
    AA.WeaponAccuracy.ProcessedWeapons[weapon] = true
    
    -- Get base spread multiplier
    local spreadMult = config.weaponOverrides[class] or config.baseAccuracyMult
    
    -- Apply level-based bonus (more levels = more accurate)
    if playerLevel and playerLevel > 1 then
        local levelBonus = math.min(playerLevel * config.levelAccuracyBonus, config.maxAccuracyBonus)
        spreadMult = math.max(0.02, spreadMult - levelBonus) -- Minimum 0.02 spread
    end
    
    -- Store original values for backup
    config.originalValues[class] = {
        cone = weapon.Primary and weapon.Primary.Cone,
        spread = weapon.Primary and weapon.Primary.Spread,
    }
    
    -- Apply accuracy improvements
    if weapon.Primary then
        -- Handle Cone (standard HL2 weapons)
        if weapon.Primary.Cone ~= nil then
            weapon.Primary.Cone = weapon.Primary.Cone * spreadMult
        end
        
        -- Handle Spread (some custom/weapons use this)
        if weapon.Primary.Spread ~= nil then
            weapon.Primary.Spread = weapon.Primary.Spread * spreadMult
        end
        
        -- Handle numbered cones (cone ironsights, hipfire, etc.)
        for i = 0, 5 do
            local coneName = "Cone" .. tostring(i)
            if weapon.Primary[coneName] ~= nil then
                weapon.Primary[coneName] = weapon.Primary[coneName] * spreadMult
            end
        end
    end
    
    -- Special handling for specific weapon types
    if class == "weapon_shotgun" then
        -- Reduce pellet spread for shotgun
        AA.WeaponAccuracy.FixShotgunSpread(weapon, spreadMult)
    end
    
    -- Mark weapon as arcade-enhanced
    weapon.ArcadeAccuracyEnhanced = true
    weapon.ArcadeAccuracyMult = spreadMult
    
    -- Notify the owning player
    if IsValid(weapon:GetOwner()) and weapon:GetOwner():IsPlayer() then
        AA.WeaponAccuracy.NotifyClient(weapon:GetOwner(), class, spreadMult)
    end
    
    -- Debug
    if AA.Debug then
        print(string.format("[AA WeaponAccuracy] %s accuracy improved (mult: %.2f)", class, spreadMult))
    end
end

--[[
    Special handling for shotgun pellet spread
]]
function AA.WeaponAccuracy.FixShotgunSpread(weapon, mult)
    -- Hook into primary fire to modify bullet spread
    if not weapon.ArcadeShotgunHooked then
        weapon.ArcadeShotgunHooked = true
        
        -- Store original primary attack
        local oldPrimary = weapon.PrimaryAttack
        weapon.PrimaryAttack = function(self)
            -- Call original
            if oldPrimary then
                oldPrimary(self)
            end
            
            -- Modify the bullet table if it exists
            if self.Primary and self.Primary.NumShots then
                -- Ensure consistent pellet count
                self.Primary.NumShots = 7 -- HL2 default
            end
        end
    end
end

--[[
    Get player level for accuracy bonus
]]
function AA.WeaponAccuracy.GetPlayerLevel(ply)
    if not IsValid(ply) then return 1 end
    
    -- Try to get level from UIManager
    if ArcadeSpawner and ArcadeSpawner.UIManager then
        local data = ArcadeSpawner.UIManager.GetPlayerData(ply)
        if data then
            return data.level or 1
        end
    end
    
    return 1
end

--[[
    Process all weapons a player is carrying
]]
function AA.WeaponAccuracy.ProcessPlayerWeapons(ply)
    if not IsValid(ply) then return end
    
    local level = AA.WeaponAccuracy.GetPlayerLevel(ply)
    
    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsValid(weapon) then
            AA.WeaponAccuracy.ImproveWeapon(weapon, level)
        end
    end
end

--[[
    Hook: When player picks up a weapon
]]
hook.Add("WeaponEquip", "AA_WeaponAccuracy_Equip", function(weapon, ply)
    if not IsValid(weapon) or not IsValid(ply) then return end
    
    -- Small delay to ensure weapon is fully initialized
    timer.Simple(0.1, function()
        if IsValid(weapon) and IsValid(ply) then
            local level = AA.WeaponAccuracy.GetPlayerLevel(ply)
            AA.WeaponAccuracy.ImproveWeapon(weapon, level)
        end
    end)
end)

--[[
    Hook: When player spawns - process existing weapons
]]
hook.Add("PlayerSpawn", "AA_WeaponAccuracy_Spawn", function(ply)
    -- Process weapons after a short delay (to allow loadout to be given)
    timer.Simple(0.5, function()
        AA.WeaponAccuracy.ProcessPlayerWeapons(ply)
    end)
end)

--[[
    Hook: When player switches weapon - ensure accuracy is applied
]]
hook.Add("PlayerSwitchWeapon", "AA_WeaponAccuracy_Switch", function(ply, oldWeapon, newWeapon)
    if IsValid(newWeapon) and not newWeapon.ArcadeAccuracyEnhanced then
        local level = AA.WeaponAccuracy.GetPlayerLevel(ply)
        AA.WeaponAccuracy.ImproveWeapon(newWeapon, level)
    end
end)

--[[
    Console command: Check current weapon accuracy stats
]]
concommand.Add("aa_weapon_accuracy", function(ply)
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then
        print("No active weapon")
        return
    end
    
    print("=== Weapon Accuracy Info ===")
    print("Class: " .. weapon:GetClass())
    
    if weapon.Primary then
        if weapon.Primary.Cone ~= nil then
            print("Cone: " .. tostring(weapon.Primary.Cone))
        end
        if weapon.Primary.Spread ~= nil then
            print("Spread: " .. tostring(weapon.Primary.Spread))
        end
        print("Enhanced: " .. tostring(weapon.ArcadeAccuracyEnhanced or false))
        if weapon.ArcadeAccuracyMult then
            print("Accuracy Mult: " .. tostring(weapon.ArcadeAccuracyMult))
        end
    end
end)

-- Network string for client notification
util.AddNetworkString("AA_WeaponAccuracy_Enhanced")

--[[
    Notify client of accuracy enhancement
]]
function AA.WeaponAccuracy.NotifyClient(ply, weaponClass, accuracyMult)
    if not IsValid(ply) then return end
    
    net.Start("AA_WeaponAccuracy_Enhanced")
    net.WriteString(weaponClass)
    net.WriteFloat(accuracyMult)
    net.Send(ply)
end

print("[Arcade Anomaly] Weapon Accuracy System loaded - Hitscan accuracy enhanced!")
