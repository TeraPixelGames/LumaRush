extends Node

func _ready() -> void:
	if FeatureFlags.clear_high_score_on_boot():
		SaveStore.clear_high_score()
	MusicManager.start_all_synced()
	call_deferred("_go_menu")

func _go_menu() -> void:
	RunManager.goto_menu()
