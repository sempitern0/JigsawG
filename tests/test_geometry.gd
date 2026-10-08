extends SceneTree
## Run: godot --headless --path . --script res://tests/test_geometry.gd
const Geometry = preload("res://addons/jigsawg/src/jigsaw_geometry.gd")

func _initialize() -> void:
	var checks := 0
	for size in [Vector2(128, 96), Vector2(203.5, 151.25)]:
		for family in range(8):
			for polarity in [-1, 1]:
				var descriptor := Vector2i(polarity, family)
				var shape_left: PackedVector2Array = Geometry.make_outline(size, Vector2i.ZERO, descriptor, Vector2i.ZERO, Vector2i.ZERO)
				var shape_right: PackedVector2Array = Geometry.make_outline(size, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, descriptor)
				# The left piece's right seam is drawn top-to-bottom. The right
				# piece's left seam is drawn bottom-to-top; reverse for comparison.
				var left_seam := Geometry.edge_points(Vector2(size.x, 0), size, Vector2.RIGHT, descriptor, minf(size.x, size.y) * 0.235)
				var right_seam := Geometry.edge_points(Vector2.ZERO, Vector2(0, size.y), Vector2.RIGHT, descriptor, minf(size.x, size.y) * 0.235)
				assert(left_seam.size() == right_seam.size())
				for i in range(left_seam.size()):
					assert((left_seam[i] - Vector2(size.x, 0)).distance_to(right_seam[i]) < 0.0001, "Unmatched vertical seam")
				assert(shape_left.size() > 12 and shape_right.size() > 12)
				checks += 1
	print("JigsawG canonical edge checks passed: %d" % checks)
	quit()
