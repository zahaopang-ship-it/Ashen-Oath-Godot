extends Node3D
const FIGHTER_FACTORY = preload("res://scripts/factories/fighter_factory.gd")
const HUD_SCRIPT = preload("res://scripts/touch_hud.gd")
const REST_POINT_SCRIPT = preload("res://scripts/rest_point.gd")
const OBJECTIVES_SCRIPT = preload("res://scripts/exploration_objectives.gd")
var player: CharacterBody3D
var enemy: CharacterBody3D
var boss: CharacterBody3D
var guard: CharacterBody3D
var guard_east: CharacterBody3D
var guard_north: CharacterBody3D
var camera: Camera3D
var exploration_objectives: Node
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
	_create_navigation_region()
	player = _make_fighter("Wolf", Vector3(0, 0, 4), true)
	boss = _make_fighter("AshenWarlord", Vector3(0, 0, -3), false, true)
	guard = _make_fighter("AshenSentinel", Vector3(-7.0, 0.0, -1.0), false)
	guard.add_to_group("stealth_guards")
	guard.target = player
	guard.patrol_points.assign([Vector3(-7.0, 0.0, -1.0), Vector3(-7.0, 0.0, -7.0), Vector3(-10.0, 0.0, -7.0), Vector3(-10.0, 0.0, -1.0)])
	guard.patrol_speed = 1.55
	guard.vision_range = 12.0
	guard.vision_half_angle_degrees = 52.0
	guard_east = _make_fighter("AshenLookout", Vector3(15.0, 0.0, 8.0), false)
	guard_east.add_to_group("stealth_guards")
	guard_east.target = player
	guard_east.patrol_points.assign([Vector3(15.0, 0.0, 8.0), Vector3(19.0, 0.0, 8.0), Vector3(19.0, 0.0, 13.0), Vector3(14.0, 0.0, 13.0)])
	guard_east.patrol_speed = 1.7
	guard_east.vision_range = 13.0
	guard_north = _make_fighter("AshenRanger", Vector3(-15.0, 0.0, -13.0), false)
	guard_north.add_to_group("stealth_guards")
	guard_north.target = player
	guard_north.patrol_points.assign([Vector3(-15.0, 0.0, -13.0), Vector3(-19.0, 0.0, -13.0), Vector3(-19.0, 0.0, -18.0), Vector3(-13.0, 0.0, -18.0)])
	guard_north.patrol_speed = 1.45
	_create_stealth_cover(Vector3(-5.1, 0.0, -3.0), "MossyBushA")
	_create_stealth_cover(Vector3(-9.2, 0.0, -4.5), "MossyBushB")
	_create_stealth_cover(Vector3(-5.8, 0.0, -8.6), "SupplyCrates")
	_create_grapple_point(Vector3(-2.5, 5.2, 0.0), "GrappleAnchorWest")
	_create_grapple_point(Vector3(2.5, 5.8, -5.5), "GrappleAnchorNorth")
	_create_grapple_point(Vector3(7.0, 4.8, 1.5), "GrappleAnchorEast")
	_create_water_zone(Vector3(9.0, -0.15, -7.0), Vector3(5.0, 1.4, 7.0), "TrainingPond")
	_create_climb_wall(Vector3(11.8, 2.0, 2.0), Vector3(0.55, 4.0, 7.0), "ClimbableTowerWall")
	_create_exploration_paths()
	_create_north_ruined_gate()
	_create_east_watch_camp()
	_create_landmark("WestGroveMonolith", Vector3(-19.0, 0.0, -7.0), Color(0.28, 0.36, 0.31))
	_create_landmark("PondsideBell", Vector3(14.0, 0.0, -8.0), Color(0.25, 0.38, 0.46))
	_create_secret_cache(Vector3(-21.0, 0.0, -8.5), "GroveRelicCache")
	_create_rest_point(Vector3(0.0, 0.0, 8.5), "AshenRestShrine")
	_create_rest_point(Vector3(-16.5, 0.0, -18.0), "GroveRestShrine")
	enemy = boss
	player.target = enemy
	player_entered_water_connect()
	player.set_checkpoint(Vector3(0.0, 0.0, 4.0))
	var starting_shrine := get_node_or_null("AshenRestShrine")
	if is_instance_valid(starting_shrine):
		starting_shrine.set_active(true)
	player.checkpoint_position = Vector3(0.0, 0.0, 10.0)
	exploration_objectives = Node.new()
	exploration_objectives.name = "ExplorationObjectives"
	exploration_objectives.set_script(OBJECTIVES_SCRIPT)
	add_child(exploration_objectives)
	exploration_objectives.configure(player)
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

func _create_navigation_region() -> void:
	var region := NavigationRegion3D.new()
	region.name = "AshenValeNavigationRegion"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.42
	nav_mesh.agent_height = 1.8
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.2
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.vertices = PackedVector3Array([
		Vector3(-26.4, 0.02, -22.4),
		Vector3(26.4, 0.02, -22.4),
		Vector3(26.4, 0.02, 22.4),
		Vector3(-26.4, 0.02, 22.4)
	])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_mesh = nav_mesh
	add_child(region)

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
	add_child(stone)
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
	add_child(gate)
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
	add_child(camp)
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
	add_child(root)
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
	add_child(shrine)
	shrine.configure(label)

func _create_secret_cache(pos: Vector3, label: String) -> void:
	var cache := Node3D.new()
	cache.name = label
	cache.position = pos
	cache.add_to_group("secret_caches")
	cache.set_meta("collected", false)
	add_child(cache)
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

func _make_fighter(label: String, pos: Vector3, player_controlled: bool, boss_character: bool = false) -> CharacterBody3D:
	return FIGHTER_FACTORY.create(self, label, pos, player_controlled, boss_character)

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
	var boss_distance := player.global_position.distance_to(enemy.global_position)
	var focus := player.global_position.lerp(enemy.global_position, 0.28) if boss_distance < 17.0 and not enemy.is_dead else player.global_position
	var combat_distance := boss_distance if boss_distance < 17.0 and not enemy.is_dead else 5.0
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
			KEY_Z: player.interact_rest_point()
			KEY_X: player.interact_secret_cache()
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