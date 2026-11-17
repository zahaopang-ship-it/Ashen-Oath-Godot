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
	var world := Node3D.new()
	root.add_child(world)
	var floor := StaticBody3D.new()
	world.add_child(floor)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(20.0, 0.5, 20.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.25
	floor.add_child(floor_shape)

	var player := CharacterBody3D.new()
	player.set_script(FIGHTER)
	player.is_player = true
	world.add_child(player)
	var capsule_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule_node.shape = capsule
	capsule_node.position.y = 0.9
	player.add_child(capsule_node)
	player.body_collision = capsule_node
	await physics_frame

	player.enter_water(0.9)
	_check(player.is_swimming, "water entry activates the dedicated swimming state")
	_check(is_equal_approx(capsule.height, 1.25), "swimming lowers the collision capsule for water movement")
	player.set_swim_vertical_input(1.0)
	_check(is_equal_approx(player.swim_vertical_input, 1.0), "touch surface control applies upward swim input")
	player.set_swim_vertical_input(-1.0)
	_check(is_equal_approx(player.swim_vertical_input, -1.0), "touch dive control applies downward swim input")
	player.set_swim_vertical_input(0.0)
	player.exit_water()
	_check(not player.is_swimming and is_equal_approx(capsule.height, 1.8), "water exit restores normal collision and movement state")
	_check(is_equal_approx(player.swim_vertical_input, 0.0), "water exit clears held vertical swim input")

	var climb_wall := StaticBody3D.new()
	climb_wall.position = Vector3(0.0, 1.5, -0.65)
	climb_wall.add_to_group("climbable_surfaces")
	world.add_child(climb_wall)
	var climb_shape := CollisionShape3D.new()
	var climb_box := BoxShape3D.new()
	climb_box.size = Vector3(3.0, 3.0, 0.5)
	climb_shape.shape = climb_box
	climb_wall.add_child(climb_shape)
	player.global_position = Vector3(0.0, 0.0, 0.2)
	player.rotation.y = 0.0
	await physics_frame
	_check(player.try_vertical_climb(), "player can attach to an explicitly marked climbable wall")
	_check(player.is_climbing, "vertical climb enters its own traversal state")
	player.input_move = Vector2(0.0, -1.0)
	var climb_start_y := player.global_position.y
	player._update_vertical_climb(0.2)
	_check(player.global_position.y > climb_start_y, "upward movement climbs the wall instead of sliding")
	player.stop_vertical_climb()
	_check(not player.is_climbing, "vertical climb can be safely cancelled")
	var ordinary_wall := StaticBody3D.new()
	ordinary_wall.position = Vector3(0.0, 1.5, -0.65)
	world.add_child(ordinary_wall)
	var ordinary_shape := CollisionShape3D.new()
	var ordinary_box := BoxShape3D.new()
	ordinary_box.size = Vector3(3.0, 3.0, 0.5)
	ordinary_shape.shape = ordinary_box
	ordinary_wall.add_child(ordinary_shape)
	player.global_position = Vector3(0.0, 0.0, 0.2)
	player.velocity = Vector3.ZERO
	await physics_frame
	_check(not player.try_vertical_climb(), "ordinary unmarked walls cannot be climbed")
	ordinary_wall.queue_free()
	await physics_frame
	player.global_position = Vector3(0.0, 0.0, 0.2)
	player.velocity = Vector3.ZERO
	await physics_frame
	_check(player.try_vertical_climb(), "climbable wall can be reattached for top-edge validation")
	player.input_move = Vector2(0.0, -1.0)
	for i in range(80):
		await physics_frame
		if not player.is_climbing:
			break
	_check(not player.is_climbing and player.global_position.y < 2.0, "climb automatically releases at the wall top instead of passing through it")

	player.global_position = Vector3(0.0, 1.5, 0.0)
	player.velocity = Vector3(0.0, -1.0, 0.0)
	player.input_move = Vector2.ZERO
	player.rotation.y = 0.0
	await physics_frame
	_check(player.try_ledge_grab(), "falling player can catch a reachable ledge")
	_check(player.is_ledge_hanging, "ledge catch enters a stable hanging state")
	var hang_y := player.global_position.y
	player.input_move = Vector2(0.0, -1.0)
	player._update_ledge_hang(0.016)
	_check(not player.is_ledge_hanging and player.is_vaulting, "upward input starts a ledge mantle")
	player._update_vault(0.6)
	_check(not player.is_vaulting and player.global_position.z > 0.5, "ledge mantle climbs onto the safe side of the platform")
	_check(hang_y > 0.0, "ledge hang remains above the ground while attached")

	var game := Node3D.new()
	game.set_script(MAIN)
	root.add_child(game)
	await process_frame
	await physics_frame
	var arena_player: CharacterBody3D = game.player
	arena_player.global_position = Vector3(9.0, 0.0, -7.0)
	await physics_frame
	await physics_frame
	_check(arena_player.is_swimming, "entering the arena pond triggers swimming through Area3D overlap")
	arena_player.global_position = Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	_check(not arena_player.is_swimming, "leaving the arena pond restores ground movement through Area3D exit")

	if failures.is_empty():
		print("Traversal world tests: 20/20 passed")
	else:
		printerr("Traversal world tests: ", 20 - failures.size(), "/20 passed")
	quit(0 if failures.is_empty() else 1)
