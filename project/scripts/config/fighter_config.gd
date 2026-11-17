extends Resource
class_name FighterConfig

## Data-only tuning profile shared by the fighter factory and runtime actors.
@export_group("Identity")
@export var profile_id: StringName = &"fighter_default"
@export_group("Vitals")
@export var max_vitality := 100.0
@export var max_posture := 100.0
@export_group("Movement")
@export var move_speed := 5.2
@export var movement_acceleration := 30.0
@export var movement_braking := 34.0
@export var combat_turn_speed := 15.0
@export var dodge_speed := 10.0
@export_group("Combat")
@export var attack_range := 2.15
@export var attack_damage := 22.0
@export var attack_posture_damage := 30.0
@export var deflect_window := 0.20
@export var deflect_lockout := 0.34
@export_group("Awareness")
@export var vision_range := 10.0
@export var vision_half_angle_degrees := 48.0
@export var sprint_noise_range := 8.0
@export_group("Boss")
@export var boss_phase_two_threshold := 0.55
@export var boss_phase_one_pattern: Array[String] = ["slash", "thrust", "heavy", "slash"]
@export var boss_phase_two_pattern: Array[String] = ["sweep", "grab", "thrust", "lightning", "ashen_rend"]
@export var boss_phase_two_damage_scale := 1.18
@export var boss_phase_one_speed := 4.4
@export var boss_phase_two_speed := 5.25
@export var boss_phase_one_attack_range := 2.5
@export var boss_phase_two_attack_range := 2.8


func apply_to(actor: CharacterBody3D) -> void:
	actor.max_vitality = max_vitality
	actor.vitality = max_vitality
	actor.max_posture = max_posture
	actor.posture = 0.0
	actor.move_speed = move_speed
	actor.movement_acceleration = movement_acceleration
	actor.movement_braking = movement_braking
	actor.combat_turn_speed = combat_turn_speed
	actor.dodge_speed = dodge_speed
	actor.attack_range = attack_range
	actor.attack_damage = attack_damage
	actor.attack_posture_damage = attack_posture_damage
	actor.deflect_window = deflect_window
	actor.deflect_lockout = deflect_lockout
	actor.vision_range = vision_range
	actor.vision_half_angle_degrees = vision_half_angle_degrees
	actor.sprint_noise_range = sprint_noise_range
