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
	guard.last_known_target_position = Vector3(-5.0, 0.0, -4.0)
	guard._begin_cover_search()
	_check(guard._search_points.size() == 4, "guard search route includes last known position and three nearby cover locations")
	_check(guard._search_points[0].is_equal_approx(guard.last_known_target_position), "guard begins investigation at last known sighting, not the hidden player's live position")
	_check(guard._search_point_index == 0 and guard._search_pause_timer > 0.0, "cover investigation initializes a pause-and-inspect state")
	guard.awareness_state = guard.AwarenessState.SEARCHING
	var expected_search_direction: Vector3 = (guard._search_points[0] - guard.global_position).normalized()
	guard._ai_update(0.1)
	var actual_search_velocity := Vector3(guard.velocity.x, 0.0, guard.velocity.z)
	_check(actual_search_velocity.dot(expected_search_direction) > 0.1, "searching guard physically moves toward the last known position")
	player.global_position = Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	_check(not player.is_in_cover, "leaving cover zone restores normal visibility")
	player.global_position = Vector3(0.0, 0.0, 4.0)
	player.global_position = get_nodes_in_group("stealth_cover_zones")[1].global_position
	player.set_crouching(false)
	_check(not player.begin_cover_transfer(), "cover transfer requires crouching")
	player.set_crouching(true)
	var transfer_start := player.global_position
	_check(player.begin_cover_transfer(), "crouched player selects a nearby cover destination")
	_check(player.is_cover_transferring and is_instance_valid(player._cover_transfer_target), "cover transfer stores a valid destination")
	for i in range(240):
		await physics_frame
		if not player.is_cover_transferring:
			break
	_check(not player.is_cover_transferring and player.is_crouching, "cover transfer completes while crouched")
	_check(player.global_position.distance_to(transfer_start) > 1.5, "cover transfer uses physical movement")
	_check(player.is_in_cover, "cover transfer arrives inside a registered concealment zone")
	player.set_crouching(false)
	player.global_position = Vector3(0.0, 0.0, 4.0)
	player.velocity = Vector3.ZERO
	player.input_move = Vector2.ZERO
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
	var hug_wall := StaticBody3D.new()
	hug_wall.position = player.global_position + Vector3(0.0, 0.0, -0.62)
	game.add_child(hug_wall)
	var hug_shape := CollisionShape3D.new()
	var hug_box := BoxShape3D.new()
	hug_box.size = Vector3(3.0, 2.2, 0.35)
	hug_shape.shape = hug_box
	hug_shape.position.y = 1.1
	hug_wall.add_child(hug_shape)
	await physics_frame
	_check(player.toggle_wall_hug(), "player can enter wall-hug mode beside a solid wall")
	_check(player.is_wall_hugging and player.is_crouching, "wall-hug engages a lowered stealth posture")
	player.input_move = Vector2(1.0, 0.0)
	var hug_start := player.global_position
	for i in range(18):
		await physics_frame
	_check(absf(player.global_position.x - hug_start.x) > 0.08, "wall-hug allows lateral movement along the wall")
	var upper_pose := Node3D.new()
	var weapon_pose := Node3D.new()
	var left_leg_pose := Node3D.new()
	var right_leg_pose := Node3D.new()
	var left_arm_pose := Node3D.new()
	var right_arm_pose := Node3D.new()
	player.add_child(upper_pose)
	player.add_child(weapon_pose)
	player.add_child(left_leg_pose)
	player.add_child(right_leg_pose)
	player.add_child(left_arm_pose)
	player.add_child(right_arm_pose)
	player.set_animation_rig(upper_pose, weapon_pose, left_leg_pose, right_leg_pose, left_arm_pose, right_arm_pose)
	player._update_combat_animation(0.2)
	_check(absf(upper_pose.rotation.z) > 0.08, "wall-hug animation leans the torso toward the wall")
	_check(right_arm_pose.rotation.x < -0.1, "wall-hug animation tucks the weapon arm close to the body")
	_check(player.toggle_wall_hug() and not player.is_wall_hugging, "wall-hug can be exited on demand")
	var corner_wall := StaticBody3D.new()
	corner_wall.position = player.global_position + Vector3(0.5, 0.0, 0.0)
	game.add_child(corner_wall)
	var corner_shape := CollisionShape3D.new()
	var corner_box := BoxShape3D.new()
	corner_box.size = Vector3(0.2, 2.2, 2.4)
	corner_shape.shape = corner_box
	corner_shape.position.y = 1.1
	corner_wall.add_child(corner_shape)
	await physics_frame
	player._wall_hug_normal = Vector3(0.0, 0.0, 1.0)
	_check(player._try_wall_corner_transition(Vector3.RIGHT), "wall-hug detects an adjacent perpendicular wall at a corner")
	_check(absf(player._wall_hug_normal.x) > 0.9, "wall-hug updates its normal to follow the new wall plane")
	player.global_position = zone.global_position
	player.set_crouching(true)
	guard.global_position = player.global_position + Vector3(0.0, 0.0, 1.45)
	guard.rotation.y = 0.0
	guard.awareness_state = guard.AwarenessState.IDLE
	guard.suspicion = 0.0
	guard.lost_sight_timer = 0.0
	_check(guard._has_clear_line_of_sight(player), "guard can see a crouched player exposed at the edge of cover")
	for i in range(90):
		guard._update_awareness(0.1)
	_check(guard.awareness_state == guard.AwarenessState.ALERTED, "guard escalates when its cover inspection gains direct sight of the player")
	if failures.is_empty():
		print("Stealth world tests: 34/34 passed")
	else:
		printerr("Stealth world tests: ", 34 - failures.size(), "/34 passed")
	quit(0 if failures.is_empty() else 1)
