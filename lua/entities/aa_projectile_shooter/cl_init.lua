include("shared.lua")

-- Projectile render constants
local CORE_COLOR = Color(200, 240, 255, 255)
local GLOW_COLOR = Color(100, 200, 255, 200)
local PULSE_SPEED = 15

function ENT:Initialize()
    -- Create dynamic light
    self.DLight = DynamicLight(self:EntIndex())
    if self.DLight then
        self.DLight.Pos = self:GetPos()
        self.DLight.r = 100
        self.DLight.g = 200
        self.DLight.b = 255
        self.DLight.Brightness = 8
        self.DLight.Size = 300
        self.DLight.Decay = 0
        self.DLight.DieTime = CurTime() + 10
    end
    
    -- Initialize pulse
    self.Pulse = 0
    self.SpinAngle = 0
end

function ENT:Draw()
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    -- Update dynamic light
    if self.DLight then
        self.DLight.Pos = pos
        self.DLight.DieTime = CurTime() + 0.1
    end
    
    -- Pulsing glow effect
    self.Pulse = self.Pulse + FrameTime() * PULSE_SPEED
    local pulseScale = 1 + math.sin(self.Pulse) * 0.2
    
    -- Spin animation
    self.SpinAngle = self.SpinAngle + FrameTime() * 360
    
    -- Draw main model (already scaled 3x on server)
    self:DrawModel()
    
    -- Draw multiple glow layers for visibility
    cam.Start3D()
        local basePos = pos + self:GetForward() * 5
        
        -- OUTER GLOW - massive faint halo
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(basePos, 80 * pulseScale, 80 * pulseScale, 
            Color(80, 160, 255, 100))
        
        -- MIDDLE GLOW
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(basePos, 50 * pulseScale, 50 * pulseScale, 
            Color(120, 200, 255, 180))
        
        -- CORE GLOW - bright center
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(basePos, 25 * pulseScale, 25 * pulseScale, 
            Color(200, 240, 255, 255))
        
        -- SPINNING ENERGY RINGS
        for i = 1, 3 do
            local ringAngle = self.SpinAngle + (i * 120)
            local ringOffset = Vector(
                math.cos(math.rad(ringAngle)) * 15,
                math.sin(math.rad(ringAngle)) * 15,
                0
            )
            ringOffset:Rotate(ang)
            
            render.SetMaterial(Material("sprites/physg_glow1"))
            render.DrawSprite(basePos + ringOffset, 12, 12,
                Color(150, 220, 255, 200))
        end
        
        -- ELECTRIC ARCS orbiting the projectile
        for i = 1, 5 do
            local arcTime = CurTime() * 20 + i * 72
            local arcOffset = Vector(
                math.cos(math.rad(arcTime)) * 20,
                math.sin(math.rad(arcTime)) * 20,
                math.sin(math.rad(arcTime * 1.5)) * 10
            )
            arcOffset:Rotate(ang)
            
            render.SetMaterial(Material("sprites/physbeama"))
            render.DrawSprite(basePos + arcOffset, 8, 8,
                Color(200, 255, 255, 220))
        end
        
        -- WARNING RING - rotating red ring for danger indication
        render.SetMaterial(Material("sprites/light_glow02_add"))
        local warningAngle = CurTime() * 180
        for i = 1, 8 do
            local angle = warningAngle + i * 45
            local rad = math.rad(angle)
            local warnPos = basePos + Vector(
                math.cos(rad) * 35,
                math.sin(rad) * 35,
                0
            )
            warnPos:Rotate(ang)
            
            render.DrawSprite(warnPos, 6, 6, Color(255, 100, 100, 150))
        end
    cam.End3D()
end

function ENT:Think()
    -- Emit particles
    if not self.Emitter then
        self.Emitter = ParticleEmitter(self:GetPos())
    end
    
    local pos = self:GetPos()
    local vel = self:GetVelocity()
    
    -- Core energy particles
    if math.random() < 0.8 then
        local particle = self.Emitter:Add("sprites/light_glow02_add", pos)
        if particle then
            particle:SetDieTime(0.3)
            particle:SetStartSize(20)
            particle:SetEndSize(5)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetColor(100, 200, 255)
            particle:SetVelocity(-vel:GetNormalized() * 50 + VectorRand() * 20)
            particle:SetAirResistance(100)
        end
    end
    
    -- Smoke trail
    if math.random() < 0.5 then
        local smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), 
            pos - vel:GetNormalized() * 10)
        if smoke then
            smoke:SetDieTime(0.5)
            smoke:SetStartSize(10)
            smoke:SetEndSize(4)
            smoke:SetStartAlpha(80)
            smoke:SetEndAlpha(0)
            smoke:SetColor(100, 180, 255)
            smoke:SetVelocity(-vel:GetNormalized() * 30 + VectorRand() * 15)
            smoke:SetAirResistance(150)
            smoke:SetRoll(math.random() * 360)
        end
    end
    
    -- Spark particles
    if math.random() < 0.4 then
        local spark = self.Emitter:Add("effects/spark", pos)
        if spark then
            spark:SetDieTime(0.6)
            spark:SetStartSize(4)
            spark:SetEndSize(0)
            spark:SetStartAlpha(255)
            spark:SetEndAlpha(0)
            spark:SetColor(200, 240, 255)
            spark:SetVelocity(VectorRand() * 100 + -vel:GetNormalized() * 50)
            spark:SetGravity(Vector(0, 0, -200))
            spark:SetAirResistance(50)
        end
    end
    
    -- Ring shockwave effect occasionally
    if math.random() < 0.1 then
        local ring = self.Emitter:Add("sprites/light_glow02_add", pos)
        if ring then
            ring:SetDieTime(0.4)
            ring:SetStartSize(10)
            ring:SetEndSize(60)
            ring:SetStartAlpha(150)
            ring:SetEndAlpha(0)
            ring:SetColor(150, 220, 255)
            ring:SetVelocity(Vector(0, 0, 0))
            ring:SetAirResistance(0)
        end
    end
end

function ENT:OnRemove()
    -- Clean up emitter
    if self.Emitter then
        self.Emitter:Finish()
    end
    
    -- Big impact effect
    local pos = self:GetPos()
    
    -- Explosion effect
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(self:GetForward())
    effect:SetScale(3)
    util.Effect("cball_explode", effect)
    
    -- Flash
    local flash = EffectData()
    flash:SetOrigin(pos)
    flash:SetMagnitude(2)
    util.Effect("Explosion", flash)
    
    -- Light burst
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.Pos = pos
        dlight.r = 100
        dlight.g = 200
        dlight.b = 255
        dlight.Brightness = 10
        dlight.Size = 400
        dlight.Decay = 1000
        dlight.DieTime = CurTime() + 0.2
    end
end
