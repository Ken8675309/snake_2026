extends Node3D
class_name ArenaBuilder

@export var arena_half_extent: float = 52.0
@export var grid_step: float = 2.0
@export var floor_thickness: float = 0.18
@export var floor_margin: float = 3.5
@export var grid_line_width: float = 0.018
@export var grid_line_height: float = 0.014
@export var wall_height: float = 1.1
@export var wall_thickness: float = 0.55
@export var panel_step: float = 8.0
@export var accent_spacing: float = 8.0

var floor_material: StandardMaterial3D
var panel_line_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var grid_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var dark_accent_material: StandardMaterial3D


func _ready() -> void:
	build()


func build() -> void:
	_clear_children()
	_build_materials()
	_build_environment()
	_build_floor()
	_build_grid()
	_build_boundary()
	_build_lighting()


func get_random_play_position(margin: float = 1.5) -> Vector3:
	var usable := arena_half_extent - margin
	return Vector3(randf_range(-usable, usable), 0.48, randf_range(-usable, usable))


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _build_materials() -> void:
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.018, 0.02, 0.026, 1.0)
	floor_material.metallic = 0.82
	floor_material.roughness = 0.19
	floor_material.emission_enabled = true
	floor_material.emission = Color(0.0, 0.012, 0.026)
	floor_material.emission_energy_multiplier = 0.18
	floor_material.normal_enabled = true
	floor_material.normal_scale = 0.11
	floor_material.normal_texture = _make_noise_texture(0.085, 4)
	floor_material.roughness_texture = _make_noise_texture(0.045, 5)

	panel_line_material = StandardMaterial3D.new()
	panel_line_material.albedo_color = Color(0.006, 0.009, 0.013, 1.0)
	panel_line_material.metallic = 0.65
	panel_line_material.roughness = 0.28
	panel_line_material.emission_enabled = true
	panel_line_material.emission = Color(0.0, 0.018, 0.026)
	panel_line_material.emission_energy_multiplier = 0.18

	rail_material = StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.012, 0.017, 0.026, 1.0)
	rail_material.metallic = 0.88
	rail_material.roughness = 0.24
	rail_material.emission_enabled = true
	rail_material.emission = Color(0.0, 0.09, 0.15)
	rail_material.emission_energy_multiplier = 0.38
	rail_material.normal_enabled = true
	rail_material.normal_scale = 0.08
	rail_material.normal_texture = _make_noise_texture(0.12, 3)

	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.0, 0.88, 0.78, 0.74)
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.0, 0.92, 0.78)
	grid_material.emission_energy_multiplier = 1.45
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	accent_material = StandardMaterial3D.new()
	accent_material.albedo_color = Color(0.95, 0.08, 0.62, 1.0)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.95, 0.02, 0.48)
	accent_material.emission_energy_multiplier = 2.35
	accent_material.metallic = 0.1
	accent_material.roughness = 0.18

	dark_accent_material = StandardMaterial3D.new()
	dark_accent_material.albedo_color = Color(0.02, 0.035, 0.05, 1.0)
	dark_accent_material.metallic = 0.7
	dark_accent_material.roughness = 0.18
	dark_accent_material.emission_enabled = true
	dark_accent_material.emission = Color(0.0, 0.2, 0.28)
	dark_accent_material.emission_energy_multiplier = 0.7


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "CinematicEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.007, 0.014)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.025, 0.04, 0.06)
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.18
	env.tonemap_white = 1.18
	env.glow_enabled = true
	env.glow_intensity = 0.78
	env.glow_strength = 1.22
	env.glow_bloom = 0.26
	env.ssao_enabled = true
	env.ssao_radius = 3.0
	env.ssao_intensity = 1.55
	environment.environment = env
	add_child(environment)


func _build_floor() -> void:
	var floor_size := arena_half_extent * 2.0 + floor_margin
	var floor := MeshInstance3D.new()
	floor.name = "ReflectiveFloor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(floor_size, floor_thickness, floor_size)
	floor.mesh = mesh
	floor.position = Vector3(0.0, -floor_thickness * 0.5, 0.0)
	floor.material_override = floor_material
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor)

	_build_floor_panel_detail()

	var reflection := ReflectionProbe.new()
	reflection.name = "FloorReflectionProbe"
	reflection.position = Vector3(0.0, 4.0, 0.0)
	reflection.size = Vector3(arena_half_extent * 2.0, 12.0, arena_half_extent * 2.0)
	reflection.intensity = 0.42
	reflection.max_distance = arena_half_extent * 2.2
	add_child(reflection)


func _build_grid() -> void:
	var index := 0
	for axis in [0, 1]:
		var coordinate := -arena_half_extent
		while coordinate <= arena_half_extent + 0.01:
			var line := MeshInstance3D.new()
			line.name = "NeonGrid%02d" % index
			var mesh := BoxMesh.new()
			if axis == 0:
				mesh.size = Vector3(grid_line_width, grid_line_height, arena_half_extent * 2.0)
				line.position = Vector3(coordinate, 0.02, 0.0)
			else:
				mesh.size = Vector3(arena_half_extent * 2.0, grid_line_height, grid_line_width)
				line.position = Vector3(0.0, 0.021, coordinate)
			line.mesh = mesh
			line.material_override = grid_material
			line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(line)
			coordinate += grid_step
			index += 1


func _build_boundary() -> void:
	var rail_y := wall_height * 0.5
	var rail_length := arena_half_extent * 2.0 + wall_thickness
	var rail_specs := [
		{"name": "NorthRail", "position": Vector3(0.0, rail_y, -arena_half_extent), "size": Vector3(rail_length, wall_height, wall_thickness)},
		{"name": "SouthRail", "position": Vector3(0.0, rail_y, arena_half_extent), "size": Vector3(rail_length, wall_height, wall_thickness)},
		{"name": "WestRail", "position": Vector3(-arena_half_extent, rail_y, 0.0), "size": Vector3(wall_thickness, wall_height, rail_length)},
		{"name": "EastRail", "position": Vector3(arena_half_extent, rail_y, 0.0), "size": Vector3(wall_thickness, wall_height, rail_length)},
	]
	for spec in rail_specs:
		var rail := MeshInstance3D.new()
		rail.name = spec.name
		var mesh := BoxMesh.new()
		mesh.size = spec.size
		rail.mesh = mesh
		rail.position = spec.position
		rail.material_override = rail_material
		add_child(rail)

	_build_wall_accents()

	var corners := [
		Vector3(-arena_half_extent, wall_height + 0.22, -arena_half_extent),
		Vector3(arena_half_extent, wall_height + 0.22, -arena_half_extent),
		Vector3(-arena_half_extent, wall_height + 0.22, arena_half_extent),
		Vector3(arena_half_extent, wall_height + 0.22, arena_half_extent),
	]
	for i in range(corners.size()):
		var pylon := MeshInstance3D.new()
		pylon.name = "CornerPylon%02d" % i
		var pylon_mesh := CylinderMesh.new()
		pylon_mesh.top_radius = 0.32
		pylon_mesh.bottom_radius = 0.48
		pylon_mesh.height = 1.8
		pylon_mesh.radial_segments = 8
		pylon.mesh = pylon_mesh
		pylon.position = corners[i]
		pylon.material_override = accent_material
		add_child(pylon)


func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-58.0, 35.0, 0.0)
	key.light_energy = 0.58
	key.light_color = Color(0.66, 0.82, 1.0)
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "CenterNeonFill"
	fill.position = Vector3(0.0, 8.0, 0.0)
	fill.light_color = Color(0.0, 0.82, 0.95)
	fill.light_energy = 1.1
	fill.omni_range = arena_half_extent * 0.65
	add_child(fill)

	for i in range(4):
		var light := OmniLight3D.new()
		light.name = "CornerAccentLight%02d" % i
		var sx := -1.0 if i < 2 else 1.0
		var sz := -1.0 if i % 2 == 0 else 1.0
		light.position = Vector3(sx * arena_half_extent, 2.1, sz * arena_half_extent)
		light.light_color = Color(1.0, 0.08, 0.65)
		light.light_energy = 1.35
		light.omni_range = 11.0
		add_child(light)

	for i in range(8):
		var light := OmniLight3D.new()
		light.name = "PerimeterCyanLight%02d" % i
		var t := float(i) / 8.0
		var side := i % 4
		var along := lerpf(-arena_half_extent * 0.72, arena_half_extent * 0.72, fmod(t * 4.0, 1.0))
		match side:
			0:
				light.position = Vector3(along, 1.35, -arena_half_extent + 0.7)
			1:
				light.position = Vector3(arena_half_extent - 0.7, 1.35, along)
			2:
				light.position = Vector3(-along, 1.35, arena_half_extent - 0.7)
			3:
				light.position = Vector3(-arena_half_extent + 0.7, 1.35, -along)
		light.light_color = Color(0.0, 0.75, 0.95)
		light.light_energy = 0.55
		light.omni_range = 9.0
		add_child(light)


func _build_floor_panel_detail() -> void:
	var limit := arena_half_extent - panel_step * 0.5
	var index := 0
	var coordinate := -limit
	while coordinate <= limit + 0.01:
		for axis in [0, 1]:
			var seam := MeshInstance3D.new()
			seam.name = "FloorPanelSeam%02d" % index
			var mesh := BoxMesh.new()
			if axis == 0:
				mesh.size = Vector3(0.035, 0.018, arena_half_extent * 2.0)
				seam.position = Vector3(coordinate, 0.006, 0.0)
			else:
				mesh.size = Vector3(arena_half_extent * 2.0, 0.018, 0.035)
				seam.position = Vector3(0.0, 0.007, coordinate)
			seam.mesh = mesh
			seam.material_override = panel_line_material
			seam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(seam)
			index += 1
		coordinate += panel_step


func _build_wall_accents() -> void:
	var index := 0
	var coordinate := -arena_half_extent + accent_spacing
	while coordinate < arena_half_extent - accent_spacing * 0.5:
		_add_wall_accent(Vector3(coordinate, wall_height + 0.035, -arena_half_extent - 0.02), Vector3(1.5, 0.055, 0.06), "NorthWallAccent%02d" % index)
		_add_wall_accent(Vector3(coordinate, wall_height + 0.035, arena_half_extent + 0.02), Vector3(1.5, 0.055, 0.06), "SouthWallAccent%02d" % index)
		_add_wall_accent(Vector3(-arena_half_extent - 0.02, wall_height + 0.035, coordinate), Vector3(0.06, 0.055, 1.5), "WestWallAccent%02d" % index)
		_add_wall_accent(Vector3(arena_half_extent + 0.02, wall_height + 0.035, coordinate), Vector3(0.06, 0.055, 1.5), "EastWallAccent%02d" % index)
		coordinate += accent_spacing
		index += 1


func _add_wall_accent(accent_position: Vector3, accent_size: Vector3, accent_name: String) -> void:
	var accent := MeshInstance3D.new()
	accent.name = accent_name
	var mesh := BoxMesh.new()
	mesh.size = accent_size
	accent.mesh = mesh
	accent.position = accent_position
	accent.material_override = dark_accent_material
	accent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(accent)


func _make_noise_texture(frequency: float, octaves: int) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.2

	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.noise = noise
	return texture
