extends RefCounted

## Owns third-person framing, camera drag, telegraph pulse, and impact response.
var camera: Camera3D
var yaw := 0.0
var pitch := -0.22
var impact_impulse := 0.0
var shake_strength := 0.0
var shake_time := 0.0
var telegraph_phase := 0.0

func configure(camera_node: Camera3D) -> void:
	camera = camera_node

func rotate_camera(delta_x: float, delta_y: float) -> void:
	yaw -= delta_x * 0.004
	pitch = clampf(pitch - delta_y * 0.003, -0.65, 0.15)

func add_impact_impulse(amount: float) -> void:
	impact_impulse = maxf(impact_impulse, amount)

func add_shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)

func reset_telegraph_phase() -> void:
	telegraph_phase = 0.0

func update_camera(delta: float, player: CharacterBody3D, enemy: CharacterBody3D, marker: MeshInstance3D) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	var boss_distance := player.global_position.distance_to(enemy.global_position)
	var focus := player.global_position.lerp(enemy.global_position, 0.28) if boss_distance < 17.0 and not enemy.is_dead else player.global_position
	var combat_distance := boss_distance if boss_distance < 17.0 and not enemy.is_dead else 5.0
	var camera_distance := clampf(5.8 + combat_distance * 0.34, 6.8, 9.6)
	if player.is_sprinting:
		camera_distance += 0.35
	var camera_height := 3.7 + clampf(combat_distance * 0.055, 0.0, 0.65) + pitch * 2.8
	var desired := focus + Vector3(sin(yaw) * camera_distance, camera_height, cos(yaw) * camera_distance)
	impact_impulse = move_toward(impact_impulse, 0.0, delta * 0.9)
	shake_time += delta
	shake_strength = move_toward(shake_strength, 0.0, delta * 2.8)
	telegraph_phase += delta
	var shake := Vector3(sin(shake_time * 79.0), cos(shake_time * 91.0), sin(shake_time * 47.0) * 0.35) * shake_strength
	var impact_nudge := Vector3(0.0, impact_impulse * 0.35, impact_impulse * 0.55)
	camera.global_position = camera.global_position.lerp(desired + shake + impact_nudge, 1.0 - exp(-7.0 * delta))
	if is_instance_valid(marker) and marker.visible:
		var pulse := 1.0 + 0.22 * sin(telegraph_phase * 15.0)
		marker.scale = Vector3.ONE * pulse
	camera.look_at(focus + Vector3(0, 1.0, 0), Vector3.UP)
