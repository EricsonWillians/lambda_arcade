-- addons/arcade_spawner/lua/arcade_spawner/server/loot_system.lua
-- INTELLIGENT Workshop-Aware Weapon Loot System v1.0

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.LootSystem = ArcadeSpawner.LootSystem or {}
local LootSystem = ArcadeSpawner.LootSystem

-- Loot configuration
LootSystem.Config = {
    dropChance = 0.35, -- 35% base drop chance
    rarityMultipliers = {
        ["Common"] = 1.0,
        ["Uncommon"] = 1.4,
        ["Rare"] = 1.8,
        ["Epic"] = 2.2,
        ["Legendary"] = 2.8,
        ["Mythic"] = 3.5
    },
    ammoMultipliers = {
        ["Common"] = 1.0,
        ["Uncommon"] = 1.5,
        ["Rare"] = 2.0,
        ["Epic"] = 2.5,
        ["Legendary"] = 3.0,
        ["Mythic"] = 4.0
    }
}

-- Weapon detection and categorization
LootSystem.WeaponCache = {}
LootSystem.WeaponCategories = {
    pistols = {},
    rifles = {},
    shotguns = {},
    smgs = {},
    explosives = {},
    special = {}
}

-- Scan for available weapons
function LootSystem.ScanAvailableWeapons()
    LootSystem.WeaponCache = {}
    LootSystem.WeaponCategories = {
        pistols = {},
        rifles = {},
        shotguns = {},
        smgs = {},
        explosives = {},
        special = {}
    }
    
    -- Get weapon list from game/workshop
    local weaponList = weapons.GetList()
    
    for _, weapon in pairs(weaponList) do
        if weapon and weapon.ClassName and weapon.PrintName then
            local className = weapon.ClassName
            local printName = weapon.PrintName or className
            
            -- Skip unwanted weapons
            if LootSystem.IsValidWeapon(className, printName) then
                local category = LootSystem.CategorizeWeapon(className, printName)
                local weaponData = {
                    class = className,
                    name = printName,
                    category = category,
                    weight = LootSystem.CalculateWeaponWeight(weapon),
                    source = weapon.Author and "workshop" or "vanilla"
                }
                
                table.insert(LootSystem.WeaponCache, weaponData)
                table.insert(LootSystem.WeaponCategories[category], weaponData)
            end
        end
    end
    
    print("[Arcade Spawner] 🔫 Scanned " .. #LootSystem.WeaponCache .. " available weapons")
    
    -- Print category breakdown
    for category, weapons in pairs(LootSystem.WeaponCategories) do
        if #weapons > 0 then
            print("[Arcade Spawner] " .. category .. ": " .. #weapons .. " weapons")
        end
    end
end

-- Validate weapon for loot drops
function LootSystem.IsValidWeapon(className, printName)
    -- Blacklist patterns
    local blacklist = {
        "gmod_", "weapon_physgun", "weapon_physcannon", "admin", "tool",
        "hands", "fists", "unarmed", "debug", "test", "dev"
    }
    
    local lowerName = string.lower(className .. " " .. printName)
    
    for _, pattern in ipairs(blacklist) do
        if string.find(lowerName, pattern) then
            return false
        end
    end
    
    return true
end

-- Categorize weapon by class name and print name
function LootSystem.CategorizeWeapon(className, printName)
    local name = string.lower(className .. " " .. printName)
    
    -- Categorization patterns
    if string.find(name, "pistol") or string.find(name, "revolver") or 
       string.find(name, "deagle") or string.find(name, "glock") then
        return "pistols"
    elseif string.find(name, "rifle") or string.find(name, "ak") or 
           string.find(name, "m4") or string.find(name, "ar15") or
           string.find(name, "sniper") then
        return "rifles"
    elseif string.find(name, "shotgun") or string.find(name, "pump") or
           string.find(name, "spas") then
        return "shotguns"
    elseif string.find(name, "smg") or string.find(name, "mp5") or
           string.find(name, "ump") or string.find(name, "submachine") then
        return "smgs"
    elseif string.find(name, "rocket") or string.find(name, "rpg") or
           string.find(name, "grenade") or string.find(name, "explosive") then
        return "explosives"
    else
        return "special"
    end
end

-- Calculate weapon weight for drop probability
function LootSystem.CalculateWeaponWeight(weapon)
    local baseWeight = 1.0
    
    -- Adjust based on weapon properties
    if weapon.Primary then
        local damage = weapon.Primary.Damage or 10
        local clipSize = weapon.Primary.ClipSize or 30
        
        -- Higher damage = lower drop chance
        if damage > 50 then baseWeight = baseWeight * 0.7 end
        if damage > 100 then baseWeight = baseWeight * 0.5 end
        
        -- Larger clips = slightly lower drop chance
        if clipSize > 50 then baseWeight = baseWeight * 0.9 end
    end
    
    return baseWeight
end

-- Analyze player's current weapons
function LootSystem.AnalyzePlayerWeapons(player)
    if not IsValid(player) then return {} end
    
    local playerWeapons = player:GetWeapons()
    local weaponData = {
        categories = {},
        total = 0,
        preferredCategories = {}
    }
    
    for _, weapon in pairs(playerWeapons) do
        if IsValid(weapon) then
            local className = weapon:GetClass()
            local category = LootSystem.CategorizeWeapon(className, className)
            
            weaponData.categories[category] = (weaponData.categories[category] or 0) + 1
            weaponData.total = weaponData.total + 1
        end
    end
    
    -- Determine preferred categories (most used)
    local sortedCategories = {}
    for category, count in pairs(weaponData.categories) do
        table.insert(sortedCategories, {category = category, count = count})
    end
    
    table.sort(sortedCategories, function(a, b) return a.count > b.count end)
    
    for i, data in ipairs(sortedCategories) do
        if i <= 2 then -- Top 2 categories
            table.insert(weaponData.preferredCategories, data.category)
        end
    end
    
    return weaponData
end

-- Generate intelligent loot drop
function LootSystem.GenerateLootDrop(enemy, killer)
    if not IsValid(enemy) then return nil end
    
    local rarity = enemy.RarityType or "Common"
    local baseChance = LootSystem.Config.dropChance
    local rarityMult = LootSystem.Config.rarityMultipliers[rarity] or 1.0
    
    local dropChance = baseChance * rarityMult
    
    if math.random() > dropChance then return nil end
    
    -- Analyze killer's preferences if valid player
    local preferredCategories = {}
    if IsValid(killer) and killer:IsPlayer() then
        local weaponAnalysis = LootSystem.AnalyzePlayerWeapons(killer)
        preferredCategories = weaponAnalysis.preferredCategories
    end
    
    -- Select weapon category intelligently
    local selectedCategory = LootSystem.SelectWeaponCategory(preferredCategories, rarity)
    local availableWeapons = LootSystem.WeaponCategories[selectedCategory]
    
    if #availableWeapons == 0 then
        -- Fallback to any available weapon
        if #LootSystem.WeaponCache > 0 then
            return table.Random(LootSystem.WeaponCache)
        else
            return nil
        end
    end
    
    -- Weight-based selection
    local selectedWeapon = LootSystem.SelectWeightedWeapon(availableWeapons)
    return selectedWeapon
end

-- Select weapon category based on preferences and rarity
function LootSystem.SelectWeaponCategory(preferredCategories, rarity)
    -- Higher rarity enemies prefer better weapons
    local categoryPriorities = {
        ["Common"] = {"pistols", "smgs", "shotguns", "rifles", "special", "explosives"},
        ["Uncommon"] = {"smgs", "shotguns", "pistols", "rifles", "special", "explosives"},
        ["Rare"] = {"rifles", "shotguns", "smgs", "special", "pistols", "explosives"},
        ["Epic"] = {"rifles", "special", "shotguns", "explosives", "smgs", "pistols"},
        ["Legendary"] = {"special", "rifles", "explosives", "shotguns", "smgs", "pistols"},
        ["Mythic"] = {"explosives", "special", "rifles", "shotguns", "smgs", "pistols"}
    }
    
    local priorities = categoryPriorities[rarity] or categoryPriorities["Common"]
    
    -- 60% chance to use player preference if available
    if #preferredCategories > 0 and math.random() < 0.6 then
        local preferredCategory = table.Random(preferredCategories)
        if #LootSystem.WeaponCategories[preferredCategory] > 0 then
            return preferredCategory
        end
    end
    
    -- Use rarity-based priority
    for _, category in ipairs(priorities) do
        if #LootSystem.WeaponCategories[category] > 0 then
            return category
        end
    end
    
    -- Ultimate fallback
    return "pistols"
end

-- Select weapon using weight-based probability
function LootSystem.SelectWeightedWeapon(weaponList)
    if #weaponList == 0 then return nil end
    
    local totalWeight = 0
    for _, weapon in ipairs(weaponList) do
        totalWeight = totalWeight + (weapon.weight or 1.0)
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for _, weapon in ipairs(weaponList) do
        currentWeight = currentWeight + (weapon.weight or 1.0)
        if randomValue <= currentWeight then
            return weapon
        end
    end
    
    return weaponList[#weaponList] -- Fallback
end

-- Create weapon drop entity
function LootSystem.CreateWeaponDrop(weaponData, position, rarity)
    if not weaponData or not position then return nil end
    
    local weaponEnt = ents.Create(weaponData.class)
    if not IsValid(weaponEnt) then return nil end
    
    -- Position slightly above ground
    local groundPos = position + Vector(0, 0, 20)
    
    weaponEnt:SetPos(groundPos)
    weaponEnt:SetAngles(Angle(0, math.random(0, 360), 0))
    weaponEnt:Spawn()
    
    -- Enhanced ammo based on rarity
    local ammoMult = LootSystem.Config.ammoMultipliers[rarity] or 1.0
    
    pcall(function()
        if weaponEnt.Primary and weaponEnt.Primary.Ammo then
            local ammoType = weaponEnt.Primary.Ammo
            local baseAmmo = weaponEnt.Primary.ClipSize or 30
            local bonusAmmo = math.floor(baseAmmo * ammoMult * math.random(2, 5))
            
            weaponEnt:SetClip1(weaponEnt.Primary.ClipSize or 30)
        end
    end)
    
    -- Visual effects based on rarity
    local effectData = EffectData()
    effectData:SetOrigin(groundPos)
    effectData:SetMagnitude(LootSystem.GetRarityMagnitude(rarity))
    util.Effect("arcade_spawn_effect", effectData)
    
    -- Mark as loot drop
    weaponEnt.IsArcadeLoot = true
    weaponEnt.LootRarity = rarity
    weaponEnt.SpawnTime = CurTime()
    
    -- Auto-cleanup after 60 seconds
    timer.Simple(60, function()
        if IsValid(weaponEnt) then
            weaponEnt:Remove()
        end
    end)
    
    print("[Arcade Spawner] 🎁 Dropped " .. rarity .. " " .. weaponData.name .. " (" .. weaponData.category .. ")")
    
    return weaponEnt
end

-- Get rarity magnitude for effects
function LootSystem.GetRarityMagnitude(rarity)
    local magnitudes = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythic"] = 6
    }
    return magnitudes[rarity] or 1
end

-- Hook into enemy death for loot drops
hook.Add("OnNPCKilled", "ArcadeSpawner_LootDrop", function(npc, attacker, inflictor)
    if IsValid(npc) and npc.IsArcadeEnemy then
        local weaponData = LootSystem.GenerateLootDrop(npc, attacker)
        
        if weaponData then
            local dropPos = npc:GetPos()
            local rarity = npc.RarityType or "Common"
            
            timer.Simple(0.5, function() -- Slight delay for death effects
                LootSystem.CreateWeaponDrop(weaponData, dropPos, rarity)
            end)
        end
    end
end)

-- Initialize weapon scanning
hook.Add("InitPostEntity", "ArcadeSpawner_LootSystem", function()
    timer.Simple(3, function()
        LootSystem.ScanAvailableWeapons()
    end)
end)

print("[Arcade Spawner] 🎁 Intelligent Loot System v1.0 loaded!")