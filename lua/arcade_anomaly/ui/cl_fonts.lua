--[[
    Arcade Anomaly: Enhanced Font System
    Modern arcade-style typography
--]]

-- Main display font (Digital/Sci-fi style)
surface.CreateFont("AA_Huge", {
    font = "Roboto Black",
    size = 96,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Huge_Glow", {
    font = "Roboto Black",
    size = 96,
    weight = 900,
    antialias = true,
    shadow = false,
    additive = true,
    outline = false,
    blursize = 8,
})

surface.CreateFont("AA_Large", {
    font = "Roboto Black",
    size = 56,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Large_Glow", {
    font = "Roboto Black",
    size = 56,
    weight = 900,
    antialias = true,
    blursize = 6,
    additive = true,
})

surface.CreateFont("AA_Medium", {
    font = "Roboto Bold",
    size = 36,
    weight = 700,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Medium_Glow", {
    font = "Roboto Bold",
    size = 36,
    weight = 700,
    antialias = true,
    blursize = 4,
    additive = true,
})

surface.CreateFont("AA_Small", {
    font = "Roboto Medium",
    size = 24,
    weight = 500,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Tiny", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true,
    shadow = false,
})

-- Monospace for scores (OCR-like)
surface.CreateFont("AA_Mono", {
    font = "Share Tech Mono",
    size = 42,
    weight = 400,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Mono_Glow", {
    font = "Share Tech Mono",
    size = 42,
    weight = 400,
    antialias = true,
    blursize = 4,
    additive = true,
})

surface.CreateFont("AA_MonoSmall", {
    font = "Share Tech Mono",
    size = 20,
    weight = 400,
    antialias = true,
    shadow = false,
})

-- Health display
surface.CreateFont("AA_Health", {
    font = "Roboto Black",
    size = 36,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Health_Glow", {
    font = "Roboto Black",
    size = 36,
    weight = 900,
    antialias = true,
    blursize = 8,
    additive = true,
})

surface.CreateFont("AA_Health_Glow", {
    font = "Roboto Black",
    size = 32,
    weight = 900,
    antialias = true,
    blursize = 6,
    additive = true,
})

-- Countdown font
surface.CreateFont("AA_Countdown", {
    font = "Roboto Black",
    size = 120,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Countdown_Glow", {
    font = "Roboto Black",
    size = 120,
    weight = 900,
    antialias = true,
    blursize = 12,
    additive = true,
})

-- Arcade-style title
surface.CreateFont("AA_Title", {
    font = "Orbitron",
    size = 72,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Title_Glow", {
    font = "Orbitron",
    size = 72,
    weight = 900,
    antialias = true,
    blursize = 16,
    additive = true,
})

surface.CreateFont("AA_Subtitle", {
    font = "Orbitron",
    size = 28,
    weight = 700,
    antialias = true,
    shadow = false,
})

-- Kill feed
surface.CreateFont("AA_KillFeed", {
    font = "Roboto Medium",
    size = 18,
    weight = 500,
    antialias = true,
    shadow = false,
})

-- Floating text
surface.CreateFont("AA_Floating", {
    font = "Roboto Bold",
    size = 28,
    weight = 700,
    antialias = true,
    shadow = true,
    shadowoffset = 2,
})

surface.CreateFont("AA_Floating_Big", {
    font = "Roboto Black",
    size = 42,
    weight = 900,
    antialias = true,
    shadow = true,
    shadowoffset = 3,
})

-- Button text
surface.CreateFont("AA_Button", {
    font = "Roboto Bold",
    size = 22,
    weight = 700,
    antialias = true,
    shadow = false,
})

-- Stats/Labels
surface.CreateFont("AA_Label", {
    font = "Roboto",
    size = 14,
    weight = 500,
    antialias = true,
    shadow = false,
    letterSpacing = 2,
})

-- Loading screen specific
surface.CreateFont("AA_Loading_Title", {
    font = "Orbitron",
    size = 48,
    weight = 900,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Loading_Text", {
    font = "Roboto Medium",
    size = 20,
    weight = 500,
    antialias = true,
    shadow = false,
})

surface.CreateFont("AA_Loading_Stage", {
    font = "Roboto Bold",
    size = 16,
    weight = 700,
    antialias = true,
    shadow = false,
    letterSpacing = 3,
})
