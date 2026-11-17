# Ashen Oath — Technical Design & Milestone Plan

## Product direction
A mobile-first 3D action game with precise sword combat inspired by the feel and combat vocabulary of Sekiro. Original title, characters, world, assets, animation, sound, and code. Do not copy proprietary Sekiro assets or branding.

## Non-negotiable production rules
- Godot version is pinned to 4.7.2 stable.
- Android touch controls are a first-class requirement, not an afterthought.
- Virtual joystick and action controls must support simultaneous multi-touch.
- Camera drag must not cancel movement or action input.
- Keep combat logic data-driven where practical and separate input, combat state, animation, AI, and UI.
- Every stable milestone is committed to Git. Never rely on a temporary remote desktop session as the only copy.
- Do not mark a feature done until scripts parse, scenes load, runtime logs are clean, and the feature is exercised.
- Keep all exported APK/AAB files in a dedicated builds directory, separate from project source and older projects.

## Combat model
### Vitality and posture
- Vitality is health; posture is the guard-break pressure meter.
- Posture rises from blocked attacks, failed defense, and pressure.
- Posture recovery depends on combat state and vitality; lower vitality should slow recovery.
- Posture break should create a punish/deathblow opportunity rather than silently resetting with no feedback.

### Deflection and block
- Deflect has a precise 12-frame target window at 60 FPS (about 200 ms).
- A successful deflect negates vitality damage and applies posture damage to the attacker.
- A normal block reduces vitality damage but adds posture to the defender.
- Repeatedly holding or spamming deflect must not provide permanent perfect defense.
- Deflect timing, cooldown, recovery, and input buffering must be explicit states.

### Player actions
- Locomotion, sprint, jump, dodge, crouch/stealth, lock-on, attack chain, block, deflect.
- Input buffer for attacks and defense with clear priority rules.
- Mikiri counter for thrust attacks.
- Jump/stomp response to sweep attacks.
- Dodge/grab interactions and punish windows.
- Deathblow against posture-broken or unaware enemies.
- Aerial and stealth deathblows.

### Enemy and boss AI
- Awareness states: unaware, suspicious, searching, alert, combat, recovering, dead.
- Enemy telegraphs must be readable on a phone screen.
- Bosses use phase/state machines with distinct attack patterns and recovery windows.
- Thrust, sweep, grab, and ordinary attack classes must be distinguishable for counter logic.

### Advanced systems
- Resurrection with explicit charge/lockout rules.
- Prosthetic tools: Shuriken, Firecrackers, Axe, Umbrella.
- Lightning reversal interaction.
- Grappling hook with validated grapple points and mobile-friendly targeting.
- Hitstop, camera impulse, animation response, spatial audio, and clear hit confirmation.

## Architecture target
- Input layer: desktop debug input plus touch HUD; both feed the same action interface.
- Player controller: locomotion and movement modes only.
- Combat controller: attack/defense state machine, windows, input buffer, and hit resolution.
- Vitality/posture component: health, posture, break, recovery, death.
- Enemy AI: awareness and combat decision state machines.
- Animation driver: maps gameplay states to animation parameters; gameplay must not depend on placeholder mesh layout.
- Camera rig: follow, lock-on framing, collision, camera drag, hit response.
- UI: mobile-safe HUD, vitality/posture bars, telegraph indicators, tool selection, pause.
- Audio: event-driven spatial SFX and mix priorities.

## Milestones and acceptance gates
### M0 — Project foundation (current)
- Godot 4.7.2 installed and pinned.
- New project and main scene.
- Procedural test arena, player/enemy bodies, camera, initial touch HUD.
- Initial vitality/posture, deflect/block/dodge and simple enemy behavior.
- Gate: headless import and scene smoke test pass; fix every parser/runtime error before M1.

### M1 — Combat vertical slice
- Reliable mobile joystick and independent camera drag.
- Simultaneous touch testing for movement + deflect + attack.
- Attack hitboxes and telegraph timing.
- Deflect timing and anti-spam behavior.
- Posture break and meaningful recovery.
- Keyboard/gamepad debug mappings for repeatable testing.
- Gate: test matrix for all input combinations and combat outcomes.

### M2 — Combat depth
- Attack chains, input buffering, Mikiri, sweep jump/stomp, dodge/grab.
- Hit reactions, hitstop, camera impulse, impact audio.
- Enemy archetypes and combat state machine.
- Gate: no stuck states; each attack type has a valid counter and punish path.

### M3 — Boss and signature mechanics
- Boss multi-phase state machine and telegraphs.
- Deathblow, stealth/aerial deathblow.
- Resurrection rules.
- Shuriken, Firecrackers, Axe, Umbrella, lightning reversal, grappling.
- Gate: full encounter can be completed with touch controls.

### M4 — Content and production quality
- Replace blockout fighters/environment with properly licensed assets.
- Retarget and tune animation library; bespoke combat transitions.
- Spatial audio, ambience, UI feedback, VFX, camera polish.
- Gate: asset licenses recorded; no missing resources.

### M5 — Android validation
- Import/export templates pinned to Godot 4.7.2.
- Android ARM64 export profile and permissions.
- Test on actual Android device, including thermal/performance behavior.
- Verify multitouch, orientation, safe areas, pause/resume, audio focus, and save behavior.
- Keep APK/AAB in builds/ with versioned filenames and test notes.

## Current known limitations
- Current fighters are procedural capsules and the arena is a greybox. They are for validating mechanics, not final visuals.
- Animation, real character assets, audio, boss systems, and Android export are not yet implemented.
- The current remote Linux container has no graphical desktop; editor GUI and physical touchscreen behavior cannot be validated there.
- Git is initialized locally. The GitHub CLI on this container is not authenticated, and no dedicated Ashen Oath GitHub repository has been created yet. Do not push to an unrelated repository.
