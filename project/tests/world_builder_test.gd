extends SceneTree

const MAIN = preload("res://scripts/main.gd")
const WORLD_BUILDER = preload("res://scripts/world/world_builder.gd")

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
	var main := Node3D.new()
	main.set_script(MAIN)
	root.add_child(main)
	await process_frame
	await physics_frame
	_check(main.world_builder is WORLD_BUILDER, "main owns a dedicated Ashen Vale world builder")
	_check(main.world_builder.world_root == main, "world builder writes environment nodes into the main scene root")
	_check(main.get_node_or_null("AshenValeGround") != null, "ground remains addressable from the main scene")
	_check(main.get_node_or_null("NorthRuinedGate") != null, "ruined gate remains addressable from the main scene")
	_check(main.get_node_or_null("EastWatchCamp") != null, "watch camp remains addressable from the main scene")
	_check(get_nodes_in_group("water_zones").size() == 1, "builder registers the training water volume")
	_check(get_nodes_in_group("climbable_surfaces").size() == 1, "builder registers climbable environment geometry")
	_check(get_nodes_in_group("grapple_points").size() == 3, "builder registers all grapple anchors")
	_check(get_nodes_in_group("stealth_cover").size() == 3, "builder registers all stealth cover props")
	_check(get_nodes_in_group("rest_points").size() == 2, "builder registers both rest shrines")
	_check(get_nodes_in_group("secret_caches").size() == 1, "builder registers the hidden relic cache")
	_check(is_instance_valid(main.player), "world setup completes before encounter actors are initialized")
	print("World builder tests: ", checks - failures, "/", checks, " passed")
	quit(1 if failures > 0 else 0)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]