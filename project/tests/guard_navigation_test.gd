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
	if failures.is_empty():
		print("Guard navigation tests: 6/6 passed")
	else:
		printerr("Guard navigation tests: ", 6 - failures.size(), "/6 passed")
	quit(0 if failures.is_empty() else 1)
