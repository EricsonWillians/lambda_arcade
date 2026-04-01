# Lambda Arcade

A high-octane, endless arcade survival mod for Garry's Mod. Fight through escalating waves of procedurally spawned enemies with workshop-powered models, polished UI feedback, and a competitive score-chasing loop.

![Lambda Arcade Banner](https://img.shields.io/badge/Garry's%20Mod-Arcade%20Mod-red?style=for-the-badge)
![Version](https://img.shields.io/badge/version-2.0-blue?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

## Overview

Lambda Arcade transforms any Garry's Mod map into a dark, stylish arcade combat experience. The mod features:

- **Infinite replayability** with procedurally generated enemy waves
- **Workshop model integration** - uses your installed addons for enemy variety
- **Polished UI** with loading screens, toast notifications, and real-time feedback
- **Score-chasing gameplay** with combos, multipliers, and persistent high scores
- **Six unique enemy archetypes** with distinct behaviors and abilities

## Features

### Core Gameplay

- **Endless Survival Mode**: Fight until you fall - how long can you survive?
- **Dynamic Difficulty**: Enemy health, damage, and spawn rates increase over time
- **Combo System**: Build combos for score multipliers; break them and lose your streak
- **Elite Enemies**: Special variants with enhanced stats and bonus points
- **Persistent High Scores**: Your best runs are saved locally

### Enemy Archetypes

| Enemy | Description | Threat Level |
|-------|-------------|--------------|
| **Chaser** | Basic melee enemy with moderate speed and health | ★★☆☆☆ |
| **Rusher** | Fast enemy with burst speed ability | ★★★☆☆ |
| **Brute** | Slow but powerful with high health and damage | ★★★★☆ |
| **Shooter** | Ranged enemy that maintains distance and fires projectiles | ★★★☆☆ |
| **Exploder** | Explodes on death or contact - keep your distance! | ★★★★☆ |
| **Elite** | Enhanced variant with special abilities and bonus points | ★★★★★ |

### User Interface

#### Loading Screens
- Full-screen loading overlay with animated backgrounds
- Real-time progress bars for async operations
- Multi-stage progress tracking (e.g., "Stage 2/4")
- ETA calculation for long operations
- Smooth fade and slide animations

#### Toast Notifications
- Context-aware feedback for game events
- 7 notification types: Info, Success, Warning, Error, Achievement, Spawn, Score
- Stacking system with smooth slide-in/out animations
- Configurable positions (top-right, center, etc.)

#### HUD Elements
- High-contrast score display with digit formatting
- Combo counter with timer bar
- Threat meter showing enemy pressure
- Kill feed with floating score popups
- Damage vignette for low health
- Wave indicator and enemy counter

#### Game Over Screen
- High-contrast cyan/teal text over GMod's red death screen
- Solid black backgrounds for readability
- Multi-layer text shadows for depth
- Cyan accents (opposite of red on color wheel)

### Workshop Integration

Lambda Arcade automatically discovers and uses workshop models from your installed addons:

- **Auto-discovery** of player models and NPCs
- **Smart validation** to ensure models work correctly
- **Model caching** for faster subsequent loads
- **Fallback system** uses HL2/CS:S models if no workshop content available

## Installation

### Manual Installation

1. Download or clone this repository
2. Copy the `arcade_anomaly` folder to your Garry's Mod addons directory:
   ```
   Steam/steamapps/common/GarrysMod/garrysmod/addons/
   ```
3. Restart Garry's Mod or run `lua_reloadents` in console

### Server Installation

For dedicated servers, install to:
```
garrysmod/addons/arcade_anomaly/
```

Ensure the addon is mounted correctly and all files are transferred.

## Usage

### Starting a Run

- **Menu**: Press `Q` or type `aa_menu` to open the main menu, then click "START RUN"
- **Console**: Type `aa_start` in console

### Controls

| Action | Command |
|--------|---------|
| Open Menu | `Q` or `aa_menu` |
| Start Run | `aa_start` |
| Force Spawn Enemy | `aa_force_spawn [1-6]` |
| Test Loading Screen | `aa_loading_test` |
| Test Notifications | `aa_toast_test` |
| Toggle HUD | `aa_hud_toggle` |

### Admin Commands

| Command | Description |
|---------|-------------|
| `aa_discover_models` | Trigger manual model discovery |
| `aa_model_stats` | Show discovered model statistics |
| `aa_model_list` | List all registered models |
| `aa_force_model <path>` | Force specific model for testing |
| `aa_test_model_anims <path>` | Test model animation sequences |

## Scoring System

- **Base Points**: Earned per kill based on enemy type
- **Combo Multiplier**: Build combos to multiply your score (up to 5x)
- **Elite Bonus**: Extra points for defeating elite enemies
- **Survival Time**: Time survived adds to final score
- **High Score**: Personal best is saved and displayed

### Combo Mechanics

- Start a combo by killing an enemy
- Combo timer (5 seconds) resets with each kill
- Higher combos grant bigger multipliers
- Breaking combo resets multiplier to 1x

## Configuration

### Game Settings (`lua/arcade_anomaly/config/sh_config.lua`)

```lua
AA.Config.Game = {
    CountdownDuration = 3,      -- Seconds before run starts
    BaseEnemyCap = 10,          -- Max enemies at start
    MaxEnemyCap = 25,           -- Absolute maximum
    MinSpawnDistance = 400,     -- Minimum distance from player
    MaxSpawnDistance = 2000,    -- Maximum spawn distance
    SpawnIntervalMin = 0.5,     -- Fastest spawn rate
}
```

### Balance Settings (`lua/arcade_anomaly/config/sh_balance.lua`)

Adjust enemy stats, difficulty scaling, and elite modifiers.

### Loot System (`lua/arcade_anomaly/core/sv_loot.lua`)

- **Guaranteed drops**: Every enemy drops 1-4 items
- **Health pickups**: 25-50 HP per drop
- **Ammo drops**: Doubled/tripled amounts for all weapon types
- **Smart drops**: Health prioritized when low, ammo matches equipped weapon
- **Visual glows**: Enhanced particle effects for visibility
- **Custom pickup handling**: Full amounts delivered on pickup

### Weapon Accuracy (`lua/arcade_anomaly/core/sv_weapon_accuracy.lua`)

- **85% spread reduction** for all hitscan weapons
- **Weapon-specific tuning**: Pistols 92% more accurate, AR2 94%, Crossbow perfect
- **Level scaling**: +2% accuracy per player level
- **Auto-applied**: Weapons enhanced on pickup, spawn, and switch

## Technical Highlights

### Architecture
- **Modular Design**: Clean separation of concerns (AI, Spawning, FX, UI)
- **Event System**: Decoupled communication between systems
- **Networking**: Efficient client-server communication with progress updates
- **Persistence**: Local storage for high scores and model cache

### AI Systems
- **Navigation Grid**: Custom pathfinding for arbitrary maps
- **Behavior Trees**: Per-archetype AI controllers
- **Stuck Recovery**: Automatic detection and resolution
- **Dynamic Difficulty**: Scales with player performance

### Model Discovery
- **Multi-source Scanning**: Workshop, legacy addons, mounted games
- **Async Validation**: Non-blocking model validation
- **Smart Caching**: Remember valid/invalid models across sessions
- **Crash Protection**: Pcall wrappers prevent spawn crashes

## Development

### Testing

#### Interactive Launcher (`test_mod.py`)

A Python 3 launcher for easy testing:

```bash
# Interactive menu
python test_mod.py

# Quick launch (uses last map)
python test_mod.py quick

# Launch specific map
python test_mod.py launch gm_construct

# Dev mode
python test_mod.py dev gm_construct

# Install/remove addon
python test_mod.py install
python test_mod.py remove

# Show status
python test_mod.py status
```

**Features:**
- Remembers last used map
- Pagination for large map lists
- Automatic addon installation on launch
- Map highlighting (construct, flatgrass marked with *)

Or use the shell script:
```bash
./test_mod.sh
```

### Project Structure

```
arcade_anomaly/
├── lua/
│   ├── arcade_anomaly/
│   │   ├── ai/           # AI behavior systems
│   │   ├── config/       # Shared configuration
│   │   ├── core/         # Game logic (HUD, Menus, State)
│   │   ├── fx/           # Effects and feedback
│   │   ├── models/       # Workshop model discovery
│   │   ├── net/          # Networking
│   │   └── ui/           # Loading screens, toasts
│   ├── entities/         # Enemy entity definitions
│   └── autorun/          # Initialization
├── docs/                 # Design documentation
└── materials/sound/      # Assets
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Documentation

- [Concept Document](docs/CONCEPT.md) - High-level design and vision
- [Technical Design](docs/TECHNICAL_DESIGN.md) - Architecture and implementation details
- [Testing Guide](TESTING.md) - How to test the mod

## Requirements

- Garry's Mod (latest version recommended)
- Counter-Strike: Source (optional, for additional models)
- Workshop addons (optional, for enemy variety)

## Credits

- **Developer**: Ericson Willians
- **Inspiration**: Classic arcade survival games, Garry's Mod community

## License

This project is licensed under the MIT License.

## Support

For issues, feature requests, or contributions, please use the [GitHub Issues](https://github.com/EricsonWillians/lambda_arcade/issues) page.

---

**Enjoy the arcade experience!** 🎮⚔️
