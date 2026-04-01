--[[
    Lambda Arcade: Enhanced Loot System
    Comprehensive ammo, health, armor, and weapon drops
--]]

AA.Loot = AA.Loot or {}

-- Health pickups - ENHANCED AMOUNTS
AA.Loot.HealthItems = {
    { class = "item_healthkit", amount = 50, weight = 40 },   -- Doubled from 25
    { class = "item_healthvial", amount = 25, weight = 50 },  -- Doubled from 10
    { class = "item_battery", amount = 30, weight = 10 },     -- Armor as health alternative
}

-- Armor pickups
AA.Loot.ArmorItems = {
    { class = "item_battery", amount = 30, weight = 40 },
    { class = "item_suit", amount = 100, weight = 10 }, -- Full suit charge
}

-- Ammo types with their item classes - ENHANCED AMOUNTS
AA.Loot.AmmoTypes = {
    -- Pistols - GENEROUS
    { class = "item_ammo_pistol", type = "Pistol", amount = 40, weight = 35 },       -- Doubled from 20
    { class = "item_ammo_pistol_large", type = "Pistol", amount = 100, weight = 25 }, -- Nearly doubled
    
    -- SMG - GENEROUS
    { class = "item_ammo_smg1", type = "SMG1", amount = 90, weight = 30 },          -- Doubled from 45
    { class = "item_ammo_smg1_large", type = "SMG1", amount = 200, weight = 20 },   -- Increased from 135
    
    -- AR2 (Pulse Rifle) - GENEROUS
    { class = "item_ammo_ar2", type = "AR2", amount = 40, weight = 20 },            -- Doubled from 20
    { class = "item_ammo_ar2_large", type = "AR2", amount = 100, weight = 15 },     -- Increased from 60
    
    -- Shotgun - GENEROUS
    { class = "item_box_buckshot", type = "Buckshot", amount = 40, weight = 35 },   -- Doubled from 20
    
    -- Crossbow
    { class = "item_ammo_crossbow", type = "XBowBolt", amount = 10, weight = 15 },  -- Increased from 6
    
    -- 357 Magnum
    { class = "item_ammo_357", type = "357", amount = 20, weight = 20 },            -- Increased from 12
    
    -- Grenades
    { class = "weapon_frag", type = "Grenade", amount = 2, weight = 12 },           -- Now gives 2
    
    -- SMG Grenades (Alt fire)
    { class = "item_ammo_smg1_grenade", type = "SMG1_Grenade", amount = 5, weight = 10 }, -- Increased from 3
    
    -- AR2 Alt Fire (Combine Balls)
    { class = "item_ammo_ar2_altfire", type = "AR2AltFire", amount = 4, weight = 8 }, -- Proper item, increased from 2
}

-- Weapons that can be dropped
AA.Loot.Weapons = {
    -- Pistols
    { class = "weapon_pistol", weight = 25, ammo = "Pistol", ammoCount = 18 },
    { class = "weapon_357", weight = 15, ammo = "357", ammoCount = 6 },
    
    -- SMGs
    { class = "weapon_smg1", weight = 20, ammo = "SMG1", ammoCount = 45 },
    
    -- Rifles
    { class = "weapon_ar2", weight = 15, ammo = "AR2", ammoCount = 30 },
    
    -- Shotguns
    { class = "weapon_shotgun", weight = 18, ammo = "Buckshot", ammoCount = 6 },
    
    -- Special
    { class = "weapon_crossbow", weight = 8, ammo = "XBowBolt", ammoCount = 5 },
    { class = "weapon_rpg", weight = 5, ammo = "RPG_Round", ammoCount = 1 },
    { class = "weapon_frag", weight = 12, ammo = "Grenade", ammoCount = 1 },
    
    -- Melee (rare)
    { class = "weapon_crowbar", weight = 3 },
    { class = "weapon_stunstick", weight = 2 },
}

-- Special drops for elite enemies
AA.Loot.EliteDrops = {
    { class = "item_item_crate", weight = 10 }, -- Supply crate
    { class = "weapon_rpg", weight = 5 },
    { class = "weapon_ar2", weight = 15 },
    { class = "item_ammo_ar2_altfire", weight = 8 }, -- Combine energy ball
}

-- Weighted random selection
function AA.Loot:WeightedRandom(items)
    local totalWeight = 0
    for _, item in ipairs(items) do
        totalWeight = totalWeight + (item.weight or 10)
    end
    
    local random = math.random(1, totalWeight)
    local current = 0
    
    for _, item in ipairs(items) do
        current = current + (item.weight or 10)
        if random <= current then
            return item
        end
    end
    
    return items[1]
end

-- Spawn a health pickup
function AA.Loot:SpawnHealth(pos, amount)
    local item = self:WeightedRandom(self.HealthItems)
    
    local ent = ents.Create(item.class)
    if not IsValid(ent) then return nil end
    
    ent:SetPos(pos)
    ent:Spawn()
    
    -- Custom health amount
    if amount then
        ent.AA_HealthAmount = amount
    else
        ent.AA_HealthAmount = item.amount
    end
    
    -- Physics
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), 100))
        phys:AddAngleVelocity(VectorRand() * 100)
    end
    
    -- Enhanced glow effect - BRIGHTER for visibility
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "255 80 80 200")
        light:SetKeyValue("brightness", "4")
        light:SetKeyValue("distance", "200")
        light:SetPos(pos)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        
        -- Parent to item and remove when item is gone
        timer.Simple(0.1, function()
            if IsValid(light) and IsValid(ent) then
                light:SetParent(ent)
            else
                light:Remove()
            end
        end)
    end
    
    -- Spawn effect - particle burst
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(2)
    util.Effect("cball_explode", effectData)
    
    -- Mark spawn time
    ent.AA_SpawnTime = CurTime()
    
    return ent
end

-- Spawn armor pickup
function AA.Loot:SpawnArmor(pos, amount)
    local item = self:WeightedRandom(self.ArmorItems)
    
    local ent = ents.Create(item.class)
    if not IsValid(ent) then return nil end
    
    ent:SetPos(pos)
    ent:Spawn()
    
    ent.AA_ArmorAmount = amount or item.amount
    
    -- Physics
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), 100))
        phys:AddAngleVelocity(VectorRand() * 100)
    end
    
    -- Enhanced blue glow for armor
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "80 180 255 200")
        light:SetKeyValue("brightness", "4")
        light:SetKeyValue("distance", "200")
        light:SetPos(pos)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        
        timer.Simple(0.1, function()
            if IsValid(light) and IsValid(ent) then
                light:SetParent(ent)
            else
                light:Remove()
            end
        end)
    end
    
    -- Spawn effect
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(2)
    util.Effect("cball_explode", effectData)
    
    ent.AA_SpawnTime = CurTime()
    
    return ent
end

-- Spawn ammo pickup
function AA.Loot:SpawnAmmo(pos, specificType)
    local items = self.AmmoTypes
    
    -- Filter by type if specified
    if specificType then
        items = {}
        for _, item in ipairs(self.AmmoTypes) do
            if item.type == specificType then
                table.insert(items, item)
            end
        end
        if #items == 0 then items = self.AmmoTypes end
    end
    
    local item = self:WeightedRandom(items)
    
    -- Special handling for grenade weapon vs ammo
    if item.class == "weapon_frag" then
        return self:SpawnWeapon(pos, item.class)
    end
    
    local ent = ents.Create(item.class)
    if not IsValid(ent) then return nil end
    
    ent:SetPos(pos)
    ent:Spawn()
    
    ent.AA_AmmoType = item.type
    ent.AA_AmmoAmount = item.amount
    
    -- Physics
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(math.random(-60, 60), math.random(-60, 60), 120))
        phys:AddAngleVelocity(VectorRand() * 150)
    end
    
    -- Enhanced yellow/orange glow for ammo
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "255 180 50 200")
        light:SetKeyValue("brightness", "4")
        light:SetKeyValue("distance", "200")
        light:SetPos(pos)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        
        timer.Simple(0.1, function()
            if IsValid(light) and IsValid(ent) then
                light:SetParent(ent)
            else
                light:Remove()
            end
        end)
    end
    
    -- Spawn effect
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(2)
    util.Effect("cball_explode", effectData)
    
    ent.AA_SpawnTime = CurTime()
    
    return ent
end

-- Spawn a weapon
function AA.Loot:SpawnWeapon(pos, specificClass)
    local item
    
    if specificClass then
        for _, w in ipairs(self.Weapons) do
            if w.class == specificClass then
                item = w
                break
            end
        end
    end
    
    if not item then
        item = self:WeightedRandom(self.Weapons)
    end
    
    local ent = ents.Create(item.class)
    if not IsValid(ent) then return nil end
    
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, math.random(0, 360), 0))
    ent:Spawn()
    
    -- Physics
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(math.random(-40, 40), math.random(-40, 40), 150))
        phys:AddAngleVelocity(VectorRand() * 100)
    end
    
    -- Enhanced green glow for weapons
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "50 255 100 200")
        light:SetKeyValue("brightness", "5")
        light:SetKeyValue("distance", "250")
        light:SetPos(pos)
        light:Spawn()
        light:Fire("TurnOn", "", 0)
        
        timer.Simple(0.1, function()
            if IsValid(light) and IsValid(ent) then
                light:SetParent(ent)
            else
                light:Remove()
            end
        end)
    end
    
    -- Spawn effect
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(3)
    util.Effect("cball_explode", effectData)
    
    -- Weapon pickup notification effect
    local sparkData = EffectData()
    sparkData:SetOrigin(pos)
    sparkData:SetMagnitude(2)
    sparkData:SetScale(2)
    util.Effect("Sparks", sparkData)
    
    ent.AA_SpawnTime = CurTime()
    
    return ent
end

-- Main drop function called on enemy death - SEVERELY ENHANCED
function AA.Loot:DropFromEnemy(enemy, attacker)
    if not IsValid(enemy) then return end
    
    local pos = enemy:GetPos() + Vector(0, 0, 40)
    local archetype = enemy.Archetype or 1
    local isElite = enemy.IsElite or false
    
    -- ALWAYS drop something (guaranteed drops)
    local numDrops = 1
    
    -- Determine number of drops based on enemy type
    if archetype == 3 then numDrops = 2      -- Brutes drop 2 items
    elseif archetype == 6 then numDrops = 3  -- Elites drop 3 items
    elseif isElite then numDrops = 2
    end
    
    -- Combo bonus - extra drops
    local combo = 0
    if attacker and attacker:IsPlayer() then
        combo = attacker.AA_Combo or 0
        if combo >= 5 then numDrops = numDrops + 1 end
        if combo >= 15 then numDrops = numDrops + 1 end
    end
    
    -- Cap max drops
    numDrops = math.min(numDrops, 4)
    
    -- Check if attacker needs health (guaranteed health drop if low)
    local attackerNeedsHealth = false
    if IsValid(attacker) and attacker:IsPlayer() then
        local healthPercent = attacker:Health() / attacker:GetMaxHealth()
        if healthPercent < 0.5 then
            attackerNeedsHealth = true
        end
    end
    
    -- Elite special drops (supply crate replaces one drop)
    if isElite and math.random() < 0.4 then
        self:SpawnSupplyCrate(pos)
        numDrops = numDrops - 1
    end
    
    -- Spawn multiple drops
    for i = 1, numDrops do
        timer.Simple((i - 1) * 0.15, function()
            if not IsValid(enemy) then return end
            local dropPos = pos + Vector(math.random(-20, 20), math.random(-20, 20), 0)
            self:SpawnSingleDrop(dropPos, attacker, archetype, isElite, attackerNeedsHealth and i == 1)
        end)
    end
    
    -- Bonus ammo drop for high combo
    if combo >= 10 then
        timer.Simple(numDrops * 0.15 + 0.1, function()
            if not IsValid(enemy) then return end
            self:SpawnAmmo(pos + Vector(math.random(-30, 30), math.random(-30, 30), 0))
        end)
    end
end

-- Spawn a single drop item
function AA.Loot:SpawnSingleDrop(pos, attacker, archetype, isElite, forceHealth)
    -- Determine what type of drop
    local dropRoll = math.random(1, 100)
    
    -- Force health if player needs it
    if forceHealth then
        dropRoll = 20  -- Forces health drop
    end
    
    -- Enhanced amounts based on enemy type
    local multiplier = 1.0
    if archetype == 3 then multiplier = 1.5      -- Brutes give 50% more
    elseif archetype == 6 then multiplier = 2.0  -- Elites give double
    elseif isElite then multiplier = 1.5
    end
    
    if dropRoll <= 40 then -- 40% Health (increased from 35%)
        local amount = math.floor(math.random(25, 50) * multiplier)
        self:SpawnHealth(pos, amount)
        
    elseif dropRoll <= 55 then -- 15% Armor
        local amount = math.floor(math.random(25, 50) * multiplier)
        self:SpawnArmor(pos, amount)
        
    elseif dropRoll <= 85 then -- 30% Ammo
        -- Try to give ammo the player needs
        local ammoType = nil
        if IsValid(attacker) and attacker:IsPlayer() and attacker:GetActiveWeapon() then
            local weapon = attacker:GetActiveWeapon()
            local primaryAmmo = weapon:GetPrimaryAmmoType()
            if primaryAmmo and primaryAmmo > 0 then
                -- Map ammo type IDs to names
                local ammoNames = {
                    [1] = "Pistol",
                    [3] = "SMG1",
                    [4] = "AR2",
                    [5] = "Buckshot",
                    [6] = "357",
                    [7] = "XBowBolt",
                    [10] = "Grenade",
                }
                ammoType = ammoNames[primaryAmmo]
            end
        end
        self:SpawnAmmo(pos, ammoType)
        
    elseif dropRoll <= 95 then -- 10% Weapon
        self:SpawnWeapon(pos)
        
    else -- 5% Double Health (bonus)
        self:SpawnHealth(pos, math.floor(50 * multiplier))
    end
end

-- Spawn a supply crate
function AA.Loot:SpawnSupplyCrate(pos)
    local crate = ents.Create("item_item_crate")
    if not IsValid(crate) then return nil end
    
    crate:SetPos(pos)
    crate:SetKeyValue("ItemClass", "item_dynamic_resupply")
    crate:SetKeyValue("ItemCount", "3")
    crate:Spawn()
    
    -- Physics
    local phys = crate:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(0, 0, 50))
    end
    
    return crate
end

-- Utility: Clean up old drops to prevent lag
function AA.Loot:CleanupOldDrops()
    local drops = ents.FindByClass("item_*")
    local weapons = ents.FindByClass("weapon_*")
    
    -- Remove drops that have been on ground too long (10 minutes - longer to help players)
    local maxAge = 600
    local now = CurTime()
    
    for _, ent in ipairs(drops) do
        if ent.AA_SpawnTime and (now - ent.AA_SpawnTime > maxAge) then
            ent:Remove()
        elseif not ent.AA_SpawnTime then
            ent.AA_SpawnTime = now
        end
    end
    
    for _, ent in ipairs(weapons) do
        if ent.AA_SpawnTime and (now - ent.AA_SpawnTime > maxAge) then
            ent:Remove()
        elseif not ent.AA_SpawnTime then
            ent.AA_SpawnTime = now
        end
    end
end

-- Periodic cleanup
hook.Add("Think", "AA_LootCleanup", function()
    if math.random() < 0.001 then -- Rare check
        AA.Loot:CleanupOldDrops()
    end
end)

-- Custom pickup handling for enhanced health amounts
hook.Add("PlayerCanPickupItem", "AA_Loot_HealthPickup", function(ply, item)
    if not IsValid(item) then return end
    
    -- Handle custom health amounts
    if item.AA_HealthAmount and item.AA_HealthAmount > 0 then
        local currentHealth = ply:Health()
        local maxHealth = ply:GetMaxHealth()
        
        if currentHealth < maxHealth then
            local newHealth = math.min(currentHealth + item.AA_HealthAmount, maxHealth)
            ply:SetHealth(newHealth)
            
            -- Visual feedback
            local effectData = EffectData()
            effectData:SetOrigin(ply:GetPos())
            effectData:SetMagnitude(1)
            util.Effect("cball_bounce", effectData)
            
            item:Remove()
            return false -- Block default pickup
        end
    end
    
    -- Handle custom armor amounts
    if item.AA_ArmorAmount and item.AA_ArmorAmount > 0 then
        local currentArmor = ply:Armor()
        
        if currentArmor < 100 then
            local newArmor = math.min(currentArmor + item.AA_ArmorAmount, 100)
            ply:SetArmor(newArmor)
            
            -- Visual feedback
            local effectData = EffectData()
            effectData:SetOrigin(ply:GetPos())
            effectData:SetMagnitude(1)
            util.Effect("cball_bounce", effectData)
            
            item:Remove()
            return false -- Block default pickup
        end
    end
    
    -- Handle custom ammo amounts
    if item.AA_AmmoType and item.AA_AmmoAmount and item.AA_AmmoAmount > 0 then
        ply:GiveAmmo(item.AA_AmmoAmount, item.AA_AmmoType)
        
        -- Visual feedback
        local effectData = EffectData()
        effectData:SetOrigin(ply:GetPos())
        effectData:SetMagnitude(1)
        util.Effect("cball_bounce", effectData)
        
        item:Remove()
        return false -- Block default pickup
    end
end)

print("[Lambda Arcade] SEVERELY ENHANCED Loot System initialized - Generous drops enabled!")
