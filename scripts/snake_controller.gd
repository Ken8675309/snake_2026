extends Node3D
class_name SnakeController

signal direction_changed(direction: Vector3)

@export var move_speed: float = 7.5
@export var boosted_speed: float = 11.0
@export var turn_responsiveness: float = 14.0
@export var segment_spacing: float = 0.62
@export var initial_segments: int = 12
@export var segment_radius: float = 0.34
@export var body_height: float = 0.42
@export var arena_half_extent: float = 13.5
@export var body_length_scale: float = 1.55
@export var body_width_scale: float = 0.78
@export var body_vertical_scale: float = 0.62
@export var wave_height: float = 0.055
@export var wave_roll_degrees: float = 4.5
@export var head_length_scale: float = 1.48
@export var head_width_scale: float = 1.08

var is_alive: bool = true
var is_paused: bool = false
var speed_multiplier: float = 1.0
var magnet_enabled: bool = false
var shield_enabled: bool = false

var _target_direction: Vector3 = Vector3.FORWARD
var _visual_direction: Vector3 = Vector3.FORWARD
var _last_cardinal_direction: Vector3 = Vector3.FORWARD
var _distance_travelled: float = 0.0
var _path_points: Array[Vector3] = []
var _segments: Array[MeshInstance3D] = []

var _head_root: Node3D
var _head_mesh: MeshInstance3D
var _body_root: Node3D
var _trail_root: Node3D
var _shield_visual: MeshInstance3D
var _head_material: StandardMaterial3D
var _body_material: StandardMaterial3D
var _eye_material: StandardMaterial3D
var _trail_material: StandardMaterial3D
var _shield_material: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_nodes()
	reset(Vector3.ZERO)


func _physics_process(delta: float) -> void:
	if not is_alive or is_paused:
		return

	_read_movement_input()
	var effective_speed := move_speed * speed_multiplier
	var old_position := _head_root.global_position
	_visual_direction = _smooth_visual_direction(delta)
	var new_position := old_position + _visual_direction * effective_speed * delta
	new_position.y = body_height
	_head_root.global_position = new_position
	_distance_travelled += old_position.distance_to(new_position)
	_record_path_point(new_position)
	_update_body(delta)
	_update_head_visual()
	_update_trail()
	_update_effect_visuals(delta)


func reset(start_position: Vector3) -> void:
	is_alive = true
	is_paused = false
	speed_multiplier = 1.0
	magnet_enabled = false
	shield_enabled = false
	_target_direction = Vector3.FORWARD
	_visual_direction = Vector3.FORWARD
	_last_cardinal_direction = Vector3.FORWARD
	_distance_travelled = 0.0

	start_position.y = body_height
	_head_root.global_position = start_position
	_path_points.clear()
	for i in range(initial_segments * 3):
		_path_points.append(start_position - Vector3.FORWARD * float(i) * segment_spacing * 0.5)

	_set_segment_count(initial_segments)
	for i in range(_segments.size()):
		_segments[i].global_position = _sample_path(float(i + 1) * segment_spacing)
	_update_body(1.0)
	_update_head_visual()
	_update_trail()
	_update_effect_visuals(1.0)


func set_alive(value: bool) -> void:
	is_alive = value


func set_paused(value: bool) -> void:
	is_paused = value


func set_speed_multiplier(value: float) -> void:
	speed_multiplier = maxf(value, 0.35)


func set_magnet_enabled(value: bool) -> void:
	magnet_enabled = value


func set_shield_enabled(value: bool) -> void:
	shield_enabled = value


func has_shield() -> bool:
	return shield_enabled


func consume_shield() -> void:
	shield_enabled = false


func deflect_from_boundary() -> void:
	var p := _head_root.global_position
	p.x = clampf(p.x, -arena_half_extent + 0.35, arena_half_extent - 0.35)
	p.z = clampf(p.z, -arena_half_extent + 0.35, arena_half_extent - 0.35)
	_head_root.global_position = p

	if absf(p.x) > arena_half_extent - 0.8:
		_target_direction = Vector3.LEFT if p.x > 0.0 else Vector3.RIGHT
	elif absf(p.z) > arena_half_extent - 0.8:
		_target_direction = Vector3.FORWARD if p.z > 0.0 else Vector3.BACK
	_visual_direction = _target_direction
	_last_cardinal_direction = _target_direction
	_record_path_point(p)


func grow(amount: int = 2) -> void:
	_set_segment_count(_segments.size() + max(amount, 1))


func shrink(amount: int = 1) -> void:
	_set_segment_count(max(initial_segments, _segments.size() - amount))


func get_head_position() -> Vector3:
	return _head_root.global_position


func get_direction() -> Vector3:
	return _visual_direction


func get_length() -> int:
	return _segments.size()


func get_body_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for segment in _segments:
		positions.append(segment.global_position)
	return positions


func collides_with_self(hit_radius: float = 0.48, skip_segments: int = 5) -> bool:
	var head_position := get_head_position()
	for i in range(skip_segments, _segments.size()):
		if head_position.distance_to(_segments[i].global_position) <= hit_radius:
			return true
	return false


func is_outside_arena(margin: float = 0.0) -> bool:
	var p := get_head_position()
	return absf(p.x) > arena_half_extent + margin or absf(p.z) > arena_half_extent + margin


func _read_movement_input() -> void:
	var requested := Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		requested = Vector3.FORWARD
	elif Input.is_action_pressed("move_down"):
		requested = Vector3.BACK
	elif Input.is_action_pressed("move_left"):
		requested = Vector3.LEFT
	elif Input.is_action_pressed("move_right"):
		requested = Vector3.RIGHT

	if requested == Vector3.ZERO:
		return
	if requested.dot(_last_cardinal_direction) < -0.4:
		return
	_target_direction = requested.normalized()
	_last_cardinal_direction = requested.normalized()
	direction_changed.emit(_target_direction)


func _smooth_visual_direction(delta: float) -> Vector3:
	var current := _safe_direction(_visual_direction)
	var target := _safe_direction(_target_direction)
	var blend := clampf(turn_responsiveness * delta, 0.0, 1.0)
	var signed_angle := current.signed_angle_to(target, Vector3.UP.normalized())
	if absf(signed_angle) < 0.0001:
		return target

	var axis := Vector3.UP.normalized()
	if axis.length_squared() < 0.0001:
		axis = Vector3.UP
	var rotated_direction := current.rotated(axis, signed_angle * blend)
	return _safe_direction(rotated_direction)


func _safe_direction(direction: Vector3) -> Vector3:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return Vector3.FORWARD
	return direction.normalized()


func _record_path_point(point: Vector3) -> void:
	if _path_points.is_empty() or point.distance_to(_path_points[0]) >= 0.045:
		_path_points.insert(0, point)

	var max_distance := float(_segments.size() + 8) * segment_spacing
	var accumulated := 0.0
	var keep_count := _path_points.size()
	for i in range(1, _path_points.size()):
		accumulated += _path_points[i - 1].distance_to(_path_points[i])
		if accumulated > max_distance:
			keep_count = i + 1
			break
	while _path_points.size() > keep_count:
		_path_points.pop_back()


func _sample_path(distance_back: float) -> Vector3:
	if _path_points.is_empty():
		return _head_root.global_position

	var remaining := distance_back
	for i in range(1, _path_points.size()):
		var a := _path_points[i - 1]
		var b := _path_points[i]
		var segment_length := a.distance_to(b)
		if segment_length >= remaining:
			return a.lerp(b, remaining / maxf(segment_length, 0.001))
		remaining -= segment_length
	return _path_points[_path_points.size() - 1]


func _update_body(delta: float) -> void:
	for i in range(_segments.size()):
		var segment := _segments[i]
		var target_position := _sample_path(float(i + 1) * segment_spacing)
		var wave := sin((_distance_travelled * 2.35) - float(i) * 0.58) * wave_height
		target_position.y = body_height + wave
		segment.global_position = segment.global_position.lerp(target_position, clampf(18.0 * delta, 0.0, 1.0))

		var look_target := _sample_path(float(i) * segment_spacing)
		look_target.y = segment.global_position.y
		if segment.global_position.distance_squared_to(look_target) > 0.0001:
			segment.look_at(look_target, Vector3.UP.normalized(), true)

		var taper := 1.0 - clampf(float(i) / maxf(float(_segments.size()), 1.0), 0.0, 1.0) * 0.42
		var pulse := 1.0 + sin((_distance_travelled * 3.0) - float(i) * 0.8) * 0.035
		var radius := segment_radius * taper * pulse
		segment.scale = Vector3(
			radius * body_width_scale,
			radius * body_vertical_scale,
			radius * body_length_scale
		)
		segment.rotation_degrees.z = sin((_distance_travelled * 2.4) - float(i) * 0.62) * wave_roll_degrees


func _update_head_visual() -> void:
	var look_target := _head_root.global_position + _visual_direction
	look_target.y = _head_root.global_position.y
	_head_root.look_at(look_target, Vector3.UP.normalized(), true)
	var pulse := 1.0 + sin(_distance_travelled * 3.8) * 0.025
	var head_radius := segment_radius * 1.2 * pulse
	_head_mesh.scale = Vector3(
		head_radius * head_width_scale,
		head_radius * 0.86,
		head_radius * head_length_scale
	)


func _update_trail() -> void:
	for i in range(_trail_root.get_child_count()):
		var trail_piece := _trail_root.get_child(i) as MeshInstance3D
		var sample := _sample_path(float(i + 1) * segment_spacing * 1.15)
		sample.y = 0.065
		trail_piece.global_position = sample
		var width := 1.2 - float(i) * 0.09
		trail_piece.scale = Vector3(maxf(width, 0.2), 0.018, 0.22)
		trail_piece.transparency = clampf(float(i) / float(max(_trail_root.get_child_count(), 1)), 0.0, 1.0)


func _set_segment_count(count: int) -> void:
	while _segments.size() < count:
		_segments.append(_create_body_segment(_segments.size()))
	while _segments.size() > count:
		var segment = _segments.pop_back()
		segment.queue_free()


func _create_body_segment(index: int) -> MeshInstance3D:
	var segment := MeshInstance3D.new()
	segment.name = "BodySegment%02d" % index
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 36
	mesh.rings = 18
	segment.mesh = mesh
	segment.material_override = _body_material
	segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_body_root.add_child(segment)
	return segment


func _build_nodes() -> void:
	_head_root = Node3D.new()
	_head_root.name = "Head"
	add_child(_head_root)

	_head_mesh = MeshInstance3D.new()
	_head_mesh.name = "HeadMesh"
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 1.0
	head_sphere.height = 2.0
	head_sphere.radial_segments = 48
	head_sphere.rings = 24
	_head_mesh.mesh = head_sphere
	_head_mesh.material_override = _head_material
	_head_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_head_root.add_child(_head_mesh)

	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.name = "Eye"
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.07
		eye_mesh.height = 0.14
		eye_mesh.radial_segments = 16
		eye_mesh.rings = 8
		eye.mesh = eye_mesh
		eye.material_override = _eye_material
		eye.position = Vector3(side * 0.19, 0.13, -0.39)
		eye.scale = Vector3(1.0, 0.85, 1.35)
		_head_root.add_child(eye)

	_body_root = Node3D.new()
	_body_root.name = "Body"
	add_child(_body_root)

	_trail_root = Node3D.new()
	_trail_root.name = "MotionTrail"
	add_child(_trail_root)
	for i in range(10):
		var trail_piece := MeshInstance3D.new()
		trail_piece.name = "Trail%02d" % i
		var trail_mesh := BoxMesh.new()
		trail_mesh.size = Vector3.ONE
		trail_piece.mesh = trail_mesh
		trail_piece.material_override = _trail_material
		trail_piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_trail_root.add_child(trail_piece)

	_shield_visual = MeshInstance3D.new()
	_shield_visual.name = "ShieldVisual"
	var shield_mesh := SphereMesh.new()
	shield_mesh.radius = 0.72
	shield_mesh.height = 1.44
	shield_mesh.radial_segments = 48
	shield_mesh.rings = 24
	_shield_visual.mesh = shield_mesh
	_shield_visual.material_override = _shield_material
	_shield_visual.visible = false
	_head_root.add_child(_shield_visual)


func _build_materials() -> void:
	_head_material = StandardMaterial3D.new()
	_head_material.albedo_color = Color(0.014, 0.16, 0.13, 1.0)
	_head_material.emission_enabled = true
	_head_material.emission = Color(0.0, 0.17, 0.13)
	_head_material.emission_energy_multiplier = 0.55
	_head_material.metallic = 0.05
	_head_material.roughness = 0.16
	_head_material.normal_enabled = true
	_head_material.normal_scale = 0.07
	_head_material.normal_texture = _make_skin_noise_texture(0.18, 3)

	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color(0.012, 0.095, 0.105, 1.0)
	_body_material.emission_enabled = true
	_body_material.emission = Color(0.0, 0.08, 0.12)
	_body_material.emission_energy_multiplier = 0.32
	_body_material.metallic = 0.08
	_body_material.roughness = 0.14
	_body_material.normal_enabled = true
	_body_material.normal_scale = 0.09
	_body_material.normal_texture = _make_skin_noise_texture(0.22, 4)
	_body_material.roughness_texture = _make_skin_noise_texture(0.11, 5)

	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = Color(0.65, 1.0, 0.38, 1.0)
	_eye_material.emission_enabled = true
	_eye_material.emission = Color(0.46, 1.0, 0.18)
	_eye_material.emission_energy_multiplier = 3.4
	_eye_material.roughness = 0.1

	_trail_material = StandardMaterial3D.new()
	_trail_material.albedo_color = Color(0.0, 0.95, 0.9, 0.25)
	_trail_material.emission_enabled = true
	_trail_material.emission = Color(0.0, 0.65, 0.9)
	_trail_material.emission_energy_multiplier = 0.55
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_trail_material.no_depth_test = false

	_shield_material = StandardMaterial3D.new()
	_shield_material.albedo_color = Color(0.15, 0.65, 1.0, 0.22)
	_shield_material.emission_enabled = true
	_shield_material.emission = Color(0.1, 0.62, 1.0)
	_shield_material.emission_energy_multiplier = 0.95
	_shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD


func _update_effect_visuals(delta: float) -> void:
	_shield_visual.visible = shield_enabled
	if shield_enabled:
		_shield_visual.rotate_y(delta * 1.7)
		var pulse := 1.0 + sin(_distance_travelled * 3.0) * 0.045
		_shield_visual.scale = Vector3.ONE * pulse

	var boost_energy := 1.0 if speed_multiplier > 1.05 else 0.0
	_head_material.emission_energy_multiplier = lerpf(_head_material.emission_energy_multiplier, 0.55 + boost_energy * 1.0, clampf(delta * 8.0, 0.0, 1.0))
	_body_material.emission_energy_multiplier = lerpf(_body_material.emission_energy_multiplier, 0.32 + boost_energy * 0.65, clampf(delta * 8.0, 0.0, 1.0))


func _make_skin_noise_texture(frequency: float, octaves: int) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.0

	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	return texture
