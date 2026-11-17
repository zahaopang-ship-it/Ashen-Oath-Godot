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

### M1 — Combat vertical slice (in progress)
- [x] Combat state flow: windup, active, recovery, posture-broken, dead.
- [x] Single-hit attack resolution with range/facing validation and readable windup state.
- [x] Deflect window (200 ms), post-deflect lockout, held-guard fallback, and posture pressure.
- [x] Posture threshold enters a timed broken state; vitality-dependent posture recovery.
- [x] Independent touch pointer tracking for movement, camera, and action-button fingers; keyboard debug controls (WASD/J/K/L/Space).
- [x] Headless combat logic suite: 56 assertions passing (including attack hit-volume, combo-buffer, and feedback-event checks).
- [x] Feedback integration suite: 3/3 checks (hitstop activation/restoration and spatial sound node creation).
- [ ] Validate simultaneous touch on a physical Android device; headless tests cannot prove touch-driver behavior.
- [x] Add a visible pulsing enemy windup marker and light camera impact feedback on confirmed hits.
- [x] Add short directional hitstun/recoil and a temporary material flash for unblocked hits.
- [ ] Add spatial telegraph audio, hit reactions, and broader automated movement/input tests.
- Gate: test matrix for all input combinations and combat outcomes; do not close M1 until physical multitouch is exercised.

### M2 — Combat depth
- [x] Attack classes and counter windows: slash, thrust/Mikiri, sweep/jump, and heavy.
- [x] Procedural combat pose foundation: attack anticipation/follow-through, guard, hitstun, posture break, and death.
- [x] Three-step slash/slash/heavy combo with a 0.58-second buffered input window.
- [x] Attack-specific forward hit volumes evaluated during active frames (narrow thrust, wide sweep, standard slash, heavy).
- [ ] Stomp and dodge/grab.
- [x] Short hitstop on hit, deflect, Mikiri/sweep counter, posture break, and death.
- [x] Stronger decaying camera shake and impact nudge tuned by combat event.
- [x] Original generated spatial SFX for body impact, sword deflect, guard clang, and posture break.
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
- Fighters are still procedural capsules and the arena is a greybox; no production character/environment assets or animation have been integrated.
- Combat is still a prototype: hit volumes are deterministic local-space gameplay boxes rather than weapon-bone swept collision; combat SFX are synthesized placeholders; no authored animation clips, boss, or Android export yet.
- The Linux container has no graphical desktop or physical touchscreen; Android rendering, safe areas, and true simultaneous multitouch remain unverified.
- GitHub repository: https://github.com/zahaopang-ship-it/Ashen-Oath-Godot (private), branch `main`. Push every stable checkpoint here; never use an unrelated repository.


## M1 combat expansion — attack classes and counters
- Added four validated attack classes: slash, thrust, sweep, and heavy, each with distinct windup, vitality damage, and posture pressure.
- Enemy AI now selects from the attack classes instead of using slash exclusively.
- Telegraph orb color identifies the incoming attack class (slash red, thrust amber, sweep cyan, heavy violet).
- Added a short Mikiri counter window against thrust attacks and a 0.60-second jump-evasion window against sweep attacks; successful counters punish attacker posture.
- Heavy attacks remain deflectable but deal substantially more posture damage through guard.
- Added dedicated mobile HUD actions and keyboard shortcuts for Mikiri and jump.
- Headless combat suite: 34/34 assertions passed; editor import and main-scene smoke run completed successfully.
- Still prototype scope: no animation-driven hitboxes, production character assets, Android device test, or APK in this milestone.


## M2 — Procedural combat pose animation foundation
- Reparented the capsule body, head, and blade under upper-body and weapon pivots so the fighter has controllable articulation points.
- Added attack-specific anticipation and follow-through poses for slash, thrust, sweep, and heavy attacks, driven directly by windup/active timers.
- Added guard, dodge, Mikiri, sweep-jump, hitstun, posture-break, death, and idle pose responses.
- Added headless assertions for heavy anticipation, active follow-through, guard pose, hit reaction, and death collapse pose.
- This is procedural pose animation on primitive meshes, not a skeletal animation asset or a replacement for authored animation clips.


## M2 — Timed hit volumes and buffered combo chain
- Replaced the simple distance/facing check with attack-specific local-space hit volumes evaluated during the active attack window.
- Slash/heavy use broad forward volumes, thrust uses a narrow and longer volume, and sweep uses a low wide volume.
- Attack hits are resolved during active frames and remain single-hit per attack token.
- Added a three-stage player chain (slash → slash → heavy) and a 0.58-second input buffer consumed when recovery ends.
- Buffered inputs expire cleanly; the combo chain resets after 0.95 seconds without continuation.
- Added headless tests for rear rejection, thrust lateral rejection, sweep lateral coverage, combo buffering, finisher, and expiry.
- Hit volumes are currently deterministic local-space gameplay volumes, not weapon-bone swept collision or animation-authored Area3D hitboxes.


## M2 — Hitstop, impact camera, and combat audio
- Added event-driven combat feedback signals for hits, deflects, guards, Mikiri/sweep counters, posture breaks, and death.
- Added brief global hitstop with unscaled SceneTree timers and generation tokens, so stale callbacks cannot prematurely restore Engine.time_scale after a newer impact.
- Tuned event-specific hitstop durations and camera shake strengths; counter and posture-break events receive stronger emphasis.
- Added four original synthesized WAV effects and play them through temporary AudioStreamPlayer3D nodes at the combatant position with distance attenuation.
- Verified all four audio resources are present and combat feedback signals fire in headless tests.
- No commercial/third-party sound assets were copied; these are procedural placeholder SFX pending final sound design.

- Feedback integration test: `project/tests/feedback_integration_test.gd` verifies hitstop activation/restoration and 3D impact audio node creation in a live headless scene.
