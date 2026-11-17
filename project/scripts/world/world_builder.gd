extends Node3D
## Owns the Ashen Vale environment, traversal landmarks, and environmental triggers.
## Combatants and encounter orchestration remain owned by Main.
const REST_POINT_SCRIPT = preload("res://scripts/rest_point.gd")
var player: CharacterBody3D
var world_root: Node3D

func connect_water_zones(player_node: CharacterBody3D) -> void:
	player = player_node
	for zone in get_tree().get_nodes_in_group("water_zones"):
		zone.body_entered.connect(world_root._on_water_body_entered.bind(zone))
		zone.body_exited.connect(world_root._on_water_body_exited.bind(zone))

func setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.48, 0.57)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	world_root.add_child(world_env)
	_make_box("AshenValeGround", Vector3(0, -0.35, 0), Vector3(56, 0.7, 50), Color(0.22, 0.19, 0.15), true)
	for x in range(-26, 27, 2):
		_make_box("ValeBoundaryStone", Vector3(float(x), 1.8, -23.5), Vector3(2.1, 3.6, 1.1), Color(0.28, 0.29, 0.28), true)
		_make_box("ValeBoundaryStone", Vector3(float(x), 1.8, 23.5), Vector3(2.1, 3.6, 1.1), Color(0.28, 0.29, 0.28), true)
	for z in range(-22, 23, 2):
		_make_box("ValeBoundaryStone", Vector3(-27.5, 1.8, float(z)), Vector3(1.1, 3.6, 2.1), Color(0.28, 0.29, 0.28), true)
		_make_box("ValeBoundaryStone", Vector3(27.5, 1.8, float(z)), Vector3(1.1, 3.6, 2.1), Color(0.28, 0.29, 0.28), true)
	for x in [-11.0, -8.0, -5.0, 5.0, 8.0, 11.0]:
		_make_box("FencePost", Vector3(x, 1.0, -12.8), Vector3(0.35, 2.0, 0.35), Color(0.20, 0.12, 0.09), true)
	_make_box("FenceRailWest", Vector3(-8.0, 1.35, -12.8), Vector3(8.0, 0.22, 0.22), Color(0.25, 0.13, 0.09), true)
	_make_box("FenceRailEast", Vector3(8.0, 1.35, -12.8), Vector3(8.0, 0.22, 0.22), Color(0.25, 0.13, 0.09), true)
	_make_box("FenceRailWestLow", Vector3(-8.0, 0.65, -12.8), Vector3(8.0, 0.16, 0.16), Color(0.25, 0.13, 0.09), true)
	_make_box("FenceRailEastLow", Vector3(8.0, 0.65, -12.8), Vector3(8.0, 0.16, 0.16), Color(0.25, 0.13, 0.09), true)
	for x in [-22.0, -10.0, 10.0, 22.0]:
		for z in [-19.0, 0.0, 18.0]:
			_make_tree(Vector3(x, 0, z))

func _create_exploration_paths() -> void:
	for z in range(7, -18, -2):
		_create_path_stone(Vector3(0.0, 0.055, float(z)))
	for x in range(2, 17, 2):
		_create_path_stone(Vector3(float(x), 0.055, -7.0))
	for x in range(-2, -17, -2):
		_create_path_stone(Vector3(float(x), 0.055, -5.0))
	for z in range(-7, -19, -2):
		_create_path_stone(Vector3(-14.0, 0.055, float(z)))
	for x in range(0, 17, 2):
		_create_path_stone(Vector3(float(x), 0.055, 14.0))
	for x in [-23.0, -20.0, 20.0, 23.0]:
		for z in [-16.0, -12.0, 12.0, 16.0]:
			_create_landmark("WayfindingStone", Vector3(x, 0.0, z), Color(0.30, 0.34, 0.31))

func _create_path_stone(pos: Vector3) -> void:
	var stone := Node3D.new()
	stone.name = "ValeTrailStone"
	stone.position = pos
	stone.add_to_group("exploration_paths")
	world_root.add_child(stone)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(1.55, 0.11, 1.2)
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.32, 0.27)
	material.roughness = 1.0
	mesh.material_override = material
	stone.add_child(mesh)

func _create_north_ruined_gate() -> void:
	var gate := Node3D.new()
	gate.name = "NorthRuinedGate"
	gate.position = Vector3(0.0, 0.0, -18.5)
	gate.add_to_group("exploration_landmarks")
	world_root.add_child(gate)
	for x in [-3.2, 3.2]:
		var pillar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.0, 5.0, 1.0)
		pillar.mesh = mesh
		pillar.position = Vector3(x, 2.5, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.25, 0.27, 0.28)
		material.roughness = 0.95
		pillar.material_override = material
		gate.add_child(pillar)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(7.0, 0.8, 1.3)
	lintel.mesh = lintel_mesh
	lintel.position.y = 5.0
	var lintel_material := StandardMaterial3D.new()
	lintel_material.albedo_color = Color(0.20, 0.22, 0.23)
	lintel.material_override = lintel_material
	gate.add_child(lintel)

func _create_east_watch_camp() -> void:
	var camp := Node3D.new()
	camp.name = "EastWatchCamp"
	camp.position = Vector3(18.0, 0.0, 10.5)
	camp.add_to_group("exploration_landmarks")
	world_root.add_child(camp)
	for x in [-2.0, 2.0]:
		_make_box("CampPost", camp.position + Vector3(x, 1.0, 0.0), Vector3(0.25, 2.0, 0.25), Color(0.22, 0.13, 0.08), false)
	var canopy := MeshInstance3D.new()
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(4.8, 0.18, 3.4)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(0.0, 2.0, 0.0)
	var canopy_material := StandardMaterial3D.new()
	canopy_material.albedo_color = Color(0.22, 0.16, 0.11)
	canopy.material_override = canopy_material
	camp.add_child(canopy)

func _create_landmark(label: String, pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = pos
	root.add_to_group("exploration_landmarks")
	world_root.add_child(root)
	var mesh := MeshInstance3D.new()
	var pillar := BoxMesh.new()
	pillar.size = Vector3(0.55, 2.2, 0.55)
	mesh.mesh = pillar
	mesh.position.y = 1.1
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	root.add_child(mesh)
	return root

func _create_rest_point(pos: Vector3, label: String) -> void:
	var shrine := Node3D.new()
	shrine.set_script(REST_POINT_SCRIPT)
	shrine.position = pos
	world_root.add_child(shrine)
	shrine.configure(label)

func _create_secret_cache(pos: Vector3, label: String) -> void:
	var cache := Node3D.new()
	cache.name = label
	cache.position = pos
	cache.add_to_group("secret_caches")
	cache.set_meta("collected", false)
	world_root.add_child(cache)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.0, 0.58, 0.72)
	base.mesh = base_mesh
	base.position.y = 0.38
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.20, 0.12, 0.075)
	wood.roughness = 0.9
	base.material_override = wood
	cache.add_child(base)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(1.04, 0.18, 0.76)
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.76, 0.0)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.42, 0.34, 0.18)
	metal.metallic = 0.65
	lid.material_override = metal
	cache.add_child(lid)
	var relic := MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.16
	orb.height = 0.32
	relic.mesh = orb
	relic.position.y = 1.12
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(0.18, 0.85, 0.72)
	glow.emission_enabled = true
	glow.emission = Color(0.05, 0.9, 0.68)
	glow.emission_energy_multiplier = 2.8
	relic.material_override = glow
	cache.add_child(relic)

func _on_water_body_entered(body: Node3D, zone: Area3D) -> void:
	if body == player:
		player.enter_water(zone.global_position.y + 0.7)

func _on_water_body_exited(body: Node3D, _zone: Area3D) -> void:
	if body == player:
		player.exit_water()

func _create_water_zone(pos: Vector3, dimensions: Vector3, label: String) -> void:
	var water := Area3D.new()
	water.name = label
	water.position = pos
	water.add_to_group("water_zones")
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	shape_node.shape = shape
	water.add_child(shape_node)
	var surface := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(dimensions.x, 0.06, dimensions.z)
	surface.mesh = plane
	surface.position.y = dimensions.y * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.06, 0.28, 0.38, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.25
	material.roughness = 0.18
	material.emission_enabled = true
	material.emission = Color(0.02, 0.12, 0.18)
	surface.material_override = material
	water.add_child(surface)
	world_root.add_child(water)

func _create_climb_wall(pos: Vector3, dimensions: Vector3, label: String) -> void:
	var wall := StaticBody3D.new()
	wall.name = label
	wall.position = pos
	wall.add_to_group("climbable_surfaces")
	world_root.add_child(wall)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	wall.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.30, 0.34)
	material.emission_enabled = true
	material.emission = Color(0.04, 0.12, 0.16)
	visual.material_override = material
	wall.add_child(visual)

func _create_grapple_point(pos: Vector3, label: String) -> void:
	var anchor := Area3D.new()
	anchor.name = label
	anchor.position = pos
	anchor.add_to_group("grapple_points")
	anchor.monitoring = false
	world_root.add_child(anchor)
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.24
	mesh.height = 0.48
	orb.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.78, 0.88)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.72, 1.0)
	material.emission_energy_multiplier = 2.2
	orb.material_override = material
	anchor.add_child(orb)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.30
	ring_mesh.outer_radius = 0.38
	ring.mesh = ring_mesh
	ring.material_override = material
	anchor.add_child(ring)

func _create_stealth_cover(pos: Vector3, label: String) -> void:
	var cover := StaticBody3D.new()
	cover.name = label
	cover.position = pos
	cover.add_to_group("stealth_cover")
	world_root.add_child(cover)
	var foliage := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 1.05 if label.begins_with("Mossy") else 0.78
	shape.height = 1.65 if label.begins_with("Mossy") else 1.25
	foliage.mesh = shape
	foliage.position.y = 0.92 if label.begins_with("Mossy") else 0.68
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.105, 0.22, 0.13) if label.begins_with("Mossy") else Color(0.30, 0.20, 0.12)
	material.roughness = 1.0
	foliage.material_override = material
	cover.add_child(foliage)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 1.65, 1.65) if label.begins_with("Mossy") else Vector3(1.55, 1.25, 1.45)
	collision.shape = box
	collision.position.y = box.size.y * 0.5
	cover.add_child(collision)
	var zone := Area3D.new()
	zone.name = label + "ConcealmentZone"
	zone.position = pos + Vector3(1.65, 0.0, 0.0)
	zone.add_to_group("stealth_cover_zones")
	zone.collision_layer = 0
	zone.collision_mask = 1
	zone.monitoring = true
	zone.monitorable = false
	world_root.add_child(zone)
	var zone_shape := CollisionShape3D.new()
	var zone_box := BoxShape3D.new()
	zone_box.size = Vector3(2.8, 2.4, 2.8)
	zone_shape.shape = zone_box
	zone_shape.position.y = 1.1
	zone.add_child(zone_shape)
	zone.body_entered.connect(_on_stealth_cover_entered.bind(zone))
	zone.body_exited.connect(_on_stealth_cover_exited.bind(zone))

func _on_stealth_cover_entered(body: Node3D, zone: Area3D) -> void:
	if body.has_method("set_stealth_cover"):
		body.set_stealth_cover(zone, true)

func _on_stealth_cover_exited(body: Node3D, zone: Area3D) -> void:
	if body.has_method("set_stealth_cover"):
		body.set_stealth_cover(zone, false)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = label
	root.position = pos
	world_root.add_child(root)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	root.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		root.add_child(shape)

func _make_tree(pos: Vector3) -> void:
	_make_box("TreeTrunk", pos + Vector3(0, 1.5, 0), Vector3(0.55, 3.0, 0.55), Color(0.20, 0.12, 0.08), false)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.65
	sphere.height = 3.3
	crown.mesh = sphere
	crown.position = pos + Vector3(0, 3.7, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.25, 0.18)
	m.roughness = 1.0
	crown.material_override = m
	world_root.add_child(crown)
