extends Node3D
class_name PowerUp

enum PowerType { SPEED, SHIELD, MAGNET, BONUS }

@export var collect_radius: float = 0.92
@export var power_type: int = PowerType.SPEED

var _time: float = 0.0
var _core: MeshInstance3D
var _rim: MeshInstance3D
var _mark: MeshInstance3D
var _material: StandardMaterial3D
var _rim_material: StandardMaterial3D
var _mark_material: StandardMaterial3D
var _base_y: float = 0.76


func _ready() -> void:
	_build_visual()
	_base_y = position.y
	_apply_type_visual()


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 2.5) * 0.12
	rotation.y += delta * 0.9
	var pulse := 1.0 + sin(_time * 3.8) * 0.035
	_core.scale = Vector3(1.0, 0.22, 1.0) * pulse


func configure(new_type: int) -> void:
	power_type = new_type
	if _core == null:
		_build_visual()
	_apply_type_visual()


func get_display_name() -> String:
	match power_type:
		PowerType.SPEED:
			return "Overdrive"
		PowerType.SHIELD:
			return "Shield"
		PowerType.MAGNET:
			return "Magnet"
		PowerType.BONUS:
			return "Bonus"
	return "Power"


func _build_visual() -> void:
	if _core != null:
		return

	_material = StandardMaterial3D.new()
	_material.roughness = 0.42
	_material.metallic = 0.0

	_rim_material = StandardMaterial3D.new()
	_rim_material.albedo_color = Color(0.96, 0.88, 0.58)
	_rim_material.roughness = 0.36
	_rim_material.metallic = 0.05

	_mark_material = StandardMaterial3D.new()
	_mark_material.roughness = 0.5

	_core = MeshInstance3D.new()
	_core.name = "PowerTokenCore"
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.52
	core_mesh.bottom_radius = 0.52
	core_mesh.height = 0.18
	core_mesh.radial_segments = 18
	_core.mesh = core_mesh
	_core.scale = Vector3(1.0, 0.22, 1.0)
	_core.material_override = _material
	add_child(_core)

	_rim = MeshInstance3D.new()
	_rim.name = "PowerTokenRim"
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.5
	rim_mesh.outer_radius = 0.56
	rim_mesh.ring_segments = 28
	rim_mesh.rings = 6
	_rim.mesh = rim_mesh
	_rim.material_override = _rim_material
	add_child(_rim)

	_mark = MeshInstance3D.new()
	_mark.name = "PowerTokenMark"
	var mark_mesh := BoxMesh.new()
	mark_mesh.size = Vector3(0.5, 0.035, 0.14)
	_mark.mesh = mark_mesh
	_mark.position = Vector3(0.0, 0.13, 0.0)
	_mark.material_override = _mark_material
	add_child(_mark)


func _apply_type_visual() -> void:
	var color := Color(0.38, 0.72, 1.0)
	var mark_color := Color(0.12, 0.24, 0.38)
	match power_type:
		PowerType.SPEED:
			color = Color(0.96, 0.58, 0.18)
			mark_color = Color(0.45, 0.18, 0.04)
			_mark.rotation_degrees.y = 0.0
		PowerType.SHIELD:
			color = Color(0.38, 0.7, 1.0)
			mark_color = Color(0.08, 0.24, 0.44)
			_mark.rotation_degrees.y = 90.0
		PowerType.MAGNET:
			color = Color(0.76, 0.42, 0.92)
			mark_color = Color(0.28, 0.1, 0.36)
			_mark.rotation_degrees.y = 45.0
		PowerType.BONUS:
			color = Color(0.46, 0.82, 0.28)
			mark_color = Color(0.12, 0.34, 0.08)
			_mark.rotation_degrees.y = -45.0
	_material.albedo_color = color
	_mark_material.albedo_color = mark_color
