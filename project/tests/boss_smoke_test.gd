extends SceneTree

const BOSS = preload("res://scripts/boss.gd")
const FIGHTER = preload("res://scripts/fighter.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
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
	_check(boss.get_phase_pattern() == ["sweep", "grab", "thrust", "heavy"], "phase two switches to sweep and grab sequence")
	_check(boss.move_speed > 4.4 and boss.attack_range > 2.5, "phase two increases aggression and reach")
	boss.vitality = 50.0
	boss._physics_process(0.016)
	_check(phases.size() == 1, "phase transition does not retrigger")
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
	print("Boss tests: ", 9 - failures, "/9 passed")
	quit(1 if failures > 0 else 0)
