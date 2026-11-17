extends SceneTree

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
	var guard: CharacterBody3D = game.guard
	guard.global_position = Vector3(0.0, 0.0, 4.0)
	var nav_region := game.get_node_or_null("AshenValeNavigationRegion") as NavigationRegion3D
	_check(nav_region != null and nav_region.navigation_mesh != null and nav_region.navigation_mesh.get_polygon_count() == 1, "Ashen Vale registers a shared walkable navigation region")
	var agent := guard.navigation_agent as NavigationAgent3D
	_check(agent != null, "each sentinel owns a NavigationAgent3D")
	if agent != null:
		agent.target_position = Vector3(-12.0, 0.0, -8.0)
		await physics_frame
		await physics_frame
		await physics_frame
		agent.get_next_path_position()
		var route: PackedVector3Array = agent.get_current_navigation_path()
		_check(route.size() >= 2, "sentinel agent computes a route across the valley")
		if route.size() >= 2:
			_check(route[route.size() - 1].distance_to(agent.target_position) < 1.0, "global route reaches the requested destination")
		var routed_direction: Vector3 = guard._get_global_route_direction(Vector3(-12.0, 0.0, -8.0), Vector3.FORWARD)
		_check(routed_direction.dot(Vector3(-1.0, 0.0, -1.0).normalized()) > 0.95, "AI steering consumes the NavigationAgent route direction")
	var desired := Vector3.FORWARD
	var clear_direction: Vector3 = guard._get_navigation_direction(desired)
	_check(clear_direction.is_equal_approx(desired), "guard keeps its direct route when the probe corridor is clear")
	var wall := StaticBody3D.new()
	wall.position = guard.global_position + Vector3(0.0, 0.0, -1.0)
	game.add_child(wall)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 2.0, 0.35)
	shape.shape = box
	wall.add_child(shape)
	await physics_frame
	var detour: Vector3 = guard._get_navigation_direction(desired)
	_check(detour.dot(desired) < 0.9, "guard selects a lateral detour when a solid wall blocks its direct route")
	_check(detour.length() > 0.95 and absf(detour.x) > 0.25, "detour retains forward progress while steering around the obstacle")
	var obstacle_count := game.get_children().size()
	guard._steer_ai_toward(guard.global_position + desired * 5.0, 1.5, 0.1, 4.0)
	_check(Vector2(guard.velocity.x, guard.velocity.z).length() > 0.1, "AI steering produces controlled movement velocity")
	_check(game.get_children().size() == obstacle_count, "navigation probes do not spawn temporary world nodes")
	wall.queue_free()
	await process_frame
	var restored: Vector3 = guard._get_navigation_direction(desired)
	_check(restored.is_equal_approx(desired), "guard resumes its direct route after the obstacle is removed")
	var nearby_guard := CharacterBody3D.new()
	nearby_guard.position = guard.global_position + Vector3(0.8, 0.0, -0.8)
	var nearby_shape := CollisionShape3D.new()
	var nearby_capsule := CapsuleShape3D.new()
	nearby_capsule.radius = 0.38
	nearby_capsule.height = 1.7
	nearby_shape.shape = nearby_capsule
	nearby_guard.add_child(nearby_shape)
	nearby_guard.add_to_group("stealth_guards")
	game.add_child(nearby_guard)
	guard.add_to_group("stealth_guards")
	var separated: Vector3 = guard._apply_guard_separation(Vector3.FORWARD)
	_check(separated.dot(Vector3.FORWARD) < 0.98, "guard separation steers away from a nearby sentinel")
	_check(separated.length() > 0.98 and absf(separated.x) > 0.15, "crowd avoidance keeps a usable travel direction while creating lateral spacing")
	nearby_guard.position = guard.global_position + Vector3(0.0, 0.0, -4.0)
	var distant: Vector3 = guard._apply_guard_separation(Vector3.FORWARD)
	_check(distant.is_equal_approx(Vector3.FORWARD), "sentinels do not influence each other outside the separation radius")
	if failures.is_empty():
		print("Guard navigation tests: 14/14 passed")
	else:
		printerr("Guard navigation tests: ", 14 - failures.size(), "/14 passed")
	quit(0 if failures.is_empty() else 1)
