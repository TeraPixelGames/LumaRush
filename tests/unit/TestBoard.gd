extends GdUnitTestSuite

func test_generates_at_least_one_move() -> void:
	var b := Board.new(6, 6, 3, 1234)
	assert_that(b.has_move()).is_true()

func test_resolve_move_clears_and_refills() -> void:
	var b := Board.new(3, 3, 2, 42)
	b.grid = [
		[0, 0, 1],
		[1, 0, 1],
		[1, 1, 1],
	]
	var group := b.resolve_move(Vector2i(0, 0))
	assert_that(group.size()).is_greater(1)
	for y in range(b.height):
		for x in range(b.width):
			assert_that(b.grid[y][x]).is_not_null()

func test_find_group_returns_connected_same_color() -> void:
	var b := Board.new(3, 3, 3, 1)
	b.grid = [
		[0, 1, 1],
		[0, 0, 2],
		[2, 0, 2],
	]
	var g := b.find_group(Vector2i(0, 0))
	assert_that(g.size()).is_equal(4)

func test_resolve_move_respects_min_match_size() -> void:
	var b := Board.new(3, 3, 3, 7, 3)
	b.grid = [
		[0, 0, 1],
		[1, 2, 2],
		[2, 1, 0],
	]
	var group := b.resolve_move(Vector2i(0, 0))
	assert_that(group.size()).is_equal(0)
	assert_that(b.grid[0][0]).is_equal(0)
	assert_that(b.grid[0][1]).is_equal(0)

func test_has_move_respects_min_match_size() -> void:
	var b := Board.new(3, 3, 3, 5, 3)
	b.grid = [
		[0, 0, 1],
		[2, 1, 2],
		[1, 2, 0],
	]
	assert_that(b.has_move()).is_false()
	b.grid = [
		[0, 0, 0],
		[2, 1, 2],
		[1, 2, 0],
	]
	assert_that(b.has_move()).is_true()

func test_count_available_matches_counts_groups() -> void:
	var b := Board.new(4, 3, 3, 9, 3)
	b.grid = [
		[0, 0, 0, 1],
		[2, 1, 2, 1],
		[1, 2, 2, 2],
	]
	assert_that(b.count_available_matches()).is_equal(2)

func test_ensure_min_available_matches_hits_target() -> void:
	var b := Board.new(6, 6, 4, 123, 3)
	var count: int = b.ensure_min_available_matches(3, 300)
	assert_that(count).is_greater_equal(3)
	assert_that(b.count_available_matches()).is_greater_equal(3)
