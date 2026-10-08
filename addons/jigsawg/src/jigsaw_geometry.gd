extends RefCounted
## Canonical, shared puzzle seams. Both pieces use the SAME edge profile, not
## independently inverted tab/hole drawings. Reversing traversal closes a
## clockwise polygon without changing the physical seam in world space.

const PROFILE_SHIFT := [-0.025, 0.0, 0.025, -0.015, 0.015, 0.0, -0.02, 0.02]
const PROFILE_HEAD := [0.18, 0.20, 0.16, 0.21, 0.17, 0.19, 0.215, 0.165]
const PROFILE_NECK := [0.105, 0.085, 0.095, 0.11, 0.08, 0.10, 0.09, 0.09]
const PROFILE_DEPTH := [1.0, 0.90, 1.10, 0.95, 1.05, 0.96, 1.12, 0.88]

## An edge is (polarity, profile_index). Both neighbors get this identical
## descriptor. A positive polarity bulges towards +Y on horizontal seams
## and +X on vertical seams; a negative polarity bulges the other way.
static func edge_points(start: Vector2, finish: Vector2, normal: Vector2, edge: Vector2i, depth: float, steps: int = 8) -> PackedVector2Array:
	if edge.x == 0:
		return PackedVector2Array([start, finish])

	var family := posmod(edge.y, PROFILE_SHIFT.size())
	var center: float = 0.5 + PROFILE_SHIFT[family]
	var head: float = PROFILE_HEAD[family]
	var neck: float = PROFILE_NECK[family]
	var signed_depth: float = depth * PROFILE_DEPTH[family] * float(signi(edge.x))
	var shoulder: float = center - 0.245
	var exit_shoulder: float = center + 0.245

	# Six cubic segments create distinct shoulders, narrow neck and a wider
	# undercut head (unlike a sine hump which is not a true jigsaw tab).
	var p0 := Vector2(shoulder, 0.0)
	var p1 := Vector2(center - neck, 0.14)
	var p2 := Vector2(center - head, 0.64)
	var p3 := Vector2(center, 1.0)
	var p4 := Vector2(center + head, 0.64)
	var p5 := Vector2(center + neck, 0.14)
	var p6 := Vector2(exit_shoulder, 0.0)

	var unit_points := PackedVector2Array([Vector2.ZERO, p0])
	_append_cubic(unit_points, p0, Vector2(shoulder + 0.068, 0.0), Vector2(center - neck - 0.025, -0.05), p1, steps)
	_append_cubic(unit_points, p1, Vector2(center - neck + 0.008, 0.43), Vector2(center - head - 0.012, 0.36), p2, steps)
	_append_cubic(unit_points, p2, Vector2(center - head - 0.04, 1.07), Vector2(center - 0.12, 1.0), p3, steps)
	_append_cubic(unit_points, p3, Vector2(center + 0.12, 1.0), Vector2(center + head + 0.04, 1.07), p4, steps)
	_append_cubic(unit_points, p4, Vector2(center + head + 0.012, 0.36), Vector2(center + neck - 0.008, 0.43), p5, steps)
	_append_cubic(unit_points, p5, Vector2(center + neck + 0.025, -0.05), Vector2(exit_shoulder - 0.068, 0.0), p6, steps)
	unit_points.append(Vector2.ONE * Vector2(1.0, 0.0))

	var answer := PackedVector2Array()
	for vertex in unit_points:
		answer.append(start.lerp(finish, vertex.x) + normal * signed_depth * vertex.y)
	return answer

static func _append_cubic(result: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int) -> void:
	for i in range(1, maxi(2, steps) + 1):
		result.append(a.bezier_interpolate(b, c, d, float(i) / float(maxi(2, steps))))

## Clockwise: top L->R, right T->B, bottom R->L, left B->T.
## Bottom and left must reverse the canonical edge traversal, NOT polarity.
static func make_outline(size: Vector2, top: Vector2i, right: Vector2i, bottom: Vector2i, left: Vector2i) -> PackedVector2Array:
	var depth := minf(size.x, size.y) * 0.235
	var segments: Array[PackedVector2Array] = [
		edge_points(Vector2.ZERO, Vector2(size.x, 0.0), Vector2.DOWN, top, depth),
		edge_points(Vector2(size.x, 0.0), size, Vector2.RIGHT, right, depth),
		edge_points(Vector2(0.0, size.y), size, Vector2.DOWN, bottom, depth),
		edge_points(Vector2.ZERO, Vector2(0.0, size.y), Vector2.RIGHT, left, depth)
	]
	segments[2].reverse()
	segments[3].reverse()
	var outline := PackedVector2Array()
	for edge_index in range(4):
		for j in range(segments[edge_index].size()):
			if edge_index > 0 and j == 0:
				continue
			outline.append(segments[edge_index][j])
	if outline.size() > 1 and outline[-1].is_equal_approx(outline[0]):
		outline.remove_at(outline.size() - 1)
	return outline
