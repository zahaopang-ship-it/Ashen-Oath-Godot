extends CharacterBody3D

const NAVIGATION_STEERING = preload("res://scripts/ai/sentinel_navigation_steering.gd")
const STEALTH_AWARENESS = preload("res://scripts/ai/stealth_awareness_controller.gd")
const SENTINEL_AI = preload("res://scripts/ai/sentinel_ai_controller.gd")
const TRAVERSAL_CONTROLLER = preload("res://scripts/traversal/fighter_traversal_controller.gd")
const PROSTHETIC_CONTROLLER = preload("res://scripts/prosthetics/fighter_prosthetic_controller.gd")
const EXPLORATION_CONTROLLER = preload("res://scripts/exploration/fighter_exploration_controller.gd")
const LOCOMOTION_CONTROLLER = preload("res://scripts/movement/fighter_locomotion_controller.gd")
const ANIMATION_CONTROLLER = preload("res://scripts/animation/fighter_animation_controller.gd")
const COMBAT_RESOLUTION = preload("res://scripts/combat/fighter_combat_resolution.gd")
const ATTACK_CONTROLLER = preload("res://scripts/combat/fighter_attack_controller.gd")
const ACTION_CONTROLLER = preload("res://scripts/combat/fighter_action_controller.gd")

signal telegraph_started(kind: String)
signal attack_phase_changed(phase: String)
signal attack_hit(target: Node)
signal posture_broken
signal died
signal exploration_event(event_name: String)
signal combat_feedback(kind: String, source: Node3D)

enum CombatState { FREE, WINDUP, ACTIVE, RECOVERY, POSTURE_BROKEN, DEAD, HITSTUN, EXECUTING }
enum AwarenessState { IDLE, SUSPICIOUS, SEARCHING, ALERTED }

@export var is_player := false
@export var display_name := "Fighter"
@export var move_speed := 5.2
var movement_acceleration := 30.0
var movement_braking := 34.0
var combat_turn_speed := 15.0
var dodge_speed := 10.0
@export var max_vitality := 100.0
@export var vitality := 100.0
@export var max_posture := 100.0
@export var posture := 0.0
@export var deflect_window := 0.20
@export var deflect_lockout := 0.34
@export var attack_range := 2.15
@export var attack_damage := 22.0
@export var attack_posture_damage := 30.0

var fighter_config: Resource
var target: CharacterBody3D
var navigation_agent: NavigationAgent3D
var _navigation_target := Vector3.INF
var input_move := Vector2.ZERO
var state: CombatState = CombatState.FREE
var is_blocking := false
var is_deflecting := false
var is_dodging := false
var is_dead := false
var attack_timer := 0.0
var deflect_timer := 0.0
var deflect_cooldown := 0.0
var dodge_timer := 0.0
var posture_break_timer := 0.0
var hit_reaction_timer := 0.0
var hit_reaction_duration := 0.18
var hit_reaction_kind := "slash"
var _hit_reaction_side := 1.0
var _posture_break_age := 0.0
var hit_flash_timer := 0.0
var _parry_pose_timer := 0.0
var _deflect_recoil_timer := 0.0
var _body_material: StandardMaterial3D
var _upper_body: Node3D
var _weapon_pivot: Node3D
var _left_leg_pivot: Node3D
var _right_leg_pivot: Node3D
var _left_arm_pivot: Node3D
var _right_arm_pivot: Node3D
var _left_elbow_pivot: Node3D
var _right_elbow_pivot: Node3D
var _combat_anim_time := 0.0
var _gait_phase := 0.0
var _locomotion_bob := 0.0
var ai_timer := 0.8
var awareness_state: AwarenessState = AwarenessState.IDLE
var suspicion := 0.0
var suspicion_threshold := 1.15
var search_timer := 0.0
var lost_sight_timer := 0.0
var last_known_target_position := Vector3.ZERO
var vision_range := 10.0
var vision_half_angle_degrees := 48.0
var sprint_noise_range := 8.0
var stealth_deathblow_started := false
var is_crouching := false
var is_in_cover := false
var stealth_cover_count := 0
var is_vaulting := false
var _vault_elapsed := 0.0
var _vault_duration := 0.42
var _vault_start := Vector3.ZERO
var _vault_end := Vector3.ZERO
var _vault_height := 0.82
var _traversal_kind := "vault"
var is_wall_hugging := false
var is_cover_transferring := false
var _cover_transfer_target: Node3D
var _cover_transfer_detour := Vector3.ZERO
var _cover_transfer_detouring := false
var _wall_hug_normal := Vector3.ZERO
var _wall_hug_side := 0.0
var _search_scan_time := 0.0
var _search_origin_yaw := 0.0
var _search_points: Array[Vector3] = []
var _search_point_index := 0
var _search_pause_timer := 0.0
var body_collision: CollisionShape3D
var patrol_points: Array[Vector3] = []
var patrol_index := 0
var patrol_wait_timer := 0.0
var patrol_speed := 1.65
var _patrol_pause := 0.7
var gravity := 22.0
var attack_kind := "slash"
var is_mikiri_countering := false
var is_sweep_evading := false
var counter_timer := 0.0
var _attack_hit_applied := false
var _attack_token := 0
var buffered_attack_kind := ""
var attack_buffer_timer := 0.0
var combo_step := 0
var combo_reset_timer := 0.0
var dodge_cooldown := 0.0
var is_sprinting := false
var sprint_requested := false
var posture_stomped := false
var deathblow_executed := false
var execution_timer := 0.0
var execution_partner: Node3D
var prosthetic_energy := 100.0
var max_prosthetic_energy := 100.0
var prosthetic_cooldown := 0.0
var umbrella_timer := 0.0
var _distraction_active := false
var _distraction_timer := 0.0
var prosthetic_pose := ""
var prosthetic_pose_timer := 0.0
var lightning_reversal_timer := 0.0
var prosthetic_upgrade_points := 3
var upgrade_selection_index := 0
var resurrection_charges := 1
var max_resurrection_charges := 1
var resurrection_invulnerability := 0.0
var resurrection_available := true
var checkpoint_position := Vector3.ZERO
var is_grappling := false
var is_swimming := false
var is_climbing := false
var is_ledge_hanging := false
var _climb_normal := Vector3.ZERO
var _ledge_hang_position := Vector3.ZERO
var _water_surface_y := 0.0
var swim_speed := 3.2
var swim_vertical_input := 0.0
var climb_speed := 2.5
var grapple_target: Node3D
var _grapple_start := Vector3.ZERO
var _grapple_end := Vector3.ZERO
var _grapple_elapsed := 0.0
var _grapple_duration := 0.48
var _grapple_height := 1.25
var _grapple_attack_ready := false
var prosthetic_upgrades := {"shuriken": 0, "firecracker": 0, "axe": 0, "umbrella": 0}

const WINDUP_TIME := 0.32
const ACTIVE_TIME := 0.10
const RECOVERY_TIME := 0.34
const POSTURE_BREAK_TIME := 1.35
const HIT_FLASH_COLOR := Color(1.0, 0.72, 0.58)
const ATTACK_KINDS := ["slash", "thrust", "sweep", "heavy", "grab", "ashen_rend", "lightning"]
const ATTACK_DAMAGE := {"slash": 22.0, "thrust": 27.0, "sweep": 18.0, "heavy": 34.0, "grab": 30.0, "ashen_rend": 46.0, "lightning": 38.0}
const ATTACK_POSTURE := {"slash": 30.0, "thrust": 36.0, "sweep": 24.0, "heavy": 46.0, "grab": 12.0, "ashen_rend": 58.0, "lightning": 42.0}
const ATTACK_WINDUP := {"slash": 0.32, "thrust": 0.48, "sweep": 0.42, "heavy": 0.62, "grab": 0.72, "ashen_rend": 0.92, "lightning": 1.05}
const ATTACK_HITBOX := {
	"slash": Vector3(0.95, 1.25, 1.65),
	"thrust": Vector3(0.52, 1.10, 2.10),
	"sweep": Vector3(1.45, 0.62, 1.55),
	"heavy": Vector3(1.00, 1.40, 1.90),
	"grab": Vector3(0.85, 1.15, 1.45),
	"ashen_rend": Vector3(1.65, 1.45, 2.35),
	"lightning": Vector3(1.35, 1.55, 2.2)
}
const ATTACK_BUFFER_WINDOW := 0.58
const COMBO_RESET_TIME := 0.95

func _physics_process(delta: float) -> void:
	if is_ledge_hanging:
		_update_ledge_hang(delta)
		_update_combat_animation(delta)
		return
	if is_climbing:
		_update_vertical_climb(delta)
		_update_combat_animation(delta)
		return
	if is_grappling:
		_update_grapple(delta)
		_update_combat_animation(delta)
		return
	if is_vaulting:
		_update_vault(delta)
		_update_combat_animation(delta)
		return
	if is_dead:
		_update_combat_animation(delta)
		velocity = Vector3.ZERO
		return
	if state == CombatState.EXECUTING:
		execution_timer = maxf(0.0, execution_timer - delta)
		if execution_timer <= 0.0:
			if deathblow_executed:
				vitality = 0.0
				_die()
			else:
				state = CombatState.FREE
			execution_partner = null
		_update_combat_animation(delta)
		velocity = Vector3.ZERO
		return
	deflect_timer = maxf(0.0, deflect_timer - delta)
	resurrection_invulnerability = maxf(0.0, resurrection_invulnerability - delta)
	prosthetic_cooldown = maxf(0.0, prosthetic_cooldown - delta)
	lightning_reversal_timer = maxf(0.0, lightning_reversal_timer - delta)
	prosthetic_pose_timer = maxf(0.0, prosthetic_pose_timer - delta)
	if prosthetic_pose_timer <= 0.0:
		prosthetic_pose = ""
	if umbrella_timer > 0.0:
		umbrella_timer = maxf(0.0, umbrella_timer - delta)
		if umbrella_timer <= 0.0:
			is_blocking = false
	if is_player and state == CombatState.FREE:
		prosthetic_energy = minf(max_prosthetic_energy, prosthetic_energy + 5.5 * delta)
	if _distraction_active:
		_distraction_timer = maxf(0.0, _distraction_timer - delta)
		if _distraction_timer <= 0.0:
			_distraction_active = false
	_parry_pose_timer = maxf(0.0, _parry_pose_timer - delta)
	_deflect_recoil_timer = maxf(0.0, _deflect_recoil_timer - delta)
	deflect_cooldown = maxf(0.0, deflect_cooldown - delta)
	dodge_timer = maxf(0.0, dodge_timer - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	counter_timer = maxf(0.0, counter_timer - delta)
	attack_buffer_timer = maxf(0.0, attack_buffer_timer - delta)
	if attack_buffer_timer <= 0.0:
		buffered_attack_kind = ""
	combo_reset_timer = maxf(0.0, combo_reset_timer - delta)
	if combo_reset_timer <= 0.0 and state == CombatState.FREE and buffered_attack_kind.is_empty():
		combo_step = 0
	if counter_timer <= 0.0:
		is_mikiri_countering = false
		is_sweep_evading = false
	is_deflecting = deflect_timer > 0.0
	is_dodging = dodge_timer > 0.0
	if state == CombatState.HITSTUN:
		_update_hit_reaction(delta)
	elif state == CombatState.POSTURE_BROKEN:
		_posture_break_age += delta
		posture_break_timer = maxf(0.0, posture_break_timer - delta)
		if posture_break_timer <= 0.0:
			state = CombatState.FREE
	elif state in [CombatState.WINDUP, CombatState.ACTIVE, CombatState.RECOVERY]:
		_update_attack_state(delta)
	if not is_player and state == CombatState.FREE:
		_ai_update(delta)
	elif is_player:
		_player_update(delta)
	if not is_blocking and state not in [CombatState.WINDUP, CombatState.ACTIVE, CombatState.RECOVERY, CombatState.POSTURE_BROKEN]:
		var vitality_factor := lerpf(0.35, 1.0, clampf(vitality / maxf(1.0, max_vitality), 0.0, 1.0))
		posture = maxf(0.0, posture - 8.0 * vitality_factor * delta)
	_update_combat_animation(delta)
	if is_swimming:
		var swim_input := Vector3(input_move.x, 0.0, input_move.y)
		var swim_direction := global_transform.basis * swim_input
		swim_direction.y = 0.0
		if swim_direction.length_squared() > 1.0:
			swim_direction = swim_direction.normalized()
		velocity.x = move_toward(velocity.x, swim_direction.x * swim_speed, movement_acceleration * 0.55 * delta)
		velocity.z = move_toward(velocity.z, swim_direction.z * swim_speed, movement_acceleration * 0.55 * delta)
		var vertical_input := swim_vertical_input + Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
		velocity.y = move_toward(velocity.y, clampf(vertical_input, -1.0, 1.0) * swim_speed * 0.72, 8.0 * delta)
		velocity.y += clampf((_water_surface_y - 0.85) - global_position.y, -1.5, 1.5) * 1.8 * delta
		move_and_slide()
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()

func _update_attack_state(delta: float) -> void:
	attack_timer -= delta
	if state == CombatState.WINDUP and attack_timer <= 0.0:
		state = CombatState.ACTIVE
		attack_phase_changed.emit("active")
		attack_timer = ACTIVE_TIME
		_resolve_attack_hit()
	elif state == CombatState.ACTIVE:
		_resolve_attack_hit()
		if attack_timer <= 0.0:
			state = CombatState.RECOVERY
			attack_phase_changed.emit("recovery")
			attack_timer = RECOVERY_TIME
	elif state == CombatState.RECOVERY and attack_timer <= 0.0:
		state = CombatState.FREE
		attack_phase_changed.emit("finished")
		if is_player and not buffered_attack_kind.is_empty() and attack_buffer_timer > 0.0:
			var next_kind := buffered_attack_kind
			buffered_attack_kind = ""
			attack_buffer_timer = 0.0
			start_attack(next_kind)

func _update_hit_reaction(delta: float) -> void:
	hit_reaction_timer = maxf(0.0, hit_reaction_timer - delta)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if _body_material:
		_body_material.albedo_color = HIT_FLASH_COLOR.lerp(_body_material.get_meta("base_color", Color.WHITE), 1.0 - clampf(hit_flash_timer / 0.12, 0.0, 1.0))
	if hit_reaction_timer <= 0.0:
		state = CombatState.FREE
		if _body_material and _body_material.has_meta("base_color"):
			_body_material.albedo_color = _body_material.get_meta("base_color")

func set_body_material(material: StandardMaterial3D) -> void:
	ANIMATION_CONTROLLER.set_body_material(self, material)

func set_animation_rig(upper_body: Node3D, weapon_pivot: Node3D, left_leg: Node3D = null, right_leg: Node3D = null, left_arm: Node3D = null, right_arm: Node3D = null, left_elbow: Node3D = null, right_elbow: Node3D = null) -> void:
	ANIMATION_CONTROLLER.set_animation_rig(self, upper_body, weapon_pivot, left_leg, right_leg, left_arm, right_arm, left_elbow, right_elbow)

func _update_combat_animation(delta: float) -> void:
	ANIMATION_CONTROLLER.update_combat_animation(self, delta)

func _begin_hit_reaction(attacker: Node3D, incoming_kind: String = "slash") -> void:
	COMBAT_RESOLUTION.begin_hit_reaction(self, attacker, incoming_kind)

func _player_update(delta: float) -> void:
	LOCOMOTION_CONTROLLER.update_player(self, delta)

func _get_player_move_direction() -> Vector3:
	return LOCOMOTION_CONTROLLER.get_player_move_direction(self)

func _ai_update(delta: float) -> void:
	SENTINEL_AI.update(self, delta)

func _patrol_update(delta: float) -> void:
	SENTINEL_AI.update_patrol(self, delta)

func _steer_ai_toward(destination: Vector3, speed: float, delta: float, turn_speed: float) -> void:
	NAVIGATION_STEERING.steer_toward(self, destination, speed, delta, turn_speed)

func _get_global_route_direction(destination: Vector3, fallback: Vector3) -> Vector3:
	return NAVIGATION_STEERING.get_global_route_direction(self, destination, fallback)

func _get_navigation_direction(desired_direction: Vector3, probe_distance: float = 1.9) -> Vector3:
	return NAVIGATION_STEERING.get_navigation_direction(self, desired_direction, probe_distance)

func _apply_guard_separation(travel_direction: Vector3, radius: float = 2.4) -> Vector3:
	return NAVIGATION_STEERING.apply_guard_separation(self, travel_direction, radius)

func _try_wall_corner_transition(tangent_direction: Vector3) -> bool:
	return TRAVERSAL_CONTROLLER.try_wall_corner_transition(self, tangent_direction)

func _cancel_cover_transfer() -> void:
	TRAVERSAL_CONTROLLER.cancel_cover_transfer(self)

func begin_cover_transfer(max_distance: float = 7.0) -> bool:
	return TRAVERSAL_CONTROLLER.begin_cover_transfer(self, max_distance)

func toggle_wall_hug() -> bool:
	return TRAVERSAL_CONTROLLER.toggle_wall_hug(self)

func try_mantle() -> bool:
	return TRAVERSAL_CONTROLLER.try_mantle(self)

func try_vault() -> bool:
	return TRAVERSAL_CONTROLLER.try_vault(self)

func _update_vault(delta: float) -> void:
	TRAVERSAL_CONTROLLER.update_vault(self, delta)

func set_crouching(enabled: bool) -> void:
	TRAVERSAL_CONTROLLER.set_crouching(self, enabled)

func toggle_crouch() -> void:
	set_crouching(not is_crouching)

func _update_awareness(delta: float) -> void:
	STEALTH_AWARENESS.update_awareness(self, delta)

func _begin_cover_search() -> void:
	STEALTH_AWARENESS.begin_cover_search(self)

func _get_target_vision_multiplier(candidate: Node3D) -> float:
	return STEALTH_AWARENESS.get_target_vision_multiplier(self, candidate)

func set_stealth_cover(zone: Area3D, entering: bool) -> void:
	STEALTH_AWARENESS.set_stealth_cover(self, zone, entering)

func _on_cover_zone_body_entered(body: Node3D, zone: Area3D) -> void:
	STEALTH_AWARENESS.on_cover_zone_body_entered(self, body, zone)

func _on_cover_zone_body_exited(body: Node3D, zone: Area3D) -> void:
	STEALTH_AWARENESS.on_cover_zone_body_exited(self, body, zone)

func _target_in_vision_cone(offset: Vector3) -> bool:
	return STEALTH_AWARENESS.target_in_vision_cone(self, offset)

func _has_clear_line_of_sight(candidate: Node3D) -> bool:
	return STEALTH_AWARENESS.has_clear_line_of_sight(self, candidate)

func emit_noise(noise_position: Vector3, radius: float) -> void:
	STEALTH_AWARENESS.emit_noise(self, noise_position, radius)

func use_prosthetic(tool: String) -> bool:
	return PROSTHETIC_CONTROLLER.use_prosthetic(self, tool)

func _use_shuriken() -> bool:
	return PROSTHETIC_CONTROLLER.use_shuriken(self)

func _use_firecracker() -> void:
	PROSTHETIC_CONTROLLER.use_firecracker(self)

func _use_axe() -> bool:
	return PROSTHETIC_CONTROLLER.use_axe(self)

func begin_lightning_reversal() -> bool:
	return PROSTHETIC_CONTROLLER.begin_lightning_reversal(self)

func receive_lightning_reversal(defender: Node3D) -> void:
	PROSTHETIC_CONTROLLER.receive_lightning_reversal(self, defender)

func _spawn_lightning_arc(other: Node3D, tint: Color) -> void:
	PROSTHETIC_CONTROLLER.spawn_lightning_arc(self, other, tint)

func upgrade_next_prosthetic() -> bool:
	return PROSTHETIC_CONTROLLER.upgrade_next_prosthetic(self)

func upgrade_prosthetic(tool: String) -> bool:
	return PROSTHETIC_CONTROLLER.upgrade_prosthetic(self, tool)

func receive_distraction(noise_position: Vector3) -> void:
	STEALTH_AWARENESS.receive_distraction(self, noise_position)

func _face_direction(dir: Vector3, delta: float, turn_speed: float = 12.0) -> void:
	LOCOMOTION_CONTROLLER.face_direction(self, dir, delta, turn_speed)

func start_attack(kind: String = "slash") -> bool:
	return ATTACK_CONTROLLER.start_attack(self, kind)

func _is_target_inside_attack_hitbox(candidate: Node3D) -> bool:
	return ATTACK_CONTROLLER.is_target_inside_hitbox(self, candidate)

func _resolve_attack_hit() -> void:
	ATTACK_CONTROLLER.resolve_attack_hit(self)

func receive_strike(damage: float, posture_damage: float, attacker: Node3D, incoming_kind: String = "slash") -> String:
	return COMBAT_RESOLUTION.receive_strike(self, damage, posture_damage, attacker, incoming_kind)

func receive_deflect(amount: float) -> void:
	COMBAT_RESOLUTION.receive_deflect(self, amount)

func _check_posture_break() -> void:
	COMBAT_RESOLUTION.check_posture_break(self)

func _die() -> void:
	COMBAT_RESOLUTION.die(self)

func set_swim_vertical_input(value: float) -> void:
	TRAVERSAL_CONTROLLER.set_swim_vertical_input(self, value)

func enter_water(surface_y: float) -> void:
	TRAVERSAL_CONTROLLER.enter_water(self, surface_y)

func exit_water() -> void:
	TRAVERSAL_CONTROLLER.exit_water(self)

func try_vertical_climb() -> bool:
	return TRAVERSAL_CONTROLLER.try_vertical_climb(self)

func stop_vertical_climb() -> void:
	TRAVERSAL_CONTROLLER.stop_vertical_climb(self)

func _update_vertical_climb(delta: float) -> void:
	TRAVERSAL_CONTROLLER.update_vertical_climb(self, delta)

func try_ledge_grab() -> bool:
	return TRAVERSAL_CONTROLLER.try_ledge_grab(self)

func _update_ledge_hang(delta: float) -> void:
	TRAVERSAL_CONTROLLER.update_ledge_hang(self, delta)

func set_checkpoint(position: Vector3) -> void:
	EXPLORATION_CONTROLLER.set_checkpoint(self, position)

func get_nearest_rest_point(max_distance: float = 2.8) -> Node3D:
	return EXPLORATION_CONTROLLER.get_nearest_rest_point(self, max_distance)

func interact_rest_point(max_distance: float = 2.8) -> bool:
	return EXPLORATION_CONTROLLER.interact_rest_point(self, max_distance)

func interact_secret_cache(max_distance: float = 2.5) -> bool:
	return EXPLORATION_CONTROLLER.interact_secret_cache(self, max_distance)

func get_nearest_secret_cache(max_distance: float = 2.5) -> Node3D:
	return EXPLORATION_CONTROLLER.get_nearest_secret_cache(self, max_distance)

func resurrect() -> bool:
	return EXPLORATION_CONTROLLER.resurrect(self)

func begin_jump() -> bool:
	return TRAVERSAL_CONTROLLER.begin_jump(self)

func try_grapple() -> bool:
	return TRAVERSAL_CONTROLLER.try_grapple(self)

func _update_grapple(delta: float) -> void:
	TRAVERSAL_CONTROLLER.update_grapple(self, delta)

func aerial_grapple_attack() -> bool:
	return TRAVERSAL_CONTROLLER.aerial_grapple_attack(self)

func request_player_attack() -> bool:
	return ATTACK_CONTROLLER.request_player_attack(self)

func player_attack() -> void:
	request_player_attack()

func get_vitality_ratio() -> float:
	return vitality / maxf(1.0, max_vitality)

func get_posture_ratio() -> float:
	return posture / maxf(1.0, max_posture)

func begin_mikiri_counter() -> bool:
	return ACTION_CONTROLLER.begin_mikiri_counter(self)

func begin_sweep_evade() -> bool:
	return ACTION_CONTROLLER.begin_sweep_evade(self)

func begin_deflect() -> bool:
	return ACTION_CONTROLLER.begin_deflect(self)

func end_deflect() -> void:
	ACTION_CONTROLLER.end_deflect(self)

func begin_block() -> void:
	ACTION_CONTROLLER.begin_block(self)

func end_block() -> void:
	ACTION_CONTROLLER.end_block(self)

func dodge() -> void:
	ACTION_CONTROLLER.dodge(self)

func stomp_broken_target() -> bool:
	return ACTION_CONTROLLER.stomp_broken_target(self)

func stealth_deathblow_target() -> bool:
	return ACTION_CONTROLLER.stealth_deathblow_target(self)

func receive_stealth_deathblow(attacker: Node3D) -> bool:
	return ACTION_CONTROLLER.receive_stealth_deathblow(self, attacker)

func deathblow_broken_target() -> bool:
	return ACTION_CONTROLLER.deathblow_broken_target(self)

func receive_deathblow(attacker: Node3D) -> bool:
	return ACTION_CONTROLLER.receive_deathblow(self, attacker)

func receive_stomp(attacker: Node3D) -> bool:
	return ACTION_CONTROLLER.receive_stomp(self, attacker)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]