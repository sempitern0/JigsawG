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

static func edge_points(start: Vector2, finish: Vector2, normal: Vector2, edge: Vector2i, depth: float, steps: int = 8, family: int = 0, variation: float = 1.0) -> PackedVector2Array:
	if edge.x == 0:
		return PackedVector2Array([start, finish])
	var variant := posmod(edge.y, PROFILE_SHIFT.size())
	var variety := clampf(variation, 0.0, 1.0)
	var profile_family := clampi(family, 0, 5)
	if profile_family == 5:
		return _organic_edge(start, finish, normal, edge, depth, steps, variety)
	if profile_family == 4: # Select from the seam's shared variant.
		profile_family = 1 + posmod(edge.y, 3)
	var center: float = 0.5 + PROFILE_SHIFT[variant] * variety
	var head := 0.195
	var neck := 0.095
	var shoulder := 0.265
	var crown_height := 0.90
	var shoulder_height := 0.47
	var tip_handle := 0.16
	match profile_family:
		1: # Rounded
			head = 0.207
			neck = 0.123
			shoulder = 0.275
			tip_handle = 0.195
		2: # Angular
			head = 0.173
			neck = 0.068
			shoulder = 0.255
			shoulder_height = 0.51
			crown_height = 0.99
			tip_handle = 0.065
		3: # Compact
			head = 0.148
			neck = 0.079
			shoulder = 0.218
			shoulder_height = 0.34
			crown_height = 0.67
			tip_handle = 0.105
	head += (PROFILE_HEAD[variant] - 0.195) * variety
	neck += (PROFILE_NECK[variant] - 0.095) * variety
	var d: float = depth * lerpf(1.0, PROFILE_DEPTH[variant], variety) * float(signi(edge.x))

	# A tab is a continuously joined six-cubic path. Unlike a sine hump, the
	# neck is narrower than the head and the crown rounds over the shoulders.
	# Its identical reverse is the precisely matching socket, including at
	# zoomed-in scales. No atlas, hard-coded PNG or per-piece mask is needed.
	var a := Vector2(center - shoulder, 0.0)
	var b := Vector2(center - neck, 0.065)
	var c := Vector2(center - head, shoulder_height)
	var tip := Vector2(center, crown_height)
	var mirror_c := Vector2(center + head, shoulder_height)
	var mirror_b := Vector2(center + neck, 0.065)
	var mirror_a := Vector2(center + shoulder, 0.0)
	var samples := PackedVector2Array([Vector2.ZERO, a])
	_cubic(samples, a, a + Vector2(0.077, 0.0), b + Vector2(-0.037, -0.080), b, steps)
	_cubic(samples, b, b + Vector2(0.050, 0.17), c + Vector2(-0.032, -0.18), c, steps)
	_cubic(samples, c, c + Vector2(-0.035, 0.25), tip + Vector2(-tip_handle, 0.0), tip, steps)
	_cubic(samples, tip, tip + Vector2(tip_handle, 0.0), mirror_c + Vector2(0.035, 0.25), mirror_c, steps)
	_cubic(samples, mirror_c, mirror_c + Vector2(0.032, -0.18), mirror_b + Vector2(-0.050, 0.17), mirror_b, steps)
	_cubic(samples, mirror_b, mirror_b + Vector2(0.037, -0.080), mirror_a + Vector2(-0.077, 0.0), mirror_a, steps)
	samples.append(Vector2(1.0, 0.0))

	var result := PackedVector2Array()
	for sample in samples:
		result.append(start.lerp(finish, sample.x) + normal * d * sample.y)
	return result

## Organic profiles are determined by one shared seam token, not by the
## individual puzzle piece. This guarantees mathematically complementary tabs
## and sockets without raster masks, per-piece textures or copied SVG artwork.
##
## Token layout: archetype * 4096 + per-seam variation. Eight simple archetypes
## can each have 4096 distinctive shapes; the same token is reused by neighbors.
static func _organic_edge(
	start: Vector2,
	finish: Vector2,
	normal: Vector2,
	edge: Vector2i,
	depth: float,
	steps: int,
	variation: float
) -> PackedVector2Array:
	var token := maxi(0, edge.y)
	var archetype := floori(float(token) / 4096.0)
	var spread := clampf(variation, 0.0, 1.0)
	var center := 0.5 + ( _organic_unit(token, 1) - 0.5) * 0.13 * spread
	var l_shoulder := 0.260 + (_organic_unit(token, 2) - 0.5) * 0.080 * spread
	var r_shoulder := 0.260 + (_organic_unit(token, 3) - 0.5) * 0.080 * spread
	var l_neck := 0.105 + (_organic_unit(token, 4) - 0.5) * 0.042 * spread
	var r_neck := 0.105 + (_organic_unit(token, 5) - 0.5) * 0.042 * spread
	var l_head := 0.182 + (_organic_unit(token, 6) - 0.5) * 0.070 * spread
	var r_head := 0.182 + (_organic_unit(token, 7) - 0.5) * 0.070 * spread
	var peak_offset := (_organic_unit(token, 8) - 0.5) * 0.090 * spread
	var height := 0.91 + (_organic_unit(token, 9) - 0.5) * 0.28 * spread
	var l_height := 0.51 + (_organic_unit(token, 10) - 0.5) * 0.15 * spread
	var r_height := 0.51 + (_organic_unit(token, 11) - 0.5) * 0.15 * spread
	# Archetypes are subtle shape families instead of visibly identical knobs.
	match posmod(archetype, 4):
		1:
			l_head += 0.016 * spread
			height += 0.09 * spread
		2:
			r_head += 0.022 * spread
			r_neck -= 0.018 * spread
		3:
			height -= 0.12 * spread
			l_shoulder += 0.025 * spread
	var left_wobble := (_organic_unit(token, 12) - 0.5) * 0.080 * spread
	var right_wobble := (_organic_unit(token, 13) - 0.5) * 0.080 * spread
	var left_foot := (_organic_unit(token, 14) - 0.5) * 0.040 * spread
	var right_foot := (_organic_unit(token, 15) - 0.5) * 0.040 * spread
	var anchors: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(0.11, left_wobble),
		Vector2(center - l_shoulder, left_foot),
		Vector2(center - l_neck, 0.10),
		Vector2(center - l_head, l_height),
		Vector2(center + peak_offset, height),
		Vector2(center + r_head, r_height),
		Vector2(center + r_neck, 0.10),
		Vector2(center + r_shoulder, right_foot),
		Vector2(0.89, right_wobble),
		Vector2(1.0, 0.0)
	]
	var samples := PackedVector2Array([anchors[0]])
	for index in range(anchors.size() - 1):
		var prev: Vector2 = anchors[maxi(0, index - 1)]
		var a: Vector2 = anchors[index]
		var d: Vector2 = anchors[index + 1]
		var next: Vector2 = anchors[mini(anchors.size() - 1, index + 2)]
		# Cardinal-spline control points give a continuous tangent at every
		# join while allowing the bulb to widen naturally beyond the neck.
		var b: Vector2 = a + (d - prev) * 0.16
		var c: Vector2 = d - (next - a) * 0.16
		_cubic(samples, a, b, c, d, mini(12, maxi(3, steps)))
	var normal_depth := depth * float(signi(edge.x))
	var outline := PackedVector2Array()
	for p in samples:
		outline.append(start.lerp(finish, p.x) + normal * normal_depth * p.y)
	return outline


static func _organic_unit(token: int, salt: int) -> float:
	# Bounded integer hash, independent of order and the board RNG.
	var value: int = posmod(token * 1607 + salt * 7919 + 104729, 1000003)
	value = posmod(value * value + salt * 8191, 1000003)
	return float(value) / 1000003.0


static func _cubic(result: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int) -> void:
	for i in range(1, maxi(3, steps) + 1):
		result.append(a.bezier_interpolate(b, c, d, float(i) / float(maxi(3, steps))))

static func make_outline(size: Vector2, top: Vector2i, right: Vector2i, bottom: Vector2i, left: Vector2i, detail: int = 8, connector_depth: float = 0.25, family: int = 0, variation: float = 1.0) -> PackedVector2Array:
	var depth := minf(size.x, size.y) * clampf(connector_depth, 0.12, 0.34)
	var segments: Array[PackedVector2Array] = [
		edge_points(Vector2.ZERO, Vector2(size.x, 0.0), Vector2.DOWN, top, depth, detail, family, variation),
		edge_points(Vector2(size.x, 0.0), size, Vector2.RIGHT, right, depth, detail, family, variation),
		edge_points(Vector2(0.0, size.y), size, Vector2.DOWN, bottom, depth, detail, family, variation),
		edge_points(Vector2.ZERO, Vector2(0.0, size.y), Vector2.RIGHT, left, depth, detail, family, variation)
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
