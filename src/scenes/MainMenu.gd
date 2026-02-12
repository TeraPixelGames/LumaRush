extends Control

@onready var track_option: OptionButton = $UI/VBox/TrackOption
@onready var title_label: Label = $UI/VBox/Title

var _title_t: float = 0.0
var _title_base_color: Color = Color(0.98, 0.99, 1.0, 1.0)
var _title_accent_color: Color = Color(0.78, 0.88, 1.0, 1.0)

func _ready() -> void:
	BackgroundMood.register_controller($BackgroundController)
	MusicManager.set_calm()
	BackgroundMood.set_mood(BackgroundMood.Mood.CALM)
	VisualTestMode.apply_if_enabled($BackgroundController, $BackgroundController)
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
		_refresh_title_pivot()

func _refresh_title_pivot() -> void:
	if title_label == null:
		return
	title_label.pivot_offset = title_label.size * 0.5

func _on_start_pressed() -> void:
	RunManager.start_game()

func _populate_track_options() -> void:
	track_option.clear()
	var tracks: Array[Dictionary] = MusicManager.get_available_tracks()
	for entry in tracks:
		track_option.add_item(str(entry.get("name", entry.get("id", ""))))
	track_option.selected = _selected_index_for_id(MusicManager.get_current_track_id(), tracks)

func _selected_index_for_id(track_id: String, tracks: Array[Dictionary]) -> int:
	for i in range(tracks.size()):
		if str(tracks[i].get("id", "")) == track_id:
			return i
	return 0

func _on_track_option_item_selected(index: int) -> void:
	var tracks: Array[Dictionary] = MusicManager.get_available_tracks()
	if index < 0 or index >= tracks.size():
		return
	var track_id: String = str(tracks[index].get("id", ""))
	MusicManager.set_track(track_id, true)
