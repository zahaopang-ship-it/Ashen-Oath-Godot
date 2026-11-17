extends Node3D
const PLAYER_SCRIPT = preload("res://scripts/fighter.gd")
const HUD_SCRIPT = preload("res://scripts/touch_hud.gd")
var player: CharacterBody3D
var enemy: CharacterBody3D
var camera: Camera3D
var arena_radius := 13.0
var camera_yaw := 0.0
var camera_pitch := -0.22

func _ready() -> void:
	_setup_world()
	player = _make_fighter("Wolf", Vector3(0, 0, 4), true)
	enemy = _make_fighter("Ashigaru", Vector3(0, 0, -3), false)
	player.set("target", enemy)
	enemy.set("target", player)
	camera = Camera3D.new()
	camera.name = "CombatCamera"
	camera.current = true
	camera.fov = 72.0
	add_child(camera)
	var hud := CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	hud.set("game", self)
	add_child(hud)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.48, 0.57)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	_make_box("Arena", Vector3(0, -0.35, 0), Vector3(30, 0.7, 30), Color(0.22, 0.19, 0.15), true)
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		var p := Vector3(cos(angle) * arena_radius, 0.4, sin(angle) * arena_radius)
		_make_box("PerimeterStone", p, Vector3(0.7, 0.8, 0.7), Color(0.28, 0.29, 0.28), true)
	for i in range(8):
		var x := -11.0 + float(i) * 3.1
		_make_box("FencePost", Vector3(x, 1.0, -12.8), Vector3(0.35, 2.0, 0.35), Color(0.20, 0.12, 0.09), true)
	_make_box("FenceRail", Vector3(0, 1.35, -12.8), Vector3(25, 0.22, 0.22), Color(0.25, 0.13, 0.09), true)
	_make_box("FenceRailLow", Vector3(0, 0.65, -12.8), Vector3(25, 0.16, 0.16), Color(0.25, 0.13, 0.09), true)
	for x in [-10.0, 10.0]:
		for z in [-9.0, 9.0]:
			_make_tree(Vector3(x, 0, z))

func _make_fighter(label: String, pos: Vector3, is_player: bool) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = label
	body.position = pos
	body.set_script(PLAYER_SCRIPT)
	body.set("is_player", is_player)
	body.set("display_name", label)
	body.set("max_vitality", 100.0)
	body.set("vitality", 100.0)
	body.set("max_posture", 100.0)
	body.set("posture", 0.0)
	add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.42
	capsule_mesh.height = 1.8
	mesh.mesh = capsule_mesh
	mesh.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.24, 0.31) if is_player else Color(0.48, 0.16, 0.12)
	mat.roughness = 0.82
	mesh.material_override = mat
	body.add_child(mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	head.position.y = 1.95
	head.material_override = mat
	body.add_child(head)
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.07, 0.9, 0.10)
	blade.mesh = blade_mesh
	blade.position = Vector3(0.48, 1.05, -0.05)
	blade.rotation.z = -0.25
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.72, 0.78, 0.82)
	blade_mat.metallic = 0.78
	blade.material_override = blade_mat
	body.add_child(blade)
	return body

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	var focus := player.global_position.lerp(enemy.global_position, 0.28)
	var desired := focus + Vector3(sin(camera_yaw) * 7.0, 4.2 + camera_pitch * 3.0, cos(camera_yaw) * 7.0)
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-5.0 * delta))
	camera.look_at(focus + Vector3(0, 1.0, 0), Vector3.UP)

func rotate_camera(delta_x: float, delta_y: float) -> void:
	camera_yaw -= delta_x * 0.004
	camera_pitch = clampf(camera_pitch - delta_y * 0.003, -0.65, 0.15)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = label
	root.position = pos
	add_child(root)
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
	add_child(crown)
