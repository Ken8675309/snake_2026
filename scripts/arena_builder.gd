extends Node3D
class_name ArenaBuilder

@export var arena_half_extent: float = 52.0
@export var platform_depth: float = 3.2
@export var platform_margin: float = 2.4
@export var boundary_height: float = 0.42
@export var boundary_width: float = 0.42
@export var default_brightness: float = 1.2
@export var grass_patch_count: int = 28
@export var stone_count: int = 20

var grass_material: StandardMaterial3D
var grass_light_material: StandardMaterial3D
var grass_dark_material: StandardMaterial3D
var dirt_material: StandardMaterial3D
var rock_material: StandardMaterial3D
var edge_material: StandardMaterial3D
var flower_material: StandardMaterial3D
var _environment: Environment


func _ready() -> void:
	build()


func build() -> void:
	_clear_children()
	_build_materials()
	_build_environment()
	_build_platform()
	_build_boundary()
	_build_surface_detail()
	_build_lighting()


func get_random_play_position(margin: float = 1.5) -> Vector3:
	var usable := arena_half_extent - margin
	return Vector3(randf_range(-usable, usable), 0.62, randf_range(-usable, usable))


func set_brightness(value: float) -> void:
	default_brightness = clampf(value, 0.5, 2.0)
	if _environment == null:
		return
	_environment.tonemap_exposure = 1.02 * default_brightness
	_environment.ambient_light_energy = 0.78 * default_brightness


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _build_materials() -> void:
	grass_material = _make_material(
		Color(0.32, 0.62, 0.24),
		0.0,
		0.58,
		_make_noise_texture(0.055, 4),
		0.06
	)
	grass_light_material = _make_material(Color(0.48, 0.74, 0.32), 0.0, 0.64, _make_noise_texture(0.09, 3), 0.035)
	grass_dark_material = _make_material(Color(0.18, 0.42, 0.19), 0.0, 0.68, _make_noise_texture(0.12, 3), 0.04)
	dirt_material = _make_material(Color(0.42, 0.27, 0.16), 0.0, 0.72, _make_noise_texture(0.08, 4), 0.08)
	rock_material = _make_material(Color(0.48, 0.46, 0.4), 0.0, 0.66, _make_noise_texture(0.16, 3), 0.06)
	edge_material = _make_material(Color(0.25, 0.5, 0.2), 0.0, 0.62, _make_noise_texture(0.1, 3), 0.04)
	flower_material = _make_material(Color(1.0, 0.78, 0.24), 0.0, 0.48, null, 0.0)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "StylizedEnvironment"

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.78, 0.94)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.76, 0.82)
	env.ambient_light_energy = 0.78
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.02
	env.tonemap_white = 1.55
	env.glow_enabled = false
	env.ssao_enabled = true
	env.ssao_radius = 2.4
	env.ssao_intensity = 0.42
	_environment = env
	set_brightness(default_brightness)
	world_environment.environment = env
	add_child(world_environment)


func _build_platform() -> void:
	var full_size := arena_half_extent * 2.0 + platform_margin

	var base := MeshInstance3D.new()
	base.name = "TerrainBlockSoil"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(full_size, platform_depth, full_size)
	base.mesh = base_mesh
	base.position = Vector3(0.0, -platform_depth * 0.5, 0.0)
	base.material_override = dirt_material
	add_child(base)

	var top := MeshInstance3D.new()
	top.name = "GrassTopSurface"
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(full_size - 0.55, 0.18, full_size - 0.55)
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.02, 0.0)
	top.material_override = grass_material
	add_child(top)

	var edge_specs := [
		{"name": "NorthGrassLip", "position": Vector3(0.0, -0.09, -full_size * 0.5 + 0.18), "size": Vector3(full_size - 0.25, 0.32, 0.36)},
		{"name": "SouthGrassLip", "position": Vector3(0.0, -0.09, full_size * 0.5 - 0.18), "size": Vector3(full_size - 0.25, 0.32, 0.36)},
		{"name": "WestGrassLip", "position": Vector3(-full_size * 0.5 + 0.18, -0.09, 0.0), "size": Vector3(0.36, 0.32, full_size - 0.25)},
		{"name": "EastGrassLip", "position": Vector3(full_size * 0.5 - 0.18, -0.09, 0.0), "size": Vector3(0.36, 0.32, full_size - 0.25)},
	]
	for spec in edge_specs:
		var lip := MeshInstance3D.new()
		lip.name = spec.name
		var mesh := BoxMesh.new()
		mesh.size = spec.size
		lip.mesh = mesh
		lip.position = spec.position
		lip.material_override = edge_material
		add_child(lip)


func _build_boundary() -> void:
	var boundary_y := boundary_height * 0.5 + 0.1
	var length := arena_half_extent * 2.0
	var specs := [
		{"name": "NorthSubtleBoundary", "position": Vector3(0.0, boundary_y, -arena_half_extent), "size": Vector3(length, boundary_height, boundary_width)},
		{"name": "SouthSubtleBoundary", "position": Vector3(0.0, boundary_y, arena_half_extent), "size": Vector3(length, boundary_height, boundary_width)},
		{"name": "WestSubtleBoundary", "position": Vector3(-arena_half_extent, boundary_y, 0.0), "size": Vector3(boundary_width, boundary_height, length)},
		{"name": "EastSubtleBoundary", "position": Vector3(arena_half_extent, boundary_y, 0.0), "size": Vector3(boundary_width, boundary_height, length)},
	]
	for spec in specs:
		var rail := MeshInstance3D.new()
		rail.name = spec.name
		var mesh := BoxMesh.new()
		mesh.size = spec.size
		rail.mesh = mesh
		rail.position = spec.position
		rail.material_override = rock_material
		add_child(rail)

	var corners := [
		Vector3(-arena_half_extent, 0.42, -arena_half_extent),
		Vector3(arena_half_extent, 0.42, -arena_half_extent),
		Vector3(-arena_half_extent, 0.42, arena_half_extent),
		Vector3(arena_half_extent, 0.42, arena_half_extent),
	]
	for i in range(corners.size()):
		var marker := MeshInstance3D.new()
		marker.name = "RoundedStoneCorner%02d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.72
		mesh.bottom_radius = 0.82
		mesh.height = 0.7
		mesh.radial_segments = 12
		marker.mesh = mesh
		marker.position = corners[i]
		marker.material_override = rock_material
		add_child(marker)


func _build_surface_detail() -> void:
	for i in range(grass_patch_count):
		var patch := MeshInstance3D.new()
		patch.name = "GrassColorPatch%02d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(
			_deterministic_range(i, 11.0, 4.0, 9.5),
			0.022,
			_deterministic_range(i, 19.0, 2.6, 7.8)
		)
		patch.mesh = mesh
		patch.position = Vector3(
			_deterministic_range(i, 31.0, -arena_half_extent * 0.82, arena_half_extent * 0.82),
			0.13 + float(i % 3) * 0.002,
			_deterministic_range(i, 47.0, -arena_half_extent * 0.82, arena_half_extent * 0.82)
		)
		patch.rotation_degrees.y = _deterministic_range(i, 59.0, -28.0, 28.0)
		patch.material_override = grass_light_material if i % 3 == 0 else grass_dark_material
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(patch)

	for i in range(stone_count):
		var stone := MeshInstance3D.new()
		stone.name = "SoftStone%02d" % i
		var mesh := SphereMesh.new()
		mesh.radius = _deterministic_range(i, 71.0, 0.18, 0.45)
		mesh.height = mesh.radius * _deterministic_range(i, 73.0, 0.55, 0.85)
		mesh.radial_segments = 10
		mesh.rings = 5
		stone.mesh = mesh
		stone.scale = Vector3(1.25, 0.35, 0.9)
		stone.position = Vector3(
			_deterministic_range(i, 83.0, -arena_half_extent * 0.88, arena_half_extent * 0.88),
			0.22,
			_deterministic_range(i, 97.0, -arena_half_extent * 0.88, arena_half_extent * 0.88)
		)
		stone.rotation_degrees.y = _deterministic_range(i, 101.0, 0.0, 180.0)
		stone.material_override = rock_material
		add_child(stone)

	for i in range(16):
		var flower := MeshInstance3D.new()
		flower.name = "TinyFlower%02d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.08
		mesh.bottom_radius = 0.1
		mesh.height = 0.08
		mesh.radial_segments = 8
		flower.mesh = mesh
		flower.position = Vector3(
			_deterministic_range(i, 109.0, -arena_half_extent * 0.76, arena_half_extent * 0.76),
			0.2,
			_deterministic_range(i, 127.0, -arena_half_extent * 0.76, arena_half_extent * 0.76)
		)
		flower.material_override = flower_material
		add_child(flower)


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "SoftSunLight"
	sun.rotation_degrees = Vector3(-48.0, 38.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	add_child(sun)

	var sky_fill := DirectionalLight3D.new()
	sky_fill.name = "SkyFillLight"
	sky_fill.rotation_degrees = Vector3(-32.0, -145.0, 0.0)
	sky_fill.light_color = Color(0.55, 0.68, 0.86)
	sky_fill.light_energy = 0.25
	sky_fill.shadow_enabled = false
	add_child(sky_fill)


func _make_material(albedo: Color, metallic: float, roughness: float, albedo_texture: Texture2D, normal_scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	if albedo_texture != null:
		material.albedo_texture = albedo_texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if normal_scale > 0.0:
		material.normal_enabled = true
		material.normal_scale = normal_scale
		material.normal_texture = _make_noise_texture(0.22, 3)
	return material


func _make_noise_texture(frequency: float, octaves: int) -> NoiseTexture2D:
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


func _deterministic_range(index: int, salt: float, min_value: float, max_value: float) -> float:
	var t := fmod(sin(float(index) * 12.9898 + salt) * 43758.5453, 1.0)
	if t < 0.0:
		t += 1.0
	return lerpf(min_value, max_value, t)
