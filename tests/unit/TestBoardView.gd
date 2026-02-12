extends GdUnitTestSuite

func test_emits_no_moves_once_when_board_is_stalled() -> void:
	ProjectSettings.set_setting("lumarush/min_match_size", 3)
	var view := BoardView.new()
	view.width = 3
	view.height = 3
	view.colors = 3
	view.tile_size = 16.0
	get_tree().root.add_child(view)
	view.board.grid = [
		[0, 1, 2],
		[1, 2, 0],
		[2, 0, 1],
	]
	var emitted_count: Array[int] = [0]
	view.connect("no_moves", func() -> void:
		emitted_count[0] += 1
	)
	assert_that(view._check_no_moves_and_emit()).is_false()
	assert_that(view._check_no_moves_and_emit()).is_false()
	assert_that(emitted_count[0]).is_equal(1)
	view.queue_free()

func test_hint_group_is_selected_after_timeout() -> void:
	ProjectSettings.set_setting("lumarush/min_match_size", 3)
	var view := BoardView.new()
	view.width = 3
	view.height = 3
	view.colors = 3
	view.tile_size = 16.0
	get_tree().root.add_child(view)
	view.board.grid = [
		[0, 0, 0],
		[1, 2, 1],
		[2, 1, 2],
	]
	view._on_hint_timeout()
	assert_that(view._hint_group.size()).is_equal(3)
	view.queue_free()

func test_hint_timer_uses_configured_delay() -> void:
	ProjectSettings.set_setting("lumarush/match_hint_delay_seconds", 3.0)
	var view := BoardView.new()
	get_tree().root.add_child(view)
	view._restart_hint_timer()
	assert_that(view._hint_timer.wait_time).is_equal(3.0)
	view.queue_free()

func test_hint_timeout_restarts_when_animating() -> void:
	ProjectSettings.set_setting("lumarush/match_hint_delay_seconds", 0.2)
	var view := BoardView.new()
	get_tree().root.add_child(view)
	view._animating = true
	view._hint_timer.stop()
	view._on_hint_timeout()
	assert_that(view._hint_timer.is_stopped()).is_false()
	view.queue_free()

func test_initial_board_respects_required_matches_normalizer() -> void:
	ProjectSettings.set_setting("lumarush/gameplay_matches_normalizer", 2.0)
	ProjectSettings.set_setting("lumarush/min_match_size", 3)
	var view := BoardView.new()
	view.width = 5
	view.height = 5
	view.colors = 4
	get_tree().root.add_child(view)
	assert_that(view.board.count_available_matches()).is_greater_equal(2)
	view.queue_free()
