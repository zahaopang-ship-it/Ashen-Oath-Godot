extends RefCounted

## Reusable navigation steering shared by sentinel controllers.
## Fighter retains the public wrapper methods for compatibility with existing AI/tests.

static func steer_toward(actor: CharacterBody3D, destination: Vector3, speed: float, delta: float, turn_speed: float) -> void:
	var desired := destination - actor.global_position
	desired.y = 0.0
	if desired.length_squared() < 0.0025:
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, 18.0 * delta)
		actor.velocity.z = move_toward(actor.velocity.z, 0.0, 18.0 * delta)
		return
	var route_direction := get_global_route_direction(actor, destination, desired.normalized())
	var direction := get_navigation_direction(actor, route_direction)
	direction = apply_guard_separation(actor, direction)
	var desired_velocity := direction * speed
	actor.velocity.x = move_toward(actor.velocity.x, desired_velocity.x, 10.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, desired_velocity.z, 10.0 * delta)
	actor._face_direction(direction, delta, turn_speed)

static func get_global_route_direction(actor: CharacterBody3D, destination: Vector3, fallback: Vector3) -> Vector3:
	var agent: NavigationAgent3D = actor.navigation_agent
	if not is_instance_valid(agent) or not agent.is_inside_tree():
		return fallback
	var map := agent.get_navigation_map()
	if map.is_valid() and NavigationServer3D.map_get_iteration_id(map) == 0:
		return fallback
	if not actor._navigation_target.is_finite() or actor._navigation_target.distance_to(destination) > 0.85:
		actor._navigation_target = destination
		agent.target_position = destination
	var next_position := agent.get_next_path_position()
	var direction := next_position - actor.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.04:
		var path: PackedVector3Array = agent.get_current_navigation_path()
		var path_index := agent.get_current_navigation_path_index()
		for index in range(path_index + 1, path.size()):
			direction = path[index] - actor.global_position
			direction.y = 0.0
			if direction.length_squared() >= 0.04:
				break
	if direction.length_squared() < 0.04:
		return fallback
	return direction.normalized()

static func get_navigation_direction(actor: CharacterBody3D, desired_direction: Vector3, probe_distance: float = 1.9) -> Vector3:
	var desired := Vector3(desired_direction.x, 0.0, desired_direction.z)
	if desired.length_squared() < 0.001:
		return Vector3.ZERO
	desired = desired.normalized()
	if not actor.is_inside_tree() or actor.get_world_3d() == null:
		return desired
	var origin := actor.global_position - Vector3.UP * 0.55
	var space := actor.get_world_3d().direct_space_state
	var forward_query := PhysicsRayQueryParameters3D.create(origin, origin + desired * probe_distance)
	forward_query.exclude = [actor.get_rid()]
	if space.intersect_ray(forward_query).is_empty():
		return desired
	var best_direction := desired
	var best_score := -INF
	for angle in [-1.15, 1.15, -0.72, 0.72, -1.62, 1.62]:
		var candidate := desired.rotated(Vector3.UP, angle).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + candidate * probe_distance)
		query.exclude = [actor.get_rid()]
		var hit := space.intersect_ray(query)
		var clearance := probe_distance if hit.is_empty() else origin.distance_to(hit.position)
		var alignment := candidate.dot(desired)
		var score := alignment * 1.35 + (clearance / probe_distance) * 0.9
		if score > best_score:
			best_score = score
			best_direction = candidate
	return best_direction

static func apply_guard_separation(actor: CharacterBody3D, travel_direction: Vector3, radius: float = 2.4) -> Vector3:
	var result := Vector3(travel_direction.x, 0.0, travel_direction.z)
	if result.length_squared() < 0.001 or not actor.is_inside_tree():
		return result.normalized() if result.length_squared() > 0.001 else Vector3.ZERO
	var separation := Vector3.ZERO
	var neighbors := 0
	for node in actor.get_tree().get_nodes_in_group("stealth_guards"):
		if node == actor or not node is CharacterBody3D:
			continue
		var offset: Vector3 = actor.global_position - (node as CharacterBody3D).global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > 0.05 and distance < radius:
			var weight := (radius - distance) / radius
			separation += offset.normalized() * weight
			neighbors += 1
	if neighbors == 0 or separation.length_squared() < 0.001:
		return result.normalized()
	separation /= float(neighbors)
	var combined := result.normalized() + separation * 1.35
	if combined.length_squared() < 0.001:
		return result.normalized()
	return combined.normalized()

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]