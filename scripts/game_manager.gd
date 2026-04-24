extends Node3D
class_name GameManager

signal score_changed(score: int, high_score: int)
signal state_changed(state_name: String)

const SAVE_PATH := "user://neon_serpent.cfg"

enum GameState { PLAYING, PAUSED, GAME_OVER }

var snake: SnakeController
var camera_controller: CameraController
var arena: ArenaBuilder
var effects: EffectsManager
var ui_manager: UIManager
var audio_manager: AudioManager
var food: Food
var power_ups: Array[PowerUp] = []
var score: int = 0
var high_score: int = 0
var state: GameState = GameState.PLAYING
var run_time: float = 0.0

var _rng := RandomNumberGenerator.new()
var _next_power_up_time: float = 8.0
var _effect_timers := {
	"speed": 0.0,
	"shield": 0.0,
	"magnet": 0.0,
}


func _ready() -> void:
	_rng.randomize()
	_load_high_score()
	_create_core_systems()
	start_new_game()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		start_new_game()
		return
	if Input.is_action_just_pressed("pause_game") and state != GameState.GAME_OVER:
		_set_state(GameState.PAUSED if state == GameState.PLAYING else GameState.PLAYING)

	if state != GameState.PLAYING:
		return

	run_time += delta
	_update_effects(delta)
	_update_power_ups(delta)
	_apply_magnet(delta)
	_check_food_collection()
	_check_collisions()


func start_new_game() -> void:
	score = 0
	run_time = 0.0
	_next_power_up_time = 7.5
	_clear_power_ups()
	_reset_effects()
	_set_state(GameState.PLAYING)
	snake.reset(Vector3.ZERO)
	_spawn_food()
	if audio_manager != null:
		audio_manager.play_start()
	score_changed.emit(score, high_score)


func _create_core_systems() -> void:
	arena = ArenaBuilder.new()
	arena.name = "ArenaBuilder"
	add_child(arena)

	snake = SnakeController.new()
	snake.name = "SnakeController"
	snake.arena_half_extent = arena.arena_half_extent - 0.45
	add_child(snake)

	camera_controller = CameraController.new()
	camera_controller.name = "CameraController"
	add_child(camera_controller)
	camera_controller.set_target(snake)

	effects = EffectsManager.new()
	effects.name = "EffectsManager"
	add_child(effects)

	ui_manager = UIManager.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.setup(self)

	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)


func _check_food_collection() -> void:
	if food == null:
		_spawn_food()
		return
	var distance := snake.get_head_position().distance_to(food.global_position)
	if distance <= food.collect_radius:
		_collect_food()


func _check_collisions() -> void:
	if snake.is_outside_arena():
		if snake.has_shield():
			_break_shield()
			snake.deflect_from_boundary()
			return
		_game_over("Boundary breach")
		return
	if snake.collides_with_self():
		if snake.has_shield():
			_break_shield()
			snake.shrink(2)
			return
		_game_over("Signal feedback")


func _collect_food() -> void:
	if food == null:
		return
	var earned := food.point_value + int(snake.get_length() * 0.5)
	var collected_position := food.global_position
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
		var power_up := power_ups[i]
		if not is_instance_valid(power_up):
			power_ups.remove_at(i)
			continue
		if snake.get_head_position().distance_to(power_up.global_position) <= power_up.collect_radius:
			_collect_power_up(power_up)
			power_ups.remove_at(i)


func _spawn_power_up() -> void:
	var power_up := PowerUp.new()
	power_up.name = "PowerUp"
	var roll := _rng.randi_range(0, 3)
	power_up.configure(roll)
	add_child(power_up)
	power_up.position = _find_clear_spawn_position()
	power_ups.append(power_up)


func _collect_power_up(power_up: PowerUp) -> void:
	match power_up.power_type:
		PowerUp.PowerType.SPEED:
			_effect_timers["speed"] = 7.5
			snake.set_speed_multiplier(1.48)
		PowerUp.PowerType.SHIELD:
			_effect_timers["shield"] = 9.0
			snake.set_shield_enabled(true)
		PowerUp.PowerType.MAGNET:
			_effect_timers["magnet"] = 10.0
			snake.set_magnet_enabled(true)
		PowerUp.PowerType.BONUS:
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
	var to_snake := snake.get_head_position() - food.global_position
	if to_snake.length() > 8.5:
		return
	food.global_position += to_snake.normalized() * 5.8 * delta


func _break_shield() -> void:
	_effect_timers["shield"] = 0.0
	snake.consume_shield()
	camera_controller.shake(0.42)
	effects.shield_break(snake.get_head_position())
	audio_manager.play_shield_break()


func _spawn_food() -> void:
	if food != null:
		food.queue_free()

	food = Food.new()
	food.name = "Food"
	add_child(food)
	food.position = _find_clear_spawn_position()
	food.configure(10 + int(run_time / 18.0), Color(1.0, 0.15 + _rng.randf() * 0.2, 0.55 + _rng.randf() * 0.35))


func _find_clear_spawn_position() -> Vector3:
	for attempt in range(80):
		var candidate := arena.get_random_play_position(2.0)
		if candidate.distance_to(snake.get_head_position()) < 3.8:
			continue
		var clear := true
		for body_position in snake.get_body_positions():
			if candidate.distance_to(body_position) < 2.0:
				clear = false
				break
		if clear:
			return candidate
	return arena.get_random_play_position(2.5)


func _clear_power_ups() -> void:
	for power_up in power_ups:
		if is_instance_valid(power_up):
			power_up.queue_free()
	power_ups.clear()


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
		PowerUp.PowerType.SPEED:
			return Color(1.0, 0.72, 0.1)
		PowerUp.PowerType.SHIELD:
			return Color(0.12, 0.6, 1.0)
		PowerUp.PowerType.MAGNET:
			return Color(0.78, 0.2, 1.0)
		PowerUp.PowerType.BONUS:
			return Color(0.4, 1.0, 0.35)
	return Color.WHITE


func _set_state(new_state: GameState) -> void:
	state = new_state
	if snake != null:
		snake.set_paused(state == GameState.PAUSED)
	match state:
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


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)


func get_effect_status() -> Dictionary:
	return {
		"speed": float(_effect_timers["speed"]),
		"shield": float(_effect_timers["shield"]),
		"magnet": float(_effect_timers["magnet"]),
	}
