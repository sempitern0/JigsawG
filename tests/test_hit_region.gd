extends SceneTree
## godot --headless --path . --script res://tests/test_hit_region.gd
const HitIndex = preload("res://addons/jigsawg/src/jigsaw_hit_index.gd")


func _initialize() -> void:
	var index := HitIndex.new()
	var rectangles: Array[Rect2] = []
	for id in range(2000):
		rectangles.append(Rect2(Vector2((id % 50) * 80 - 2000, (id / 50) * 80 - 1600), Vector2(64, 64)))
	index.rebuild(rectangles, 64.0)
	for probe in [Rect2(Vector2(-2000, -1600), Vector2(300, 300)), Rect2(Vector2(0, 0), Vector2(15, 15)), Rect2(Vector2(-4000, -4000), Vector2(8000, 8000))]:
		var candidates := index.query_region(probe)
		var previous := 2000
		for id in candidates:
			assert(id < previous, "Region candidates must preserve descending draw order.")
			previous = id
		for id in range(rectangles.size()):
			if rectangles[id].intersects(probe):
				assert(candidates.has(id), "Region query must include every intersecting piece.")
	var corner_touch := index.query_region(Rect2(Vector2(-2001, -1601), Vector2(1, 1)))
	assert(corner_touch.has(0), "Inclusive edge/corner contacts cannot be dropped.")
	index.invalidate()
	assert(index.query_region(Rect2(Vector2.ZERO, Vector2(100, 100))).is_empty())
	index.clear()
	assert(index.is_dirty())
	print("JigsawG accessible broad-phase region query: PASS")
	quit()
