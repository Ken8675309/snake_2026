extends Node3D
class_name Food

@export var point_value: int = 10
@export var collect_radius: float = 0.82
@export var bob_height: float = 0.18
@export var bob_speed: float = 3.6

var _base_y: float = 0.55
var _time: float = 0.0
var _mesh: MeshInstance3D
var _halo: MeshInstance3D
var _inner_ring: MeshInstance3D
var _light: OmniLight3D
var _aura: GPUParticles3D
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
	_halo.rotation.z += delta * 1.35
	_inner_ring.rotation.x += delta * 2.1
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
	if _aura != null:
		var process := _aura.process_material as ParticleProcessMaterial
		process.color = color


func _build_visual() -> void:
	if _mesh != null:
		return
	if _material == null:
		_build_material(Color(1.0, 0.18, 0.5))

	_mesh = MeshInstance3D.new()
	_mesh.name = "FoodCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	_mesh.material_override = _material
	add_child(_mesh)

	_halo = MeshInstance3D.new()
	_halo.name = "FoodHalo"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.49
	torus.ring_segments = 48
	torus.rings = 8
	_halo.mesh = torus
	_halo.material_override = _material
	_halo.rotation_degrees.x = 90.0
	add_child(_halo)

	_inner_ring = MeshInstance3D.new()
	_inner_ring.name = "FoodInnerRing"
	var inner_torus := TorusMesh.new()
	inner_torus.inner_radius = 0.28
	inner_torus.outer_radius = 0.305
	inner_torus.ring_segments = 40
	inner_torus.rings = 6
	_inner_ring.mesh = inner_torus
	_inner_ring.material_override = _material
	_inner_ring.rotation_degrees.z = 90.0
	add_child(_inner_ring)

	_light = OmniLight3D.new()
	_light.name = "FoodLight"
	_light.light_color = _material.emission
	_light.light_energy = 1.8
	_light.omni_range = 5.3
	add_child(_light)

	_aura = GPUParticles3D.new()
	_aura.name = "FoodAura"
	_aura.amount = 28
	_aura.lifetime = 1.35
	_aura.preprocess = 1.35
	_aura.randomness = 0.72
	_aura.local_coords = true
	_aura.emitting = true
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.5
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 0.08
	process.initial_velocity_max = 0.38
	process.gravity = Vector3.ZERO
	process.scale_min = 0.018
	process.scale_max = 0.055
	process.color = _material.emission
	_aura.process_material = process
	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.055
	draw_mesh.height = 0.11
	draw_mesh.radial_segments = 8
	draw_mesh.rings = 4
	_aura.draw_pass_1 = draw_mesh
	add_child(_aura)


func _build_material(color: Color) -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = 2.7
	_material.metallic = 0.1
	_material.roughness = 0.12
