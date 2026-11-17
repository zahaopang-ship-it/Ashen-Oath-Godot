extends SceneTree

const FIGHTER = preload("res://scripts/fighter.gd")
const BOSS = preload("res://scripts/boss.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _fighter(script: Script, label: String, pos: Vector3, player: bool = false) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = label
	actor.set_script(script)
	actor.position = pos
	actor.is_player = player
	root.add_child(actor)
	return actor

func _run() -> void:
	var player := _fighter(FIGHTER, "Player", Vector3.ZERO, true)
	var boss := _fighter(BOSS, "LightningWarlord", Vector3(0.0, 0.0, -1.5))
	player.target = boss
	boss.target = player
	_check(not player.begin_lightning_reversal(), "lightning reversal cannot start while grounded")
	player.velocity.y = 5.8
	_check(player.begin_lightning_reversal(), "lightning reversal window opens while airborne")
	_check(not player.begin_lightning_reversal(), "lightning reversal cannot be repeatedly refreshed")
	var health: float = player.vitality
	_check(player.receive_strike(38.0, 42.0, boss, "lightning") == "lightning_reversed", "airborne timed reversal catches incoming lightning")
	_check(is_equal_approx(player.vitality, health), "successful reversal prevents lightning vitality damage")
	_check(boss.state == boss.CombatState.HITSTUN and boss.posture >= 82.0, "lightning is reflected into boss stagger and posture damage")
	_check(root.find_child("LightningArc", true, false) != null, "successful reversal creates a visible return lightning arc")
	_check(is_equal_approx(player.lightning_reversal_timer, 0.0), "successful reversal consumes its timing window")
	var grounded_player := _fighter(FIGHTER, "GroundedPlayer", Vector3(3.0, 0.0, 0.0), true)
	var second_boss := _fighter(BOSS, "SecondWarlord", Vector3(3.0, 0.0, -1.5))
	grounded_player.velocity.y = 0.0
	grounded_player.begin_lightning_reversal()
	_check(grounded_player.receive_strike(38.0, 42.0, second_boss, "lightning") == "hit", "grounded player cannot reverse lightning even with a stale timer")
	_check(grounded_player.vitality < 100.0, "failed lightning counter takes normal damage")
	var pattern_boss := _fighter(BOSS, "PatternBoss", Vector3(6.0, 0.0, 0.0))
	pattern_boss.boss_phase = 2
	_check(pattern_boss.get_phase_pattern().has("lightning"), "phase two boss pattern includes a lightning attack")
	_check(pattern_boss.start_attack("lightning") and is_equal_approx(pattern_boss.attack_timer, 1.05), "lightning attack has a readable 1.05-second telegraph")
	var upgrade_player := _fighter(FIGHTER, "UpgradePlayer", Vector3(9.0, 0.0, 0.0), true)
	_check(upgrade_player.prosthetic_upgrade_points == 3, "prototype starts with three prosthetic upgrade tokens")
	_check(upgrade_player.upgrade_next_prosthetic(), "upgrade selector upgrades the next available tool")
	_check(upgrade_player.prosthetic_upgrades["shuriken"] == 1 and upgrade_player.prosthetic_upgrade_points == 2, "shuriken upgrade raises its level and spends one token")
	_check(upgrade_player.upgrade_next_prosthetic() and upgrade_player.prosthetic_upgrades["firecracker"] == 1, "upgrade selector advances to firecracker")
	_check(upgrade_player.upgrade_next_prosthetic() and upgrade_player.prosthetic_upgrades["axe"] == 1, "upgrade selector advances to axe")
	_check(not upgrade_player.upgrade_next_prosthetic(), "upgrade selector refuses upgrades after tokens are exhausted")
	_check(not upgrade_player.upgrade_prosthetic("unknown"), "unknown tool upgrades are rejected")
	if failures.is_empty():
		print("Lightning and upgrade tests: 19/19 passed")
	else:
		printerr("Lightning and upgrade tests: ", 19 - failures.size(), "/19 passed")
	quit(0 if failures.is_empty() else 1)
