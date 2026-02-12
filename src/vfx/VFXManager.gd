extends Node

const EXPLOSION_SCENE := preload("res://src/vfx/PixelExplosion.tscn")

func play_pixel_explosion(group: Array, tile_size: float, board_origin: Vector2, colors: Array) -> void:
	if group.is_empty():
		return
	var first: Vector2i = group[0]
	var min_x: int = first.x
	var max_x: int = first.x
	var min_y: int = first.y
	var max_y: int = first.y
	for p in group:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	var w: int = max_x - min_x + 1
	var h: int = max_y - min_y + 1
	var img := Image.create(int(w * tile_size), int(h * tile_size), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for p in group:
		var local_x := int((p.x - min_x) * tile_size)
		var local_y := int((p.y - min_y) * tile_size)
		var color_idx: int = int(colors[p.y][p.x]) if p.y < colors.size() and p.x < colors[p.y].size() else 0
		var c: Color = _color_from_index(color_idx)
		img.fill_rect(Rect2i(local_x, local_y, int(tile_size), int(tile_size)), c)
	var tex := ImageTexture.create_from_image(img)
	var explosion: Node2D = EXPLOSION_SCENE.instantiate()
	var parent := get_tree().current_scene
	parent.add_child(explosion)
	var pos := board_origin + Vector2(min_x * tile_size, min_y * tile_size)
	explosion.position = pos
	explosion.call("setup", tex, 6.0, float(randi() % 1000))

func _color_from_index(idx: int) -> Color:
	var palette := [
		Color(0.42, 0.8, 1.0, 0.9),
		Color(0.96, 0.62, 0.9, 0.9),
		Color(0.6, 0.95, 0.7, 0.9),
		Color(1.0, 0.85, 0.5, 0.9),
		Color(0.9, 0.6, 0.6, 0.9),
	]
	return palette[idx % palette.size()]
