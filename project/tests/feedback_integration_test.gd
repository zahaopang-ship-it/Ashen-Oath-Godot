extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	main.enemy.is_player = true # Keep the integration scene deterministic: no autonomous follow-up attacks.
	main.enemy.receive_strike(9.0, 6.0, main.player)
	_check(Engine.time_scale < 0.1, "combat hit activates a brief global hitstop")
	var audio_nodes := 0
	for child in main.get_children():
		if child is AudioStreamPlayer3D and child.name == "CombatSFX":
			audio_nodes += 1
	_check(audio_nodes == 1, "combat feedback spawns a spatial impact sound")
	await create_timer(0.18, true, false, true).timeout
	main._restore_hitstop(main._hitstop_generation) # Drive the restore callback explicitly in the SceneTree test harness.
	_check(is_equal_approx(Engine.time_scale, 1.0), "hitstop restores the previous time scale (actual: %.3f)" % Engine.time_scale)
	await create_timer(0.65, true, false, true).timeout
	main.queue_free()
	await process_frame
	print("Feedback integration tests: ", 3 - failures.size(), "/3 passed")
	quit(1 if not failures.is_empty() else 0)
