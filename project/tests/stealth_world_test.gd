extends SceneTree

const MAIN_SCRIPT = preload("res://scripts/main.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var game := Node3D.new()
	game.set_script(MAIN_SCRIPT)
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	_check(get_nodes_in_group("stealth_cover").size() == 3, "arena creates three physical stealth cover props")
	_check(get_nodes_in_group("stealth_cover_zones").size() == 3, "each cover prop has a concealment zone")
	var player: CharacterBody3D = game.player
	var guard: CharacterBody3D = game.guard
	var zone: Area3D = get_nodes_in_group("stealth_cover_zones")[0]
	player.global_position = zone.global_position
	player.set_crouching(true)
	await physics_frame
	await physics_frame
	_check(player.is_in_cover, "player entering a cover zone is detected by the physics area")
	_check(is_equal_approx(guard._get_target_vision_multiplier(player), 0.16), "crouched player in cover receives deep concealment")
	_check(not guard._has_clear_line_of_sight(player), "solid cover geometry blocks guard line of sight")
	player.global_position = Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	_check(not player.is_in_cover, "leaving cover zone restores normal visibility")
	if failures.is_empty():
		print("Stealth world tests: 5/5 passed")
	else:
		printerr("Stealth world tests: ", 5 - failures.size(), "/5 passed")
	quit(0 if failures.is_empty() else 1)
