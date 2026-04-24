extends Node3D
class_name ArenaBuilder

@export var arena_half_extent: float = 52.0
@export var grid_step: float = 2.0
@export var floor_thickness: float = 0.18
@export var floor_margin: float = 3.5
@export var grid_line_width: float = 0.011
@export var grid_line_height: float = 0.009
@export var wall_height: float = 1.45
@export var wall_thickness: float = 0.75
@export var panel_step: float = 8.0
@export var accent_spacing: float = 8.0
@export var floor_plate_step: float = 13.0
@export var default_brightness: float = 1.2

var floor_material: StandardMaterial3D
var floor_plate_material: StandardMaterial3D
var panel_line_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var grid_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var dark_accent_material: StandardMaterial3D
var warm_light_material: StandardMaterial3D
var hazard_material: StandardMaterial3D
var rubber_material: StandardMaterial3D
var bolt_material: StandardMaterial3D
var vent_material: StandardMaterial3D
var _environment: Environment


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


func set_brightness(value: float) -> void:
	default_brightness = clampf(value, 0.5, 2.0)
	if _environment == null:
		return
	_environment.tonemap_exposure = 1.2 * default_brightness
	_environment.ambient_light_energy = 0.34 * default_brightness
	_environment.glow_intensity = 0.34 + default_brightness * 0.18


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _build_materials() -> void:
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.024, 0.026, 0.029, 1.0)
	floor_material.metallic = 0.9
	floor_material.roughness = 0.13
	floor_material.emission_enabled = true
	floor_material.emission = Color(0.006, 0.008, 0.011)
	floor_material.emission_energy_multiplier = 0.12
	floor_material.normal_enabled = true
	floor_material.normal_scale = 0.22
	floor_material.normal_texture = _make_noise_texture(0.18, 5)
	floor_material.roughness_texture = _make_noise_texture(0.075, 6)

	floor_plate_material = StandardMaterial3D.new()
	floor_plate_material.albedo_color = Color(0.036, 0.039, 0.043, 1.0)
	floor_plate_material.metallic = 0.86
	floor_plate_material.roughness = 0.18
	floor_plate_material.normal_enabled = true
	floor_plate_material.normal_scale = 0.18
	floor_plate_material.normal_texture = _make_noise_texture(0.28, 4)
	floor_plate_material.roughness_texture = _make_noise_texture(0.12, 5)

	panel_line_material = StandardMaterial3D.new()
	panel_line_material.albedo_color = Color(0.003, 0.004, 0.006, 1.0)
	panel_line_material.metallic = 0.65
	panel_line_material.roughness = 0.28
	panel_line_material.emission_enabled = true
	panel_line_material.emission = Color(0.0, 0.01, 0.014)
	panel_line_material.emission_energy_multiplier = 0.08

	rail_material = StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.009, 0.011, 0.014, 1.0)
	rail_material.metallic = 0.88
	rail_material.roughness = 0.2
	rail_material.emission_enabled = true
	rail_material.emission = Color(0.0, 0.035, 0.052)
	rail_material.emission_energy_multiplier = 0.16
	rail_material.normal_enabled = true
	rail_material.normal_scale = 0.16
	rail_material.normal_texture = _make_noise_texture(0.2, 4)

	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.0, 0.58, 0.52, 0.3)
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.0, 0.58, 0.5)
	grid_material.emission_energy_multiplier = 0.42
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	accent_material = StandardMaterial3D.new()
	accent_material.albedo_color = Color(0.04, 0.65, 0.7, 1.0)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.0, 0.52, 0.62)
	accent_material.emission_energy_multiplier = 1.25
	accent_material.metallic = 0.1
	accent_material.roughness = 0.18

	dark_accent_material = StandardMaterial3D.new()
	dark_accent_material.albedo_color = Color(0.02, 0.035, 0.05, 1.0)
	dark_accent_material.metallic = 0.7
	dark_accent_material.roughness = 0.18
	dark_accent_material.emission_enabled = true
	dark_accent_material.emission = Color(0.0, 0.2, 0.28)
	dark_accent_material.emission_energy_multiplier = 0.7

	warm_light_material = StandardMaterial3D.new()
	warm_light_material.albedo_color = Color(1.0, 0.42, 0.12, 1.0)
	warm_light_material.emission_enabled = true
	warm_light_material.emission = Color(1.0, 0.32, 0.06)
	warm_light_material.emission_energy_multiplier = 2.15

	hazard_material = StandardMaterial3D.new()
	hazard_material.albedo_color = Color(0.95, 0.58, 0.08, 1.0)
	hazard_material.metallic = 0.2
	hazard_material.roughness = 0.34
	hazard_material.emission_enabled = true
	hazard_material.emission = Color(0.5, 0.2, 0.0)
	hazard_material.emission_energy_multiplier = 0.15

	rubber_material = StandardMaterial3D.new()
	rubber_material.albedo_color = Color(0.006, 0.006, 0.007, 1.0)
	rubber_material.roughness = 0.58

	bolt_material = StandardMaterial3D.new()
	bolt_material.albedo_color = Color(0.075, 0.078, 0.08, 1.0)
	bolt_material.metallic = 0.92
	bolt_material.roughness = 0.16

	vent_material = StandardMaterial3D.new()
	vent_material.albedo_color = Color(0.006, 0.008, 0.01, 1.0)
	vent_material.metallic = 0.82
	vent_material.roughness = 0.26


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "CinematicEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.006, 0.011)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.045, 0.052, 0.062)
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	env.tonemap_white = 1.22
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_strength = 0.95
	env.glow_bloom = 0.18
	env.ssao_enabled = true
	env.ssao_radius = 3.0
	env.ssao_intensity = 1.55
	_environment = env
	set_brightness(default_brightness)
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

	_build_floor_plates()
	_build_floor_panel_detail()
	_build_floor_props()

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
	_build_modular_wall(Vector3.FORWARD, -arena_half_extent, "North")
	_build_modular_wall(Vector3.BACK, arena_half_extent, "South")
	_build_modular_wall(Vector3.RIGHT, -arena_half_extent, "West")
	_build_modular_wall(Vector3.LEFT, arena_half_extent, "East")

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
		pylon_mesh.top_radius = 0.72
		pylon_mesh.bottom_radius = 1.05
		pylon_mesh.height = 3.2
		pylon_mesh.radial_segments = 10
		pylon.mesh = pylon_mesh
		pylon.position = corners[i]
		pylon.material_override = accent_material
		add_child(pylon)

		var collar := MeshInstance3D.new()
		collar.name = "CornerTowerCollar%02d" % i
		var collar_mesh := CylinderMesh.new()
		collar_mesh.top_radius = 1.15
		collar_mesh.bottom_radius = 1.15
		collar_mesh.height = 0.16
		collar_mesh.radial_segments = 10
		collar.mesh = collar_mesh
		collar.position = Vector3(corners[i].x, 0.62, corners[i].z)
		collar.material_override = rail_material
		add_child(collar)


func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-58.0, 35.0, 0.0)
	key.light_energy = 0.58
	key.light_color = Color(0.78, 0.84, 0.95)
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "CenterNeonFill"
	fill.position = Vector3(0.0, 8.0, 0.0)
	fill.light_color = Color(0.0, 0.82, 0.95)
	fill.light_energy = 0.95
	fill.omni_range = arena_half_extent * 0.65
	add_child(fill)

	for i in range(4):
		var light := OmniLight3D.new()
		light.name = "CornerAccentLight%02d" % i
		var sx := -1.0 if i < 2 else 1.0
		var sz := -1.0 if i % 2 == 0 else 1.0
		light.position = Vector3(sx * arena_half_extent, 2.1, sz * arena_half_extent)
		light.light_color = Color(1.0, 0.34, 0.08)
		light.light_energy = 1.45
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
		light.light_energy = 0.34
		light.omni_range = 7.5
		add_child(light)

	for i in range(12):
		var light := OmniLight3D.new()
		light.name = "LowAmberSideLight%02d" % i
		var side := i % 4
		var along := lerpf(-arena_half_extent * 0.82, arena_half_extent * 0.82, float(i / 4) / 2.0)
		match side:
			0:
				light.position = Vector3(along, 0.42, -arena_half_extent + 1.25)
			1:
				light.position = Vector3(arena_half_extent - 1.25, 0.42, along)
			2:
				light.position = Vector3(-along, 0.42, arena_half_extent - 1.25)
			3:
				light.position = Vector3(-arena_half_extent + 1.25, 0.42, -along)
		light.light_color = Color(1.0, 0.42, 0.12)
		light.light_energy = 0.72
		light.omni_range = 6.5
		add_child(light)


func _build_floor_plates() -> void:
	var index := 0
	var limit := arena_half_extent - floor_plate_step * 0.5
	var x := -limit
	while x <= limit + 0.01:
		var z := -limit
		while z <= limit + 0.01:
			var plate := MeshInstance3D.new()
			plate.name = "FloorPlate%02d" % index
			var mesh := BoxMesh.new()
			var shrink := 0.42 + float((index * 7) % 5) * 0.035
			mesh.size = Vector3(floor_plate_step - shrink, 0.026, floor_plate_step - shrink)
			plate.mesh = mesh
			plate.position = Vector3(x, 0.018 + float(index % 3) * 0.002, z)
			plate.material_override = floor_plate_material
			plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(plate)
			z += floor_plate_step
			index += 1
		x += floor_plate_step


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


func _build_modular_wall(normal: Vector3, edge: float, wall_name: String) -> void:
	var segment_count := int(floor((arena_half_extent * 2.0) / accent_spacing))
	for i in range(segment_count):
		var center := -arena_half_extent + accent_spacing * 0.5 + float(i) * accent_spacing
		var panel := MeshInstance3D.new()
		panel.name = "%sWallPanel%02d" % [wall_name, i]
		var mesh := BoxMesh.new()
		if absf(normal.z) > 0.5:
			mesh.size = Vector3(accent_spacing - 0.36, wall_height, wall_thickness)
			panel.position = Vector3(center, wall_height * 0.5, edge)
		else:
			mesh.size = Vector3(wall_thickness, wall_height, accent_spacing - 0.36)
			panel.position = Vector3(edge, wall_height * 0.5, center)
		panel.mesh = mesh
		panel.material_override = rail_material
		add_child(panel)

		var rib := MeshInstance3D.new()
		rib.name = "%sWallRib%02d" % [wall_name, i]
		var rib_mesh := BoxMesh.new()
		if absf(normal.z) > 0.5:
			rib_mesh.size = Vector3(0.16, wall_height + 0.28, wall_thickness + 0.16)
			rib.position = Vector3(center + accent_spacing * 0.47, (wall_height + 0.28) * 0.5, edge)
		else:
			rib_mesh.size = Vector3(wall_thickness + 0.16, wall_height + 0.28, 0.16)
			rib.position = Vector3(edge, (wall_height + 0.28) * 0.5, center + accent_spacing * 0.47)
		rib.mesh = rib_mesh
		rib.material_override = dark_accent_material
		add_child(rib)

		if i % 2 == 0:
			_add_wall_light(wall_name, i, panel.position, normal)


func _add_wall_light(wall_name: String, index: int, base_position: Vector3, normal: Vector3) -> void:
	var light_bar := MeshInstance3D.new()
	light_bar.name = "%sWarmWallLight%02d" % [wall_name, index]
	var mesh := BoxMesh.new()
	if absf(normal.z) > 0.5:
		mesh.size = Vector3(1.6, 0.1, 0.08)
	else:
		mesh.size = Vector3(0.08, 0.1, 1.6)
	light_bar.mesh = mesh
	light_bar.position = base_position + Vector3(0.0, -0.35, 0.0) - normal * 0.42
	light_bar.material_override = warm_light_material
	light_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(light_bar)


func _build_floor_props() -> void:
	for i in range(18):
		var x := _deterministic_range(i, 17.0, -arena_half_extent * 0.75, arena_half_extent * 0.75)
		var z := _deterministic_range(i, 31.0, -arena_half_extent * 0.75, arena_half_extent * 0.75)
		if i % 3 == 0:
			_add_vent(Vector3(x, 0.055, z), i)
		elif i % 3 == 1:
			_add_cable(Vector3(x, 0.075, z), i)
		else:
			_add_recessed_panel(Vector3(x, 0.052, z), i)

	for i in range(14):
		var along := lerpf(-arena_half_extent * 0.78, arena_half_extent * 0.78, float(i) / 13.0)
		_add_hazard_stripe(Vector3(along, 0.08, -arena_half_extent + 2.1), i, true)
		_add_hazard_stripe(Vector3(-arena_half_extent + 2.1, 0.08, along), i + 20, false)

	for i in range(44):
		var x := _deterministic_range(i, 47.0, -arena_half_extent * 0.9, arena_half_extent * 0.9)
		var z := _deterministic_range(i, 71.0, -arena_half_extent * 0.9, arena_half_extent * 0.9)
		_add_bolt(Vector3(x, 0.105, z), i)


func _add_vent(vent_position: Vector3, index: int) -> void:
	var base := MeshInstance3D.new()
	base.name = "FloorVentBase%02d" % index
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(2.2, 0.04, 1.15)
	base.mesh = base_mesh
	base.position = vent_position
	base.rotation_degrees.y = float((index * 37) % 90)
	base.material_override = vent_material
	add_child(base)

	for slot_index in range(4):
		var slot := MeshInstance3D.new()
		slot.name = "FloorVentSlot%02d_%02d" % [index, slot_index]
		var slot_mesh := BoxMesh.new()
		slot_mesh.size = Vector3(1.72, 0.022, 0.055)
		slot.mesh = slot_mesh
		slot.position = vent_position + Vector3(0.0, 0.035, -0.36 + float(slot_index) * 0.24)
		slot.rotation_degrees.y = base.rotation_degrees.y
		slot.material_override = rubber_material
		slot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(slot)


func _add_cable(cable_position: Vector3, index: int) -> void:
	var cable := MeshInstance3D.new()
	cable.name = "FloorCable%02d" % index
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.09, 3.2 + float(index % 3) * 0.8)
	cable.mesh = mesh
	cable.position = cable_position
	cable.rotation_degrees.y = float((index * 29) % 180)
	cable.material_override = rubber_material
	add_child(cable)


func _add_recessed_panel(panel_position: Vector3, index: int) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "RecessedServicePanel%02d" % index
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.8, 0.035, 1.8)
	panel.mesh = mesh
	panel.position = panel_position
	panel.rotation_degrees.y = float((index * 19) % 90)
	panel.material_override = panel_line_material
	add_child(panel)


func _add_hazard_stripe(stripe_position: Vector3, index: int, horizontal: bool) -> void:
	for stripe_index in range(3):
		var stripe := MeshInstance3D.new()
		stripe.name = "HazardStripe%02d_%02d" % [index, stripe_index]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.0, 0.032, 0.16) if horizontal else Vector3(0.16, 0.032, 1.0)
		stripe.mesh = mesh
		stripe.position = stripe_position + (Vector3(0.42 * float(stripe_index), 0.0, 0.0) if horizontal else Vector3(0.0, 0.0, 0.42 * float(stripe_index)))
		stripe.rotation_degrees.y = -24.0
		stripe.material_override = hazard_material
		stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stripe)


func _add_bolt(bolt_position: Vector3, index: int) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = "FloorBolt%02d" % index
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.09
	mesh.bottom_radius = 0.09
	mesh.height = 0.035
	mesh.radial_segments = 8
	bolt.mesh = mesh
	bolt.position = bolt_position
	bolt.material_override = bolt_material
	add_child(bolt)


func _deterministic_range(index: int, salt: float, min_value: float, max_value: float) -> float:
	var t := fmod(sin(float(index) * 12.9898 + salt) * 43758.5453, 1.0)
	if t < 0.0:
		t += 1.0
	return lerpf(min_value, max_value, t)


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
