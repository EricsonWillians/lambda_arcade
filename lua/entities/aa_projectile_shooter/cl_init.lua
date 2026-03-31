include("shared.lua")

-- Projectile visibility constants
local GLOW_COLOR = Color(100, 200, 255, 255)
local CORE_COLOR = Color(200, 240, 255, 255)
local TRAIL_COLOR = Color(80, 180, 255, 200)

function ENT:Initialize()
    -- Create a dynamic light for the projectile
    self.DLight = DynamicLight(self:EntIndex())
    if self.DLight then
        self.DLight.Pos = self:GetPos()
        self.DLight.r = 100
        self.DLight.g = 200
        self.DLight.b = 255
        self.DLight.Brightness = 5
        self.DLight.Size = 256
        self.DLight.Decay = 0
        self.DLight.DieTime = CurTime() + 10
    end
    
    -- Particle emitter for trail
    self.Emitter = ParticleEmitter(self:GetPos())
    self.NextParticle = 0
end

function ENT:Draw()
    local pos = self:GetPos()
    
    -- Update dynamic light position
    if self.DLight then
        self.DLight.Pos = pos
        self.DLight.DieTime = CurTime() + 0.1
    end
    
    -- Draw the model (slightly larger)
    self:SetModelScale(2.5)
    self:DrawModel()
    
    -- Draw a glowing sprite core
    cam.Start3D()
        local spritePos = pos + self:GetForward() * 2
        
        -- Outer glow (large, faint)
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(spritePos, 32, 32, Color(80, 160, 255, 150))
        
        -- Middle glow
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(spritePos, 20, 20, Color(120, 200, 255, 200))
        
        -- Bright core
        render.SetMaterial(Material("sprites/light_glow02_add"))
        render.DrawSprite(spritePos, 10, 10, CORE_COLOR)
        
        -- Electric arc effect around projectile
        render.SetMaterial(Material("sprites/physg_glow1"))
        for i = 1, 3 do
            local arcOffset = Vector(
                math.sin(CurTime() * 15 + i * 2) * 8,
                math.cos(CurTime() * 12 + i * 3) * 8,
                math.sin(CurTime() * 10 + i) * 8
            )
            render.DrawSprite(spritePos + arcOffset, 6, 6, Color(150, 220, 255, 180))
        end
    cam.End3D()
end

function ENT:Think()
    if not IsValid(self) then return end
    
    local pos = self:GetPos()
    local vel = self:GetVelocity()
    local speed = vel:Length()
    
    -- Emit particles for trail
    if self.Emitter and CurTime() > self.NextParticle then
        self.NextParticle = CurTime() + 0.015
        
        -- Core trail particle
        local particle = self.Emitter:Add("sprites/light_glow02_add", pos)
        if particle then
            particle:SetDieTime(0.3)
            particle:SetStartSize(12)
            particle:SetEndSize(2)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetColor(100, 200, 255)
            particle:SetVelocity(-vel * 0.3 + VectorRand() * 10)
            particle:SetAirResistance(50)
        end
        
        -- Smoke trail particle
        local smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos - vel:GetNormalized() * 5)
        if smoke then
            smoke:SetDieTime(0.4)
            smoke:SetStartSize(8)
            smoke:SetEndSize(3)
            smoke:SetStartAlpha(100)
            smoke:SetEndAlpha(0)
            smoke:SetColor(150, 200, 255)
            smoke:SetVelocity(-vel * 0.1 + VectorRand() * 20)
            smoke:SetAirResistance(100)
            smoke:SetRoll(math.random() * 360)
        end
        
        -- Spark particles occasionally
        if math.random() < 0.3 then
            local spark = self.Emitter:Add("effects/spark", pos)
            if spark then
                spark:SetDieTime(0.5)
                spark:SetStartSize(3)
                spark:SetEndSize(0)
                spark:SetStartAlpha(255)
                spark:SetEndAlpha(0)
                spark:SetColor(200, 240, 255)
                spark:SetVelocity(VectorRand() * 50 + -vel:GetNormalized() * 30)
                spark:SetGravity(Vector(0, 0, -100))
                spark:SetAirResistance(50)
            end
        end
    end
    
    -- Clean up emitter when entity is removed
    if not IsValid(self) and self.Emitter then
        self.Emitter:Finish()
    end
end

function ENT:OnRemove()
    if self.Emitter then
        self.Emitter:Finish()
    end
    
    -- Create impact effect
    local pos = self:GetPos()
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(self:GetForward())
    effect:SetScale(1)
    util.Effect("cball_explode", effect)
end
