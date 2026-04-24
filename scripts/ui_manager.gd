extends CanvasLayer
class_name UIManager

var game_manager: GameManager

var _score_label: Label
var _high_score_label: Label
var _length_label: Label
var _effects_label: Label
var _state_label: Label
var _state_subtitle: Label
var _vignette: ColorRect


func _ready() -> void:
	layer = 20
	_build_ui()


func _process(_delta: float) -> void:
	if game_manager == null or game_manager.snake == null:
		return

	_length_label.text = "LENGTH  %02d" % game_manager.snake.get_length()
	var effects := game_manager.get_effect_status()
	var active: Array[String] = []
	if effects["speed"] > 0.0:
		active.append("OVERDRIVE %.0f" % effects["speed"])
	if effects["shield"] > 0.0:
		active.append("SHIELD %.0f" % effects["shield"])
	if effects["magnet"] > 0.0:
		active.append("MAGNET %.0f" % effects["magnet"])
	_effects_label.text = " / ".join(active) if not active.is_empty() else "SYSTEMS NOMINAL"


func setup(manager: GameManager) -> void:
	game_manager = manager
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.state_changed.connect(_on_state_changed)
	_on_score_changed(game_manager.score, game_manager.high_score)
	_on_state_changed("PLAYING")


func _on_score_changed(score: int, high_score: int) -> void:
	_score_label.text = "SCORE  %06d" % score
	_high_score_label.text = "BEST  %06d" % high_score


func _on_state_changed(state_name: String) -> void:
	_state_label.visible = state_name != "PLAYING"
	_state_subtitle.visible = state_name != "PLAYING"
	_vignette.visible = state_name != "PLAYING"
	match state_name:
		"PAUSED":
			_state_label.text = "PAUSED"
			_state_subtitle.text = "RUN SUSPENDED"
		"GAME_OVER":
			_state_label.text = "SIGNAL LOST"
			_state_subtitle.text = "NEW RUN AVAILABLE"
		_:
			_state_label.text = ""
			_state_subtitle.text = ""


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

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 28.0
	top_bar.offset_top = 22.0
	top_bar.offset_right = -28.0
	top_bar.offset_bottom = 62.0
	top_bar.add_theme_constant_override("separation", 28)
	root.add_child(top_bar)

	_score_label = _make_label(24, Color(0.8, 1.0, 0.96))
	_score_label.custom_minimum_size = Vector2(230.0, 34.0)
	top_bar.add_child(_score_label)

	_high_score_label = _make_label(18, Color(0.55, 0.82, 1.0))
	_high_score_label.custom_minimum_size = Vector2(210.0, 34.0)
	top_bar.add_child(_high_score_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_length_label = _make_label(18, Color(0.55, 1.0, 0.74))
	_length_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_length_label.custom_minimum_size = Vector2(160.0, 34.0)
	top_bar.add_child(_length_label)

	_effects_label = _make_label(16, Color(1.0, 0.82, 0.35))
	_effects_label.name = "EffectsLabel"
	_effects_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_effects_label.offset_left = 28.0
	_effects_label.offset_right = -28.0
	_effects_label.offset_top = -54.0
	_effects_label.offset_bottom = -20.0
	_effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_effects_label)

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


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
