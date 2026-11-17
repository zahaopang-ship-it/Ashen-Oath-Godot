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
- [x] Headless combat logic suite: 67 assertions passing (including attack hit-volume, combo-buffer, grab/stomp, dodge cooldown, and sprint checks).
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
- [x] Stomp punish against a nearby posture-broken target.
- [x] Grab attack bypasses guard/deflect but is evaded by dodge; enemy AI can select it.
- [x] Dodge cooldown prevents repeated invulnerability-window spam.
- [x] Sprint movement activates at full joystick deflection; keyboard Shift is supported.
- [x] Short hitstop on hit, deflect, Mikiri/sweep counter, posture break, and death.
- [x] Stronger decaying camera shake and impact nudge tuned by combat event.
- [x] Original generated spatial SFX for body impact, sword deflect, guard clang, and posture break.
- Enemy archetypes and combat state machine.
- Gate: no stuck states; each attack type has a valid counter and punish path.

### M3 — Boss and signature mechanics
- [x] First boss encounter: Ashen Warlord with two distinct phases, escalating tempo, and phase-specific attack sequences.
- [x] Boss-specific vitality/posture pools, phase HUD label, and procedural armor silhouette.
- [x] Headless boss phase transition and pattern tests.
- [x] Contextual deathblow against a nearby posture-broken boss; validates range, facing, posture state, and one-time execution.
- [x] Phase II signature Ashen Rend: extended telegraph, unique crimson warning, broad heavy hit volume, and distinct procedural anticipation/follow-through.
- [x] Phase transition feedback: intensified crimson telegraph, hitstop, camera impulse, and spatial cue.
- [ ] Authored skeletal boss animation set.
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
- Fighters are still procedural primitive rigs with simple procedural locomotion and the arena is a greybox; no production character/environment assets, foot IK, or authored skeletal animation clips have been integrated.
- Combat is still a prototype: hit volumes are deterministic local-space gameplay boxes rather than weapon-bone swept collision; combat SFX are synthesized placeholders; Android export and device validation remain outstanding.
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


## M2 — Grab, stomp, dodge discipline, and sprint movement
- Added a telegraphed grab attack with its own windup, damage, and forward reach; guard and deflect do not counter grabs, while dodge still evades them.
- Added an extended grab hit reaction and mapped grab feedback to the impact sound event.
- Enemy AI can now select grabs occasionally, and the telegraph uses a pale warning color.
- Added a contextual stomp action that damages a nearby posture-broken target and rejects distant or non-broken targets.
- Added dodge cooldown to prevent immediate repeated evasion windows.
- Full virtual-stick deflection now produces sprint speed; desktop debug input supports Shift sprint.
- Added touch HUD STOMP button and keyboard P shortcut.
- Expanded headless combat checks for grab counter rules, stomp conditions, dodge cooldown, and sprint speed.


## M3 — Ashen Warlord first boss encounter
- Replaced the generic Ashigaru opponent in the main encounter with the Ashen Warlord boss controller.
- Added a dedicated 420 vitality / 260 posture pool and a two-phase state machine. Phase II begins at 55% vitality, increases movement/attack range, and accelerates attack cadence.
- Phase I uses a slash/thrust/heavy pattern; Phase II changes to sweep/grab/thrust/heavy to force different defensive answers.
- Added a procedural armored silhouette with shoulder plates, chest armor, and crest, plus boss name/phase HUD feedback.
- Added boss phase transition signal, combat feedback, and dedicated headless test coverage.
- The boss remains built from primitive geometry and procedural poses; no skeletal boss animations, cinematic deathblow, or Android playtest yet.


## M3 — Deathblow and Ashen Warlord signature attack
- Added a contextual DEATHBLOW touch action and `E` keyboard action. It only succeeds when the target is posture-broken, alive, within execution distance, and in front of the player.
- A successful deathblow now runs a synchronized 0.82-second attacker/victim execution sequence with distinct procedural draw-back, strike, fold, and collapse poses. The victim enters the terminal death state only after the sequence completes. Repeated, distant, rear-facing, and pre-break attempts are rejected.
- Added the Phase II-only `ashen_rend` attack to the Warlord's pattern. It has a 0.92-second telegraph, distinct broad hit volume, increased damage/posture pressure, and dedicated procedural windup/follow-through poses.
- Added a crimson signature telegraph and stronger phase-transition impact feedback.
- Automated checks cover execution eligibility, one-time death, range/facing validation, phase-specific move selection, and signature telegraph timing.
- Prototype limitation: deathblow is currently a gameplay state/instant finisher, not a cinematic synchronized animation; authored skeletal animation and physical Android input validation remain outstanding.


## M3 — Synchronized execution animation pass
- Replaced the instant deathblow with a timed 0.82-second paired execution state. Attacker and posture-broken victim enter the sequence together and cannot move or accept normal combat actions during it.
- Added distinct procedural execution poses: attacker draw-back/strike/follow-through and victim fold/collapse. The boss only transitions to DEAD when the sequence timer completes.
- Added regression checks for paired state entry, movement/attack lockout, mid-animation timing, delayed terminal death, and one-shot execution behavior.
- This remains procedural transform animation on capsule/primitive characters; it is not yet authored skeletal animation or motion-captured cinematic choreography.

## M3 — Procedural locomotion and footwork pass
- Added independent left/right leg pivots and simple leg/foot meshes to the greybox fighter rig; the upper-body capsule was shortened to create clearer separation between torso and legs.
- Added a continuous gait phase driven by planar movement speed, with alternating leg swings, a subtle vertical body bounce, and light torso/weapon sway. Sprinting increases cadence and body response.
- Added a lower guarded dodge posture and kept leg locomotion subordinate to combat states, so windup/active/recovery, hitstun, posture break, death, and synchronized execution continue to own the pose.
- Boss locomotion has a heavier cadence and a more forceful Phase II stride; its idle weapon/body stance is distinct from the player.
- Added five regression assertions for gait phase, alternating legs, body bounce, attack-state suppression, and return to idle. Headless combat suite: 72/72; boss suite: 22/22; feedback integration: 3/3.
- Limitation: this is still procedural animation on primitive meshes, without foot IK, root-motion clips, authored skeletal animation, or Android visual validation.

## M3 — Procedural upper-body, arm, and weapon articulation
- Added separate left/right shoulder pivots with upper-arm, forearm, and hand meshes; the katana grip is now attached to the right-hand/weapon pivot rather than floating independently beside the torso.
- Added state-driven arm poses for neutral guard, attack anticipation and follow-through, recovery, hitstun, posture break, dodge/counters, death, and the paired deathblow sequence.
- The weapon retains its existing attack-specific rotation layered beneath the arm pivot, so the arm carries the sword while the blade still receives its combat pose.
- Added regression checks confirming both arm pivots respond to attack anticipation and the weapon arm assumes a defensive angle during guard.
- Headless validation: combat 74/74, boss 22/22, feedback integration 3/3, editor import and main-scene smoke passed.
- Limitation: these are procedural primitive arm segments and transform poses, not skinned mesh deformation, hand IK, authored animation clips, or Android visual validation. Weapon collision remains the existing gameplay hit-volume system.

## M3 — Independent elbow and wrist articulation
- Rebuilt each primitive arm as a shoulder pivot, upper-arm segment, independent elbow pivot, forearm segment, and wrist pivot/hand.
- Reparented the katana grip and blade beneath the right wrist, so the weapon now inherits shoulder and elbow motion instead of being attached directly to the shoulder.
- Added procedural elbow flex driven by the active arm pose, with a stronger compact bend during guard; attack poses articulate both elbows.
- Added regression checks for elbow response during attack anticipation and defensive guard.
- Headless validation: combat 76/76, boss 22/22, feedback integration 3/3, Godot editor import and main-scene smoke passed.
- Limitation: the rig remains a hierarchy of primitive meshes and Node3D pivots; no skinned character, inverse kinematics, retargeted animation clips, or Android visual/device validation yet.

## M3 — Deflect clash and weapon-recoil feedback
- Perfect deflect now drives a short blade-contact pose on the defender and a separate shoulder/weapon recoil on the attacker.
- Added a brief crossed-blade spark flash at the midpoint between the fighters, layered with the existing deflect hitstop, camera shake, and spatial sword sound.
- Added combat assertions for both timed reactions and integration checks for the generated clash effect.
- Headless validation: combat 78/78, boss 22/22, feedback integration 5/5, main-scene smoke passed, editor import passed, and `git diff --check` passed.
- Limitation: clash FX is a procedural primitive flash, not a particle system or authored VFX; visual timing and placement still need in-engine and Android device review.

## M3 — Attack-specific hit reactions and posture-break stagger
- Replaced the single generic hitstun pose with distinct slash, thrust, sweep, heavy/Ashen Rend, and grab reaction profiles.
- Reaction duration, knockback strength, torso lean, arm bracing, weapon recoil, and low sweep stagger now vary by incoming attack; lateral reaction direction is derived from attacker position.
- Posture break now has a time-driven buckling/weapon-drop idle instead of a mostly static held pose.
- Added regression coverage for thrust/heavy/sweep/grab reaction selection and timing.
- Headless validation: combat 82/82, boss 22/22, feedback integration 5/5, main-scene smoke passed, script check/editor import passed, and `git diff --check` passed.
- Limitation: animation remains procedural on primitive meshes; no authored skeletal clips, animation-driven weapon collision, or Android visual/device validation yet.


## M4 — Combat footwork, directional dodge, and adaptive camera framing
- Added acceleration/braking-based player movement instead of immediate full-speed velocity changes.
- While a target is assigned, the player smoothly maintains target-facing orientation during lateral and backward movement, enabling lock-on strafing without turning away.
- Dodge now follows the current movement direction; neutral dodge retreats from the assigned target, and the player keeps facing that target during the evade.
- Camera distance and height now respond to player–enemy spacing, with a slight sprint framing adjustment.
- Regression coverage: lateral strafe, target-facing while strafing, lateral dodge, target-facing during dodge, and neutral retreat.
- Headless validation: combat 87/87, boss 22/22, feedback integration 5/5, editor import, main-scene smoke, and `git diff --check` passed.
- Limitation: touch-screen feel, camera composition, and movement responsiveness still require hands-on Android testing; no device build was produced in this phase.

## M5 — Stealth awareness and rear deathblow
- Added enemy awareness states: unaware, suspicious, searching, and alerted.
- Enemy vision uses a forward cone, configurable range, and physics raycast line-of-sight.
- Suspicion builds while the target remains visible and decays when it disappears; sustained sight escalates to alert and pursuit.
- Sprinting and player attacks create investigation noise; alerted guards search the last known target position after losing sight.
- Added a rear-approach stealth deathblow with range, facing, awareness, and state checks, using synchronized execution.
- Headless validation: combat 94/94, boss 22/22, feedback 5/5, editor import and main-scene smoke passed.

## M6 — Crouch, patrol routes, and detection feedback
- Added crouch toggle (keyboard C and touchscreen button) with a shortened collision capsule, lowered body pose, bent legs, reduced movement speed, and sprint suppression.
- Crouching reduces enemy effective vision range and suspicion gain; line-of-sight checks target a lower body point.
- Player attacks broadcast noise to stealth guards; crouched attacks have a smaller hearing radius. Sprinting and fast non-crouched movement remain audible.
- Added waypoint patrol movement for unaware guards, pause-at-waypoint behavior, and return to patrol after completing a search.
- Added an Ashen Sentinel guard to the arena with a four-point patrol route, configurable vision, and a live suspicion meter/state in the HUD.
- Regression coverage includes crouch collision/movement, crouch concealment, and patrol waypoint movement.
- Headless validation: combat 100/100, boss 22/22, feedback 5/5, editor import, main-scene smoke, and git diff --check passed.
- Limitation: the guard is a single prototype NPC; no authored animation clips, cover snapping, shadow/light visibility model, or Android device validation yet.


## M7 — Physical cover and concealment animation
- Added three solid stealth props (two dense bushes and a supply-crate cluster) with collision geometry that blocks enemy raycast line-of-sight.
- Added nearby concealment trigger volumes placed outside solid prop collision, so the player can take cover without entering the obstacle.
- Crouching inside cover reduces enemy vision to 16% of normal; standing inside cover grants partial concealment only. Suspicion gain is reduced while concealed.
- Added cover enter/exit tracking and HUD feedback (`COVERED` / `IN COVER`).
- Refined crouch locomotion pose with a lower center of mass, bent knees, compact arm posture, and a subtle slow sneak cycle.
- The arena directional light already casts real-time shadows; foliage and crates use the normal shadow-casting geometry. Detection currently uses physical cover occlusion and authored concealment zones rather than sampling rendered shadow pixels.
- Headless validation: combat 104/104, boss 22/22, feedback 5/5, stealth world 5/5; editor import and main-scene smoke passed.
- Limitation: no dynamic lighting-based stealth meter, foliage wind, or Android visual/touch validation yet.


## M8 — Low-obstacle vault traversal
- Added context-sensitive vault detection using low and high forward raycasts plus a landing-ground raycast.
- Player can vault over low obstacles with a short eased arc; tall walls and missing landing ground are rejected.
- Added keyboard V and touchscreen VAULT action. Traversal temporarily locks normal movement and combat input until landing.
- Added regression checks for successful low obstacle vault start and rejection of a tall wall.
- Added a compact airborne vault pose with tucked legs and raised arms.
- Headless validation: combat 104/104, boss 22/22, feedback 5/5, stealth/traversal world 10/10; editor import and main-scene smoke passed.
- Limitation: this is a prototype traversal arc, not a hand-authored climbing animation or ledge-grab system.


## M9 — Ledge mantle and active guard search
- Added a contextual mantle action for reachable raised platforms: a chest-height obstacle probe, head-clearance probe, and landing-surface raycast validate the climb before traversal begins. Heights outside the supported range and blocked overhead clearance are rejected.
- Mantle uses a distinct traversal duration and compact airborne pose while reusing the validated traversal lockout; it is separate from the shorter low-obstacle vault.
- Added keyboard M and a dedicated touchscreen CLIMB action. Existing V / VAULT remains unchanged.
- Improved the Sentinel's SEARCHING state: after reaching the last known position, it pauses and scans left/right before returning to patrol.
- Regression coverage: successful low vault, successful raised-platform mantle, mantle completion at platform height, and rejection of a full-height wall; stealth world suite now has 14 assertions.
- Headless validation: combat 104/104, boss 22/22, feedback integration 5/5, stealth world 14/14; editor import and main-scene smoke passed; `git diff --check` passed.
- Limitation: mantle is a procedural eased arc, not an authored ledge-grab/climb animation. Search scanning is a simple yaw sweep. Cover-to-cover snapping, navigation around arbitrary geometry, shadow-pixel detection, and Android touch/device validation remain future work.


## M10 — Wall-hug stealth traversal
- Added contextual wall-hug entry: the player must face a nearby solid wall, and a horizontal surface normal is captured from a physics raycast.
- While attached, movement is projected along the wall tangent; forward/back input controls approach/separation, and a small planar correction maintains a consistent offset.
- Wall-hug enforces a lowered crouch posture and disables sprint. The player can exit on demand; if the wall is no longer detected, the mode disengages automatically.
- Added keyboard H and a touchscreen WALL action. Vault (V) and mantle (M) remain separate traversal actions.
- Added regression checks for valid wall attachment, stealth posture, lateral movement along the wall, and manual exit.
- Headless validation: combat 104/104, boss 22/22, feedback integration 5/5, stealth world 18/18; editor import and main-scene smoke passed; `git diff --check` passed.
- Limitation: wall-hug currently uses a single forward-facing wall probe and does not yet support corner wrapping, cover-to-cover auto-routing, authored wall animations, or Android device validation.


## M11 — Wall corner wrapping
- Extended wall-hug traversal with a forward-side corner probe. When the current wall ray loses contact, lateral input probes around the corner for an adjacent perpendicular wall and updates the wall normal without dropping the stealth stance.
- The transition rejects floor/ceiling hits and near-parallel surfaces to avoid snapping to unrelated geometry. If no valid continuation is found, the existing safe disengage behavior remains.
- Added regression checks for detecting an adjacent perpendicular wall and adopting its new surface normal.
- Headless validation: combat 104/104, boss 22/22, feedback integration 5/5, stealth world 20/20; editor import and main-scene smoke passed; `git diff --check` passed.
- Limitation: corner traversal currently requires lateral input and uses a single probe, so it supports clean 90-degree corners but not arbitrary curved walls, narrow gaps, or automatic cover-to-cover pathfinding. Sentinel search still uses a timed yaw scan at the last known location; it does not yet physically inspect each cover prop. Android device validation remains pending.

## M12 — Guard cover investigation
- When an alerted guard loses sight of the player for four seconds, it now builds a bounded investigation route from the last known position and nearby stealth-cover zones (within 6.5 m).
- The guard walks to the last known position, then visits nearby bushes/crates in nearest-first order, pausing and scanning at each point before continuing. The route is based on remembered sighting data, not the player's current hidden position.
- Added regression checks for route composition, memory-only search origin, pause initialization, and actual movement toward the last known location.
- Limitation: this is a simple waypoint investigation, not full navigation/pathfinding; collision geometry can still obstruct direct travel. It does not guarantee that every prop is reachable. Android device validation remains pending.


## M13 — Cover-to-cover stealth traversal and wall-hug pose
- Added a crouch-only COVER action (keyboard B and touchscreen button) that selects the nearest other concealment zone within 7 m and moves the player there through CharacterBody3D movement. It never teleports; short collision probes choose a lateral detour around the current cover, and the transfer cancels safely if both sides are blocked. Standing up cancels an active transfer.
- Added a distinct wall-hug procedural pose: torso lean toward the wall, tucked shoulder/weapon arm, and asymmetric foot placement layered over the crouch animation. HUD reports COVER MOVE while traversing.
- Guard awareness continues updating while investigating cover points. If inspection restores direct vision of an exposed player, normal suspicion escalation can transition the guard back to ALERTED; hidden position is not read from the player's location to create search waypoints.
- Regression coverage includes crouch requirement, valid cover destination, collision-safe physical movement, arrival inside concealment, visible-player rediscovery, and wall-hug torso/arm pose.
- Limitation: cover transfer uses local collision probes and one detour, not a global navigation mesh; it may cancel around complex obstacles. Wall pose is procedural, not authored animation. Android device validation remains pending.


## M14 — Prosthetic tool combat prototype
- Added four player prosthetic actions on keyboard 1–4 and touchscreen: Shuriken, Firecracker, Axe, and Umbrella. Tool use is restricted to neutral combat state and uses a shared 100-point spirit-emblem pool with per-tool costs, cooldowns, and gradual regeneration (5.5/sec).
- Shuriken checks a 10 m forward arc and clear ray, deals light vitality/posture damage, and displays a short emissive projectile traveling to the target. Failed targeting does not consume energy.
- Firecracker creates a short-lived emissive burst, interrupts nearby free guards, and redirects their investigation route to the burst location rather than the player's current position.
- Axe applies a close-range heavy impact with strong posture pressure and a dedicated procedural swing pose. Umbrella creates a 1.25-second timed guard window, including a broader defensive pose, then closes automatically.
- Added spirit-energy HUD bar and regression tests for targeting, damage, distraction, guard interruption, timed defense, energy costs, and invalid tool use.
- Limitation: these are prototype gameplay implementations and primitive VFX, not final Sekiro-grade authored animations, models, or sound design. Umbrella currently uses the existing guard/block damage rules; lightning reversal and prosthetic upgrades are not implemented. Android touch/performance validation remains pending.


## M15 — Lightning reversal and prosthetic upgrades
- Added a Phase II-only lightning attack to the Ashen Warlord's sequence with a 1.05-second blue telegraph and a dedicated attack hit volume.
- Player can activate Lightning Reversal only while airborne; the 0.85-second counter window must overlap the incoming lightning hit. A successful reversal negates player damage, consumes the window, reflects an emissive arc, and inflicts 82 posture plus a heavy stagger on the boss. A grounded or mistimed counter receives normal damage.
- Added three prototype upgrade tokens and a rotating upgrade selector (keyboard U / touchscreen UPGRADE). Up to three levels per tool: Shuriken damage/posture, Firecracker distraction radius, Axe damage/posture, and Umbrella duration improve; each upgrade reduces that tool's emblem cost by 8% (minimum 8).
- Added regression coverage for airborne-only activation, timing-window consumption, damage prevention, reflected stagger/VFX, phase-two lightning telegraph, and upgrade spending/selection.
- Limitation: the upgrade tokens are prototype starting resources, not yet earned from a progression or save system. Lightning is a procedural beam placeholder; no authored lightning animation, sound, or Android device validation yet.


## M16 — Resurrection and grappling traversal
- Added one player resurrection charge. On death, REVIVE becomes available; using it restores 55% vitality, clears posture and transient combat/traversal states, returns the player to the configured checkpoint, consumes the charge, and grants 1.35 seconds of damage immunity. No automatic resurrection or repeated use after charge exhaustion.
- Added three glowing arena grapple anchors. The player can select the nearest visible anchor in a forward cone up to 12.5 m; an obstructed, behind-player, too-close, or out-of-range anchor is rejected. Grapple traversal follows a timed raised arc using CharacterBody3D movement and collision checks, not teleportation.
- Completing a grapple arms one contextual heavy aerial follow-up when an enemy is within 3.1 m and in front. Added touch controls and keyboard G (grapple), T (aerial follow-up), Y (resurrection), and F (jump); the existing touch JUMP action now performs a real jump.
- Tests cover resurrection charge, health/posture restoration, checkpoint return, immunity, non-player rejection, anchor targeting, arc completion, physical displacement, aerial follow-up, and rear-anchor rejection.
- Limitation: resurrection charge is a prototype per-player resource and does not yet refill from deathblows/rest points or persist in saves. Grapple anchors are fixed test-arena points; there is no rope mesh, swing physics, enemy grapple execution, authored traversal animation, or Android device validation yet.

## M17 — Swimming, marked wall climbing, and ledge hanging
- Completed the traversal work already present in the working tree and added a dedicated traversal regression suite. The arena now includes a shallow training pond with Area3D enter/exit detection and a visible water surface; swimming uses a reduced collision capsule, horizontal joystick movement, buoyancy toward the surface, and explicit touchscreen SURFACE/DIVE hold controls.
- Added explicit `climbable_surfaces` marking so vertical climbing is restricted to authored climbable geometry rather than arbitrary walls. The climb action toggles attachment/cancellation, and the player moves vertically along the wall with a collision probe maintaining contact.
- Added airborne ledge catches with wall/top probes, a stable hang state, joystick up to mantle onto the safe side, and joystick down to drop. Fixed the top-surface probe offset and extended the landing ray so it can find ground below raised ledges.
- Added regression coverage for water-state/capsule transitions, vertical swim controls, marked-vs-unmarked climbing, upward climb movement, ledge catch/hang/mantle, and live arena water trigger entry/exit.
- Headless traversal suites: 20/20 and 14/14; all prior regression suites also pass (259 total assertions), editor import, main-scene smoke, and `git diff --check` passed.
- Limitations: swimming is a simple buoyant movement prototype with no strokes, underwater camera/post-processing, oxygen, or water combat. Climbing uses a single surface normal and does not yet support corner transitions or stamina. Ledge hang/mantle uses procedural movement, not authored animation. Android touch, rendering, and performance validation remain pending.


## M17 — Swimming, vertical climbing, and ledge hanging
- Added a water volume and translucent training pond surface. Entering the volume switches to a shorter collision capsule and swim movement with buoyancy toward the surface; horizontal steering uses the movement stick and vertical movement uses SWIM UP/DOWN (keyboard PageUp/PageDown). Exiting restores the standing capsule.
- Added explicitly tagged climbable surfaces. A forward ray selects a wall; the player can climb vertically using the movement stick and toggle the climb action to disengage. The system releases automatically when the wall ends above. Unmarked walls are not climbable.
- Added an airborne ledge catch with wall/top-surface probes and a stable hanging state. Upward stick input mantles onto the detected top surface; downward input releases the ledge. The arena includes a marked climb wall and training pond.
- Regression tests cover water volume registration, swim profile/movement/exit, climbable wall targeting and vertical movement, automatic release at the wall top, rejection of unmarked walls, ledge catch/hang, mantle transition and landing.
- Limitation: swimming is a shallow-water prototype without underwater camera, breath/drowning, buoyancy simulation or swim animations. Climbing is a tagged vertical-wall mechanic, not freeform rock climbing. Ledge detection uses simple ray probes and does not yet support corner shimming, hand IK, authored animation or Android device validation.

## M18 — Ashen Vale exploration, hidden relic, patrols, and rest shrines
- Expanded the playable ground from the compact 30 m arena into a bounded 56 × 50 m valley. Replaced the old continuous perimeter ring with outer boundary stones and opened the former north fence into a traversable gate passage.
- Added connected stone trail markers linking the starting courtyard, northern ruined gate/grove, western monolith route, eastern pond/bell route, and eastern watch camp. Added distinct visible landmarks to help orient navigation without a minimap; decorative trail stones do not interfere with collision or stealth traversal.
- Added two additional independently patrolling Sentinels: an eastern lookout guarding the camp and a northern ranger near the grove. Both use their own patrol loops and target the player; the original Sentinel remains in the central stealth route.
- Added a hidden Grove Relic Cache off the western trail. Finding it and pressing X (or the touchscreen SECRET action) permanently hides it for the session and grants one prosthetic upgrade point plus 25 spirit energy; the HUD displays a contextual discovery prompt.
- Added two interactable rest shrines with active/inactive ember lighting. Keyboard Z and the touchscreen REST action activate the nearest shrine within 2.8 m, move the player to a safe offset, set the resurrection checkpoint, restore vitality/posture/spirit energy, and refill the one resurrection charge. Only the selected shrine remains lit; the HUD shows a contextual interaction prompt.
- Camera framing becomes player-centric while the boss is distant or defeated, so exploration is not forced to keep the boss in the camera focus.
- Added an exploration-world regression suite covering patrol population, landmark/path layout, touch REST/SECRET actions, secret-cache range and one-time rewards, shrine range checks, checkpoint transfer, resource restoration, active shrine visuals, and resurrection at the newly selected checkpoint.
- Headless validation: all 284 assertions across ten suites pass; editor import, main-scene smoke, and `git diff --check` pass.
- Limitations: this is a handcrafted compact prototype region, not a streamed open world. Trail stones and landmarks are primitive meshes; there is no navigation mesh/pathfinding, minimap, quest system, additional collectibles beyond the single prototype cache, save persistence, authored environment art, or Android device validation yet.

## M19 — Linked exploration oath and reward progression
- Added a small event-driven exploration objective controller. The Grove's Forgotten Oath begins by asking the player to find the western Grove Relic Cache; collecting it advances the objective to the remote Grove Rest Shrine.
- Activating the Grove Rest Shrine after discovering the relic completes the two-step objective and grants two additional prosthetic upgrade points plus up to 35 spirit energy. The reward is one-time and cannot be farmed by resting repeatedly.
- Player exploration interactions now emit lightweight events, keeping objective progression separate from combat and shrine implementation. The objective text is displayed in a dedicated HUD line and updates as the player advances.
- Added an exploration-objectives regression suite covering initial state, both objective transitions, reward amounts, duplicate-reward prevention, and HUD integration (11 assertions).
- Headless validation: all 295 assertions across eleven suites pass; Godot 4.7.2 editor import and main-scene smoke pass; `git diff --check` passes.
- Limitations: objective progress and rewards are session-only; there is no save/load persistence, journal UI, branching quest logic, map marker, or Android touch/rendering validation. Guard navigation remains waypoint-based and does not yet have global pathfinding.


## M20 — Collision-aware sentinel steering
- Added a lightweight local navigation steering layer for Sentinel patrol, last-known-position investigation, and alerted pursuit. It probes the direct corridor and six angled alternatives using physics ray queries, then selects a clear direction that balances forward progress and obstacle clearance.
- AI velocity now accelerates toward the chosen steering direction rather than snapping directly toward a waypoint. When the corridor is clear, guards preserve their original direct route.
- Added a dedicated guard-navigation suite (6 assertions): clear-route preservation, wall detection, lateral detour selection, forward progress, controlled velocity, no temporary-node creation, and route recovery after obstacle removal.
- Full headless validation: 301/301 assertions across twelve suites pass. Godot 4.7.2 editor import and main-scene smoke pass; `git diff --check` passes.
- Scope/limitations: this is local ray-probe steering, not global pathfinding or a NavigationServer3D/navmesh solution. It does not guarantee a route around large or enclosed obstacles, and it does not yet model crowd avoidance between guards. No APK or Android device validation was performed.


## M21 — Sentinel crowd spacing and patrol coordination
- Extended the M20 steering layer with local separation between members of the `stealth_guards` group. Nearby sentinels now contribute a distance-weighted repulsion vector that blends with their current travel direction, helping patrols and pursuits avoid occupying the same space.
- Separation is limited to a 2.4 m radius and ignores self, non-character nodes, near-zero overlaps, and distant guards. It does not alter a guard's route when no nearby sentinel is present.
- Added three regression assertions for near-neighbor avoidance, preserving a normalized usable travel direction with lateral spacing, and no influence beyond the separation radius.
- Full headless validation: 304/304 assertions across twelve suites pass. Godot 4.7.2 editor import and main-scene smoke pass; `git diff --check` passes.
- Limitations: no NavigationRegion3D/navmesh or global route planning yet. This remains local ray-probe obstacle steering plus short-range guard separation; dense groups and enclosed obstacles may still cause congestion. No APK or Android device validation was performed.


## M22 — Global sentinel route queries
- Added a shared NavigationRegion3D to the valley with a coarse walkable polygon covering the bounded ground area.
- Added a NavigationAgent3D to each non-player, non-boss sentinel and configured agent radius, height, and path arrival tolerances.
- Sentinel patrol, investigation, and alerted pursuit now request the next point from the agent path and feed that direction into the existing collision-aware ray steering and local guard separation.
- Added five route assertions covering region registration, agent ownership, long-distance route calculation, destination reachability, and consumption of the agent direction by AI steering.
- Full headless validation: 309/309 assertions across twelve suites pass. Godot 4.7.2 editor import and main-scene smoke pass; git diff --check passes.
- Limitations: the current NavigationRegion3D is a coarse rectangular ground polygon; it does not yet carve fence, tree, or prop obstacles from the navmesh. Local physics probes still handle immediate obstacle detours, and dense crowd behavior is only short-range separation. No APK or Android device validation was performed.

## M23 — Fighter construction factory and first architecture boundary
- Extracted the complete runtime fighter assembly pipeline from `main.gd` into `scripts/factories/fighter_factory.gd` (`RefCounted` factory). The factory now owns CharacterBody3D creation, collision capsule setup, sentinel NavigationAgent3D setup, primitive visual rig assembly, weapon pivots, and boss armor additions.
- `main.gd` now delegates fighter construction through one typed factory entry point; gameplay behavior remains in `fighter.gd` / `boss.gd`, and world orchestration remains in `main.gd`. This is an incremental boundary, not a claim that the large gameplay scripts have already been decomposed.
- Added `fighter_factory_test.gd` with 12 assertions covering player/sentinel/boss script selection, player role, collision capsule, body/weapon rig, sentinel-only navigation agent, boss armor, and parent attachment.
- Validation: all 13 headless suites pass (321 assertions total); Godot 4.7.2 editor import, main-scene smoke, and `git diff --check` pass.
- Extracted Ashen Vale environment construction from main.gd into scripts/world/world_builder.gd. The builder owns world environment, terrain/boundaries, trees, paths, landmarks, camp/gate, water, climb wall, grapple anchors, stealth cover, shrines, and secret cache creation. main.gd delegates world construction and water-trigger setup.
- Preserved existing main-scene node paths by letting the builder attach top-level world nodes to the scene root; water callbacks remain available on Main as compatibility delegates.
- Added world_builder_test.gd with 12 assertions for builder ownership, root compatibility, environment registrations, and encounter initialization.
- Extracted keyboard debug input dispatch from main.gd into scripts/input/player_input_router.gd; the router sends J/K/L/Space and traversal/combat keys through the same Fighter API as the touch HUD. Added player_input_router_test.gd with 10 input-routing assertions.
- Extracted third-person follow framing, camera drag rotation, telegraph pulse timing, impact impulse, and shake decay into scripts/camera/combat_camera_rig.gd. Added combat_camera_rig_test.gd for camera follow, focus, drag, pitch limits, impulse/shake, telegraph reset, and decay.
- Extracted NavigationAgent route consumption, local physics-probe obstacle steering, and nearby-sentinel separation into scripts/ai/sentinel_navigation_steering.gd. Fighter keeps thin wrapper methods to preserve current AI/test interfaces. Added sentinel_navigation_steering_test.gd for safe fallbacks and steering behavior.
- Extracted sentinel perception and stealth awareness into scripts/ai/stealth_awareness_controller.gd: vision multiplier, cone and line-of-sight tests, suspicion accumulation/decay, noise investigation, distraction response, and multi-point cover-search generation. Fighter keeps compatibility wrappers for existing callers and tests.
- Extracted sentinel decision selection, attack-pattern choice, search-point movement, patrol waypoint progression, and idle braking into scripts/ai/sentinel_ai_controller.gd. Fighter now delegates high-level AI updates through thin compatibility wrappers.
- Extracted swimming, vertical climb attach/update/release, ledge grab/hang/mantle, jump gating, grapple target selection and arc movement, and aerial grapple follow-up into scripts/traversal/fighter_traversal_controller.gd. Existing Fighter entry points remain compatibility wrappers.
- Extracted shuriken, firecracker, axe, umbrella resource/cooldown handling, lightning reversal/arc feedback, and prosthetic upgrade selection into scripts/prosthetics/fighter_prosthetic_controller.gd. Existing Fighter public actions remain compatibility wrappers.
- Extracted rest-shrine interaction/checkpoint restoration, secret-cache collection/rewards, and resurrection into scripts/exploration/fighter_exploration_controller.gd. Moved stealth-cover overlap bookkeeping into the stealth awareness controller.
- Extracted strike reception, block/deflect/mikiri/sweep outcomes, hit-reaction/knockback setup, posture-break transitions, and death transitions into scripts/combat/fighter_combat_resolution.gd.
- Extracted player movement, crouch/sprint acceleration, cover-transfer steering, wall-hug motion, and facing into scripts/movement/fighter_locomotion_controller.gd.
- Extracted player acceleration/braking, crouch/sprint movement, wall-hug and cover-transfer movement, movement direction, and facing into scripts/movement/fighter_locomotion_controller.gd. Fighter retains compatibility entry points.
- Corrected static controller references to use the actor transform and added explicit types where Godot could not infer values from the generic CharacterBody3D API.
- Validation after the locomotion extraction is being rerun across all 17 headless suites; the combat suite now passes 104/104 after the typing fixes. Godot 4.7.2 editor import succeeds.
- Remaining M23 work: extract procedural combat/locomotion animation, reduce fighter.gd further, introduce data-driven fighter/encounter configuration, and formalize shared event/service boundaries. fighter.gd is currently 1,210 lines. Android export/device validation remains pending.

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]