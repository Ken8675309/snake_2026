extends CanvasLayer
class_name UIManager

var game_manager

var _score_label: Label
var _high_score_label: Label
var _length_label: Label
var _effects_label: Label
var _state_label: Label
var _state_subtitle: Label
var _countdown_label: Label
var _controls_label: Label
var _brightness_slider: HSlider
var _vignette: ColorRect
var _top_bar: HBoxContainer
var _menu_root: Control
var _start_button: Button
var _quit_button: Button


func _ready() -> void:
	layer = 20
	_build_ui()


func _process(_delta: float) -> void:
	if game_manager == null or game_manager.snake == null:
		return

	_length_label.text = "LENGTH  %02d" % game_manager.snake.get_length()
	var effects = game_manager.get_effect_status()
	var active: Array[String] = []
	if effects["speed"] > 0.0:
		active.append("OVERDRIVE %.0f" % effects["speed"])
	if effects["shield"] > 0.0:
		active.append("SHIELD %.0f" % effects["shield"])
	if effects["magnet"] > 0.0:
		active.append("MAGNET %.0f" % effects["magnet"])
	_effects_label.text = " / ".join(active) if not active.is_empty() else _get_status_line()


func setup(manager) -> void:
	game_manager = manager
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.state_changed.connect(_on_state_changed)
	game_manager.countdown_changed.connect(_on_countdown_changed)
	_start_button.pressed.connect(game_manager.request_start_game)
	_quit_button.pressed.connect(game_manager.request_quit)
	_brightness_slider.value = game_manager.brightness
	_brightness_slider.value_changed.connect(_on_brightness_changed)
	_on_score_changed(game_manager.score, game_manager.high_score)
	_on_state_changed("MENU")


func _on_score_changed(score: int, high_score: int) -> void:
	_score_label.text = "SCORE  %06d" % score
	_high_score_label.text = "BEST  %06d" % high_score


func _on_state_changed(state_name: String) -> void:
	var menu_visible := state_name == "MENU"
	var center_state_visible := state_name == "PAUSED" or state_name == "GAME_OVER"
	_menu_root.visible = menu_visible
	_top_bar.visible = not menu_visible
	_effects_label.visible = true
	_countdown_label.visible = state_name == "COUNTDOWN"
	_state_label.visible = center_state_visible
	_state_subtitle.visible = center_state_visible
	_vignette.visible = menu_visible or center_state_visible
	match state_name:
		"MENU":
			_state_label.text = ""
			_state_subtitle.text = ""
			_countdown_label.text = ""
			_effects_label.text = "READY TO STRIKE"
			_start_button.grab_focus()
		"COUNTDOWN":
			_state_label.text = ""
			_state_subtitle.text = ""
			_effects_label.text = "READY TO STRIKE"
		"PAUSED":
			_state_label.text = "PAUSED"
			_state_subtitle.text = "P RESUME   ESC MENU"
			_effects_label.text = "COILED"
		"GAME_OVER":
			_state_label.text = "SERPENT DOWN"
			_state_subtitle.text = "R / ENTER RESTART   ESC MENU"
			_effects_label.text = "VENOM SPENT"
		_:
			_state_label.text = ""
			_state_subtitle.text = ""
			_countdown_label.text = ""


func _on_countdown_changed(text: String) -> void:
	_countdown_label.text = text
	_countdown_label.visible = not text.is_empty()


func _on_brightness_changed(value: float) -> void:
	if game_manager != null and game_manager.has_method("set_brightness"):
		game_manager.set_brightness(value)


func _get_status_line() -> String:
	if game_manager == null:
		return "READY TO STRIKE"
	match game_manager.state:
		game_manager.GameState.MENU, game_manager.GameState.COUNTDOWN:
			return "READY TO STRIKE"
		game_manager.GameState.PAUSED:
			return "COILED"
		game_manager.GameState.GAME_OVER:
			return "VENOM SPENT"
	return "HUNT ACTIVE"


func _build_ui() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_vignette = ColorRect.new()
	_vignette.name = "StateVignette"
	_vignette.color = Color(0.0, 0.0, 0.0, 0.42)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.visible = false
	root.add_child(_vignette)

	_top_bar = HBoxContainer.new()
	_top_bar.name = "TopBar"
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_left = 28.0
	_top_bar.offset_top = 22.0
	_top_bar.offset_right = -28.0
	_top_bar.offset_bottom = 62.0
	_top_bar.add_theme_constant_override("separation", 28)
	root.add_child(_top_bar)

	_score_label = _make_label(24, Color(0.8, 1.0, 0.96))
	_score_label.custom_minimum_size = Vector2(230.0, 34.0)
	_top_bar.add_child(_score_label)

	_high_score_label = _make_label(18, Color(0.55, 0.82, 1.0))
	_high_score_label.custom_minimum_size = Vector2(210.0, 34.0)
	_top_bar.add_child(_high_score_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar.add_child(spacer)

	_length_label = _make_label(18, Color(0.55, 1.0, 0.74))
	_length_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_length_label.custom_minimum_size = Vector2(160.0, 34.0)
	_top_bar.add_child(_length_label)

	_effects_label = _make_label(16, Color(1.0, 0.82, 0.35))
	_effects_label.name = "EffectsLabel"
	_effects_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_effects_label.offset_left = 28.0
	_effects_label.offset_right = -28.0
	_effects_label.offset_top = -54.0
	_effects_label.offset_bottom = -20.0
	_effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_effects_label)

	_controls_label = _make_label(15, Color(0.72, 0.9, 1.0))
	_controls_label.name = "ControlsLabel"
	_controls_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_controls_label.offset_left = 28.0
	_controls_label.offset_right = -28.0
	_controls_label.offset_top = -28.0
	_controls_label.offset_bottom = -4.0
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.text = "WASD / Arrow Keys steer   Left Mouse: camera   Wheel: zoom   C: reset camera   P pause   R restart   Esc menu"
	root.add_child(_controls_label)

	_build_brightness_control(root)

	_countdown_label = _make_label(96, Color(0.95, 1.0, 0.96))
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	_countdown_label.offset_left = -180.0
	_countdown_label.offset_top = -90.0
	_countdown_label.offset_right = 180.0
	_countdown_label.offset_bottom = 90.0
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.visible = false
	root.add_child(_countdown_label)

	var center := VBoxContainer.new()
	center.name = "StateCenter"
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -260.0
	center.offset_top = -80.0
	center.offset_right = 260.0
	center.offset_bottom = 80.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(center)

	_state_label = _make_label(54, Color(0.95, 1.0, 0.96))
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.visible = false
	center.add_child(_state_label)

	_state_subtitle = _make_label(18, Color(0.25, 0.95, 0.9))
	_state_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_subtitle.visible = false
	center.add_child(_state_subtitle)

	_build_menu(root)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build_brightness_control(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "BrightnessControl"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -210.0
	panel.offset_top = -94.0
	panel.offset_right = -24.0
	panel.offset_bottom = -42.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var label := _make_label(13, Color(0.78, 0.9, 0.95))
	label.text = "Brightness"
	box.add_child(label)

	_brightness_slider = HSlider.new()
	_brightness_slider.min_value = 0.5
	_brightness_slider.max_value = 2.0
	_brightness_slider.step = 0.01
	_brightness_slider.value = 1.2
	_brightness_slider.custom_minimum_size = Vector2(164.0, 20.0)
	_brightness_slider.focus_mode = Control.FOCUS_NONE
	_brightness_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(_brightness_slider)


func _build_menu(root: Control) -> void:
	_menu_root = Control.new()
	_menu_root.name = "MainMenu"
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_menu_root)

	var center := VBoxContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -220.0
	center.offset_top = -150.0
	center.offset_right = 220.0
	center.offset_bottom = 150.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 14)
	_menu_root.add_child(center)

	var title := _make_label(56, Color(0.95, 1.0, 0.96))
	title.text = "Neon Serpent"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var prompt := _make_label(17, Color(0.28, 0.95, 0.9))
	prompt.text = "ENTER / SPACE START   Q QUIT"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(prompt)

	_start_button = _make_button("Start Game")
	center.add_child(_start_button)

	_quit_button = _make_button("Quit")
	center.add_child(_quit_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220.0, 42.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	return button
