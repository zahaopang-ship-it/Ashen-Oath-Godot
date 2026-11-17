extends RefCounted

## Owns checkpoints, shrine/cache interactions, exploration rewards, and resurrection.
const STATE_FREE := 0

static func set_checkpoint(actor: CharacterBody3D, position: Vector3) -> void:
	actor.checkpoint_position = position

static func get_nearest_rest_point(actor: CharacterBody3D, max_distance: float = 2.8) -> Node3D:
	if not actor.is_player or actor.is_dead:
		return null
	var nearest: Node3D = null
	var nearest_distance: float = max_distance
	for candidate in actor.get_tree().get_nodes_in_group("rest_points"):
		if not candidate is Node3D or not is_instance_valid(candidate):
			continue
		var distance: float = actor.global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

static func interact_rest_point(actor: CharacterBody3D, max_distance: float = 2.8) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.is_grappling or actor.is_vaulting or actor.is_climbing or actor.is_ledge_hanging:
		return false
	var shrine: Node3D = get_nearest_rest_point(actor, max_distance)
	if not is_instance_valid(shrine):
		return false
	for candidate in actor.get_tree().get_nodes_in_group("rest_points"):
		if candidate.has_method("set_active"):
			candidate.set_active(candidate == shrine)
	actor.checkpoint_position = shrine.global_position + Vector3(0.0, 0.0, 1.5)
	actor.exploration_event.emit("rest:" + shrine.name)
	actor.global_position = actor.checkpoint_position
	actor.velocity = Vector3.ZERO
	actor.vitality = actor.max_vitality
	actor.posture = 0.0
	actor.prosthetic_energy = actor.max_prosthetic_energy
	actor.resurrection_charges = actor.max_resurrection_charges
	actor.resurrection_available = true
	actor.resurrection_invulnerability = 0.0
	return true

static func interact_secret_cache(actor: CharacterBody3D, max_distance: float = 2.5) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE:
		return false
	var nearest: Node3D = null
	var nearest_distance: float = max_distance
	for candidate in actor.get_tree().get_nodes_in_group("secret_caches"):
		if not candidate is Node3D or not is_instance_valid(candidate) or bool(candidate.get_meta("collected", false)):
			continue
		var distance: float = actor.global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if not is_instance_valid(nearest):
		return false
	nearest.set_meta("collected", true)
	actor.exploration_event.emit("cache_collected")
	nearest.visible = false
	actor.prosthetic_upgrade_points += 1
	actor.prosthetic_energy = minf(actor.max_prosthetic_energy, actor.prosthetic_energy + 25.0)
	return true

static func get_nearest_secret_cache(actor: CharacterBody3D, max_distance: float = 2.5) -> Node3D:
	if not actor.is_player or actor.is_dead:
		return null
	var nearest: Node3D = null
	var nearest_distance: float = max_distance
	for candidate in actor.get_tree().get_nodes_in_group("secret_caches"):
		if not candidate is Node3D or not is_instance_valid(candidate) or bool(candidate.get_meta("collected", false)):
			continue
		var distance: float = actor.global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

static func resurrect(actor: CharacterBody3D) -> bool:
	if not actor.is_player or not actor.is_dead or not actor.resurrection_available or actor.resurrection_charges <= 0:
		return false
	actor.resurrection_charges -= 1
	actor.resurrection_available = false
	actor.is_dead = false
	actor.state = STATE_FREE
	actor.vitality = actor.max_vitality * 0.55
	actor.posture = 0.0
	actor.velocity = Vector3.ZERO
	actor.global_position = actor.checkpoint_position
	actor.is_blocking = false
	actor.is_deflecting = false
	actor.is_dodging = false
	actor.is_crouching = false
	actor.is_wall_hugging = false
	actor.is_cover_transferring = false
	actor.is_swimming = false
	actor.is_climbing = false
	actor.is_ledge_hanging = false
	actor.is_grappling = false
	actor.is_vaulting = false
	actor.resurrection_invulnerability = 1.35
	return true

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]