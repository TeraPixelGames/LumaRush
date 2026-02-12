extends GdUnitTestSuite

func test_new_mood_change_cancels_previous_fade() -> void:
	var controller: BackgroundController = preload("res://src/visual/BackgroundController.tscn").instantiate()
	get_tree().root.add_child(controller)
	await get_tree().process_frame

	controller.set_mood(BackgroundMood.Mood.CALM, 6.0)
	await get_tree().process_frame
	controller.set_mood(BackgroundMood.Mood.HYPE, 0.05)
	await get_tree().create_timer(0.1).timeout

	var mat: ShaderMaterial = controller.bg_rect.material
	var color_a: Color = mat.get_shader_parameter("color_a")
	assert_that(color_a.r).is_less_equal(0.25)
	assert_that(color_a.g).is_less_equal(0.35)
	assert_that(color_a.b).is_greater_equal(0.45)
	controller.queue_free()
