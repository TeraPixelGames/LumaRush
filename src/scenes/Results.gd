extends Control

@onready var score_label: Label = $UI/VBox/Score
@onready var best_label: Label = $UI/VBox/Best
@onready var streak_label: Label = $UI/VBox/Streak

func _ready() -> void:
	BackgroundMood.register_controller($BackgroundController)
	BackgroundMood.set_mood(BackgroundMood.Mood.CALM)
	MusicManager.fade_to_calm(0.6)
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController/Particles)
	_update_labels()
	_play_intro()
	if StreakManager.is_streak_at_risk():
		var modal := preload("res://src/scenes/SaveStreakModal.tscn").instantiate()
		add_child(modal)

func _update_labels() -> void:
	score_label.text = "Score: %d" % RunManager.last_score
	best_label.text = "Best: %d" % int(SaveStore.data["high_score"])
	streak_label.text = "Streak: %d" % StreakManager.get_streak_days()

func _on_play_again_pressed() -> void:
	RunManager.start_game()

func _on_menu_pressed() -> void:
	RunManager.goto_menu()

func _play_intro() -> void:
	var ui: CanvasItem = $UI
	var panel: CanvasItem = $UI/Panel
	var box: CanvasItem = $UI/VBox
	var play_again: CanvasItem = $UI/VBox/PlayAgain
	var menu: CanvasItem = $UI/VBox/Menu
	ui.modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	play_again.modulate.a = 0.0
	menu.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(ui, "modulate:a", 1.0, 0.35)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.35)
	t.tween_property(play_again, "modulate:a", 1.0, 0.16)
	t.tween_property(menu, "modulate:a", 1.0, 0.16)
