extends RefCounted

## Routes keyboard debug input through the same fighter action API used by touch HUD.
static func handle_event(event: InputEvent, player: CharacterBody3D) -> void:
	if not player:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J: player.player_attack()
			KEY_K: player.begin_deflect()
			KEY_L: player.begin_block()
			KEY_SPACE: player.dodge()
			KEY_I: player.begin_mikiri_counter()
			KEY_O: player.begin_sweep_evade()
			KEY_P: player.stomp_broken_target()
			KEY_E:
				if not player.stealth_deathblow_target():
					player.deathblow_broken_target()
			KEY_C: player.toggle_crouch()
			KEY_V: player.try_vault()
			KEY_M: player.try_mantle()
			KEY_H: player.toggle_wall_hug()
			KEY_B: player.begin_cover_transfer()
			KEY_1: player.use_prosthetic("shuriken")
			KEY_2: player.use_prosthetic("firecracker")
			KEY_3: player.use_prosthetic("axe")
			KEY_4: player.use_prosthetic("umbrella")
			KEY_R: player.begin_lightning_reversal()
			KEY_U: player.upgrade_next_prosthetic()
			KEY_F: player.begin_jump()
			KEY_G: player.try_grapple()
			KEY_T: player.aerial_grapple_attack()
			KEY_Y: player.resurrect()
			KEY_Z: player.interact_rest_point()
			KEY_X: player.interact_secret_cache()
			KEY_N: player.try_vertical_climb()
			KEY_COMMA: player.stop_vertical_climb()
			KEY_PERIOD: player.try_ledge_grab()
			KEY_PAGEUP: player.set_swim_vertical_input(1.0)
			KEY_PAGEDOWN: player.set_swim_vertical_input(-1.0)
			KEY_KP_1: player.end_deflect()
			KEY_KP_2: player.end_block()
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_K: player.end_deflect()
		if event.keycode == KEY_L: player.end_block()
		if event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]: player.set_swim_vertical_input(0.0)
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if Input.is_key_pressed(KEY_W): move.y -= 1.0
	if Input.is_key_pressed(KEY_S): move.y += 1.0
	player.input_move = move.normalized() if move.length() > 1.0 else move
	player.sprint_requested = Input.is_key_pressed(KEY_SHIFT)


[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]