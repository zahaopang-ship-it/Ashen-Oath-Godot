extends Node3D
const FIGHTER_FACTORY = preload("res://scripts/factories/fighter_factory.gd")
const HUD_SCRIPT = preload("res://scripts/touch_hud.gd")
const REST_POINT_SCRIPT = preload("res://scripts/rest_point.gd")
const OBJECTIVES_SCRIPT = preload("res://scripts/exploration_objectives.gd")
const WORLD_BUILDER_SCRIPT = preload("res://scripts/world/world_builder.gd")
const INPUT_ROUTER = preload("res://scripts/input/player_input_router.gd")
const CAMERA_RIG_SCRIPT = preload("res://scripts/camera/combat_camera_rig.gd")
var world_builder: Node3D
var world_root: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var boss: CharacterBody3D
var guard: CharacterBody3D
var guard_east: CharacterBody3D
var guard_north: CharacterBody3D
var camera: Camera3D
var exploration_objectives: Node
var camera_rig: RefCounted
var telegraph_marker: MeshInstance3D
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
	world_builder = WORLD_BUILDER_SCRIPT.new()
	world_builder.name = "AshenValeWorld"
	add_child(world_builder)
	world_builder.world_root = self
	world_builder.setup_world()
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
	world_builder._create_stealth_cover(Vector3(-5.1, 0.0, -3.0), "MossyBushA")
	world_builder._create_stealth_cover(Vector3(-9.2, 0.0, -4.5), "MossyBushB")
	world_builder._create_stealth_cover(Vector3(-5.8, 0.0, -8.6), "SupplyCrates")
	world_builder._create_grapple_point(Vector3(-2.5, 5.2, 0.0), "GrappleAnchorWest")
	world_builder._create_grapple_point(Vector3(2.5, 5.8, -5.5), "GrappleAnchorNorth")
	world_builder._create_grapple_point(Vector3(7.0, 4.8, 1.5), "GrappleAnchorEast")
	world_builder._create_water_zone(Vector3(9.0, -0.15, -7.0), Vector3(5.0, 1.4, 7.0), "TrainingPond")
	world_builder._create_climb_wall(Vector3(11.8, 2.0, 2.0), Vector3(0.55, 4.0, 7.0), "ClimbableTowerWall")
	world_builder._create_exploration_paths()
	world_builder._create_north_ruined_gate()
	world_builder._create_east_watch_camp()
	world_builder._create_landmark("WestGroveMonolith", Vector3(-19.0, 0.0, -7.0), Color(0.28, 0.36, 0.31))
	world_builder._create_landmark("PondsideBell", Vector3(14.0, 0.0, -8.0), Color(0.25, 0.38, 0.46))
	world_builder._create_secret_cache(Vector3(-21.0, 0.0, -8.5), "GroveRelicCache")
	world_builder._create_rest_point(Vector3(0.0, 0.0, 8.5), "AshenRestShrine")
	world_builder._create_rest_point(Vector3(-16.5, 0.0, -18.0), "GroveRestShrine")
	enemy = boss
	player.target = enemy
	world_builder.connect_water_zones(player)
	player.set_checkpoint(Vector3(0.0, 0.0, 4.0))
	var starting_shrine := world_builder.get_node_or_null("AshenRestShrine")
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
	camera_rig = CAMERA_RIG_SCRIPT.new()
	camera_rig.configure(camera)
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
		camera_rig.reset_telegraph_phase()

func _on_enemy_attack_hit(_target: Node) -> void:
	camera_rig.add_impact_impulse(0.22)

func _on_player_attack_hit(_target: Node) -> void:
	camera_rig.add_impact_impulse(0.13)

func _trigger_hitstop(duration: float, strength: float) -> void:
	if not _hitstop_active:
		_hitstop_previous_scale = Engine.time_scale
		_hitstop_active = true
	Engine.time_scale = HITSTOP_SCALE
	_hitstop_generation += 1
	var generation := _hitstop_generation
	camera_rig.add_shake(strength)
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
	camera_rig.update_camera(delta, player, enemy, telegraph_marker)

func _unhandled_input(event: InputEvent) -> void:
	INPUT_ROUTER.handle_event(event, player)

func _on_water_body_entered(body: Node3D, zone: Area3D) -> void:
	if is_instance_valid(world_builder):
		world_builder._on_water_body_entered(body, zone)

func _on_water_body_exited(body: Node3D, zone: Area3D) -> void:
	if is_instance_valid(world_builder):
		world_builder._on_water_body_exited(body, zone)

func rotate_camera(delta_x: float, delta_y: float) -> void:
	camera_rig.rotate_camera(delta_x, delta_y)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]