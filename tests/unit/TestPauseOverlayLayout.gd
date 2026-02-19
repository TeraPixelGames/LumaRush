extends GdUnitTestSuite

func test_pause_overlay_scales_for_wide_short_viewports() -> void:
	var original_window_size: Vector2i = DisplayServer.window_get_size()
	var scene: PackedScene = load("res://src/scenes/PauseOverlay.tscn") as PackedScene
	var pause_overlay: Control = scene.instantiate() as Control
	assert_that(pause_overlay).is_not_null()
	get_tree().root.add_child(pause_overlay)
	await get_tree().process_frame

	var panel: Control = pause_overlay.get_node_or_null("Panel") as Control
	var resume_button: Control = pause_overlay.get_node_or_null("VBox/Resume") as Control
	var quit_button: Control = pause_overlay.get_node_or_null("VBox/Quit") as Control
	assert_that(panel).is_not_null()
	assert_that(resume_button).is_not_null()
	assert_that(quit_button).is_not_null()

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
		pause_overlay.call("_layout_overlay")
		await get_tree().process_frame
		var viewport_rect := Rect2(Vector2.ZERO, pause_overlay.get_viewport_rect().size)
		var panel_rect: Rect2 = panel.get_global_rect()
		var resume_rect: Rect2 = resume_button.get_global_rect()
		var quit_rect: Rect2 = quit_button.get_global_rect()
		_assert_rect_inside(panel_rect, viewport_rect)
		_assert_rect_inside(resume_rect, panel_rect)
		_assert_rect_inside(quit_rect, panel_rect)
		assert_that(panel_rect.size.x).is_less_equal(viewport_rect.size.x * 0.68)

	DisplayServer.window_set_size(original_window_size)
	pause_overlay.queue_free()

func _assert_rect_inside(inner: Rect2, outer: Rect2, epsilon: float = 1.0) -> void:
	assert_that(inner.position.x).is_greater_equal(outer.position.x - epsilon)
	assert_that(inner.position.y).is_greater_equal(outer.position.y - epsilon)
	assert_that(inner.position.x + inner.size.x).is_less_equal(outer.position.x + outer.size.x + epsilon)
	assert_that(inner.position.y + inner.size.y).is_less_equal(outer.position.y + outer.size.y + epsilon)
