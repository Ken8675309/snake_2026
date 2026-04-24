extends Node3D
class_name CameraController

@export var follow_distance: float = 16.5
@export var follow_height: float = 15.0
@export var look_ahead: float = 1.8
@export var smoothness: float = 8.5
@export var base_fov: float = 56.0
@export var zoom_speed_influence: float = 1.2
@export var shake_decay: float = 7.5

var target: Node3D
var _camera: Camera3D
var _shake_strength: float = 0.0
var _shake_seed: float = 0.0
var _last_target_position: Vector3 = Vector3.ZERO
var _target_speed: float = 0.0


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "GameCamera"
	_camera.current = true
	_camera.fov = base_fov
	_camera.near = 0.05
	_camera.far = 120.0
	add_child(_camera)


func _process(delta: float) -> void:
	if target == null:
		return

	var target_position := _get_target_position()
	_target_speed = lerpf(_target_speed, target_position.distance_to(_last_target_position) / maxf(delta, 0.001), 0.12)
	_last_target_position = target_position

	var desired_offset := Vector3(0.0, follow_height, follow_distance)
	var desired_position := target_position + desired_offset
	global_position = global_position.lerp(desired_position, clampf(smoothness * delta, 0.0, 1.0))

	var look_position := target_position + _get_target_forward() * look_ahead
	look_position.y = 0.25
	look_at(look_position, Vector3.UP)

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
	_target_speed = 0.0
	_shake_strength = 0.0
	global_position = _last_target_position + Vector3(0.0, follow_height, follow_distance)
	if _camera != null:
		_camera.position = Vector3.ZERO
		_camera.fov = base_fov
	var look_position := _last_target_position + _get_target_forward() * look_ahead
	look_position.y = 0.25
	look_at(look_position, Vector3.UP)


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
