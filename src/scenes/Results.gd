extends Control

@onready var score_label: Label = $UI/VBox/Score
@onready var best_label: Label = $UI/VBox/Best
@onready var streak_label: Label = $UI/VBox/Streak
@onready var online_status_label: Label = $UI/VBox/OnlineStatus
@onready var leaderboard_label: Label = $UI/VBox/Leaderboard

func _ready() -> void:
	BackgroundMood.register_controller($BackgroundController)
	BackgroundMood.set_mood(BackgroundMood.Mood.CALM)
	MusicManager.fade_to_calm(0.6)
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController)
	Typography.style_results(self)
	_update_labels()
	_bind_online_signals()
	_sync_online_results()
	_play_intro()
	if StreakManager.is_streak_at_risk():
		var modal := preload("res://src/scenes/SaveStreakModal.tscn").instantiate()
		add_child(modal)

func _update_labels() -> void:
	score_label.text = "%d" % RunManager.last_score
	var local_best: int = int(SaveStore.data["high_score"])
	var online_record: Dictionary = NakamaService.get_my_high_score()
	var online_best: int = int(online_record.get("score", 0))
	var online_rank: int = int(online_record.get("rank", 0))
	var best_value: int = max(local_best, online_best)
	if online_best > 0 and online_rank > 0:
		best_label.text = "Best: %d (Global #%d)" % [best_value, online_rank]
	else:
		best_label.text = "Best: %d" % best_value
	streak_label.text = "Streak: %d" % StreakManager.get_streak_days()
	online_status_label.text = "Online: %s" % NakamaService.get_online_status()
	leaderboard_label.text = _format_leaderboard(NakamaService.get_leaderboard_records())

func _on_play_again_pressed() -> void:
	AdManager.maybe_show_interstitial()
	RunManager.start_game()

func _on_menu_pressed() -> void:
	RunManager.goto_menu()

func _play_intro() -> void:
	var ui: CanvasItem = $UI
	var bloom: CanvasItem = $UI/PanelBloom
	var panel: CanvasItem = $UI/Panel
	var box: CanvasItem = $UI/VBox
	var play_again: CanvasItem = $UI/VBox/PlayAgain
	var menu: CanvasItem = $UI/VBox/Menu
	ui.modulate.a = 0.0
	bloom.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	box.scale = Vector2(0.95, 0.95)
	play_again.modulate.a = 0.0
	menu.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(ui, "modulate:a", 1.0, 0.28)
	t.parallel().tween_property(bloom, "modulate:a", 1.0, 0.46)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(box, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(play_again, "modulate:a", 1.0, 0.16)
	t.tween_property(menu, "modulate:a", 1.0, 0.16)

func _bind_online_signals() -> void:
	if not NakamaService.online_state_changed.is_connected(_on_online_state_changed):
		NakamaService.online_state_changed.connect(_on_online_state_changed)
	if not NakamaService.high_score_updated.is_connected(_on_high_score_updated):
		NakamaService.high_score_updated.connect(_on_high_score_updated)
	if not NakamaService.leaderboard_updated.is_connected(_on_leaderboard_updated):
		NakamaService.leaderboard_updated.connect(_on_leaderboard_updated)

func _on_online_state_changed(status: String) -> void:
	online_status_label.text = "Online: %s" % status

func _on_high_score_updated(_record: Dictionary) -> void:
	_update_labels()

func _on_leaderboard_updated(records: Array) -> void:
	leaderboard_label.text = _format_leaderboard(records)

func _sync_online_results() -> void:
	await NakamaService.submit_score(RunManager.last_score, {
		"source": "results_ready",
	})
	await NakamaService.refresh_my_high_score()
	await NakamaService.refresh_leaderboard(5)

func _format_leaderboard(records: Array) -> String:
	if records.is_empty():
		return "Leaderboard: no online records yet"
	var lines: Array[String] = []
	var count: int = min(records.size(), 5)
	for i in range(count):
		var item: Variant = records[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = item
		var rank: int = int(row.get("rank", i + 1))
		var username: String = str(row.get("username", "Player"))
		var score: int = int(row.get("score", 0))
		lines.append("%d. %s - %d" % [rank, username, score])
	return "Leaderboard\n%s" % "\n".join(lines)

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		Typography.style_results(self)
