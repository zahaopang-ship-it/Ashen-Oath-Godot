extends "res://scripts/fighter.gd"

signal boss_phase_changed(phase: int)

const PHASE_ONE := 1
const PHASE_TWO := 2
const PHASE_TWO_THRESHOLD := 0.55
const PHASE_ONE_PATTERN := ["slash", "thrust", "heavy", "slash"]
const PHASE_TWO_PATTERN := ["sweep", "grab", "thrust", "heavy"]

var boss_phase := PHASE_ONE
var pattern_index := 0
var phase_two_damage_scale := 1.18

func _ready() -> void:
	display_name = "Ashen Warlord"
	max_vitality = 420.0
	vitality = max_vitality
	max_posture = 260.0
	posture = 0.0
	move_speed = 4.4
	attack_range = 2.5
	ai_timer = 1.1

func _physics_process(delta: float) -> void:
	if not is_dead and boss_phase == PHASE_ONE and vitality <= max_vitality * PHASE_TWO_THRESHOLD:
		_enter_phase_two()
	super._physics_process(delta)

func _enter_phase_two() -> void:
	boss_phase = PHASE_TWO
	pattern_index = 0
	ai_timer = 0.35
	move_speed = 5.25
	attack_range = 2.8
	boss_phase_changed.emit(boss_phase)
	combat_feedback.emit("boss_phase", self)

func _ai_update(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead or state != CombatState.FREE:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance > 1.85:
		var dir := to_target.normalized()
		var approach_speed := move_speed * (0.82 if boss_phase == PHASE_ONE else 1.02)
		velocity.x = dir.x * approach_speed
		velocity.z = dir.z * approach_speed
		_face_direction(dir, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 26.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 26.0 * delta)
	ai_timer -= delta
	if ai_timer > 0.0 or distance > attack_range:
		return
	var pattern: Array = PHASE_ONE_PATTERN if boss_phase == PHASE_ONE else PHASE_TWO_PATTERN
	var chosen: String = pattern[pattern_index % pattern.size()]
	pattern_index += 1
	var started := start_attack(chosen)
	if started and boss_phase == PHASE_TWO:
		attack_timer *= 0.78
		ai_timer = 0.62
	else:
		ai_timer = 1.05 if boss_phase == PHASE_ONE else 0.78

func _resolve_attack_hit() -> void:
	if _attack_hit_applied or not is_instance_valid(target) or target.is_dead:
		return
	if not _is_target_inside_attack_hitbox(target):
		return
	_attack_hit_applied = true
	var damage_scale := 1.0 if boss_phase == PHASE_ONE else phase_two_damage_scale
	target.receive_strike(float(ATTACK_DAMAGE[attack_kind]) * damage_scale, float(ATTACK_POSTURE[attack_kind]) * damage_scale, self, attack_kind)
	attack_hit.emit(target)

func get_phase_pattern() -> Array:
	return PHASE_ONE_PATTERN.duplicate() if boss_phase == PHASE_ONE else PHASE_TWO_PATTERN.duplicate()
