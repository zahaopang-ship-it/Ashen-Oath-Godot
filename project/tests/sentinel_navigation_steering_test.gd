extends SceneTree

const NAVIGATION = preload("res://scripts/ai/sentinel_navigation_steering.gd")
const FIGHTER = preload("res://scripts/fighter.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	var actor := CharacterBody3D.new()
	actor.set_script(FIGHTER)
	root.add_child(actor)
	var fallback := Vector3(0.0, 0.0, -1.0)
	var destination := Vector3(0.0, 0.0, -8.0)
	_check(NAVIGATION.get_global_route_direction(actor, destination, fallback) == fallback, "global navigation safely uses fallback without an agent")
	_check(NAVIGATION.get_navigation_direction(actor, fallback).is_equal_approx(fallback), "local navigation preserves a clear direction outside the physics world")
	_check(NAVIGATION.get_navigation_direction(actor, Vector3.ZERO) == Vector3.ZERO, "local navigation rejects a zero-length direction")
	_check(NAVIGATION.apply_guard_separation(actor, fallback).is_equal_approx(fallback), "separation preserves direction when no crowd context exists")
	NAVIGATION.steer_toward(actor, destination, 2.0, 1.0 / 60.0, 4.0)
	_check(actor.velocity.z < 0.0, "steering accelerates toward the requested destination")
	print("Sentinel navigation module tests: ", checks - failures, "/", checks, " passed")
	quit(1 if failures > 0 else 0)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]