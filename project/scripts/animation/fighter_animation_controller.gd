extends RefCounted

## Owns procedural rig binding and the full combat/locomotion pose evaluator.
enum CombatState { FREE, WINDUP, ACTIVE, RECOVERY, POSTURE_BROKEN, DEAD, HITSTUN, EXECUTING }
const WINDUP_TIME := 0.32
const ACTIVE_TIME := 0.10
const ATTACK_WINDUP := {"slash": 0.32, "thrust": 0.48, "sweep": 0.42, "heavy": 0.62, "grab": 0.72, "ashen_rend": 0.92, "lightning": 1.05}

static func set_body_material(actor: CharacterBody3D, material: StandardMaterial3D) -> void:
	actor._body_material = material
	if actor._body_material:
		actor._body_material.set_meta("base_color", actor._body_material.albedo_color)

static func set_animation_rig(actor: CharacterBody3D, upper_body: Node3D, weapon_pivot: Node3D, left_leg: Node3D = null, right_leg: Node3D = null, left_arm: Node3D = null, right_arm: Node3D = null, left_elbow: Node3D = null, right_elbow: Node3D = null) -> void:
	actor._upper_body = upper_body
	actor._weapon_pivot = weapon_pivot
	actor._left_leg_pivot = left_leg
	actor._right_leg_pivot = right_leg
	actor._left_arm_pivot = left_arm
	actor._right_arm_pivot = right_arm
	actor._left_elbow_pivot = left_elbow
	actor._right_elbow_pivot = right_elbow

static func update_combat_animation(actor: CharacterBody3D, delta: float) -> void:
	actor._combat_anim_time += delta
	if not is_instance_valid(actor._upper_body) or not is_instance_valid(actor._weapon_pivot):
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
	var planar_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var speed_ratio := clampf(planar_speed / maxf(0.1, actor.move_speed * 1.42), 0.0, 1.0)
	var locomotion_active: bool = planar_speed > 0.22 and actor.state == 0 and not actor.is_blocking
	if locomotion_active:
		var gait_rate := lerpf(5.8, 10.5, speed_ratio)
		if actor.is_sprinting:
			gait_rate *= 1.12
		var gait_style := 1.0
		if not actor.is_player:
			gait_rate *= 0.92
			gait_style = 0.88
			if actor.has_method("get_phase_pattern") and int(actor.get("boss_phase")) == 2:
				gait_style = 1.12
		actor._gait_phase = fposmod(actor._gait_phase + delta * gait_rate, TAU)
		gait_blend = clampf(planar_speed / maxf(0.1, actor.move_speed * 0.32), 0.0, 1.0)
		var stride := sin(actor._gait_phase) * 0.48 * gait_blend * gait_style
		left_leg_pose = stride
		right_leg_pose = -stride
		var bob_rate := 2.0 if actor.is_sprinting else 1.0
		actor._locomotion_bob = absf(cos(actor._gait_phase)) * 0.045 * gait_blend * bob_rate
	else:
		actor._locomotion_bob = lerpf(actor._locomotion_bob, 0.0, weight)
		left_leg_pose = 0.0
		right_leg_pose = 0.0
	if is_instance_valid(actor._left_leg_pivot):
		actor._left_leg_pivot.rotation.x = lerpf(actor._left_leg_pivot.rotation.x, left_leg_pose, 1.0 - exp(-14.0 * delta))
	if is_instance_valid(actor._right_leg_pivot):
		actor._right_leg_pivot.rotation.x = lerpf(actor._right_leg_pivot.rotation.x, right_leg_pose, 1.0 - exp(-14.0 * delta))
	if actor.state == 1:
		var duration: float = float(ATTACK_WINDUP.get(actor.attack_kind, WINDUP_TIME))
		var progress := 1.0 - clampf(actor.attack_timer / duration, 0.0, 1.0)
		var anticipation := sin(progress * PI * 0.5)
		match actor.attack_kind:
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
	elif actor.state == 2:
		var progress := 1.0 - clampf(actor.attack_timer / ACTIVE_TIME, 0.0, 1.0)
		var follow := sin(progress * PI)
		match actor.attack_kind:
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
	elif actor.state == 3:
		left_arm_pose = Vector3(0.05, 0.0, 0.12)
		right_arm_pose = Vector3(0.12, 0.0, -0.08)
		body_pose = Vector3(0.08, 0.0, 0.08)
		weapon_pose = Vector3(0.18, 0.0, -0.10)
		left_arm_pose = Vector3(-0.08, 0.0, 0.14)
		right_arm_pose = Vector3(0.12, 0.0, -0.18)
	elif actor.state == 6:
		var stagger := clampf(actor.hit_reaction_timer / maxf(0.01, actor.hit_reaction_duration), 0.0, 1.0)
		match actor.hit_reaction_kind:
			"thrust":
				body_pose = Vector3(-0.78, 0.0, 0.10 * actor._hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.22, 0.0, 0.36)
				right_arm_pose = Vector3(-0.26, 0.0, -0.34)
				weapon_pose = Vector3(0.62, 0.0, 0.18)
			"heavy", "ashen_rend":
				var force := 1.0 if actor.hit_reaction_kind == "heavy" else 1.35
				body_pose = Vector3(-0.92 * force, 0.0, 0.34 * actor._hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.72, 0.0, 0.58)
				right_arm_pose = Vector3(-0.68, 0.0, -0.62)
				weapon_pose = Vector3(0.92 * force, 0.0, 0.28)
				body_offset = Vector3(0.0, -0.12 * force, 0.08)
			"sweep":
				body_pose = Vector3(0.28, 0.0, 0.72 * actor._hit_reaction_side) * stagger
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
				body_pose = Vector3(-0.42, 0.0, 0.20 * actor._hit_reaction_side) * stagger
				left_arm_pose = Vector3(-0.48, 0.0, 0.42)
				right_arm_pose = Vector3(-0.42, 0.0, -0.38)
				weapon_pose = Vector3(0.55, 0.0, 0.3)
	elif actor.state == 4:
		var buckle := sin(actor._posture_break_age * 9.0)
		left_arm_pose = Vector3(0.42 + buckle * 0.08, 0.0, 0.58)
		right_arm_pose = Vector3(0.35 + buckle * 0.06, 0.0, -0.52)
		body_pose = Vector3(0.72 + absf(buckle) * 0.10, 0.0, sin(actor._posture_break_age * 4.5) * 0.12)
		weapon_pose = Vector3(0.95 + buckle * 0.12, 0.0, 0.08)
		body_offset = Vector3(0.0, -0.10 - absf(buckle) * 0.04, 0.0)
	elif actor.state == 7:
		var execution_progress := 1.0 - clampf(actor.execution_timer / 0.82, 0.0, 1.0)
		if actor.deathblow_executed:
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
	elif actor.state == 5:
		left_arm_pose = Vector3(0.65, 0.0, 0.72)
		right_arm_pose = Vector3(0.72, 0.0, -0.68)
		body_pose = Vector3(1.35, 0.0, 0.0)
		weapon_pose = Vector3(0.4, 0.0, 0.0)
	elif actor.umbrella_timer > 0.0:
		left_arm_pose = Vector3(-0.38, 0.0, 0.62)
		right_arm_pose = Vector3(-0.68, 0.0, -0.58)
		body_pose = Vector3(-0.16, 0.0, 0.0)
		weapon_pose = Vector3(-0.72, 0.0, -0.48)
	elif actor.is_blocking:
		left_arm_pose = Vector3(-0.22, 0.0, 0.36)
		right_arm_pose = Vector3(-0.48, 0.0, -0.38)
		body_pose = Vector3(-0.08, 0.0, 0.0)
		weapon_pose = Vector3(-0.42, 0.0, -0.32)
	elif actor.is_dodging:
		left_arm_pose = Vector3(0.38, 0.0, 0.45)
		right_arm_pose = Vector3(0.30, 0.0, -0.42)
		body_pose = Vector3(0.25, 0.0, 0.0)
		body_offset = Vector3(0.0, -0.13, 0.0)
		weapon_pose = Vector3(0.25, 0.0, -0.24)
	elif actor.is_mikiri_countering:
		left_arm_pose = Vector3(-0.18, 0.0, 0.32)
		right_arm_pose = Vector3(-0.58, 0.0, -0.52)
		body_pose = Vector3(-0.16, 0.0, 0.0)
		weapon_pose = Vector3(-0.28, 0.0, -0.5)
	elif actor.is_sweep_evading:
		left_arm_pose = Vector3(0.28, 0.0, 0.42)
		right_arm_pose = Vector3(0.12, 0.0, -0.32)
		body_pose = Vector3(0.35, 0.0, 0.0)
		weapon_pose = Vector3(-0.35, 0.0, -0.2)
	else:
		var idle_breath := sin(actor._combat_anim_time * 2.4)
		var walk_sway := sin(actor._gait_phase) * gait_blend
		body_pose = Vector3(0.025 * idle_breath + walk_sway * 0.035, 0.0, 0.025 * sin(actor._combat_anim_time * 1.7) + gait_blend * (0.035 if actor.is_sprinting else 0.015))
		body_offset = Vector3(0.0, actor._locomotion_bob, 0.0)
		weapon_pose = Vector3(0.0, 0.0, -0.18 + 0.035 * sin(actor._combat_anim_time * 2.0) + walk_sway * 0.045)
		left_arm_pose = Vector3(0.035 * sin(actor._combat_anim_time * 2.0), 0.0, 0.10 + walk_sway * 0.12)
		right_arm_pose = Vector3(-0.04 * sin(actor._combat_anim_time * 2.0), 0.0, -0.12 - walk_sway * 0.10)
		if not actor.is_player:
			weapon_pose.x -= 0.10
			body_pose.z += 0.025
			left_arm_pose.z += 0.08
			right_arm_pose.z -= 0.06
	if actor.is_crouching:
		var sneak_cycle := sin(actor._combat_anim_time * (3.4 if planar_speed > 0.18 else 1.5))
		var sneak_blend := clampf(planar_speed / maxf(0.1, actor.move_speed * 0.48), 0.0, 1.0)
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
	if actor.is_wall_hugging:
		var wall_side := -1.0 if actor._wall_hug_side < 0.0 else 1.0
		body_pose.z += wall_side * 0.16
		body_pose.x += 0.08
		left_arm_pose.x -= 0.12
		right_arm_pose.x -= 0.20
		left_arm_pose.z -= wall_side * 0.10
		right_arm_pose.z += wall_side * 0.10
		weapon_pose.z += wall_side * 0.12
		left_leg_pose += 0.06 * wall_side
		right_leg_pose -= 0.06 * wall_side
	if actor.is_vaulting:
		var vault_progress := clampf(actor._vault_elapsed / maxf(0.01, actor._vault_duration), 0.0, 1.0)
		var tuck := sin(vault_progress * PI)
		body_pose = Vector3(-0.28, 0.0, 0.0)
		body_offset.y += 0.08 + tuck * 0.06
		left_leg_pose = -0.72 * tuck
		right_leg_pose = -0.62 * tuck
		left_arm_pose = Vector3(-0.48, 0.0, 0.42)
		right_arm_pose = Vector3(-0.42, 0.0, -0.38)
		weapon_pose = Vector3(0.36, 0.0, -0.22)
	var parry_blend := clampf(actor._parry_pose_timer / 0.22, 0.0, 1.0)
	var recoil_blend := clampf(actor._deflect_recoil_timer / 0.20, 0.0, 1.0)
	var tool_blend := clampf(actor.prosthetic_pose_timer / 0.34, 0.0, 1.0)
	match actor.prosthetic_pose:
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
	actor._upper_body.rotation = actor._upper_body.rotation.lerp(body_pose, weight)
	actor._upper_body.position = actor._upper_body.position.lerp(body_offset, weight)
	actor._weapon_pivot.rotation = actor._weapon_pivot.rotation.lerp(weapon_pose, weight)
	if is_instance_valid(actor._left_arm_pivot):
		actor._left_arm_pivot.rotation = actor._left_arm_pivot.rotation.lerp(left_arm_pose, weight)
	if is_instance_valid(actor._right_arm_pivot):
		actor._right_arm_pivot.rotation = actor._right_arm_pivot.rotation.lerp(right_arm_pose, weight)
	var left_elbow_bend := clampf(absf(left_arm_pose.x) * 0.42 + absf(left_arm_pose.z) * 0.28 + 0.10, 0.08, 0.72)
	var right_elbow_bend := clampf(absf(right_arm_pose.x) * 0.42 + absf(right_arm_pose.z) * 0.28 + 0.12, 0.08, 0.78)
	if actor.is_blocking:
		left_elbow_bend = 0.58
		right_elbow_bend = 0.66
	if is_instance_valid(actor._left_elbow_pivot):
		actor._left_elbow_pivot.rotation.x = lerpf(actor._left_elbow_pivot.rotation.x, left_elbow_bend, weight)
	if is_instance_valid(actor._right_elbow_pivot):
		actor._right_elbow_pivot.rotation.x = lerpf(actor._right_elbow_pivot.rotation.x, right_elbow_bend, weight)
