extends CharacterBody3D

const NAVIGATION_STEERING = preload("res://scripts/ai/sentinel_navigation_steering.gd")
const STEALTH_AWARENESS = preload("res://scripts/ai/stealth_awareness_controller.gd")
const SENTINEL_AI = preload("res://scripts/ai/sentinel_ai_controller.gd")
const TRAVERSAL_CONTROLLER = preload("res://scripts/traversal/fighter_traversal_controller.gd")
const PROSTHETIC_CONTROLLER = preload("res://scripts/prosthetics/fighter_prosthetic_controller.gd")
const EXPLORATION_CONTROLLER = preload("res://scripts/exploration/fighter_exploration_controller.gd")
const LOCOMOTION_CONTROLLER = preload("res://scripts/movement/fighter_locomotion_controller.gd")
const COMBAT_RESOLUTION = preload("res://scripts/combat/fighter_combat_resolution.gd")
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
	_body_material = material
	if _body_material:
		_body_material.set_meta("base_color", _body_material.albedo_color)

func set_animation_rig(upper_body: Node3D, weapon_pivot: Node3D, left_leg: Node3D = null, right_leg: Node3D = null, left_arm: Node3D = null, right_arm: Node3D = null, left_elbow: Node3D = null, right_elbow: Node3D = null) -> void:
	_upper_body = upper_body
	_weapon_pivot = weapon_pivot
	_left_leg_pivot = left_leg
	_right_leg_pivot = right_leg
	_left_arm_pivot = left_arm
	_right_arm_pivot = right_arm
	_left_elbow_pivot = left_elbow
	_right_elbow_pivot = right_elbow

func _update_combat_animation(delta: float) -> void:
	_combat_anim_time += delta
	if not is_instance_valid(_upper_body) or not is_instance_valid(_weapon_pivot):
		return
	var body_pose := Vector3(0.0, 0.0, 0.0)
	var weapon_pose := Vector3(0.0, 0.0, -0.18)
	var left_arm_pose := Vector3(0.0, 0.0, 0.10)
	var right_arm_pose := Vector3(0.0, 0.0, -0.12)
	var body_offset := Vector3.ZERO
	var left_leg_pose := 0.0
	var right_leg_pose := 0.0
	var gait_blend := 0.0
	var weight := 1.0 - exp(-18.0 * delta)
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(planar_speed / maxf(0.1, move_speed * 1.42), 0.0, 1.0)
	var locomotion_active := planar_speed > 0.22 and state == CombatState.FREE and not is_blocking
	if locomotion_active:
		var gait_rate := lerpf(5.8, 10.5, speed_ratio)
		if is_sprinting:
			gait_rate *= 1.12
		var gait_style := 1.0
		if not is_player:
			gait_rate *= 0.92
			gait_style = 0.88
			if has_method("get_phase_pattern") and int(get("boss_phase")) == 2:
				gait_style = 1.12
		_gait_phase = fposmod(_gait_phase + delta * gait_rate, TAU)
		gait_blend = clampf(planar_speed / maxf(0.1, move_speed * 0.32), 0.0, 1.0)
		var stride := sin(_gait_phase) * 0.48 * gait_blend * gait_style
		left_leg_pose = stride
		right_leg_pose = -stride
		var bob_rate := 2.0 if is_sprinting else 1.0
		_locomotion_bob = absf(cos(_gait_phase)) * 0.045 * gait_blend * bob_rate
	else:
		_locomotion_bob = lerpf(_locomotion_bob, 0.0, weight)
		left_leg_pose = 0.0
		right_leg_pose = 0.0
	if is_instance_valid(_left_leg_pivot):
		_left_leg_pivot.rotation.x = lerpf(_left_leg_pivot.rotation.x, left_leg_pose, 1.0 - exp(-14.0 * delta))
	if is_instance_valid(_right_leg_pivot):
		_right_leg_pivot.rotation.x = lerpf(_right_leg_pivot.rotation.x, right_leg_pose, 1.0 - exp(-14.0 * delta))
	if state == CombatState.WINDUP:
		var duration: float = float(ATTACK_WINDUP.get(attack_kind, WINDUP_TIME))
		var progress := 1.0 - clampf(attack_timer / duration, 0.0, 1.0)
		var anticipation := sin(progress * PI * 0.5)
		match attack_kind:
			"slash":
				body_pose = Vector3(-0.12, 0.0, -0.10) * anticipation
				weapon_pose = Vector3(-1.15, 0.0, -0.75) * anticipation
			"thrust":
				body_pose = Vector3(0.08, 0.0, 0.16) * anticipation
				weapon_pose = Vector3(0.05, 0.0, 0.95) * anticipation
			"sweep":
				body_pose = Vector3(0.42, 0.0, -0.18) * anticipation
				weapon_pose = Vector3(1.0, 0.0, -1.0) * anticipation
			"heavy":
				body_pose = Vector3(-0.48, 0.0, -0.16) * anticipation
				weapon_pose = Vector3(-1.85, 0.0, -0.45) * anticipation
			"grab":
				body_pose = Vector3(-0.25, 0.0, -0.32) * anticipation
				weapon_pose = Vector3(0.15, 0.0, 0.45) * anticipation
			"ashen_rend":
				body_pose = Vector3(-0.62, 0.0, -0.24) * anticipation
				weapon_pose = Vector3(-2.05, 0.0, -0.82) * anticipation
		left_arm_pose = Vector3(-0.18, 0.0, 0.28) * anticipation
		right_arm_pose = Vector3(-0.32, 0.0, -0.42) * anticipation
	elif state == CombatState.ACTIVE:
		var progress := 1.0 - clampf(attack_timer / ACTIVE_TIME, 0.0, 1.0)
		var follow := sin(progress * PI)
		match attack_kind:
			"slash":
				body_pose = Vector3(0.12, 0.0, 0.48) * follow
				weapon_pose = Vector3(1.25, 0.0, 1.25) * follow
			"thrust":
				body_pose = Vector3(-0.12, 0.0, -0.24) * follow
				weapon_pose = Vector3(-0.08, 0.0, -0.25) * follow
			"sweep":
				body_pose = Vector3(-0.12, 0.0, 0.58) * follow
				weapon_pose = Vector3(-1.0, 0.0, 1.4) * follow
			"heavy":
				body_pose = Vector3(0.22, 0.0, 0.65) * follow
				weapon_pose = Vector3(1.75, 0.0, 1.0) * follow
			"grab":
				body_pose = Vector3(0.42, 0.0, 0.55) * follow
				weapon_pose = Vector3(-0.25, 0.0, 0.7) * follow
			"ashen_rend":
				body_pose = Vector3(0.52, 0.0, 0.72) * follow
				weapon_pose = Vector3(2.15, 0.0, 1.55) * follow
		left_arm_pose = Vector3(0.20, 0.0, -0.20) * follow
		right_arm_pose = Vector3(0.22, 0.0, 0.36) * follow
	elif state == CombatState.RECOVERY:
		left_arm_pose = Vector3(0.05, 0.0, 0.12)
		right_arm_pose = Vector3(0.12, 0.0, -0.08)
		body_pose = Vector3(0.08, 0.0, 0.08)
		weapon_pose = Vector3(0.18, 0.0, -0.10)
		left_arm_pose = Vector3(-0.08, 0.0, 0.14)
		right_arm_pose = Vector3(0.12, 0.0, -0.18)
	elif state == CombatState.HITSTUN:
		var stagger := clampf(hit_reaction_timer / maxf(0.01, hit_reaction_duration), 0.0, 1.0)
		match hit_reaction_kind:
			"thrust":
				body_pose = Vector3(-0.78, 0.0, 0.10 * _hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.22, 0.0, 0.36)
				right_arm_pose = Vector3(-0.26, 0.0, -0.34)
				weapon_pose = Vector3(0.62, 0.0, 0.18)
			"heavy", "ashen_rend":
				var force := 1.0 if hit_reaction_kind == "heavy" else 1.35
				body_pose = Vector3(-0.92 * force, 0.0, 0.34 * _hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.72, 0.0, 0.58)
				right_arm_pose = Vector3(-0.68, 0.0, -0.62)
				weapon_pose = Vector3(0.92 * force, 0.0, 0.28)
				body_offset = Vector3(0.0, -0.12 * force, 0.08)
			"sweep":
				body_pose = Vector3(0.28, 0.0, 0.72 * _hit_reaction_side) * stagger
				left_arm_pose = Vector3(0.32, 0.0, 0.62)
				right_arm_pose = Vector3(0.26, 0.0, -0.62)
				weapon_pose = Vector3(0.45, 0.0, 0.42)
				body_offset = Vector3(0.0, -0.22, 0.0)
			"grab":
				body_pose = Vector3(-0.68, 0.0, 0.0)
				left_arm_pose = Vector3(-0.12, 0.0, 0.78)
				right_arm_pose = Vector3(-0.12, 0.0, -0.78)
				weapon_pose = Vector3(0.38, 0.0, 0.0)
			_:
				body_pose = Vector3(-0.42, 0.0, 0.20 * _hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.48, 0.0, 0.42)
				right_arm_pose = Vector3(-0.42, 0.0, -0.38)
				weapon_pose = Vector3(0.55, 0.0, 0.3)
	elif state == CombatState.POSTURE_BROKEN:
		var buckle := sin(_posture_break_age * 9.0)
		left_arm_pose = Vector3(0.42 + buckle * 0.08, 0.0, 0.58)
		right_arm_pose = Vector3(0.35 + buckle * 0.06, 0.0, -0.52)
		body_pose = Vector3(0.72 + absf(buckle) * 0.10, 0.0, sin(_posture_break_age * 4.5) * 0.12)
		weapon_pose = Vector3(0.95 + buckle * 0.12, 0.0, 0.08)
		body_offset = Vector3(0.0, -0.10 - absf(buckle) * 0.04, 0.0)
	elif state == CombatState.EXECUTING:
		var execution_progress := 1.0 - clampf(execution_timer / 0.82, 0.0, 1.0)
		if deathblow_executed:
			left_arm_pose = Vector3(0.45, 0.0, 0.62)
			right_arm_pose = Vector3(0.52, 0.0, -0.62)
			# Victim folds forward, then drops as the execution completes.
			var collapse := smoothstep(0.28, 1.0, execution_progress)
			body_pose = Vector3(0.28 + collapse * 0.92, 0.0, 0.08)
			weapon_pose = Vector3(0.35 + collapse * 0.48, 0.0, 0.12)
			body_offset = Vector3(0.0, -0.10 * collapse, 0.10 * execution_progress)
		else:
			left_arm_pose = Vector3(-0.20, 0.0, 0.38)
			right_arm_pose = Vector3(-0.52, 0.0, -0.48)
			# Attacker draws back, drives in, and holds the finishing follow-through.
			var strike := sin(clampf(execution_progress / 0.62, 0.0, 1.0) * PI)
			body_pose = Vector3(-0.22 + strike * 0.38, 0.0, -0.10 + execution_progress * 0.20)
			weapon_pose = Vector3(-0.95 + strike * 1.85, 0.0, -0.35 + execution_progress * 0.72)
		left_arm_pose = Vector3(0.15, 0.0, 0.48)
		right_arm_pose = Vector3(0.12, 0.0, -0.52)
	elif state == CombatState.DEAD:
		left_arm_pose = Vector3(0.65, 0.0, 0.72)
		right_arm_pose = Vector3(0.72, 0.0, -0.68)
		body_pose = Vector3(1.35, 0.0, 0.0)
		weapon_pose = Vector3(0.4, 0.0, 0.0)
	elif umbrella_timer > 0.0:
		left_arm_pose = Vector3(-0.38, 0.0, 0.62)
		right_arm_pose = Vector3(-0.68, 0.0, -0.58)
		body_pose = Vector3(-0.16, 0.0, 0.0)
		weapon_pose = Vector3(-0.72, 0.0, -0.48)
	elif is_blocking:
		left_arm_pose = Vector3(-0.22, 0.0, 0.36)
		right_arm_pose = Vector3(-0.48, 0.0, -0.38)
		body_pose = Vector3(-0.08, 0.0, 0.0)
		weapon_pose = Vector3(-0.42, 0.0, -0.32)
	elif is_dodging:
		left_arm_pose = Vector3(0.38, 0.0, 0.45)
		right_arm_pose = Vector3(0.30, 0.0, -0.42)
		body_pose = Vector3(0.25, 0.0, 0.0)
		body_offset = Vector3(0.0, -0.13, 0.0)
		weapon_pose = Vector3(0.25, 0.0, -0.24)
	elif is_mikiri_countering:
		left_arm_pose = Vector3(-0.18, 0.0, 0.32)
		right_arm_pose = Vector3(-0.58, 0.0, -0.52)
		body_pose = Vector3(-0.16, 0.0, 0.0)
		weapon_pose = Vector3(-0.28, 0.0, -0.5)
	elif is_sweep_evading:
		left_arm_pose = Vector3(0.28, 0.0, 0.42)
		right_arm_pose = Vector3(0.12, 0.0, -0.32)
		body_pose = Vector3(0.35, 0.0, 0.0)
		weapon_pose = Vector3(-0.35, 0.0, -0.2)
	else:
		var idle_breath := sin(_combat_anim_time * 2.4)
		var walk_sway := sin(_gait_phase) * gait_blend
		body_pose = Vector3(0.025 * idle_breath + walk_sway * 0.035, 0.0, 0.025 * sin(_combat_anim_time * 1.7) + gait_blend * (0.035 if is_sprinting else 0.015))
		body_offset = Vector3(0.0, _locomotion_bob, 0.0)
		weapon_pose = Vector3(0.0, 0.0, -0.18 + 0.035 * sin(_combat_anim_time * 2.0) + walk_sway * 0.045)
		left_arm_pose = Vector3(0.035 * sin(_combat_anim_time * 2.0), 0.0, 0.10 + walk_sway * 0.12)
		right_arm_pose = Vector3(-0.04 * sin(_combat_anim_time * 2.0), 0.0, -0.12 - walk_sway * 0.10)
		if not is_player:
			weapon_pose.x -= 0.10
			body_pose.z += 0.025
			left_arm_pose.z += 0.08
			right_arm_pose.z -= 0.06
	if is_crouching:
		var sneak_cycle := sin(_combat_anim_time * (3.4 if planar_speed > 0.18 else 1.5))
		var sneak_blend := clampf(planar_speed / maxf(0.1, move_speed * 0.48), 0.0, 1.0)
		left_leg_pose = 0.48 + sneak_cycle * 0.10 * sneak_blend
		right_leg_pose = 0.48 - sneak_cycle * 0.10 * sneak_blend
		body_pose.x += 0.20 + sneak_cycle * 0.025 * sneak_blend
		body_pose.z += 0.035 * sneak_cycle * sneak_blend
		body_offset.y -= 0.22
		left_arm_pose.x -= 0.16
		right_arm_pose.x -= 0.18
		left_arm_pose.z += 0.08
		right_arm_pose.z -= 0.08
		weapon_pose.x += 0.12
	if is_wall_hugging:
		var wall_side := -1.0 if _wall_hug_side < 0.0 else 1.0
		body_pose.z += wall_side * 0.16
		body_pose.x += 0.08
		left_arm_pose.x -= 0.12
		right_arm_pose.x -= 0.20
		left_arm_pose.z -= wall_side * 0.10
		right_arm_pose.z += wall_side * 0.10
		weapon_pose.z += wall_side * 0.12
		left_leg_pose += 0.06 * wall_side
		right_leg_pose -= 0.06 * wall_side
	if is_vaulting:
		var vault_progress := clampf(_vault_elapsed / maxf(0.01, _vault_duration), 0.0, 1.0)
		var tuck := sin(vault_progress * PI)
		body_pose = Vector3(-0.28, 0.0, 0.0)
		body_offset.y += 0.08 + tuck * 0.06
		left_leg_pose = -0.72 * tuck
		right_leg_pose = -0.62 * tuck
		left_arm_pose = Vector3(-0.48, 0.0, 0.42)
		right_arm_pose = Vector3(-0.42, 0.0, -0.38)
		weapon_pose = Vector3(0.36, 0.0, -0.22)
	var parry_blend := clampf(_parry_pose_timer / 0.22, 0.0, 1.0)
	var recoil_blend := clampf(_deflect_recoil_timer / 0.20, 0.0, 1.0)
	var tool_blend := clampf(prosthetic_pose_timer / 0.34, 0.0, 1.0)
	match prosthetic_pose:
		"shuriken":
			right_arm_pose += Vector3(-0.58, 0.0, -0.24) * tool_blend
			weapon_pose += Vector3(-0.18, 0.0, -0.18) * tool_blend
		"firecracker":
			left_arm_pose += Vector3(-0.30, 0.0, 0.42) * tool_blend
			right_arm_pose += Vector3(-0.30, 0.0, -0.42) * tool_blend
		"axe":
			right_arm_pose += Vector3(-0.72, 0.0, -0.16) * tool_blend
			weapon_pose += Vector3(-0.92, 0.0, -0.12) * tool_blend
	# A successful deflect snaps the defender's blade into the contact line.
	right_arm_pose += Vector3(-0.24, 0.0, 0.42) * parry_blend
	left_arm_pose += Vector3(-0.10, 0.0, -0.16) * parry_blend
	weapon_pose += Vector3(-0.32, 0.0, 0.58) * parry_blend
	# The attacker absorbs a short, readable recoil through shoulders and wrists.
	body_pose.x -= 0.16 * recoil_blend
	right_arm_pose += Vector3(0.28, 0.0, -0.24) * recoil_blend
	left_arm_pose += Vector3(0.12, 0.0, 0.12) * recoil_blend
	weapon_pose += Vector3(0.38, 0.0, -0.30) * recoil_blend
	_upper_body.rotation = _upper_body.rotation.lerp(body_pose, weight)
	_upper_body.position = _upper_body.position.lerp(body_offset, weight)
	_weapon_pivot.rotation = _weapon_pivot.rotation.lerp(weapon_pose, weight)
	if is_instance_valid(_left_arm_pivot):
		_left_arm_pivot.rotation = _left_arm_pivot.rotation.lerp(left_arm_pose, weight)
	if is_instance_valid(_right_arm_pivot):
		_right_arm_pivot.rotation = _right_arm_pivot.rotation.lerp(right_arm_pose, weight)
	var left_elbow_bend := clampf(absf(left_arm_pose.x) * 0.42 + absf(left_arm_pose.z) * 0.28 + 0.10, 0.08, 0.72)
	var right_elbow_bend := clampf(absf(right_arm_pose.x) * 0.42 + absf(right_arm_pose.z) * 0.28 + 0.12, 0.08, 0.78)
	if is_blocking:
		left_elbow_bend = 0.58
		right_elbow_bend = 0.66
	if is_instance_valid(_left_elbow_pivot):
		_left_elbow_pivot.rotation.x = lerpf(_left_elbow_pivot.rotation.x, left_elbow_bend, weight)
	if is_instance_valid(_right_elbow_pivot):
		_right_elbow_pivot.rotation.x = lerpf(_right_elbow_pivot.rotation.x, right_elbow_bend, weight)

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
	if tangent_direction.length_squared() < 0.5 or _wall_hug_normal.length_squared() < 0.5:
		return false
	var direction := tangent_direction.normalized()
	var probe_origin := global_position + direction * 0.82 + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(probe_origin, probe_origin - direction * 1.25)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var next_normal: Vector3 = hit.normal
	next_normal.y = 0.0
	if next_normal.length_squared() < 0.5:
		return false
	next_normal = next_normal.normalized()
	if absf(next_normal.dot(_wall_hug_normal)) > 0.78:
		return false
	_wall_hug_normal = next_normal
	return true

func _cancel_cover_transfer() -> void:
	is_cover_transferring = false
	_cover_transfer_target = null
	_cover_transfer_detouring = false
	_cover_transfer_detour = Vector3.ZERO

func begin_cover_transfer(max_distance: float = 7.0) -> bool:
	if not is_player or is_dead or state != CombatState.FREE or is_vaulting or is_wall_hugging or is_cover_transferring:
		return false
	if not is_crouching:
		return false
	var nearest: Area3D
	var nearest_distance := max_distance
	for candidate in get_tree().get_nodes_in_group("stealth_cover_zones"):
		if not is_instance_valid(candidate):
			continue
		var point: Vector3 = candidate.global_position
		var offset := point - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance < 1.8 or distance >= nearest_distance:
			continue
		nearest = candidate
		nearest_distance = distance
	if not is_instance_valid(nearest):
		return false
	_cover_transfer_target = nearest
	_cover_transfer_detouring = false
	_cover_transfer_detour = Vector3.ZERO
	is_cover_transferring = true
	sprint_requested = false
	is_sprinting = false
	return true

func toggle_wall_hug() -> bool:
	if not is_player or is_dead or is_vaulting or state != CombatState.FREE:
		return false
	if is_wall_hugging:
		is_wall_hugging = false
		_wall_hug_normal = Vector3.ZERO
		return true
	var forward := -global_transform.basis.z
	var origin := global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 0.95)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var normal: Vector3 = hit.normal
	if absf(normal.y) > 0.25:
		return false
	_wall_hug_normal = normal.normalized()
	_wall_hug_side = signf(global_transform.basis.x.dot(_wall_hug_normal))
	if is_zero_approx(_wall_hug_side):
		_wall_hug_side = 1.0
	is_wall_hugging = true
	is_crouching = true
	is_sprinting = false
	return true

func try_mantle() -> bool:
	if not is_player or is_dead or is_vaulting or state != CombatState.FREE or not is_on_floor():
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length_squared() < 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var chest_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.02, global_position + Vector3.UP * 1.02 + forward * 1.05)
	chest_query.exclude = [get_rid()]
	var obstacle_hit := space.intersect_ray(chest_query)
	if obstacle_hit.is_empty():
		return false
	var head_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.92, global_position + Vector3.UP * 1.92 + forward * 1.20)
	head_query.exclude = [get_rid()]
	if not space.intersect_ray(head_query).is_empty():
		return false
	var landing := global_position + forward * 1.75
	var floor_query := PhysicsRayQueryParameters3D.create(landing + Vector3.UP * 2.8, landing + Vector3.DOWN * 2.8)
	floor_query.exclude = [get_rid()]
	var floor_hit := space.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return false
	var landing_y: float = (floor_hit.position as Vector3).y
	var rise := landing_y - global_position.y
	if rise < 0.45 or rise > 1.55:
		return false
	landing.y = landing_y
	_vault_start = global_position
	_vault_end = landing
	_vault_elapsed = 0.0
	_vault_duration = 0.62
	_vault_height = 0.38
	_traversal_kind = "mantle"
	is_wall_hugging = false
	is_vaulting = true
	is_crouching = false
	is_sprinting = false
	sprint_requested = false
	velocity = Vector3.ZERO
	return true

func try_vault() -> bool:
	if not is_player or is_dead or is_vaulting or state != CombatState.FREE or not is_on_floor():
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length_squared() < 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var low_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.58, global_position + Vector3.UP * 0.58 + forward * 1.25)
	low_query.exclude = [get_rid()]
	var low_hit := space.intersect_ray(low_query)
	if low_hit.is_empty():
		return false
	var high_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.48, global_position + Vector3.UP * 1.48 + forward * 1.15)
	high_query.exclude = [get_rid()]
	if not space.intersect_ray(high_query).is_empty():
		return false
	var landing := global_position + forward * 1.9
	var floor_query := PhysicsRayQueryParameters3D.create(landing + Vector3.UP * 2.0, landing + Vector3.DOWN * 2.0)
	floor_query.exclude = [get_rid()]
	var floor_hit := space.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return false
	landing.y = (floor_hit.position as Vector3).y
	_vault_start = global_position
	_vault_end = landing
	_vault_elapsed = 0.0
	_vault_duration = 0.42
	_vault_height = 0.82
	_traversal_kind = "vault"
	is_wall_hugging = false
	is_vaulting = true
	is_crouching = false
	is_sprinting = false
	sprint_requested = false
	velocity = Vector3.ZERO
	return true

func _update_vault(delta: float) -> void:
	_vault_elapsed = minf(_vault_duration, _vault_elapsed + delta)
	var t := _vault_elapsed / _vault_duration
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _vault_start.lerp(_vault_end, eased) + Vector3.UP * (sin(t * PI) * _vault_height)
	if t >= 1.0:
		global_position = _vault_end
		is_vaulting = false
		_traversal_kind = "vault"
		velocity = Vector3.ZERO

func set_crouching(enabled: bool) -> void:
	if not is_player or is_dead or state != CombatState.FREE:
		return
	if not enabled and is_cover_transferring:
		_cancel_cover_transfer()
	is_crouching = enabled
	if is_instance_valid(body_collision) and body_collision.shape is CapsuleShape3D:
		var capsule := body_collision.shape as CapsuleShape3D
		capsule.height = 1.05 if enabled else 1.8
		capsule.radius = 0.36 if enabled else 0.42
		body_collision.position.y = 0.53 if enabled else 0.9
	if enabled:
		sprint_requested = false
		is_sprinting = false

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
	if is_dead or state != CombatState.FREE or is_blocking or not ATTACK_KINDS.has(kind):
		return false
	if is_player:
		var noise_radius := 3.2 if is_crouching else 9.5
		for listener in get_tree().get_nodes_in_group("stealth_guards"):
			if is_instance_valid(listener) and listener.has_method("emit_noise"):
				listener.emit_noise(global_position, noise_radius)
	_attack_token += 1
	_attack_hit_applied = false
	attack_kind = kind
	state = CombatState.WINDUP
	attack_timer = float(ATTACK_WINDUP[kind])
	telegraph_started.emit(kind)
	attack_phase_changed.emit("windup")
	return true

func _is_target_inside_attack_hitbox(candidate: Node3D) -> bool:
	if not is_instance_valid(candidate):
		return false
	var local_center: Vector3 = global_transform.affine_inverse() * (candidate.global_position + Vector3.UP * 0.9)
	var half_extents: Vector3 = ATTACK_HITBOX.get(attack_kind, ATTACK_HITBOX["slash"])
	var vertical_center := 0.45 if attack_kind == "sweep" else 0.9
	return absf(local_center.x) <= half_extents.x and absf(local_center.y - vertical_center) <= half_extents.y and local_center.z <= -0.22 and local_center.z >= -half_extents.z

func _resolve_attack_hit() -> void:
	if _attack_hit_applied or not is_instance_valid(target) or target.is_dead:
		return
	if not _is_target_inside_attack_hitbox(target):
		return
	_attack_hit_applied = true
	target.receive_strike(float(ATTACK_DAMAGE[attack_kind]), float(ATTACK_POSTURE[attack_kind]), self, attack_kind)
	attack_hit.emit(target)

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

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]