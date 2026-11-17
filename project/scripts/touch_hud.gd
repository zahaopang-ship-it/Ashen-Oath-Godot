extends CanvasLayer
var game: Node
var stick_touch := -1
var look_touch := -1
var action_touches: Dictionary = {}
var move_vector := Vector2.ZERO
var stick_radius := 78.0
var stick_knob: ColorRect
var stick_control: Control
var vitality_bar: ProgressBar
var posture_bar: ProgressBar
var enemy_vitality: ProgressBar
var enemy_posture: ProgressBar
var suspicion_bar: ProgressBar
var status_label: Label
var action_rects: Dictionary = {}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var title := Label.new()
	title.text = "ASHEN OATH  /  COMBAT TEST"
	title.position = Vector2(28, 18)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.85, 0.83, 0.75))
	root.add_child(title)
	vitality_bar = _make_bar(root, Vector2(28, 54), Vector2(250, 18), Color(0.65, 0.13, 0.12))
	posture_bar = _make_bar(root, Vector2(28, 78), Vector2(250, 12), Color(0.83, 0.61, 0.18))
	enemy_vitality = _make_bar(root, Vector2(500, 36), Vector2(280, 14), Color(0.62, 0.12, 0.10))
	enemy_posture = _make_bar(root, Vector2(500, 55), Vector2(280, 9), Color(0.83, 0.61, 0.18))
	suspicion_bar = _make_bar(root, Vector2(28, 101), Vector2(250, 8), Color(0.88, 0.48, 0.12))
	suspicion_bar.max_value = 1.15
	var enemy_label := Label.new()
	enemy_label.text = "ASHEN WARLORD  /  BOSS"
	enemy_label.position = Vector2(500, 10)
	enemy_label.add_theme_font_size_override("font_size", 15)
	root.add_child(enemy_label)
	status_label = Label.new()
	status_label.position = Vector2(28, 105)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
	root.add_child(status_label)
	stick_control = Control.new()
	stick_control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick_control.position = Vector2(70, -220)
	stick_control.size = Vector2(156, 156)
	stick_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stick_control)
	var ring := ColorRect.new()
	ring.color = Color(0.85, 0.85, 0.85, 0.12)
	ring.size = Vector2(150, 150)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_control.add_child(ring)
	stick_knob = ColorRect.new()
	stick_knob.color = Color(0.9, 0.88, 0.78, 0.42)
	stick_knob.size = Vector2(58, 58)
	stick_knob.position = Vector2(46, 46)
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_control.add_child(stick_knob)
	_register_action("ATTACK", Vector2(-195, -145), "attack", Color(0.62, 0.16, 0.12))
	_register_action("DEFLECT", Vector2(-115, -250), "deflect", Color(0.72, 0.55, 0.20))
	_register_action("BLOCK", Vector2(-275, -250), "block", Color(0.25, 0.37, 0.48))
	_register_action("DODGE", Vector2(-95, -70), "dodge", Color(0.25, 0.42, 0.32))
	_register_action("MIKIRI", Vector2(-275, -70), "mikiri", Color(0.58, 0.25, 0.12))
	_register_action("JUMP", Vector2(-195, -70), "jump", Color(0.18, 0.42, 0.55))
	_register_action("STOMP", Vector2(-370, -145), "stomp", Color(0.52, 0.30, 0.12))
	_register_action("DEATHBLOW", Vector2(-370, -70), "deathblow", Color(0.72, 0.08, 0.08))
	_register_action("CROUCH", Vector2(-370, -250), "crouch", Color(0.25, 0.34, 0.39))
	_register_action("VAULT", Vector2(-475, -250), "vault", Color(0.34, 0.39, 0.28))
	_register_action("CLIMB", Vector2(-475, -170), "climb", Color(0.28, 0.39, 0.52))
	var hint := Label.new()
	hint.text = "C CROUCH  /  V VAULT  /  M CLIMB ledges  /  Hide in cover"
	hint.position = Vector2(28, 132)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	root.add_child(hint)

func _make_bar(parent: Control, pos: Vector2, bar_size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = bar_size
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.05, 0.78)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	return bar

func _register_action(label_text: String, offset: Vector2, action: String, color: Color) -> void:
	var b := Button.new()
	b.text = label_text
	b.size = Vector2(100, 70)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.position = offset
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.bg_color.a = 0.72
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("pressed", style)
	get_child(0).add_child(b)
	action_rects[action] = Rect2(Vector2(get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y) + offset, b.size)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	var size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			var action := _action_at(event.position)
			if action != "":
				action_touches[event.index] = action
				_action_down(action)
				get_viewport().set_input_as_handled()
			elif event.position.x < size.x * 0.42 and stick_touch == -1:
				stick_touch = event.index
				_update_stick(event.position)
			elif event.position.x >= size.x * 0.42 and look_touch == -1:
				look_touch = event.index
		else:
			if action_touches.has(event.index):
				_action_up(str(action_touches[event.index]))
				action_touches.erase(event.index)
			if event.index == stick_touch:
				stick_touch = -1
				move_vector = Vector2.ZERO
				game.player.input_move = move_vector
				stick_knob.position = Vector2(46, 46)
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == stick_touch:
			_update_stick(event.position)
		elif event.index == look_touch:
			game.rotate_camera(event.relative.x, event.relative.y)

func _action_at(pos: Vector2) -> String:
	for action in action_rects:
		if action_rects[action].has_point(pos):
			return str(action)
	return ""

func _action_down(action: String) -> void:
	match action:
		"attack": game.player.player_attack()
		"deflect": game.player.begin_deflect()
		"block": game.player.begin_block()
		"dodge": game.player.dodge()
		"mikiri": game.player.begin_mikiri_counter()
		"jump": game.player.begin_sweep_evade()
		"stomp": game.player.stomp_broken_target()
		"deathblow":
			if not game.player.stealth_deathblow_target():
				game.player.deathblow_broken_target()
		"crouch": game.player.toggle_crouch()
		"vault": game.player.try_vault()
		"climb": game.player.try_mantle()

func _action_up(action: String) -> void:
	match action:
		"deflect": game.player.end_deflect()
		"block": game.player.end_block()

func _update_stick(screen_pos: Vector2) -> void:
	var center := Vector2(70.0 + 78.0, get_viewport().get_visible_rect().size.y - 142.0)
	var delta := screen_pos - center
	if delta.length() > stick_radius:
		delta = delta.normalized() * stick_radius
	move_vector = delta / stick_radius
	game.player.input_move = move_vector
	stick_knob.position = Vector2(46, 46) + delta * 0.58

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player) or not is_instance_valid(game.enemy):
		return
	vitality_bar.value = game.player.get_vitality_ratio() * 100.0
	posture_bar.value = game.player.get_posture_ratio() * 100.0
	enemy_vitality.value = game.enemy.get_vitality_ratio() * 100.0
	enemy_posture.value = game.enemy.get_posture_ratio() * 100.0
	var movement_label := "SPRINT" if game.player.is_sprinting else "WALK"
	var execution_prompt := "  /  DEATHBLOW READY" if game.enemy.state == 4 and not game.enemy.is_dead else ""
	var phase_text := "PHASE II" if game.enemy.boss_phase == 2 else "PHASE I"
	var awareness_text: String = ["UNAWARE", "SUSPICIOUS", "SEARCHING", "ALERTED"][game.guard.awareness_state]
	suspicion_bar.value = game.guard.suspicion
	var stealth_label := " / COVERED" if game.player.is_in_cover and game.player.is_crouching else (" / IN COVER" if game.player.is_in_cover else "")
	status_label.text = "PLAYER: " + _state_name(game.player) + (" / CROUCH" if game.player.is_crouching else " / " + movement_label) + stealth_label + "   |   SENTINEL: " + awareness_text + "   |   WARLORD: " + phase_text + " / " + _state_name(game.enemy) + execution_prompt

func _state_name(fighter: Node) -> String:
	if fighter.state == 4: return "POSTURE BROKEN"
	if fighter.state == 1: return "TELEGRAPH"
	if fighter.state == 2: return "ATTACK"
	if fighter.state == 3: return "RECOVERY"
	if fighter.is_blocking: return "GUARD"
	if fighter.is_deflecting: return "DEFLECT"
	return "READY"
