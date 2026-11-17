extends SceneTree

const INPUT_ROUTER = preload("res://scripts/input/player_input_router.gd")
const FIGHTER = preload("res://scripts/fighter.gd")

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

func _new_player(label: String) -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = label
	player.set_script(FIGHTER)
	player.is_player = true
	root.add_child(player)
	return player

func _key(code: Key, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	return event

func _run() -> void:
	var attacker := _new_player("InputAttack")
	INPUT_ROUTER.handle_event(_key(KEY_J), attacker)
	_check(attacker.attack_timer > 0.0, "J routes to the player attack action")
	var defender := _new_player("InputDeflect")
	INPUT_ROUTER.handle_event(_key(KEY_K), defender)
	_check(defender.is_deflecting, "K press begins deflect")
	INPUT_ROUTER.handle_event(_key(KEY_K, false), defender)
	_check(not defender.is_deflecting, "K release ends deflect")
	var blocker := _new_player("InputBlock")
	INPUT_ROUTER.handle_event(_key(KEY_L), blocker)
	_check(blocker.is_blocking, "L press begins block")
	INPUT_ROUTER.handle_event(_key(KEY_L, false), blocker)
	_check(not blocker.is_blocking, "L release ends block")
	var croucher := _new_player("InputCrouch")
	INPUT_ROUTER.handle_event(_key(KEY_C), croucher)
	_check(croucher.is_crouching, "C toggles crouch")
	var jumper := _new_player("InputJump")
	INPUT_ROUTER.handle_event(_key(KEY_F), jumper)
	_check(is_zero_approx(jumper.velocity.y), "F safely rejects a jump while the fighter is airborne")
	var mikiri := _new_player("InputMikiri")
	INPUT_ROUTER.handle_event(_key(KEY_I), mikiri)
	_check(mikiri.is_mikiri_countering, "I routes to the Mikiri counter")
	var evader := _new_player("InputSweep")
	INPUT_ROUTER.handle_event(_key(KEY_O), evader)
	_check(evader.is_sweep_evading, "O routes to the sweep-evasion action")
	var dodge := _new_player("InputDodge")
	INPUT_ROUTER.handle_event(_key(KEY_SPACE), dodge)
	_check(dodge.is_dodging, "Space routes to dodge")
	print("Player input router tests: ", checks - failures, "/", checks, " passed")
	quit(1 if failures > 0 else 0)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]