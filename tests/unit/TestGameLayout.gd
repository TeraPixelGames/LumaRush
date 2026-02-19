extends GdUnitTestSuite

func test_gameplay_layout_stays_inside_wide_short_viewports() -> void:
	var original_window_size: Vector2i = DisplayServer.window_get_size()
	var scene: PackedScene = load("res://src/scenes/Game.tscn") as PackedScene
	var game: Control = scene.instantiate() as Control
	assert_that(game).is_not_null()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	var board: BoardView = game.get_node_or_null("BoardView") as BoardView
	var top_bar: Control = game.get_node_or_null("UI/TopBar") as Control
	var powerups_row: Control = game.get_node_or_null("UI/Powerups") as Control
	var undo_button: Control = game.get_node_or_null("UI/Powerups/Undo") as Control
	assert_that(board).is_not_null()
	assert_that(top_bar).is_not_null()
	assert_that(powerups_row).is_not_null()
	assert_that(undo_button).is_not_null()

	var viewport_sizes: Array[Vector2] = [
		Vector2(1920.0, 1010.0),
		Vector2(1920.0, 720.0),
		Vector2(2560.0, 900.0),
		Vector2(2560.0, 720.0),
	]
	for size in viewport_sizes:
		DisplayServer.window_set_size(Vector2i(size))
		await get_tree().process_frame
		await get_tree().process_frame
		game.call("_center_board")
		await get_tree().process_frame
		var viewport_rect := Rect2(Vector2.ZERO, game.get_viewport_rect().size)
		var top_rect: Rect2 = top_bar.get_global_rect()
		var powerups_rect: Rect2 = powerups_row.get_global_rect()
		var undo_rect: Rect2 = undo_button.get_global_rect()
		var board_rect := Rect2(
			board.global_position,
			Vector2(float(board.width) * board.tile_size, float(board.height) * board.tile_size)
		)
		_assert_rect_inside(top_rect, viewport_rect)
		_assert_rect_inside(powerups_rect, viewport_rect)
		_assert_rect_inside(undo_rect, viewport_rect)
		assert_that(board_rect.position.x).is_greater_equal(0.0)
		assert_that(board_rect.position.x + board_rect.size.x).is_less_equal(viewport_rect.size.x + 1.0)
		assert_that(board_rect.position.y).is_greater_equal(top_rect.position.y + top_rect.size.y - 1.0)
		assert_that(board_rect.position.y + board_rect.size.y).is_less_equal(powerups_rect.position.y + 1.0)

	DisplayServer.window_set_size(original_window_size)
	game.queue_free()

func _assert_rect_inside(inner: Rect2, outer: Rect2, epsilon: float = 1.0) -> void:
	assert_that(inner.position.x).is_greater_equal(outer.position.x - epsilon)
	assert_that(inner.position.y).is_greater_equal(outer.position.y - epsilon)
	assert_that(inner.position.x + inner.size.x).is_less_equal(outer.position.x + outer.size.x + epsilon)
	assert_that(inner.position.y + inner.size.y).is_less_equal(outer.position.y + outer.size.y + epsilon)
