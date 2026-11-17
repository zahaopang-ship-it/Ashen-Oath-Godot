extends RefCounted

## Owns player locomotion, crouch/sprint acceleration, cover transfers, wall-hug motion, and facing.
static func update_player(actor: CharacterBody3D, delta: float) -> void:
	if actor.is_swimming:
		actor.is_sprinting = false
		actor.sprint_requested = false
		return
	if actor.is_vaulting:
		return
	if actor.state != 0:
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.movement_braking * delta)
		actor.velocity.z = move_toward(actor.velocity.z, 0.0, actor.movement_braking * delta)
		return
	var move_dir: Vector3 = get_player_move_direction(actor)
	if actor.is_cover_transferring:
		if not is_instance_valid(actor._cover_transfer_target):
			actor.is_cover_transferring = false
		else:
			var transfer_goal: Vector3 = actor._cover_transfer_detour if actor._cover_transfer_detouring else actor._cover_transfer_target.global_position
			var transfer_offset := transfer_goal - actor.global_position
			transfer_offset.y = 0.0
			if transfer_offset.length() <= (0.38 if actor._cover_transfer_detouring else 0.52):
				if actor._cover_transfer_detouring:
					actor._cover_transfer_detouring = false
					actor._cover_transfer_detour = Vector3.ZERO
				else:
					actor.is_cover_transferring = false
					actor._cover_transfer_target = null
					actor.velocity.x = 0.0
					actor.velocity.z = 0.0
			else:
				move_dir = transfer_offset.normalized()
				var probe_motion := move_dir * minf(0.22, transfer_offset.length())
				if actor.test_move(actor.global_transform, probe_motion):
					if not actor._cover_transfer_detouring:
						var side := Vector3(-move_dir.z, 0.0, move_dir.x)
						if actor.test_move(actor.global_transform, side * 0.45):
							side = -side
						if actor.test_move(actor.global_transform, side * 0.45):
							actor._cancel_cover_transfer()
						else:
							actor._cover_transfer_detour = actor.global_position + side * 1.9
							actor._cover_transfer_detour.y = actor.global_position.y
							actor._cover_transfer_detouring = true
							move_dir = side
					else:
						actor._cancel_cover_transfer()
						move_dir = Vector3.ZERO
	if actor.is_wall_hugging:
		var wall_query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.0, actor.global_position + Vector3.UP * 1.0 - actor._wall_hug_normal * 0.95)
		wall_query.exclude = [actor.get_rid()]
		var wall_hit := actor.get_world_3d().direct_space_state.intersect_ray(wall_query)
		if wall_hit.is_empty():
			var old_tangent := Vector3.UP.cross(actor._wall_hug_normal).normalized()
			var side_input := signf(actor.input_move.x)
			if not is_zero_approx(side_input) and actor._try_wall_corner_transition(old_tangent * side_input):
				wall_query = PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.0, actor.global_position + Vector3.UP * 1.0 - actor._wall_hug_normal * 0.95)
				wall_query.exclude = [actor.get_rid()]
				wall_hit = actor.get_world_3d().direct_space_state.intersect_ray(wall_query)
			if wall_hit.is_empty():
				actor.is_wall_hugging = false
				actor._wall_hug_normal = Vector3.ZERO
		else:
			actor._wall_hug_normal = (wall_hit.normal as Vector3).normalized()
			var tangent := Vector3.UP.cross(actor._wall_hug_normal).normalized()
			move_dir = tangent * actor.input_move.x + actor._wall_hug_normal * actor.input_move.y
			if move_dir.length_squared() > 1.0:
				move_dir = move_dir.normalized()
			var wall_distance: float = Vector2(actor.global_position.x - wall_hit.position.x, actor.global_position.z - wall_hit.position.z).length()
			var correction := clampf(wall_distance - 0.58, -0.8, 0.8)
			actor.velocity += -actor._wall_hug_normal * correction * 5.0 * delta
		if actor.is_wall_hugging:
			actor.is_crouching = true
			actor.is_sprinting = false
		else:
			actor.is_crouching = false
	else:
		actor.is_sprinting = not actor.is_crouching and (actor.sprint_requested or actor.input_move.length() >= 0.82)
	var current_speed: float = actor.move_speed * (0.48 if actor.is_crouching else (1.42 if actor.is_sprinting else 1.0))
	var desired_velocity: Vector3 = move_dir * current_speed
	var accel: float = actor.movement_acceleration if move_dir.length_squared() > 0.001 else actor.movement_braking
	actor.velocity.x = move_toward(actor.velocity.x, desired_velocity.x, accel * delta)
	actor.velocity.z = move_toward(actor.velocity.z, desired_velocity.z, accel * delta)
	if is_instance_valid(actor._upper_body):
		actor._upper_body.position.y = lerpf(actor._upper_body.position.y, -0.28 if actor.is_crouching else 0.0, 1.0 - exp(-12.0 * delta))
	if actor.is_crouching:
		actor.velocity.x *= 0.92
		actor.velocity.z *= 0.92
	if is_instance_valid(actor.target) and not actor.target.is_dead:
		var to_target: Vector3 = actor.target.global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.04:
			face_direction(actor, to_target.normalized(), delta, actor.combat_turn_speed)
	elif move_dir.length_squared() > 0.001:
		face_direction(actor, move_dir, delta)


static func get_player_move_direction(actor: CharacterBody3D) -> Vector3:
	var forward: Vector3 = -actor.global_transform.basis.z
	var right: Vector3 = actor.global_transform.basis.x
	var move_dir: Vector3 = right * actor.input_move.x + forward * -actor.input_move.y
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()
	return move_dir



static func face_direction(actor: CharacterBody3D, dir: Vector3, delta: float, turn_speed: float = 12.0) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle: float = atan2(-dir.x, -dir.z)
	actor.rotation.y = lerp_angle(actor.rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))
