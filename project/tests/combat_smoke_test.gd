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

	var dodger := _new_fighter("Dodger", Vector3.ZERO)
	dodger.dodge()
	_check(dodger.is_dodging, "dodge grants an active evasion window")
	_check(dodger.receive_strike(20.0, 20.0, attacker) == "evaded", "dodge window evades incoming strike")

	print("Combat tests: ", 25 - failures.size(), "/25 passed")
	if not failures.is_empty():
		quit(1)
	else:
		quit(0)
