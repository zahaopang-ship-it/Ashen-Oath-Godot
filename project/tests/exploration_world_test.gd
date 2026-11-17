extends SceneTree

const MAIN = preload("res://scripts/main.gd")
const HUD = preload("res://scripts/touch_hud.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var game := Node3D.new()
	game.set_script(MAIN)
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	var player: CharacterBody3D = game.player
	var guards := get_nodes_in_group("stealth_guards")
	_check(guards.size() >= 3, "expanded region has multiple independently patrolling sentinels")
	_check(get_nodes_in_group("rest_points").size() == 2, "two rest shrines are placed in separate exploration regions")
	_check(get_nodes_in_group("secret_caches").size() == 1, "a hidden relic cache rewards exploration away from the main path")
	_check(get_nodes_in_group("exploration_landmarks").size() >= 4, "region contains distinct navigational landmarks")
	_check(get_nodes_in_group("exploration_paths").size() >= 12, "stone trail pieces form connected route markers")
	_check(game.get_node_or_null("NorthRuinedGate") != null, "north approach has a visible ruined gate landmark")
	_check(game.get_node_or_null("EastWatchCamp") != null, "eastern approach has a distinct guard camp")
	var hud: Node = null
	for child in game.get_children():
		if child.get_script() == HUD:
			hud = child
	_check(is_instance_valid(hud) and hud.action_rects.has("rest"), "touch HUD exposes the contextual rest-shrine action")
	_check(is_instance_valid(hud) and hud.action_rects.has("secret"), "touch HUD exposes the contextual secret-cache action")
	var cache: Node3D = get_nodes_in_group("secret_caches")[0]
	player.global_position = Vector3(0.0, 0.0, 4.0)
	_check(not player.interact_secret_cache(), "secret cache cannot be collected from outside interaction range")
	player.global_position = cache.global_position + Vector3(0.0, 0.0, 1.4)
	player.prosthetic_energy = 40.0
	var upgrade_points_before: int = player.prosthetic_upgrade_points
	_check(player.interact_secret_cache(), "hidden relic cache can be collected at close range")
	_check(bool(cache.get_meta("collected")) and not cache.visible, "collected secret cache is permanently hidden for this session")
	_check(player.prosthetic_upgrade_points == upgrade_points_before + 1 and is_equal_approx(player.prosthetic_energy, 65.0), "secret relic grants one upgrade point and spirit energy")
	_check(not player.interact_secret_cache(), "a collected secret cannot be claimed twice")
	var shrines := get_nodes_in_group("rest_points")
	var first = shrines[0]
	var second = shrines[1]
	player.global_position = first.global_position + Vector3(0.0, 0.0, 1.4)
	player.vitality = 24.0
	player.posture = 70.0
	player.prosthetic_energy = 12.0
	player.resurrection_charges = 0
	player.resurrection_available = false
	_check(player.interact_rest_point(), "nearby rest shrine can be activated")
	_check(player.checkpoint_position.distance_to(first.global_position) > 0.5, "rest shrine sets a safe respawn offset")
	_check(is_equal_approx(player.vitality, player.max_vitality), "rest shrine restores vitality")
	_check(is_equal_approx(player.posture, 0.0), "rest shrine clears posture")
	_check(is_equal_approx(player.prosthetic_energy, player.max_prosthetic_energy), "rest shrine replenishes prosthetic energy")
	_check(player.resurrection_charges == player.max_resurrection_charges and player.resurrection_available, "rest shrine restores the resurrection charge")
	_check(first.is_active and not second.is_active, "only the selected shrine is lit as the active checkpoint")
	player.global_position = second.global_position + Vector3(0.0, 0.0, 1.4)
	_check(player.interact_rest_point(), "distant shrine can replace the active checkpoint")
	_check(second.is_active and not first.is_active, "checkpoint activation transfers cleanly between shrines")
	player.is_dead = true
	player.state = player.CombatState.DEAD
	player.resurrection_available = true
	player.resurrection_charges = 1
	_check(player.resurrect(), "resurrection can be used after resting at the newly selected shrine")
	_check(player.global_position.distance_to(player.checkpoint_position) < 0.01, "resurrection returns to the selected shrine checkpoint")
	player.global_position = Vector3(0.0, 0.0, 4.0)
	_check(not player.interact_rest_point(), "rest interaction fails safely outside shrine range")
	if failures.is_empty():
		print("Exploration world tests: 25/25 passed")
	else:
		printerr("Exploration world tests: ", 25 - failures.size(), "/25 passed")
	quit(0 if failures.is_empty() else 1)
