extends Node3D
class_name EffectsManager

var _timed_nodes: Array[Dictionary] = []


func _process(delta: float) -> void:
	for i in range(_timed_nodes.size() - 1, -1, -1):
		var entry = _timed_nodes[i]
		var node := entry["node"] as Node3D
		if not is_instance_valid(node):
			_timed_nodes.remove_at(i)
			continue

		entry["age"] += delta
		var age: float = entry["age"]
		var lifetime: float = entry["lifetime"]
		var t := clampf(age / maxf(lifetime, 0.001), 0.0, 1.0)

		if entry["kind"] == "ring":
			node.scale = Vector3.ONE * lerpf(entry["start_scale"], entry["end_scale"], t)
			var mesh := node as MeshInstance3D
			var mat := mesh.material_override as StandardMaterial3D
			var color := mat.albedo_color
			color.a = 1.0 - t
			mat.albedo_color = color
			mat.emission_energy_multiplier = lerpf(entry["energy"], 0.0, t)
		elif entry["kind"] == "light":
			var light := node as OmniLight3D
			light.light_energy = lerpf(entry["energy"], 0.0, t)

		_timed_nodes[i] = entry
		if age >= lifetime:
			node.queue_free()
			_timed_nodes.remove_at(i)


func food_burst(position: Vector3) -> void:
	particle_burst(position, Color(1.0, 0.18, 0.58), 42, 0.8)
	shock_ring(position, Color(1.0, 0.12, 0.55), 0.35, 4.2, 0.42)
	impact_light(position, Color(1.0, 0.2, 0.55), 4.0, 0.28)


func power_burst(position: Vector3, color: Color) -> void:
	particle_burst(position, color, 32, 0.65)
	shock_ring(position, color, 0.4, 3.2, 0.35)
	impact_light(position, color, 3.2, 0.22)


func crash_burst(position: Vector3) -> void:
	particle_burst(position, Color(0.95, 0.08, 0.16), 72, 1.1)
	shock_ring(position, Color(1.0, 0.05, 0.12), 0.5, 6.2, 0.65)
	impact_light(position, Color(1.0, 0.04, 0.08), 6.0, 0.38)


func shield_break(position: Vector3) -> void:
	particle_burst(position, Color(0.15, 0.65, 1.0), 36, 0.7)
	shock_ring(position, Color(0.1, 0.62, 1.0), 0.55, 4.8, 0.42)
	impact_light(position, Color(0.1, 0.62, 1.0), 4.5, 0.3)


func particle_burst(position: Vector3, color: Color, amount: int, lifetime: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ParticleBurst"
	particles.position = position
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.88
	particles.randomness = 0.75

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 2.4
	process.initial_velocity_max = 7.2
	process.gravity = Vector3(0.0, -2.6, 0.0)
	process.scale_min = 0.035
	process.scale_max = 0.12
	process.color = color
	particles.process_material = process

	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.06
	draw_mesh.height = 0.12
	draw_mesh.radial_segments = 8
	draw_mesh.rings = 4
	particles.draw_pass_1 = draw_mesh
	add_child(particles)
	particles.emitting = true
	_track(particles, lifetime + 0.35, "particles")


func shock_ring(position: Vector3, color: Color, start_scale: float, end_scale: float, lifetime: float) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "ShockRing"
	ring.position = Vector3(position.x, 0.08, position.z)
	ring.rotation_degrees.x = 90.0
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.92
	mesh.outer_radius = 1.0
	mesh.ring_segments = 72
	mesh.rings = 6
	ring.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.78)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring.material_override = mat
	ring.scale = Vector3.ONE * start_scale
	add_child(ring)
	_timed_nodes.append({
		"node": ring,
		"age": 0.0,
		"lifetime": lifetime,
		"kind": "ring",
		"start_scale": start_scale,
		"end_scale": end_scale,
		"energy": mat.emission_energy_multiplier,
	})


func impact_light(position: Vector3, color: Color, energy: float, lifetime: float) -> void:
	var light := OmniLight3D.new()
	light.name = "ImpactLight"
	light.position = Vector3(position.x, 1.0, position.z)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 5.5
	add_child(light)
	_timed_nodes.append({
		"node": light,
		"age": 0.0,
		"lifetime": lifetime,
		"kind": "light",
		"energy": energy,
	})


func _track(node: Node3D, lifetime: float, kind: String) -> void:
	_timed_nodes.append({
		"node": node,
		"age": 0.0,
		"lifetime": lifetime,
		"kind": kind,
	})
