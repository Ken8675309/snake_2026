extends Node3D
class_name CameraController

@export var follow_distance: float = 15.5
@export var follow_height: float = 13.5
@export var look_ahead: float = 3.2
@export var smoothness: float = 5.4
@export var base_fov: float = 52.0
@export var zoom_speed_influence: float = 1.2
@export var shake_decay: float = 7.5
@export var target_lag: float = 5.0
@export var mouse_sensitivity: float = 0.005
@export var wheel_zoom_step: float = 1.0
@export var min_zoom_distance: float = 3.0
@export var max_zoom_distance: float = 60.0
@export var min_pitch: float = -1.0
@export var max_pitch: float = -0.1
@export var min_camera_height: float = 1.0

var target: Node3D
var dragging: bool = false
var distance: float = 0.0
var rotation_x: float = 0.0
var rotation_y: float = 0.0

var _pivot: Node3D
var _camera: Camera3D
var _shake_strength: float = 0.0
var _shake_seed: float = 0.0
var _last_target_position: Vector3 = Vector3.ZERO
var _smoothed_target_position: Vector3 = Vector3.ZERO
var _target_speed: float = 0.0


func _ready() -> void:
	_reset_camera_values()
	_pivot = Node3D.new()
	_pivot.name = "CameraPivot"
	add_child(_pivot)

	_camera = Camera3D.new()
	_camera.name = "GameCamera"
	_camera.current = true
	_camera.fov = base_fov
	_camera.near = 0.05
	_camera.far = 260.0
	_pivot.add_child(_camera)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			dragging = mouse_button.pressed
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom(-1.0)
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1.0)

	if event is InputEventMouseMotion and dragging:
		var motion := event as InputEventMouseMotion
		rotate_camera(motion.relative)


func _process(delta: float) -> void:
	if target == null:
		return
	if Input.is_key_pressed(KEY_C):
		_reset_camera_values()

	var target_position := _get_target_position()
	_target_speed = lerpf(_target_speed, target_position.distance_to(_last_target_position) / maxf(delta, 0.001), 0.12)
	_last_target_position = target_position
	_smoothed_target_position = _smoothed_target_position.lerp(target_position, clampf(target_lag * delta, 0.0, 1.0))

	var look_position := _smoothed_target_position + _get_target_forward() * look_ahead
	look_position.y = 0.8
	global_position = global_position.lerp(look_position, clampf(smoothness * delta, 0.0, 1.0))
	_pivot.rotation = Vector3(rotation_x, rotation_y, 0.0)

	_shake_seed += delta * 34.0
	_shake_strength = lerpf(_shake_strength, 0.0, clampf(shake_decay * delta, 0.0, 1.0))
	var shake := Vector3(
		sin(_shake_seed * 1.7),
		cos(_shake_seed * 2.1),
		sin(_shake_seed * 2.9)
	) * _shake_strength
	_camera.position = Vector3(0.0, 0.0, distance) + shake
	if _camera.global_position.y < min_camera_height:
		var camera_position := _camera.global_position
		camera_position.y = min_camera_height
		_camera.global_position = camera_position
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
	_reset_camera_values()
	global_position = _last_target_position
	if _pivot != null:
		_pivot.rotation = Vector3(rotation_x, rotation_y, 0.0)
	if _camera != null:
		_camera.position = Vector3(0.0, 0.0, distance)
		_camera.fov = base_fov


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


func rotate_camera(delta: Vector2) -> void:
	rotation_y -= delta.x * mouse_sensitivity
	rotation_x -= delta.y * mouse_sensitivity
	rotation_x = clampf(rotation_x, min_pitch, max_pitch)


func zoom(direction: float) -> void:
	distance += direction * wheel_zoom_step
	distance = clampf(distance, min_zoom_distance, max_zoom_distance)


func _reset_camera_values() -> void:
	rotation_y = 0.0
	rotation_x = clampf(-atan2(follow_height, follow_distance), min_pitch, max_pitch)
	distance = clampf(sqrt(follow_distance * follow_distance + follow_height * follow_height), min_zoom_distance, max_zoom_distance)
