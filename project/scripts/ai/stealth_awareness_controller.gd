extends RefCounted

## Owns sentinel perception, suspicion, investigation, and noise response.
## Awareness enum values mirror Fighter.AwarenessState (IDLE, SUSPICIOUS, SEARCHING, ALERTED).
const AWARENESS_IDLE := 0
const AWARENESS_SUSPICIOUS := 1
const AWARENESS_SEARCHING := 2
const AWARENESS_ALERTED := 3

static func update_awareness(actor: CharacterBody3D, delta: float) -> void:
	var target: Node3D = actor.target
	if not is_instance_valid(target) or target.is_dead:
		return
	var offset := target.global_position - actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	var crouched: bool = bool(target.get("is_crouching"))
	var in_cover: bool = bool(target.get("is_in_cover"))
	var effective_vision: float = actor.vision_range * get_target_vision_multiplier(actor, target)
	var visible: bool = distance <= effective_vision and target_in_vision_cone(actor, offset) and has_clear_line_of_sight(actor, target)
	var noise_multiplier := 0.42 if crouched else 1.0
	var noisy: bool = (bool(target.get("is_sprinting")) or (not crouched and Vector2(target.velocity.x, target.velocity.z).length() > 3.2)) and distance <= actor.sprint_noise_range * noise_multiplier
	if actor._distraction_active and not visible:
		return
	if visible:
		actor._distraction_active = false
		actor.last_known_target_position = target.global_position
		actor.lost_sight_timer = 0.0
		if actor.awareness_state == AWARENESS_IDLE or actor.awareness_state == AWARENESS_SEARCHING:
			actor.awareness_state = AWARENESS_SUSPICIOUS
		if actor.awareness_state == AWARENESS_SUSPICIOUS:
			var suspicion_rate := 0.48 if crouched else (1.8 if distance < 4.0 else 1.0)
			if in_cover:
				suspicion_rate *= 0.32 if crouched else 0.72
			actor.suspicion += delta * suspicion_rate
			if actor.suspicion >= actor.suspicion_threshold:
				actor.awareness_state = AWARENESS_ALERTED
				actor.ai_timer = 0.25
	elif noisy and actor.awareness_state != AWARENESS_ALERTED:
		actor.last_known_target_position = target.global_position
		actor.awareness_state = AWARENESS_SUSPICIOUS
		actor.suspicion = minf(actor.suspicion_threshold, actor.suspicion + delta * 1.5)
	else:
		if actor.awareness_state == AWARENESS_SUSPICIOUS:
			actor.suspicion = maxf(0.0, actor.suspicion - delta * 0.45)
			if actor.suspicion <= 0.0:
				actor.awareness_state = AWARENESS_IDLE
		elif actor.awareness_state == AWARENESS_ALERTED:
			actor.lost_sight_timer += delta
			if actor.lost_sight_timer >= 4.0:
				actor.awareness_state = AWARENESS_SEARCHING
				actor.search_timer = 12.0
				actor._search_origin_yaw = actor.rotation.y
				actor._search_scan_time = 0.0
				begin_cover_search(actor)

static func begin_cover_search(actor: CharacterBody3D) -> void:
	actor._search_points.clear()
	actor._search_point_index = 0
	actor._search_pause_timer = 0.85
	actor._search_points.append(actor.last_known_target_position)
	var candidates: Array[Vector3] = []
	for zone in actor.get_tree().get_nodes_in_group("stealth_cover_zones"):
		if not is_instance_valid(zone):
			continue
		var point: Vector3 = zone.global_position
		var offset: Vector3 = point - actor.last_known_target_position
		offset.y = 0.0
		if offset.length() <= 6.5:
			candidates.append(point)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return Vector2(a.x - actor.last_known_target_position.x, a.z - actor.last_known_target_position.z).length_squared() < Vector2(b.x - actor.last_known_target_position.x, b.z - actor.last_known_target_position.z).length_squared()
	)
	for point in candidates:
		actor._search_points.append(point)

static func get_target_vision_multiplier(_actor: CharacterBody3D, candidate: Node3D) -> float:
	if not is_instance_valid(candidate):
		return 1.0
	var crouched: bool = bool(candidate.get("is_crouching"))
	var covered: bool = bool(candidate.get("is_in_cover"))
	if crouched and covered:
		return 0.16
	if covered:
		return 0.58
	if crouched:
		return 0.52
	return 1.0

static func target_in_vision_cone(actor: CharacterBody3D, offset: Vector3) -> bool:
	if offset.length_squared() < 0.001:
		return true
	var forward := -actor.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return false
	var threshold := cos(deg_to_rad(actor.vision_half_angle_degrees))
	return forward.normalized().dot(offset.normalized()) >= threshold

static func has_clear_line_of_sight(actor: CharacterBody3D, candidate: Node3D) -> bool:
	var world := actor.get_world_3d()
	if world == null:
		return true
	var target_height := 0.55 if bool(candidate.get("is_crouching")) else 1.0
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.35, candidate.global_position + Vector3.UP * target_height)
	query.exclude = [actor.get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == candidate

static func emit_noise(actor: CharacterBody3D, noise_position: Vector3, radius: float) -> void:
	if actor.is_player or actor.is_dead or actor.awareness_state == AWARENESS_ALERTED:
		return
	if actor.global_position.distance_to(noise_position) <= radius:
		actor.last_known_target_position = noise_position
		actor.awareness_state = AWARENESS_SUSPICIOUS
		actor.suspicion = minf(actor.suspicion_threshold, actor.suspicion + 0.55)

static func receive_distraction(actor: CharacterBody3D, noise_position: Vector3) -> void:
	if actor.is_player or actor.is_dead:
		return
	if actor.awareness_state == AWARENESS_ALERTED and is_instance_valid(actor.target) and has_clear_line_of_sight(actor, actor.target):
		return
	actor._distraction_active = true
	actor._distraction_timer = 7.0
	actor.last_known_target_position = noise_position
	actor.awareness_state = AWARENESS_SEARCHING
	actor.suspicion = maxf(actor.suspicion, 0.55)
	actor.search_timer = 7.0
	actor._search_points.clear()
	actor._search_points.append(noise_position)
	actor._search_point_index = 0
	actor._search_pause_timer = 0.0
	actor._search_scan_time = 0.0

static func set_stealth_cover(actor: CharacterBody3D, _zone: Area3D, entering: bool) -> void:
	actor.stealth_cover_count = maxi(0, actor.stealth_cover_count + (1 if entering else -1))
	actor.is_in_cover = actor.stealth_cover_count > 0

static func on_cover_zone_body_entered(actor: CharacterBody3D, body: Node3D, zone: Area3D) -> void:
	if body == actor:
		set_stealth_cover(actor, zone, true)

static func on_cover_zone_body_exited(actor: CharacterBody3D, body: Node3D, zone: Area3D) -> void:
	if body == actor:
		set_stealth_cover(actor, zone, false)
