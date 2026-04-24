extends Node3D
class_name CameraController

@export var follow_distance: float = 18.0
@export var follow_height: float = 16.0
@export var look_ahead: float = 3.2
@export var smoothness: float = 5.4
@export var base_fov: float = 55.0
@export var zoom_speed_influence: float = 1.2
@export var shake_decay: float = 7.5
@export var target_lag: float = 5.0
@export var mouse_sensitivity: float = 0.008
@export var wheel_zoom_step: float = 1.8
@export var min_zoom_distance: float = 10.0
@export var max_zoom_distance: float = 42.0
@export var min_pitch_degrees: float = 24.0
@export var max_pitch_degrees: float = 68.0

var target: Node3D
var _camera: Camera3D
var _shake_strength: float = 0.0
var _shake_seed: float = 0.0
var _last_target_position: Vector3 = Vector3.ZERO
var _smoothed_target_position: Vector3 = Vector3.ZERO
var _target_speed: float = 0.0
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.0
var _orbit_distance: float = 0.0
var _dragging_camera: bool = false


func _ready() -> void:
	_reset_orbit_values()
	_camera = Camera3D.new()
	_camera.name = "GameCamera"
	_camera.current = true
	_camera.fov = base_fov
	_camera.near = 0.05
	_camera.far = 260.0
	add_child(_camera)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_dragging_camera = mouse_button.pressed
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_distance = clampf(_orbit_distance - wheel_zoom_step, min_zoom_distance, max_zoom_distance)
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_distance = clampf(_orbit_distance + wheel_zoom_step, min_zoom_distance, max_zoom_distance)
	elif event is InputEventMouseMotion and _dragging_camera:
		var motion := event as InputEventMouseMotion
		_orbit_yaw -= motion.relative.x * mouse_sensitivity
		_orbit_pitch = clampf(
			_orbit_pitch - motion.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)


func _process(delta: float) -> void:
	if target == null:
		return
	if Input.is_key_pressed(KEY_C):
		_reset_orbit_values()

	var target_position := _get_target_position()
	_target_speed = lerpf(_target_speed, target_position.distance_to(_last_target_position) / maxf(delta, 0.001), 0.12)
	_last_target_position = target_position
	_smoothed_target_position = _smoothed_target_position.lerp(target_position, clampf(target_lag * delta, 0.0, 1.0))

	var desired_offset := _get_orbit_offset()
	var desired_position := _smoothed_target_position + desired_offset
	global_position = global_position.lerp(desired_position, clampf(smoothness * delta, 0.0, 1.0))

	var look_position := _smoothed_target_position + _get_target_forward() * look_ahead
	look_position.y = 0.25
	look_at(look_position, Vector3.UP.normalized())

	_shake_seed += delta * 34.0
	_shake_strength = lerpf(_shake_strength, 0.0, clampf(shake_decay * delta, 0.0, 1.0))
	var shake := Vector3(
		sin(_shake_seed * 1.7),
		cos(_shake_seed * 2.1),
		sin(_shake_seed * 2.9)
	) * _shake_strength
	_camera.position = shake
	_camera.fov = lerpf(_camera.fov, base_fov + minf(_target_speed * 0.08, zoom_speed_influence), clampf(4.0 * delta, 0.0, 1.0))


func set_target(new_target: Node3D) -> void:
	target = new_target
	reset_to_target()


func reset_to_target() -> void:
	if target == null:
		return
	_last_target_position = _get_target_position()
	_smoothed_target_position = _last_target_position
	_target_speed = 0.0
	_shake_strength = 0.0
	_reset_orbit_values()
	global_position = _last_target_position + _get_orbit_offset()
	if _camera != null:
		_camera.position = Vector3.ZERO
		_camera.fov = base_fov
	var look_position := _last_target_position + _get_target_forward() * look_ahead
	look_position.y = 0.25
	look_at(look_position, Vector3.UP.normalized())


func shake(strength: float = 0.28) -> void:
	_shake_strength = maxf(_shake_strength, strength)


func _get_target_position() -> Vector3:
	if target.has_method("get_head_position"):
		return target.get_head_position()
	return target.global_position


func _get_target_forward() -> Vector3:
	if target.has_method("get_direction"):
		return target.get_direction()
	return -target.global_transform.basis.z


func _reset_orbit_values() -> void:
	_orbit_yaw = 0.0
	_orbit_distance = clampf(sqrt(follow_distance * follow_distance + follow_height * follow_height), min_zoom_distance, max_zoom_distance)
	_orbit_pitch = clampf(atan2(follow_height, follow_distance), deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))


func _get_orbit_offset() -> Vector3:
	var horizontal := cos(_orbit_pitch) * _orbit_distance
	return Vector3(
		sin(_orbit_yaw) * horizontal,
		sin(_orbit_pitch) * _orbit_distance,
		cos(_orbit_yaw) * horizontal
	)
