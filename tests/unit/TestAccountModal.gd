extends GdUnitTestSuite

func test_account_modal_close_button_dismisses_modal() -> void:
	var modal_scene: PackedScene = load("res://src/scenes/AccountModal.tscn")
	var modal: Control = modal_scene.instantiate() as Control
	assert_that(modal).is_not_null()
	if modal == null:
		return
	get_tree().root.add_child(modal)
	await get_tree().process_frame

	var close_button: Button = modal.get_node_or_null("Panel/VBox/Footer/Close") as Button
	assert_that(close_button).is_not_null()
	if close_button == null:
		modal.queue_free()
		await get_tree().process_frame
		return
	close_button.emit_signal("pressed")
	await get_tree().create_timer(0.25).timeout
	assert_that(is_instance_valid(modal)).is_false()

func test_account_modal_shows_logout_for_linked_profile() -> void:
	var original_user_id: String = SaveStore.get_terapixel_user_id()
	var original_name: String = SaveStore.get_terapixel_display_name()
	var original_email: String = SaveStore.get_terapixel_email()
	SaveStore.set_terapixel_identity("profile_linked_1", "Linked", "linked@example.com")

	var modal_scene: PackedScene = load("res://src/scenes/AccountModal.tscn")
	var modal: Control = modal_scene.instantiate() as Control
	assert_that(modal).is_not_null()
	if modal == null:
		SaveStore.set_terapixel_identity(original_user_id, original_name, original_email)
		return
	get_tree().root.add_child(modal)
	await get_tree().process_frame

	var email_input: LineEdit = modal.get_node_or_null("Panel/VBox/Scroll/Content/Email") as LineEdit
	var send_button: Button = modal.get_node_or_null("Panel/VBox/Scroll/Content/SendMagicLink") as Button
	assert_that(email_input).is_not_null()
	assert_that(send_button).is_not_null()
	if email_input == null or send_button == null:
		modal.queue_free()
		await get_tree().process_frame
		SaveStore.set_terapixel_identity(original_user_id, original_name, original_email)
		return
	assert_that(email_input.editable).is_false()
	assert_that(email_input.text).is_equal("linked@example.com")
	assert_that(send_button.text).is_equal("Logout")

	modal.queue_free()
	await get_tree().process_frame
	SaveStore.set_terapixel_identity(original_user_id, original_name, original_email)
