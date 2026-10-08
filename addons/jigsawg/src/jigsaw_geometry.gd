extends RefCounted
## Geometrically shared cardboard-style Bézier seams.
##
## Polarity is signed relative to a CANONICAL axis (top-to-bottom for vertical
## seams, left-to-right for horizontal seams). Adjacent pieces traverse the same
## points in reverse. NEVER independently flip the profile on one neighbor.

const PROFILE_SHIFT := [-0.028, 0.0, 0.026, -0.015, 0.016, 0.035, -0.035, 0.01]
const PROFILE_HEAD := [0.188, 0.201, 0.175, 0.211, 0.193, 0.180, 0.216, 0.205]
const PROFILE_NECK := [0.100, 0.090, 0.107, 0.095, 0.085, 0.110, 0.094, 0.083]
const PROFILE_DEPTH := [0.95, 1.0, 0.90, 1.06, 1.11, 0.94, 1.04, 0.98]

static func edge_points(start: Vector2, finish: Vector2, normal: Vector2, edge: Vector2i, depth: float, steps: int = 8) -> PackedVector2Array:
	if edge.x == 0:
		return PackedVector2Array([start, finish])
	var variant := posmod(edge.y, PROFILE_SHIFT.size())
	var center: float = 0.5 + PROFILE_SHIFT[variant]
	var neck: float = PROFILE_NECK[variant]
	var head: float = PROFILE_HEAD[variant]
	var d: float = depth * PROFILE_DEPTH[variant] * float(signi(edge.x))
	var shoulder := 0.265

	# A tab is a continuously joined six-cubic path. Unlike a sine hump, the
	# neck is narrower than the head and the crown rounds over the shoulders.
	# Its identical reverse is the precisely matching socket, including at
	# zoomed-in scales. No atlas, hard-coded PNG or per-piece mask is needed.
	var a := Vector2(center - shoulder, 0.0)
	var b := Vector2(center - neck, 0.065)
	var c := Vector2(center - head, 0.47)
	var tip := Vector2(center, 0.90)
	var mirror_c := Vector2(center + head, 0.47)
	var mirror_b := Vector2(center + neck, 0.065)
	var mirror_a := Vector2(center + shoulder, 0.0)
	var samples := PackedVector2Array([Vector2.ZERO, a])
	_cubic(samples, a, a + Vector2(0.077, 0.0), b + Vector2(-0.037, -0.080), b, steps)
	_cubic(samples, b, b + Vector2(0.050, 0.17), c + Vector2(-0.032, -0.18), c, steps)
	_cubic(samples, c, c + Vector2(-0.035, 0.25), tip + Vector2(-0.16, 0.0), tip, steps)
	_cubic(samples, tip, tip + Vector2(0.16, 0.0), mirror_c + Vector2(0.035, 0.25), mirror_c, steps)
	_cubic(samples, mirror_c, mirror_c + Vector2(0.032, -0.18), mirror_b + Vector2(-0.050, 0.17), mirror_b, steps)
	_cubic(samples, mirror_b, mirror_b + Vector2(0.037, -0.080), mirror_a + Vector2(-0.077, 0.0), mirror_a, steps)
	samples.append(Vector2(1.0, 0.0))

	var result := PackedVector2Array()
	for sample in samples:
		result.append(start.lerp(finish, sample.x) + normal * d * sample.y)
	return result

static func _cubic(result: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int) -> void:
	for i in range(1, maxi(3, steps) + 1):
		result.append(a.bezier_interpolate(b, c, d, float(i) / float(maxi(3, steps))))

static func make_outline(size: Vector2, top: Vector2i, right: Vector2i, bottom: Vector2i, left: Vector2i, detail: int = 8) -> PackedVector2Array:
	var depth := minf(size.x, size.y) * 0.25
	var segments: Array[PackedVector2Array] = [
		edge_points(Vector2.ZERO, Vector2(size.x, 0.0), Vector2.DOWN, top, depth, detail),
		edge_points(Vector2(size.x, 0.0), size, Vector2.RIGHT, right, depth, detail),
		edge_points(Vector2(0.0, size.y), size, Vector2.DOWN, bottom, depth, detail),
		edge_points(Vector2.ZERO, Vector2(0.0, size.y), Vector2.RIGHT, left, depth, detail)
	]
	segments[2].reverse()
	segments[3].reverse()
	var outline := PackedVector2Array()
	for side in range(4):
		for index in range(segments[side].size()):
			if side > 0 and index == 0:
				continue
			outline.append(segments[side][index])
	if outline.size() > 1 and outline[-1].is_equal_approx(outline[0]):
		outline.remove_at(outline.size() - 1)
	return outline
