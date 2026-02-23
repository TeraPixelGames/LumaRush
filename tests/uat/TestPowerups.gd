extends GdUnitTestSuite

func before() -> void:
	ProjectSettings.set_setting("lumarush/powerup_undo_charges", 1)
	ProjectSettings.set_setting("lumarush/powerup_remove_color_charges", 1)
	ProjectSettings.set_setting("lumarush/powerup_hint_charges", 1)
	ProjectSettings.set_setting("lumarush/visual_test_mode", true)
	ProjectSettings.set_setting("lumarush/audio_test_mode", true)
	ProjectSettings.set_setting("lumarush/use_mock_ads", true)
	RunManager.set_selected_mode("OPEN", "test")

func test_remove_color_and_undo_restore_board() -> void:
	var game: Control = await _spawn_game()
	var board_view: BoardView = game.get_node("BoardView") as BoardView
	var custom_grid: Array = []
	for y in range(board_view.height):
		var row: Array = []
		for x in range(board_view.width):
			row.append((x + y) % 3)
		custom_grid.append(row)
	board_view.board.grid = custom_grid
	board_view._refresh_tiles()
	var before: Array = board_view.capture_snapshot()
	var prism_badge: Label = game.get_node("UI/Powerups/RemoveColor/Badge/Value") as Label
	game._on_remove_color_pressed()
	assert_that(prism_badge.text).is_equal("Tap Color")
	await game._on_prism_color_selected(0)
	for _i in range(90):
		await get_tree().process_frame
		if prism_badge.text != "Tap Color":
			break
	assert_that(prism_badge.text).is_not_equal("Tap Color")
	game._on_undo_pressed()
	await get_tree().process_frame
	assert_that(board_view.capture_snapshot()).is_equal(before)
	game.queue_free()
	await get_tree().process_frame

func test_hint_consumes_charge() -> void:
	var game: Control = await _spawn_game()
	await game._on_hint_pressed()
	var hint_badge: Label = game.get_node("UI/Powerups/Hint/Badge/Value") as Label
	assert_that(hint_badge.visible).is_false()
	game.queue_free()
	await get_tree().process_frame

func test_depleted_button_reward_grants_that_powerup() -> void:
	ProjectSettings.set_setting("lumarush/powerup_undo_charges", 0)
	ProjectSettings.set_setting("lumarush/powerup_remove_color_charges", 0)
	ProjectSettings.set_setting("lumarush/powerup_hint_charges", 0)
	var game: Control = await _spawn_game()
	var undo_badge: Label = game.get_node("UI/Powerups/Undo/Badge/Value") as Label
	assert_that(undo_badge.visible).is_false()
	await game._on_undo_pressed()
	for _i in range(120):
		await get_tree().process_frame
		if undo_badge.visible and undo_badge.text.contains("x1"):
			break
	assert_that(undo_badge.visible).is_true()
	assert_that(undo_badge.text).contains("x1")
	game.queue_free()
	await get_tree().process_frame

func _spawn_game() -> Control:
	var scene: PackedScene = load("res://src/scenes/Game.tscn") as PackedScene
	var game: Control = scene.instantiate() as Control
	get_tree().root.add_child(game)
	await get_tree().process_frame
	return game
