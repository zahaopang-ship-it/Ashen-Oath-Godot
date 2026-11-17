extends RefCounted

## Owns prosthetic resource costs, tool effects, lightning reversal, and upgrades.
const STATE_FREE := 0
const STATE_HITSTUN := 6

static func use_prosthetic(actor: CharacterBody3D, tool: String) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.is_blocking or actor.prosthetic_cooldown > 0.0:
		return false
	var base_costs := {"shuriken": 18.0, "firecracker": 28.0, "axe": 32.0, "umbrella": 24.0}
	if not base_costs.has(tool):
		return false
	var level: int = int(actor.prosthetic_upgrades[tool])
	var cost: float = maxf(8.0, float(base_costs[tool]) * (1.0 - 0.08 * float(level)))
	if actor.prosthetic_energy < cost:
		return false
	var succeeded := false
	match tool:
		"shuriken":
			succeeded = use_shuriken(actor)
			if succeeded:
				actor.prosthetic_cooldown = 0.38
		"firecracker":
			use_firecracker(actor)
			succeeded = true
			actor.prosthetic_cooldown = 0.75
		"axe":
			succeeded = use_axe(actor)
			if succeeded:
				actor.prosthetic_cooldown = 0.72
		"umbrella":
			actor.umbrella_timer = 1.25 + 0.22 * float(actor.prosthetic_upgrades["umbrella"])
			actor.is_blocking = true
			succeeded = true
			actor.prosthetic_cooldown = 0.45
	if succeeded:
		actor.prosthetic_energy -= cost
		actor.prosthetic_pose = tool
		actor.prosthetic_pose_timer = 0.34
	return succeeded

static func use_shuriken(actor: CharacterBody3D) -> bool:
	if not is_instance_valid(actor.target) or actor.target.is_dead:
		return false
	var offset: Vector3 = actor.target.global_position - actor.global_position
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > 10.0 or flat.length() < 0.1:
		return false
	var forward: Vector3 = -actor.global_transform.basis.z
	forward.y = 0.0
	if forward.normalized().dot(flat.normalized()) < 0.72:
		return false
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.15, actor.target.global_position + Vector3.UP * 1.0)
	query.exclude = [actor.get_rid()]
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("collider") != actor.target:
		return false
	var level: int = int(actor.prosthetic_upgrades["shuriken"])
	actor.target.receive_strike(12.0 + 3.0 * level, 20.0 + 4.0 * level, actor, "thrust")
	var projectile := MeshInstance3D.new()
	projectile.name = "ProstheticShuriken"
	var blade := SphereMesh.new()
	blade.radius = 0.085
	blade.height = 0.17
	projectile.mesh = blade
	var blade_material := StandardMaterial3D.new()
	blade_material.albedo_color = Color(0.58, 0.68, 0.78)
	blade_material.metallic = 0.82
	blade_material.emission_enabled = true
	blade_material.emission = Color(0.18, 0.28, 0.42)
	projectile.material_override = blade_material
	var scene_root: Node = actor.get_tree().current_scene if is_instance_valid(actor.get_tree().current_scene) else actor.get_tree().root
	scene_root.add_child(projectile)
	projectile.global_position = actor.global_position + Vector3.UP * 1.15 - actor.global_transform.basis.z * 0.55
	var flight := actor.get_tree().create_tween()
	flight.tween_property(projectile, "global_position", actor.target.global_position + Vector3.UP * 1.0, 0.16)
	flight.tween_callback(projectile.queue_free)
	return true

static func use_firecracker(actor: CharacterBody3D) -> void:
	var burst_position: Vector3 = actor.global_position - actor.global_transform.basis.z * 3.0
	for listener in actor.get_tree().get_nodes_in_group("stealth_guards"):
		if not is_instance_valid(listener):
			continue
		var firecracker_level: int = int(actor.prosthetic_upgrades["firecracker"])
		if listener.global_position.distance_to(burst_position) > 10.0 + 1.5 * float(firecracker_level):
			continue
		if listener.has_method("receive_distraction"):
			listener.receive_distraction(burst_position)
		if int(listener.get("state")) == STATE_FREE:
			listener.set("state", STATE_HITSTUN)
			listener.set("hit_reaction_kind", "heavy")
			listener.set("hit_reaction_duration", 0.62)
			listener.set("hit_reaction_timer", 0.62)
	var flash := MeshInstance3D.new()
	flash.name = "FirecrackerBurst"
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.24
	flash.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.72, 0.22, 0.65)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.46, 0.08)
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = material
	var scene_root: Node = actor.get_tree().current_scene if is_instance_valid(actor.get_tree().current_scene) else actor.get_tree().root
	scene_root.add_child(flash)
	flash.global_position = burst_position + Vector3.UP * 0.9
	var timer := actor.get_tree().create_timer(0.24)
	timer.timeout.connect(flash.queue_free)

static func use_axe(actor: CharacterBody3D) -> bool:
	if not is_instance_valid(actor.target) or actor.target.is_dead:
		return false
	var offset: Vector3 = actor.target.global_position - actor.global_position
	offset.y = 0.0
	if offset.length() > 3.0 or offset.length() < 0.1:
		return false
	if -actor.global_transform.basis.z.dot(offset.normalized()) < 0.35:
		return false
	if actor.target.has_method("receive_strike"):
		var axe_level: int = int(actor.prosthetic_upgrades["axe"])
		actor.target.receive_strike(18.0 + 5.0 * axe_level, 52.0 + 8.0 * axe_level, actor, "heavy")
	return true

static func begin_lightning_reversal(actor: CharacterBody3D) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.velocity.y < 0.5 or actor.lightning_reversal_timer > 0.0:
		return false
	actor.lightning_reversal_timer = 0.85
	actor.combat_feedback.emit("lightning_ready", actor)
	return true

static func receive_lightning_reversal(actor: CharacterBody3D, defender: Node3D) -> void:
	if actor.is_dead or not is_instance_valid(defender):
		return
	spawn_lightning_arc(actor, defender, Color(0.24, 0.82, 1.0))
	actor.posture += 82.0
	actor._check_posture_break()
	if actor.state != 4:
		actor.state = STATE_HITSTUN
		actor.hit_reaction_kind = "heavy"
		actor.hit_reaction_duration = 0.72
		actor.hit_reaction_timer = 0.72
	actor.combat_feedback.emit("lightning_reversed", actor)

static func spawn_lightning_arc(actor: CharacterBody3D, other: Node3D, tint: Color) -> void:
	if not is_instance_valid(other):
		return
	var start: Vector3 = actor.global_position + Vector3.UP * 1.2
	var finish: Vector3 = other.global_position + Vector3.UP * 1.2
	var direction := finish - start
	var length := direction.length()
	if length < 0.1:
		return
	var beam := MeshInstance3D.new()
	beam.name = "LightningArc"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045
	mesh.bottom_radius = 0.075
	mesh.height = length
	beam.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 4.0
	beam.material_override = material
	var scene_root: Node = actor.get_tree().current_scene if is_instance_valid(actor.get_tree().current_scene) else actor.get_tree().root
	scene_root.add_child(beam)
	beam.global_position = (start + finish) * 0.5
	var axis := Vector3.UP.cross(direction.normalized())
	if axis.length_squared() > 0.001:
		beam.global_basis = Basis(axis.normalized(), Vector3.UP.angle_to(direction.normalized()))
	var tween := actor.get_tree().create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.16)
	tween.tween_callback(beam.queue_free)

static func upgrade_next_prosthetic(actor: CharacterBody3D) -> bool:
	var tools := ["shuriken", "firecracker", "axe", "umbrella"]
	for offset in range(tools.size()):
		var index: int = (actor.upgrade_selection_index + offset) % tools.size()
		var tool: String = tools[index]
		if upgrade_prosthetic(actor, tool):
			actor.upgrade_selection_index = (index + 1) % tools.size()
			return true
	return false

static func upgrade_prosthetic(actor: CharacterBody3D, tool: String) -> bool:
	if not actor.is_player or actor.is_dead or actor.state != STATE_FREE or actor.prosthetic_upgrade_points <= 0 or not actor.prosthetic_upgrades.has(tool):
		return false
	if int(actor.prosthetic_upgrades[tool]) >= 3:
		return false
	actor.prosthetic_upgrades[tool] = int(actor.prosthetic_upgrades[tool]) + 1
	actor.prosthetic_upgrade_points -= 1
	return true
