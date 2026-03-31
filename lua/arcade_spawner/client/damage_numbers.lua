-- addons/arcade_spawner/lua/arcade_spawner/client/damage_numbers.lua
-- Simple damage number display

if not ArcadeSpawner then ArcadeSpawner = {} end
ArcadeSpawner.DamageNumbers = ArcadeSpawner.DamageNumbers or {}
local DamageNumbers = ArcadeSpawner.DamageNumbers

DamageNumbers.Active = {}

net.Receive("ArcadeSpawner_DamageNumber", function()
    local pos = net.ReadVector()
    local dmg = net.ReadInt(16)
    local isKill = net.ReadBool()

    local text = tostring(dmg)
    if isKill then
        text = text .. " キル!"
    else
        text = text .. " ダメ"
    end

    table.insert(DamageNumbers.Active, {
        pos = pos,
        vel = Vector(0, 0, 40),
        text = text,
        start = CurTime(),
        life = 1.2,
        alpha = 255
    })
end)

hook.Add("Think", "ArcadeSpawner_UpdateDamageNumbers", function()
    local ft = FrameTime()
    for i = #DamageNumbers.Active, 1, -1 do
        local d = DamageNumbers.Active[i]
        d.pos = d.pos + d.vel * ft
        local progress = (CurTime() - d.start) / d.life
        d.alpha = 255 * math.Clamp(1 - progress, 0, 1)
        if progress >= 1 then
            table.remove(DamageNumbers.Active, i)
        end
    end
end)

hook.Add("HUDPaint", "ArcadeSpawner_DrawDamageNumbers", function()
    for _, d in ipairs(DamageNumbers.Active) do
        local screen = d.pos:ToScreen()
        if screen.visible ~= false then
            draw.SimpleTextOutlined(d.text, "ArcadeHUD_Large", screen.x, screen.y,
                Color(255, 80, 80, d.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,d.alpha))
        end
    end
end)

print("[Arcade Spawner] ✨ Damage number client module loaded!")
