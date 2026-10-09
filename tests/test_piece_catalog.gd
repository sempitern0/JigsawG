extends SceneTree
## godot --headless --path . --script res://tests/test_piece_catalog.gd
const Catalog = preload("res://addons/jigsawg/src/jigsaw_piece_catalog.gd")


func _initialize() -> void:
	# 2x2 consists solely of corners. 2xN never has interior pieces.
	for grid: Vector2i in [Vector2i(2, 2), Vector2i(2, 8), Vector2i(5, 4), Vector2i(50, 40)]:
		var count: int = grid.x * grid.y
		var corners: PackedInt32Array = Catalog.ids_for_category(grid.x, grid.y, Catalog.Category.CORNER)
		var edges: PackedInt32Array = Catalog.ids_for_category(grid.x, grid.y, Catalog.Category.EDGE)
		var inside: PackedInt32Array = Catalog.ids_for_category(grid.x, grid.y, Catalog.Category.INTERIOR)
		assert(corners.size() == 4, "A rectangular puzzle must have four corners.")
		assert(edges.size() == 2 * (grid.x - 2) + 2 * (grid.y - 2), "Border count must match topology.")
		assert(inside.size() == (grid.x - 2) * (grid.y - 2), "Interior count must match topology.")
		assert(corners.size() + edges.size() + inside.size() == count)
		var seen: Dictionary = {}
		for category: int in range(3):
			var ids: PackedInt32Array = Catalog.ids_for_category(grid.x, grid.y, category)
			var previous: int = -1
			for piece_id: int in ids:
				assert(piece_id > previous, "Category results must be sorted and deterministic.")
				assert(not seen.has(piece_id), "Category membership must be exclusive.")
				assert(Catalog.category_for(piece_id, grid.x, grid.y) == category)
				seen[piece_id] = true
				previous = piece_id
		assert(seen.size() == count)
	assert(Catalog.ids_for_category(0, 10, Catalog.Category.CORNER).is_empty())
	assert(Catalog.ids_for_category(5, 4, -1).is_empty())
	assert(Catalog.ids_for_category(5, 4, 20).is_empty())
	assert(Catalog.category_for(-1, 5, 4) == -1)
	assert(Catalog.category_for(20, 5, 4) == -1)
	print("JigsawG immutable piece topology catalog: PASS")
	quit()
