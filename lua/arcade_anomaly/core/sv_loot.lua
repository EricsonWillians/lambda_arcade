--[[
    Lambda Arcade: Enhanced Loot System
    Comprehensive ammo, health, armor, and weapon drops
--]]

AA.Loot = AA.Loot or {}

-- Health pickups
AA.Loot.HealthItems = {
    { class = "item_healthkit", amount = 25, weight = 30 },
    { class = "item_healthvial", amount = 10, weight = 50 },
    { class = "item_battery", amount = 15, weight = 20 }, -- Armor as health alternative
}

-- Armor pickups
AA.Loot.ArmorItems = {
    { class = "item_battery", amount = 30, weight = 40 },
    { class = "item_suit", amount = 100, weight = 10 }, -- Full suit charge
}

-- Ammo types with their item classes
AA.Loot.AmmoTypes = {
    -- Pistols
    { class = "item_ammo_pistol", type = "Pistol", amount = 20, weight = 40 },
    { class = "item_ammo_pistol_large", type = "Pistol", amount = 60, weight = 20 },
    
    -- SMG
    { class = "item_ammo_smg1", type = "SMG1", amount = 45, weight = 35 },
    { class = "item_ammo_smg1_large", type = "SMG1", amount = 135, weight = 15 },
    
    -- AR2 (Pulse Rifle)
    { class = "item_ammo_ar2", type = "AR2", amount = 20, weight = 25 },
    { class = "item_ammo_ar2_large", type = "AR2", amount = 60, weight = 10 },
    
    -- Shotgun
    { class = "item_box_buckshot", type = "Buckshot", amount = 20, weight = 30 },
    
    -- Crossbow
    { class = "item_ammo_crossbow", type = "XBowBolt", amount = 6, weight = 15 },
    
    -- RPG
    { class = "item_ammo_357", type = "357", amount = 12, weight = 20 },
    
    -- Grenades
    { class = "weapon_frag", type = "Grenade", amount = 1, weight = 10 },
    
    -- SMG Grenades (Alt fire)
    { class = "item_ammo_smg1_grenade", type = "SMG1_Grenade", amount = 3, weight = 8 },
    
    -- AR2 Alt Fire (Combine Balls)
    { class = "item_battery", type = "AR2AltFire", amount = 2, weight = 5 }, -- Using battery as proxy
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
    
    -- Glow effect
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "255 100 100 150")
        light:SetKeyValue("brightness", "2")
        light:SetKeyValue("distance", "128")
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
    
    -- Blue glow for armor
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "100 150 255 150")
        light:SetKeyValue("brightness", "2")
        light:SetKeyValue("distance", "128")
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
    
    -- Yellow/orange glow for ammo
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "255 200 50 150")
        light:SetKeyValue("brightness", "2")
        light:SetKeyValue("distance", "128")
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
    
    -- Green glow for weapons
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetKeyValue("_light", "50 255 100 150")
        light:SetKeyValue("brightness", "3")
        light:SetKeyValue("distance", "160")
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
    
    return ent
end

-- Main drop function called on enemy death
function AA.Loot:DropFromEnemy(enemy, attacker)
    if not IsValid(enemy) then return end
    
    local pos = enemy:GetPos() + Vector(0, 0, 40)
    local archetype = enemy.Archetype or 1
    local isElite = enemy.IsElite or false
    
    -- Calculate drop chance based on enemy type
    local dropChance = 0.25 -- Base 25%
    
    if archetype == 3 then dropChance = 0.45 -- Brutes drop more
    elseif archetype == 6 then dropChance = 0.70 -- Elites drop even more
    elseif isElite then dropChance = 0.60
    end
    
    -- Player luck bonus (based on combo)
    local combo = 0
    if attacker and attacker:IsPlayer() and attacker.AA_Combo then
        combo = attacker.AA_Combo
        dropChance = dropChance + (combo * 0.05) -- +5% per combo
    end
    
    -- Guaranteed drop on high combos
    if combo >= 10 then dropChance = 1.0 end
    
    -- Roll for drop
    if math.random() > dropChance then return end
    
    -- Determine what type of drop
    local dropRoll = math.random(1, 100)
    
    -- Elite special drops
    if isElite and math.random() < 0.3 then
        local eliteItem = self:WeightedRandom(self.EliteDrops)
        if eliteItem.class == "item_item_crate" then
            self:SpawnSupplyCrate(pos)
        else
            self:SpawnWeapon(pos, eliteItem.class)
        end
        return
    end
    
    -- Weighted drop types
    if dropRoll <= 35 then -- 35% Health
        local amount = math.random(10, 25)
        if archetype == 3 then amount = math.random(25, 50) end
        if isElite then amount = math.random(50, 100) end
        self:SpawnHealth(pos, amount)
        
    elseif dropRoll <= 55 then -- 20% Armor
        local amount = math.random(15, 30)
        if isElite then amount = math.random(40, 80) end
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
        
    else -- 5% Bonus (health + ammo)
        self:SpawnHealth(pos, 25)
        timer.Simple(0.1, function()
            self:SpawnAmmo(pos + Vector(10, 0, 0))
        end)
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
    
    -- Remove drops that have been on ground too long (5 minutes)
    local maxAge = 300
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

print("[Lambda Arcade] Enhanced Loot System initialized")
