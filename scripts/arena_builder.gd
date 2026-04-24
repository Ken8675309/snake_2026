extends Node3D
class_name ArenaBuilder

@export var arena_half_extent: float = 13.5
@export var grid_step: float = 2.25
@export var floor_thickness: float = 0.18

var floor_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var grid_material: StandardMaterial3D
var accent_material: StandardMaterial3D


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
	floor_material.albedo_color = Color(0.015, 0.017, 0.027, 1.0)
	floor_material.metallic = 0.65
	floor_material.roughness = 0.16
	floor_material.emission_enabled = true
	floor_material.emission = Color(0.0, 0.02, 0.045)
	floor_material.emission_energy_multiplier = 0.35

	rail_material = StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.02, 0.03, 0.05, 1.0)
	rail_material.metallic = 0.8
	rail_material.roughness = 0.22
	rail_material.emission_enabled = true
	rail_material.emission = Color(0.0, 0.26, 0.44)
	rail_material.emission_energy_multiplier = 0.75

	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.0, 0.92, 0.82, 1.0)
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.0, 0.92, 0.78)
	grid_material.emission_energy_multiplier = 1.85
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	accent_material = StandardMaterial3D.new()
	accent_material.albedo_color = Color(0.95, 0.12, 0.78, 1.0)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.95, 0.04, 0.65)
	accent_material.emission_energy_multiplier = 2.1
	accent_material.metallic = 0.1
	accent_material.roughness = 0.18


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "CinematicEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.007, 0.014)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.08, 0.12)
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.tonemap_white = 1.35
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.95
	env.glow_bloom = 0.18
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.25
	environment.environment = env
	add_child(environment)


func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "ReflectiveFloor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(arena_half_extent * 2.0 + 1.5, floor_thickness, arena_half_extent * 2.0 + 1.5)
	floor.mesh = mesh
	floor.position = Vector3(0.0, -floor_thickness * 0.5, 0.0)
	floor.material_override = floor_material
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor)

	var reflection := ReflectionProbe.new()
	reflection.name = "FloorReflectionProbe"
	reflection.position = Vector3(0.0, 4.0, 0.0)
	reflection.size = Vector3(arena_half_extent * 2.0, 9.0, arena_half_extent * 2.0)
	reflection.intensity = 0.36
	reflection.max_distance = arena_half_extent * 2.5
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
				mesh.size = Vector3(0.035, 0.025, arena_half_extent * 2.0)
				line.position = Vector3(coordinate, 0.02, 0.0)
			else:
				mesh.size = Vector3(arena_half_extent * 2.0, 0.025, 0.035)
				line.position = Vector3(0.0, 0.021, coordinate)
			line.mesh = mesh
			line.material_override = grid_material
			line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(line)
			coordinate += grid_step
			index += 1


func _build_boundary() -> void:
	var rail_specs := [
		{"name": "NorthRail", "position": Vector3(0.0, 0.34, -arena_half_extent), "size": Vector3(arena_half_extent * 2.0 + 0.6, 0.68, 0.32)},
		{"name": "SouthRail", "position": Vector3(0.0, 0.34, arena_half_extent), "size": Vector3(arena_half_extent * 2.0 + 0.6, 0.68, 0.32)},
		{"name": "WestRail", "position": Vector3(-arena_half_extent, 0.34, 0.0), "size": Vector3(0.32, 0.68, arena_half_extent * 2.0 + 0.6)},
		{"name": "EastRail", "position": Vector3(arena_half_extent, 0.34, 0.0), "size": Vector3(0.32, 0.68, arena_half_extent * 2.0 + 0.6)},
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

	var corners := [
		Vector3(-arena_half_extent, 0.72, -arena_half_extent),
		Vector3(arena_half_extent, 0.72, -arena_half_extent),
		Vector3(-arena_half_extent, 0.72, arena_half_extent),
		Vector3(arena_half_extent, 0.72, arena_half_extent),
	]
	for i in range(corners.size()):
		var pylon := MeshInstance3D.new()
		pylon.name = "CornerPylon%02d" % i
		var pylon_mesh := CylinderMesh.new()
		pylon_mesh.top_radius = 0.32
		pylon_mesh.bottom_radius = 0.48
		pylon_mesh.height = 1.4
		pylon_mesh.radial_segments = 8
		pylon.mesh = pylon_mesh
		pylon.position = corners[i]
		pylon.material_override = accent_material
		add_child(pylon)


func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-58.0, 35.0, 0.0)
	key.light_energy = 1.25
	key.light_color = Color(0.78, 0.9, 1.0)
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "CenterNeonFill"
	fill.position = Vector3(0.0, 5.0, 0.0)
	fill.light_color = Color(0.0, 0.82, 0.95)
	fill.light_energy = 1.35
	fill.omni_range = 18.0
	add_child(fill)

	for i in range(4):
		var light := OmniLight3D.new()
		light.name = "CornerAccentLight%02d" % i
		var sx := -1.0 if i < 2 else 1.0
		var sz := -1.0 if i % 2 == 0 else 1.0
		light.position = Vector3(sx * arena_half_extent, 1.7, sz * arena_half_extent)
		light.light_color = Color(1.0, 0.08, 0.65)
		light.light_energy = 1.1
		light.omni_range = 7.0
		add_child(light)
