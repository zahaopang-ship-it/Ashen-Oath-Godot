extends SceneTree

const FIGHTER = preload("res://scripts/fighter.gd")
const MAIN = preload("res://scripts/main.gd")
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
	_check(get_nodes_in_group("water_zones").size() == 1, "arena creates a dedicated water volume")
	_check(get_nodes_in_group("water_zones")[0].body_entered.is_connected(game._on_water_body_entered), "water volume is wired to player swim transitions")
	player.enter_water(0.7)
	_check(player.is_swimming and is_equal_approx(player.body_collision.shape.height, 1.25), "entering water switches to the swimming collision profile")
	player.input_move = Vector2(0.0, -1.0)
	var swim_start: Vector3 = player.global_position
	for i in range(12):
		await physics_frame
	_check(player.global_position.z < swim_start.z, "swimming applies horizontal movement input")
	player.exit_water()
	_check(not player.is_swimming and is_equal_approx(player.body_collision.shape.height, 1.8), "leaving water restores the standing collision profile")
	player.input_move = Vector2.ZERO
	player.global_position = Vector3(0.0, 0.0, 4.0)
	player.rotation.y = 0.0
	var climb_wall := StaticBody3D.new()
	climb_wall.position = Vector3(0.0, 2.5, 3.25)
	climb_wall.add_to_group("climbable_surfaces")
	game.add_child(climb_wall)
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3.0, 5.0, 0.45)
	wall_shape.shape = wall_box
	climb_wall.add_child(wall_shape)
	await physics_frame
	var climb_query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.95, player.global_position + Vector3.UP * 0.95 + Vector3(0.0, 0.0, -0.9))
	climb_query.exclude = [player.get_rid()]
	_check(player.try_vertical_climb(), "player can attach to a vertical climb surface")
	_check(player.is_climbing, "vertical climb enters a dedicated movement state")
	var climb_start_y: float = player.global_position.y
	player.input_move = Vector2(0.0, -1.0)
	for i in range(20):
		await physics_frame
	_check(player.global_position.y > climb_start_y + 0.45, "vertical climb moves player upward from joystick input")
	player.stop_vertical_climb()
	_check(not player.is_climbing, "vertical climb can be safely disengaged")
	player.input_move = Vector2.ZERO
	climb_wall.queue_free()
	await physics_frame
	player.global_position = Vector3(0.0, 1.0, 4.0)
	player.velocity = Vector3(0.0, -2.0, 0.0)
	var ledge := StaticBody3D.new()
	ledge.position = Vector3(0.0, 1.25, 3.25)
	ledge.add_to_group("climbable_surfaces")
	game.add_child(ledge)
	var ledge_shape := CollisionShape3D.new()
	var ledge_box := BoxShape3D.new()
	ledge_box.size = Vector3(3.0, 2.5, 0.45)
	ledge_shape.shape = ledge_box
	ledge.add_child(ledge_shape)
	await physics_frame
	var ledge_query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.35, player.global_position + Vector3.UP * 1.35 + Vector3(0.0, 0.0, -0.9))
	ledge_query.exclude = [player.get_rid()]
	_check(player.try_ledge_grab(), "falling player can catch the top edge of a reachable ledge")
	_check(player.is_ledge_hanging, "ledge grab enters a stable hanging state")
	player.input_move = Vector2(0.0, -1.0)
	await physics_frame
	_check(player.is_vaulting and player._traversal_kind == "ledge_mantle", "upward input starts a ledge mantle transition")
	for i in range(35):
		await physics_frame
	_check(not player.is_ledge_hanging and not player.is_vaulting and player.global_position.y > 2.0, "ledge mantle completes onto the raised platform")
	if failures.is_empty():
		print("Traversal expansion tests: 14/14 passed")
	else:
		printerr("Traversal expansion tests: ", 14 - failures.size(), "/14 passed")
	quit(0 if failures.is_empty() else 1)
