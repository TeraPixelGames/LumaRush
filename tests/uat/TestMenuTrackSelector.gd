extends GdUnitTestSuite

func test_main_menu_track_selection_updates_state_and_manager() -> void:
	var original_track: String = str(SaveStore.data.get("selected_track_id", "glassgrid"))
	var menu_scene: PackedScene = load("res://src/scenes/MainMenu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame

	var tracks: Array[Dictionary] = MusicManager.get_available_tracks()
	var target_index: int = 0
	for i in range(tracks.size()):
		if str(tracks[i].get("id", "")) == "glassgrid":
			target_index = i
			break
	menu._on_track_option_item_selected(target_index)

	assert_that(str(SaveStore.data["selected_track_id"])).is_equal("glassgrid")
	assert_that(MusicManager.get_current_track_id()).is_equal("glassgrid")

	menu.queue_free()
	MusicManager.set_track(original_track, false)

func test_off_track_stays_muted_after_ads_pause_resume() -> void:
	var original_track: String = str(SaveStore.data.get("selected_track_id", "glassgrid"))
	MusicManager.start_all_synced()
	MusicManager.set_track("off", true)
	var music_bus: int = AudioServer.get_bus_index("Music")
	assert_that(music_bus).is_greater_equal(0)
	assert_that(AudioServer.is_bus_mute(music_bus)).is_true()

	MusicManager.set_ads_paused(true)
	MusicManager.set_ads_paused(false)
	assert_that(AudioServer.is_bus_mute(music_bus)).is_true()

	MusicManager.set_track(original_track, false)
