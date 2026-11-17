extends SceneTree

const FIGHTER = preload("res://scripts/fighter.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _new_fighter(label: String, pos: Vector3) -> CharacterBody3D:
	var f := CharacterBody3D.new()
	f.name = label
	f.set_script(FIGHTER)
	f.position = pos
	root.add_child(f)
	return f

func _run() -> void:
	var defender := _new_fighter("Defender", Vector3.ZERO)
	var attacker := _new_fighter("Attacker", Vector3(0, 0, -1.2))
	defender.target = attacker
	attacker.target = defender

	_check(defender.begin_deflect(), "deflect can start from neutral")
	_check(defender.receive_strike(20.0, 30.0, attacker) == "deflected", "perfect deflect negates vitality damage")
	_check(is_equal_approx(defender.vitality, 100.0), "deflect preserves vitality")
	_check(is_equal_approx(attacker.posture, 26.0), "deflect pressures attacker posture")
	defender.end_deflect()
	_check(not defender.begin_deflect(), "deflect lockout prevents immediate repeat")

	defender.deflect_cooldown = 0.0
	defender.begin_block()
	var before: float = defender.vitality
	_check(defender.receive_strike(20.0, 30.0, attacker) == "blocked", "held guard blocks")
	_check(is_equal_approx(defender.vitality, before), "guard prevents vitality damage")
	_check(defender.posture > 0.0, "guard adds posture pressure")
	defender.end_block()

	defender.posture = 90.0
	defender.receive_deflect(15.0)
	_check(defender.state == 4, "posture threshold enters broken state")
	_check(defender.posture == 100.0, "posture is clamped at break threshold")
	_check(not defender.begin_deflect(), "posture-broken fighter cannot deflect")

	var striker := _new_fighter("Striker", Vector3.ZERO)
	var victim := _new_fighter("Victim", Vector3(0, 0, -1.4))
	striker.target = victim
	_check(striker.start_attack(), "attack starts from neutral")
	_check(striker.state == 1, "attack enters readable windup")
	striker.call("_update_attack_state", 0.33)
	_check(striker.state == 2, "windup transitions to active frame")
	_check(victim.vitality < 100.0, "active attack hitbox resolves a target in front")
	var health_after: float = victim.vitality
	striker.call("_resolve_attack_hit")
	_check(is_equal_approx(victim.vitality, health_after), "one attack cannot hit same target twice")

	var rear_striker := _new_fighter("RearStriker", Vector3.ZERO)
	var rear_target := _new_fighter("RearTarget", Vector3(0, 0, 1.0))
	rear_striker.target = rear_target
	rear_striker.start_attack("slash")
	rear_striker.call("_update_attack_state", 0.33)
	_check(is_equal_approx(rear_target.vitality, 100.0), "attack hitbox does not hit targets behind the fighter")

	var thrust_striker := _new_fighter("ThrustStriker", Vector3.ZERO)
	var side_target := _new_fighter("SideTarget", Vector3(1.0, 0, -1.0))
	thrust_striker.target = side_target
	thrust_striker.start_attack("thrust")
	thrust_striker.call("_update_attack_state", 0.49)
	_check(is_equal_approx(side_target.vitality, 100.0), "narrow thrust hitbox rejects a lateral target")

	var sweep_striker := _new_fighter("SweepStriker", Vector3.ZERO)
	var sweep_target := _new_fighter("SweepTarget", Vector3(1.1, 0, -1.0))
	sweep_striker.target = sweep_target
	sweep_striker.start_attack("sweep")
	sweep_striker.call("_update_attack_state", 0.43)
	_check(sweep_target.vitality < 100.0, "wide sweep hitbox catches a lateral target")

	var doomed := _new_fighter("Doomed", Vector3.ZERO)
	doomed.receive_strike(150.0, 0.0, attacker)
	_check(doomed.is_dead and doomed.state == 5, "lethal strike enters terminal dead state")
	_check(not doomed.begin_deflect(), "dead fighter cannot deflect")

	var stunned := _new_fighter("Stunned", Vector3.ZERO)
	var source := _new_fighter("Source", Vector3(0, 0, -1))
	_check(stunned.receive_strike(10.0, 8.0, source) == "hit", "unblocked strike returns hit result")
	_check(stunned.state == 6 and stunned.hit_reaction_timer > 0.0, "unblocked hit enters timed hitstun")
	_check(stunned.velocity.length() > 0.0, "hit reaction applies directional recoil")
	stunned.call("_update_hit_reaction", 0.25)
	_check(stunned.state == 0, "hitstun recovers to neutral after its timer")

	var countering := _new_fighter("Countering", Vector3.ZERO)
	var thrust_source := _new_fighter("ThrustSource", Vector3(0, 0, -1))
	_check(countering.begin_mikiri_counter(), "Mikiri counter opens from neutral")
	_check(countering.receive_strike(27.0, 36.0, thrust_source, "thrust") == "mikiri", "Mikiri defeats a thrust attack")
	_check(is_equal_approx(thrust_source.posture, 48.0), "Mikiri applies strong posture punishment")

	var jumping := _new_fighter("Jumping", Vector3.ZERO)
	var sweep_source := _new_fighter("SweepSource", Vector3(0, 0, -1))
	_check(jumping.begin_sweep_evade(), "jump counter opens and launches upward")
	_check(is_equal_approx(jumping.counter_timer, 0.60), "jump counter window covers the sweep telegraph")
	_check(jumping.receive_strike(18.0, 24.0, sweep_source, "sweep") == "sweep_evaded", "jump evades a sweep attack")
	_check(is_equal_approx(sweep_source.posture, 32.0), "sweep evade punishes attacker posture")

	var heavy_guard := _new_fighter("HeavyGuard", Vector3.ZERO)
	heavy_guard.begin_block()
	_check(heavy_guard.receive_strike(34.0, 46.0, attacker, "heavy") == "blocked", "heavy attack can be guarded")
	_check(is_equal_approx(heavy_guard.posture, 39.1), "heavy guard causes increased posture damage")
	_check(not heavy_guard.start_attack("invalid"), "unknown attack kinds are rejected")

	var animated := _new_fighter("Animated", Vector3.ZERO)
	var upper := Node3D.new()
	var weapon := Node3D.new()
	animated.add_child(upper)
	upper.add_child(weapon)
	animated.set_animation_rig(upper, weapon)
	animated.start_attack("heavy")
	animated.attack_timer = 0.31
	animated.call("_update_combat_animation", 0.05)
	_check(absf(weapon.rotation.x) > 0.01, "heavy windup drives weapon anticipation pose")
	animated.state = 2
	animated.attack_timer = 0.05
	animated.call("_update_combat_animation", 0.05)
	_check(absf(upper.rotation.z) > 0.01, "active heavy attack drives body follow-through")
	animated.state = 0
	animated.is_blocking = true
	for frame in range(5):
		animated.call("_update_combat_animation", 0.05)
	_check(weapon.rotation.x < -0.05, "guard state drives a defensive weapon pose")
	animated.is_blocking = false
	animated.state = 6
	animated.call("_update_combat_animation", 0.05)
	_check(upper.rotation.x < -0.05, "hitstun state drives a hit reaction pose")
	animated._die()
	animated.call("_update_combat_animation", 0.05)
	_check(upper.rotation.x > 0.05, "death state drives a collapse pose")

	var gait_fighter := _new_fighter("GaitFighter", Vector3.ZERO)
	gait_fighter.is_player = true
	var gait_upper := Node3D.new()
	var gait_weapon := Node3D.new()
	var left_leg := Node3D.new()
	var right_leg := Node3D.new()
	var left_arm := Node3D.new()
	var right_arm := Node3D.new()
	gait_fighter.add_child(gait_upper)
	gait_upper.add_child(gait_weapon)
	gait_fighter.add_child(left_leg)
	gait_fighter.add_child(right_leg)
	gait_fighter.add_child(left_arm)
	gait_fighter.add_child(right_arm)
	gait_fighter.set_animation_rig(gait_upper, gait_weapon, left_leg, right_leg, left_arm, right_arm)
	gait_fighter.velocity = Vector3(0.0, 0.0, -5.0)
	gait_fighter.call("_update_combat_animation", 0.12)
	_check(gait_fighter._gait_phase > 0.0, "locomotion advances a continuous gait phase")
	_check(not is_equal_approx(left_leg.rotation.x, right_leg.rotation.x), "walking drives alternating leg swings")
	_check(gait_upper.position.y > 0.0, "walking adds a subtle body bounce")
	gait_fighter.state = 1
	gait_fighter.call("_update_combat_animation", 0.12)
	_check(absf(left_leg.rotation.x) < 0.2 and absf(right_leg.rotation.x) < 0.2, "attack states suppress locomotion leg swings")
	gait_fighter.state = 0
	gait_fighter.velocity = Vector3.ZERO
	gait_fighter.call("_update_combat_animation", 0.2)
	_check(absf(left_leg.rotation.x) < 0.1 and absf(right_leg.rotation.x) < 0.1, "legs settle back to idle when movement stops")
	gait_fighter.start_attack("slash")
	gait_fighter.attack_timer = 0.18
	gait_fighter.call("_update_combat_animation", 0.06)
	_check(absf(right_arm.rotation.x) > 0.05 and absf(left_arm.rotation.x) > 0.05, "attack anticipation coordinates both arm pivots")
	gait_fighter.state = 0
	gait_fighter.is_blocking = true
	gait_fighter.call("_update_combat_animation", 0.06)
	_check(right_arm.rotation.z < -0.05, "guard pose raises the weapon arm into a defensive angle")

	var feedback_log: Array[String] = []
	var feedback_receiver := _new_fighter("FeedbackReceiver", Vector3.ZERO)
	var feedback_source := _new_fighter("FeedbackSource", Vector3(0, 0, -1))
	feedback_receiver.combat_feedback.connect(func(kind: String, _source: Node3D) -> void: feedback_log.append(kind))
	feedback_receiver.receive_strike(8.0, 5.0, feedback_source)
	_check(feedback_log.has("hit"), "successful vitality hit emits combat feedback")
	feedback_receiver.end_block()
	var feedback_guard := _new_fighter("FeedbackGuard", Vector3.ZERO)
	feedback_guard.combat_feedback.connect(func(kind: String, _source: Node3D) -> void: feedback_log.append(kind))
	feedback_guard.begin_deflect()
	feedback_guard.receive_strike(8.0, 5.0, feedback_source)
	_check(feedback_log.has("deflect"), "perfect deflect emits combat feedback")
	_check(ResourceLoader.exists("res://audio/impact_body.wav"), "original body impact sound is included")
	_check(ResourceLoader.exists("res://audio/sword_deflect.wav"), "original sword deflect sound is included")
	_check(ResourceLoader.exists("res://audio/guard_clang.wav"), "original guard clang sound is included")
	_check(ResourceLoader.exists("res://audio/posture_break.wav"), "original posture break sound is included")

	var combo := _new_fighter("ComboPlayer", Vector3.ZERO)
	combo.is_player = true
	_check(combo.request_player_attack(), "first combo input starts a slash")
	_check(combo.attack_kind == "slash", "combo opener uses slash")
	_check(combo.request_player_attack(), "second combo input is buffered during windup")
	_check(combo.buffered_attack_kind == "slash", "second combo stage is queued")
	combo.state = 3
	combo.attack_timer = 0.01
	combo.call("_update_attack_state", 0.02)
	_check(combo.state == 1 and combo.attack_kind == "slash", "buffered slash starts immediately after recovery")
	_check(combo.request_player_attack(), "third combo input is buffered")
	_check(combo.buffered_attack_kind == "heavy", "third combo stage queues a heavy finisher")
	combo.state = 3
	combo.attack_timer = 0.01
	combo.call("_update_attack_state", 0.02)
	_check(combo.attack_kind == "heavy" and combo.state == 1, "heavy finisher follows the second slash")
	combo.state = 1
	combo.buffered_attack_kind = "slash"
	combo.attack_buffer_timer = 0.1
	combo.call("_physics_process", 0.2)
	_check(combo.buffered_attack_kind.is_empty(), "expired input buffer is discarded")

	var dodger := _new_fighter("Dodger", Vector3.ZERO)
	dodger.dodge()
	_check(dodger.is_dodging, "dodge grants an active evasion window")
	_check(dodger.receive_strike(20.0, 20.0, attacker) == "evaded", "dodge window evades incoming strike")
	var dodge_timer_before: float = dodger.dodge_timer
	dodger.dodge()
	_check(is_equal_approx(dodger.dodge_timer, dodge_timer_before), "dodge cooldown prevents immediate repeat")

	var grab_defender := _new_fighter("GrabDefender", Vector3.ZERO)
	grab_defender.begin_block()
	_check(grab_defender.receive_strike(30.0, 12.0, attacker, "grab") == "grabbed", "grab bypasses held guard")
	_check(grab_defender.vitality < 100.0 and grab_defender.hit_reaction_timer > 0.5, "grab applies damage and extended hit reaction")
	var grab_deflector := _new_fighter("GrabDeflector", Vector3.ZERO)
	grab_deflector.begin_deflect()
	_check(grab_deflector.receive_strike(30.0, 12.0, attacker, "grab") == "grabbed", "grab cannot be deflected")
	var grab_evader := _new_fighter("GrabEvader", Vector3.ZERO)
	grab_evader.dodge()
	_check(grab_evader.receive_strike(30.0, 12.0, attacker, "grab") == "evaded", "dodge evades a grab")

	var stomp_player := _new_fighter("StompPlayer", Vector3.ZERO)
	var stomp_target := _new_fighter("StompTarget", Vector3(0, 0, -1.2))
	stomp_player.is_player = true
	stomp_player.target = stomp_target
	stomp_target.state = 4
	_check(stomp_player.stomp_broken_target(), "stomp punishes a nearby posture-broken target")
	_check(is_equal_approx(stomp_target.vitality, 82.0), "stomp deals vitality damage to broken target")
	_check(not stomp_player.stomp_broken_target(), "stomp cannot be repeated on the same posture break")
	var distant_stomp := _new_fighter("DistantStomp", Vector3.ZERO)
	var distant_target := _new_fighter("DistantTarget", Vector3(0, 0, -4.0))
	distant_stomp.target = distant_target
	distant_target.state = 4
	_check(not distant_stomp.stomp_broken_target(), "stomp requires close range")

	var sprinter := _new_fighter("Sprinter", Vector3.ZERO)
	sprinter.is_player = true
	sprinter.input_move = Vector2(0, -1)
	sprinter.call("_player_update", 0.016)
	_check(sprinter.is_sprinting and sprinter.velocity.length() > sprinter.move_speed, "full joystick deflection triggers sprint speed")
	sprinter.input_move = Vector2(0, -0.6)
	sprinter.sprint_requested = true
	sprinter.call("_player_update", 0.016)
	_check(sprinter.is_sprinting and sprinter.velocity.length() > sprinter.move_speed * 0.6 * 1.2, "keyboard sprint request works below full joystick deflection")

	print("Combat tests: ", 74 - failures.size(), "/74 passed")
	if not failures.is_empty():
		quit(1)
	else:
		quit(0)
