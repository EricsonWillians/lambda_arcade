--[[
    Arcade Anomaly: Enhanced Hit Feedback & Gore 2.0
    Satisfying hit markers, blood effects, screen shake, and hitstop
--]]

AA.HitFeedback = AA.HitFeedback or {}
AA.HitFeedback.Hits = {}
AA.HitFeedback.BloodParticles = {}
AA.HitFeedback.GoreChunks = {}
AA.HitFeedback.CrosshairExpand = 0
AA.HitFeedback.ComboHits = 0
AA.HitFeedback.LastHitTime = 0
AA.HitFeedback.HitstopEndTime = 0
AA.HitFeedback.ScreenShakeEndTime = 0
AA.HitFeedback.ScreenShakeIntensity = 0

-- Hitstop configuration
local HITSTOP_DURATION = 0.05 -- 50ms freeze on hit
local KILL_HITSTOP_DURATION = 0.08 -- 80ms freeze on kill
local CRIT_THRESHOLD = 50 -- Damage for critical hit

-- Register a hit marker with enhanced feedback
function AA.HitFeedback:AddHit(position, damage, isKill, hitNormal)
    table.insert(self.Hits, {
        pos = position,
        damage = damage,
        isKill = isKill,
        time = CurTime(),
        life = 1.0,
    })
    
    -- Crosshair expansion
    self.CrosshairExpand = isKill and 25 or 15
    
    -- Track combo
    local now = CurTime()
    if now - self.LastHitTime < 0.5 then
        self.ComboHits = self.ComboHits + 1
    else
        self.ComboHits = 1
    end
    self.LastHitTime = now
    
    -- Hitstop (freeze frame) - only for local player
    local isCritical = damage >= CRIT_THRESHOLD
    if isKill then
        self:TriggerHitstop(KILL_HITSTOP_DURATION)
    elseif isCritical then
        self:TriggerHitstop(HITSTOP_DURATION * 1.5)
    else
        self:TriggerHitstop(HITSTOP_DURATION)
    end
    
    -- Screen shake based on damage
    local shakeIntensity = math.min(damage / 20, 3)
    if isKill then shakeIntensity = shakeIntensity * 2 end
    self:TriggerScreenShake(shakeIntensity, isKill and 0.4 or 0.2)
    
    -- Effects
    if isKill then
        self:KillFlash()
        self:SpawnBloodExplosion(position, hitNormal)
        self:SpawnGoreChunks(position, 5)
        self:SpawnBloodMist(position, 2)
    else
        self:SpawnBlood(position, hitNormal)
        if damage >= CRIT_THRESHOLD then
            self:SpawnGoreChunks(position, 2)
        end
    end
    
    -- Sounds with pitch variation
    if isKill then
        local killSounds = {
            "physics/flesh/flesh_squishy_impact_hard1.wav",
            "physics/flesh/flesh_squishy_impact_hard2.wav",
            "physics/flesh/flesh_squishy_impact_hard3.wav",
            "physics/flesh/flesh_squishy_impact_hard4.wav",
        }
        surface.PlaySound(killSounds[math.random(1, #killSounds)])
        
        -- Deeper kill sound
        timer.Simple(0.05, function()
            surface.PlaySound("buttons/button9.wav")
        end)
    else
        local hitSounds = {
            "physics/flesh/flesh_impact_bullet1.wav",
            "physics/flesh/flesh_impact_bullet2.wav",
            "physics/flesh/flesh_impact_bullet3.wav",
            "physics/flesh/flesh_impact_bullet4.wav",
            "physics/flesh/flesh_impact_bullet5.wav",
        }
        local pitch = 100 + self.ComboHits * 5 + (isCritical and -20 or 0)
        LocalPlayer():EmitSound(hitSounds[math.random(1, #hitSounds)], 60, pitch, isCritical and 0.6 or 0.3)
    end
end

-- Hitstop implementation (freeze frame)
function AA.HitFeedback:TriggerHitstop(duration)
    self.HitstopEndTime = CurTime() + duration
end

function AA.HitFeedback:IsHitstopActive()
    return CurTime() < self.HitstopEndTime
end

-- Screen shake
function AA.HitFeedback:TriggerScreenShake(intensity, duration)
    self.ScreenShakeEndTime = CurTime() + duration
    self.ScreenShakeIntensity = intensity
end

function AA.HitFeedback:UpdateScreenShake()
    if CurTime() > self.ScreenShakeEndTime then return end
    
    local remaining = self.ScreenShakeEndTime - CurTime()
    local progress = remaining / 0.4 -- normalized to max duration
    local currentIntensity = self.ScreenShakeIntensity * progress
    
    -- Apply shake to view
    local shakeX = math.sin(CurTime() * 50) * currentIntensity * 2
    local shakeY = math.cos(CurTime() * 40) * currentIntensity * 2
    
    local view = LocalPlayer():GetViewPunchAngles()
    view.p = view.p + shakeX * FrameTime() * 10
    view.y = view.y + shakeY * FrameTime() * 10
    LocalPlayer():SetViewPunchAngles(view)
end

function AA.HitFeedback:KillFlash()
    self.FlashTime = CurTime() + 0.15
    self.FlashAlpha = 100
    self.FlashColor = Color(255, 50, 50)
end

-- Enhanced blood particle effect
function AA.HitFeedback:SpawnBlood(pos, hitNormal)
    hitNormal = hitNormal or Vector(0, 0, 1)
    
    -- Main impact
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(hitNormal)
    effect:SetScale(math.random(2, 3))
    util.Effect("BloodImpact", effect)
    
    -- Blood spray in hit direction
    local sprayDir = hitNormal * -1
    for i = 1, 3 do
        local offset = sprayDir * 10 + VectorRand() * 5
        local eff = EffectData()
        eff:SetOrigin(pos + offset)
        eff:SetNormal(sprayDir + VectorRand() * 0.3)
        eff:SetScale(1)
        util.Effect("bloodspray", eff)
    end
    
    -- Blood decal on nearby surfaces
    local tr = util.TraceLine({
        start = pos,
        endpos = pos - hitNormal * 50,
        mask = MASK_SOLID,
    })
    if tr.Hit then
        util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end
    
    -- Add to particle list
    table.insert(self.BloodParticles, {
        pos = pos,
        vel = sprayDir * 50 + VectorRand() * 20,
        time = CurTime(),
        life = 3,
        size = math.random(5, 10),
    })
end

-- Enhanced blood explosion for kills
function AA.HitFeedback:SpawnBloodExplosion(pos, hitNormal)
    hitNormal = hitNormal or Vector(0, 0, 1)
    
    -- Multiple blood impacts in sphere pattern
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local height = math.sin(i * 0.5) * 20
        local offset = Vector(
            math.cos(angle) * math.random(20, 40),
            math.sin(angle) * math.random(20, 40),
            height + math.random(0, 30)
        )
        
        local effect = EffectData()
        effect:SetOrigin(pos + offset)
        effect:SetScale(math.random(3, 5))
        util.Effect("BloodImpact", effect)
    end
    
    -- Large blood spray upward
    for i = 1, 5 do
        local eff = EffectData()
        eff:SetOrigin(pos)
        eff:SetNormal(Vector(0, 0, 1) + VectorRand() * 0.5)
        eff:SetScale(4)
        util.Effect("HL2BloodSpray", eff)
    end
    
    -- Blood explosion effect
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetMagnitude(3)
    effect:SetScale(4)
    util.Effect("Explosion", effect)
    
    -- Large blood decals in radius
    for i = 1, 5 do
        local angle = math.random() * math.pi * 2
        local dist = math.random(30, 80)
        local decalPos = pos + Vector(math.cos(angle) * dist, math.sin(angle) * dist, 0)
        
        local tr = util.TraceLine({
            start = decalPos + Vector(0, 0, 50),
            endpos = decalPos - Vector(0, 0, 50),
            mask = MASK_SOLID,
        })
        
        if tr.Hit then
            util.Decal("BloodLarge", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
        end
    end
end

-- Blood mist effect
function AA.HitFeedback:SpawnBloodMist(pos, intensity)
    for i = 1, intensity * 5 do
        local mistPos = pos + VectorRand() * 30
        local eff = EffectData()
        eff:SetOrigin(mistPos)
        eff:SetScale(0.3)
        util.Effect("cball_bounce", eff)
    end
end

-- Gore chunks (flesh particles)
function AA.HitFeedback:SpawnGoreChunks(pos, count)
    for i = 1, count do
        local chunk = {
            pos = pos + Vector(0, 0, math.random(20, 50)),
            vel = VectorRand() * math.random(100, 300) + Vector(0, 0, 150),
            angVel = VectorRand() * 500,
            angles = AngleRand(),
            time = CurTime(),
            life = math.random(1.5, 2.5),
            size = math.random(3, 8),
            bounced = false,
        }
        table.insert(self.GoreChunks, chunk)
    end
end

-- Enhanced crosshair with hit feedback
hook.Add("HUDPaint", "AA_Crosshair", function()
    if AA.HUD.Data.runState ~= AA.Types.RunState.RUNNING then return end
    
    local w, h = ScrW(), ScrH()
    local cx, cy = w / 2, h / 2
    
    -- Decay expansion
    AA.HitFeedback.CrosshairExpand = math.max(0, AA.HitFeedback.CrosshairExpand - FrameTime() * 150)
    local expand = AA.HitFeedback.CrosshairExpand
    
    -- Dynamic size based on movement
    local ply = LocalPlayer()
    local velocity = ply:GetVelocity():Length()
    local size = 4 + math.min(velocity / 200, 8) + expand
    local gap = 8 + expand * 0.5
    
    -- Color based on hit type
    local color = color_white
    local timeSinceHit = CurTime() - AA.HitFeedback.LastHitTime
    if timeSinceHit < 0.15 then
        if AA.HitFeedback.LastHitWasKill then
            color = Color(255, 0, 0) -- Bright red on kill
        else
            color = Color(255, 100, 100) -- Normal red on hit
        end
    end
    
    -- Crosshair lines with glow on hit
    if timeSinceHit < 0.1 then
        surface.SetDrawColor(color.r, color.g, color.b, 100)
        surface.DrawRect(cx - 2, cy - gap - size - 1, 4, size + 2)
        surface.DrawRect(cx - 2, cy + gap - 1, 4, size + 2)
        surface.DrawRect(cx - gap - size - 1, cy - 2, size + 2, 4)
        surface.DrawRect(cx + gap - 1, cy - 2, size + 2, 4)
    end
    
    surface.SetDrawColor(color)
    surface.DrawRect(cx - 1, cy - gap - size, 2, size)
    surface.DrawRect(cx - 1, cy + gap, 2, size)
    surface.DrawRect(cx - gap - size, cy - 1, size, 2)
    surface.DrawRect(cx + gap, cy - 1, size, 2)
    
    -- Center dot when stationary
    if velocity < 100 then
        surface.SetDrawColor(255, 255, 255, 150)
        surface.DrawRect(cx - 1, cy - 1, 2, 2)
    end
end)

-- Hit markers, damage numbers, and gore rendering
hook.Add("HUDPaint", "AA_HitFeedback_Paint", function()
    local now = CurTime()
    
    -- Update screen shake
    AA.HitFeedback:UpdateScreenShake()
    
    -- Render gore chunks
    for i = #AA.HitFeedback.GoreChunks, 1, -1 do
        local chunk = AA.HitFeedback.GoreChunks[i]
        local age = now - chunk.time
        
        if age > chunk.life then
            table.remove(AA.HitFeedback.GoreChunks, i)
        else
            -- Physics simulation
            if not chunk.bounced then
                chunk.vel.z = chunk.vel.z - 800 * FrameTime() -- Gravity
            end
            
            local newPos = chunk.pos + chunk.vel * FrameTime()
            
            -- Ground collision
            local tr = util.TraceLine({
                start = chunk.pos,
                endpos = newPos,
                mask = MASK_SOLID,
            })
            
            if tr.Hit and not chunk.bounced then
                chunk.pos = tr.HitPos
                chunk.vel = chunk.vel * 0.3
                chunk.vel.z = math.abs(chunk.vel.z) * 0.5
                chunk.bounced = true
                chunk.angVel = chunk.angVel * 0.5
                
                -- Leave blood on impact
                util.Decal("Blood", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
            else
                chunk.pos = newPos
            end
            
            chunk.angles = chunk.angles + Angle(
                chunk.angVel.x * FrameTime(),
                chunk.angVel.y * FrameTime(),
                chunk.angVel.z * FrameTime()
            )
            
            -- Render chunk
            local screenPos = chunk.pos:ToScreen()
            if screenPos.visible then
                local alpha = 255 * (1 - age / chunk.life)
                local size = chunk.size * (1 - age / chunk.life * 0.3)
                
                surface.SetDrawColor(120, 20, 20, alpha)
                surface.DrawRect(screenPos.x - size/2, screenPos.y - size/2, size, size)
            end
        end
    end
    
    -- Process hit markers
    local validHits = {}
    for i, hit in ipairs(AA.HitFeedback.Hits) do
        local age = now - hit.time
        
        if age <= 1.2 then
            local screenPos = hit.pos:ToScreen()
            
            if screenPos.visible then
                local progress = age / 1.2
                local alpha = 255 * (1 - progress)
                local floatY = -20 - progress * 30
                local size = (hit.isKill and 20 or 14) * (1 - progress * 0.3)
                
                -- Hit marker X with glow
                local color = hit.isKill and Color(255, 30, 30, alpha) or Color(255, 100, 100, alpha)
                
                -- Outer glow
                surface.SetDrawColor(color.r, color.g, color.b, alpha * 0.3)
                for offset = 1, 3 do
                    surface.DrawLine(screenPos.x - size - offset, screenPos.y - size + floatY, 
                                    screenPos.x + size + offset, screenPos.y + size + floatY)
                    surface.DrawLine(screenPos.x + size + offset, screenPos.y - size + floatY, 
                                    screenPos.x - size - offset, screenPos.y + size + floatY)
                end
                
                -- Main X
                surface.SetDrawColor(color)
                surface.DrawLine(screenPos.x - size, screenPos.y - size + floatY, 
                                screenPos.x + size, screenPos.y + size + floatY)
                surface.DrawLine(screenPos.x + size, screenPos.y - size + floatY, 
                                screenPos.x - size, screenPos.y + size + floatY)
                
                -- Damage number with shadow
                if hit.damage then
                    local dmgText = tostring(math.floor(hit.damage))
                    local dmgColor = hit.isKill and Color(255, 50, 50, alpha) or Color(255, 200, 100, alpha)
                    local dmgY = screenPos.y + floatY - 25
                    
                    -- Shadow
                    draw.SimpleText(dmgText, "AA_Floating", screenPos.x + 1, dmgY + 1, 
                        Color(0, 0, 0, alpha * 0.7), TEXT_ALIGN_CENTER)
                    -- Text
                    draw.SimpleText(dmgText, "AA_Floating", screenPos.x, dmgY, dmgColor, TEXT_ALIGN_CENTER)
                end
                
                -- KILL text with animation
                if hit.isKill then
                    local killY = screenPos.y + floatY - 45
                    local killAlpha = math.max(0, 255 - age * 400)
                    local scale = 1 + math.sin(age * 15) * 0.1
                    
                    draw.SimpleText("KILL!", "AA_Medium", screenPos.x + 1, killY + 1, 
                        Color(0, 0, 0, killAlpha * 0.7), TEXT_ALIGN_CENTER)
                    draw.SimpleText("KILL!", "AA_Medium", screenPos.x, killY, 
                        Color(255, 50, 50, killAlpha), TEXT_ALIGN_CENTER)
                end
                
                table.insert(validHits, hit)
            else
                table.insert(validHits, hit)
            end
        end
    end
    AA.HitFeedback.Hits = validHits
    
    -- Kill flash
    if AA.HitFeedback.FlashTime and now < AA.HitFeedback.FlashTime then
        local remaining = AA.HitFeedback.FlashTime - now
        local flashAlpha = (remaining / 0.15) * (AA.HitFeedback.FlashAlpha or 80)
        local flashColor = AA.HitFeedback.FlashColor or Color(255, 255, 255)
        surface.SetDrawColor(flashColor.r, flashColor.g, flashColor.b, flashAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    
    -- Combo counter
    if AA.HitFeedback.ComboHits > 1 and (now - AA.HitFeedback.LastHitTime) < 1 then
        local alpha = 255 * (1 - (now - AA.HitFeedback.LastHitTime))
        local comboText = AA.HitFeedback.ComboHits .. " HITS"
        local pulse = 1 + math.sin(now * 15) * 0.1
        
        draw.SimpleText(comboText, "AA_Small", ScrW()/2 + 85, ScrH()/2 - 40, 
            Color(255, 180, 0, alpha), TEXT_ALIGN_LEFT)
        
        -- Combo meter bar
        local barWidth = 100
        local barHeight = 4
        local comboProgress = 1 - (now - AA.HitFeedback.LastHitTime)
        
        surface.SetDrawColor(50, 50, 50, 150)
        surface.DrawRect(ScrW()/2 - barWidth/2 + 85, ScrH()/2 - 25, barWidth, barHeight)
        
        surface.SetDrawColor(255, 180, 0, alpha)
        surface.DrawRect(ScrW()/2 - barWidth/2 + 85, ScrH()/2 - 25, barWidth * comboProgress, barHeight)
    end
    
    -- Hitstop frame freeze visual (white flash)
    if AA.HitFeedback:IsHitstopActive() then
        surface.SetDrawColor(255, 255, 255, 30)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)

-- Damage hook with hit normal calculation
hook.Add("EntityTakeDamage", "AA_HitFeedback_Damage", function(target, dmg)
    if not IsValid(target) then return end
    if not target.Archetype then return end
    
    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker ~= LocalPlayer() then return end
    
    local damage = dmg:GetDamage()
    local isKill = target:Health() <= damage
    
    -- Calculate hit normal from damage position
    local hitNormal = Vector(0, 0, 1)
    if dmg:GetDamagePosition() ~= vector_origin then
        hitNormal = (dmg:GetDamagePosition() - target:GetPos()):GetNormalized()
    end
    
    AA.HitFeedback.LastHitWasKill = isKill
    AA.HitFeedback:AddHit(target:WorldSpaceCenter(), damage, isKill, hitNormal)
end)

-- Blood on the floor decals cleanup
hook.Add("PostDrawOpaqueRenderables", "AA_BloodDecals", function()
    local now = CurTime()
    for i = #AA.HitFeedback.BloodParticles, 1, -1 do
        local p = AA.HitFeedback.BloodParticles[i]
        if now - p.time > p.life then
            table.remove(AA.HitFeedback.BloodParticles, i)
        end
    end
end)

-- Freeze game during hitstop
hook.Add("Think", "AA_HitstopThink", function()
    if AA.HitFeedback:IsHitstopActive() then
        -- Slow down time during hitstop
        game.SetTimeScale(0.1)
    else
        game.SetTimeScale(1)
    end
end)

-- Reset on round end
hook.Add("AA_RoundEnded", "AA_ResetHitFeedback", function()
    AA.HitFeedback.Hits = {}
    AA.HitFeedback.GoreChunks = {}
    AA.HitFeedback.ComboHits = 0
    AA.HitFeedback.HitstopEndTime = 0
    game.SetTimeScale(1)
end)
