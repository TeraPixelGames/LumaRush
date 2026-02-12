extends RefCounted
class_name Board

var width: int
var height: int
var color_count: int
var min_match_size: int
var rng: RandomNumberGenerator
var grid: Array

func _init(w: int = 8, h: int = 10, colors: int = 5, rng_seed: int = -1, min_match: int = 2) -> void:
	width = w
	height = h
	color_count = colors
	min_match_size = max(2, min_match)
	rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	grid = []
	_generate_board()

func _generate_board() -> void:
	_fill_random_grid()
	ensure_min_available_matches(1, 20)

func _fill_random_grid() -> void:
	grid.clear()
	for y in range(height):
		var row: Array = []
		row.resize(width)
		for x in range(width):
			row[x] = _rand_color()
		grid.append(row)

func _rand_color() -> int:
	return rng.randi_range(0, color_count - 1)

func get_tile(pos: Vector2i) -> Variant:
	if not _in_bounds(pos):
		return null
	return grid[pos.y][pos.x]

func set_tile(pos: Vector2i, value: Variant) -> void:
	if _in_bounds(pos):
		grid[pos.y][pos.x] = value

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func find_group(start: Vector2i) -> Array:
	if not _in_bounds(start):
		return []
	var target: Variant = get_tile(start)
	if target == null:
		return []
	var stack: Array[Vector2i] = []
	stack.append(start)
	var visited := {}
	visited[start] = true
	var group: Array = []
	while stack.size() > 0:
		var p: Vector2i = stack.pop_back()
		group.append(p)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var np: Vector2i = p + d
			if _in_bounds(np) and not visited.has(np) and get_tile(np) == target:
				visited[np] = true
				stack.append(np)
	return group

func has_move() -> bool:
	if min_match_size <= 2:
		for y in range(height):
			for x in range(width):
				var v = grid[y][x]
				if x + 1 < width and grid[y][x + 1] == v:
					return true
				if y + 1 < height and grid[y + 1][x] == v:
					return true
		return false

	for y in range(height):
		for x in range(width):
			if find_group(Vector2i(x, y)).size() >= min_match_size:
				return true
	return false

func resolve_move(start: Vector2i) -> Array:
	var group := find_group(start)
	if group.size() < min_match_size:
		return []
	_clear_group(group)
	_apply_gravity()
	_refill()
	return group

func snapshot() -> Array:
	return grid.duplicate(true)

func restore(snapshot_grid: Array) -> void:
	grid = snapshot_grid.duplicate(true)

func shuffle_tiles() -> void:
	var values: Array = []
	for y in range(height):
		for x in range(width):
			values.append(grid[y][x])
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = values[i]
		values[i] = values[j]
		values[j] = tmp
	var idx: int = 0
	for row in range(height):
		for col in range(width):
			grid[row][col] = values[idx]
			idx += 1
	if not has_move():
		ensure_min_available_matches(1, 80)

func remove_color(color_idx: int) -> int:
	var removed: int = 0
	for y in range(height):
		for x in range(width):
			if int(grid[y][x]) == color_idx:
				grid[y][x] = null
				removed += 1
	if removed <= 0:
		return 0
	_apply_gravity()
	_refill()
	if not has_move():
		ensure_min_available_matches(1, 80)
	return removed

func count_available_matches() -> int:
	var visited := {}
	var count: int = 0
	for y in range(height):
		for x in range(width):
			var p := Vector2i(x, y)
			if visited.has(p):
				continue
			var g: Array = find_group(p)
			for gp in g:
				visited[gp] = true
			if g.size() >= min_match_size:
				count += 1
	return count

func ensure_min_available_matches(min_count: int, max_attempts: int = 100) -> int:
	var target: int = max(0, min_count)
	var current: int = count_available_matches()
	if current >= target:
		return current
	var best_count: int = current
	var best_grid: Array = grid.duplicate(true)
	var attempts: int = 0
	while attempts < max_attempts:
		attempts += 1
		_fill_random_grid()
		if not has_move():
			continue
		current = count_available_matches()
		if current > best_count:
			best_count = current
			best_grid = grid.duplicate(true)
		if current >= target:
			return current
	grid = best_grid
	return best_count

func _clear_group(group: Array) -> void:
	for p in group:
		set_tile(p, null)

func _apply_gravity() -> void:
	for x in range(width):
		var stack: Array = []
		for y in range(height - 1, -1, -1):
			var v = grid[y][x]
			if v != null:
				stack.append(v)
		for y in range(height - 1, -1, -1):
			var idx := height - 1 - y
			if idx < stack.size():
				grid[y][x] = stack[idx]
			else:
				grid[y][x] = null

func _refill() -> void:
	for y in range(height):
		for x in range(width):
			if grid[y][x] == null:
				grid[y][x] = _rand_color()

func _reshuffle_until_move() -> void:
	var attempts := 0
	while attempts < 20:
		attempts += 1
		for y in range(height):
			for x in range(width):
				grid[y][x] = _rand_color()
		if has_move():
			return
