# TECHNICAL_DESIGN.md

## Project

**Lambda Arcade**

A technical design for a Garry's Mod arcade survival mod focused on infinite replayability, dark polished presentation, workshop-model-driven enemies, reliable AI across arbitrary maps, and a strong score-chasing loop.

---

## 1. Technical Objectives

This document defines how to implement the core fantasy in a way that is robust inside Garry's Mod.

Primary objectives:

* infinite arcade gameplay loop
* stable enemy spawning on most maps
* AI that can function even when map quality is inconsistent
* workshop models that feel alive instead of broken or decorative
* polished HUD and run flow
* persistent high score support
* graceful fallback behavior when workshop content is invalid

---

## 2. Core Architecture Overview

Recommended top-level systems:

* **GameMode Core**
* **Run State Manager**
* **Game Director**
* **Map Analyzer**
* **Spawn Manager**
* **Enemy Manager**
* **Enemy Archetype System**
* **Workshop Model Registry**
* **Presentation / Animation Layer**
* **AI Controller Layer**
* **Score Manager**
* **Persistence Manager**
* **HUD / UI Manager**
* **Effects / Audio Manager**

A clean separation matters because Garry's Mod projects become fragile quickly when game logic, entity logic, and UI logic are tightly coupled.

---

## 3. Recommended Folder Structure

Example structure for a maintainable addon:

```text
lua/
  autorun/
    aa_init.lua
    aa_client_init.lua

  arcade_anomaly/
    config/
      sh_config.lua
      sh_balance.lua
      sh_enemy_tags.lua

    core/
      sh_types.lua
      sh_util.lua
      sv_run_state.lua
      sv_game_director.lua
      sv_map_analyzer.lua
      sv_spawn_manager.lua
      sv_enemy_manager.lua
      sv_score_manager.lua
      sv_persistence.lua
      cl_hud.lua
      cl_menus.lua
      cl_scoreboard.lua
      sh_events.lua

    ai/
      sv_ai_base.lua
      sv_ai_chaser.lua
      sv_ai_rusher.lua
      sv_ai_brute.lua
      sv_ai_shooter.lua
      sv_ai_exploder.lua
      sv_ai_elite.lua
      sv_navigation.lua
      sv_stuck_recovery.lua

    models/
      sv_model_registry.lua
      sh_model_tags.lua
      sv_model_validation.lua
      sv_model_cache.lua

    entities/
      entities/
        aa_enemy_base/
        aa_enemy_chaser/
        aa_enemy_rusher/
        aa_enemy_brute/
        aa_enemy_shooter/
        aa_enemy_exploder/
        aa_enemy_elite/

    fx/
      sh_fx_defs.lua
      sv_fx_dispatch.lua
      cl_fx.lua
      cl_postrun.lua
      cl_hit_feedback.lua

    net/
      sh_net.lua

    ui/
      cl_fonts.lua
      cl_panels.lua
      cl_endscreen.lua
      cl_settings.lua
```

This keeps server/client/shared responsibilities readable.

---

## 4. Game Flow State Machine

The run loop should be driven by a simple but explicit state machine.

Recommended states:

* `IDLE`
* `PREPARING_MAP`
* `COUNTDOWN`
* `RUNNING`
* `PLAYER_DEAD`
* `RUN_SUMMARY`
* `RESTARTING`

### State Behavior

#### IDLE

* waiting for player to start run
* UI visible
* no enemy activity

#### PREPARING_MAP

* analyze map
* compute spawn anchors
* reset score/run data
* warm model pool if needed

#### COUNTDOWN

* short countdown (2 to 4 seconds)
* lock enemy spawn until countdown completes

#### RUNNING

* active enemy spawning
* scoring enabled
* director scaling active

#### PLAYER_DEAD

* stop new enemy spawns
* allow existing cleanup or brief freeze
* capture final score

#### RUN_SUMMARY

* show end screen
* compare highscores
* offer instant restart

#### RESTARTING

* clear enemies
* reset player state
* return to `PREPARING_MAP`

This prevents messy ad hoc transitions.

---

## 5. Entity Model: Why Custom Enemies Are Best

To make workshop models work flawlessly, the safest design is:

### Use custom enemy entities with workshop models as presentation assets

Do **not** rely primarily on arbitrary workshop NPCs for the core loop.

Reason:

* workshop NPC logic is inconsistent
* many addon NPCs are poorly balanced
* some have broken schedules or animation issues
* some assume map-specific behavior
* some are too expensive to run in large numbers

Instead:

* gameplay logic lives in **your own entities**
* workshop models are assigned onto those entities after validation
* animation, collision, movement, hit reactions, and class behavior remain under your control

This is the most important architectural decision in the whole project.

---

## 6. Enemy Entity Architecture

## 6.1 Base Entity

Create a shared base entity, for example:

* `aa_enemy_base`

Responsibilities:

* health / damage handling
* score value
* enemy archetype identity
* target acquisition hooks
* spawn/despawn lifecycle
* presentation hooks
* stuck tracking
* movement mode support
* networked state for client effects

Core fields:

* `Archetype`
* `Health`
* `MaxHealth`
* `MoveSpeed`
* `Damage`
* `ScoreValue`
* `ModelId`
* `ThreatLevel`
* `IsElite`
* `SpawnTime`
* `LastProgressTime`
* `LastKnownTargetPos`

## 6.2 Derived Enemy Classes

Each gameplay archetype should derive from the base:

* `aa_enemy_chaser`
* `aa_enemy_rusher`
* `aa_enemy_brute`
* `aa_enemy_shooter`
* `aa_enemy_exploder`
* `aa_enemy_elite`

These subclasses should change:

* target behavior
* speed/health profile
* attack logic
* preferred engagement distance
* animation selection priorities
* audio profile

Behavior logic should differ even if presentation assets overlap.

---

## 7. AI Design Strategy

## 7.1 Preferred Approach

Best practical approach:

### Hybrid custom AI with navmesh support when available

Use:

* direct chase / steering when possible
* navmesh/pathfinding when available and useful
* fallback logic when navmesh is missing or poor

This is more robust than assuming perfect navmesh or relying only on base NPC schedules.

## 7.2 AI Loop Responsibilities

Per enemy think/update cycle:

* validate target
* decide desired movement mode
* update path or steering goal
* check attack conditions
* update stuck state
* update animation state
* update presentation state

## 7.3 Target Selection

For MVP, simplest rule:

* target nearest alive player

Later extensions:

* threat-based targeting
* anti-camping pressure targeting
* elite preference logic

## 7.4 Movement Styles by Archetype

### Chaser

* direct pursuit
* moderate speed
* low hesitation

### Rusher

* fast bursts
* short attack windup
* angle-cutting movement

### Brute

* steady push
* low responsiveness but high commitment
* breaks safe space

### Shooter

* maintain preferred distance
* reposition when too close
* line-of-sight checks

### Exploder

* strongest pursuit commitment
* detonation on range threshold or death

### Elite

* enhanced path updates
* more reliable pursuit
* greater anti-stuck tolerance

---

## 8. Navigation and Map-Agnostic Behavior

## 8.1 Problem Reality

Garry's Mod maps vary wildly:

* some have navmesh
* some do not
* some have awful geometry for NPCs
* some are huge and empty
* some are tiny and cluttered

So the AI system must be designed around resilience.

## 8.2 Map Analysis Pass

At run start, perform a map scan.

Inputs to inspect:

* player spawn positions
* `info_player_start`
* `info_player_deathmatch`
* broad walkable surfaces around live player positions
* nav areas if present
* traces to detect floor support and enclosure

Outputs to compute:

* spawn anchors
* danger zones near player spawn
* fallback enemy spawn nodes
* map openness score
* recommended enemy cap range
* recommended spawn radius range

## 8.3 Spawn Anchors

A spawn anchor is a validated region from which enemies can enter the play loop.

Each anchor should track:

* position
* last usage time
* success count
* failure count
* reachability confidence
* average time to engage player

Over time, anchors that produce broken or stuck enemies should be deprioritized automatically.

## 8.4 Path Validation

Before accepting a spawn point, run checks like:

* hull trace for collision validity
* floor support trace
* distance from player minimum threshold
* maximum distance threshold
* line or path feasibility toward player zone

## 8.5 Fallback Movement Logic

When formal nav/pathing is weak:

* move toward last known target direction
* use obstacle avoidance traces
* periodically re-sample route
* allow short corrective teleport for permanently invalid stuck cases

This is preferable to letting enemies freeze forever.

---

## 9. Anti-Stuck and Recovery System

This is mandatory.

Each enemy should track movement progress:

* distance traveled over recent time window
* whether target remains valid
* number of failed path updates
* time since last meaningful progress

Recovery tiers:

### Tier 1: Repath

* recompute movement goal

### Tier 2: Local nudge

* try alternate nearby offset

### Tier 3: Micro-reposition

* small safe relocation within local area

### Tier 4: Hard recovery

* despawn and respawn through a valid anchor

Do not overuse hard teleport visibly. Prefer silent correction when possible.

---

## 10. Workshop Model Registry

## 10.1 Registry Responsibilities

The model system should not simply pick random workshop models blindly.

A dedicated registry should:

* discover candidate models
* validate them
* classify them
* cache decisions
* expose filtered pools by archetype/tag

## 10.2 Registry Data Structure

Each model entry can include:

* `path`
* `display_name`
* `source_addon`
* `scale_class`
* `tags`
* `humanoid_like`
* `beast_like`
* `machine_like`
* `material_ok`
* `animation_ok`
* `collision_ok`
* `approved`
* `blacklisted`
* `preferred_archetypes`
* `performance_cost`

## 10.3 Validation Pipeline

On first discovery or admin refresh:

1. verify model path exists
2. instantiate temporary server-side test entity if needed
3. inspect bounds
4. detect absurd dimensions
5. test sequence availability
6. validate material presence if possible
7. classify rough silhouette / tag grouping manually or semi-manually
8. store approval result

Because Garry's Mod model ecosystems are messy, manual curation support should exist.

## 10.4 Model Pool Selection

When assigning a model to an enemy:

* filter by approved status
* filter by archetype compatibility
* filter by optional theme pack
* apply anti-repetition weighting

This prevents ugly random repetition and improves overall tone.

---

## 11. Making Workshop Models Feel Alive

This is one of the defining systems.

## 11.1 Key Principle

The model must be part of a believable combat actor.

That means the mod must control:

* movement rhythm
* animation state switching
* facing direction
* attack windup timing
* hit reactions
* spawn presentation
* death presentation

## 11.2 Animation State Layer

Each enemy should expose simple semantic states:

* `Idle`
* `Move`
* `Sprint`
* `Attack`
* `Pain`
* `Death`
* `Special`

The presentation layer maps these semantic states onto best-fit sequences for the chosen model.

For example:

* if a model has proper run sequence, use it
* if not, fall back to walk or generic locomotion
* if attack sequence missing, use class fallback timing and minimal gesture behavior

The actor should never feel fully static unless intentionally paused.

## 11.3 Spawn Presentation

When enemies spawn, do not just pop them into existence with no ceremony.

Use a short polished presentation, for example:

* shadow arrival
* dust kickup
* smoke vent burst
* ground impact
* portal-like effect only if it fits theme

Keep it fast so it remains arcade-friendly.

## 11.4 Hit and Death Reactions

To give presence:

* enemies should react to damage directionally if feasible
* elites should have heavier reactions
* deaths should feel class-appropriate
* ragdolls or controlled death effects should not be sloppy

A brute should die differently from a rusher.

## 11.5 Class-Specific Presence

Examples:

### Soldier-like models

* confident forward pressure
* sharper turn rates
* disciplined attack pacing

### Beast-like models

* lower posture feel
* burst movement
* aggressive lunge attacks

### Machine-like models

* heavy step feel
* stable motion
* sparks or metallic impact sounds

### Undead-like models

* momentum-heavy aggression
* brutal commitment
* weighty death presentation

This is where workshop models stop feeling like random props.

---

## 12. Game Director

The Game Director is responsible for pacing and replayability.

Inputs:

* elapsed run time
* current score
* current combo rate
* number of alive enemies
* player performance
* map openness score
* spawn anchor success data

Outputs:

* enemy budget
* spawn cadence
* elite chance
* archetype mix
* event triggers
* temporary pressure surges

## 12.1 Scaling Logic

Difficulty should not just be "spawn more forever."

Scale using a mix of:

* active cap increase
* spawn interval reduction
* archetype variety increase
* elite probability rise
* occasional special rounds

This creates a better curve.

## 12.2 Fairness Constraints

Director rules should prevent:

* impossible point-blank spawns
* repeated anchor spam
* overstacking ranged enemies on tiny maps
* too many brutes on cramped maps

---

## 13. Spawn Manager

The Spawn Manager turns director budget into actual enemy entities.

Responsibilities:

* choose archetype to spawn
* choose anchor
* validate spawn
* assign approved model
* initialize presentation state
* register entity with Enemy Manager

Spawn logic should consider:

* current player position
* visibility fairness
* enemy cap
* anchor cooldowns
* map size profile
* recent archetype repetition

---

## 14. Enemy Manager

Responsibilities:

* track all live enemies
* prune invalid entities
* process cleanup on run end
* maintain elite counts
* expose alive count to HUD and director
* coordinate hard recovery/despawn

Useful methods:

* `SpawnEnemy(archetype, anchor)`
* `DespawnEnemy(ent, reason)`
* `GetAliveEnemies()`
* `GetAliveCountByArchetype()`
* `CleanupAllEnemies()`

---

## 15. Score System Design

## 15.1 Core Score Sources

* kill score
* elite kill bonus
* survival tick bonus
* combo multiplier
* special event rewards
* close-range or style bonuses later if desired

## 15.2 Combo System

Track:

* current combo
* combo timer
* highest combo this run
* multiplier

Rules:

* kills refresh timer
* timer decays quickly enough to force momentum
* elites give bigger combo extension or bonus

## 15.3 Score Events

Use explicit server-driven events such as:

* `ENEMY_KILLED`
* `ELITE_KILLED`
* `SURVIVAL_TICK`
* `COMBO_INCREASED`
* `SPECIAL_ROUND_CLEARED`

This makes balancing easier.

---

## 16. Persistence and Highscore

## 16.1 MVP Persistence

At minimum persist:

* local best score
* optional per-map best
* settings
* approved/blacklisted model cache

Possible storage:

* Garry's Mod data folder via JSON

Examples:

* `data/arcade_anomaly/highscores.json`
* `data/arcade_anomaly/settings.json`
* `data/arcade_anomaly/model_cache.json`

## 16.2 Data Model

Example highscore structure:

```json
{
  "global_best": 482300,
  "best_by_map": {
    "gm_construct": 210440,
    "gm_flatgrass": 182900
  },
  "last_run": {
    "score": 89120,
    "time_survived": 412,
    "kills": 203,
    "highest_combo": 17
  }
}
```

Later, server-side leaderboards can be added behind a clean persistence interface.

---

## 17. HUD and UI Technical Plan

## 17.1 HUD Requirements

Real-time HUD should show:

* score
* high score
* health
* combo
* danger level or wave intensity
* elite/event warnings
* alive enemy pressure indicator if useful

## 17.2 UI Principles

* must be readable while moving fast
* must not cover core aim space excessively
* large typography for score
* animated but restrained transitions
* dark palette with strong accent color

## 17.3 Networked UI Data

Send only what is needed.

Examples:

* current score
* best score
* combo state
* run state
* event banners
* elite warning payload

Keep the client-side UI mostly presentational.

## 17.4 End Screen

Data to show:

* final score
* best score comparison
* kills
* survival time
* highest combo
* elite kills
* restart prompt

The end screen should appear fast and feel rewarding.

---

## 18. Effects and Audio System

## 18.1 Effects Direction

Dark, clean, punchy.

Examples:

* kill popups
* impact sparks/dust/blood depending on class
* elite spawn stinger with lighting emphasis
* combo pulse on HUD
* smoke/embers/shadow burst on heavy kills

Avoid noisy or messy effects that hide gameplay.

## 18.2 Audio Routing

Suggested categories:

* UI sounds
* kill confirms
* enemy movement/attack sounds
* elite warnings
* event stingers
* background intensity layers

Audio should communicate game state, not just decorate it.

---

## 19. Networking Strategy

Server authoritative for:

* score
* enemy spawn/despawn
* AI decisions
* highscore updates
* run state

Client handles:

* HUD drawing
* local polish effects
* sound playback based on server events

This reduces desync and prevents score abuse in multiplayer scenarios later.

---

## 20. Multiplayer Considerations

Even if MVP is single-player focused, design cleanly for future multiplayer.

Potential adjustments later:

* target selection across multiple players
* score ownership or team score modes
* revive/co-op rules
* enemy scaling by player count
* leaderboard sync

The director and enemy systems should avoid assuming only one player exists.

---

## 21. Debug Tooling

Strong debug tooling will save the project.

Useful debug commands/features:

* show spawn anchors
* show failed anchors
* print current enemy counts by archetype
* force spawn archetype
* validate workshop model manually
* toggle nav/path debug lines
* print stuck recovery events
* reset highscore
* run map analysis report

This is especially important when trying to support arbitrary maps.

---

## 22. Recommended MVP Implementation Order

### Phase 1: Core Loop

* run state machine
* score manager
* one enemy archetype
* simple spawn logic
* death/restart flow

### Phase 2: Reliable Combat

* 3 to 5 archetypes
* map analyzer
* spawn anchors
* anti-stuck system
* director scaling

### Phase 3: Workshop Model Life

* model registry
* validation cache
* archetype compatibility filters
* animation state layer
* presentation polish

### Phase 4: UI and Persistence

* final HUD
* end screen
* local highscore save
* settings panel

### Phase 5: Replayability

* elites
* special rounds
* themed packs
* better audio layering

This order reduces risk and proves the fun early.

---

## 23. Recommended Engineering Rules

1. Never bind core gameplay to third-party NPC logic.
2. Treat workshop models as presentation assets filtered through your rules.
3. Every enemy must be recoverable if stuck.
4. Every map system must degrade gracefully.
5. Prefer robust simple AI over fancy fragile AI.
6. Score and run flow should always feel immediate.
7. Effects should amplify readability, not bury it.

---

## 24. Final Technical Statement

The cleanest way to realize **Lambda Arcade** is to build a custom arcade combat framework whose gameplay logic is fully owned by the mod, while workshop models are integrated through a curated presentation pipeline.

That approach makes it possible to achieve all of the critical goals at once:

* workshop models that feel alive
* reliable AI across different maps
* infinite replayability
* dark polished presentation
* a score loop worth mastering

In practice, the heart of the project is not "random workshop enemies."

It is a **controlled combat architecture** that gives workshop content real purpose, motion, and identity.
