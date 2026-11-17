extends SceneTree

const FIGHTER = preload("res://scripts/fighter.gd")
const MAIN = preload("res://scripts/main.gd")
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
	var player := CharacterBody3D.new()
	player.set_script(FIGHTER)
	player.is_player = true
	player.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(player)
	player.set_checkpoint(Vector3(2.0, 0.0, 3.0))
	player._die()
	_check(player.is_dead and player.resurrection_available and player.resurrection_charges == 1, "player death enables one available resurrection charge")
	_check(player.resurrect(), "player can consume resurrection after death")
	_check(not player.is_dead and player.state == FIGHTER.CombatState.FREE, "resurrection restores the live combat state")
	_check(is_equal_approx(player.vitality, 55.0) and is_equal_approx(player.posture, 0.0), "resurrection restores 55 percent vitality and clears posture")
	_check(player.global_position.is_equal_approx(Vector3(2.0, 0.0, 3.0)), "resurrection returns player to checkpoint position")
	_check(player.resurrection_charges == 0 and not player.resurrection_available, "resurrection consumes its only charge")
	_check(player.receive_strike(30.0, 20.0, null) == "immune", "resurrection grants a brief damage immunity window")
	player._die()
	_check(not player.resurrect(), "player cannot resurrect again after charge is exhausted")
	var enemy := CharacterBody3D.new()
	enemy.set_script(FIGHTER)
	root.add_child(enemy)
	_check(not enemy.resurrect(), "non-player fighters cannot use player resurrection")
	var game := Node3D.new()
	game.set_script(MAIN)
	root.add_child(game)
	await process_frame
	await physics_frame
	var world_player: CharacterBody3D = game.player
	world_player.global_position = Vector3(0.0, 0.0, 4.0)
	world_player.rotation.y = 0.0
	_check(get_nodes_in_group("grapple_points").size() == 3, "arena builds three visible grapple anchors")
	_check(world_player.try_grapple(), "player can lock onto a forward reachable grapple anchor")
	_check(world_player.is_grappling and is_instance_valid(world_player.grapple_target), "grapple enters a dedicated traversal state with a target")
	var grapple_start: Vector3 = world_player.global_position
	for i in range(80):
		await physics_frame
		if not world_player.is_grappling:
			break
	_check(not world_player.is_grappling, "grapple traversal completes within its timed arc")
	_check(world_player.global_position.distance_to(grapple_start) > 2.0, "grapple moves player through world space rather than teleporting")
	_check(world_player._grapple_attack_ready, "completed grapple arms a contextual aerial attack")
	world_player.global_position = game.boss.global_position + Vector3(0.0, 0.0, 2.0)
	world_player.rotation.y = 0.0
	_check(world_player.aerial_grapple_attack(), "aerial follow-up attack can trigger near the target")
	_check(world_player.state == FIGHTER.CombatState.WINDUP, "aerial follow-up enters the heavy attack telegraph")
	var blocked_player := CharacterBody3D.new()
	blocked_player.set_script(FIGHTER)
	blocked_player.is_player = true
	root.add_child(blocked_player)
	blocked_player.global_position = Vector3(100.0, 0.0, 100.0)
	var behind_anchor := Area3D.new()
	behind_anchor.add_to_group("grapple_points")
	root.add_child(behind_anchor)
	behind_anchor.global_position = Vector3(100.0, 3.0, 105.0)
	_check(not blocked_player.try_grapple(), "grapple rejects anchors behind the player")
	if failures.is_empty():
		print("Resurrection and grapple tests: 18/18 passed")
	else:
		printerr("Resurrection and grapple tests: ", 18 - failures.size(), "/18 passed")
	quit(0 if failures.is_empty() else 1)
