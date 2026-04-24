extends Node3D
class_name LifeEgg

@export var collect_radius: float = 0.92
@export var lifetime: float = 10.0
@export var bob_height: float = 0.16
@export var bob_speed: float = 2.4

var age: float = 0.0
var _base_y: float = 0.72
var _body: MeshInstance3D
var _halo: MeshInstance3D
var _light: OmniLight3D
var _wave_player: AudioStreamPlayer
var _body_material: StandardMaterial3D
var _halo_material: StandardMaterial3D
var _next_wave_age: float = 0.0


func _ready() -> void:
	_build_visual()
	_base_y = position.y
	_play_wave_ping(2.2, 0.72)
	_next_wave_age = (PI * 0.5) / 2.2


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return

	var phase_speed := _blink_speed()
	var visible_pulse := 0.55 + absf(sin(age * phase_speed)) * 0.45
	var scale_pulse := 1.0 + sin(age * bob_speed * 1.3) * 0.08
	position.y = _base_y + sin(age * bob_speed) * bob_height
	rotation.y += delta * 1.1

	_body.scale = Vector3(0.72, 0.96, 0.72) * scale_pulse
	_halo.scale = Vector3.ONE * (1.0 + visible_pulse * 0.18)
	_halo.transparency = 1.0 - visible_pulse
	_body_material.emission_energy_multiplier = 0.65 + visible_pulse * 1.2
	_halo_material.emission_energy_multiplier = 0.45 + visible_pulse * 1.8
	_light.light_energy = 0.55 + visible_pulse * 1.7
	_update_wave_audio(phase_speed, visible_pulse)


func _blink_speed() -> float:
	if age < 6.0:
		return 2.2
	if age < 9.0:
		return 6.5
	return 15.0


func _update_wave_audio(phase_speed: float, visible_pulse: float) -> void:
	if _wave_player == null:
		return
	if _next_wave_age <= 0.0:
		_next_wave_age = (PI * 0.5) / maxf(phase_speed, 0.001)
	while age >= _next_wave_age:
		_play_wave_ping(phase_speed, visible_pulse)
		_next_wave_age += PI / maxf(phase_speed, 0.001)


func _play_wave_ping(phase_speed: float, visible_pulse: float) -> void:
	if _wave_player == null:
		return
	_wave_player.stop()
	_wave_player.pitch_scale = clampf(phase_speed / 2.2, 0.8, 3.2)
	_wave_player.volume_db = lerpf(-16.0, -7.0, visible_pulse)
	_wave_player.play()


func _build_visual() -> void:
	if _body != null:
		return

	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color(0.98, 0.82, 0.26)
	_body_material.emission_enabled = true
	_body_material.emission = Color(1.0, 0.72, 0.18)
	_body_material.emission_energy_multiplier = 1.0
	_body_material.roughness = 0.34

	_halo_material = StandardMaterial3D.new()
	_halo_material.albedo_color = Color(0.35, 0.95, 1.0, 0.18)
	_halo_material.emission_enabled = true
	_halo_material.emission = Color(0.25, 0.9, 1.0)
	_halo_material.emission_energy_multiplier = 1.0
	_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	_body = MeshInstance3D.new()
	_body.name = "EggBody"
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 0.74
	body_mesh.radial_segments = 24
	body_mesh.rings = 12
	_body.mesh = body_mesh
	_body.scale = Vector3(0.72, 0.96, 0.72)
	_body.material_override = _body_material
	add_child(_body)

	_halo = MeshInstance3D.new()
	_halo.name = "EggHalo"
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.62
	halo_mesh.height = 1.04
	halo_mesh.radial_segments = 20
	halo_mesh.rings = 10
	_halo.mesh = halo_mesh
	_halo.material_override = _halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	_light = OmniLight3D.new()
	_light.name = "EggLight"
	_light.light_color = Color(0.55, 0.92, 1.0)
	_light.light_energy = 1.2
	_light.omni_range = 4.0
	add_child(_light)

	_wave_player = AudioStreamPlayer.new()
	_wave_player.name = "EggWavePlayer"
	_wave_player.stream = _make_wave_sound()
	_wave_player.volume_db = -12.0
	add_child(_wave_player)


func _make_wave_sound() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 0.34
	var sample_count := int(duration * float(mix_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var envelope := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var sweep := lerpf(260.0, 680.0, t / duration)
		var shimmer := sin(TAU * sweep * t) * 0.42
		shimmer += sin(TAU * (sweep * 1.5) * t) * 0.18
		var sample := clampf(shimmer * envelope * 0.34, -1.0, 1.0)
		var pcm := int(sample * 32767.0)
		if pcm < 0:
			pcm = 65536 + pcm
		data[i * 2] = pcm & 0xff
		data[i * 2 + 1] = (pcm >> 8) & 0xff

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav
