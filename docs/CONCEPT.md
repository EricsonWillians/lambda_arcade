# CONCEPT.md

## Project Title

**Lambda Arcade**

A fully replayable, score-driven Garry's Mod arcade experience built for speed, pressure, and style. It delivers infinite runs with aggressive pacing, a dark visual identity, and enemy variety powered by workshop models that are presented cleanly and brought to life with polish rather than distortion.

---

## 1. High-Level Vision

Turn Garry's Mod into a **dark, stylish, endlessly replayable arcade survival mode**.

This should not feel like a horror map and it should not depend on cheap atmosphere tricks.

It should feel like:

* fast
* polished
* dangerous
* expressive
* replayable

The fantasy:

> "Boot any map, start a run, and survive against an endless hostile cast of animated workshop creatures, soldiers, monsters, machines, or characters that feel properly alive inside a dark arcade combat loop."

---

## 2. Core Design Pillars

### 2.1 Infinite Arcade Gameplay

The mode should be instantly replayable and effectively endless.

* quick start
* quick death-to-restart flow
* escalating pressure
* scoring that rewards mastery
* run variety through enemy composition and map flow

### 2.2 Dark Through Tone, Not Horror Clichés

Reject the common Garry's Mod horror formula.

Do **not** rely on:

* stalking behavior
* slow pursuit for creepiness
* awkward sudden appearances behind the player
* uncanny glitch effects
* cheap jumpscare pacing

Darkness should come from:

* lighting contrast
* oppressive combat pacing
* strong sound design
* ominous presentation
* elite enemy presence
* stylish death and combat feedback

The tone should feel closer to a **black-metal arcade arena**, a cursed action machine, or a dark combat ritual rather than a haunted map gimmick.

### 2.3 Workshop Models Must Be Given Life

Workshop models are not decoration. They are one of the mod's greatest strengths.

The system should treat them respectfully:

* models should animate properly
* models should be scaled correctly
* models should move convincingly
* models should feel embodied and intentional
* model selection should avoid broken content

The goal is not random absurdity. The goal is to make workshop content feel like it truly belongs in the game loop.

### 2.4 Readable Combat First

Even with visual variety, combat must stay readable.

* behavior archetypes remain consistent
* silhouettes should be understandable where possible
* audio cues and effects must support recognition
* elites must stand out clearly

---

## 3. Gameplay Loop

### Start of Run

When the player starts:

* the map is analyzed
* the HUD fades in cleanly
* score resets
* a short stylish countdown appears
* enemies begin spawning quickly

### Mid-Run

The player:

* fights increasingly dangerous waves or continuous pressure
* earns score through kills and survival
* builds combos and momentum
* responds to tougher enemy mixes over time
* chases personal best or leaderboard goals

### End of Run

On death:

* the run ends cleanly and dramatically
* score tallies instantly
* high score comparison is shown
* restart is offered immediately

The experience should encourage: **one more run**.

---

## 4. Enemy Philosophy

## 4.1 Gameplay Archetypes, Living Presentation

Enemies should still be based on stable gameplay archetypes so the mode stays fair.

Possible archetypes:

* **Grunt**: baseline melee pressure
* **Rusher**: high mobility threat
* **Brute**: high health, area pressure
* **Shooter**: ranged harassment
* **Exploder**: spacing punishment
* **Elite**: powerful rare threat with major score value

The important distinction is that each archetype should be **performed through workshop models with proper life and presence**, not just slapped on carelessly.

## 4.2 Workshop Model Integration Rules

Workshop models should be curated through a validation pipeline.

A valid model should:

* have acceptable scale
* support believable movement/animation presentation
* not have obviously broken materials
* not destroy hitbox readability
* not be too performance-heavy
* fit at least one gameplay archetype reasonably well

The system should maintain:

* approved model pool
* rejected model pool
* optional manual whitelist/blacklist
* class tags such as humanoid, beast, machine, undead, soldier, creature

This allows the mod to build themed enemy sets that feel coherent.

## 4.3 Giving Models Life

This is a major identity feature.

Instead of distorting models with mutations or glitches, the mod should bring them to life through:

* convincing locomotion
* proper animation state transitions
* purposeful spawn presentation
* class-specific movement styles
* quality audio selection
* subtle visual treatment like rim light, eye glow, dust, sparks, smoke, or shadow emphasis where appropriate

Examples:

* a Combine soldier model can feel like a disciplined elite hunter
* a creature model can feel animalistic and aggressive
* a zombie model can feel brutal without becoming generic horror stalking
* a machine model can feel heavy and relentless

The player should feel that these enemies are **inhabiting roles**, not wearing costumes.

---

## 5. Dark Effects Direction

## 5.1 Visual Style

The dark style should be elegant and forceful, not messy.

Use effects like:

* deep contrast
* strong shadows
* restrained bloom/emissive highlights
* muzzle flashes, sparks, embers, smoke, dust, blood where appropriate
* elite auras or subtle class highlights
* dramatic spawn lighting
* stylish kill confirmations

Avoid:

* glitch overlays
* chromatic corruption
* random visual deformation
* surreal mutation effects

The presentation should feel grounded inside Garry's Mod while still feeling more premium and arcade-like than usual.

## 5.2 Combat Feedback

Every combat action should feel satisfying.

Examples:

* hit confirmation effects
* score pops with tasteful animation
* elite death burst with shadow/smoke/embers
* combo escalation with stronger HUD pulse
* boss or event warning with clean dramatic presentation

## 5.3 Audio Identity

The audio should support darkness and intensity.

Use:

* heavy impact sounds
* metallic or ritualistic stingers
* low ambient tension layers
* strong elite spawn warnings
* satisfying kill feedback

Avoid leaning on horror cliché audio such as whisper spam, random scream spam, or fake stalking sound loops.

---

## 6. AI Behavior Direction

## 6.1 No Stalking Behavior

Enemies must not behave like typical GMod horror entities.

Do not design around:

* slowly following the player forever
* freezing and staring for effect
* teleporting behind the player for scares
* passive psychological horror loops

Instead, AI should be:

* assertive
* fast to engage
* pressure-oriented
* spatially active
* reliable on different maps

## 6.2 Personality Through Movement

Different enemy archetypes can feel alive through movement style.

Examples:

* soldiers advance with confidence and bursts of intent
* beasts lunge and cut angles
* machines push steadily and ignore intimidation
* undead brutes commit heavily and overwhelm with momentum

This creates life and character without needing cutscenes or horror scripting.

## 6.3 Map-Agnostic Reliability

AI should work regardless of the current map by using:

* dynamic spawn discovery
* path reachability checks
* anti-stuck recovery
* fallback movement logic when nav data is weak
* adaptive spawn radius based on map geometry

The system should favor reliability over fancy intelligence.

---

## 7. Map Adaptation

At run start, the mod should inspect the current map to determine:

* safe spawn anchors
* player combat space
* enemy approach routes
* congested vs open zones
* suitable active enemy budget

This allows the same mode to feel functional across sandbox, urban, industrial, sci-fi, or custom workshop maps.

---

## 8. Scoring and Replayability

## 8.1 Score System

Points come from:

* kills
* elite kills
* time survived
* combo chains
* special events
* clean wave clears if waves are used

## 8.2 Combo and Momentum

The score system should encourage bold play.

* quick kills build multiplier
* elite kills create score spikes
* inactivity drops combo
* risky positioning can reward more points

This keeps the run active and exciting.

## 8.3 High Score

Must support at least:

* current run score
* local personal best
* optional per-map best
* optional server/global board later

The high score should be visible enough to constantly tempt the player.

---

## 9. UI / HUD Direction

The UI should feel arcadey, sharp, and dark without becoming cluttered.

### Core HUD Elements

* Score
* High Score
* Health / armor if applicable
* Combo meter
* Danger level / wave intensity
* Event or elite notifications

### UI Style

* high readability
* dark palette with strong accent color
* smooth transitions
* minimal wasted space
* elegant typography and paneling

### End Screen

* final score
* best score comparison
* run stats
* instant restart button

A decent UI here means the game feels intentional and addictive, not like a rough sandbox overlay.

---

## 10. Replayability Enhancers

To make the infinite loop stronger, the mod can later include:

### Themed Enemy Sets

Curated packs based on available workshop models, for example:

* military incursion
* undead outbreak
* machine uprising
* occult beasts
* sci-fi invasion

### Special Rounds

* elite surge
* heavy unit round
* ranged swarm round
* darkness round with visibility pressure
* reward round

### Optional Unlockables

Cosmetic only:

* HUD themes
* announcer packs
* score effect styles
* soundtrack variations

---

## 11. Technical Architecture Direction

Suggested systems:

* **Game Director**: pacing, difficulty, enemy budget
* **Map Analyzer**: spawn and space detection
* **Enemy Manager**: spawn, validation, recovery, cleanup
* **Model Registry**: workshop model discovery, validation, tags, whitelist/blacklist
* **Animation/Presentation Layer**: how models are made to feel alive
* **Score Manager**: current score, combos, highscores, persistence
* **UI Manager**: HUD, menus, restart flow, scoreboard
* **AI Controller Layer**: pursuit, pathing, class behavior, stuck recovery

The architecture should treat workshop content as a first-class system, not an afterthought.

---

## 12. Risks and Design Constraints

## 12.1 Workshop Content Is Inconsistent

Some workshop models will be broken, ugly, badly scaled, or unsuitable.

Mitigation:

* strict validation
* user blacklist support
* curated defaults
* class tagging
* safe fallbacks

## 12.2 Readability Can Be Lost

Too much visual variety can confuse the player.

Mitigation:

* archetype-based behaviors
* class indicators
* good sound cues
* elite markers
* restrained presentation

## 12.3 AI Must Survive Bad Maps

Not every map is built for combat.

Mitigation:

* spawn validation
* anti-stuck systems
* adaptive enemy caps
* graceful fallback logic

---

## 13. Recommended MVP

The MVP should prove the core fantasy immediately.

### MVP Features

* endless arcade survival mode
* decent polished HUD
* score + local high score
* 3 to 5 gameplay archetypes
* workshop model pool with validation
* map-agnostic spawn logic
* reliable AI pursuit and stuck recovery
* fast restart loop
* tasteful dark effects and audio

### Post-MVP Features

* combo multiplier depth
* themed enemy packs
* elite types
* map-specific highscores
* leaderboard support
* special rounds and mutators
* advanced animation polish per class

---

## 14. Design Principles Summary

1. **Fun first**
2. **Infinite replayability**
3. **Dark style without horror clichés**
4. **Workshop models treated with care**
5. **Readable arcade combat**
6. **Reliable AI on any map**
7. **Fast restart, strong addiction loop**

---

## 15. Final Concept Statement

**Lambda Arcade** is an endless Garry's Mod arcade survival mod where the player fights through escalating combat against workshop-powered enemies that feel properly alive, animated, and intentional.

Its identity comes from:

* infinite replayable arcade gameplay
* dark but polished presentation
* strong UI and score-chasing loop
* reliable AI across maps
* workshop models integrated flawlessly instead of distorted or wasted

The goal is not horror stalking.

The goal is to create a dark action arcade where Garry's Mod's huge model ecosystem finally feels alive inside a mode worth replaying forever.
