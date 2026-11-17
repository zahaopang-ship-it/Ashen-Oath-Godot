extends Node3D
const FIGHTER_SCRIPT = preload("res://scripts/fighter.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const HUD_SCRIPT = preload("res://scripts/touch_hud.gd")
var player: CharacterBody3D
var enemy: CharacterBody3D
var boss: CharacterBody3D
var guard: CharacterBody3D
var camera: Camera3D
var arena_radius := 13.0
var camera_yaw := 0.0
var camera_pitch := -0.22
var camera_impulse := 0.0
var telegraph_marker: MeshInstance3D
var telegraph_phase := 0.0
var camera_shake_strength := 0.0
var camera_shake_time := 0.0
var _hitstop_generation := 0
var _hitstop_previous_scale := 1.0
var _hitstop_active := false
const HITSTOP_SCALE := 0.055
const AUDIO_EVENTS := {
	"hit": "res://audio/impact_body.wav",
	"deflect": "res://audio/sword_deflect.wav",
	"mikiri": "res://audio/sword_deflect.wav",
	"sweep_evaded": "res://audio/sword_deflect.wav",
	"guard": "res://audio/guard_clang.wav",
	"posture_break": "res://audio/posture_break.wav",
	"death": "res://audio/impact_body.wav",
	"grabbed": "res://audio/impact_body.wav",
	"stomp": "res://audio/posture_break.wav",
	"boss_phase": "res://audio/posture_break.wav",
	"deathblow": "res://audio/sword_deflect.wav"
}

func _ready() -> void:
	_setup_world()
	player = _make_fighter("Wolf", Vector3(0, 0, 4), true)
	boss = _make_fighter("AshenWarlord", Vector3(0, 0, -3), false, true)
	guard = _make_fighter("AshenSentinel", Vector3(-7.0, 0.0, -1.0), false)
	guard.add_to_group("stealth_guards")
	guard.target = player
	guard.patrol_points.assign([Vector3(-7.0, 0.0, -1.0), Vector3(-7.0, 0.0, -7.0), Vector3(-10.0, 0.0, -7.0), Vector3(-10.0, 0.0, -1.0)])
	guard.patrol_speed = 1.55
	guard.vision_range = 12.0
	guard.vision_half_angle_degrees = 52.0
	_create_stealth_cover(Vector3(-5.1, 0.0, -3.0), "MossyBushA")
	_create_stealth_cover(Vector3(-9.2, 0.0, -4.5), "MossyBushB")
	_create_stealth_cover(Vector3(-5.8, 0.0, -8.6), "SupplyCrates")
	_create_grapple_point(Vector3(-2.5, 5.2, 0.0), "GrappleAnchorWest")
	_create_grapple_point(Vector3(2.5, 5.8, -5.5), "GrappleAnchorNorth")
	_create_grapple_point(Vector3(7.0, 4.8, 1.5), "GrappleAnchorEast")
	_create_water_zone(Vector3(9.0, -0.15, -7.0), Vector3(5.0, 1.4, 7.0), "TrainingPond")
	_create_climb_wall(Vector3(11.8, 2.0, 2.0), Vector3(0.55, 4.0, 7.0), "ClimbableTowerWall")
	enemy = boss
	player.target = enemy
	player_entered_water_connect()
	player.set_checkpoint(Vector3(0.0, 0.0, 4.0))
	enemy.target = player
	boss.boss_phase_changed.connect(_on_boss_phase_changed)
	enemy.attack_phase_changed.connect(_on_enemy_attack_phase)
	enemy.telegraph_started.connect(_on_enemy_telegraph_started)
	enemy.attack_hit.connect(_on_enemy_attack_hit)
	player.attack_hit.connect(_on_player_attack_hit)
	player.combat_feedback.connect(_on_combat_feedback)
	enemy.combat_feedback.connect(_on_combat_feedback)
	_create_telegraph_marker()
	camera = Camera3D.new()
	camera.name = "CombatCamera"
	camera.current = true
	camera.fov = 72.0
	add_child(camera)
	var hud := CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	hud.game = self
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

func _make_fighter(label: String, pos: Vector3, player_controlled: bool, boss_character: bool = false) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = label
	body.position = pos
	body.set_script(BOSS_SCRIPT if boss_character else FIGHTER_SCRIPT)
	body.is_player = player_controlled
	body.display_name = label
	add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
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



func _make_arm_pivot(parent: Node3D, label: String, x: float, material: Material) -> Node3D:
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

func armor_material_for_grip() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.19, 0.11, 0.075)
	material.roughness = 0.82
	return material

func _make_leg_pivot(parent: Node3D, label: String, x: float, material: Material) -> Node3D:
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

func _add_boss_armor(body: CharacterBody3D, upper_body: Node3D) -> void:
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

func _on_boss_phase_changed(phase: int) -> void:
	if is_instance_valid(telegraph_marker):
		var material := telegraph_marker.material_override as StandardMaterial3D
		if material:
			material.emission_energy_multiplier = 3.2 if phase == 2 else 2.2
			if phase == 2:
				material.albedo_color = Color(1.0, 0.035, 0.015)
				material.emission = Color(1.0, 0.015, 0.005)
				telegraph_marker.scale = Vector3.ONE * 1.55

func _create_telegraph_marker() -> void:
	telegraph_marker = MeshInstance3D.new()
	telegraph_marker.name = "EnemyAttackTelegraph"
	var orb := SphereMesh.new()
	orb.radius = 0.22
	orb.height = 0.44
	telegraph_marker.mesh = orb
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.16, 0.055)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.055, 0.015)
	material.emission_energy_multiplier = 2.2
	telegraph_marker.material_override = material
	telegraph_marker.position = Vector3(0, 2.65, 0)
	telegraph_marker.visible = false
	enemy.add_child(telegraph_marker)

func _on_enemy_telegraph_started(kind: String) -> void:
	if not is_instance_valid(telegraph_marker):
		return
	var material := telegraph_marker.material_override as StandardMaterial3D
	if not material:
		return
	var colors := {
		"slash": Color(1.0, 0.16, 0.055),
		"thrust": Color(1.0, 0.72, 0.08),
		"sweep": Color(0.18, 0.72, 1.0),
		"heavy": Color(0.78, 0.12, 1.0),
		"grab": Color(1.0, 0.92, 0.72),
		"ashen_rend": Color(1.0, 0.035, 0.015),
		"lightning": Color(0.18, 0.78, 1.0)
	}
	material.albedo_color = colors.get(kind, Color(1.0, 0.16, 0.055))
	material.emission = material.albedo_color

func _on_enemy_attack_phase(phase: String) -> void:
	if not is_instance_valid(telegraph_marker):
		return
	telegraph_marker.visible = phase == "windup"
	if phase == "windup":
		telegraph_phase = 0.0

func _on_enemy_attack_hit(_target: Node) -> void:
	camera_impulse = maxf(camera_impulse, 0.22)

func _on_player_attack_hit(_target: Node) -> void:
	camera_impulse = maxf(camera_impulse, 0.13)

func _trigger_hitstop(duration: float, strength: float) -> void:
	if not _hitstop_active:
		_hitstop_previous_scale = Engine.time_scale
		_hitstop_active = true
	Engine.time_scale = HITSTOP_SCALE
	_hitstop_generation += 1
	var generation := _hitstop_generation
	camera_shake_strength = maxf(camera_shake_strength, strength)
	get_tree().create_timer(duration, true, false, true).timeout.connect(_restore_hitstop.bind(generation))

func _restore_hitstop(generation: int) -> void:
	if not _hitstop_active or generation != _hitstop_generation:
		return
	Engine.time_scale = _hitstop_previous_scale
	_hitstop_active = false

func _on_combat_feedback(kind: String, source: Node3D) -> void:
	if not is_instance_valid(source):
		return
	var hitstop := 0.045
	var shake := 0.12
	match kind:
		"hit":
			hitstop = 0.052
			shake = 0.22
		"deflect":
			hitstop = 0.072
			shake = 0.34
		"mikiri":
			hitstop = 0.085
			shake = 0.38
		"sweep_evaded":
			hitstop = 0.085
			shake = 0.38
		"guard":
			hitstop = 0.025
			shake = 0.12
		"posture_break":
			hitstop = 0.105
			shake = 0.48
		"death":
			hitstop = 0.12
			shake = 0.52
		"grabbed":
			hitstop = 0.07
			shake = 0.36
		"stomp":
			hitstop = 0.085
			shake = 0.42
		"boss_phase":
			hitstop = 0.11
			shake = 0.58
		"deathblow":
			hitstop = 0.16
			shake = 0.72
	_trigger_hitstop(hitstop, shake)
	_play_combat_sound(kind, source.global_position)
	if kind == "deflect":
		_spawn_deflect_clash(source)

func _spawn_deflect_clash(source: Node3D) -> void:
	var clash := Node3D.new()
	clash.name = "DeflectClashFX"
	var contact := source.global_position + Vector3.UP * 1.30
	if "target" in source and is_instance_valid(source.get("target")):
		var opponent: Node3D = source.get("target")
		contact = (source.global_position + opponent.global_position) * 0.5 + Vector3.UP * 1.35
	add_child(clash)
	clash.global_position = contact
	clash.rotation.y = source.global_rotation.y
	clash.scale = Vector3.ONE * 0.35
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.72, 0.94, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.28, 0.78, 1.0)
	material.emission_energy_multiplier = 3.2
	for angle in [-0.68, 0.68]:
		var spark := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.055, 0.055, 0.72)
		spark.mesh = shape
		spark.rotation.y = angle
		spark.material_override = material
		clash.add_child(spark)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(clash, "scale", Vector3.ONE * 1.25, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.16)
	tween.chain().tween_callback(clash.queue_free)

func _play_combat_sound(kind: String, world_position: Vector3) -> void:
	if not AUDIO_EVENTS.has(kind):
		return
	var stream := load(str(AUDIO_EVENTS[kind])) as AudioStream
	if not stream:
		return
	var player_audio := AudioStreamPlayer3D.new()
	player_audio.name = "CombatSFX"
	player_audio.stream = stream
	player_audio.position = world_position
	player_audio.volume_db = -5.0 if kind in ["deflect", "mikiri", "posture_break"] else -9.0
	player_audio.max_distance = 22.0
	player_audio.unit_size = 7.0
	player_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(player_audio)
	player_audio.finished.connect(player_audio.queue_free)
	player_audio.play()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	var focus := player.global_position.lerp(enemy.global_position, 0.28)
	var combat_distance := player.global_position.distance_to(enemy.global_position)
	var camera_distance := clampf(5.8 + combat_distance * 0.34, 6.8, 9.6)
	if player.is_sprinting:
		camera_distance += 0.35
	var camera_height := 3.7 + clampf(combat_distance * 0.055, 0.0, 0.65) + camera_pitch * 2.8
	var desired := focus + Vector3(sin(camera_yaw) * camera_distance, camera_height, cos(camera_yaw) * camera_distance)
	camera_impulse = move_toward(camera_impulse, 0.0, delta * 0.9)
	camera_shake_time += delta
	camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 2.8)
	telegraph_phase += delta
	var shake := Vector3(sin(camera_shake_time * 79.0), cos(camera_shake_time * 91.0), sin(camera_shake_time * 47.0) * 0.35) * camera_shake_strength
	var impact_nudge := Vector3(0.0, camera_impulse * 0.35, camera_impulse * 0.55)
	camera.global_position = camera.global_position.lerp(desired + shake + impact_nudge, 1.0 - exp(-7.0 * delta))
	if is_instance_valid(telegraph_marker) and telegraph_marker.visible:
		var pulse := 1.0 + 0.22 * sin(telegraph_phase * 15.0)
		telegraph_marker.scale = Vector3.ONE * pulse
	camera.look_at(focus + Vector3(0, 1.0, 0), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not player:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J: player.player_attack()
			KEY_K: player.begin_deflect()
			KEY_L: player.begin_block()
			KEY_SPACE: player.dodge()
			KEY_I: player.begin_mikiri_counter()
			KEY_O: player.begin_sweep_evade()
			KEY_P: player.stomp_broken_target()
			KEY_E:
				if not player.stealth_deathblow_target():
					player.deathblow_broken_target()
			KEY_C: player.toggle_crouch()
			KEY_V: player.try_vault()
			KEY_M: player.try_mantle()
			KEY_H: player.toggle_wall_hug()
			KEY_B: player.begin_cover_transfer()
			KEY_1: player.use_prosthetic("shuriken")
			KEY_2: player.use_prosthetic("firecracker")
			KEY_3: player.use_prosthetic("axe")
			KEY_4: player.use_prosthetic("umbrella")
			KEY_R: player.begin_lightning_reversal()
			KEY_U: player.upgrade_next_prosthetic()
			KEY_F: player.begin_jump()
			KEY_G: player.try_grapple()
			KEY_T: player.aerial_grapple_attack()
			KEY_Y: player.resurrect()
			KEY_N: player.try_vertical_climb()
			KEY_COMMA: player.stop_vertical_climb()
			KEY_PERIOD: player.try_ledge_grab()
			KEY_PAGEUP: player.set_swim_vertical_input(1.0)
			KEY_PAGEDOWN: player.set_swim_vertical_input(-1.0)
			KEY_KP_1: player.end_deflect()
			KEY_KP_2: player.end_block()
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_K: player.end_deflect()
		if event.keycode == KEY_L: player.end_block()
		if event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]: player.set_swim_vertical_input(0.0)
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if Input.is_key_pressed(KEY_W): move.y -= 1.0
	if Input.is_key_pressed(KEY_S): move.y += 1.0
	player.input_move = move.normalized() if move.length() > 1.0 else move
	player.sprint_requested = Input.is_key_pressed(KEY_SHIFT)

func rotate_camera(delta_x: float, delta_y: float) -> void:
	camera_yaw -= delta_x * 0.004
	camera_pitch = clampf(camera_pitch - delta_y * 0.003, -0.65, 0.15)

func player_entered_water_connect() -> void:
	for zone in get_tree().get_nodes_in_group("water_zones"):
		zone.body_entered.connect(_on_water_body_entered.bind(zone))
		zone.body_exited.connect(_on_water_body_exited.bind(zone))

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
	add_child(water)

func _create_climb_wall(pos: Vector3, dimensions: Vector3, label: String) -> void:
	var wall := StaticBody3D.new()
	wall.name = label
	wall.position = pos
	wall.add_to_group("climbable_surfaces")
	add_child(wall)
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
	add_child(anchor)
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
	add_child(cover)
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
	add_child(zone)
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
