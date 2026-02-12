extends Control

@onready var track_prev: Button = $UI/VBox/TrackCarousel/TrackPrev
@onready var track_next: Button = $UI/VBox/TrackCarousel/TrackNext
@onready var track_name: Label = $UI/VBox/TrackCarousel/TrackNameHost/TrackName
@onready var title_label: Label = $UI/VBox/Title

var _title_t: float = 0.0
var _title_base_color: Color = Color(0.98, 0.99, 1.0, 1.0)
var _title_accent_color: Color = Color(0.78, 0.88, 1.0, 1.0)
var _tracks: Array[Dictionary] = []
var _track_index: int = 0
var _track_slide_tween: Tween

func _ready() -> void:
	BackgroundMood.register_controller($BackgroundController)
	MusicManager.set_calm()
	BackgroundMood.set_mood(BackgroundMood.Mood.CALM)
	if not FeatureFlags.is_visual_test_mode():
		$BackgroundController.call("set_emission_activity", 1.0, true)
		$BackgroundController.call("set_menu_visibility_boost", 4.4, 4.0)
		$BackgroundController.call("set_menu_emission_persistent", true)
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController)
	Typography.style_main_menu(self)
	call_deferred("_refresh_title_pivot")
	title_label.add_theme_color_override("font_color", _title_base_color)
	_populate_track_options()

func _process(delta: float) -> void:
	if FeatureFlags.is_visual_test_mode():
		return
	_title_t += delta
	var rot_wave: float = sin(_title_t * 1.8)
	title_label.rotation_degrees = rot_wave * 3.8
	var color_wave: float = (sin(_title_t * 1.2) + 1.0) * 0.5
	title_label.add_theme_color_override("font_color", _title_base_color.lerp(_title_accent_color, color_wave))

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		Typography.style_main_menu(self)
		_refresh_title_pivot()

func _refresh_title_pivot() -> void:
	if title_label == null:
		return
	title_label.pivot_offset = title_label.size * 0.5

func _on_start_pressed() -> void:
	RunManager.start_game()

func _populate_track_options() -> void:
	_tracks = MusicManager.get_available_tracks()
	_track_index = _selected_index_for_id(MusicManager.get_current_track_id(), _tracks)
	var can_cycle: bool = _tracks.size() > 1
	track_prev.disabled = not can_cycle
	track_next.disabled = not can_cycle
	_refresh_track_name(false)

func _selected_index_for_id(track_id: String, tracks: Array[Dictionary]) -> int:
	for i in range(tracks.size()):
		if str(tracks[i].get("id", "")) == track_id:
			return i
	return 0

func _on_track_prev_pressed() -> void:
	_cycle_track(-1)

func _on_track_next_pressed() -> void:
	_cycle_track(1)

func _cycle_track(step: int) -> void:
	if _tracks.is_empty():
		return
	_track_index = posmod(_track_index + step, _tracks.size())
	var track_id: String = str(_tracks[_track_index].get("id", ""))
	MusicManager.set_track(track_id, true)
	_refresh_track_name(true, step)

func _refresh_track_name(animated: bool, direction: int = 1) -> void:
	if _tracks.is_empty():
		track_name.text = ""
		return
	track_name.text = str(_tracks[_track_index].get("name", "Track"))
	if not animated:
		track_name.modulate = Color(1, 1, 1, 1)
		track_name.scale = Vector2.ONE
		track_name.position.x = 0.0
		return
	if is_instance_valid(_track_slide_tween):
		_track_slide_tween.kill()
	var offset: float = 22.0 * float(sign(direction))
	var dir_scale: float = 1.0 + (0.05 * float(sign(direction)))
	track_name.position.x = offset
	track_name.scale = Vector2(dir_scale, 1.0)
	track_name.modulate.a = 0.0
	_track_slide_tween = create_tween()
	_track_slide_tween.set_parallel(true)
	_track_slide_tween.tween_property(track_name, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_track_slide_tween.tween_property(track_name, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_track_slide_tween.tween_property(track_name, "modulate:a", 1.0, 0.2)
