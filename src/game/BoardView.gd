extends Node2D
class_name BoardView

signal match_made(group: Array)
signal no_moves
signal move_committed(group: Array, snapshot: Array)
signal match_click_haptic_triggered(duration_ms: int, amplitude: float)
signal match_haptic_triggered(duration_ms: int, amplitude: float)

@export var width := 8
@export var height := 10
@export var colors := 5
@export var tile_size := 96.0

var board: Board
var tiles: Array = []
var _animating: bool = false
var _min_match_size: int = 2
var _game_over_emitted: bool = false
var _hint_timer: Timer
var _hint_tween: Tween
var _hint_group: Array = []

func _ready() -> void:
	var board_seed: int = 1234 if FeatureFlags.is_visual_test_mode() else -1
	_min_match_size = FeatureFlags.min_match_size()
	board = Board.new(width, height, colors, board_seed, _min_match_size)
	var required_matches: int = int(ceil(FeatureFlags.gameplay_matches_normalizer()))
	board.ensure_min_available_matches(required_matches)
	_create_tiles()
	_refresh_tiles()
	_setup_hint_timer()
	_check_no_moves_and_emit()

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
		_clear_hint()
		await _animate_resolution(group, snapshot)
		_trigger_match_haptic()
		emit_signal("move_committed", group, snapshot)
		emit_signal("match_made", group)
		if _check_no_moves_and_emit():
			_restart_hint_timer()
	_animating = false

func _cell_from_screen_pos(screen_pos: Vector2) -> Vector2i:
	var canvas_pos: Vector2 = screen_pos
	var viewport: Viewport = get_viewport()
	if viewport:
		canvas_pos = viewport.get_canvas_transform().affine_inverse() * screen_pos
	var local_canvas: Vector2 = to_local(canvas_pos)
	var local_direct: Vector2 = to_local(screen_pos)
	var x_canvas: int = int(floor(local_canvas.x / tile_size))
	var y_canvas: int = int(floor(local_canvas.y / tile_size))
	if x_canvas >= 0 and x_canvas < width and y_canvas >= 0 and y_canvas < height:
		return Vector2i(x_canvas, y_canvas)
	var x_direct: int = int(floor(local_direct.x / tile_size))
	var y_direct: int = int(floor(local_direct.y / tile_size))
	return Vector2i(x_direct, y_direct)

func capture_snapshot() -> Array:
	return board.snapshot()

func restore_snapshot(snapshot_grid: Array) -> void:
	_clear_hint()
	board.restore(snapshot_grid)
	_game_over_emitted = false
	_refresh_tiles()
	if _check_no_moves_and_emit():
		_restart_hint_timer()

func apply_shuffle_powerup() -> bool:
	if _animating:
		return false
	_animating = true
	_clear_hint()
	await _animate_powerup_charge(Color(0.7, 0.95, 1.0, 1.0))
	board.shuffle_tiles()
	_refresh_tiles()
	await _animate_powerup_release()
	if _check_no_moves_and_emit():
		_restart_hint_timer()
	_animating = false
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
	VFXManager.play_pixel_explosion(removed_cells, tile_size, global_position, board.grid)
	var fade: Tween = create_tween()
	fade.set_parallel(true)
	for p in removed_cells:
		var tile: ColorRect = tiles[p.y][p.x]
		fade.tween_property(tile, "scale", Vector2(1.25, 1.25), 0.14)
		fade.tween_property(tile, "modulate:a", 0.0, 0.18)
	await fade.finished
	var removed: int = board.remove_color(target_color)
	_refresh_tiles()
	await _animate_powerup_release()
	if _check_no_moves_and_emit():
		_restart_hint_timer()
	_animating = false
	return {"removed": removed, "color_idx": target_color}

func _refresh_tiles() -> void:
	for y in range(height):
		for x in range(width):
			var tile: ColorRect = tiles[y][x]
			var c := _color_from_index(int(board.grid[y][x]))
			tile.color = c
			tile.modulate = Color(1, 1, 1, 1)
			tile.scale = Vector2.ONE
			tile.position = Vector2(x * tile_size, y * tile_size)
			var mat: ShaderMaterial = tile.material
			if mat:
				mat.set_shader_parameter("tint_color", c)
				mat.set_shader_parameter("blur_radius", _blur_radius())

func _create_tile_node(cell: Vector2i, color: Color) -> ColorRect:
	var tile := ColorRect.new()
	tile.size = Vector2(tile_size, tile_size)
	tile.pivot_offset = tile.size * 0.5
	tile.position = Vector2(cell.x * tile_size, cell.y * tile_size)
	tile.color = color
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/visual/TileGlass.gdshader")
	mat.set_shader_parameter("tint_color", color)
	mat.set_shader_parameter("blur_radius", _blur_radius())
	tile.material = mat
	add_child(tile)
	return tile

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
			fall_tween.tween_property(node, "position:y", target_y * tile_size, 0.22)

		for y in range(start_y):
			var spawn_color: Color = _color_from_index(int(final_grid[y][x]))
			var spawned: ColorRect = _create_tile_node(Vector2i(x, y), spawn_color)
			spawned.modulate.a = 0.0
			spawned.position.y = -(start_y - y) * tile_size
			new_tiles[y][x] = spawned
			fall_tween.tween_property(spawned, "position:y", y * tile_size, 0.24)
			fall_tween.tween_property(spawned, "modulate:a", 1.0, 0.18)
	await fall_tween.finished

	for p in group:
		var old_tile: ColorRect = tiles[p.y][p.x]
		if is_instance_valid(old_tile):
			old_tile.queue_free()

	tiles = new_tiles
	_refresh_tiles()

func _color_from_index(idx: int) -> Color:
	var palette := [
		Color(0.55, 0.86, 1.0, 0.55),
		Color(0.98, 0.65, 0.92, 0.55),
		Color(0.7, 0.98, 0.8, 0.55),
		Color(1.0, 0.9, 0.6, 0.55),
		Color(0.95, 0.7, 0.7, 0.55),
	]
	return palette[idx % palette.size()]

func _blur_radius() -> float:
	return 2.0 if FeatureFlags.tile_blur_mode() == FeatureFlags.TileBlurMode.LITE else 6.0

func _check_no_moves_and_emit() -> bool:
	if board.has_move():
		return true
	_clear_hint()
	if _hint_timer:
		_hint_timer.stop()
	if not _game_over_emitted:
		_game_over_emitted = true
		emit_signal("no_moves")
	return false

func _setup_hint_timer() -> void:
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	_hint_timer.wait_time = max(0.1, FeatureFlags.match_hint_delay_seconds())
	add_child(_hint_timer)
	_hint_timer.timeout.connect(_on_hint_timeout)
	_restart_hint_timer()

func _restart_hint_timer() -> void:
	if _hint_timer == null:
		return
	_hint_timer.stop()
	_hint_timer.wait_time = max(0.1, FeatureFlags.match_hint_delay_seconds())
	_hint_timer.start()

func _on_hint_timeout() -> void:
	if _animating or _game_over_emitted:
		if _animating:
			_restart_hint_timer()
		return
	if not board.has_move():
		_check_no_moves_and_emit()
		return
	var hint := _find_hint_group()
	if hint.is_empty():
		_restart_hint_timer()
		return
	_apply_hint(hint)
	_restart_hint_timer()

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
		_hint_tween.parallel().tween_property(tile, "scale", Vector2(1.48, 1.48), attack).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hint_tween.parallel().tween_property(tile, "modulate", Color(1.0, 0.92, 0.35, 1.0), attack)
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
		_hint_tween.parallel().tween_property(tile, "modulate", Color(1.0, 1.0, 1.0, 1.0), settle)

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
	for y in range(height):
		for x in range(width):
			var c: int = int(board.grid[y][x])
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
	for y in range(height):
		for x in range(width):
			if int(board.grid[y][x]) == color_idx:
				out.append(Vector2i(x, y))
	return out

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
