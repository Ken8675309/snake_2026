extends Node
class_name AudioManager

var _players: Dictionary = {}
var _ambient_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _exit_tree() -> void:
	cleanup_runtime_objects()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		cleanup_runtime_objects()


func cleanup_runtime_objects() -> void:
	if _ambient_player != null:
		_ambient_player.stop()
		_ambient_player.stream = null
	for player_name in _players.keys():
		var player := _players[player_name] as AudioStreamPlayer
		if player == null:
			continue
		player.stop()
		player.stream = null
	_players.clear()


func play_eat() -> void:
	_play("eat", 0.96 + _rng.randf() * 0.08)


func play_power() -> void:
	_play("power", 0.92 + _rng.randf() * 0.12)


func play_shield_break() -> void:
	_play("shield", 0.96)


func play_crash() -> void:
	_play("crash", 0.92)


func play_start() -> void:
	_play("start", 1.0)


func _build_players() -> void:
	_create_player("eat", _make_tone([660.0, 990.0], 0.16, 0.28))
	_create_player("power", _make_tone([330.0, 660.0, 1320.0], 0.32, 0.3))
	_create_player("shield", _make_tone([520.0, 390.0, 260.0], 0.36, 0.32))
	_create_player("crash", _make_tone([110.0, 72.0, 44.0], 0.55, 0.44))
	_create_player("start", _make_tone([220.0, 330.0, 550.0], 0.42, 0.25))

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.stream = _make_ambient_loop()
	_ambient_player.volume_db = -24.0
	add_child(_ambient_player)


func _create_player(player_name: String, stream: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "%sPlayer" % player_name.capitalize()
	player.stream = stream
	player.volume_db = -7.0
	add_child(player)
	_players[player_name] = player


func _play(player_name: String, pitch: float) -> void:
	if _players.is_empty():
		_build_players()
		_play_ambient()
	if not _players.has(player_name):
		return
	var player := _players[player_name] as AudioStreamPlayer
	player.stop()
	player.pitch_scale = pitch
	player.play()


func _play_ambient() -> void:
	if _ambient_player != null:
		_ambient_player.play()


func _make_tone(frequencies: Array[float], duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate := 44100
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var envelope := _tone_envelope(t, duration)
		var sample := 0.0
		for f_index in range(frequencies.size()):
			var freq := frequencies[f_index]
			var sweep := freq * (1.0 + t * 0.28 * float(f_index + 1))
			sample += sin(TAU * sweep * t) / float(frequencies.size())
		sample = clampf(sample * envelope * volume, -1.0, 1.0)
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


func _make_ambient_loop() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 4.0
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var fade := minf(t / 0.5, minf((duration - t) / 0.5, 1.0))
		var sample := sin(TAU * 55.0 * t) * 0.08
		sample += sin(TAU * 82.5 * t + sin(t * 0.7) * 0.8) * 0.045
		sample += sin(TAU * 165.0 * t) * 0.02
		sample = clampf(sample * fade, -1.0, 1.0)
		var pcm := int(sample * 32767.0)
		if pcm < 0:
			pcm = 65536 + pcm
		data[i * 2] = pcm & 0xff
		data[i * 2 + 1] = (pcm >> 8) & 0xff

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = data
	return wav


func _tone_envelope(t: float, duration: float) -> float:
	var attack := 0.015
	var release := maxf(duration * 0.45, 0.08)
	var a := clampf(t / attack, 0.0, 1.0)
	var r := clampf((duration - t) / release, 0.0, 1.0)
	return a * r
