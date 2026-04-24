extends Node3D
class_name Food

@export var point_value: int = 10
@export var collect_radius: float = 0.82
@export var bob_height: float = 0.16
@export var bob_speed: float = 3.2

var _base_y: float = 0.65
var _time: float = 0.0
var _fruit: MeshInstance3D
var _stem: MeshInstance3D
var _leaf: MeshInstance3D
var _fruit_material: StandardMaterial3D
var _stem_material: StandardMaterial3D
var _leaf_material: StandardMaterial3D


func _ready() -> void:
	_build_visual()
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	rotation.y += delta * 0.95
	position.y = _base_y + sin(_time * bob_speed) * bob_height
	var pulse := 1.0 + sin(_time * 4.0) * 0.035
	_fruit.scale = Vector3(1.0, 0.92, 1.0) * pulse


func configure(value: int, color: Color) -> void:
	point_value = value
	if _fruit_material == null:
		_build_materials(color)
	else:
		_fruit_material.albedo_color = color.lerp(Color(0.95, 0.18, 0.12), 0.45)


func _build_visual() -> void:
	if _fruit != null:
		return
	if _fruit_material == null:
		_build_materials(Color(0.95, 0.18, 0.12))

	_fruit = MeshInstance3D.new()
	_fruit.name = "FruitBody"
	var fruit_mesh := SphereMesh.new()
	fruit_mesh.radius = 0.38
	fruit_mesh.height = 0.74
	fruit_mesh.radial_segments = 28
	fruit_mesh.rings = 14
	_fruit.mesh = fruit_mesh
	_fruit.scale = Vector3(1.0, 0.92, 1.0)
	_fruit.material_override = _fruit_material
	add_child(_fruit)

	_stem = MeshInstance3D.new()
	_stem.name = "FruitStem"
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.035
	stem_mesh.bottom_radius = 0.045
	stem_mesh.height = 0.24
	stem_mesh.radial_segments = 8
	_stem.mesh = stem_mesh
	_stem.position = Vector3(0.0, 0.42, 0.0)
	_stem.rotation_degrees.z = 10.0
	_stem.material_override = _stem_material
	add_child(_stem)

	_leaf = MeshInstance3D.new()
	_leaf.name = "FruitLeaf"
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.16
	leaf_mesh.height = 0.08
	leaf_mesh.radial_segments = 12
	leaf_mesh.rings = 6
	_leaf.mesh = leaf_mesh
	_leaf.position = Vector3(0.12, 0.47, 0.02)
	_leaf.scale = Vector3(1.45, 0.28, 0.65)
	_leaf.rotation_degrees = Vector3(0.0, 18.0, -28.0)
	_leaf.material_override = _leaf_material
	add_child(_leaf)


func _build_materials(color: Color) -> void:
	_fruit_material = StandardMaterial3D.new()
	_fruit_material.albedo_color = color.lerp(Color(0.95, 0.18, 0.12), 0.45)
	_fruit_material.metallic = 0.0
	_fruit_material.roughness = 0.38

	_stem_material = StandardMaterial3D.new()
	_stem_material.albedo_color = Color(0.35, 0.2, 0.08)
	_stem_material.roughness = 0.62

	_leaf_material = StandardMaterial3D.new()
	_leaf_material.albedo_color = Color(0.26, 0.58, 0.2)
	_leaf_material.roughness = 0.55
