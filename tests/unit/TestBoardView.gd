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

func test_restore_snapshot_restores_grid_state() -> void:
	ProjectSettings.set_setting("lumarush/min_match_size", 3)
	var view := BoardView.new()
	view.width = 3
	view.height = 3
	view.colors = 3
	view.tile_size = 16.0
	get_tree().root.add_child(view)
	var snapshot: Array = [
		[0, 0, 0],
		[1, 2, 1],
		[2, 1, 2],
	]
	view.restore_snapshot(snapshot)
	assert_that(view.board.grid).is_equal(snapshot)
	view.queue_free()

func test_remove_color_powerup_removes_tiles() -> void:
	ProjectSettings.set_setting("lumarush/min_match_size", 3)
	var view := BoardView.new()
	view.width = 3
	view.height = 3
	view.colors = 3
	view.tile_size = 16.0
	get_tree().root.add_child(view)
	view.board.grid = [
		[0, 0, 1],
		[1, 0, 2],
		[2, 1, 2],
	]
	view._refresh_tiles()
	var result: Dictionary = await view.apply_remove_color_powerup(0)
	assert_that(int(result.get("removed", 0))).is_equal(3)
	view.queue_free()

func test_cell_from_screen_pos_accounts_for_board_position() -> void:
	var view := BoardView.new()
	view.width = 8
	view.height = 10
	view.tile_size = 96.0
	view.position = Vector2(156, 420)
	get_tree().root.add_child(view)
	var cell: Vector2i = view._cell_from_screen_pos(Vector2(156 + 96 * 2 + 8, 420 + 96 * 3 + 8))
	assert_that(cell).is_equal(Vector2i(2, 3))
	view.queue_free()

func test_match_haptic_signal_emits_when_enabled() -> void:
	ProjectSettings.set_setting("lumarush/haptics_enabled", true)
	ProjectSettings.set_setting("lumarush/match_haptic_duration_ms", 20)
	ProjectSettings.set_setting("lumarush/match_haptic_amplitude", 0.4)
	var view := BoardView.new()
	get_tree().root.add_child(view)
	var emitted: bool = false
	var emitted_ms: int = -1
	var emitted_amp: float = -1.0
	view.connect("match_haptic_triggered", func(ms: int, amp: float) -> void:
		emitted = true
		emitted_ms = ms
		emitted_amp = amp
	)
	assert_that(view._trigger_match_haptic()).is_true()
	assert_that(emitted).is_true()
	assert_that(emitted_ms).is_equal(20)
	assert_that(emitted_amp).is_equal(0.4)
	view.queue_free()

func test_match_haptic_disabled_does_not_emit() -> void:
	ProjectSettings.set_setting("lumarush/haptics_enabled", false)
	var view := BoardView.new()
	get_tree().root.add_child(view)
	var emitted: bool = false
	view.connect("match_haptic_triggered", func(_ms: int, _amp: float) -> void:
		emitted = true
	)
	assert_that(view._trigger_match_haptic()).is_false()
	assert_that(emitted).is_false()
	view.queue_free()

func test_match_click_haptic_signal_emits_when_enabled() -> void:
	ProjectSettings.set_setting("lumarush/haptics_enabled", true)
	ProjectSettings.set_setting("lumarush/match_click_haptic_duration_ms", 12)
	ProjectSettings.set_setting("lumarush/match_click_haptic_amplitude", 0.3)
	var view := BoardView.new()
	get_tree().root.add_child(view)
	var emitted: bool = false
	var emitted_ms: int = -1
	var emitted_amp: float = -1.0
	view.connect("match_click_haptic_triggered", func(ms: int, amp: float) -> void:
		emitted = true
		emitted_ms = ms
		emitted_amp = amp
	)
	assert_that(view._trigger_match_click_haptic()).is_true()
	assert_that(emitted).is_true()
	assert_that(emitted_ms).is_equal(12)
	assert_that(emitted_amp).is_equal(0.3)
	view.queue_free()
