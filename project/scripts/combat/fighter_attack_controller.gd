extends RefCounted

## Owns attack startup, local-space hit-volume checks, one-hit resolution, and player combo buffering.
## CombatState numeric values mirror Fighter.CombatState: FREE=0, WINDUP=1, ACTIVE=2, RECOVERY=3.
const STATE_FREE := 0
const STATE_WINDUP := 1
const STATE_ACTIVE := 2
const STATE_RECOVERY := 3


static func start_attack(actor: CharacterBody3D, kind: String) -> bool:
	if actor.is_dead or actor.state != STATE_FREE or actor.is_blocking or not actor.ATTACK_KINDS.has(kind):
		return false
	if actor.is_player:
		var noise_radius := 3.2 if actor.is_crouching else 9.5
		for listener in actor.get_tree().get_nodes_in_group("stealth_guards"):
			if is_instance_valid(listener) and listener.has_method("emit_noise"):
				listener.emit_noise(actor.global_position, noise_radius)
	actor._attack_token += 1
	actor._attack_hit_applied = false
	actor.attack_kind = kind
	actor.state = STATE_WINDUP
	actor.attack_timer = float(actor.ATTACK_WINDUP[kind])
	actor.telegraph_started.emit(kind)
	actor.attack_phase_changed.emit("windup")
	return true


static func is_target_inside_hitbox(actor: CharacterBody3D, candidate: Node3D) -> bool:
	if not is_instance_valid(candidate):
		return false
	var local_center: Vector3 = actor.global_transform.affine_inverse() * (candidate.global_position + Vector3.UP * 0.9)
	var half_extents: Vector3 = actor.ATTACK_HITBOX.get(actor.attack_kind, actor.ATTACK_HITBOX["slash"])
	var vertical_center := 0.45 if actor.attack_kind == "sweep" else 0.9
	return absf(local_center.x) <= half_extents.x and absf(local_center.y - vertical_center) <= half_extents.y and local_center.z <= -0.22 and local_center.z >= -half_extents.z


static func resolve_attack_hit(actor: CharacterBody3D) -> void:
	if actor._attack_hit_applied or not is_instance_valid(actor.target) or actor.target.is_dead:
		return
	if not is_target_inside_hitbox(actor, actor.target):
		return
	actor._attack_hit_applied = true
	actor.target.receive_strike(float(actor.ATTACK_DAMAGE[actor.attack_kind]), float(actor.ATTACK_POSTURE[actor.attack_kind]), actor, actor.attack_kind)
	actor.attack_hit.emit(actor.target)


static func request_player_attack(actor: CharacterBody3D) -> bool:
	if actor.is_dead or not actor.is_player:
		return false
	if actor.combo_reset_timer <= 0.0 and actor.state == STATE_FREE:
		actor.combo_step = 0
	var chain: Array[String] = ["slash", "slash", "heavy"]
	var requested_kind: String = chain[mini(actor.combo_step, chain.size() - 1)]
	actor.combo_step = (actor.combo_step + 1) % chain.size()
	actor.combo_reset_timer = actor.COMBO_RESET_TIME
	if actor.state == STATE_FREE and not actor.is_blocking:
		return actor.start_attack(requested_kind)
	if actor.state in [STATE_WINDUP, STATE_ACTIVE, STATE_RECOVERY]:
		actor.buffered_attack_kind = requested_kind
		actor.attack_buffer_timer = actor.ATTACK_BUFFER_WINDOW
		return true
	return false

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]