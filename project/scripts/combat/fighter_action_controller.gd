extends RefCounted

## Owns defensive combat actions, counters, and dodge direction.
const STATE_FREE := 0

static func begin_mikiri_counter(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE:
		return false
	actor.is_mikiri_countering = true
	actor.is_sweep_evading = false
	actor.counter_timer = 0.28
	return true

static func begin_sweep_evade(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE:
		return false
	actor.is_sweep_evading = true
	actor.is_mikiri_countering = false
	actor.counter_timer = 0.60
	actor.velocity.y = 5.8
	return true

static func begin_deflect(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or actor.deflect_cooldown > 0.0:
		return false
	actor.is_blocking = true
	actor.is_deflecting = true
	actor.deflect_timer = actor.deflect_window
	actor.deflect_cooldown = actor.deflect_lockout
	return true

static func end_deflect(actor: CharacterBody3D) -> void:
	actor.is_blocking = false
	actor.is_deflecting = false
	actor.deflect_timer = 0.0

static func begin_block(actor: CharacterBody3D) -> void:
	if not actor.is_dead and actor.state == STATE_FREE:
		actor.is_blocking = true

static func end_block(actor: CharacterBody3D) -> void:
	actor.is_blocking = false

static func dodge(actor: CharacterBody3D) -> void:
	if actor.is_dead or actor.state != STATE_FREE or actor.is_dodging or actor.dodge_cooldown > 0.0:
		return
	actor.dodge_timer = 0.38
	actor.dodge_cooldown = 0.52
	actor.is_dodging = true
	var direction: Vector3 = actor._get_player_move_direction()
	if direction.length_squared() < 0.01:
		if is_instance_valid(actor.target) and not actor.target.is_dead:
			direction = actor.global_position - actor.target.global_position
			direction.y = 0.0
		else:
			direction = -actor.global_transform.basis.z
	if direction.length_squared() < 0.001:
		direction = -actor.global_transform.basis.z
	direction = direction.normalized()
	actor.velocity.x = direction.x * actor.dodge_speed
	actor.velocity.z = direction.z * actor.dodge_speed
	if is_instance_valid(actor.target) and not actor.target.is_dead:
		var face_target: Vector3 = actor.target.global_position - actor.global_position
		face_target.y = 0.0
		actor._face_direction(face_target, 0.12, 18.0)
	else:
		actor._face_direction(direction, 0.12, 18.0)

## Synchronized posture-break and stealth executions.
const STATE_POSTURE_BROKEN := 4
const STATE_EXECUTING := 7
const AWARENESS_ALERTED := 3

static func stomp_broken_target(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or not is_instance_valid(actor.target):
		return false
	if actor.target.state != STATE_POSTURE_BROKEN or actor.target.is_dead or actor.target.posture_stomped:
		return false
	var offset: Vector3 = actor.target.global_position - actor.global_position
	offset.y = 0.0
	if offset.length() > 2.35:
		return false
	if offset.length_squared() > 0.001 and (-actor.global_transform.basis.z).normalized().dot(offset.normalized()) < 0.0:
		return false
	return actor.target.receive_stomp(actor)

static func stealth_deathblow_target(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or not is_instance_valid(actor.target):
		return false
	if actor.target.is_dead or actor.target.state != STATE_FREE or actor.target.awareness_state == AWARENESS_ALERTED or actor.target.stealth_deathblow_started:
		return false
	var offset: Vector3 = actor.global_position - actor.target.global_position
	offset.y = 0.0
	if offset.length() > 2.25 or offset.length_squared() < 0.001:
		return false
	var target_forward: Vector3 = -actor.target.global_transform.basis.z
	if target_forward.dot(offset.normalized()) > -0.35:
		return false
	return actor.target.receive_stealth_deathblow(actor)

static func receive_stealth_deathblow(actor: CharacterBody3D, attacker: Node3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or actor.awareness_state == AWARENESS_ALERTED or actor.stealth_deathblow_started or not is_instance_valid(attacker):
		return false
	actor.stealth_deathblow_started = true
	actor.deathblow_executed = true
	actor.state = STATE_EXECUTING
	actor.execution_timer = 0.82
	actor.execution_partner = attacker
	actor.velocity = Vector3.ZERO
	if attacker is CharacterBody3D:
		attacker.state = STATE_EXECUTING
		attacker.execution_timer = 0.82
		attacker.execution_partner = actor
		attacker.deathblow_executed = false
	actor.combat_feedback.emit("deathblow", actor)
	return true

static func deathblow_broken_target(actor: CharacterBody3D) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or not is_instance_valid(actor.target):
		return false
	if actor.target.is_dead or actor.target.state != STATE_POSTURE_BROKEN or actor.target.deathblow_executed:
		return false
	var offset: Vector3 = actor.target.global_position - actor.global_position
	offset.y = 0.0
	if offset.length() > 2.35 or offset.length_squared() < 0.001:
		return false
	if (-actor.global_transform.basis.z).normalized().dot(offset.normalized()) < 0.35:
		return false
	return actor.target.receive_deathblow(actor)

static func receive_deathblow(actor: CharacterBody3D, attacker: Node3D) -> bool:
	if actor.is_dead or actor.state != STATE_POSTURE_BROKEN or actor.deathblow_executed or not is_instance_valid(attacker):
		return false
	var offset: Vector3 = attacker.global_position - actor.global_position
	offset.y = 0.0
	if offset.length() > 2.8 or offset.length_squared() < 0.001:
		return false
	actor.deathblow_executed = true
	actor.state = STATE_EXECUTING
	actor.execution_timer = 0.82
	actor.execution_partner = attacker
	actor.velocity = Vector3.ZERO
	if attacker is CharacterBody3D:
		attacker.state = STATE_EXECUTING
		attacker.execution_timer = 0.82
		attacker.execution_partner = actor
		attacker.velocity = Vector3.ZERO
	actor.combat_feedback.emit("deathblow", actor)
	return true

static func receive_stomp(actor: CharacterBody3D, _attacker: Node3D) -> bool:
	if actor.is_dead or actor.state != STATE_POSTURE_BROKEN or actor.posture_stomped:
		return false
	actor.posture_stomped = true
	actor.vitality = maxf(0.0, actor.vitality - 18.0)
	actor.combat_feedback.emit("stomp", actor)
	if actor.vitality <= 0.0:
		actor._die()
	return true
