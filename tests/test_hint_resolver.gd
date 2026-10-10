extends SceneTree
## godot --headless --path . --script res://tests/test_hint_resolver.gd
const Resolver = preload("res://addons/jigsawg/src/jigsaw_hint_resolver.gd")


func _initialize() -> void:
	# Three groups: {0,1}, {2}, {3,4}; deterministic root scanning.
	var groups: PackedInt32Array = PackedInt32Array([0, 0, 2, 3, 3])
	var locked: PackedInt32Array = PackedInt32Array()
	var empty: PackedInt32Array = PackedInt32Array()
	assert(Resolver.pick_candidate(groups, locked, empty) == 0)
	assert(Resolver.pick_candidate(groups, locked, empty, 0) == 2)
	assert(Resolver.pick_candidate(groups, locked, empty, 2) == 3)
	assert(Resolver.pick_candidate(groups, locked, empty, 3) == 0)
	# Selected loose piece overrides root ordering; locked selection is ignored.
	assert(Resolver.pick_candidate(groups, locked, PackedInt32Array([4])) == 4)
	assert(Resolver.pick_candidate(groups, PackedInt32Array([4]),
		PackedInt32Array([4])) == 0)
	assert(Resolver.pick_candidate(groups, PackedInt32Array([0, 1, 2, 3, 4]), empty) == -1)
	assert(Resolver.pick_candidate(PackedInt32Array(), empty, empty) == -1)

	# Every solved cell has a bounded region, covering its center but never
	# revealing more detail than the requested coarse 3x3 rectangle.
	var cell: Vector2 = Vector2(64.0, 48.0)
	var grid: Vector2i = Vector2i(50, 40)
	var divs: int = 3
	var width: Vector2 = cell * Vector2(grid)
	for y: int in range(grid.y):
		for x: int in range(grid.x):
			var home: Vector2 = Vector2(x, y) * cell
			var region: Rect2 = Resolver.coarse_region(home, cell, grid, divs)
			var center: Vector2 = home + cell * 0.5
			assert(region.has_point(center))
			assert(region.position.x >= 0.0 and region.position.y >= 0.0)
			assert(region.end.x <= width.x + 0.01 and region.end.y <= width.y + 0.01)
			assert(is_equal_approx(region.size.x, width.x / 3.0))
	assert(Resolver.coarse_region(Vector2.ZERO, Vector2.ONE, Vector2i.ZERO, 3) == Rect2())
	assert(Resolver.coarse_region(Vector2.ZERO, Vector2.ONE, Vector2i(3, 3), 1) == Rect2())
	print("JigsawG pure progressive hint resolver (2000 pieces): PASS")
	quit()
