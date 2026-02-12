extends ColorRect
class_name GlassPanel

@export var blur_radius := 8.0
@export var tint := Color(1, 1, 1, 0.2)

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/visual/TileGlass.gdshader")
	mat.set_shader_parameter("blur_radius", blur_radius)
	mat.set_shader_parameter("tint_color", tint)
	material = mat
	color = tint
