extends Control

signal resume
signal quit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_resume_pressed() -> void:
	emit_signal("resume")
	queue_free()

func _on_quit_pressed() -> void:
	emit_signal("quit")
	queue_free()
