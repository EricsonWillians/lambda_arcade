--[[
    CL_WEAPON_ACCURACY - Client-side Weapon Accuracy Feedback
    
    Handles notifications and visual feedback for accuracy-enhanced weapons.
]]

AA = AA or {}
AA.WeaponAccuracy = AA.WeaponAccuracy or {}

-- Receive accuracy enhancement notification
net.Receive("AA_WeaponAccuracy_Enhanced", function()
    local weaponClass = net.ReadString()
    local accuracyMult = net.ReadFloat()
    
    -- Could show a small notification or visual indicator here
    -- For now, just log it in debug mode
    if AA.Debug then
        print(string.format("[AA WeaponAccuracy] %s accuracy enhanced (mult: %.2f)", weaponClass, accuracyMult))
    end
    
    -- Trigger a small hitmarker-style feedback (optional)
    -- This gives the player immediate feedback that their weapon is upgraded
    if AA.FX and AA.FX.PlayWeaponEnhanced then
        AA.FX.PlayWeaponEnhanced()
    end
end)

print("[Arcade Anomaly] Weapon Accuracy client module loaded")
