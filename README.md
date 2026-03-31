# Arcade Enemy Spawner

Arcade Enemy Spawner is a modular enemy spawning and encounter system for Garry's Mod.
It combines dynamic wave generation, intelligent spawn point analysis and advanced AI
behaviour to deliver fast-paced gameplay on any map. The addon autonomously scales
difficulty, validates custom workshop NPCs and provides a fully featured HUD with
health bars, direction indicators and creepy ambience effects.

## Features

- **Dynamic wave progression** with difficulty tracking that scales enemy counts and
  stats based on player performance.
- **Intelligent spawn distribution** using NavMesh, entity markers and grid analysis
  to place enemies near players while avoiding unfair spawns.
- **Workshop model validation** to automatically include NPCs from installed addons
  with checks for animations and size limits.
- **Advanced enemy AI** including patrolling, flanking and player searching when idle.
- **Arcade-style HUD** showing wave number, remaining enemies, damage numbers in
  Japanese characters and health bars above enemies.
- **Creepy ambience system** that plays atmospheric sounds and screen effects during
  sessions.
- **Loot drops and rarity tiers** providing varied weapons and enemies with
  increasing challenge.

## Installation

1. Clone this repository or download the release archive.
2. Copy the folder `arcade_enemy_spawner` into your `garrysmod/addons` directory.
3. Start Garry's Mod. The addon will initialize automatically on both server and
   client. You can verify initialization in the console.

To update, simply pull the latest changes or replace the folder with the newest
release.

## Starting a Session

Open the in-game console and run:

```text
arcade_start
```

This begins an endless wave session using the current map. Set the convar
`arcade_auto_start 1` to start sessions automatically when the map loads.
Sessions can be stopped with `arcade_stop`.

## Configuration

Server administrators can adjust behaviour with console variables or by editing
`lua/arcade_spawner/core/config.lua`.
Important settings include:

- `arcade_max_enemies` – total enemies allowed at once
- `arcade_spawn_rate` – time between enemy spawns
- `arcade_difficulty_scale` – base multiplier for scaling per wave
- `arcade_workshop_validation` – enable scanning of workshop models
- `arcade_creepy_fx` – toggle ambience filters and sounds

Run `arcade_reload` after modifying settings to reload the system.

## Console Commands

- `arcade_start` – begin a new session
- `arcade_stop` – end the current session
- `arcade_reload` – reload all scripts
- `arcade_validate_workshop` – scan installed workshop addons for NPC models
- `arcade_status` – print a status report to the console

## Development

This repository is self-contained and does not require external dependencies
beyond Garry's Mod. Lua files are organized under `lua/arcade_spawner/` with
client, server and shared modules. Contributions are welcome via pull requests.

## License

This project is provided under the MIT License. See `LICENSE` for details.

