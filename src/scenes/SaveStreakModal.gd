extends Control

@onready var status_label: Label = $Panel/VBox/Status
@onready var save_button: Button = $Panel/VBox/SaveButton

var _rewarded_success := false

func _ready() -> void:
	# This modal is shown on Results while the tree is not paused.
	# Keep it interactive in both paused and unpaused states.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Typography.style_save_streak(self)
	if not AdManager.is_connected("rewarded_earned", Callable(self, "_on_rewarded_earned")):
		AdManager.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	if not AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		Typography.style_save_streak(self)

func _on_save_pressed() -> void:
	status_label.text = "Loading ad..."
	status_label.add_theme_color_override("font_color", Typography.SECONDARY_TEXT)
	save_button.disabled = true
	if not AdManager.show_rewarded_for_save():
		status_label.text = "Ad not ready"
		status_label.add_theme_color_override("font_color", Typography.SECONDARY_TEXT)
		save_button.disabled = false

func _on_close_pressed() -> void:
	queue_free()

func _on_rewarded_earned() -> void:
	_rewarded_success = true
	status_label.text = "Streak saved!"
	status_label.add_theme_color_override("font_color", Typography.PRIMARY_TEXT)
	queue_free()

func _on_rewarded_closed() -> void:
	if _rewarded_success:
		return
	status_label.text = "Try again later"
	status_label.add_theme_color_override("font_color", Typography.SECONDARY_TEXT)
	save_button.disabled = false
