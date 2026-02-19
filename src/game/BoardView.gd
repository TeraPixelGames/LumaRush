extends Node2D
class_name BoardView

signal match_made(group: Array)
signal no_moves
signal move_committed(group: Array, snapshot: Array)
signal match_click_haptic_triggered(duration_ms: int, amplitude: float)
signal match_haptic_triggered(duration_ms: int, amplitude: float)
signal prism_color_selected(color_idx: int)

@export var width := 8
@export var height := 10
@export var colors := 5
@export var tile_size := 100.0

const TILE_PALETTE_MODERN := [
	Color(0.18, 0.78, 1.0, 0.78),  # cyan
	Color(0.98, 0.34, 0.30, 0.78), # red
	Color(0.28, 0.94, 0.46, 0.78), # green
	Color(1.0, 0.84, 0.18, 0.78),  # yellow
	Color(0.88, 0.34, 1.0, 0.84),  # vivid purple
]

const TILE_PALETTE_LEGACY := [
	Color(0.62, 0.84, 1.0, 0.74),  # soft blue
	Color(0.94, 0.56, 0.52, 0.74), # coral red
	Color(0.58, 0.90, 0.66, 0.74), # mint green
	Color(0.96, 0.82, 0.52, 0.74), # warm gold
	Color(0.86, 0.56, 0.96, 0.78), # vivid plum
]

var board: Board
var tiles: Array = []
var _animating: bool = false
var _min_match_size: int = 2
var _game_over_emitted: bool = false
var _hint_tween: Tween
var _hint_group: Array = []
var _tile_gap_px: float = 8.0
var _prism_pick_mode: bool = false
var _theme_tile_palette: Array = []

func _ready() -> void:
	_tile_gap_px = _gap_for_tile_size(tile_size)
	var board_seed: int = 1234 if FeatureFlags.is_visual_test_mode() else -1
	_min_match_size = FeatureFlags.min_match_size()
	colors = _palette_size()
	board = Board.new(width, height, colors, board_seed, _min_match_size, _palette_size())
	_normalize_board_color_ids()
	var required_matches: int = int(ceil(FeatureFlags.gameplay_matches_normalizer()))
	board.ensure_min_available_matches(required_matches)
	_create_tiles()
	_refresh_tiles()
	queue_redraw()
	_check_no_moves_and_emit()

func set_tile_size(new_size: float) -> void:
	var target: float = max(36.0, new_size)
	if absf(target - tile_size) < 0.1:
		return
	tile_size = target
	_tile_gap_px = _gap_for_tile_size(tile_size)
	if board == null:
		return
	_rebuild_tiles_from_grid()

func set_prism_pick_mode(enabled: bool) -> void:
	_prism_pick_mode = enabled
	if board == null:
		return
	if _prism_pick_mode:
		_clear_hint()
	else:
		_check_no_moves_and_emit()

func is_prism_pick_mode() -> bool:
	return _prism_pick_mode

func set_theme_palette(theme_palette: Array) -> void:
	_theme_tile_palette = theme_palette.duplicate(true)
	colors = _palette_size()
	if board:
		_normalize_board_color_ids()
		_refresh_tiles()

func _gap_for_tile_size(size: float) -> float:
	return clamp(size * 0.08, 4.0, 11.0)

func _create_tiles() -> void:
	tiles.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var tile: ColorRect = _create_tile_node(Vector2i(x, y), _color_from_index(int(board.grid[y][x])))
			row.append(tile)
		tiles.append(row)

func _input(event: InputEvent) -> void:
	if _animating:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)
	if event is InputEventMouseButton and event.pressed:
		_handle_click(event.position)

func _handle_click(pos: Vector2) -> void:
	var cell: Vector2i = _cell_from_screen_pos(pos)
	var x: int = cell.x
	var y: int = cell.y
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	if _prism_pick_mode:
		var tile_color: Variant = board.get_tile(Vector2i(x, y))
		if tile_color == null:
			return
		_trigger_match_click_haptic()
		emit_signal("prism_color_selected", posmod(int(tile_color), _palette_size()))
		return
	if not _check_no_moves_and_emit():
		return
	var group := board.find_group(Vector2i(x, y))
	if group.size() < _min_match_size:
		return
	_trigger_match_click_haptic()
	_animating = true
	var snapshot := board.grid.duplicate(true)
	var resolved := board.resolve_move(Vector2i(x, y))
	if resolved.size() >= _min_match_size:
		# Keep color ids strictly in palette bounds before visual refresh/animation.
		_normalize_board_color_ids()
		_clear_hint()
		await _animate_resolution(group, snapshot)
		_trigger_match_haptic()
		emit_signal("move_committed", group, snapshot)
		emit_signal("match_made", group)
		_check_no_moves_and_emit()
	_animating = false

func _cell_from_screen_pos(screen_pos: Vector2) -> Vector2i:
	# Convert viewport/screen point to this CanvasItem's local coordinates using
	# the full canvas transform chain (robust across stretch, DPI, and safe-area).
	var local: Vector2 = make_canvas_position_local(screen_pos)
	var x: int = int(floor(local.x / tile_size))
	var y: int = int(floor(local.y / tile_size))
	return Vector2i(x, y)

func capture_snapshot() -> Array:
	return board.snapshot()

func restore_snapshot(snapshot_grid: Array) -> void:
	_clear_hint()
	board.restore(snapshot_grid)
	_normalize_board_color_ids()
	_game_over_emitted = false
	_refresh_tiles()
	_check_no_moves_and_emit()

func apply_hint_powerup() -> bool:
	if _animating:
		return false
	if _prism_pick_mode:
		return false
	var hint: Array = _find_hint_group()
	if hint.is_empty():
		return false
	await _animate_powerup_charge(Color(0.7, 0.95, 1.0, 1.0))
	_apply_hint(hint)
	await _animate_powerup_release()
	return true

func apply_remove_color_powerup(color_idx: int = -1) -> Dictionary:
	if _animating:
		return {"removed": 0, "color_idx": -1}
	var target_color: int = color_idx if color_idx >= 0 else _best_removal_color()
	if target_color < 0:
		return {"removed": 0, "color_idx": -1}
	var removed_cells: Array = _positions_for_color(target_color)
	if removed_cells.is_empty():
		return {"removed": 0, "color_idx": -1}
	_animating = true
	_clear_hint()
	VFXManager.play_prism_clear(removed_cells, tile_size, global_position, target_color)
	var fade: Tween = create_tween()
	fade.set_parallel(true)
	for p in removed_cells:
		var tile: ColorRect = tiles[p.y][p.x]
		fade.tween_property(tile, "scale", Vector2(1.25, 1.25), 0.14)
		fade.tween_property(tile, "modulate:a", 0.0, 0.18)
	await fade.finished
	var removed: int = board.remove_color(target_color, _palette_size())
	_normalize_board_color_ids()
	_rebuild_tiles_from_grid()
	await _animate_powerup_release()
	_check_no_moves_and_emit()
	_animating = false
	return {"removed": removed, "color_idx": target_color}

func _refresh_tiles() -> void:
	for y in range(height):
		for x in range(width):
			var tile: ColorRect = tiles[y][x]
			var c := _color_from_index(int(board.grid[y][x]))
			_apply_tile_color(tile, c)
			tile.modulate = Color(1, 1, 1, 1)
			tile.scale = Vector2.ONE
			tile.position = _tile_origin(Vector2i(x, y))
			var mat: ShaderMaterial = tile.material
			if mat:
				mat.set_shader_parameter("blur_radius", _blur_radius())

func _create_tile_node(cell: Vector2i, color: Color) -> ColorRect:
	var tile := ColorRect.new()
	var visual_size: float = max(12.0, tile_size - _tile_gap_px)
	tile.size = Vector2(visual_size, visual_size)
	tile.pivot_offset = tile.size * 0.5
	tile.position = _tile_origin(cell)
	tile.color = color
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/visual/TileGlass.gdshader")
	mat.set_shader_parameter("tint_color", color)
	mat.set_shader_parameter("blur_radius", _blur_radius())
	_apply_tile_design_shader_profile(mat)
	tile.material = mat
	add_child(tile)
	return tile

func _rebuild_tiles_from_grid() -> void:
	for row in tiles:
		for tile in row:
			var tile_node: ColorRect = tile as ColorRect
			if is_instance_valid(tile_node):
				tile_node.queue_free()
	tiles.clear()
	_create_tiles()
	_refresh_tiles()
	queue_redraw()

func _animate_resolution(group: Array, snapshot: Array) -> void:
	VFXManager.play_pixel_explosion(group, tile_size, global_position, snapshot)
	var final_grid: Array = board.grid.duplicate(true)
	var group_set := {}
	for p in group:
		group_set[p] = true

	var new_tiles: Array = []
	for y in range(height):
		var row: Array = []
		row.resize(width)
		new_tiles.append(row)

	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	for p in group:
		var removed_tile: ColorRect = tiles[p.y][p.x]
		fade_tween.tween_property(removed_tile, "modulate:a", 0.0, 0.16)
		fade_tween.tween_property(removed_tile, "scale", Vector2(0.82, 0.82), 0.16)
	await fade_tween.finished

	var fall_tween: Tween = create_tween()
	fall_tween.set_parallel(true)
	for x in range(width):
		var survivors: Array = []
		for y in range(height):
			var cell := Vector2i(x, y)
			if not group_set.has(cell):
				survivors.append(tiles[y][x])

		var start_y: int = height - survivors.size()
		for i in range(survivors.size()):
			var node: ColorRect = survivors[i] as ColorRect
			var target_y: int = start_y + i
			new_tiles[target_y][x] = node
			# Force visual to match final logical color during fall, not only after settle.
			var target_color: Color = _color_from_index(int(final_grid[target_y][x]))
			_apply_tile_color(node, target_color)
			fall_tween.tween_property(node, "position:y", (target_y * tile_size) + (_tile_gap_px * 0.5), 0.22)

		for y in range(start_y):
			var spawn_color: Color = _color_from_index(int(final_grid[y][x]))
			var spawned: ColorRect = _create_tile_node(Vector2i(x, y), spawn_color)
			spawned.modulate.a = 0.0
			spawned.position.y = -(start_y - y) * tile_size + (_tile_gap_px * 0.5)
			new_tiles[y][x] = spawned
			fall_tween.tween_property(spawned, "position:y", (y * tile_size) + (_tile_gap_px * 0.5), 0.24)
			fall_tween.tween_property(spawned, "modulate:a", 1.0, 0.18)
	await fall_tween.finished

	for p in group:
		var old_tile: ColorRect = tiles[p.y][p.x]
		if is_instance_valid(old_tile):
			old_tile.queue_free()

	tiles = new_tiles
	_refresh_tiles()

func _color_from_index(idx: int) -> Color:
	var palette: Array = _tile_palette()
	return palette[posmod(idx, palette.size())]

func _apply_tile_color(tile: ColorRect, color: Color) -> void:
	tile.color = color
	var mat: ShaderMaterial = tile.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("tint_color", color)

func _blur_radius() -> float:
	return 2.0 if FeatureFlags.tile_blur_mode() == FeatureFlags.TileBlurMode.LITE else 6.0

func _check_no_moves_and_emit() -> bool:
	if board.has_move():
		return true
	_clear_hint()
	if not _game_over_emitted:
		_game_over_emitted = true
		emit_signal("no_moves")
	return false

func _find_hint_group() -> Array:
	for y in range(height):
		for x in range(width):
			var g: Array = board.find_group(Vector2i(x, y))
			if g.size() >= _min_match_size:
				return g
	return []

func _apply_hint(group: Array) -> void:
	_clear_hint()
	_hint_group = group.duplicate()
	var speed_mul: float = FeatureFlags.hint_pulse_speed_multiplier()
	var beat_seconds: float = (60.0 / max(1.0, float(FeatureFlags.BPM))) / speed_mul
	var attack: float = beat_seconds * 0.42
	var release: float = beat_seconds * 0.33
	var settle: float = beat_seconds * 0.25
	_hint_tween = create_tween()
	_hint_tween.set_loops()
	for p in _hint_group:
		var tile: ColorRect = tiles[p.y][p.x]
		tile.z_index = 200
		tile.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_hint_tween.parallel().tween_property(tile, "scale", Vector2(1.48, 1.48), attack).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hint_tween.parallel().tween_property(tile, "rotation_degrees", -3.0, attack * 0.5)
		_hint_tween.parallel().tween_property(tile, "rotation_degrees", 3.0, attack * 0.5).set_delay(attack * 0.5)
	_hint_tween.chain()
	for p in _hint_group:
		var tile: ColorRect = tiles[p.y][p.x]
		_hint_tween.parallel().tween_property(tile, "scale", Vector2(0.88, 0.88), release)
		_hint_tween.parallel().tween_property(tile, "rotation_degrees", 0.0, release)
	_hint_tween.chain()
	for p in _hint_group:
		var tile: ColorRect = tiles[p.y][p.x]
		_hint_tween.parallel().tween_property(tile, "scale", Vector2.ONE, settle).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _clear_hint() -> void:
	if is_instance_valid(_hint_tween):
		_hint_tween.kill()
	_hint_tween = null
	for p in _hint_group:
		if p.y >= 0 and p.y < tiles.size() and p.x >= 0 and p.x < tiles[p.y].size():
			var tile: ColorRect = tiles[p.y][p.x]
			if is_instance_valid(tile):
				tile.scale = Vector2.ONE
				tile.modulate = Color(1.0, 1.0, 1.0, 1.0)
				tile.rotation_degrees = 0.0
				tile.z_index = 0
	_hint_group.clear()

func _best_removal_color() -> int:
	var counts: Dictionary = {}
	var mod_count: int = _palette_size()
	for y in range(height):
		for x in range(width):
			var c: int = posmod(int(board.grid[y][x]), mod_count)
			counts[c] = int(counts.get(c, 0)) + 1
	var best_color: int = -1
	var best_count: int = 0
	for c in counts.keys():
		var count: int = int(counts[c])
		if count > best_count:
			best_count = count
			best_color = int(c)
	return best_color

func _positions_for_color(color_idx: int) -> Array:
	var out: Array = []
	var target_idx: int = posmod(color_idx, _palette_size())
	for y in range(height):
		for x in range(width):
			if posmod(int(board.grid[y][x]), _palette_size()) == target_idx:
				out.append(Vector2i(x, y))
	return out

func _palette_size() -> int:
	return _tile_palette().size()

func _tile_palette() -> Array:
	if _theme_tile_palette.size() >= 3:
		return _theme_tile_palette
	return TILE_PALETTE_LEGACY if FeatureFlags.tile_design_mode() == FeatureFlags.TileDesignMode.LEGACY else TILE_PALETTE_MODERN

func _apply_tile_design_shader_profile(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	if FeatureFlags.tile_design_mode() == FeatureFlags.TileDesignMode.LEGACY:
		mat.set_shader_parameter("corner_radius", 0.06)
		mat.set_shader_parameter("border", 0.055)
		mat.set_shader_parameter("tint_mix", 0.92)
		mat.set_shader_parameter("saturation_boost", 1.14)
		mat.set_shader_parameter("bg_luma_mix", 0.32)
		mat.set_shader_parameter("specular_strength", 0.24)
		mat.set_shader_parameter("inner_shadow_strength", 0.3)
		mat.set_shader_parameter("edge_color", Color(0.84, 0.9, 1.0, 0.4))
	else:
		mat.set_shader_parameter("corner_radius", 0.11)
		mat.set_shader_parameter("border", 0.08)
		mat.set_shader_parameter("tint_mix", 1.0)
		mat.set_shader_parameter("saturation_boost", 1.3)
		mat.set_shader_parameter("bg_luma_mix", 0.14)
		mat.set_shader_parameter("specular_strength", 0.36)
		mat.set_shader_parameter("inner_shadow_strength", 0.34)
		mat.set_shader_parameter("edge_color", Color(0.88, 0.95, 1.0, 0.54))

func _normalize_board_color_ids() -> void:
	if board == null or board.grid.is_empty():
		return
	var mod_count: int = _palette_size()
	board.match_color_mod = mod_count
	for y in range(height):
		for x in range(width):
			var value: Variant = board.grid[y][x]
			if value == null:
				continue
			board.grid[y][x] = posmod(int(value), mod_count)

func _tile_origin(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x * tile_size) + (_tile_gap_px * 0.5),
		(cell.y * tile_size) + (_tile_gap_px * 0.5)
	)

func _draw() -> void:
	var board_size: Vector2 = Vector2(width * tile_size, height * tile_size)
	var glow_rect := Rect2(Vector2(-14.0, -14.0), board_size + Vector2(28.0, 28.0))
	draw_rect(glow_rect, Color(0.62, 0.78, 1.0, 0.08), true)
	var frame_rect := Rect2(Vector2(-6.0, -6.0), board_size + Vector2(12.0, 12.0))
	draw_rect(frame_rect, Color(0.2, 0.32, 0.58, 0.2), true)
	draw_rect(frame_rect, Color(1.0, 1.0, 1.0, 0.2), false, 1.0)

func _animate_powerup_charge(tint: Color) -> void:
	var t: Tween = create_tween()
	t.set_parallel(true)
	for row in tiles:
		for tile in row:
			var tile_node: ColorRect = tile as ColorRect
			t.tween_property(tile_node, "modulate", tint, 0.12)
			t.tween_property(tile_node, "scale", Vector2(1.04, 1.04), 0.12)
	await t.finished

func _animate_powerup_release() -> void:
	var t: Tween = create_tween()
	t.set_parallel(true)
	for row in tiles:
		for tile in row:
			var tile_node: ColorRect = tile as ColorRect
			t.tween_property(tile_node, "modulate", Color(1, 1, 1, 1), 0.18)
			t.tween_property(tile_node, "scale", Vector2.ONE, 0.18)
	await t.finished

func _trigger_match_haptic() -> bool:
	if not FeatureFlags.haptics_enabled():
		return false
	var duration_ms: int = FeatureFlags.match_haptic_duration_ms()
	var amplitude: float = FeatureFlags.match_haptic_amplitude()
	Input.vibrate_handheld(duration_ms, amplitude)
	emit_signal("match_haptic_triggered", duration_ms, amplitude)
	return true

func _trigger_match_click_haptic() -> bool:
	if not FeatureFlags.haptics_enabled():
		return false
	var duration_ms: int = FeatureFlags.match_click_haptic_duration_ms()
	var amplitude: float = FeatureFlags.match_click_haptic_amplitude()
	Input.vibrate_handheld(duration_ms, amplitude)
	emit_signal("match_click_haptic_triggered", duration_ms, amplitude)
	return true


