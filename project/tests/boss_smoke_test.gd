extends SceneTree

const BOSS = preload("res://scripts/boss.gd")
const FIGHTER = preload("res://scripts/fighter.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	var boss := CharacterBody3D.new()
	boss.set_script(BOSS)
	root.add_child(boss)
	var player := CharacterBody3D.new()
	player.set_script(FIGHTER)
	player.is_player = true
	player.position = Vector3(0, 0, -1.6)
	root.add_child(player)
	boss.target = player
	_check(boss.max_vitality == 420.0 and boss.vitality == 420.0, "boss has dedicated vitality pool")
	_check(boss.max_posture == 260.0, "boss has dedicated posture pool")
	_check(boss.boss_phase == 1, "boss starts in phase one")
	_check(boss.get_phase_pattern() == ["slash", "thrust", "heavy", "slash"], "phase one uses its authored attack sequence")
	var phases: Array[int] = []
	boss.boss_phase_changed.connect(func(phase: int) -> void: phases.append(phase))
	boss.vitality = 230.0
	boss._physics_process(0.016)
	_check(boss.boss_phase == 2 and phases == [2], "vitality threshold triggers phase transition once")
	_check(boss.get_phase_pattern() == ["sweep", "grab", "thrust", "ashen_rend"], "phase two switches to sweep, grab, thrust and signature finisher sequence")
	_check(boss.move_speed > 4.4 and boss.attack_range > 2.5, "phase two increases aggression and reach")
	boss.vitality = 50.0
	boss._physics_process(0.016)
	_check(phases.size() == 1 and boss.phase_transition_count == 1, "phase transition does not retrigger")
	boss._die()
	_check(boss.is_dead, "boss supports the standard terminal death state")
	var damage_boss := CharacterBody3D.new()
	damage_boss.set_script(BOSS)
	root.add_child(damage_boss)
	var damage_target := CharacterBody3D.new()
	damage_target.set_script(FIGHTER)
	damage_target.position = Vector3(0, 0, -1.4)
	root.add_child(damage_target)
	damage_boss.target = damage_target
	damage_boss.boss_phase = 2
	damage_boss.attack_kind = "slash"
	damage_boss._resolve_attack_hit()
	_check(is_equal_approx(damage_target.vitality, 74.04), "phase two applies increased boss attack damage")
	var execution_player := CharacterBody3D.new()
	execution_player.set_script(FIGHTER)
	execution_player.is_player = true
	execution_player.position = Vector3.ZERO
	root.add_child(execution_player)
	var execution_boss := CharacterBody3D.new()
	execution_boss.set_script(BOSS)
	execution_boss.position = Vector3(0, 0, -1.5)
	root.add_child(execution_boss)
	execution_player.target = execution_boss
	execution_boss.target = execution_player
	_check(not execution_player.deathblow_broken_target(), "deathblow is rejected before posture break")
	execution_boss.state = 4
	execution_boss.posture = execution_boss.max_posture
	_check(execution_player.deathblow_broken_target(), "deathblow executes a nearby posture-broken boss")
	_check(not execution_boss.is_dead and execution_boss.state == 7 and execution_player.state == 7 and execution_boss.deathblow_executed, "deathblow begins a synchronized attacker-victim execution sequence")
	var execution_attack_rejected: bool = not execution_player.start_attack("slash")
	execution_player.dodge()
	_check(execution_attack_rejected and execution_player.state == 7, "normal combat inputs are locked during the execution")
	execution_boss._physics_process(0.35)
	execution_player._physics_process(0.35)
	_check(not execution_boss.is_dead and execution_boss.state == 7 and execution_boss.execution_timer > 0.0, "victim remains in the execution pose during the cinematic window")
	execution_boss._physics_process(0.5)
	execution_player._physics_process(0.5)
	_check(execution_boss.is_dead and execution_boss.vitality == 0.0 and execution_player.state == 0, "execution animation completes before the boss enters terminal death")
	_check(not execution_player.deathblow_broken_target() and not execution_boss.receive_deathblow(execution_player), "deathblow cannot be repeated after the cinematic sequence")
	var distant_player := CharacterBody3D.new()
	distant_player.set_script(FIGHTER)
	distant_player.is_player = true
	root.add_child(distant_player)
	var distant_boss := CharacterBody3D.new()
	distant_boss.set_script(BOSS)
	distant_boss.position = Vector3(0, 0, -4.0)
	distant_boss.state = 4
	root.add_child(distant_boss)
	distant_player.target = distant_boss
	_check(not distant_player.deathblow_broken_target(), "deathblow requires close execution range")
	var turned_player := CharacterBody3D.new()
	turned_player.set_script(FIGHTER)
	turned_player.is_player = true
	turned_player.rotation.y = PI
	root.add_child(turned_player)
	var turned_boss := CharacterBody3D.new()
	turned_boss.set_script(BOSS)
	turned_boss.position = Vector3(0, 0, -1.5)
	turned_boss.state = 4
	root.add_child(turned_boss)
	turned_player.target = turned_boss
	_check(not turned_player.deathblow_broken_target(), "deathblow requires player to face the broken target")
	var signature_boss := CharacterBody3D.new()
	signature_boss.set_script(BOSS)
	root.add_child(signature_boss)
	_check(signature_boss.get_phase_pattern().has("ashen_rend") == false, "phase one does not use the phase-two signature attack")
	signature_boss.boss_phase = 2
	_check(signature_boss.get_phase_pattern().has("ashen_rend"), "phase two includes the telegraphed Ashen Rend signature attack")
	_check(signature_boss.start_attack("ashen_rend") and signature_boss.attack_timer == 0.92, "Ashen Rend starts with its longer punishable telegraph")
	print("Boss tests: ", checks - failures, "/", checks, " passed")
	quit(1 if failures > 0 else 0)
