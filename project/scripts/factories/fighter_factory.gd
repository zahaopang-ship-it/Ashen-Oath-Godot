extends RefCounted

const FIGHTER_SCRIPT = preload("res://scripts/fighter.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const PLAYER_CONFIG = preload("res://resources/fighters/player.tres")
const SENTINEL_CONFIG = preload("res://resources/fighters/sentinel.tres")
const BOSS_CONFIG = preload("res://resources/fighters/ashen_warlord.tres")

## Builds a complete prototype fighter hierarchy and attaches it to `parent`.
## Gameplay behavior remains in Fighter/Boss; this class owns visual/physics assembly.
static func create(parent: Node, label: String, pos: Vector3, player_controlled: bool, boss_character: bool = false) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = label
	body.position = pos
	body.set_script(BOSS_SCRIPT if boss_character else FIGHTER_SCRIPT)
	body.is_player = player_controlled
	body.display_name = label
	body.fighter_config = BOSS_CONFIG if boss_character else (PLAYER_CONFIG if player_controlled else SENTINEL_CONFIG)
	body.fighter_config.apply_to(body)
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
	if not player_controlled and not boss_character:
		var nav_agent := NavigationAgent3D.new()
		nav_agent.name = "PatrolNavigationAgent"
		nav_agent.radius = 0.42
		nav_agent.height = 1.8
		nav_agent.path_desired_distance = 0.55
		nav_agent.target_desired_distance = 0.7
		nav_agent.avoidance_enabled = false
		body.add_child(nav_agent)
		body.navigation_agent = nav_agent
	body.body_collision = collision
	var upper_body := Node3D.new()
	upper_body.name = "UpperBodyPivot"
	body.add_child(upper_body)
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.42
	capsule_mesh.height = 1.48
	mesh.mesh = capsule_mesh
	mesh.position.y = 1.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.24, 0.31) if player_controlled else Color(0.20, 0.075, 0.065)
	mat.roughness = 0.82
	mesh.name = "BodyMesh"
	mesh.material_override = mat
	upper_body.add_child(mesh)
	body.set_body_material(mat)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	head.position.y = 1.95
	head.material_override = mat
	upper_body.add_child(head)
	var arm_material := StandardMaterial3D.new()
	arm_material.albedo_color = Color(0.12, 0.18, 0.23) if player_controlled else Color(0.16, 0.055, 0.05)
	arm_material.roughness = 0.86
	var left_arm := _make_arm_pivot(upper_body, "LeftArmPivot", -0.39, arm_material)
	var right_arm := _make_arm_pivot(upper_body, "RightArmPivot", 0.39, arm_material)
	var right_wrist: Node3D = right_arm.get_node("ElbowPivot/WristPivot")
	var weapon_pivot := Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(0.02, -0.02, -0.02)
	right_wrist.add_child(weapon_pivot)
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.065, 0.92, 0.075)
	blade.mesh = blade_mesh
	blade.position = Vector3(0.0, 0.48, -0.06)
	blade.rotation.z = -0.16
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.72, 0.78, 0.82)
	blade_mat.metallic = 0.78
	blade.material_override = blade_mat
	weapon_pivot.add_child(blade)
	var grip := MeshInstance3D.new()
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.045
	grip_mesh.bottom_radius = 0.045
	grip_mesh.height = 0.34
	grip.mesh = grip_mesh
	grip.position = Vector3(0.0, -0.08, 0.0)
	grip.material_override = armor_material_for_grip()
	weapon_pivot.add_child(grip)
	var leg_material := StandardMaterial3D.new()
	leg_material.albedo_color = Color(0.075, 0.09, 0.105) if player_controlled else Color(0.095, 0.065, 0.06)
	leg_material.roughness = 0.9
	var left_leg := _make_leg_pivot(body, "LeftLegPivot", -0.19, leg_material)
	var right_leg := _make_leg_pivot(body, "RightLegPivot", 0.19, leg_material)
	body.set_animation_rig(upper_body, weapon_pivot, left_leg, right_leg, left_arm, right_arm, left_arm.get_node("ElbowPivot"), right_arm.get_node("ElbowPivot"))
	if not player_controlled:
		_add_boss_armor(body, upper_body)
	return body



static func _make_arm_pivot(parent: Node3D, label: String, x: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = label
	pivot.position = Vector3(x, 1.48, 0.0)
	parent.add_child(pivot)
	var upper_arm := MeshInstance3D.new()
	var upper_shape := CapsuleMesh.new()
	upper_shape.radius = 0.13
	upper_shape.height = 0.58
	upper_arm.mesh = upper_shape
	upper_arm.position = Vector3(0.0, -0.24, 0.0)
	upper_arm.material_override = material
	pivot.add_child(upper_arm)
	var elbow := Node3D.new()
	elbow.name = "ElbowPivot"
	elbow.position = Vector3(0.0, -0.49, 0.0)
	pivot.add_child(elbow)
	var forearm := MeshInstance3D.new()
	var forearm_shape := CapsuleMesh.new()
	forearm_shape.radius = 0.105
	forearm_shape.height = 0.54
	forearm.mesh = forearm_shape
	forearm.position = Vector3(0.0, -0.22, -0.015)
	forearm.material_override = material
	elbow.add_child(forearm)
	var wrist := Node3D.new()
	wrist.name = "WristPivot"
	wrist.position = Vector3(0.0, -0.45, -0.025)
	elbow.add_child(wrist)
	var hand := MeshInstance3D.new()
	var hand_shape := SphereMesh.new()
	hand_shape.radius = 0.12
	hand_shape.height = 0.22
	hand.mesh = hand_shape
	hand.position = Vector3(0.0, -0.015, -0.025)
	hand.material_override = material
	wrist.add_child(hand)
	return pivot

static func armor_material_for_grip() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.19, 0.11, 0.075)
	material.roughness = 0.82
	return material

static func _make_leg_pivot(parent: Node3D, label: String, x: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = label
	pivot.position = Vector3(x, 0.78, 0.0)
	parent.add_child(pivot)
	var leg := MeshInstance3D.new()
	var shape := CapsuleMesh.new()
	shape.radius = 0.145
	shape.height = 0.78
	leg.mesh = shape
	leg.position = Vector3(0.0, -0.34, 0.0)
	leg.material_override = material
	pivot.add_child(leg)
	var foot := MeshInstance3D.new()
	var foot_shape := BoxMesh.new()
	foot_shape.size = Vector3(0.25, 0.13, 0.38)
	foot.mesh = foot_shape
	foot.position = Vector3(0.0, -0.68, -0.09)
	foot.material_override = material
	pivot.add_child(foot)
	return pivot

static func _add_boss_armor(body: CharacterBody3D, upper_body: Node3D) -> void:
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.105, 0.12, 0.14)
	armor.metallic = 0.72
	armor.roughness = 0.48
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.48, 0.19, 0.075)
	trim.metallic = 0.58
	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var plate := BoxMesh.new()
		plate.size = Vector3(0.62, 0.34, 0.58)
		shoulder.mesh = plate
		shoulder.position = Vector3(side * 0.48, 1.52, 0.0)
		shoulder.material_override = armor
		upper_body.add_child(shoulder)
		var trim_line := MeshInstance3D.new()
		var trim_mesh := BoxMesh.new()
		trim_mesh.size = Vector3(0.64, 0.055, 0.60)
		trim_line.mesh = trim_mesh
		trim_line.position = Vector3(side * 0.48, 1.70, 0.0)
		trim_line.material_override = trim
		upper_body.add_child(trim_line)
	var chest := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.72, 0.58, 0.24)
	chest.mesh = chest_mesh
	chest.position = Vector3(0.0, 1.18, -0.34)
	chest.material_override = armor
	upper_body.add_child(chest)
	var crest := MeshInstance3D.new()
	var crest_mesh := BoxMesh.new()
	crest_mesh.size = Vector3(0.12, 0.52, 0.12)
	crest.mesh = crest_mesh
	crest.position = Vector3(0.0, 2.35, -0.02)
	crest.rotation.z = -0.18
	crest.material_override = trim
	upper_body.add_child(crest)

