# Ashen Oath — Mobile Combat Prototype

Fresh Godot 4.7.2 project. A mobile-first 3D action game prototype with Sekiro-inspired combat, not affiliated with FromSoftware or Sekiro.

## Architecture progress
- Fighter assembly is isolated in `scripts/factories/fighter_factory.gd`; it builds physics, rig, weapon pivots, sentinel navigation, and boss armor.
- World generation is isolated in `scripts/world/world_builder.gd`; main-scene node paths remain compatible.
- Player debug keyboard dispatch and third-person camera behavior are isolated in `scripts/input/player_input_router.gd` and `scripts/camera/combat_camera_rig.gd`.
- Sentinel navigation, perception, awareness, patrol decisions, and local separation are split across focused modules in `scripts/ai/`.
- Swimming, climbing, ledge traversal, grappling, vaulting, mantling, wall-hug, crouch, and cover-transfer movement are isolated in `scripts/traversal/fighter_traversal_controller.gd`.
- Prosthetic effects/upgrades and shrine/cache/resurrection interactions are isolated in `scripts/prosthetics/` and `scripts/exploration/`.
- Player movement, cover transfer, wall-hug, and facing are isolated in `scripts/movement/fighter_locomotion_controller.gd`.
- Strike reception, deflect/counter outcomes, hit reactions, posture breaks, and death transitions are isolated in `scripts/combat/fighter_combat_resolution.gd`; attack hit volumes/combo buffering and defensive/execution actions live in separate combat controllers.
- Procedural rig binding, gait, attack/guard/hit/death poses, and animation blending are isolated in `scripts/animation/fighter_animation_controller.gd`.
- Fighter archetype tuning is data-driven through `FighterConfig` resources for the player, sentinel, and Ashen Warlord. Encounter spawn points, patrol routes, cover, grapple anchors, water, climb wall, shrines, and cache placements live in `resources/encounters/ashen_vale.tres`.
- Hitstop, impact-camera requests, deflect clash VFX, and spatial combat SFX are delegated to `scripts/services/combat_feedback_service.gd`.
- `main.gd` focuses on encounter orchestration and connects the world, camera, input, and feedback services. `fighter.gd` is now a compact gameplay façade (573 lines): core physics/state progression stays there while feature behavior is delegated to focused controllers.
- No Android package was exported as part of this refactor; export/device validation is intentionally pending until explicit authorization.

## Current milestone
- Godot 4.7.2 mobile-first 3D action prototype with Vitality/Posture combat, buffered combos, deflects, Mikiri/sweep counters, hitstop, and a two-phase boss.
- Procedural third-person arena, primitive articulated fighter rigs, lock-on footwork, directional dodge, and adaptive camera framing.
- Touch HUD with virtual stick, camera drag, combat actions, crouch, stealth deathblow, vault, ledge mantle, wall-hug corner wrapping, and crouched cover-to-cover movement (keyboard B / touchscreen COVER).
- Sentinel patrols, vision-cone awareness, noise investigation, physical cover concealment, and multi-point cover investigation after losing sight; guards can escalate again if inspection restores direct line of sight.
- Four prototype prosthetic tools: forward-arc shuriken (ranged chip damage), firecracker (guard distraction/stagger), close-range axe (heavy vitality/posture impact), and timed umbrella guard. Spirit-emblem energy is displayed in the touch HUD and regenerates gradually; keyboard shortcuts 1–4 mirror the four touch actions.
- Phase II lightning attack with a long blue telegraph, airborne timed lightning reversal, reflected boss stagger, and emissive lightning arc feedback. Three prototype upgrade tokens let the player cycle through shuriken, firecracker, axe, and umbrella upgrades (keyboard U / touchscreen UPGRADE).
- One-use player resurrection restores 55% vitality at the configured checkpoint, clears posture, and grants 1.35 seconds of damage immunity. Three glowing grapple anchors support forward-cone targeting, collision-aware arcing movement, and a contextual heavy aerial follow-up (keyboard G/T/Y; touchscreen GRAPPLE/AIR ATTACK/REVIVE).
- Expanded traversal: a shallow training pond switches to swimming movement with vertical swim input; marked climbable walls support vertical climbing; airborne players can catch a ledge and mantle onto its top. Touchscreen adds CLIMB WALL (toggle), LEDGE, SWIM UP and SWIM DOWN.
- Expanded the test arena into the bounded Ashen Vale exploration region with a traversable north gate, connected stone trail markers, a western grove, eastern watch camp, pondside landmark, and three independently patrolling Sentinels.
- Added two interactable rest shrines. Press Z or the touchscreen REST action nearby to set the active checkpoint, restore vitality/posture/spirit energy, and refill the single resurrection charge. The active shrine is marked by a warm ember and the HUD displays a contextual prompt.
- A hidden Grove Relic Cache rewards off-path exploration. Press X or the touchscreen SECRET action nearby to collect a one-time prosthetic upgrade point and spirit energy.
- Added the two-step “The Grove’s Forgotten Oath” exploration objective: find the western relic cache, then carry its discovery to the Grove Rest Shrine. Completion grants two extra prosthetic upgrade points and spirit energy; the HUD tracks the objective and the reward cannot be claimed twice.
- Sentinel patrol, investigation, and alerted pursuit use local collision-aware steering: physics probes select angled detours around nearby solid obstacles while preserving direct travel in clear corridors. This remains the short-range obstacle-avoidance layer alongside the shared global navigation routes below.
- Nearby sentinels now use distance-weighted local separation while patrolling or pursuing, reducing overlap without changing routes when guards are far apart.
- The valley now has a shared NavigationRegion3D walkable surface and each sentinel has a NavigationAgent3D; patrol, investigation, and alerted pursuit steering consume agent path directions, with the existing ray probes handling nearby solid obstacles.
- Procedural wall-hug pose leans the torso toward the wall and tucks the weapon arm while preserving the crouched stance.
- Current validation is headless on Linux; Android export and real-device touch/visual checks are still pending.

## Roadmap
1. Replace primitive fighters with rigged characters and authored combat/traversal animation.
2. Replace blockout landmarks and props with a coherent licensed/CC0 environment art set.
3. Refine the coarse valley navigation surface around physical obstacles and add encounter-specific enemy behaviors; current ray probes and short-range sentinel separation remain the local avoidance layer.
4. Expand the objective chain into a journal, more secrets, and persistent save/checkpoint data.
5. Optimize rendering, input, memory, and validate a real Android export on device.

## Validation policy
A milestone is not complete until the project opens in the pinned Godot version, scripts parse without errors, scene starts, and each touch action is tested. Android export requires matching export templates and an actual build test.

## Project rules
- Keep source and progress in Git; commit after each stable milestone.
- Never overwrite unrelated projects.
- Keep generated builds in a dedicated builds folder (ignored by Git).
- Record blockers honestly in logs.

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]