extends RefCounted

## Owns swimming, vertical climbing, ledge hanging, jumping, and grapple movement.
const STATE_FREE := 0

static func set_swim_vertical_input(actor: CharacterBody3D, value: float) -> void:
	actor.swim_vertical_input = clampf(value, -1.0, 1.0) if actor.is_swimming else 0.0

static func enter_water(actor: CharacterBody3D, surface_y: float) -> void:
	if not actor.is_player or actor.is_dead:
		return
	actor.is_swimming = true
	actor.swim_vertical_input = 0.0
	actor._water_surface_y = surface_y
	actor.is_crouching = false
	actor.is_sprinting = false
	actor.sprint_requested = false
	if is_instance_valid(actor.body_collision) and actor.body_collision.shape is CapsuleShape3D:
		actor.body_collision.shape.height = 1.25
		actor.body_collision.position.y = 0.68

static func exit_water(actor: CharacterBody3D) -> void:
	if not actor.is_swimming:
		return
	actor.is_swimming = false
	actor.swim_vertical_input = 0.0
	actor.velocity.y = maxf(actor.velocity.y, 1.0)
	if is_instance_valid(actor.body_collision) and actor.body_collision.shape is CapsuleShape3D:
		actor.body_collision.shape.height = 1.8
		actor.body_collision.position.y = 0.9

static func try_vertical_climb(actor: CharacterBody3D) -> bool:
	if actor.is_climbing:
		stop_vertical_climb(actor)
		return true
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.is_swimming or actor.is_grappling or actor.is_vaulting or actor.is_wall_hugging:
		return false
	var forward: Vector3 = -actor.global_transform.basis.z.normalized()
	var origin: Vector3 = actor.global_position + Vector3.UP * 0.95
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 0.9)
	query.exclude = [actor.get_rid()]
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or absf((hit.normal as Vector3).y) > 0.25:
		return false
	var climb_collider: Object = hit.get("collider")
	if not is_instance_valid(climb_collider) or not climb_collider.is_in_group("climbable_surfaces"):
		return false
	actor._climb_normal = (hit.normal as Vector3).normalized()
	actor.is_climbing = true
	actor.is_crouching = false
	actor.is_sprinting = false
	actor.velocity = Vector3.ZERO
	return true

static func stop_vertical_climb(actor: CharacterBody3D) -> void:
	if not actor.is_climbing:
		return
	actor.is_climbing = false
	actor._climb_normal = Vector3.ZERO
	actor.velocity = Vector3(0.0, -1.2, 0.0)

static func update_vertical_climb(actor: CharacterBody3D, delta: float) -> void:
	if actor._climb_normal.length_squared() < 0.5:
		stop_vertical_climb(actor)
		return
	var origin: Vector3 = actor.global_position + Vector3.UP * 0.95
	var query := PhysicsRayQueryParameters3D.create(origin, origin - actor._climb_normal * 1.05)
	query.exclude = [actor.get_rid()]
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		stop_vertical_climb(actor)
		return
	var vertical: float = -actor.input_move.y
	actor.velocity = Vector3.UP * vertical * actor.climb_speed - actor._climb_normal * 0.35
	actor.move_and_slide()
	if vertical > 0.0:
		var top_query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.9 + actor._climb_normal * 0.2, actor.global_position + Vector3.UP * 1.9 - actor._climb_normal * 0.85)
		top_query.exclude = [actor.get_rid()]
		if actor.get_world_3d().direct_space_state.intersect_ray(top_query).is_empty():
			stop_vertical_climb(actor)

static func try_ledge_grab(actor: CharacterBody3D) -> bool:
	if not actor.is_player or actor.is_dead or actor.is_on_floor() or actor.is_swimming or actor.is_grappling or actor.is_climbing or actor.is_ledge_hanging or actor.state != STATE_FREE:
		return false
	if actor.velocity.y > 1.5 or actor.velocity.y < -8.5:
		return false
	var forward: Vector3 = -actor.global_transform.basis.z.normalized()
	var chest: Vector3 = actor.global_position + Vector3.UP * 1.35
	var wall_query := PhysicsRayQueryParameters3D.create(chest, chest + forward * 0.9)
	wall_query.exclude = [actor.get_rid()]
	var wall_hit := actor.get_world_3d().direct_space_state.intersect_ray(wall_query)
	if wall_hit.is_empty() or absf((wall_hit.normal as Vector3).y) > 0.25:
		return false
	var top_origin: Vector3 = (wall_hit.position as Vector3) + Vector3.UP * 2.0 + forward * 0.08
	var top_query := PhysicsRayQueryParameters3D.create(top_origin, top_origin + Vector3.DOWN * 2.5)
	top_query.exclude = [actor.get_rid()]
	var top_hit := actor.get_world_3d().direct_space_state.intersect_ray(top_query)
	if top_hit.is_empty():
		return false
	var top_y: float = (top_hit.position as Vector3).y
	if top_y < actor.global_position.y + 0.55 or top_y > actor.global_position.y + 2.4:
		return false
	actor._ledge_hang_position = (wall_hit.position as Vector3) + (wall_hit.normal as Vector3) * 0.48 + Vector3.UP * (top_y - actor.global_position.y - 1.15)
	actor._ledge_hang_position.y = top_y - 1.05
	actor._climb_normal = (wall_hit.normal as Vector3).normalized()
	actor.global_position = actor._ledge_hang_position
	actor.velocity = Vector3.ZERO
	actor.is_ledge_hanging = true
	return true

static func update_ledge_hang(actor: CharacterBody3D, _delta: float) -> void:
	actor.velocity = Vector3.ZERO
	if actor.input_move.y < -0.45:
		var landing: Vector3 = actor._ledge_hang_position + actor._climb_normal * 0.9 + Vector3.UP * 1.05
		var query := PhysicsRayQueryParameters3D.create(landing + Vector3.UP * 2.0, landing + Vector3.DOWN * 3.0)
		query.exclude = [actor.get_rid()]
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var floor_y: float = (hit.position as Vector3).y
			actor._vault_start = actor.global_position
			actor._vault_end = Vector3(landing.x, floor_y, landing.z)
			actor._vault_elapsed = 0.0
			actor._vault_duration = 0.48
			actor._vault_height = 0.42
			actor._traversal_kind = "ledge_mantle"
			actor.is_ledge_hanging = false
			actor.is_vaulting = true
			return
	if actor.input_move.y > 0.65:
		actor.is_ledge_hanging = false
		actor.velocity = Vector3(0.0, -1.8, 0.0)

static func begin_jump(actor: CharacterBody3D) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or not actor.is_on_floor() or actor.is_grappling or actor.is_vaulting:
		return false
	actor.velocity.y = 7.2
	actor.is_crouching = false
	return true

static func try_grapple(actor: CharacterBody3D) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.is_grappling or actor.is_vaulting or actor.is_wall_hugging or actor.is_cover_transferring:
		return false
	var best: Node3D = null
	var best_distance: float = 12.5
	var forward: Vector3 = -actor.global_transform.basis.z.normalized()
	for candidate in actor.get_tree().get_nodes_in_group("grapple_points"):
		if not candidate is Node3D or not is_instance_valid(candidate):
			continue
		var offset: Vector3 = candidate.global_position - actor.global_position
		var distance: float = offset.length()
		if distance < 2.0 or distance > best_distance:
			continue
		var direction: Vector3 = offset.normalized()
		if forward.dot(direction) < 0.48:
			continue
		var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.1, candidate.global_position)
		query.exclude = [actor.get_rid()]
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider != candidate:
			continue
		best = candidate
		best_distance = distance
	if not is_instance_valid(best):
		return false
	actor.grapple_target = best
	actor._grapple_start = actor.global_position
	actor._grapple_end = best.global_position + Vector3(0.0, -0.8, 0.0)
	actor._grapple_elapsed = 0.0
	actor._grapple_duration = clampf(best_distance / 18.0, 0.32, 0.62)
	actor._grapple_height = clampf(best_distance * 0.16, 0.8, 1.8)
	actor.is_grappling = true
	actor._grapple_attack_ready = true
	actor.velocity = Vector3.ZERO
	return true

static func update_grapple(actor: CharacterBody3D, delta: float) -> void:
	if not is_instance_valid(actor.grapple_target):
		actor.is_grappling = false
		return
	actor._grapple_elapsed += delta
	var t: float = clampf(actor._grapple_elapsed / actor._grapple_duration, 0.0, 1.0)
	var desired: Vector3 = actor._grapple_start.lerp(actor._grapple_end, t) + Vector3.UP * (sin(t * PI) * actor._grapple_height)
	var travel: Vector3 = desired - actor.global_position
	actor.velocity = travel / maxf(delta, 0.001)
	actor.move_and_slide()
	if actor.get_slide_collision_count() > 0 and t < 0.92:
		actor.is_grappling = false
		actor.grapple_target = null
		actor.velocity = Vector3.ZERO
		return
	if t >= 1.0:
		actor.is_grappling = false
		actor.grapple_target = null
		actor.velocity = Vector3.ZERO
		actor._grapple_attack_ready = true

static func aerial_grapple_attack(actor: CharacterBody3D) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.is_grappling or not actor._grapple_attack_ready or not is_instance_valid(actor.target) or actor.target.is_dead:
		return false
	var offset: Vector3 = actor.target.global_position - actor.global_position
	offset.y = 0.0
	if offset.length() > 3.1 or offset.length() < 0.1:
		return false
	if (-actor.global_transform.basis.z).dot(offset.normalized()) < 0.0:
		return false
	actor._grapple_attack_ready = false
	actor.start_attack("heavy")
	return true
