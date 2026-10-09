extends SceneTree
## godot --headless --path . --script res://tests/test_large_scatter_layout.gd
const Planner = preload("res://addons/jigsawg/src/jigsaw_scatter_layout.gd")
const Resolver = preload("res://addons/jigsawg/src/jigsaw_grid_resolver.gd")

func _initialize() -> void:
	for target in [200, 500, 2000]:
		var grid := Resolver.resolve(target, Vector2i(4096, 3072))
		assert(grid.x >= 2 and grid.y >= 2 and grid.x <= 80 and grid.y <= 80)
		var count := grid.x * grid.y
		assert(abs(count - target) <= maxi(12, roundi(float(target) * 0.08)))
		var piece_size := Vector2(4096, 3072) / Vector2(grid)
		var board_size := piece_size * Vector2(grid)
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		var started := Time.get_ticks_msec()
		var slots := Planner.structured(count, board_size, piece_size, Planner.AROUND_BOARD, 0, 0.14, rng)
		var structured_ms := Time.get_ticks_msec() - started
		assert(slots.size() == count)
		var side := maxf(piece_size.x, piece_size.y)
		_check_separation(slots, side * 1.66)
		var forbidden := Rect2(Vector2.ZERO, board_size).grow(side * (1.65 + 0.14))
		for slot in slots:
			assert(not forbidden.intersects(Rect2(slot - Vector2.ONE * side * 0.33, Vector2.ONE * side * 1.66)))
		rng.seed = 2026
		started = Time.get_ticks_msec()
		var chaotic := Planner.chaotic(count, board_size, piece_size, 0.14, 2.2, 64, rng)
		var chaotic_ms := Time.get_ticks_msec() - started
		assert(chaotic.size() == count)
		var centers: Array[Vector2] = []
		for pos in chaotic:
			centers.append(pos + piece_size * 0.5)
		_check_separation(centers, side * (0.82 + 0.07) * 2.0)
		rng.seed = 2026
		assert(Planner.chaotic(count, board_size, piece_size, 0.14, 2.2, 64, rng) == chaotic)
		print("SCATTER target=%d actual=%d grid=%dx%d structured_ms=%d chaotic_ms=%d" % [target, count, grid.x, grid.y, structured_ms, chaotic_ms])
	print("JigsawG large-puzzle scatter tests: PASS")
	quit()

func _check_separation(positions: Array[Vector2], side: float) -> void:
	var buckets: Dictionary = {}
	for point in positions:
		var cell := Vector2i(floori(point.x / side), floori(point.y / side))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for other in buckets.get(cell + Vector2i(dx, dy), []):
					assert(absf(point.x - other.x) >= side or absf(point.y - other.y) >= side, "Footprints overlap.")
		if not buckets.has(cell):
			buckets[cell] = []
		buckets[cell].append(point)
