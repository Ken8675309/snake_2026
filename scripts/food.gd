extends Node3D
class_name Food

@export var point_value: int = 10
@export var collect_radius: float = 0.82
@export var bob_height: float = 0.18
@export var bob_speed: float = 3.6

var _base_y: float = 0.55
var _time: float = 0.0
var _mesh: MeshInstance3D
var _light: OmniLight3D
var _material: StandardMaterial3D


func _ready() -> void:
	_build_visual()
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	rotation.y += delta * 1.8
	position.y = _base_y + sin(_time * bob_speed) * bob_height
	var pulse := 1.0 + sin(_time * 5.8) * 0.08
	_mesh.scale = Vector3.ONE * pulse
	_light.light_energy = 1.7 + sin(_time * 5.8) * 0.35


func configure(value: int, color: Color) -> void:
	point_value = value
	if _material == null:
		_build_material(color)
	else:
		_material.albedo_color = color
		_material.emission = color
	if _light != null:
		_light.light_color = color


func _build_visual() -> void:
	if _mesh != null:
		return
	if _material == null:
		_build_material(Color(1.0, 0.18, 0.5))

	_mesh = MeshInstance3D.new()
	_mesh.name = "FoodCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.72
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	_mesh.material_override = _material
	add_child(_mesh)

	var ring := MeshInstance3D.new()
	ring.name = "FoodHalo"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.49
	torus.ring_segments = 48
	torus.sides = 8
	ring.mesh = torus
	ring.material_override = _material
	ring.rotation_degrees.x = 90.0
	add_child(ring)

	_light = OmniLight3D.new()
	_light.name = "FoodLight"
	_light.light_color = _material.emission
	_light.light_energy = 1.8
	_light.omni_range = 4.5
	add_child(_light)


func _build_material(color: Color) -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = 2.7
	_material.metallic = 0.1
	_material.roughness = 0.12
