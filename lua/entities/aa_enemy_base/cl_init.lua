--[[
    Arcade Anomaly: Base Enemy Entity (Client)
    Enhanced visual effects and animation
--]]

include("shared.lua")

function ENT:Initialize()
    -- Client-side init
    self.LastAnimState = -1
    self.EliteGlow = 0
    
    -- Animation smoothing
    self.SmoothYaw = 0
    self.LastPos = self:GetPos()
    self.VelocitySmooth = Vector(0, 0, 0)
    
    -- Footstep timing
    self.NextFootstep = 0
    self.LastFootstepSide = false -- false = left, true = right
end

function ENT:Draw()
    -- Smooth rotation interpolation
    local dt = FrameTime()
    local ang = self:GetAngles()
    self.SmoothYaw = LerpAngle(10 * dt, Angle(0, self.SmoothYaw, 0), ang).yaw
    
    -- Draw with smoothed angles
    local drawAng = Angle(0, self.SmoothYaw, 0)
    self:SetRenderAngles(drawAng)
    self:DrawModel()
    self:SetRenderAngles(ang) -- Reset
    
    -- Elite glow effect
    if self:GetNW2Bool("IsElite") then
        self:DrawEliteGlow()
    end
    
    -- Draw effects based on state
    local state = self:GetNW2Int("AnimState", 0)
    if state == 1 or state == 2 then -- Moving
        self:HandleMovementEffects()
    end
    
    -- Debug info
    if AA and AA.Config and AA.Config.Debug and AA.Config.Debug.ShowNavigationPaths then
        self:DrawDebugInfo()
    end
end

function ENT:DrawEliteGlow()
    -- Pulsing glow for elites
    local pulse = math.sin(CurTime() * 4) * 0.3 + 0.7
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:WorldSpaceCenter()
        dlight.r = 255
        dlight.g = 50 * pulse
        dlight.b = 50 * pulse
        dlight.brightness = 2
        dlight.Decay = 1000
        dlight.Size = 128 * pulse
        dlight.DieTime = CurTime() + 0.05
    end
    
    -- Add sprite glow
    local glowPos = self:WorldSpaceCenter()
    local glowCol = Color(255, 100, 100, 100 * pulse)
    cam.Start3D()
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(glowPos, 40 * pulse, 40 * pulse, glowCol)
    cam.End3D()
end

function ENT:HandleMovementEffects()
    local speed = self:GetNW2Float("MoveSpeed", 0)
    if speed < 10 then return end
    
    -- Footstep sounds based on animation cycle
    local cycle = self:GetCycle()
    local speedRatio = speed / 250
    
    -- Determine footstep timing based on animation
    local footstepInterval = 0.35 / math.max(0.5, speedRatio)
    
    if CurTime() > self.NextFootstep then
        self.NextFootstep = CurTime() + footstepInterval
        self:DoFootstep()
    end
    
    -- Dust particles when running fast
    if speed > 200 and self:IsOnGround() then
        if math.random() < 0.3 * speedRatio then
            local pos = self:GetPos() + Vector(
                math.random(-10, 10),
                math.random(-10, 10),
                5
            )
            
            local effect = EffectData()
            effect:SetOrigin(pos)
            effect:SetNormal(Vector(0, 0, 1))
            effect:SetScale(0.5)
            util.Effect("WheelDust", effect)
        end
    end
end

function ENT:DoFootstep()
    if not self:IsOnGround() then return end
    
    local side = self.LastFootstepSide and "left" or "right"
    self.LastFootstepSide = not self.LastFootstepSide
    
    -- Determine foot position
    local forward = self:GetForward()
    local right = self:GetRight()
    local footOffset = self.LastFootstepSide and -8 or 8
    
    local footPos = self:GetPos() + forward * 10 + right * footOffset
    
    -- Trace for surface type
    local tr = util.TraceLine({
        start = footPos + Vector(0, 0, 10),
        endpos = footPos - Vector(0, 0, 10),
        mask = MASK_SOLID
    })
    
    if tr.Hit then
        -- Footstep sound
        local surfaceProps = tr.SurfaceProps
        local material = util.GetSurfacePropName(surfaceProps)
        
        local snd
        if material:find("concrete") or material:find("rock") then
            snd = "player/footsteps/concrete" .. math.random(1, 4) .. ".wav"
        elseif material:find("metal") then
            snd = "player/footsteps/metal" .. math.random(1, 6) .. ".wav"
        elseif material:find("dirt") or material:find("sand") then
            snd = "player/footsteps/dirt" .. math.random(1, 4) .. ".wav"
        elseif material:find("wood") then
            snd = "player/footsteps/wood" .. math.random(1, 4) .. ".wav"
        else
            snd = "player/footsteps/concrete" .. math.random(1, 4) .. ".wav"
        end
        
        EmitSound(snd, footPos, self:EntIndex(), CHAN_AUTO, 0.4, 60, 0, 100)
        
        -- Small dust puff
        local effect = EffectData()
        effect:SetOrigin(tr.HitPos)
        effect:SetNormal(tr.HitNormal)
        effect:SetScale(0.3)
        util.Effect("Impact", effect)
    end
end

function ENT:DrawDebugInfo()
    local pos = self:WorldSpaceCenter() + Vector(0, 0, 30)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Up(), 180)
    
    cam.Start3D2D(pos, Angle(0, ang.yaw, 90), 0.1)
        local state = self:GetNW2Int("AnimState", 0)
        local stateNames = {"IDLE", "MOVE", "SPRINT", "ATTACK", "PAIN", "DEATH"}
        local stateName = stateNames[state + 1] or "UNKNOWN"
        
        draw.SimpleText(
            "State: " .. stateName,
            "DermaDefault",
            0, 0,
            Color(255, 255, 255),
            TEXT_ALIGN_CENTER
        )
        
        local speed = self:GetNW2Float("MoveSpeed", 0)
        draw.SimpleText(
            "Speed: " .. math.floor(speed),
            "DermaDefault",
            0, 15,
            Color(255, 255, 150),
            TEXT_ALIGN_CENTER
        )
        
        if self:GetNW2Bool("IsElite") then
            draw.SimpleText(
                "ELITE",
                "DermaDefault",
                0, 35,
                Color(255, 100, 100),
                TEXT_ALIGN_CENTER
            )
        end
    cam.End3D2D()
end

function ENT:Think()
    -- Smooth velocity calculation
    local dt = FrameTime()
    local pos = self:GetPos()
    self.VelocitySmooth = LerpVector(5 * dt, self.VelocitySmooth, (pos - self.LastPos) / dt)
    self.LastPos = pos
    
    -- State change effects
    local state = self:GetNW2Int("AnimState", 0)
    if state ~= self.LastAnimState then
        self.LastAnimState = state
        self:OnAnimStateChanged(state)
    end
end

function ENT:OnAnimStateChanged(newState)
    if not AA or not AA.Types then return end
    
    if newState == AA.Types.AnimState.ATTACK then
        -- Attack windup effect
        local effect = EffectData()
        effect:SetOrigin(self:GetPos() + self:GetUp() * 50)
        effect:SetEntity(self)
        util.Effect("MuzzleEffect", effect)
    elseif newState == AA.Types.AnimState.PAIN then
        -- Pain flash
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = self:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 50
            dlight.b = 50
            dlight.brightness = 3
            dlight.Decay = 2000
            dlight.Size = 60
            dlight.DieTime = CurTime() + 0.1
        end
    end
end

-- Animation events from the model
function ENT:DoAnimationEvent(event, data)
    -- Handle footstep events from model
    if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
        -- This would sync with actual model animation events
    end
end
