extends CharacterBody3D
signal telegraph_started(kind: String)
signal attack_hit(target: Node)
signal posture_broken
signal died

enum CombatState { FREE, WINDUP, ACTIVE, RECOVERY, POSTURE_BROKEN, DEAD }

@export var is_player := false
@export var display_name := "Fighter"
@export var move_speed := 5.2
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
var ai_timer := 0.8
var gravity := 22.0
var attack_kind := "slash"
var _attack_hit_applied := false
var _attack_token := 0

const WINDUP_TIME := 0.32
const ACTIVE_TIME := 0.10
const RECOVERY_TIME := 0.34
const POSTURE_BREAK_TIME := 1.35

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		return
	deflect_timer = maxf(0.0, deflect_timer - delta)
	deflect_cooldown = maxf(0.0, deflect_cooldown - delta)
	dodge_timer = maxf(0.0, dodge_timer - delta)
	is_deflecting = deflect_timer > 0.0
	is_dodging = dodge_timer > 0.0
	if state == CombatState.POSTURE_BROKEN:
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
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _update_attack_state(delta: float) -> void:
	attack_timer -= delta
	if state == CombatState.WINDUP and attack_timer <= 0.0:
		state = CombatState.ACTIVE
		attack_timer = ACTIVE_TIME
		_resolve_attack_hit()
	elif state == CombatState.ACTIVE and attack_timer <= 0.0:
		state = CombatState.RECOVERY
		attack_timer = RECOVERY_TIME
	elif state == CombatState.RECOVERY and attack_timer <= 0.0:
		state = CombatState.FREE

func _player_update(delta: float) -> void:
	if state != CombatState.FREE:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		return
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var move_dir := right * input_move.x + forward * -input_move.y
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	if move_dir.length() > 0.08:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		_face_direction(move_dir, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)

func _ai_update(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead or state != CombatState.FREE:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
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
			start_attack("slash")

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-12.0 * delta))

func start_attack(kind: String = "slash") -> bool:
	if is_dead or state != CombatState.FREE or is_blocking:
		return false
	_attack_token += 1
	_attack_hit_applied = false
	attack_kind = kind
	state = CombatState.WINDUP
	attack_timer = WINDUP_TIME
	telegraph_started.emit(kind)
	return true

func _resolve_attack_hit() -> void:
	if _attack_hit_applied or not is_instance_valid(target) or target.is_dead:
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > attack_range:
		return
	var facing := -global_transform.basis.z
	if offset.length_squared() > 0.001 and facing.normalized().dot(offset.normalized()) < 0.15:
		return
	_attack_hit_applied = true
	target.receive_strike(attack_damage, attack_posture_damage, self)
	attack_hit.emit(target)

func receive_strike(damage: float, posture_damage: float, attacker: Node3D) -> String:
	if is_dead or is_dodging:
		return "evaded"
	if is_deflecting:
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(26.0)
		return "deflected"
	if is_blocking:
		posture += posture_damage * 0.55
		_check_posture_break()
		return "blocked"
	vitality = maxf(0.0, vitality - damage)
	posture += posture_damage
	_check_posture_break()
	if vitality <= 0.0:
		_die()
	return "hit"

func receive_deflect(amount: float) -> void:
	if is_dead:
		return
	posture += amount
	_check_posture_break()

func _check_posture_break() -> void:
	posture = clampf(posture, 0.0, max_posture)
	if posture >= max_posture and state != CombatState.POSTURE_BROKEN:
		state = CombatState.POSTURE_BROKEN
		posture_break_timer = POSTURE_BREAK_TIME
		is_blocking = false
		deflect_timer = 0.0
		is_deflecting = false
		posture_broken.emit()

func _die() -> void:
	is_dead = true
	state = CombatState.DEAD
	is_blocking = false
	velocity = Vector3.ZERO
	died.emit()

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
	if is_dead or state != CombatState.FREE or is_dodging:
		return
	dodge_timer = 0.38
	var dir := global_transform.basis.x * input_move.x + (-global_transform.basis.z) * -input_move.y
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	velocity.x = dir.x * 10.0
	velocity.z = dir.z * 10.0

func player_attack() -> void:
	start_attack("slash")

func get_vitality_ratio() -> float:
	return vitality / maxf(1.0, max_vitality)

func get_posture_ratio() -> float:
	return posture / maxf(1.0, max_posture)
