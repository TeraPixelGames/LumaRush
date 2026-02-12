extends Node

# Scene expectation:
# MusicManager node has 4 child AudioStreamPlayer nodes:
#   $Synth -> background layer
#   $Bass  -> hype layer
#   $Drums -> match layer
#   $Fx    -> fx layer
#
# All stems must be loop-enabled and start in sync once.
# Never restart stems individually; only adjust volume_db.

const DEFAULT_SYNTH: AudioStream = preload("res://assets/stems/default/background_layer.ogg")
const DEFAULT_BASS: AudioStream = preload("res://assets/stems/default/hype_layer.ogg")
const DEFAULT_DRUMS: AudioStream = preload("res://assets/stems/default/match_layer.ogg")
const DEFAULT_FX: AudioStream = preload("res://assets/stems/default/fx_layer.ogg")

const GLASSGRID_SYNTH: AudioStream = preload("res://assets/stems/glassgrid/background_layer.ogg")
const GLASSGRID_BASS: AudioStream = preload("res://assets/stems/glassgrid/hype_layer.ogg")
const GLASSGRID_DRUMS: AudioStream = preload("res://assets/stems/glassgrid/match_layer.ogg")
const GLASSGRID_FX: AudioStream = preload("res://assets/stems/glassgrid/fx_layer.ogg")

var synth: AudioStreamPlayer
var bass: AudioStreamPlayer
var drums: AudioStreamPlayer
var fx: AudioStreamPlayer

var _drums_fade_tween: Tween
var _mix_fade_tween: Tween
var _fx_cooldown_until_ms := 0
var _tracks: Dictionary = {}
var _current_track_id: String = ""
var _friendly_names := {
	"default": "Luma Theme",
	"glassgrid": "Neon Drift",
	"off": "Off",
}

func _ready() -> void:
	_ensure_music_bus()
	synth = _ensure_player("Synth")
	bass = _ensure_player("Bass")
	drums = _ensure_player("Drums")
	fx = _ensure_player("Fx")
	_register_builtin_tracks()
	_load_tracks_from_manifest(FeatureFlags.audio_track_manifest_path())
	set_track(_initial_track_id(), false)

func start_all_synced() -> void:
	if _current_track_id.is_empty():
		set_track(_initial_track_id(), false)
	for p in [synth, bass, drums, fx]:
		p.stream_paused = false
		p.play()
	set_calm()

func set_calm() -> void:
	synth.volume_db = 0.0
	bass.volume_db  = FeatureFlags.COMBO_FLOOR_DB
	drums.volume_db = FeatureFlags.COMBO_FLOOR_DB
	fx.volume_db    = FeatureFlags.COMBO_FLOOR_DB

func fade_out_hype_layers(duration: float = 0.45) -> void:
	if is_instance_valid(_mix_fade_tween):
		_mix_fade_tween.kill()
	_mix_fade_tween = create_tween()
	_mix_fade_tween.set_parallel(true)
	_mix_fade_tween.tween_property(drums, "volume_db", FeatureFlags.COMBO_FLOOR_DB, duration)
	_mix_fade_tween.tween_property(fx, "volume_db", FeatureFlags.COMBO_FLOOR_DB, duration)

func fade_to_calm(duration: float = 0.5) -> void:
	if is_instance_valid(_mix_fade_tween):
		_mix_fade_tween.kill()
	_mix_fade_tween = create_tween()
	_mix_fade_tween.set_parallel(true)
	_mix_fade_tween.tween_property(synth, "volume_db", 0.0, duration)
	_mix_fade_tween.tween_property(bass, "volume_db", FeatureFlags.COMBO_FLOOR_DB, duration)
	_mix_fade_tween.tween_property(drums, "volume_db", FeatureFlags.COMBO_FLOOR_DB, duration)
	_mix_fade_tween.tween_property(fx, "volume_db", FeatureFlags.COMBO_FLOOR_DB, duration)

func set_gameplay() -> void:
	# Fade bass in for gameplay energy bed
	var t := create_tween()
	t.tween_property(bass, "volume_db", -8.0, 0.5)

func on_match_made() -> void:
	if FeatureFlags.is_audio_test_mode():
		return

	if is_instance_valid(_drums_fade_tween):
		_drums_fade_tween.kill()

	drums.volume_db = FeatureFlags.COMBO_PEAK_DB
	_drums_fade_tween = create_tween()
	_drums_fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drums_fade_tween.tween_interval(FeatureFlags.combo_decay_delay_seconds())
	_drums_fade_tween.tween_property(
		drums,
		"volume_db",
		FeatureFlags.combo_decay_target_db(),
		FeatureFlags.combo_decay_seconds()
	)

func maybe_trigger_high_combo_fx() -> void:
	if FeatureFlags.is_audio_test_mode():
		return

	var now := Time.get_ticks_msec()
	if now < _fx_cooldown_until_ms:
		return
	_fx_cooldown_until_ms = now + int(FeatureFlags.FX_COOLDOWN_SECONDS * 1000.0)

	# Treat fx loop as a short accent envelope (no restarts).
	fx.volume_db = -10.0
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(fx, "volume_db", FeatureFlags.COMBO_FLOOR_DB, 0.6)

func set_ads_paused(paused: bool) -> void:
	for p in [synth, bass, drums, fx]:
		p.stream_paused = paused

func set_ads_ducked(ducked: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, -12.0 if ducked else 0.0)

func list_track_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in _tracks.keys():
		ids.append(str(id))
	ids.append("off")
	ids.sort()
	return ids

func get_available_tracks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in list_track_ids():
		out.append({
			"id": id,
			"name": _friendly_names.get(id, id.capitalize()),
		})
	return out

func get_current_track_id() -> String:
	return _current_track_id

func register_track(id: String, synth_stream: AudioStream, bass_stream: AudioStream, drums_stream: AudioStream, fx_stream: AudioStream) -> bool:
	if id.is_empty():
		return false
	if synth_stream == null or bass_stream == null or drums_stream == null or fx_stream == null:
		return false
	_tracks[id] = {
		"synth": synth_stream,
		"bass": bass_stream,
		"drums": drums_stream,
		"fx": fx_stream,
	}
	return true

func set_track(id: String, restart_if_playing: bool = true) -> bool:
	if id == "off":
		_set_music_bus_muted(true)
		_current_track_id = id
		SaveStore.set_selected_track_id(id)
		return true
	if not _tracks.has(id):
		if _tracks.has("default"):
			id = "default"
		else:
			return false
	var data: Dictionary = _tracks[id]
	synth.stream = data["synth"] as AudioStream
	bass.stream = data["bass"] as AudioStream
	drums.stream = data["drums"] as AudioStream
	fx.stream = data["fx"] as AudioStream
	if restart_if_playing:
		for p in [synth, bass, drums, fx]:
			p.stop()
			p.stream_paused = false
			p.play()
	_set_music_bus_muted(false)
	_current_track_id = id
	SaveStore.set_selected_track_id(id)
	return true

func _register_builtin_tracks() -> void:
	register_track(
		"default",
		DEFAULT_SYNTH,
		DEFAULT_BASS,
		DEFAULT_DRUMS,
		DEFAULT_FX
	)
	register_track(
		"glassgrid",
		GLASSGRID_SYNTH,
		GLASSGRID_BASS,
		GLASSGRID_DRUMS,
		GLASSGRID_FX
	)

func _ensure_player(node_name: String) -> AudioStreamPlayer:
	var existing: Node = get_node_or_null(node_name)
	if existing is AudioStreamPlayer:
		var existing_player: AudioStreamPlayer = existing as AudioStreamPlayer
		existing_player.bus = "Music"
		return existing_player
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = "Music"
	player.stream_paused = true
	add_child(player)
	return player

func _initial_track_id() -> String:
	var pinned: String = VisualTestMode.pinned_track_id_or_empty()
	if not pinned.is_empty():
		return pinned
	var saved: String = str(SaveStore.data.get("selected_track_id", ""))
	if not saved.is_empty():
		return saved
	return FeatureFlags.audio_track_id()

func _music_bus_index() -> int:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx != -1:
		return idx
	return AudioServer.get_bus_index("Master")

func _set_music_bus_muted(muted: bool) -> void:
	var idx: int = _music_bus_index()
	if idx != -1:
		AudioServer.set_bus_mute(idx, muted)

func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		return
	var index: int = AudioServer.get_bus_count()
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, "Music")

func _load_tracks_from_manifest(path: String) -> void:
	if path.is_empty():
		return
	if not FileAccess.file_exists(path):
		return
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		return
	if parsed is Dictionary:
		_register_track_entry(parsed as Dictionary)
		return
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				_register_track_entry(entry as Dictionary)

func _register_track_entry(entry: Dictionary) -> void:
	var id: String = str(entry.get("id", ""))
	var synth_path: String = str(entry.get("synth", ""))
	var bass_path: String = str(entry.get("bass", ""))
	var drums_path: String = str(entry.get("drums", ""))
	var fx_path: String = str(entry.get("fx", ""))
	if id.is_empty() or synth_path.is_empty() or bass_path.is_empty() or drums_path.is_empty() or fx_path.is_empty():
		return
	if not FileAccess.file_exists(synth_path):
		return
	if not FileAccess.file_exists(bass_path):
		return
	if not FileAccess.file_exists(drums_path):
		return
	if not FileAccess.file_exists(fx_path):
		return
	register_track(
		id,
		load(synth_path) as AudioStream,
		load(bass_path) as AudioStream,
		load(drums_path) as AudioStream,
		load(fx_path) as AudioStream
	)
