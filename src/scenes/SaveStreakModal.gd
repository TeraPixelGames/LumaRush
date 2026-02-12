extends Control

@onready var status_label: Label = $Panel/VBox/Status
@onready var save_button: Button = $Panel/VBox/SaveButton

var _rewarded_success := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	AdManager.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	AdManager.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _on_save_pressed() -> void:
	status_label.text = "Loading ad..."
	save_button.disabled = true
	if not AdManager.show_rewarded_for_save():
		status_label.text = "Ad not ready"
		save_button.disabled = false

func _on_close_pressed() -> void:
	queue_free()

func _on_rewarded_earned() -> void:
	_rewarded_success = true
	status_label.text = "Streak saved!"
	queue_free()

func _on_rewarded_closed() -> void:
	if _rewarded_success:
		return
	status_label.text = "Try again later"
	save_button.disabled = false
