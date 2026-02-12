extends GdUnitTestSuite

const GOLDEN_DIR := "res://tests/goldens/"

func before() -> void:
	ProjectSettings.set_setting("lumarush/visual_test_mode", true)
	ProjectSettings.set_setting("lumarush/audio_test_mode", true)
	ProjectSettings.set_setting("lumarush/use_mock_ads", true)
	DisplayServer.window_set_size(FeatureFlags.GOLDEN_RESOLUTION)

func after() -> void:
	ProjectSettings.set_setting("lumarush/visual_test_mode", false)
	ProjectSettings.set_setting("lumarush/audio_test_mode", false)

func test_menu_calm() -> void:
	await _capture_and_compare("res://src/scenes/MainMenu.tscn", "menu_calm")

func test_gameplay_hype_lite() -> void:
	ProjectSettings.set_setting("lumarush/tile_blur_mode", FeatureFlags.TileBlurMode.LITE)
	await _capture_and_compare("res://src/scenes/Game.tscn", "game_hype_lite")

func test_gameplay_hype_heavy() -> void:
	ProjectSettings.set_setting("lumarush/tile_blur_mode", FeatureFlags.TileBlurMode.HEAVY)
	await _capture_and_compare("res://src/scenes/Game.tscn", "game_hype_heavy")

func test_results_calm() -> void:
	SaveStore.data["high_score"] = 1200
	RunManager.last_score = 800
	await _capture_and_compare("res://src/scenes/Results.tscn", "results_calm")

func test_save_streak_modal() -> void:
	SaveStore.data["streak_at_risk"] = 3
	RunManager.last_score = 500
	var scene := await _load_scene("res://src/scenes/Results.tscn")
	await _wait_frames(2)
	_capture_to_golden("save_streak_modal")
	scene.queue_free()

func test_pause_overlay() -> void:
	var scene := await _load_scene("res://src/scenes/Game.tscn")
	await _wait_frames(2)
	var pause := preload("res://src/scenes/PauseOverlay.tscn").instantiate()
	scene.add_child(pause)
	await _wait_frames(1)
	_capture_to_golden("pause_overlay")
	scene.queue_free()

func _load_scene(path: String) -> Node:
	var packed: PackedScene = load(path) as PackedScene
	var inst: Node = packed.instantiate()
	get_tree().root.add_child(inst)
	return inst

func _capture_and_compare(path: String, name: String) -> void:
	var scene := await _load_scene(path)
	await _wait_frames(2)
	_capture_to_golden(name)
	scene.queue_free()

func _capture_to_golden(name: String) -> void:
	var golden_path := GOLDEN_DIR + name + ".png"
	var capture_path := "user://tmp_" + name + ".png"
	ScreenshotUtil.capture_png(capture_path)
	if not FileAccess.file_exists(golden_path):
		var img := Image.load_from_file(capture_path)
		img.save_png(golden_path)
		return
	_compare_with_golden(capture_path, golden_path)

func _compare_with_golden(capture_path: String, golden_path: String) -> void:
	var img_new := Image.load_from_file(capture_path)
	var img_gold := Image.load_from_file(golden_path)
	assert_that(_images_similar(img_new, img_gold)).is_true()

func _images_similar(a: Image, b: Image) -> bool:
	if a.get_width() != b.get_width() or a.get_height() != b.get_height():
		return false
	var w := a.get_width()
	var h := a.get_height()
	var max_bad := int(w * h * 0.01)
	var bad := 0
	for y in range(h):
		for x in range(w):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if abs(ca.r - cb.r) > 0.05 or abs(ca.g - cb.g) > 0.05 or abs(ca.b - cb.b) > 0.05 or abs(ca.a - cb.a) > 0.05:
				bad += 1
				if bad > max_bad:
					return false
	return true

func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
