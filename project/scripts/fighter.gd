extends CharacterBody3D
signal telegraph_started(kind: String)
signal attack_phase_changed(phase: String)
signal attack_hit(target: Node)
signal posture_broken
signal died
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
	if state == CombatState.POSTURE_BROKEN or is_dead:
		return
	hit_reaction_kind = incoming_kind
	hit_reaction_duration = 0.34 if incoming_kind in ["heavy", "ashen_rend"] else (0.25 if incoming_kind in ["thrust", "sweep", "grab"] else 0.18)
	state = CombatState.HITSTUN
	hit_reaction_timer = hit_reaction_duration
	hit_flash_timer = 0.12 if incoming_kind in ["slash", "thrust"] else 0.18
	if is_instance_valid(attacker):
		var away := global_position - attacker.global_position
		away.y = 0.0
		if away.length_squared() > 0.001:
			away = away.normalized()
			_hit_reaction_side = signf(global_transform.basis.x.dot(away))
			if is_zero_approx(_hit_reaction_side):
				_hit_reaction_side = 1.0
			var knockback := 5.0 if incoming_kind in ["heavy", "ashen_rend"] else (2.2 if incoming_kind == "thrust" else 3.4)
			velocity.x = away.x * knockback
			velocity.z = away.z * knockback

func _player_update(delta: float) -> void:
	if is_swimming:
		is_sprinting = false
		sprint_requested = false
		return
	if is_vaulting:
		return
	if state != CombatState.FREE:
		velocity.x = move_toward(velocity.x, 0.0, movement_braking * delta)
		velocity.z = move_toward(velocity.z, 0.0, movement_braking * delta)
		return
	var move_dir := _get_player_move_direction()
	if is_cover_transferring:
		if not is_instance_valid(_cover_transfer_target):
			is_cover_transferring = false
		else:
			var transfer_goal: Vector3 = _cover_transfer_detour if _cover_transfer_detouring else _cover_transfer_target.global_position
			var transfer_offset := transfer_goal - global_position
			transfer_offset.y = 0.0
			if transfer_offset.length() <= (0.38 if _cover_transfer_detouring else 0.52):
				if _cover_transfer_detouring:
					_cover_transfer_detouring = false
					_cover_transfer_detour = Vector3.ZERO
				else:
					is_cover_transferring = false
					_cover_transfer_target = null
					velocity.x = 0.0
					velocity.z = 0.0
			else:
				move_dir = transfer_offset.normalized()
				var probe_motion := move_dir * minf(0.22, transfer_offset.length())
				if test_move(global_transform, probe_motion):
					if not _cover_transfer_detouring:
						var side := Vector3(-move_dir.z, 0.0, move_dir.x)
						if test_move(global_transform, side * 0.45):
							side = -side
						if test_move(global_transform, side * 0.45):
							_cancel_cover_transfer()
						else:
							_cover_transfer_detour = global_position + side * 1.9
							_cover_transfer_detour.y = global_position.y
							_cover_transfer_detouring = true
							move_dir = side
					else:
						_cancel_cover_transfer()
						move_dir = Vector3.ZERO
	if is_wall_hugging:
		var wall_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.0, global_position + Vector3.UP * 1.0 - _wall_hug_normal * 0.95)
		wall_query.exclude = [get_rid()]
		var wall_hit := get_world_3d().direct_space_state.intersect_ray(wall_query)
		if wall_hit.is_empty():
			var old_tangent := Vector3.UP.cross(_wall_hug_normal).normalized()
			var side_input := signf(input_move.x)
			if not is_zero_approx(side_input) and _try_wall_corner_transition(old_tangent * side_input):
				wall_query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.0, global_position + Vector3.UP * 1.0 - _wall_hug_normal * 0.95)
				wall_query.exclude = [get_rid()]
				wall_hit = get_world_3d().direct_space_state.intersect_ray(wall_query)
			if wall_hit.is_empty():
				is_wall_hugging = false
				_wall_hug_normal = Vector3.ZERO
		else:
			_wall_hug_normal = (wall_hit.normal as Vector3).normalized()
			var tangent := Vector3.UP.cross(_wall_hug_normal).normalized()
			move_dir = tangent * input_move.x + _wall_hug_normal * input_move.y
			if move_dir.length_squared() > 1.0:
				move_dir = move_dir.normalized()
			var wall_distance: float = Vector2(global_position.x - wall_hit.position.x, global_position.z - wall_hit.position.z).length()
			var correction := clampf(wall_distance - 0.58, -0.8, 0.8)
			velocity += -_wall_hug_normal * correction * 5.0 * delta
		if is_wall_hugging:
			is_crouching = true
			is_sprinting = false
		else:
			is_crouching = false
	else:
		is_sprinting = not is_crouching and (sprint_requested or input_move.length() >= 0.82)
	var current_speed := move_speed * (0.48 if is_crouching else (1.42 if is_sprinting else 1.0))
	var desired_velocity := move_dir * current_speed
	var accel := movement_acceleration if move_dir.length_squared() > 0.001 else movement_braking
	velocity.x = move_toward(velocity.x, desired_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, accel * delta)
	if is_instance_valid(_upper_body):
		_upper_body.position.y = lerpf(_upper_body.position.y, -0.28 if is_crouching else 0.0, 1.0 - exp(-12.0 * delta))
	if is_crouching:
		velocity.x *= 0.92
		velocity.z *= 0.92
	if is_instance_valid(target) and not target.is_dead:
		var to_target := target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.04:
			_face_direction(to_target.normalized(), delta, combat_turn_speed)
	elif move_dir.length_squared() > 0.001:
		_face_direction(move_dir, delta)

func _get_player_move_direction() -> Vector3:
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var move_dir := right * input_move.x + forward * -input_move.y
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()
	return move_dir


func _ai_update(delta: float) -> void:
	if state != CombatState.FREE:
		return
	if is_instance_valid(target) and not target.is_dead:
		_update_awareness(delta)
	else:
		_patrol_update(delta)
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if awareness_state == AwarenessState.ALERTED:
		if distance > 1.7:
			var dir := to_target.normalized()
			velocity.x = dir.x * move_speed * 0.72
			velocity.z = dir.z * move_speed * 0.72
			_face_direction(dir, delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
		ai_timer -= delta
		if ai_timer <= 0.0 and distance <= attack_range:
			ai_timer = randf_range(1.15, 1.75)
			if randf() < 0.72:
				var roll := randf()
				var chosen := "slash"
				if roll < 0.18:
					chosen = "thrust"
				elif roll < 0.34:
					chosen = "sweep"
				elif roll < 0.48:
					chosen = "heavy"
				elif roll < 0.57:
					chosen = "grab"
				start_attack(chosen)
	elif awareness_state == AwarenessState.SEARCHING:
		search_timer -= delta
		if _search_point_index < _search_points.size():
			var search_dir := _search_points[_search_point_index] - global_position
			search_dir.y = 0.0
			if search_dir.length() > 0.55:
				var direction := search_dir.normalized()
				velocity.x = direction.x * patrol_speed * 0.9
				velocity.z = direction.z * patrol_speed * 0.9
				_face_direction(direction, delta, 5.0)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
				_search_pause_timer -= delta
				_search_scan_time += delta
				var scan_angle := sin(_search_scan_time * 2.8) * 0.78
				rotation.y = lerp_angle(rotation.y, _search_origin_yaw + scan_angle, 1.0 - exp(-3.5 * delta))
				if _search_pause_timer <= 0.0:
					_search_point_index += 1
					_search_pause_timer = 0.85
					_search_origin_yaw = rotation.y
		else:
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
			_search_scan_time += delta
			var scan_angle := sin(_search_scan_time * 2.8) * 0.78
			rotation.y = lerp_angle(rotation.y, _search_origin_yaw + scan_angle, 1.0 - exp(-3.5 * delta))
		if search_timer <= 0.0 or _search_point_index >= _search_points.size():
			awareness_state = AwarenessState.IDLE
			suspicion = 0.0
			_search_scan_time = 0.0
			_search_points.clear()
	elif awareness_state == AwarenessState.IDLE:
		_patrol_update(delta)

func _patrol_update(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		return
	if patrol_wait_timer > 0.0:
		patrol_wait_timer = maxf(0.0, patrol_wait_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		return
	var waypoint := patrol_points[patrol_index % patrol_points.size()]
	var direction := waypoint - global_position
	direction.y = 0.0
	if direction.length() <= 0.45:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		patrol_wait_timer = _patrol_pause
		return
	direction = direction.normalized()
	velocity.x = direction.x * patrol_speed
	velocity.z = direction.z * patrol_speed
	_face_direction(direction, delta, 4.0)

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
	if not is_instance_valid(target) or target.is_dead:
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var crouched: bool = bool(target.get("is_crouching"))
	var in_cover: bool = bool(target.get("is_in_cover"))
	var effective_vision := vision_range * _get_target_vision_multiplier(target)
	var visible := distance <= effective_vision and _target_in_vision_cone(offset) and _has_clear_line_of_sight(target)
	var noise_multiplier := 0.42 if crouched else 1.0
	var noisy: bool = (bool(target.get("is_sprinting")) or (not crouched and Vector2(target.velocity.x, target.velocity.z).length() > 3.2)) and distance <= sprint_noise_range * noise_multiplier
	if _distraction_active and not visible:
		return
	if visible:
		_distraction_active = false
		last_known_target_position = target.global_position
		lost_sight_timer = 0.0
		if awareness_state == AwarenessState.IDLE or awareness_state == AwarenessState.SEARCHING:
			awareness_state = AwarenessState.SUSPICIOUS
		if awareness_state == AwarenessState.SUSPICIOUS:
			var suspicion_rate := 0.48 if crouched else (1.8 if distance < 4.0 else 1.0)
			if in_cover:
				suspicion_rate *= 0.32 if crouched else 0.72
			suspicion += delta * suspicion_rate
			if suspicion >= suspicion_threshold:
				awareness_state = AwarenessState.ALERTED
				ai_timer = 0.25
	elif noisy and awareness_state != AwarenessState.ALERTED:
		last_known_target_position = target.global_position
		awareness_state = AwarenessState.SUSPICIOUS
		suspicion = minf(suspicion_threshold, suspicion + delta * 1.5)
	else:
		if awareness_state == AwarenessState.SUSPICIOUS:
			suspicion = maxf(0.0, suspicion - delta * 0.45)
			if suspicion <= 0.0:
				awareness_state = AwarenessState.IDLE
		elif awareness_state == AwarenessState.ALERTED:
			lost_sight_timer += delta
			if lost_sight_timer >= 4.0:
				awareness_state = AwarenessState.SEARCHING
				search_timer = 12.0
				_search_origin_yaw = rotation.y
				_search_scan_time = 0.0
				_begin_cover_search()

func _begin_cover_search() -> void:
	_search_points.clear()
	_search_point_index = 0
	_search_pause_timer = 0.85
	_search_points.append(last_known_target_position)
	var candidates: Array[Vector3] = []
	for zone in get_tree().get_nodes_in_group("stealth_cover_zones"):
		if not is_instance_valid(zone):
			continue
		var point: Vector3 = zone.global_position
		var offset := point - last_known_target_position
		offset.y = 0.0
		if offset.length() <= 6.5:
			candidates.append(point)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return Vector2(a.x - last_known_target_position.x, a.z - last_known_target_position.z).length_squared() < Vector2(b.x - last_known_target_position.x, b.z - last_known_target_position.z).length_squared()
	)
	for point in candidates:
		_search_points.append(point)

func _get_target_vision_multiplier(candidate: Node3D) -> float:
	if not is_instance_valid(candidate):
		return 1.0
	var crouched: bool = bool(candidate.get("is_crouching"))
	var covered: bool = bool(candidate.get("is_in_cover"))
	if crouched and covered:
		return 0.16
	if covered:
		return 0.58
	if crouched:
		return 0.52
	return 1.0

func set_stealth_cover(_zone: Area3D, entering: bool) -> void:
	stealth_cover_count = maxi(0, stealth_cover_count + (1 if entering else -1))
	is_in_cover = stealth_cover_count > 0

func _on_cover_zone_body_entered(body: Node3D, zone: Area3D) -> void:
	if body == self:
		set_stealth_cover(zone, true)

func _on_cover_zone_body_exited(body: Node3D, zone: Area3D) -> void:
	if body == self:
		set_stealth_cover(zone, false)

func _target_in_vision_cone(offset: Vector3) -> bool:
	if offset.length_squared() < 0.001:
		return true
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return false
	var threshold := cos(deg_to_rad(vision_half_angle_degrees))
	return forward.normalized().dot(offset.normalized()) >= threshold

func _has_clear_line_of_sight(candidate: Node3D) -> bool:
	var world := get_world_3d()
	if world == null:
		return true
	var target_height := 0.55 if bool(candidate.get("is_crouching")) else 1.0
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.35, candidate.global_position + Vector3.UP * target_height)
	query.exclude = [get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == candidate

func emit_noise(noise_position: Vector3, radius: float) -> void:
	if is_player or is_dead or awareness_state == AwarenessState.ALERTED:
		return
	if global_position.distance_to(noise_position) <= radius:
		last_known_target_position = noise_position
		awareness_state = AwarenessState.SUSPICIOUS
		suspicion = minf(suspicion_threshold, suspicion + 0.55)


func use_prosthetic(tool: String) -> bool:
	if not is_player or is_dead or state != CombatState.FREE or is_blocking or prosthetic_cooldown > 0.0:
		return false
	var base_costs := {"shuriken": 18.0, "firecracker": 28.0, "axe": 32.0, "umbrella": 24.0}
	if not base_costs.has(tool):
		return false
	var level: int = int(prosthetic_upgrades[tool])
	var cost := maxf(8.0, float(base_costs[tool]) * (1.0 - 0.08 * float(level)))
	if prosthetic_energy < cost:
		return false
	var succeeded := false
	match tool:
		"shuriken":
			succeeded = _use_shuriken()
			if succeeded:
				prosthetic_cooldown = 0.38
		"firecracker":
			_use_firecracker()
			succeeded = true
			prosthetic_cooldown = 0.75
		"axe":
			succeeded = _use_axe()
			if succeeded:
				prosthetic_cooldown = 0.72
		"umbrella":
			umbrella_timer = 1.25 + 0.22 * float(prosthetic_upgrades["umbrella"])
			is_blocking = true
			succeeded = true
			prosthetic_cooldown = 0.45
	if succeeded:
		prosthetic_energy -= cost
		prosthetic_pose = tool
		prosthetic_pose_timer = 0.34
	return succeeded
	return false

func _use_shuriken() -> bool:
	if not is_instance_valid(target) or target.is_dead:
		return false
	var offset := target.global_position - global_position
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > 10.0 or flat.length() < 0.1:
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.normalized().dot(flat.normalized()) < 0.72:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.15, target.global_position + Vector3.UP * 1.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("collider") != target:
		return false
	var level: int = int(prosthetic_upgrades["shuriken"])
	target.receive_strike(12.0 + 3.0 * level, 20.0 + 4.0 * level, self, "thrust")
	var projectile := MeshInstance3D.new()
	projectile.name = "ProstheticShuriken"
	var blade := SphereMesh.new()
	blade.radius = 0.085
	blade.height = 0.17
	projectile.mesh = blade
	var blade_material := StandardMaterial3D.new()
	blade_material.albedo_color = Color(0.58, 0.68, 0.78)
	blade_material.metallic = 0.82
	blade_material.emission_enabled = true
	blade_material.emission = Color(0.18, 0.28, 0.42)
	projectile.material_override = blade_material
	var scene_root: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else get_tree().root
	scene_root.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 1.15 - global_transform.basis.z * 0.55
	var flight := get_tree().create_tween()
	flight.tween_property(projectile, "global_position", target.global_position + Vector3.UP * 1.0, 0.16)
	flight.tween_callback(projectile.queue_free)
	return true

func _use_firecracker() -> void:
	var burst_position := global_position - global_transform.basis.z * 3.0
	for listener in get_tree().get_nodes_in_group("stealth_guards"):
		if not is_instance_valid(listener):
			continue
		var firecracker_level: int = int(prosthetic_upgrades["firecracker"])
		if listener.global_position.distance_to(burst_position) > 10.0 + 1.5 * float(firecracker_level):
			continue
		if listener.has_method("receive_distraction"):
			listener.receive_distraction(burst_position)
		if listener.state == CombatState.FREE:
			listener.state = CombatState.HITSTUN
			listener.hit_reaction_kind = "heavy"
			listener.hit_reaction_duration = 0.62
			listener.hit_reaction_timer = 0.62
	# The brief emissive burst is a gameplay marker, not a finished VFX asset.
	var flash := MeshInstance3D.new()
	flash.name = "FirecrackerBurst"
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.24
	flash.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.72, 0.22, 0.65)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.46, 0.08)
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = material
	var scene_root: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else get_tree().root
	scene_root.add_child(flash)
	flash.global_position = burst_position + Vector3.UP * 0.9
	var timer := get_tree().create_timer(0.24)
	timer.timeout.connect(flash.queue_free)

func _use_axe() -> bool:
	if not is_instance_valid(target) or target.is_dead:
		return false
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > 3.0 or offset.length() < 0.1:
		return false
	if -global_transform.basis.z.dot(offset.normalized()) < 0.35:
		return false
	if target.has_method("receive_strike"):
		var axe_level: int = int(prosthetic_upgrades["axe"])
		target.receive_strike(18.0 + 5.0 * axe_level, 52.0 + 8.0 * axe_level, self, "heavy")
	return true

func begin_lightning_reversal() -> bool:
	if not is_player or is_dead or state != CombatState.FREE or velocity.y < 0.5 or lightning_reversal_timer > 0.0:
		return false
	lightning_reversal_timer = 0.85
	combat_feedback.emit("lightning_ready", self)
	return true

func receive_lightning_reversal(defender: Node3D) -> void:
	if is_dead or not is_instance_valid(defender):
		return
	_spawn_lightning_arc(defender, Color(0.24, 0.82, 1.0))
	posture += 82.0
	_check_posture_break()
	if state != CombatState.POSTURE_BROKEN:
		state = CombatState.HITSTUN
		hit_reaction_kind = "heavy"
		hit_reaction_duration = 0.72
		hit_reaction_timer = 0.72
	combat_feedback.emit("lightning_reversed", self)

func _spawn_lightning_arc(other: Node3D, tint: Color) -> void:
	if not is_instance_valid(other):
		return
	var start := global_position + Vector3.UP * 1.2
	var finish := other.global_position + Vector3.UP * 1.2
	var direction := finish - start
	var length := direction.length()
	if length < 0.1:
		return
	var beam := MeshInstance3D.new()
	beam.name = "LightningArc"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045
	mesh.bottom_radius = 0.075
	mesh.height = length
	beam.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 4.0
	beam.material_override = material
	var scene_root: Node = get_tree().current_scene if is_instance_valid(get_tree().current_scene) else get_tree().root
	scene_root.add_child(beam)
	beam.global_position = (start + finish) * 0.5
	var axis := Vector3.UP.cross(direction.normalized())
	if axis.length_squared() > 0.001:
		beam.global_basis = Basis(axis.normalized(), Vector3.UP.angle_to(direction.normalized()))
	var tween := get_tree().create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.16)
	tween.tween_callback(beam.queue_free)

func upgrade_next_prosthetic() -> bool:
	var tools := ["shuriken", "firecracker", "axe", "umbrella"]
	for offset in range(tools.size()):
		var index := (upgrade_selection_index + offset) % tools.size()
		var tool: String = tools[index]
		if upgrade_prosthetic(tool):
			upgrade_selection_index = (index + 1) % tools.size()
			return true
	return false

func upgrade_prosthetic(tool: String) -> bool:
	if not is_player or is_dead or state != CombatState.FREE or prosthetic_upgrade_points <= 0 or not prosthetic_upgrades.has(tool):
		return false
	if int(prosthetic_upgrades[tool]) >= 3:
		return false
	prosthetic_upgrades[tool] = int(prosthetic_upgrades[tool]) + 1
	prosthetic_upgrade_points -= 1
	return true

func receive_distraction(noise_position: Vector3) -> void:
	if is_player or is_dead:
		return
	if awareness_state == AwarenessState.ALERTED and is_instance_valid(target) and _has_clear_line_of_sight(target):
		return
	_distraction_active = true
	_distraction_timer = 7.0
	last_known_target_position = noise_position
	awareness_state = AwarenessState.SEARCHING
	suspicion = maxf(suspicion, 0.55)
	search_timer = 7.0
	_search_points = [noise_position]
	_search_point_index = 0
	_search_pause_timer = 0.0
	_search_scan_time = 0.0

func _face_direction(dir: Vector3, delta: float, turn_speed: float = 12.0) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))

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
	if is_dead:
		return "ignored"
	if resurrection_invulnerability > 0.0:
		return "immune"
	if is_dodging:
		combat_feedback.emit("evaded", self)
		return "evaded"
	if incoming_kind == "lightning" and is_player and lightning_reversal_timer > 0.0 and velocity.y > 0.35:
		lightning_reversal_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_lightning_reversal"):
			attacker.receive_lightning_reversal(self)
		combat_feedback.emit("lightning_reversed", self)
		return "lightning_reversed"
	if incoming_kind == "thrust" and is_mikiri_countering:
		is_mikiri_countering = false
		counter_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(48.0)
		combat_feedback.emit("mikiri", self)
		return "mikiri"
	if incoming_kind == "sweep" and is_sweep_evading:
		is_sweep_evading = false
		counter_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(32.0)
		combat_feedback.emit("sweep_evaded", self)
		return "sweep_evaded"
	if is_deflecting and incoming_kind != "grab":
		_parry_pose_timer = 0.22
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(40.0 if incoming_kind == "heavy" else 26.0)
		combat_feedback.emit("deflect", self)
		return "deflected"
	if is_blocking and incoming_kind != "grab":
		var block_scale := 0.85 if incoming_kind == "heavy" else (0.72 if incoming_kind == "thrust" else 0.55)
		posture += posture_damage * block_scale
		_check_posture_break()
		combat_feedback.emit("guard", self)
		return "blocked"
	vitality = maxf(0.0, vitality - damage)
	posture += posture_damage
	_check_posture_break()
	if vitality <= 0.0:
		_die()
	else:
		_begin_hit_reaction(attacker, incoming_kind)
		if incoming_kind == "grab":
			hit_reaction_timer = 0.62
			combat_feedback.emit("grabbed", self)
		else:
			combat_feedback.emit("hit", self)
	return "grabbed" if incoming_kind == "grab" else "hit"

func receive_deflect(amount: float) -> void:
	if is_dead:
		return
	_deflect_recoil_timer = 0.20
	posture += amount
	_check_posture_break()

func _check_posture_break() -> void:
	posture = clampf(posture, 0.0, max_posture)
	if posture >= max_posture and state != CombatState.POSTURE_BROKEN:
		state = CombatState.POSTURE_BROKEN
		_posture_break_age = 0.0
		attack_phase_changed.emit("interrupted")
		posture_break_timer = POSTURE_BREAK_TIME
		posture_stomped = false
		hit_reaction_timer = 0.0
		is_blocking = false
		deflect_timer = 0.0
		is_deflecting = false
		posture_broken.emit()
		combat_feedback.emit("posture_break", self)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if is_player:
		resurrection_available = resurrection_charges > 0
	state = CombatState.DEAD
	attack_phase_changed.emit("finished")
	is_blocking = false
	velocity = Vector3.ZERO
	combat_feedback.emit("death", self)
	died.emit()

func set_swim_vertical_input(value: float) -> void:
	swim_vertical_input = clampf(value, -1.0, 1.0) if is_swimming else 0.0

func enter_water(surface_y: float) -> void:
	if not is_player or is_dead:
		return
	is_swimming = true
	swim_vertical_input = 0.0
	_water_surface_y = surface_y
	is_crouching = false
	is_sprinting = false
	sprint_requested = false
	if is_instance_valid(body_collision) and body_collision.shape is CapsuleShape3D:
		body_collision.shape.height = 1.25
		body_collision.position.y = 0.68

func exit_water() -> void:
	if not is_swimming:
		return
	is_swimming = false
	swim_vertical_input = 0.0
	velocity.y = maxf(velocity.y, 1.0)
	if is_instance_valid(body_collision) and body_collision.shape is CapsuleShape3D:
		body_collision.shape.height = 1.8
		body_collision.position.y = 0.9

func try_vertical_climb() -> bool:
	if is_climbing:
		stop_vertical_climb()
		return true
	if not is_player or is_dead or state != CombatState.FREE or is_swimming or is_grappling or is_vaulting or is_wall_hugging:
		return false
	var forward := -global_transform.basis.z.normalized()
	var origin := global_position + Vector3.UP * 0.95
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 0.9)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or absf((hit.normal as Vector3).y) > 0.25:
		return false
	var climb_collider: Object = hit.get("collider")
	if not is_instance_valid(climb_collider) or not climb_collider.is_in_group("climbable_surfaces"):
		return false
	_climb_normal = (hit.normal as Vector3).normalized()
	is_climbing = true
	is_crouching = false
	is_sprinting = false
	velocity = Vector3.ZERO
	return true

func stop_vertical_climb() -> void:
	if not is_climbing:
		return
	is_climbing = false
	_climb_normal = Vector3.ZERO
	velocity = Vector3(0.0, -1.2, 0.0)

func _update_vertical_climb(delta: float) -> void:
	if _climb_normal.length_squared() < 0.5:
		stop_vertical_climb()
		return
	var origin := global_position + Vector3.UP * 0.95
	var query := PhysicsRayQueryParameters3D.create(origin, origin - _climb_normal * 1.05)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		stop_vertical_climb()
		return
	var vertical := -input_move.y
	velocity = Vector3.UP * vertical * climb_speed - _climb_normal * 0.35
	move_and_slide()
	if vertical > 0.0:
		var top_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.9 + _climb_normal * 0.2, global_position + Vector3.UP * 1.9 - _climb_normal * 0.85)
		top_query.exclude = [get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(top_query).is_empty():
			stop_vertical_climb()

func try_ledge_grab() -> bool:
	if not is_player or is_dead or is_on_floor() or is_swimming or is_grappling or is_climbing or is_ledge_hanging or state != CombatState.FREE:
		return false
	if velocity.y > 1.5 or velocity.y < -8.5:
		return false
	var forward := -global_transform.basis.z.normalized()
	var chest := global_position + Vector3.UP * 1.35
	var wall_query := PhysicsRayQueryParameters3D.create(chest, chest + forward * 0.9)
	wall_query.exclude = [get_rid()]
	var wall_hit := get_world_3d().direct_space_state.intersect_ray(wall_query)
	if wall_hit.is_empty() or absf((wall_hit.normal as Vector3).y) > 0.25:
		return false
	var top_origin := (wall_hit.position as Vector3) + Vector3.UP * 2.0 + forward * 0.08
	var top_query := PhysicsRayQueryParameters3D.create(top_origin, top_origin + Vector3.DOWN * 2.5)
	top_query.exclude = [get_rid()]
	var top_hit := get_world_3d().direct_space_state.intersect_ray(top_query)
	if top_hit.is_empty():
		return false
	var top_y: float = (top_hit.position as Vector3).y
	if top_y < global_position.y + 0.55 or top_y > global_position.y + 2.4:
		return false
	_ledge_hang_position = (wall_hit.position as Vector3) + (wall_hit.normal as Vector3) * 0.48 + Vector3.UP * (top_y - global_position.y - 1.15)
	_ledge_hang_position.y = top_y - 1.05
	_climb_normal = (wall_hit.normal as Vector3).normalized()
	global_position = _ledge_hang_position
	velocity = Vector3.ZERO
	is_ledge_hanging = true
	return true

func _update_ledge_hang(_delta: float) -> void:
	velocity = Vector3.ZERO
	if input_move.y < -0.45:
		var landing := _ledge_hang_position + _climb_normal * 0.9 + Vector3.UP * 1.05
		var query := PhysicsRayQueryParameters3D.create(landing + Vector3.UP * 2.0, landing + Vector3.DOWN * 3.0)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var floor_y: float = (hit.position as Vector3).y
			_vault_start = global_position
			_vault_end = Vector3(landing.x, floor_y, landing.z)
			_vault_elapsed = 0.0
			_vault_duration = 0.48
			_vault_height = 0.42
			_traversal_kind = "ledge_mantle"
			is_ledge_hanging = false
			is_vaulting = true
			return
	if input_move.y > 0.65:
		is_ledge_hanging = false
		velocity = Vector3(0.0, -1.8, 0.0)

func set_checkpoint(position: Vector3) -> void:
	checkpoint_position = position

func resurrect() -> bool:
	if not is_player or not is_dead or not resurrection_available or resurrection_charges <= 0:
		return false
	resurrection_charges -= 1
	resurrection_available = false
	is_dead = false
	state = CombatState.FREE
	vitality = max_vitality * 0.55
	posture = 0.0
	velocity = Vector3.ZERO
	global_position = checkpoint_position
	is_blocking = false
	is_deflecting = false
	is_dodging = false
	is_crouching = false
	is_wall_hugging = false
	is_cover_transferring = false
	is_grappling = false
	is_swimming = false
	swim_vertical_input = 0.0
	is_climbing = false
	is_ledge_hanging = false
	attack_timer = 0.0
	attack_buffer_timer = 0.0
	buffered_attack_kind = ""
	resurrection_invulnerability = 1.35
	combat_feedback.emit("resurrection", self)
	return true

func begin_jump() -> bool:
	if not is_player or is_dead or state != CombatState.FREE or not is_on_floor() or is_grappling or is_vaulting:
		return false
	velocity.y = 7.2
	is_crouching = false
	return true

func try_grapple() -> bool:
	if not is_player or is_dead or state != CombatState.FREE or is_grappling or is_vaulting or is_wall_hugging or is_cover_transferring:
		return false
	var best: Node3D = null
	var best_distance := 12.5
	var forward := -global_transform.basis.z.normalized()
	for candidate in get_tree().get_nodes_in_group("grapple_points"):
		if not candidate is Node3D or not is_instance_valid(candidate):
			continue
		var offset: Vector3 = candidate.global_position - global_position
		var distance := offset.length()
		if distance < 2.0 or distance > best_distance:
			continue
		var direction := offset.normalized()
		if forward.dot(direction) < 0.48:
			continue
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.1, candidate.global_position)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider != candidate:
			continue
		best = candidate
		best_distance = distance
	if not is_instance_valid(best):
		return false
	grapple_target = best
	_grapple_start = global_position
	_grapple_end = best.global_position + Vector3(0.0, -0.8, 0.0)
	_grapple_elapsed = 0.0
	_grapple_duration = clampf(best_distance / 18.0, 0.32, 0.62)
	_grapple_height = clampf(best_distance * 0.16, 0.8, 1.8)
	is_grappling = true
	_grapple_attack_ready = true
	velocity = Vector3.ZERO
	return true

func _update_grapple(delta: float) -> void:
	if not is_instance_valid(grapple_target):
		is_grappling = false
		return
	_grapple_elapsed += delta
	var t := clampf(_grapple_elapsed / _grapple_duration, 0.0, 1.0)
	var desired := _grapple_start.lerp(_grapple_end, t) + Vector3.UP * (sin(t * PI) * _grapple_height)
	var travel := desired - global_position
	velocity = travel / maxf(delta, 0.001)
	move_and_slide()
	if get_slide_collision_count() > 0 and t < 0.92:
		is_grappling = false
		grapple_target = null
		velocity = Vector3.ZERO
		return
	if t >= 1.0:
		is_grappling = false
		grapple_target = null
		velocity = Vector3.ZERO
		_grapple_attack_ready = true

func aerial_grapple_attack() -> bool:
	if not is_player or is_dead or state != CombatState.FREE or is_grappling or not _grapple_attack_ready or not is_instance_valid(target) or target.is_dead:
		return false
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > 3.1 or offset.length() < 0.1:
		return false
	if (-global_transform.basis.z).dot(offset.normalized()) < 0.0:
		return false
	_grapple_attack_ready = false
	start_attack("heavy")
	return true

func begin_mikiri_counter() -> bool:
	if is_dead or state != CombatState.FREE:
		return false
	is_mikiri_countering = true
	is_sweep_evading = false
	counter_timer = 0.28
	return true

func begin_sweep_evade() -> bool:
	if is_dead or state != CombatState.FREE:
		return false
	is_sweep_evading = true
	is_mikiri_countering = false
	counter_timer = 0.60
	velocity.y = 5.8
	return true

func begin_deflect() -> bool:
	if is_dead or state != CombatState.FREE or deflect_cooldown > 0.0:
		return false
	is_blocking = true
	is_deflecting = true
	deflect_timer = deflect_window
	deflect_cooldown = deflect_lockout
	return true

func end_deflect() -> void:
	is_blocking = false
	is_deflecting = false
	deflect_timer = 0.0

func begin_block() -> void:
	if not is_dead and state == CombatState.FREE:
		is_blocking = true

func end_block() -> void:
	is_blocking = false

func dodge() -> void:
	if is_dead or state != CombatState.FREE or is_dodging or dodge_cooldown > 0.0:
		return
	dodge_timer = 0.38
	dodge_cooldown = 0.52
	is_dodging = true
	var dir := _get_player_move_direction()
	if dir.length_squared() < 0.01:
		if is_instance_valid(target) and not target.is_dead:
			dir = global_position - target.global_position
			dir.y = 0.0
		else:
			dir = -global_transform.basis.z
	if dir.length_squared() < 0.001:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	velocity.x = dir.x * dodge_speed
	velocity.z = dir.z * dodge_speed
	if is_instance_valid(target) and not target.is_dead:
		var face_target := target.global_position - global_position
		face_target.y = 0.0
		_face_direction(face_target, 0.12, 18.0)
	else:
		_face_direction(dir, 0.12, 18.0)

func request_player_attack() -> bool:
	if is_dead or not is_player:
		return false
	if combo_reset_timer <= 0.0 and state == CombatState.FREE:
		combo_step = 0
	var chain := ["slash", "slash", "heavy"]
	var requested_kind: String = chain[mini(combo_step, chain.size() - 1)]
	combo_step = (combo_step + 1) % chain.size()
	combo_reset_timer = COMBO_RESET_TIME
	if state == CombatState.FREE and not is_blocking:
		return start_attack(requested_kind)
	if state in [CombatState.WINDUP, CombatState.ACTIVE, CombatState.RECOVERY]:
		buffered_attack_kind = requested_kind
		attack_buffer_timer = ATTACK_BUFFER_WINDOW
		return true
	return false

func player_attack() -> void:
	request_player_attack()

func stomp_broken_target() -> bool:
	if is_dead or state != CombatState.FREE or not is_instance_valid(target):
		return false
	if target.state != CombatState.POSTURE_BROKEN or target.is_dead or target.posture_stomped:
		return false
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > 2.35:
		return false
	if offset.length_squared() > 0.001 and (-global_transform.basis.z).normalized().dot(offset.normalized()) < 0.0:
		return false
	return target.receive_stomp(self)

func stealth_deathblow_target() -> bool:
	if is_dead or state != CombatState.FREE or not is_instance_valid(target):
		return false
	if target.is_dead or target.state != CombatState.FREE or target.awareness_state == AwarenessState.ALERTED or target.stealth_deathblow_started:
		return false
	var offset := global_position - target.global_position
	offset.y = 0.0
	if offset.length() > 2.25 or offset.length_squared() < 0.001:
		return false
	var target_forward := -target.global_transform.basis.z
	if target_forward.dot(offset.normalized()) > -0.35:
		return false
	return target.receive_stealth_deathblow(self)

func receive_stealth_deathblow(attacker: Node3D) -> bool:
	if is_dead or state != CombatState.FREE or awareness_state == AwarenessState.ALERTED or stealth_deathblow_started or not is_instance_valid(attacker):
		return false
	stealth_deathblow_started = true
	deathblow_executed = true
	state = CombatState.EXECUTING
	execution_timer = 0.82
	execution_partner = attacker
	velocity = Vector3.ZERO
	if attacker is CharacterBody3D:
		attacker.state = CombatState.EXECUTING
		attacker.execution_timer = 0.82
		attacker.execution_partner = self
		attacker.deathblow_executed = false
	combat_feedback.emit("deathblow", self)
	return true

func deathblow_broken_target() -> bool:
	if is_dead or state != CombatState.FREE or not is_instance_valid(target):
		return false
	if target.is_dead or target.state != CombatState.POSTURE_BROKEN or target.deathblow_executed:
		return false
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > 2.35 or offset.length_squared() < 0.001:
		return false
	if (-global_transform.basis.z).normalized().dot(offset.normalized()) < 0.35:
		return false
	return target.receive_deathblow(self)

func receive_deathblow(attacker: Node3D) -> bool:
	if is_dead or state != CombatState.POSTURE_BROKEN or deathblow_executed or not is_instance_valid(attacker):
		return false
	var offset := attacker.global_position - global_position
	offset.y = 0.0
	if offset.length() > 2.8 or offset.length_squared() < 0.001:
		return false
	deathblow_executed = true
	state = CombatState.EXECUTING
	execution_timer = 0.82
	execution_partner = attacker
	velocity = Vector3.ZERO
	if attacker is CharacterBody3D:
		attacker.state = CombatState.EXECUTING
		attacker.execution_timer = 0.82
		attacker.execution_partner = self
		attacker.velocity = Vector3.ZERO
	combat_feedback.emit("deathblow", self)
	return true

func receive_stomp(attacker: Node3D) -> bool:
	if is_dead or state != CombatState.POSTURE_BROKEN or posture_stomped:
		return false
	posture_stomped = true
	vitality = maxf(0.0, vitality - 18.0)
	combat_feedback.emit("stomp", self)
	if vitality <= 0.0:
		_die()
	return true

func get_vitality_ratio() -> float:
	return vitality / maxf(1.0, max_vitality)

func get_posture_ratio() -> float:
	return posture / maxf(1.0, max_posture)
