extends SceneTree
## Run: godot --headless --path . --script res://tests/test_shape_profiles.gd
const Geometry = preload("res://addons/jigsawg/src/jigsaw_geometry.gd")

func _initialize() -> void:
	var start := Vector2.ZERO
	var finish := Vector2(100.0, 0.0)
	var normal := Vector2.DOWN
	var classic := Geometry.edge_points(start, finish, normal, Vector2i(1, 2), 24.0)
	assert(classic == Geometry.edge_points(start, finish, normal, Vector2i(1, 2), 24.0, 8, 0, 1.0), "Default profile must be backward compatible.")
	for family in range(5):
		for variant in range(8):
			var seam := Vector2i(1, variant)
			var positive := Geometry.edge_points(start, finish, normal, seam, 24.0, 8, family, 0.8)
			var negative := Geometry.edge_points(start, finish, normal, Vector2i(-1, variant), 24.0, 8, family, 0.8)
			assert(positive.size() == negative.size())
			for i in range(positive.size()):
				assert(is_equal_approx(positive[i].x, negative[i].x))
				assert(is_equal_approx(positive[i].y, -negative[i].y), "Shared seam must mirror exactly.")
			var outline := Geometry.make_outline(
				Vector2(100, 100), Vector2i.ZERO, seam, Vector2i.ZERO,
				Vector2i.ZERO, 8, 0.25, family, 0.8
			)
			assert(outline.size() > 10)
			for point in outline:
				assert(point.is_finite(), "Generated shape contains invalid coordinates.")
	assert(classic != Geometry.edge_points(start, finish, normal, Vector2i(1, 2), 24.0, 8, 1, 1.0))
	print("JigsawG procedural connector family test: PASS")
	quit()
