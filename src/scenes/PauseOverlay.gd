extends Control

signal resume
signal quit

@onready var panel: Control = $Panel
@onready var vbox: VBoxContainer = $VBox
@onready var title_label: Label = $VBox/Title
@onready var resume_button: Button = $VBox/Resume
@onready var quit_button: Button = $VBox/Quit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Typography.style_pause_overlay(self)
	_layout_overlay()

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED:
		Typography.style_pause_overlay(self)
		_layout_overlay()

func _layout_overlay() -> void:
	if panel == null or vbox == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	_layout_overlay_for_size(viewport_size)

func _layout_overlay_for_size(viewport_size: Vector2) -> void:
	if panel == null or vbox == null:
		return
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var insets: Dictionary = SafeArea.get_insets()
	var safe_top: float = float(insets.get("top", 0.0))
	var safe_bottom: float = float(insets.get("bottom", 0.0))
	var safe_left: float = float(insets.get("left", 0.0))
	var safe_right: float = float(insets.get("right", 0.0))
	var viewport_aspect: float = viewport_size.x / max(1.0, viewport_size.y)
	var is_wide: bool = viewport_aspect >= 1.55

	var margin_x: float = clamp(viewport_size.x * 0.05, 16.0, 80.0)
	var margin_y: float = clamp(viewport_size.y * 0.06, 20.0, 88.0)
	var usable_width: float = max(260.0, viewport_size.x - safe_left - safe_right - (margin_x * 2.0))
	var usable_height: float = max(240.0, viewport_size.y - safe_top - safe_bottom - (margin_y * 2.0))

	var panel_width_target: float = viewport_size.x * (0.52 if is_wide else 0.76)
	var panel_width: float = clamp(panel_width_target, min(320.0, usable_width), min(980.0, usable_width))
	var button_height: float = clamp(viewport_size.y * (0.11 if is_wide else 0.1), 72.0, 120.0)
	var title_height: float = clamp(viewport_size.y * 0.14, 76.0, 180.0)
	var inner_pad_x: float = clamp(panel_width * 0.07, 20.0, 56.0)
	var inner_pad_y: float = clamp(viewport_size.y * 0.025, 14.0, 28.0)
	var content_gap: float = clamp(button_height * 0.16, 12.0, 24.0)
	var panel_height: float = title_height + (button_height * 2.0) + (inner_pad_y * 2.0) + (content_gap * 2.0)
	if panel_height > usable_height:
		var fit_scale: float = clamp(usable_height / panel_height, 0.72, 1.0)
		button_height *= fit_scale
		title_height *= fit_scale
		content_gap *= fit_scale
		inner_pad_y *= fit_scale
		panel_height = usable_height

	var panel_size := Vector2(panel_width, panel_height)
	var safe_origin := Vector2(safe_left + margin_x, safe_top + margin_y)
	var safe_size := Vector2(usable_width, usable_height)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = safe_origin + ((safe_size - panel_size) * 0.5)
	panel.size = panel_size

	vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	vbox.position = panel.position + Vector2(inner_pad_x, inner_pad_y)
	vbox.size = panel.size - Vector2(inner_pad_x * 2.0, inner_pad_y * 2.0)
	vbox.add_theme_constant_override("separation", int(round(content_gap)))

	resume_button.custom_minimum_size.y = button_height
	quit_button.custom_minimum_size.y = button_height
	title_label.add_theme_font_size_override("font_size", int(round(clamp(title_height * 0.66, 40.0, 88.0))))
	resume_button.add_theme_font_size_override("font_size", int(round(clamp(button_height * 0.42, 22.0, 46.0))))
	quit_button.add_theme_font_size_override("font_size", int(round(clamp(button_height * 0.42, 22.0, 46.0))))

func _on_resume_pressed() -> void:
	emit_signal("resume")
	queue_free()

func _on_quit_pressed() -> void:
	emit_signal("quit")
	queue_free()
