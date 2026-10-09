extends RefCounted
## Pure, deterministic scatter planner for thousands of pieces.
## Structured modes enumerate concentric slot rings (no huge global sort);
## chaotic mode uses fixed-size spatial buckets (local collision checks).

const AROUND_BOARD := 0
const CENTER := 1
const BOTTOM := 2

static func structured(
	count: int,
	board_size: Vector2,
	piece_size: Vector2,
	mode: int,
	distribution: int,
	spacing: float,
	rng: RandomNumberGenerator
) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	if count <= 0:
		return slots
	var footprint_side := maxf(piece_size.x, piece_size.y)
	var stride := footprint_side * (1.65 + spacing)
	var board := Rect2(Vector2.ZERO, board_size)
	var forbidden := board.grow(stride)
	var center := board.get_center()
	var cx := roundi(center.x / stride)
	var cy := roundi(center.y / stride)
	# Concentric square rings yield O(count + cells intersecting the board).
	var ring := 0
	while slots.size() < count:
		if ring == 0:
			_append_slot(slots, Vector2(cx, cy) * stride, board, forbidden, mode, footprint_side, stride)
		else:
			for x in range(-ring, ring + 1):
				if slots.size() >= count:
					break
				_append_slot(slots, Vector2(cx + x, cy - ring) * stride, board, forbidden, mode, footprint_side, stride)
				if slots.size() < count:
					_append_slot(slots, Vector2(cx + x, cy + ring) * stride, board, forbidden, mode, footprint_side, stride)
			for y in range(-ring + 1, ring):
				if slots.size() >= count:
					break
				_append_slot(slots, Vector2(cx - ring, cy + y) * stride, board, forbidden, mode, footprint_side, stride)
				if slots.size() < count:
					_append_slot(slots, Vector2(cx + ring, cy + y) * stride, board, forbidden, mode, footprint_side, stride)
		ring += 1
		# Impossible layout inputs must not hang the main thread.
		if ring > count + 256:
			break
	if distribution == 0: # Random; Radial retains near-to-far ring order.
		for i in range(slots.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp: Vector2 = slots[i]
			slots[i] = slots[j]
			slots[j] = tmp
	return slots


static func _append_slot(
	slots: Array[Vector2],
	slot: Vector2,
	board: Rect2,
	forbidden: Rect2,
	mode: int,
	footprint_side: float,
	stride: float
) -> void:
	var footprint := Rect2(slot - Vector2.ONE * footprint_side * 0.33, Vector2.ONE * footprint_side * 1.66)
	if mode == AROUND_BOARD and forbidden.intersects(footprint):
		return
	if mode == BOTTOM and footprint.position.y < board.end.y + stride * 0.5:
		return
	slots.append(slot)


static func chaotic(
	count: int,
	board_size: Vector2,
	piece_size: Vector2,
	spacing: float,
	spread: float,
	max_attempts: int,
	rng: RandomNumberGenerator
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions
	var footprint_side := maxf(piece_size.x, piece_size.y)
	var half_side := footprint_side * (0.82 + spacing * 0.5)
	var full_side := half_side * 2.0
	var board := Rect2(Vector2.ZERO, board_size)
	var forbidden := board.grow(half_side * 0.8)
	var base_margin := footprint_side * maxf(3.0, sqrt(float(count)) * spread)
	var occupied: Dictionary = {}
	for piece_index in range(count):
		var placed := false
		var attempts_per_band := maxi(max_attempts, 8)
		for attempt in range(attempts_per_band * 5):
			var band := floori(float(attempt) / float(attempts_per_band))
			var area := board.grow(base_margin * (1.0 + float(band) * 0.35))
			var center := Vector2(
				rng.randf_range(area.position.x, area.end.x),
				rng.randf_range(area.position.y, area.end.y)
			)
			var footprint := Rect2(center - Vector2.ONE * half_side, Vector2.ONE * full_side)
			if forbidden.intersects(footprint) or _has_overlap(center, full_side, occupied):
				continue
			_store(center, full_side, occupied)
			positions.append(center - piece_size * 0.5)
			placed = true
			break
		if not placed:
			# Guaranteed expanding lane: no O(N^2) scan of all prior pieces.
			var center := Vector2(board.position.x + half_side + float(piece_index % 16) * full_side * 1.05,
					board.end.y + base_margin + float(piece_index / 16) * full_side * 1.05)
			while forbidden.intersects(Rect2(center - Vector2.ONE * half_side, Vector2.ONE * full_side)) or _has_overlap(center, full_side, occupied):
				center.y += full_side * 1.05
			_store(center, full_side, occupied)
			positions.append(center - piece_size * 0.5)
	return positions


static func _cell(center: Vector2, side: float) -> Vector2i:
	return Vector2i(floori(center.x / side), floori(center.y / side))


static func _store(center: Vector2, side: float, occupied: Dictionary) -> void:
	var key := _cell(center, side)
	if not occupied.has(key):
		occupied[key] = []
	occupied[key].append(center)


static func _has_overlap(center: Vector2, side: float, occupied: Dictionary) -> bool:
	var cell := _cell(center, side)
	for cy in range(cell.y - 1, cell.y + 2):
		for cx in range(cell.x - 1, cell.x + 2):
			for previous in occupied.get(Vector2i(cx, cy), []):
				if absf(previous.x - center.x) < side and absf(previous.y - center.y) < side:
					return true
	return false
