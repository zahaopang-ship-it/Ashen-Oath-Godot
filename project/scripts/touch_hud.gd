extends CanvasLayer
var game: Node
var stick_touch := -1
var look_touch := -1
var move_vector := Vector2.ZERO
var stick_radius := 78.0
var stick_knob: ColorRect
var vitality_bar: ProgressBar
var posture_bar: ProgressBar
var enemy_vitality: ProgressBar

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
	var enemy_label := Label.new()
	enemy_label.text = "ASHIGARU"
	enemy_label.position = Vector2(500, 10)
	enemy_label.add_theme_font_size_override("font_size", 15)
	root.add_child(enemy_label)
	var stick := Control.new()
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick.position = Vector2(90, -205)
	stick.size = Vector2(150, 150)
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stick)
	var ring := ColorRect.new()
	ring.color = Color(0.85, 0.85, 0.85, 0.12)
	ring.size = Vector2(150, 150)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.add_child(ring)
	stick_knob = ColorRect.new()
	stick_knob.color = Color(0.9, 0.88, 0.78, 0.42)
	stick_knob.size = Vector2(58, 58)
	stick_knob.position = Vector2(46, 46)
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.add_child(stick_knob)
	_add_action_button(root, "ATTACK", Vector2(-190, -150), "attack", Color(0.62, 0.16, 0.12))
	_add_action_button(root, "DEFLECT", Vector2(-110, -255), "deflect", Color(0.72, 0.55, 0.20))
	_add_action_button(root, "BLOCK", Vector2(-270, -260), "block", Color(0.25, 0.37, 0.48))
	_add_action_button(root, "DODGE", Vector2(-90, -80), "dodge", Color(0.25, 0.42, 0.32))
	var hint := Label.new()
	hint.text = "Drag right side to rotate camera"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-310, -30)
	hint.add_theme_font_size_override("font_size", 13)
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

func _add_action_button(parent: Control, label_text: String, offset: Vector2, action: String, color: Color) -> void:
	var b := Button.new()
	b.text = label_text
	b.size = Vector2(100, 70)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.position = offset
	b.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.bg_color.a = 0.72
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("pressed", normal)
	parent.add_child(b)
	match action:
		"attack":
			b.button_down.connect(func(): game.player.player_attack())
		"deflect":
			b.button_down.connect(func(): game.player.begin_deflect())
			b.button_up.connect(func(): game.player.end_deflect())
		"block":
			b.button_down.connect(func(): game.player.begin_block())
			b.button_up.connect(func(): game.player.end_block())
		"dodge":
			b.button_down.connect(func(): game.player.dodge())

func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < size.x * 0.42 and stick_touch == -1:
				stick_touch = event.index
				_update_stick(event.position)
			elif event.position.x >= size.x * 0.42 and look_touch == -1:
				look_touch = event.index
		else:
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

func _update_stick(screen_pos: Vector2) -> void:
	var size := get_viewport().get_visible_rect().size
	var center := Vector2(165, size.y - 130)
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
