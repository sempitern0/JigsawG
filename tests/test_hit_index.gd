extends SceneTree
## godot --headless --path . --script res://tests/test_hit_index.gd
const HitIndex = preload("res://addons/jigsawg/src/jigsaw_hit_index.gd")

func _initialize() -> void:
	var index := HitIndex.new()
	assert(index.is_dirty())
	assert(index.query(Vector2.ZERO).is_empty())
	for count in [200, 500, 2000]:
		var rectangles: Array[Rect2] = []
		for i in range(count):
			rectangles.append(Rect2(Vector2((i % 50) * 38 - 900, (i / 50) * 38 - 500), Vector2(46, 46)))
		index.rebuild(rectangles, 48.0)
		assert(not index.is_dirty())
		var rng := RandomNumberGenerator.new()
		rng.seed = 14729
		var total_candidates := 0
		for sample in range(1200):
			var point := Vector2(rng.randf_range(-1000, 1200), rng.randf_range(-600, 1200))
			var candidate_ids := index.query(point)
			var last_id := count
			for id in candidate_ids:
				assert(id < last_id, "Broad phase must preserve descending scene order.")
				last_id = id
			for id in range(count):
				if rectangles[id].has_point(point):
					assert(candidate_ids.has(id), "Spatial lookup lost a geometrically possible hit.")
			total_candidates += index.last_candidate_count()
		assert(total_candidates < count * 300, "Candidate count should stay far below a full scan.")
		print("HIT INDEX count=%d average_candidates=%.2f" % [count, float(total_candidates) / 1200.0])
	index.invalidate()
	assert(index.is_dirty() and index.query(Vector2.ZERO).is_empty())
	index.clear()
	assert(index.is_dirty())
	print("JigsawG spatial hit index: PASS")
	quit()
