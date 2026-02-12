extends Control

@onready var board: BoardView = $BoardView
@onready var score_label: Label = $UI/TopBar/Score

var score := 0
var combo := 0
const HIGH_COMBO_THRESHOLD := 4
var _run_finished: bool = false
var _ending_transition_started: bool = false

func _ready() -> void:
	BackgroundMood.register_controller($BackgroundController)
	_update_gameplay_mood_from_matches(0.0)
	MusicManager.set_gameplay()
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController/Particles)
	board.connect("match_made", Callable(self, "_on_match_made"))
	board.connect("no_moves", Callable(self, "_on_no_moves"))
	_update_score()

func _on_match_made(group: Array) -> void:
	combo += 1
	var gained := group.size() * 10 * combo
	score += gained
	_update_score()
	_update_gameplay_mood_from_matches()
	MusicManager.on_match_made()
	if combo == HIGH_COMBO_THRESHOLD:
		MusicManager.maybe_trigger_high_combo_fx()

func _update_score() -> void:
	score_label.text = "Score: %d" % score

func _on_pause_pressed() -> void:
	var pause := preload("res://src/scenes/PauseOverlay.tscn").instantiate()
	add_child(pause)
	pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	pause.connect("resume", Callable(self, "_on_resume"))
	pause.connect("quit", Callable(self, "_on_quit"))

func _on_resume() -> void:
	get_tree().paused = false

func _on_quit() -> void:
	get_tree().paused = false
	_finish_run()

func _on_end_pressed() -> void:
	_finish_run()

func _update_gameplay_mood_from_matches(fade_seconds: float = -1.0) -> void:
	var matches_left: int = board.board.count_available_matches()
	var n: float = FeatureFlags.gameplay_matches_normalizer()
	var max_calm_weight: float = FeatureFlags.gameplay_matches_max_calm_weight()
	var raw_calm_weight: float = 1.0 - clamp(float(matches_left) / n, 0.0, 1.0)
	var calm_weight: float = raw_calm_weight * max_calm_weight
	var fade: float = fade_seconds if fade_seconds >= 0.0 else FeatureFlags.gameplay_matches_mood_fade_seconds()
	BackgroundMood.set_mood_mix(calm_weight, fade)

func _on_no_moves() -> void:
	_finish_run()

func _finish_run() -> void:
	if _run_finished:
		return
	if _ending_transition_started:
		return
	_ending_transition_started = true
	await _play_end_transition()
	_run_finished = true
	RunManager.end_game(score)

func _play_end_transition() -> void:
	set_process_input(false)
	MusicManager.fade_out_hype_layers(0.5)
	# End transition should always drive the background fully calm before white-out.
	BackgroundMood.set_mood(BackgroundMood.Mood.CALM, 0.45)
	var overlay := ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(overlay)

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property($BoardView, "modulate:a", 0.0, 0.45)
	fade.tween_property($UI, "modulate:a", 0.0, 0.35)
	fade.tween_property(overlay, "color:a", 0.95, 0.45)
	await fade.finished
