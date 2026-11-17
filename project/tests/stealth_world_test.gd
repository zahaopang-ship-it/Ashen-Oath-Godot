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
	player.global_position = Vector3(0.0, 0.0, 4.0)
	player.rotation.y = 0.0
	await physics_frame
	await physics_frame
	var obstacle := StaticBody3D.new()
	obstacle.position = Vector3(0.0, 0.0, 2.8)
	game.add_child(obstacle)
	var obstacle_shape := CollisionShape3D.new()
	var obstacle_box := BoxShape3D.new()
	obstacle_box.size = Vector3(1.2, 0.8, 0.4)
	obstacle_shape.shape = obstacle_box
	obstacle_shape.position.y = 0.4
	obstacle.add_child(obstacle_shape)
	await physics_frame
	var start_z := player.global_position.z
	_check(player.try_vault(), "player can vault a low obstacle in the live arena")
	_check(player.is_vaulting, "vault enters a dedicated traversal state")
	for i in range(30):
		await physics_frame
	_check(not player.is_vaulting and player.global_position.z < start_z - 1.4, "vault completes beyond the obstacle")
	var ledge := StaticBody3D.new()
	ledge.position = player.global_position + Vector3(0.0, 0.65, -1.4)
	game.add_child(ledge)
	var ledge_shape := CollisionShape3D.new()
	var ledge_box := BoxShape3D.new()
	ledge_box.size = Vector3(2.4, 1.3, 1.8)
	ledge_shape.shape = ledge_box
	ledge.add_child(ledge_shape)
	await physics_frame
	var mantle_start_y := player.global_position.y
	_check(player.try_mantle(), "player can mantle a reachable waist-high ledge")
	_check(player.is_vaulting and player._traversal_kind == "mantle", "mantle enters the dedicated ledge traversal")
	for i in range(42):
		await physics_frame
	_check(not player.is_vaulting and player.global_position.y > mantle_start_y + 0.7, "mantle completes on the raised platform")
	var tall_wall := StaticBody3D.new()
	tall_wall.position = player.global_position + Vector3(0.0, 0.0, -1.2)
	game.add_child(tall_wall)
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(1.2, 2.0, 0.4)
	wall_shape.shape = wall_box
	wall_shape.position.y = 1.0
	tall_wall.add_child(wall_shape)
	await physics_frame
	_check(not player.try_vault(), "vault rejects a full-height wall")
	_check(not player.is_vaulting, "rejected traversal leaves player in normal movement state")
	if failures.is_empty():
		print("Stealth world tests: 14/14 passed")
	else:
		printerr("Stealth world tests: ", 14 - failures.size(), "/14 passed")
	quit(0 if failures.is_empty() else 1)
