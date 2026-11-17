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
	_check(victim.vitality < 100.0, "active attack resolves hit within range")
	var health_after: float = victim.vitality
	striker.call("_resolve_attack_hit")
	_check(is_equal_approx(victim.vitality, health_after), "one attack cannot hit same target twice")

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

	var dodger := _new_fighter("Dodger", Vector3.ZERO)
	dodger.dodge()
	_check(dodger.is_dodging, "dodge grants an active evasion window")
	_check(dodger.receive_strike(20.0, 20.0, attacker) == "evaded", "dodge window evades incoming strike")

	print("Combat tests: ", 39 - failures.size(), "/39 passed")
	if not failures.is_empty():
		quit(1)
	else:
		quit(0)
