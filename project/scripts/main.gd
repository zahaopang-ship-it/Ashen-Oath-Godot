extends Node3D
const FIGHTER_FACTORY = preload("res://scripts/factories/fighter_factory.gd")
const HUD_SCRIPT = preload("res://scripts/touch_hud.gd")
const OBJECTIVES_SCRIPT = preload("res://scripts/exploration_objectives.gd")
const WORLD_BUILDER_SCRIPT = preload("res://scripts/world/world_builder.gd")
const INPUT_ROUTER = preload("res://scripts/input/player_input_router.gd")
const CAMERA_RIG_SCRIPT = preload("res://scripts/camera/combat_camera_rig.gd")
const COMBAT_FEEDBACK_SERVICE = preload("res://scripts/services/combat_feedback_service.gd")
const ENCOUNTER_CONFIG = preload("res://resources/encounters/ashen_vale.tres")
var world_builder: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var boss: CharacterBody3D
var guard: CharacterBody3D
var guard_east: CharacterBody3D
var guard_north: CharacterBody3D
var camera: Camera3D
var exploration_objectives: Node
var camera_rig: RefCounted
var combat_feedback_service: RefCounted
var _hitstop_generation := 0 # Compatibility/debug visibility for existing integration checks.
var telegraph_marker: MeshInstance3D

func _ready() -> void:
	var encounter: EncounterConfig = ENCOUNTER_CONFIG
	world_builder = WORLD_BUILDER_SCRIPT.new()
	world_builder.name = "AshenValeWorld"
	add_child(world_builder)
	world_builder.world_root = self
	world_builder.setup_world()
	_create_navigation_region()
	player = _make_fighter("Wolf", encounter.player_spawn, true)
	boss = _make_fighter("AshenWarlord", encounter.boss_spawn, false, true)
	guard = _make_fighter("AshenSentinel", encounter.west_sentinel_spawn, false)
	guard.add_to_group("stealth_guards")
	guard.target = player
	guard.patrol_points.assign(encounter.west_sentinel_patrol)
	guard.patrol_speed = encounter.west_sentinel_speed
	guard.vision_range = encounter.west_sentinel_vision
	guard.vision_half_angle_degrees = encounter.west_sentinel_half_angle
	guard_east = _make_fighter("AshenLookout", encounter.east_sentinel_spawn, false)
	guard_east.add_to_group("stealth_guards")
	guard_east.target = player
	guard_east.patrol_points.assign(encounter.east_sentinel_patrol)
	guard_east.patrol_speed = encounter.east_sentinel_speed
	guard_east.vision_range = encounter.east_sentinel_vision
	guard_north = _make_fighter("AshenRanger", encounter.north_sentinel_spawn, false)
	guard_north.add_to_group("stealth_guards")
	guard_north.target = player
	guard_north.patrol_points.assign(encounter.north_sentinel_patrol)
	guard_north.patrol_speed = encounter.north_sentinel_speed
	for i in range(encounter.stealth_cover_positions.size()):
		var cover_names := ["MossyBushA", "MossyBushB", "SupplyCrates"]
		world_builder._create_stealth_cover(encounter.stealth_cover_positions[i], cover_names[i] if i < cover_names.size() else "StealthCover%d" % i)
	var grapple_names := ["GrappleAnchorWest", "GrappleAnchorNorth", "GrappleAnchorEast"]
	for i in range(encounter.grapple_anchor_positions.size()):
		world_builder._create_grapple_point(encounter.grapple_anchor_positions[i], grapple_names[i] if i < grapple_names.size() else "GrappleAnchor%d" % i)
	world_builder._create_water_zone(encounter.training_pond_position, encounter.training_pond_size, "TrainingPond")
	world_builder._create_climb_wall(encounter.climb_wall_position, encounter.climb_wall_size, "ClimbableTowerWall")
	world_builder._create_exploration_paths()
	world_builder._create_north_ruined_gate()
	world_builder._create_east_watch_camp()
	world_builder._create_landmark("WestGroveMonolith", encounter.west_monolith_position, Color(0.28, 0.36, 0.31))
	world_builder._create_landmark("PondsideBell", encounter.pondside_bell_position, Color(0.25, 0.38, 0.46))
	world_builder._create_secret_cache(encounter.secret_cache_position, "GroveRelicCache")
	world_builder._create_rest_point(encounter.ashen_shrine_position, "AshenRestShrine")
	world_builder._create_rest_point(encounter.grove_shrine_position, "GroveRestShrine")
	enemy = boss
	player.target = enemy
	world_builder.connect_water_zones(player)
	player.set_checkpoint(encounter.player_spawn)
	var starting_shrine := world_builder.get_node_or_null("AshenRestShrine")
	if is_instance_valid(starting_shrine):
		starting_shrine.set_active(true)
	player.checkpoint_position = encounter.player_checkpoint
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
	combat_feedback_service = COMBAT_FEEDBACK_SERVICE.new()
	combat_feedback_service.configure(self, camera_rig)
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

func _on_enemy_attack_hit(target_node: Node) -> void:
	combat_feedback_service.on_enemy_attack_hit(target_node)

func _on_player_attack_hit(target_node: Node) -> void:
	combat_feedback_service.on_player_attack_hit(target_node)

func _trigger_hitstop(duration: float, strength: float) -> void:
	combat_feedback_service.trigger_hitstop(duration, strength)
	_hitstop_generation = combat_feedback_service._hitstop_generation

func _restore_hitstop(generation: int) -> void:
	combat_feedback_service.restore_hitstop(generation)

func _on_combat_feedback(kind: String, source: Node3D) -> void:
	combat_feedback_service.handle_feedback(kind, source)
	_hitstop_generation = combat_feedback_service._hitstop_generation

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
