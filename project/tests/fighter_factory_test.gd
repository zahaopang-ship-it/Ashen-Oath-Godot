extends SceneTree

const FACTORY = preload("res://scripts/factories/fighter_factory.gd")
const FIGHTER = preload("res://scripts/fighter.gd")
const BOSS = preload("res://scripts/boss.gd")

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
	var world := Node3D.new()
	root.add_child(world)
	var player := FACTORY.create(world, "FactoryPlayer", Vector3.ZERO, true)
	_check(player.get_script() == FIGHTER, "factory creates the standard fighter script")
	_check(player.is_player, "factory preserves player-control role")
	_check(is_instance_valid(player.body_collision) and player.body_collision.shape is CapsuleShape3D, "factory creates the physics capsule")
	_check(player.get_node_or_null("UpperBodyPivot/BodyMesh") != null, "factory creates the body visual hierarchy")
	_check(player.get_node_or_null("UpperBodyPivot/RightArmPivot/ElbowPivot/WristPivot/WeaponPivot") != null, "factory creates the weapon rig hierarchy")
	_check(player.get_node_or_null("PatrolNavigationAgent") == null, "player does not receive an AI navigation agent")
	var sentinel := FACTORY.create(world, "FactorySentinel", Vector3(4, 0, 0), false)
	_check(sentinel.get_script() == FIGHTER and not sentinel.is_player, "factory creates a non-player sentinel")
	_check(sentinel.get_node_or_null("PatrolNavigationAgent") is NavigationAgent3D, "sentinel receives its navigation agent")
	var boss := FACTORY.create(world, "FactoryBoss", Vector3(8, 0, 0), false, true)
	_check(boss.get_script() == BOSS, "factory selects the dedicated boss script")
	_check(boss.get_node_or_null("PatrolNavigationAgent") == null, "boss does not receive a sentinel navigation agent")
	_check(boss.get_node_or_null("UpperBodyPivot") != null and boss.get_node("UpperBodyPivot").get_child_count() > 4, "boss receives its armor visual additions")
	_check(world.get_child_count() == 3, "factory attaches each fighter to the requested parent")
	print("Fighter factory: ", checks - failures, "/", checks, " assertions passed")
	if failures > 0:
		quit(1)
	else:
		quit(0)