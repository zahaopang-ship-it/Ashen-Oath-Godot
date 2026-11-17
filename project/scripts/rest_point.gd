extends Node3D

var is_active := false
var _flame: MeshInstance3D
var _light: OmniLight3D

func configure(label: String) -> void:
	name = label
	add_to_group("rest_points")
	_flame = MeshInstance3D.new()
	_flame.name = "Ember"
	var orb := SphereMesh.new()
	orb.radius = 0.22
	orb.height = 0.44
	_flame.mesh = orb
	_flame.position.y = 1.45
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.position.y = 1.5
	_light.omni_range = 5.5
	_light.light_energy = 1.4
	add_child(_light)
	var pedestal := MeshInstance3D.new()
	var stone := CylinderMesh.new()
	stone.top_radius = 0.48
	stone.bottom_radius = 0.62
	stone.height = 0.85
	pedestal.mesh = stone
	pedestal.position.y = 0.42
	var stone_material := StandardMaterial3D.new()
	stone_material.albedo_color = Color(0.20, 0.22, 0.23)
	stone_material.roughness = 0.95
	pedestal.material_override = stone_material
	add_child(pedestal)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.52
	ring_mesh.outer_radius = 0.61
	ring.mesh = ring_mesh
	ring.position.y = 0.08
	ring.rotation.x = PI * 0.5
	ring.material_override = stone_material
	add_child(ring)
	set_active(false)

func set_active(value: bool) -> void:
	is_active = value
	if not is_instance_valid(_flame) or not is_instance_valid(_light):
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.albedo_color = Color(1.0, 0.72, 0.25) if value else Color(0.20, 0.42, 0.55)
	material.emission = Color(1.0, 0.34, 0.08) if value else Color(0.04, 0.22, 0.38)
	material.emission_energy_multiplier = 3.0 if value else 1.3
	_flame.material_override = material
	_light.light_color = Color(1.0, 0.38, 0.12) if value else Color(0.08, 0.42, 0.72)
	_light.light_energy = 2.0 if value else 0.75
