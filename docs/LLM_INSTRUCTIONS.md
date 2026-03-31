## GLua / Garry's Mod Coding Instructions

When generating, editing, or reviewing Garry's Mod Lua (GLua) code, treat correctness and API compatibility as more important than speed.

### Source of Truth
The primary reference for GLua behavior, functions, realms, and API usage is the GLua Docs:

- https://samuelmaddock.github.io/glua-docs/

### Mandatory Rule
When in doubt, consult the GLua Docs before making assumptions.

This applies especially to:
- hook names
- entity/NPC/NextBot APIs
- networking functions
- timers
- player/entity lifecycle functions
- rendering/UI functions
- realm-specific behavior (`SERVER`, `CLIENT`, `MENU`, `SHARED`)
- library function signatures
- predicted vs non-predicted behavior
- Garry's Mod specific extensions to Lua

### Behavior Requirements
- Do not invent GLua APIs, hooks, methods, or fields.
- Do not assume a standard Lua function exists in GLua without verification when the usage is GMod-specific.
- Do not guess parameter names, return values, or realm availability.
- If uncertain whether something is clientside, serverside, shared, or menu-only, verify in the docs.
- Prefer documented GLua APIs over generic Lua or Source-engine assumptions.
- When implementing entities, weapons, gamemodes, UI, or networking code, verify the exact functions used.
- When a requested feature depends on undocumented or unclear behavior, say so explicitly and recommend checking the docs before finalizing implementation.

### Decision Policy
If confidence is not high:
1. Check the GLua Docs.
2. Use documented names and behavior.
3. State any remaining uncertainty clearly.
4. Avoid hallucinating missing engine behavior.

### Output Expectations
When producing GLua code:
- keep code compatible with Garry's Mod conventions
- respect realm separation
- prefer maintainable patterns over speculative cleverness
- include brief comments only where they help explain non-obvious GMod behavior
- avoid presenting unverified code as certain

### Practical Heuristic
For any Garry's Mod-specific task, assume the docs should be consulted unless the API usage is already fully confirmed.