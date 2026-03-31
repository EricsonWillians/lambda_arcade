# Arcade Anomaly: Testing Guide

## Quick Start

```bash
# Install the addon to GMod (creates symlink)
./test_mod.sh install

# Launch and test
./test_mod.sh launch gm_construct

# Or launch in developer mode with console
./test_mod.sh dev gm_construct
```

## Available Commands

| Command | Description |
|---------|-------------|
| `install` | Symlinks addon to GMod's addons folder |
| `remove` | Removes addon from GMod |
| `reinstall` | Remove + Install |
| `status` | Shows installation status and file counts |
| `launch [map]` | Launches GMod with the addon |
| `dev [map]` | Launches in developer mode (-console -dev 2) |
| `test` | Validates Lua syntax and required files |
| `watch` | Watches for file changes (requires inotify-tools) |
| `package` | Creates a distributable zip file |

## Developer Console Commands

Once in-game, open console (`~`) and use these commands:

### Run Management
```
aa_start          # Start a new run (or use menu)
aa_restart        # Restart current run
```

### Spawning (Admin only)
```
aa_force_spawn [archetype]     # Force spawn enemy type (1-6)
aa_enemy_count                 # Show alive enemy counts
aa_enemy_clear                 # Remove all enemies
```

### Director Control (Admin only)
```
aa_director_force_surge        # Trigger elite surge event
aa_director_set_cap [number]   # Set enemy cap manually
```

### Model Management (Admin only)
```
aa_model_list                  # List registered models
aa_model_add [path]            # Add a workshop model
aa_model_blacklist [path]      # Blacklist a model
aa_model_validate [path]       # Validate a model
```

### Debug Visualization
```
aa_debug_anchors 1             # Show spawn anchors
aa_debug_paths 1               # Show navigation paths
aa_debug_stuck 1               # Show stuck recovery
```

### Persistence (Admin only)
```
aa_reset_highscores            # Reset all high scores
aa_export_data                 # Export data to JSON
```

## Enemy Archetype IDs

| ID | Name | Description |
|----|------|-------------|
| 1 | Chaser | Basic melee enemy |
| 2 | Rusher | Fast burst enemy |
| 3 | Brute | Heavy tank |
| 4 | Shooter | Ranged enemy |
| 5 | Exploder | Suicide enemy |
| 6 | Elite | Special ability enemy |

## Example Test Workflows

### Test Basic Combat
```bash
./test_mod.sh dev gm_construct
# In console:
map gm_construct
aa_force_spawn 1    # Spawn chaser
aa_force_spawn 2    # Spawn rusher
```

### Test Difficulty Scaling
```bash
./test_mod.sh dev gm_flatgrass
# In console:
aa_director_set_cap 20    # High enemy count
aa_director_force_surge   # Trigger elite wave
```

### Validate Changes
```bash
# After making code changes:
./test_mod.sh test       # Check for syntax errors
./test_mod.sh reinstall  # Reinstall if needed
```

## Maps Recommended for Testing

- `gm_construct` - Good for basic testing
- `gm_flatgrass` - Open space for AI movement
- `gm_bigcity` - Large urban environment
- `ph_restaurant` - Indoor/CQB testing

## Troubleshooting

### Addon not loading
```bash
./test_mod.sh status      # Check if installed
./test_mod.sh reinstall   # Try reinstalling
```

### Lua errors
```bash
./test_mod.sh test        # Validate syntax
# Or check GMod console for error details
```

### Stuck enemies
```bash
# Enable debug visualization:
aa_debug_stuck 1
aa_debug_anchors 1
```

## Packaging for Release

```bash
./test_mod.sh test        # Validate everything
./test_mod.sh package     # Create zip file
```

The packaged zip can be distributed and installed by users to their `garrysmod/addons/` folder.
