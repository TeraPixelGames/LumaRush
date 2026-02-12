extends GdUnitTestSuite

func before() -> void:
	ProjectSettings.set_setting("lumarush/audio_test_mode", false)
	ProjectSettings.set_setting("lumarush/visual_test_mode", false)
	ProjectSettings.set_setting("lumarush/combo_decay_delay_seconds", FeatureFlags.COMBO_DECAY_DELAY_SECONDS)
	ProjectSettings.set_setting("lumarush/combo_decay_seconds", FeatureFlags.COMBO_DECAY_SECONDS)
	ProjectSettings.set_setting("lumarush/combo_decay_target_db", FeatureFlags.COMBO_DECAY_TARGET_DB)
	ProjectSettings.set_setting("lumarush/audio_track_id", FeatureFlags.AUDIO_TRACK_ID)
	ProjectSettings.set_setting("lumarush/audio_track_manifest_path", FeatureFlags.AUDIO_TRACK_MANIFEST_PATH)

func test_set_calm_sets_floor() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	mm.set_calm()
	assert_that(mm.synth.volume_db).is_equal(0.0)
	assert_that(mm.bass.volume_db).is_equal(FeatureFlags.COMBO_FLOOR_DB)
	mm.queue_free()

func test_on_match_made_respects_audio_test_mode() -> void:
	ProjectSettings.set_setting("lumarush/audio_test_mode", true)
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	mm.on_match_made()
	assert_that(mm.drums.volume_db).is_equal(FeatureFlags.COMBO_FLOOR_DB)
	mm.queue_free()
	ProjectSettings.set_setting("lumarush/audio_test_mode", false)

func test_on_match_made_uses_configurable_decay_delay_and_target() -> void:
	ProjectSettings.set_setting("lumarush/combo_decay_delay_seconds", 0.2)
	ProjectSettings.set_setting("lumarush/combo_decay_seconds", 0.3)
	ProjectSettings.set_setting("lumarush/combo_decay_target_db", -20.0)
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	mm.set_calm()
	mm.on_match_made()
	assert_that(mm.drums.volume_db).is_equal(FeatureFlags.COMBO_PEAK_DB)
	await get_tree().create_timer(0.1).timeout
	assert_that(mm.drums.volume_db).is_equal(FeatureFlags.COMBO_PEAK_DB)
	await get_tree().create_timer(0.5).timeout
	assert_that(mm.drums.volume_db).is_less_equal(-19.0)
	mm.queue_free()

func test_register_and_switch_track() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	var synth_alt := AudioStreamGenerator.new()
	var bass_alt := AudioStreamGenerator.new()
	var drums_alt := AudioStreamGenerator.new()
	var fx_alt := AudioStreamGenerator.new()
	assert_that(mm.register_track("alt", synth_alt, bass_alt, drums_alt, fx_alt)).is_true()
	assert_that(mm.set_track("alt", false)).is_true()
	assert_that(mm.get_current_track_id()).is_equal("alt")
	assert_that(mm.synth.stream).is_equal(synth_alt)
	assert_that(mm.bass.stream).is_equal(bass_alt)
	assert_that(mm.drums.stream).is_equal(drums_alt)
	assert_that(mm.fx.stream).is_equal(fx_alt)
	mm.queue_free()

func test_set_track_falls_back_to_default() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	assert_that(mm.set_track("does_not_exist", false)).is_true()
	assert_that(mm.get_current_track_id()).is_equal("default")
	assert_that(mm.list_track_ids().has("default")).is_true()
	mm.queue_free()

func test_builtin_glassgrid_track_is_registered() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	assert_that(mm.list_track_ids().has("glassgrid")).is_true()
	assert_that(mm.set_track("glassgrid", false)).is_true()
	assert_that(mm.get_current_track_id()).is_equal("glassgrid")
	assert_that((mm.synth.stream as AudioStream).resource_path).contains("/glassgrid/background_layer.ogg")
	assert_that((mm.bass.stream as AudioStream).resource_path).contains("/glassgrid/hype_layer.ogg")
	assert_that((mm.drums.stream as AudioStream).resource_path).contains("/glassgrid/match_layer.ogg")
	assert_that((mm.fx.stream as AudioStream).resource_path).contains("/glassgrid/fx_layer.ogg")
	mm.queue_free()

func test_off_track_mutes_music_bus_without_stopping_stems() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	mm.start_all_synced()
	assert_that(mm.synth.playing).is_true()
	assert_that(mm.bass.playing).is_true()
	assert_that(mm.set_track("off", true)).is_true()
	var music_bus: int = AudioServer.get_bus_index("Music")
	assert_that(music_bus).is_greater_equal(0)
	assert_that(AudioServer.is_bus_mute(music_bus)).is_true()
	assert_that(mm.synth.playing).is_true()
	assert_that(mm.bass.playing).is_true()
	assert_that(str(SaveStore.data["selected_track_id"])).is_equal("off")
	mm.queue_free()

func test_visual_mode_pins_default_track() -> void:
	SaveStore.data["selected_track_id"] = "glassgrid"
	ProjectSettings.set_setting("lumarush/visual_test_mode", true)
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	assert_that(mm.get_current_track_id()).is_equal("default")
	mm.queue_free()
	ProjectSettings.set_setting("lumarush/visual_test_mode", false)

func test_set_track_starts_players_when_not_already_running() -> void:
	var mm := preload("res://src/audio/MusicManager.tscn").instantiate()
	get_tree().root.add_child(mm)
	assert_that(mm.synth.playing).is_false()
	assert_that(mm.set_track("glassgrid", true)).is_true()
	assert_that(mm.synth.playing).is_true()
	assert_that(mm.bass.playing).is_true()
	assert_that(mm.drums.playing).is_true()
	assert_that(mm.fx.playing).is_true()
	assert_that(mm.synth.stream_paused).is_false()
	assert_that(mm.bass.stream_paused).is_false()
	mm.queue_free()
