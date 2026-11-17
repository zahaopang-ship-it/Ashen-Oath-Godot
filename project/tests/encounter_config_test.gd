extends SceneTree

const CONFIG = preload("res://resources/encounters/ashen_vale.tres")
const FIGHTER_CONFIG = preload("res://resources/fighters/ashen_warlord.tres")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	_check(CONFIG.player_spawn == Vector3(0.0, 0.0, 4.0), "encounter config preserves player spawn")
	_check(CONFIG.player_checkpoint == Vector3(0.0, 0.0, 10.0), "encounter config owns player checkpoint")
	_check(CONFIG.boss_spawn == Vector3(0.0, 0.0, -3.0), "encounter config preserves boss spawn")
	_check(CONFIG.west_sentinel_patrol.size() == 4 and CONFIG.east_sentinel_patrol.size() == 4 and CONFIG.north_sentinel_patrol.size() == 4, "each sentinel patrol route is authored as resource data")
	_check(is_equal_approx(CONFIG.west_sentinel_speed, 1.55) and is_equal_approx(CONFIG.east_sentinel_speed, 1.7), "sentinel movement tuning is data-driven")
	_check(CONFIG.stealth_cover_positions.size() == 3 and CONFIG.grapple_anchor_positions.size() == 3, "cover and grapple placements are data-driven")
	_check(CONFIG.training_pond_size == Vector3(5.0, 1.4, 7.0), "water trigger dimensions are stored in encounter resource")
	_check(CONFIG.climb_wall_size == Vector3(0.55, 4.0, 7.0), "climb wall dimensions are stored in encounter resource")
	_check(CONFIG.secret_cache_position == Vector3(-21.0, 0.0, -8.5), "secret cache placement is stored in encounter resource")
	_check(CONFIG.ashen_shrine_position != CONFIG.grove_shrine_position, "both shrine placements remain independently configurable")
	_check(FIGHTER_CONFIG.boss_phase_two_pattern.has("lightning") and FIGHTER_CONFIG.boss_phase_two_pattern.has("ashen_rend"), "boss phase-two signature attacks remain configurable")
	print("Encounter config: ", checks - failures, "/", checks, " assertions passed")
	quit(1 if failures > 0 else 0)
