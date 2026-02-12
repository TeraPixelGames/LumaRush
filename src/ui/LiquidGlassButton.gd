extends Button
class_name LiquidGlassButton

@export var tint: Color = Color(0.95, 0.97, 1.0, 0.22)
@export var edge_highlight: Color = Color(1.0, 1.0, 1.0, 0.48)
@export var blur: float = 3.5

func _ready() -> void:
	flat = false
	focus_mode = Control.FOCUS_NONE
	_apply_style_overrides()
	_ensure_glass_layer()

func _apply_style_overrides() -> void:
	# Override old dark button skin so upstate matches liquid glass look.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.72, 0.78, 0.96, 0.26)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.95, 0.98, 1.0, 0.36)
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_right = 18
	normal.corner_radius_bottom_left = 18
	normal.shadow_size = 2
	normal.shadow_color = Color(0.02, 0.05, 0.2, 0.35)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.74, 0.82, 1.0, 0.34)
	hover.border_color = Color(1.0, 1.0, 1.0, 0.5)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.63, 0.7, 0.92, 0.34)
	pressed.border_color = Color(0.88, 0.95, 1.0, 0.42)

	var disabled_style := normal.duplicate()
	disabled_style.bg_color = Color(0.62, 0.67, 0.82, 0.2)
	disabled_style.border_color = Color(0.78, 0.84, 0.95, 0.22)
	disabled_style.shadow_size = 0

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("focus", normal)
	add_theme_stylebox_override("disabled", disabled_style)

	add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_pressed_color", Color(0.98, 0.99, 1.0, 1.0))
	add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_disabled_color", Color(0.78, 0.8, 0.86, 0.9))

func _ensure_glass_layer() -> void:
	var layer: ColorRect = get_node_or_null("LiquidGlassLayer") as ColorRect
	if layer == null:
		layer = ColorRect.new()
		layer.name = "LiquidGlassLayer"
		layer.anchor_right = 1.0
		layer.anchor_bottom = 1.0
		layer.color = Color(1, 1, 1, 1)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.show_behind_parent = true
		add_child(layer)
		move_child(layer, 0)
	var mat: ShaderMaterial = layer.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = preload("res://src/ui/LiquidGlassButton.gdshader")
		layer.material = mat
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("edge_highlight", edge_highlight)
	mat.set_shader_parameter("blur", blur)
