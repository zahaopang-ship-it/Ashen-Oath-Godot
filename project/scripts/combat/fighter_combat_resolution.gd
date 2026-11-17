extends RefCounted

## Centralizes strike reception, hit reactions, posture breaks, and death transitions.
const STATE_FREE := 0
const STATE_POSTURE_BROKEN := 4
const STATE_DEAD := 5
const STATE_HITSTUN := 6

static func begin_hit_reaction(actor: CharacterBody3D, attacker: Node3D, incoming_kind: String = "slash") -> void:
	if actor.state == STATE_POSTURE_BROKEN or actor.is_dead:
		return
	actor.hit_reaction_kind = incoming_kind
	actor.hit_reaction_duration = 0.34 if incoming_kind in ["heavy", "ashen_rend"] else (0.25 if incoming_kind in ["thrust", "sweep", "grab"] else 0.18)
	actor.state = STATE_HITSTUN
	actor.hit_reaction_timer = actor.hit_reaction_duration
	actor.hit_flash_timer = 0.12 if incoming_kind in ["slash", "thrust"] else 0.18
	if is_instance_valid(attacker):
		var away: Vector3 = actor.global_position - attacker.global_position
		away.y = 0.0
		if away.length_squared() > 0.001:
			away = away.normalized()
			actor._hit_reaction_side = signf(actor.global_transform.basis.x.dot(away))
			if is_zero_approx(actor._hit_reaction_side):
				actor._hit_reaction_side = 1.0
			var knockback: float = 5.0 if incoming_kind in ["heavy", "ashen_rend"] else (2.2 if incoming_kind == "thrust" else 3.4)
			actor.velocity.x = away.x * knockback
			actor.velocity.z = away.z * knockback

static func receive_strike(actor: CharacterBody3D, damage: float, posture_damage: float, attacker: Node3D, incoming_kind: String = "slash") -> String:
	if actor.is_dead:
		return "ignored"
	if actor.resurrection_invulnerability > 0.0:
		return "immune"
	if actor.is_dodging:
		actor.combat_feedback.emit("evaded", actor)
		return "evaded"
	if incoming_kind == "lightning" and actor.is_player and actor.lightning_reversal_timer > 0.0 and actor.velocity.y > 0.35:
		actor.lightning_reversal_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_lightning_reversal"):
			attacker.receive_lightning_reversal(actor)
		actor.combat_feedback.emit("lightning_reversed", actor)
		return "lightning_reversed"
	if incoming_kind == "thrust" and actor.is_mikiri_countering:
		actor.is_mikiri_countering = false
		actor.counter_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(48.0)
		actor.combat_feedback.emit("mikiri", actor)
		return "mikiri"
	if incoming_kind == "sweep" and actor.is_sweep_evading:
		actor.is_sweep_evading = false
		actor.counter_timer = 0.0
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(32.0)
		actor.combat_feedback.emit("sweep_evaded", actor)
		return "sweep_evaded"
	if actor.is_deflecting and incoming_kind != "grab":
		actor._parry_pose_timer = 0.22
		if is_instance_valid(attacker) and attacker.has_method("receive_deflect"):
			attacker.receive_deflect(40.0 if incoming_kind == "heavy" else 26.0)
		actor.combat_feedback.emit("deflect", actor)
		return "deflected"
	if actor.is_blocking and incoming_kind != "grab":
		var block_scale: float = 0.85 if incoming_kind == "heavy" else (0.72 if incoming_kind == "thrust" else 0.55)
		actor.posture += posture_damage * block_scale
		check_posture_break(actor)
		actor.combat_feedback.emit("guard", actor)
		return "blocked"
	actor.vitality = maxf(0.0, actor.vitality - damage)
	actor.posture += posture_damage
	check_posture_break(actor)
	if actor.vitality <= 0.0:
		die(actor)
	else:
		begin_hit_reaction(actor, attacker, incoming_kind)
		if incoming_kind == "grab":
			actor.hit_reaction_timer = 0.62
			actor.combat_feedback.emit("grabbed", actor)
		else:
			actor.combat_feedback.emit("hit", actor)
	return "grabbed" if incoming_kind == "grab" else "hit"

static func receive_deflect(actor: CharacterBody3D, amount: float) -> void:
	if actor.is_dead:
		return
	actor._deflect_recoil_timer = 0.20
	actor.posture += amount
	check_posture_break(actor)

static func check_posture_break(actor: CharacterBody3D) -> void:
	actor.posture = clampf(actor.posture, 0.0, actor.max_posture)
	if actor.posture >= actor.max_posture and actor.state != STATE_POSTURE_BROKEN:
		actor.state = STATE_POSTURE_BROKEN
		actor._posture_break_age = 0.0
		actor.attack_phase_changed.emit("interrupted")
		actor.posture_break_timer = actor.POSTURE_BREAK_TIME
		actor.posture_stomped = false
		actor.hit_reaction_timer = 0.0
		actor.is_blocking = false
		actor.deflect_timer = 0.0
		actor.is_deflecting = false
		actor.posture_broken.emit()
		actor.combat_feedback.emit("posture_break", actor)

static func die(actor: CharacterBody3D) -> void:
	if actor.is_dead:
		return
	actor.is_dead = true
	if actor.is_player:
		actor.resurrection_available = actor.resurrection_charges > 0
	actor.state = STATE_DEAD
	actor.attack_phase_changed.emit("finished")
	actor.is_blocking = false
	actor.velocity = Vector3.ZERO
	actor.combat_feedback.emit("death", actor)
	actor.died.emit()

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]