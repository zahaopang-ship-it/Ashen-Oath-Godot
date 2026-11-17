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

const WINDUP_TIME := 0.32
const ACTIVE_TIME := 0.10
const RECOVERY_TIME := 0.34
const POSTURE_BREAK_TIME := 1.35
const HIT_FLASH_COLOR := Color(1.0, 0.72, 0.58)
const ATTACK_KINDS := ["slash", "thrust", "sweep", "heavy", "grab", "ashen_rend"]
const ATTACK_DAMAGE := {"slash": 22.0, "thrust": 27.0, "sweep": 18.0, "heavy": 34.0, "grab": 30.0, "ashen_rend": 46.0}
const ATTACK_POSTURE := {"slash": 30.0, "thrust": 36.0, "sweep": 24.0, "heavy": 46.0, "grab": 12.0, "ashen_rend": 58.0}
const ATTACK_WINDUP := {"slash": 0.32, "thrust": 0.48, "sweep": 0.42, "heavy": 0.62, "grab": 0.72, "ashen_rend": 0.92}
const ATTACK_HITBOX := {
	"slash": Vector3(0.95, 1.25, 1.65),
	"thrust": Vector3(0.52, 1.10, 2.10),
	"sweep": Vector3(1.45, 0.62, 1.55),
	"heavy": Vector3(1.00, 1.40, 1.90),
	"grab": Vector3(0.85, 1.15, 1.45),
	"ashen_rend": Vector3(1.65, 1.45, 2.35)
}
const ATTACK_BUFFER_WINDOW := 0.58
const COMBO_RESET_TIME := 0.95

func _physics_process(delta: float) -> void:
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
	var parry_blend := clampf(_parry_pose_timer / 0.22, 0.0, 1.0)
	var recoil_blend := clampf(_deflect_recoil_timer / 0.20, 0.0, 1.0)
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
	if state != CombatState.FREE:
		velocity.x = move_toward(velocity.x, 0.0, movement_braking * delta)
		velocity.z = move_toward(velocity.z, 0.0, movement_braking * delta)
		return
	var move_dir := _get_player_move_direction()
	is_sprinting = sprint_requested or input_move.length() >= 0.82
	var current_speed := move_speed * (1.42 if is_sprinting else 1.0)
	var desired_velocity := move_dir * current_speed
	var accel := movement_acceleration if move_dir.length_squared() > 0.001 else movement_braking
	velocity.x = move_toward(velocity.x, desired_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, accel * delta)
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
	if not is_instance_valid(target) or target.is_dead or state != CombatState.FREE:
		return
	_update_awareness(delta)
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
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		var search_dir := last_known_target_position - global_position
		search_dir.y = 0.0
		if search_dir.length() > 0.65:
			_face_direction(search_dir.normalized(), delta, 5.0)
		else:
			search_timer -= delta
			if search_timer <= 0.0:
				awareness_state = AwarenessState.IDLE
				suspicion = 0.0
	elif awareness_state == AwarenessState.IDLE:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)

func _update_awareness(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead:
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var visible := distance <= vision_range and _target_in_vision_cone(offset) and _has_clear_line_of_sight(target)
	var noisy: bool = bool(target.get("is_sprinting")) and distance <= sprint_noise_range
	if visible:
		last_known_target_position = target.global_position
		lost_sight_timer = 0.0
		if awareness_state == AwarenessState.IDLE or awareness_state == AwarenessState.SEARCHING:
			awareness_state = AwarenessState.SUSPICIOUS
		if awareness_state == AwarenessState.SUSPICIOUS:
			suspicion += delta * (1.8 if distance < 4.0 else 1.0)
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
				search_timer = 2.6
		elif awareness_state == AwarenessState.SEARCHING:
			search_timer -= delta
			if search_timer <= 0.0:
				awareness_state = AwarenessState.IDLE
				suspicion = 0.0

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
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.35, candidate.global_position + Vector3.UP * 1.0)
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


func _face_direction(dir: Vector3, delta: float, turn_speed: float = 12.0) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))

func start_attack(kind: String = "slash") -> bool:
	if is_dead or state != CombatState.FREE or is_blocking or not ATTACK_KINDS.has(kind):
		return false
	if is_player and is_instance_valid(target) and target.has_method("emit_noise"):
		target.emit_noise(global_position, 9.5)
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
	if is_dead or is_dodging:
		if is_dodging:
			combat_feedback.emit("evaded", self)
		return "evaded"
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
	is_dead = true
	state = CombatState.DEAD
	attack_phase_changed.emit("finished")
	is_blocking = false
	velocity = Vector3.ZERO
	combat_feedback.emit("death", self)
	died.emit()

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
