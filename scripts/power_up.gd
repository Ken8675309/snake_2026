extends Node3D
class_name PowerUp

enum PowerType { SPEED, SHIELD, MAGNET, BONUS }

@export var collect_radius: float = 0.92
@export var power_type: int = PowerType.SPEED

var _time: float = 0.0
var _core: MeshInstance3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _light: OmniLight3D
var _material: StandardMaterial3D
var _base_y: float = 0.7


func _ready() -> void:
	_build_visual()
	_base_y = position.y
	_apply_type_visual()


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 2.7) * 0.14
	_core.rotation.y += delta * 1.5
	_ring_a.rotation.y += delta * 2.4
	_ring_b.rotation.x += delta * 2.0
	var pulse := 1.0 + sin(_time * 5.0) * 0.07
	_core.scale = Vector3.ONE * pulse
	_light.light_energy = 1.2 + sin(_time * 4.0) * 0.25


func configure(new_type: int) -> void:
	power_type = new_type
	if _material == null:
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
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 2.2
	_material.metallic = 0.15
	_material.roughness = 0.14

	_core = MeshInstance3D.new()
	_core.name = "PowerCore"
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.62, 0.62, 0.62)
	_core.mesh = core_mesh
	_core.material_override = _material
	add_child(_core)

	_ring_a = _make_ring("PowerRingA", 0.63)
	_ring_a.rotation_degrees.x = 90.0
	add_child(_ring_a)

	_ring_b = _make_ring("PowerRingB", 0.78)
	_ring_b.rotation_degrees.z = 90.0
	add_child(_ring_b)

	_light = OmniLight3D.new()
	_light.name = "PowerLight"
	_light.omni_range = 4.8
	add_child(_light)


func _make_ring(ring_name: String, radius: float) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = ring_name
	var torus := TorusMesh.new()
	torus.inner_radius = radius
	torus.outer_radius = radius + 0.035
	torus.ring_segments = 48
	torus.rings = 6
	ring.mesh = torus
	ring.material_override = _material
	return ring


func _apply_type_visual() -> void:
	var color := Color(0.2, 0.8, 1.0)
	match power_type:
		PowerType.SPEED:
			color = Color(1.0, 0.72, 0.1)
		PowerType.SHIELD:
			color = Color(0.12, 0.6, 1.0)
		PowerType.MAGNET:
			color = Color(0.78, 0.2, 1.0)
		PowerType.BONUS:
			color = Color(0.4, 1.0, 0.35)
	_material.albedo_color = color
	_material.emission = color
	if _light != null:
		_light.light_color = color
