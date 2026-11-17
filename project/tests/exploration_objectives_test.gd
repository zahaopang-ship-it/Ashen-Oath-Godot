extends SceneTree

const MAIN = preload("res://scripts/main.gd")
const HUD = preload("res://scripts/touch_hud.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var game := Node3D.new()
	game.set_script(MAIN)
	root.add_child(game)
	await process_frame
	await physics_frame
	var player: CharacterBody3D = game.player
	var objectives: Node = game.exploration_objectives
	_check(objectives.stage == 0 and not objectives.completed, "grove oath begins with the relic discovery objective")
	_check(objectives.get_status_text().contains("hidden relic cache"), "initial objective explains the first exploration step")
	player.global_position = Vector3(-21.0, 0.0, -7.1)
	_check(player.interact_secret_cache(), "relic cache can trigger the objective chain")
	_check(objectives.stage == 1 and not objectives.completed, "finding the relic advances the oath to its shrine destination")
	_check(objectives.get_status_text().contains("Grove Rest Shrine"), "second objective names the linked grove shrine")
	var upgrade_before: int = player.prosthetic_upgrade_points
	var energy_before: float = player.prosthetic_energy
	player.global_position = Vector3(-16.5, 0.0, -16.6)
	_check(player.interact_rest_point(), "visiting the grove shrine advances the linked objective")
	_check(objectives.completed and objectives.stage == 2, "the two-step grove oath completes")
	_check(player.prosthetic_upgrade_points == upgrade_before + 2, "completed oath grants two additional prosthetic upgrade points")
	_check(player.prosthetic_energy == minf(player.max_prosthetic_energy, energy_before + 35.0), "completed oath grants spirit energy")
	var completed_points: int = player.prosthetic_upgrade_points
	player.global_position = Vector3(-16.5, 0.0, -16.6)
	player.interact_rest_point()
	_check(player.prosthetic_upgrade_points == completed_points, "completed oath cannot pay its reward twice")
	var hud: Node = null
	for child in game.get_children():
		if child.get_script() == HUD:
			hud = child
	_check(is_instance_valid(hud) and is_instance_valid(hud.objective_label), "touch HUD includes a dedicated exploration objective display")
	if failures.is_empty():
		print("Exploration objectives tests: 11/11 passed")
	else:
		printerr("Exploration objectives tests: ", 10 - failures.size(), "/10 passed")
	quit(0 if failures.is_empty() else 1)
