extends Node2D
class_name BoardView

signal match_made(group: Array)
signal no_moves

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
	var local := to_local(pos)
	var x := int(floor(local.x / tile_size))
	var y := int(floor(local.y / tile_size))
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	if not _check_no_moves_and_emit():
		return
	var group := board.find_group(Vector2i(x, y))
	if group.size() < _min_match_size:
		return
	_animating = true
	var snapshot := board.grid.duplicate(true)
	var resolved := board.resolve_move(Vector2i(x, y))
	if resolved.size() >= _min_match_size:
		_clear_hint()
		await _animate_resolution(group, snapshot)
		emit_signal("match_made", group)
		if _check_no_moves_and_emit():
			_restart_hint_timer()
	_animating = false

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
