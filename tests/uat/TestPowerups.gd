extends GdUnitTestSuite

func before() -> void:
	ProjectSettings.set_setting("lumarush/powerup_undo_charges", 1)
	ProjectSettings.set_setting("lumarush/powerup_remove_color_charges", 1)
	ProjectSettings.set_setting("lumarush/powerup_shuffle_charges", 1)
	ProjectSettings.set_setting("lumarush/visual_test_mode", true)
	ProjectSettings.set_setting("lumarush/audio_test_mode", true)
	ProjectSettings.set_setting("lumarush/use_mock_ads", true)

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
	await game._on_remove_color_pressed()
	var remove_button: Button = game.get_node("UI/Powerups/RemoveColor") as Button
	assert_that(remove_button.text).contains("x0")
	game._on_undo_pressed()
	assert_that(board_view.capture_snapshot()).is_equal(before)
	var undo_button: Button = game.get_node("UI/Powerups/Undo") as Button
	assert_that(undo_button.text).contains("x0")
	game.queue_free()
	await get_tree().process_frame

func test_shuffle_consumes_charge() -> void:
	var game: Control = await _spawn_game()
	await game._on_shuffle_pressed()
	var shuffle_button: Button = game.get_node("UI/Powerups/Shuffle") as Button
	assert_that(shuffle_button.text).contains("x0")
	game.queue_free()
	await get_tree().process_frame

func test_depleted_button_reward_grants_that_powerup() -> void:
	ProjectSettings.set_setting("lumarush/powerup_undo_charges", 0)
	ProjectSettings.set_setting("lumarush/powerup_remove_color_charges", 0)
	ProjectSettings.set_setting("lumarush/powerup_shuffle_charges", 0)
	var game: Control = await _spawn_game()
	var undo_button: Button = game.get_node("UI/Powerups/Undo") as Button
	assert_that(undo_button.text).contains("Watch Ad")
	game._on_undo_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_that(undo_button.text).contains("x1")
	game.queue_free()
	await get_tree().process_frame

func _spawn_game() -> Control:
	var scene: PackedScene = load("res://src/scenes/Game.tscn") as PackedScene
	var game: Control = scene.instantiate() as Control
	get_tree().root.add_child(game)
	await get_tree().process_frame
	return game
