extends CharacterBody3D
@export var is_player := false
@export var display_name := "Fighter"
@export var move_speed := 5.2
@export var max_vitality := 100.0
@export var vitality := 100.0
@export var max_posture := 100.0
@export var posture := 0.0
@export var deflect_window := 0.20
@export var attack_range := 2.15
@export var attack_cooldown := 0.72
var target: CharacterBody3D
var input_move := Vector2.ZERO
var is_blocking := false
var is_deflecting := false
var is_attacking := false
var is_dodging := false
var is_dead := false
var attack_timer := 0.0
var deflect_timer := 0.0
var dodge_timer := 0.0
var ai_timer := 0.0
var posture_recovery := 8.0
var gravity := 22.0

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	deflect_timer = maxf(0.0, deflect_timer - delta)
	dodge_timer = maxf(0.0, dodge_timer - delta)
	is_deflecting = deflect_timer > 0.0
	is_dodging = dodge_timer > 0.0
	if not is_player:
		_ai_update(delta)
	else:
		_player_update(delta)
	if not is_blocking and not is_deflecting and not is_attacking:
		posture = maxf(0.0, posture - posture_recovery * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _player_update(delta: float) -> void:
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var move_dir := right * input_move.x + forward * -input_move.y
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	if move_dir.length() > 0.08 and not is_attacking:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		_face_direction(move_dir, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)

func _ai_update(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var to_target := target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()
	if distance > 1.65:
		var dir := to_target.normalized()
		velocity.x = dir.x * move_speed * 0.72
		velocity.z = dir.z * move_speed * 0.72
		_face_direction(dir, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
	ai_timer -= delta
	if ai_timer <= 0.0 and distance <= attack_range:
		ai_timer = randf_range(1.1, 1.8)
		if randf() < 0.72:
			_attack()

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-12.0 * delta))

func _attack() -> void:
	if attack_timer > 0.0 or is_dead:
		return
	attack_timer = attack_cooldown
	is_attacking = true
	await get_tree().create_timer(0.24).timeout
	if not is_inside_tree() or is_dead:
		return
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		target.receive_strike(22.0, 30.0, self)
	await get_tree().create_timer(0.18).timeout
	is_attacking = false

func receive_strike(damage: float, posture_damage: float, attacker: Node3D) -> void:
	if is_dead or is_dodging:
		return
	if is_deflecting:
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(24.0)
		return
	if is_blocking:
		posture = minf(max_posture, posture + posture_damage * 0.42)
		return
	vitality = maxf(0.0, vitality - damage)
	posture = minf(max_posture, posture + posture_damage)
	if vitality <= 0.0:
		is_dead = true
		velocity = Vector3.ZERO

func receive_deflect(amount: float) -> void:
	posture = minf(max_posture, posture + amount)
	if posture >= max_posture:
		posture = 0.0
		vitality = maxf(0.0, vitality - 35.0)
		if vitality <= 0.0:
			is_dead = true

func begin_deflect() -> void:
	is_blocking = true
	deflect_timer = deflect_window

func end_deflect() -> void:
	is_blocking = false

func begin_block() -> void:
	is_blocking = true
	deflect_timer = 0.0

func end_block() -> void:
	is_blocking = false

func dodge() -> void:
	if is_dead or is_dodging:
		return
	dodge_timer = 0.38
	var dir := Vector3(input_move.x, 0, -input_move.y)
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	velocity.x = dir.normalized().x * 10.0
	velocity.z = dir.normalized().z * 10.0

func player_attack() -> void:
	_attack()

func get_vitality_ratio() -> float:
	return vitality / maxf(1.0, max_vitality)

func get_posture_ratio() -> float:
	return posture / maxf(1.0, max_posture)
