extends Control

@onready var board: BoardView = $BoardView
@onready var score_value_label: Label = $UI/TopBar/ScoreBox/ScoreValue
@onready var undo_button: Button = $UI/Powerups/Undo
@onready var remove_color_button: Button = $UI/Powerups/RemoveColor
@onready var shuffle_button: Button = $UI/Powerups/Shuffle
@onready var undo_badge: Label = $UI/Powerups/Undo/Badge
@onready var prism_badge: Label = $UI/Powerups/RemoveColor/Badge
@onready var shuffle_badge: Label = $UI/Powerups/Shuffle/Badge
@onready var board_frame: ColorRect = $UI/BoardFrame
@onready var board_glow: ColorRect = $UI/BoardGlow
@onready var powerup_flash: ColorRect = $UI/PowerupFlash

var score := 0
var combo := 0
const HIGH_COMBO_THRESHOLD := 4
var _run_finished: bool = false
var _ending_transition_started: bool = false
var _undo_charges: int = 0
var _remove_color_charges: int = 0
var _shuffle_charges: int = 0
var _undo_stack: Array[Dictionary] = []
var _pending_powerup_refill_type: String = ""

const ICON_UNDO := "↶"
const ICON_PRISM := "◈"
const ICON_SHUFFLE := "⤮"
const ICON_LOADING := "…"

func _ready() -> void:
	var stale_overlay: Node = get_node_or_null("RunEndOverlay")
	if stale_overlay:
		stale_overlay.queue_free()
	stale_overlay = get_node_or_null("RunEnterOverlay")
	if stale_overlay:
		stale_overlay.queue_free()
	modulate = Color(1, 1, 1, 1)
	$BoardView.modulate = Color(1, 1, 1, 1)
	$UI.modulate = Color(1, 1, 1, 1)
	Typography.style_game(self)
	BackgroundMood.register_controller($BackgroundController)
	_update_gameplay_mood_from_matches(0.0)
	BackgroundMood.reset_starfield_emission_taper()
	MusicManager.set_gameplay()
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController)
	board.connect("match_made", Callable(self, "_on_match_made"))
	board.connect("move_committed", Callable(self, "_on_move_committed"))
	board.connect("no_moves", Callable(self, "_on_no_moves"))
	if not AdManager.is_connected("rewarded_powerup_earned", Callable(self, "_on_powerup_rewarded_earned")):
		AdManager.connect("rewarded_powerup_earned", Callable(self, "_on_powerup_rewarded_earned"))
	if not AdManager.is_connected("rewarded_closed", Callable(self, "_on_powerup_rewarded_closed")):
		AdManager.connect("rewarded_closed", Callable(self, "_on_powerup_rewarded_closed"))
	_undo_charges = FeatureFlags.powerup_undo_charges()
	_remove_color_charges = FeatureFlags.powerup_remove_color_charges()
	_shuffle_charges = FeatureFlags.powerup_shuffle_charges()
	if board_frame:
		board_frame.visible = false
	if board_glow:
		board_glow.visible = false
	for badge in [undo_badge, prism_badge, shuffle_badge]:
		badge.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
		badge.add_theme_color_override("font_outline_color", Color(0.1, 0.18, 0.36, 0.95))
		badge.add_theme_constant_override("outline_size", 3)
	powerup_flash.visible = false
	_update_score()
	_update_powerup_buttons()
	_center_board()
	_play_enter_transition()

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		Typography.style_game(self)
		_center_board()

func _on_match_made(group: Array) -> void:
	combo += 1
	var gained := group.size() * 10 * combo
	score += gained
	_update_score()
	_update_gameplay_mood_from_matches()
	BackgroundMood.reset_starfield_emission_taper()
	BackgroundMood.pulse_starfield()
	MusicManager.on_match_made()
	if combo == HIGH_COMBO_THRESHOLD:
		MusicManager.maybe_trigger_high_combo_fx()

func _on_move_committed(_group: Array, snapshot: Array) -> void:
	_push_undo(snapshot, score, combo)

func _update_score() -> void:
	score_value_label.text = "%d" % score

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

func _on_undo_pressed() -> void:
	if _undo_charges <= 0:
		_request_powerup_refill("undo")
		return
	if _undo_stack.is_empty():
		return
	if _ending_transition_started:
		return
	var state: Dictionary = _undo_stack.pop_back()
	board.restore_snapshot(state["grid"] as Array)
	score = int(state["score"])
	combo = int(state["combo"])
	_undo_charges -= 1
	_update_score()
	_update_gameplay_mood_from_matches(0.3)
	_update_powerup_buttons()
	_play_powerup_juice(Color(0.72, 0.9, 1.0, FeatureFlags.powerup_flash_alpha()))

func _on_remove_color_pressed() -> void:
	if _remove_color_charges <= 0:
		_request_powerup_refill("prism")
		return
	if _ending_transition_started:
		return
	var snapshot: Array = board.capture_snapshot()
	var score_before: int = score
	var combo_before: int = combo
	var result: Dictionary = await board.apply_remove_color_powerup()
	var removed: int = int(result.get("removed", 0))
	if removed <= 0:
		return
	_push_undo(snapshot, score_before, combo_before)
	_remove_color_charges -= 1
	combo += 1
	score += removed * 12
	_update_score()
	_update_gameplay_mood_from_matches(0.3)
	_update_powerup_buttons()
	MusicManager.on_match_made()
	_play_powerup_juice(Color(1.0, 0.92, 0.7, FeatureFlags.powerup_flash_alpha()))

func _on_shuffle_pressed() -> void:
	if _shuffle_charges <= 0:
		_request_powerup_refill("shuffle")
		return
	if _ending_transition_started:
		return
	var snapshot: Array = board.capture_snapshot()
	var score_before: int = score
	var combo_before: int = combo
	var changed: bool = await board.apply_shuffle_powerup()
	if not changed:
		return
	_push_undo(snapshot, score_before, combo_before)
	_shuffle_charges -= 1
	score += 80
	combo = max(0, combo - 1)
	_update_score()
	_update_gameplay_mood_from_matches(0.3)
	_update_powerup_buttons()
	_play_powerup_juice(Color(0.8, 0.86, 1.0, FeatureFlags.powerup_flash_alpha()))

func _update_gameplay_mood_from_matches(fade_seconds: float = -1.0) -> void:
	var matches_left: int = board.board.count_available_matches()
	var n: float = FeatureFlags.gameplay_matches_normalizer()
	var max_calm_weight: float = FeatureFlags.gameplay_matches_max_calm_weight()
	var raw_calm_weight: float = 1.0 - clamp(float(matches_left) / n, 0.0, 1.0)
	var calm_weight: float = raw_calm_weight * max_calm_weight
	var fade: float = fade_seconds if fade_seconds >= 0.0 else FeatureFlags.gameplay_matches_mood_fade_seconds()
	BackgroundMood.set_mood_mix(calm_weight, fade)

func _update_powerup_buttons() -> void:
	undo_button.text = _powerup_button_icon(ICON_UNDO, _undo_charges, "undo")
	remove_color_button.text = _powerup_button_icon(ICON_PRISM, _remove_color_charges, "prism")
	shuffle_button.text = _powerup_button_icon(ICON_SHUFFLE, _shuffle_charges, "shuffle")
	_update_badge(undo_badge, _undo_charges, _pending_powerup_refill_type == "undo")
	_update_badge(prism_badge, _remove_color_charges, _pending_powerup_refill_type == "prism")
	_update_badge(shuffle_badge, _shuffle_charges, _pending_powerup_refill_type == "shuffle")
	undo_button.disabled = (_undo_charges > 0 and _undo_stack.is_empty()) or _is_other_refill_pending("undo")
	remove_color_button.disabled = _is_other_refill_pending("prism")
	shuffle_button.disabled = _is_other_refill_pending("shuffle")

func _push_undo(snapshot: Array, score_snapshot: int, combo_snapshot: int) -> void:
	_undo_stack.append({
		"grid": snapshot.duplicate(true),
		"score": score_snapshot,
		"combo": combo_snapshot,
	})
	if _undo_stack.size() > 6:
		_undo_stack.pop_front()
	_update_powerup_buttons()

func _play_powerup_juice(flash_color: Color) -> void:
	powerup_flash.visible = true
	powerup_flash.color = flash_color
	var board_scale_start: Vector2 = board.scale
	var board_scale_peak: Vector2 = board_scale_start * Vector2(1.03, 1.03)
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_method(Callable(self, "_set_board_scale_centered"), board_scale_start, board_scale_peak, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(powerup_flash, "color:a", FeatureFlags.powerup_flash_alpha(), 0.08)
	t.chain().tween_method(Callable(self, "_set_board_scale_centered"), board_scale_peak, board_scale_start, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(powerup_flash, "color:a", 0.0, FeatureFlags.powerup_flash_seconds())
	t.finished.connect(func() -> void:
		powerup_flash.visible = false
	)

func _set_board_scale_centered(target_scale: Vector2) -> void:
	var board_center_local: Vector2 = Vector2(
		float(board.width) * board.tile_size * 0.5,
		float(board.height) * board.tile_size * 0.5
	)
	var center_before: Vector2 = board.to_global(board_center_local)
	board.scale = target_scale
	var center_after: Vector2 = board.to_global(board_center_local)
	board.global_position += center_before - center_after

func _grant_bonus_powerup(powerup_type: String) -> void:
	match powerup_type:
		"undo":
			_undo_charges += 1
		"prism":
			_remove_color_charges += 1
		"shuffle":
			_shuffle_charges += 1
	_update_powerup_buttons()
	_play_powerup_juice(Color(1.0, 0.94, 0.58, 0.28))
	Input.vibrate_handheld(38, 0.65)

func _on_powerup_rewarded_earned() -> void:
	if _pending_powerup_refill_type.is_empty():
		return
	var powerup_type: String = _pending_powerup_refill_type
	_pending_powerup_refill_type = ""
	_grant_bonus_powerup(powerup_type)

func _on_powerup_rewarded_closed() -> void:
	if not _pending_powerup_refill_type.is_empty():
		_pending_powerup_refill_type = ""
		_update_powerup_buttons()

func _request_powerup_refill(powerup_type: String) -> void:
	if _ending_transition_started:
		return
	if not _pending_powerup_refill_type.is_empty():
		return
	_pending_powerup_refill_type = powerup_type
	_update_powerup_buttons()
	if not AdManager.show_rewarded_for_powerup():
		_pending_powerup_refill_type = ""
		_update_powerup_buttons()

func _powerup_button_icon(base_icon: String, charges: int, powerup_type: String) -> String:
	if _pending_powerup_refill_type == powerup_type:
		return ICON_LOADING
	return base_icon

func _update_badge(label: Label, charges: int, is_loading: bool) -> void:
	if label == null:
		return
	label.visible = true
	if is_loading:
		label.text = "Loading..."
		label.modulate = Color(0.78, 0.86, 1.0, 0.94)
		_set_badge_centered(label)
	elif charges > 0:
		label.text = "x%d" % charges
		label.modulate = Color(0.98, 0.99, 1.0, 0.98)
		_set_badge_top_center(label)
	else:
		label.text = "Watch Ad"
		label.modulate = Color(0.78, 0.9, 1.0, 0.98)
		_set_badge_top_center(label)

func _set_badge_top_center(label: Label) -> void:
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 0.0
	label.offset_left = 8.0
	label.offset_top = 8.0
	label.offset_right = -8.0
	label.offset_bottom = 40.0

func _set_badge_centered(label: Label) -> void:
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 8.0
	label.offset_top = 0.0
	label.offset_right = -8.0
	label.offset_bottom = 0.0

func _is_other_refill_pending(powerup_type: String) -> bool:
	return not _pending_powerup_refill_type.is_empty() and _pending_powerup_refill_type != powerup_type

func _on_no_moves() -> void:
	_finish_run()

func _finish_run() -> void:
	if _run_finished:
		return
	if _ending_transition_started:
		return
	get_tree().paused = false
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
	overlay.name = "RunEndOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var fade := create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.set_parallel(true)
	fade.tween_property($BoardView, "modulate:a", 0.0, 0.45)
	fade.tween_property($UI, "modulate:a", 0.0, 0.35)
	fade.tween_property(overlay, "color:a", 0.95, 0.45)
	await fade.finished

func _play_enter_transition() -> void:
	board.set_process_input(false)
	set_process_input(false)
	var overlay := ColorRect.new()
	overlay.name = "RunEnterOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(overlay, "color:a", 0.0, 0.35)
	t.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		board.set_process_input(true)
		set_process_input(true)
	)

func _center_board() -> void:
	if board == null:
		return
	var view_size: Vector2 = get_viewport_rect().size
	var board_size: Vector2 = Vector2(board.width * board.tile_size, board.height * board.tile_size)
	board.position = (view_size - board_size) * 0.5
