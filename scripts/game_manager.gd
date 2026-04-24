extends Node3D
class_name GameManager

signal score_changed(score: int, high_score: int)
signal lives_changed(lives: int, max_lives: int)
signal state_changed(state_name: String)
signal countdown_changed(text: String)

const SAVE_PATH := "user://python.cfg"
const DEFAULT_BRIGHTNESS := 1.2
const START_POSITION := Vector3.ZERO
const COUNTDOWN_SECONDS := 3.0
const GO_SECONDS := 0.65
const START_GRACE_SECONDS := 1.25
const PICKUP_HEIGHT := 0.72
const IMPACT_RECOVERY_SECONDS := 0.45
const IMPACT_GRACE_SECONDS := 1.0
const RECOVERY_SCAN_STEPS := 18
const SnakeControllerScript := preload("res://scripts/snake_controller.gd")
const CameraControllerScript := preload("res://scripts/camera_controller.gd")
const ArenaBuilderScript := preload("res://scripts/arena_builder.gd")
const EffectsManagerScript := preload("res://scripts/effects_manager.gd")
const UIManagerScript := preload("res://scripts/ui_manager.gd")
const AudioManagerScript := preload("res://scripts/audio_manager.gd")
const FoodScript := preload("res://scripts/food.gd")
const PowerUpScript := preload("res://scripts/power_up.gd")
const LifeEggScene := preload("res://scenes/life_egg.tscn")

enum GameState { MENU, COUNTDOWN, PLAYING, PAUSED, GAME_OVER }

var snake
var camera_controller
var arena
var effects
var ui_manager
var audio_manager
var food
var power_ups: Array = []
var life_eggs: Array = []
var score: int = 0
var high_score: int = 0
var current_lives: int = 3
var max_lives: int = 3
var state: GameState = GameState.MENU
var run_time: float = 0.0
var brightness: float = DEFAULT_BRIGHTNESS

var _rng := RandomNumberGenerator.new()
var _next_power_up_time: float = 8.0
var _next_life_egg_time: float = 14.0
var _life_eggs_spawned: int = 0
var _life_egg_target_total: int = 0
var _impact_recovery_time: float = 0.0
var _impact_grace_time: float = 0.0
var _countdown_time: float = 0.0
var _go_time: float = 0.0
var _grace_time: float = 0.0
var _last_countdown_text: String = ""
var _effect_timers := {
	"speed": 0.0,
	"shield": 0.0,
	"magnet": 0.0,
}


func _ready() -> void:
	_rng.randomize()
	_load_high_score()
	_create_core_systems()
	show_main_menu()


func _exit_tree() -> void:
	cleanup_runtime_objects()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup_runtime_objects()
		get_tree().quit()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu_quit") and state == GameState.MENU:
		request_quit()
		return

	if Input.is_action_just_pressed("menu_accept"):
		if state == GameState.MENU or state == GameState.GAME_OVER:
			start_new_game()
		return

	if Input.is_action_just_pressed("menu_back"):
		if state == GameState.MENU:
			request_quit()
		else:
			show_main_menu()
		return

	if Input.is_action_just_pressed("restart") and state == GameState.GAME_OVER:
		start_new_game()
		return

	if Input.is_action_just_pressed("pause_game") and (state == GameState.PLAYING or state == GameState.PAUSED):
		_set_state(GameState.PAUSED if state == GameState.PLAYING else GameState.PLAYING)

	if state == GameState.COUNTDOWN:
		_update_countdown(delta)
		return

	if state != GameState.PLAYING:
		return

	run_time += delta
	_grace_time = maxf(0.0, _grace_time - delta)
	_update_effects(delta)
	_update_power_ups(delta)
	_update_life_eggs(delta)
	_apply_magnet(delta)
	_check_food_collection()

	if _impact_recovery_time > 0.0:
		_impact_recovery_time = maxf(0.0, _impact_recovery_time - delta)
		if _impact_recovery_time == 0.0:
			snake.set_paused(false)
		return

	_impact_grace_time = maxf(0.0, _impact_grace_time - delta)
	if _grace_time <= 0.0 and _impact_grace_time <= 0.0:
		_check_collisions()


func request_start_game() -> void:
	start_new_game()


func request_quit() -> void:
	cleanup_runtime_objects()
	get_tree().quit()


func show_main_menu() -> void:
	score = 0
	current_lives = max_lives
	run_time = 0.0
	_countdown_time = 0.0
	_go_time = 0.0
	_grace_time = 0.0
	_clear_food()
	_clear_power_ups()
	_clear_life_eggs()
	if effects != null:
		effects.cleanup_runtime_objects()
	if audio_manager != null:
		audio_manager.cleanup_runtime_objects()
	_reset_effects()
	if snake != null:
		snake.reset(START_POSITION)
		snake.set_alive(true)
		snake.set_paused(true)
	if camera_controller != null:
		camera_controller.reset_to_target()
	score_changed.emit(score, high_score)
	lives_changed.emit(current_lives, max_lives)
	countdown_changed.emit("")
	_set_state(GameState.MENU)


func start_new_game() -> void:
	score = 0
	current_lives = max_lives
	run_time = 0.0
	_next_power_up_time = 7.5
	_next_life_egg_time = 12.0
	_life_eggs_spawned = 0
	_life_egg_target_total = _rng.randi_range(2, 3)
	_impact_recovery_time = 0.0
	_impact_grace_time = 0.0
	_countdown_time = COUNTDOWN_SECONDS
	_go_time = GO_SECONDS
	_grace_time = START_GRACE_SECONDS
	_last_countdown_text = ""
	_clear_food()
	_clear_power_ups()
	_clear_life_eggs()
	if effects != null:
		effects.cleanup_runtime_objects()
	if audio_manager != null:
		audio_manager.cleanup_runtime_objects()
	_reset_effects()
	snake.reset(START_POSITION)
	snake.set_alive(true)
	snake.set_paused(true)
	camera_controller.reset_to_target()
	_spawn_food()
	if audio_manager != null:
		audio_manager.play_start()
	score_changed.emit(score, high_score)
	lives_changed.emit(current_lives, max_lives)
	_set_state(GameState.COUNTDOWN)
	_emit_countdown_text("3")


func _create_core_systems() -> void:
	arena = ArenaBuilderScript.new()
	arena.name = "ArenaBuilder"
	arena.default_brightness = brightness
	add_child(arena)

	snake = SnakeControllerScript.new()
	snake.name = "SnakeController"
	snake.arena_half_extent = arena.arena_half_extent - 0.45
	add_child(snake)

	camera_controller = CameraControllerScript.new()
	camera_controller.name = "CameraController"
	add_child(camera_controller)
	camera_controller.set_target(snake)

	effects = EffectsManagerScript.new()
	effects.name = "EffectsManager"
	add_child(effects)

	ui_manager = UIManagerScript.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.setup(self)

	audio_manager = AudioManagerScript.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 2.0)
	if arena != null and arena.has_method("set_brightness"):
		arena.set_brightness(brightness)
	_save_settings()


func _check_food_collection() -> void:
	if food == null:
		_spawn_food()
		return
	var distance = _horizontal_distance(snake.get_head_position(), food.global_position)
	if distance <= food.collect_radius:
		_collect_food()


func _check_collisions() -> void:
	if snake.is_outside_arena():
		if snake.has_shield():
			_break_shield()
			snake.deflect_from_boundary()
			return
		_handle_impact("Boundary breach")
		return
	if snake.collides_with_self():
		if snake.has_shield():
			_break_shield()
			snake.shrink(2)
			return
		_handle_impact("Signal feedback")


func _collect_food() -> void:
	if food == null:
		return
	var earned = food.point_value + int(snake.get_length() * 0.5)
	var collected_position = food.global_position
	score += earned
	high_score = max(high_score, score)
	_save_high_score()
	snake.grow(2)
	camera_controller.shake(0.18)
	effects.food_burst(collected_position)
	audio_manager.play_eat()
	food.queue_free()
	food = null
	_spawn_food()
	score_changed.emit(score, high_score)


func _update_power_ups(delta: float) -> void:
	if run_time >= _next_power_up_time and power_ups.size() < 2:
		_spawn_power_up()
		_next_power_up_time = run_time + _rng.randf_range(10.0, 15.0)

	for i in range(power_ups.size() - 1, -1, -1):
		var power_up = power_ups[i]
		if not is_instance_valid(power_up):
			power_ups.remove_at(i)
			continue
		if _horizontal_distance(snake.get_head_position(), power_up.global_position) <= power_up.collect_radius:
			_collect_power_up(power_up)
			power_ups.remove_at(i)


func _update_life_eggs(delta: float) -> void:
	if _life_eggs_spawned < _life_egg_target_total and run_time >= _next_life_egg_time and life_eggs.size() < 1:
		_spawn_life_egg()
		_next_life_egg_time = run_time + _rng.randf_range(16.0, 24.0)

	for i in range(life_eggs.size() - 1, -1, -1):
		var egg = life_eggs[i]
		if not is_instance_valid(egg):
			life_eggs.remove_at(i)
			continue
		if _horizontal_distance(snake.get_head_position(), egg.global_position) <= egg.collect_radius:
			_collect_life_egg(egg)
			life_eggs.remove_at(i)


func _spawn_power_up() -> void:
	var power_up = PowerUpScript.new()
	power_up.name = "PowerUp"
	var roll := _rng.randi_range(0, 3)
	power_up.configure(roll)
	power_up.position = _find_clear_spawn_position()
	add_child(power_up)
	power_ups.append(power_up)


func _spawn_life_egg() -> void:
	var egg = LifeEggScene.instantiate()
	egg.name = "LifeEgg"
	egg.position = _find_clear_spawn_position(4.0, 6.0)
	add_child(egg)
	life_eggs.append(egg)
	_life_eggs_spawned += 1


func _collect_life_egg(egg) -> void:
	current_lives = mini(max_lives, current_lives + 1)
	lives_changed.emit(current_lives, max_lives)
	var collected_position: Vector3 = egg.global_position
	if effects != null:
		effects.life_burst(collected_position)
	if audio_manager != null:
		audio_manager.play_life()
	egg.queue_free()


func _collect_power_up(power_up) -> void:
	match power_up.power_type:
		PowerUpScript.PowerType.SPEED:
			_effect_timers["speed"] = 7.5
			snake.set_speed_multiplier(1.48)
		PowerUpScript.PowerType.SHIELD:
			_effect_timers["shield"] = 9.0
			snake.set_shield_enabled(true)
		PowerUpScript.PowerType.MAGNET:
			_effect_timers["magnet"] = 10.0
			snake.set_magnet_enabled(true)
		PowerUpScript.PowerType.BONUS:
			score += 50
			high_score = max(high_score, score)
			_save_high_score()
			score_changed.emit(score, high_score)
	camera_controller.shake(0.24)
	effects.power_burst(power_up.global_position, _get_power_up_color(power_up.power_type))
	audio_manager.play_power()
	print("Power-up: %s" % power_up.get_display_name())
	power_up.queue_free()


func _update_effects(delta: float) -> void:
	if _effect_timers["speed"] > 0.0:
		_effect_timers["speed"] = maxf(0.0, _effect_timers["speed"] - delta)
		if _effect_timers["speed"] == 0.0:
			snake.set_speed_multiplier(1.0)

	if _effect_timers["shield"] > 0.0:
		_effect_timers["shield"] = maxf(0.0, _effect_timers["shield"] - delta)
		if _effect_timers["shield"] == 0.0:
			snake.set_shield_enabled(false)

	if _effect_timers["magnet"] > 0.0:
		_effect_timers["magnet"] = maxf(0.0, _effect_timers["magnet"] - delta)
		if _effect_timers["magnet"] == 0.0:
			snake.set_magnet_enabled(false)


func _apply_magnet(delta: float) -> void:
	if food == null or not snake.magnet_enabled:
		return
	var to_snake = snake.get_head_position() - food.global_position
	if to_snake.length() > 8.5:
		return
	food.global_position += to_snake.normalized() * 5.8 * delta


func _break_shield() -> void:
	_effect_timers["shield"] = 0.0
	snake.consume_shield()
	camera_controller.shake(0.42)
	effects.shield_break(snake.get_head_position())
	audio_manager.play_shield_break()


func _handle_impact(reason: String) -> void:
	current_lives = maxi(current_lives - 1, 0)
	lives_changed.emit(current_lives, max_lives)
	var impact_position: Vector3 = snake.get_head_position()
	camera_controller.shake(0.72)
	if ui_manager != null and ui_manager.has_method("flash_impact"):
		ui_manager.flash_impact()
	if effects != null:
		effects.impact_burst(impact_position)
	if audio_manager != null:
		audio_manager.play_impact()
	if snake != null and snake.has_method("trigger_segment_impact"):
		snake.trigger_segment_impact(0.72, 0.8)

	if current_lives <= 0:
		_game_over(reason)
		return

	var recovery_direction: Vector2i = _choose_recovery_direction()
	snake.recover_after_impact(recovery_direction)
	snake.set_paused(true)
	_impact_recovery_time = IMPACT_RECOVERY_SECONDS
	_impact_grace_time = IMPACT_GRACE_SECONDS


func _spawn_food() -> void:
	if food != null:
		food.queue_free()

	food = FoodScript.new()
	food.name = "Food"
	food.position = _find_clear_spawn_position(3.25, 4.6)
	food.configure(10 + int(run_time / 18.0), Color(1.0, 0.15 + _rng.randf() * 0.2, 0.55 + _rng.randf() * 0.35))
	add_child(food)


func _find_clear_spawn_position(edge_margin: float = 2.6, snake_margin: float = 3.8) -> Vector3:
	for attempt in range(80):
		var candidate = _snap_pickup_position(arena.get_random_play_position(edge_margin))
		if _horizontal_distance(candidate, snake.get_head_position()) < snake_margin:
			continue
		var clear := true
		for body_position in snake.get_body_positions():
			if _horizontal_distance(candidate, body_position) < 2.0:
				clear = false
				break
		if clear:
			return candidate
	return _snap_pickup_position(arena.get_random_play_position(edge_margin))


func _snap_pickup_position(position: Vector3) -> Vector3:
	var cell_size := 1.0
	if snake != null:
		cell_size = maxf(float(snake.cell_size), 0.001)
	position.x = roundf(position.x / cell_size) * cell_size
	position.z = roundf(position.z / cell_size) * cell_size
	position.y = PICKUP_HEIGHT
	return position


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _choose_recovery_direction() -> Vector2i:
	var current_dir: Vector2i = snake.get_grid_direction()
	var candidates: Array[Vector2i] = [
		current_dir,
		Vector2i(current_dir.y, -current_dir.x),
		Vector2i(-current_dir.y, current_dir.x),
		-current_dir,
	]
	var start := _clamped_grid_position(snake.get_grid_position())
	var best_direction := candidates[0]
	var best_score := -1
	for candidate in candidates:
		var score := _clear_path_score(start, candidate)
		if score > best_score:
			best_score = score
			best_direction = candidate
	return best_direction


func _clear_path_score(start: Vector2i, test_direction: Vector2i) -> int:
	if test_direction == Vector2i.ZERO:
		return -1
	var occupied := _body_grid_cells()
	var score := 0
	for step in range(1, RECOVERY_SCAN_STEPS + 1):
		var p := start + test_direction * step
		if _is_grid_outside_arena(p):
			break
		if occupied.has(p):
			break
		score += 1
	return score


func _body_grid_cells(skip_segments: int = 5) -> Dictionary:
	var occupied := {}
	var positions: Array[Vector3] = snake.get_body_positions()
	var cell_size := maxf(float(snake.cell_size), 0.001)
	for i in range(skip_segments, positions.size()):
		var p := positions[i]
		occupied[Vector2i(roundi(p.x / cell_size), roundi(p.z / cell_size))] = true
	return occupied


func _clamped_grid_position(grid_position: Vector2i) -> Vector2i:
	var cell_size := maxf(float(snake.cell_size), 0.001)
	var limit := floori((snake.arena_half_extent - cell_size) / cell_size)
	return Vector2i(clampi(grid_position.x, -limit, limit), clampi(grid_position.y, -limit, limit))


func _is_grid_outside_arena(grid_position: Vector2i) -> bool:
	var cell_size := maxf(float(snake.cell_size), 0.001)
	var x := absf(float(grid_position.x) * cell_size)
	var z := absf(float(grid_position.y) * cell_size)
	return x > snake.arena_half_extent or z > snake.arena_half_extent


func _update_countdown(delta: float) -> void:
	if _countdown_time > 0.0:
		_countdown_time = maxf(0.0, _countdown_time - delta)
		if _countdown_time > 0.0:
			_emit_countdown_text(str(int(ceil(_countdown_time))))
			return
		_emit_countdown_text("GO")
		return

	_go_time = maxf(0.0, _go_time - delta)
	if _go_time > 0.0:
		_emit_countdown_text("GO")
		return

	countdown_changed.emit("")
	_set_state(GameState.PLAYING)


func _emit_countdown_text(text: String) -> void:
	if text == _last_countdown_text:
		return
	_last_countdown_text = text
	countdown_changed.emit(text)


func _clear_power_ups() -> void:
	for power_up in power_ups:
		if is_instance_valid(power_up):
			power_up.queue_free()
	power_ups.clear()


func _clear_life_eggs() -> void:
	for egg in life_eggs:
		if is_instance_valid(egg):
			egg.queue_free()
	life_eggs.clear()


func _clear_food() -> void:
	if food != null and is_instance_valid(food):
		food.queue_free()
	food = null


func cleanup_runtime_objects() -> void:
	_clear_food()
	_clear_power_ups()
	_clear_life_eggs()
	if effects != null and is_instance_valid(effects):
		effects.cleanup_runtime_objects()
	if audio_manager != null and is_instance_valid(audio_manager):
		audio_manager.cleanup_runtime_objects()


func _reset_effects() -> void:
	_effect_timers["speed"] = 0.0
	_effect_timers["shield"] = 0.0
	_effect_timers["magnet"] = 0.0
	if snake != null:
		snake.set_speed_multiplier(1.0)
		snake.set_shield_enabled(false)
		snake.set_magnet_enabled(false)


func _game_over(reason: String) -> void:
	snake.set_alive(false)
	camera_controller.shake(0.55)
	effects.crash_burst(snake.get_head_position())
	audio_manager.play_crash()
	_set_state(GameState.GAME_OVER)
	print("Game over: %s. Score: %d" % [reason, score])


func _get_power_up_color(power_type: int) -> Color:
	match power_type:
		PowerUpScript.PowerType.SPEED:
			return Color(1.0, 0.72, 0.1)
		PowerUpScript.PowerType.SHIELD:
			return Color(0.12, 0.6, 1.0)
		PowerUpScript.PowerType.MAGNET:
			return Color(0.78, 0.2, 1.0)
		PowerUpScript.PowerType.BONUS:
			return Color(0.4, 1.0, 0.35)
	return Color.WHITE


func _set_state(new_state: GameState) -> void:
	state = new_state
	if snake != null:
		snake.set_paused(state != GameState.PLAYING)
	match state:
		GameState.MENU:
			state_changed.emit("MENU")
		GameState.COUNTDOWN:
			state_changed.emit("COUNTDOWN")
		GameState.PLAYING:
			state_changed.emit("PLAYING")
		GameState.PAUSED:
			state_changed.emit("PAUSED")
		GameState.GAME_OVER:
			state_changed.emit("GAME_OVER")


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = int(config.get_value("scores", "high_score", 0))
		brightness = clampf(float(config.get_value("settings", "brightness", DEFAULT_BRIGHTNESS)), 0.5, 2.0)


func _save_high_score() -> void:
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("scores", "high_score", high_score)
	config.set_value("settings", "brightness", brightness)
	config.save(SAVE_PATH)


func get_effect_status() -> Dictionary:
	return {
		"speed": float(_effect_timers["speed"]),
		"shield": float(_effect_timers["shield"]),
		"magnet": float(_effect_timers["magnet"]),
	}


func get_lives() -> int:
	return current_lives


func get_max_lives() -> int:
	return max_lives
