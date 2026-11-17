extends RefCounted

## Owns sentinel decision selection, patrol progression, and investigation movement.
const AWARENESS = preload("res://scripts/ai/stealth_awareness_controller.gd")
const STATE_FREE := 0

static func update(actor: CharacterBody3D, delta: float) -> void:
	if actor.state != STATE_FREE:
		return
	if is_instance_valid(actor.target) and not actor.target.is_dead:
		actor._update_awareness(delta)
	else:
		update_patrol(actor, delta)
		return
	var to_target: Vector3 = actor.target.global_position - actor.global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if actor.awareness_state == AWARENESS.AWARENESS_ALERTED:
		if distance > 1.7:
			actor._steer_ai_toward(actor.target.global_position, actor.move_speed * 0.72, delta, actor.combat_turn_speed)
		else:
			actor.velocity.x = move_toward(actor.velocity.x, 0.0, 22.0 * delta)
			actor.velocity.z = move_toward(actor.velocity.z, 0.0, 22.0 * delta)
		actor.ai_timer -= delta
		if actor.ai_timer <= 0.0 and distance <= actor.attack_range:
			actor.ai_timer = randf_range(1.15, 1.75)
			if randf() < 0.72:
				var roll := randf()
				var chosen := "slash"
				if roll < 0.18:
					chosen = "thrust"
				elif roll < 0.34:
					chosen = "sweep"
				elif roll < 0.48:
					chosen = "heavy"
				elif roll < 0.57:
					chosen = "grab"
				actor.start_attack(chosen)
	elif actor.awareness_state == AWARENESS.AWARENESS_SEARCHING:
		actor.search_timer -= delta
		if actor._search_point_index < actor._search_points.size():
			var search_dir: Vector3 = actor._search_points[actor._search_point_index] - actor.global_position
			search_dir.y = 0.0
			if search_dir.length() > 0.55:
				actor._steer_ai_toward(actor._search_points[actor._search_point_index], actor.patrol_speed * 0.9, delta, 5.0)
			else:
				actor.velocity.x = move_toward(actor.velocity.x, 0.0, 20.0 * delta)
				actor.velocity.z = move_toward(actor.velocity.z, 0.0, 20.0 * delta)
				actor._search_pause_timer -= delta
				actor._search_scan_time += delta
				var scan_angle := sin(actor._search_scan_time * 2.8) * 0.78
				actor.rotation.y = lerp_angle(actor.rotation.y, actor._search_origin_yaw + scan_angle, 1.0 - exp(-3.5 * delta))
				if actor._search_pause_timer <= 0.0:
					actor._search_point_index += 1
					actor._search_pause_timer = 0.85
					actor._search_origin_yaw = actor.rotation.y
		else:
			actor.velocity.x = move_toward(actor.velocity.x, 0.0, 18.0 * delta)
			actor.velocity.z = move_toward(actor.velocity.z, 0.0, 18.0 * delta)
			actor._search_scan_time += delta
			var scan_angle := sin(actor._search_scan_time * 2.8) * 0.78
			actor.rotation.y = lerp_angle(actor.rotation.y, actor._search_origin_yaw + scan_angle, 1.0 - exp(-3.5 * delta))
		if actor.search_timer <= 0.0 or actor._search_point_index >= actor._search_points.size():
			actor.awareness_state = AWARENESS.AWARENESS_IDLE
			actor.suspicion = 0.0
			actor._search_scan_time = 0.0
			actor._search_points.clear()
	elif actor.awareness_state == AWARENESS.AWARENESS_IDLE:
		update_patrol(actor, delta)

static func update_patrol(actor: CharacterBody3D, delta: float) -> void:
	if actor.patrol_points.is_empty():
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, 18.0 * delta)
		actor.velocity.z = move_toward(actor.velocity.z, 0.0, 18.0 * delta)
		return
	if actor.patrol_wait_timer > 0.0:
		actor.patrol_wait_timer = maxf(0.0, actor.patrol_wait_timer - delta)
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, 18.0 * delta)
		actor.velocity.z = move_toward(actor.velocity.z, 0.0, 18.0 * delta)
		return
	var waypoint: Vector3 = actor.patrol_points[actor.patrol_index % actor.patrol_points.size()]
	var direction: Vector3 = waypoint - actor.global_position
	direction.y = 0.0
	if direction.length() <= 0.45:
		actor.patrol_index = (actor.patrol_index + 1) % actor.patrol_points.size()
		actor.patrol_wait_timer = actor._patrol_pause
		return
	actor._steer_ai_toward(waypoint, actor.patrol_speed, delta, 4.0)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]