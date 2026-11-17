# Ashen Oath — Mobile Combat Prototype

Fresh Godot 4.7.2 project. A mobile-first 3D action game prototype with Sekiro-inspired combat, not affiliated with FromSoftware or Sekiro.

## Current milestone
- Godot 4.7.2 mobile-first 3D action prototype with Vitality/Posture combat, buffered combos, deflects, Mikiri/sweep counters, hitstop, and a two-phase boss.
- Procedural third-person arena, primitive articulated fighter rigs, lock-on footwork, directional dodge, and adaptive camera framing.
- Touch HUD with virtual stick, camera drag, combat actions, crouch, stealth deathblow, vault, ledge mantle, wall-hug corner wrapping, and crouched cover-to-cover movement (keyboard B / touchscreen COVER).
- Sentinel patrols, vision-cone awareness, noise investigation, physical cover concealment, and multi-point cover investigation after losing sight; guards can escalate again if inspection restores direct line of sight.
- Four prototype prosthetic tools: forward-arc shuriken (ranged chip damage), firecracker (guard distraction/stagger), close-range axe (heavy vitality/posture impact), and timed umbrella guard. Spirit-emblem energy is displayed in the touch HUD and regenerates gradually; keyboard shortcuts 1–4 mirror the four touch actions.
- Procedural wall-hug pose leans the torso toward the wall and tucks the weapon arm while preserving the crouched stance.
- Current validation is headless on Linux; Android export and real-device touch/visual checks are still pending.

## Roadmap
1. Stabilize combat prototype and multi-touch input.
2. Add animation state machine, hit reactions, posture break, Mikiri, sweep, and hitstop.
3. Add deathblow, boss phases, resurrection, prosthetic tools, grappling, and stealth.
4. Add real licensed/CC0 character, environment, and audio assets; optimize and validate Android export.

## Validation policy
A milestone is not complete until the project opens in the pinned Godot version, scripts parse without errors, scene starts, and each touch action is tested. Android export requires matching export templates and an actual build test.

## Project rules
- Keep source and progress in Git; commit after each stable milestone.
- Never overwrite unrelated projects.
- Keep generated builds in a dedicated builds folder (ignored by Git).
- Record blockers honestly in logs.
