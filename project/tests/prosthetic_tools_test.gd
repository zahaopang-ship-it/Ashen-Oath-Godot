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

func _new_fighter(label: String, pos: Vector3, player_controlled: bool = false) -> CharacterBody3D:
	var fighter := CharacterBody3D.new()
	fighter.name = label
	fighter.set_script(FIGHTER)
	fighter.position = pos
	fighter.is_player = player_controlled
	root.add_child(fighter)
	return fighter

func _run() -> void:
	var player := _new_fighter("ToolUser", Vector3.ZERO, true)
	var target := _new_fighter("ShurikenTarget", Vector3(0.0, 0.0, -5.0))
	player.target = target
	target.target = player
	var initial_energy: float = player.prosthetic_energy
	_check(player.use_prosthetic("shuriken"), "shuriken fires at a target within range and forward arc")
	_check(target.vitality < 100.0 and target.posture > 0.0, "shuriken deals light vitality and posture damage")
	_check(is_equal_approx(player.prosthetic_energy, initial_energy - 18.0), "shuriken consumes its spirit-emblem cost")
	_check(root.find_child("ProstheticShuriken", true, false) != null, "shuriken spawns a visible short-flight projectile")
	var energy_after_miss: float = player.prosthetic_energy
	player.target = null
	_check(not player.use_prosthetic("shuriken"), "shuriken refuses to fire without a valid target")
	_check(is_equal_approx(player.prosthetic_energy, energy_after_miss), "failed shuriken use does not consume energy")
	player.target = target
	player.prosthetic_cooldown = 0.0
	target.global_position = Vector3(0.0, 0.0, -2.0)
	var posture_before: float = target.posture
	_check(player.use_prosthetic("axe"), "prosthetic axe connects with a nearby frontal target")
	_check(target.posture > posture_before + 40.0, "axe inflicts heavy posture pressure")
	_check(target.vitality < 90.0, "axe also deals a heavy impact")
	var guard := _new_fighter("DistractedGuard", Vector3(1.0, 0.0, -2.0))
	guard.add_to_group("stealth_guards")
	guard.target = player
	player.prosthetic_cooldown = 0.0
	var firecracker_energy: float = player.prosthetic_energy
	_check(player.use_prosthetic("firecracker"), "firecracker can be deployed as an area distraction")
	_check(guard.awareness_state == guard.AwarenessState.SEARCHING, "firecracker redirects a nearby guard to investigate its sound position")
	_check(guard._search_points.size() == 1 and guard._search_points[0].distance_to(player.global_position - player.global_transform.basis.z * 3.0) < 0.1, "guard investigates the firecracker position rather than the player's live position")
	_check(guard.state == guard.CombatState.HITSTUN, "firecracker briefly interrupts a nearby free guard")
	_check(player.prosthetic_energy < firecracker_energy, "firecracker consumes spirit emblems")
	_check(root.find_child("FirecrackerBurst", true, false) != null, "firecracker spawns a short-lived emissive burst")
	player.prosthetic_cooldown = 0.0
	player.prosthetic_energy = 100.0
	_check(player.use_prosthetic("umbrella"), "umbrella opens from neutral")
	_check(player.is_blocking and player.umbrella_timer > 1.0, "umbrella creates a timed defensive guard window")
	_check(player.receive_strike(25.0, 30.0, target, "heavy") == "blocked", "umbrella guard blocks a heavy strike")
	player.umbrella_timer = 0.01
	player._physics_process(0.02)
	_check(not player.is_blocking and player.umbrella_timer == 0.0, "umbrella automatically closes when its guard window expires")
	var energy: float = player.prosthetic_energy
	player.prosthetic_energy = 0.0
	_check(not player.use_prosthetic("umbrella"), "tools cannot be used without sufficient spirit emblems")
	_check(is_equal_approx(player.prosthetic_energy, 0.0), "insufficient energy remains unchanged")
	player.prosthetic_energy = 50.0
	player._physics_process(1.0)
	_check(player.prosthetic_energy > 55.0, "spirit emblems regenerate gradually while the player is free")
	player.prosthetic_energy = energy
	_check(not player.use_prosthetic("unknown"), "unknown prosthetic tools are rejected")
	if failures.is_empty():
		print("Prosthetic tools tests: 23/23 passed")
	else:
		printerr("Prosthetic tools tests: ", 23 - failures.size(), "/23 passed")
	quit(0 if failures.is_empty() else 1)
