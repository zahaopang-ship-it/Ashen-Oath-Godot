extends SceneTree

const CAMERA_RIG = preload("res://scripts/camera/combat_camera_rig.gd")
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

func _fighter(label: String, position: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = label
	actor.set_script(FIGHTER)
	root.add_child(actor)
	actor.global_position = position
	return actor

func _run() -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	var rig = CAMERA_RIG.new()
	rig.configure(camera)
	var player := _fighter("CameraPlayer", Vector3.ZERO)
	var enemy := _fighter("CameraEnemy", Vector3(0.0, 0.0, -10.0))
	var marker := MeshInstance3D.new()
	root.add_child(marker)
	marker.visible = true
	rig.update_camera(1.0 / 60.0, player, enemy, marker)
	_check(camera.global_position.length() > 0.1, "camera rig computes a follow-camera position")
	_check(camera.global_transform.basis.z.length() > 0.9, "camera rig aims toward the combat focus")
	var original_yaw: float = rig.yaw
	var original_pitch: float = rig.pitch
	rig.rotate_camera(100.0, 100.0)
	_check(not is_equal_approx(rig.yaw, original_yaw), "horizontal drag updates camera yaw")
	_check(rig.pitch < original_pitch, "vertical drag updates camera pitch")
	rig.rotate_camera(0.0, 100000.0)
	_check(rig.pitch >= -0.65, "camera pitch respects its lower clamp")
	rig.add_impact_impulse(0.4)
	_check(is_equal_approx(rig.impact_impulse, 0.4), "combat hit can add a camera impulse")
	rig.add_shake(0.7)
	_check(is_equal_approx(rig.shake_strength, 0.7), "combat feedback can add camera shake")
	rig.reset_telegraph_phase()
	_check(is_zero_approx(rig.telegraph_phase), "new attack telegraph resets the camera pulse phase")
	rig.update_camera(0.2, player, enemy, marker)
	_check(rig.impact_impulse < 0.4 and rig.shake_strength < 0.7, "camera impact effects decay over time")
	print("Combat camera rig tests: ", checks - failures, "/", checks, " passed")
	quit(1 if failures > 0 else 0)
