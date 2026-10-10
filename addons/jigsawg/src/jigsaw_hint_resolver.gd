extends RefCounted
## Pure deterministic candidate selection and solved-region calculation.
## No scene nodes, motion, group mutation or camera dependencies.

static func pick_candidate(group_ids: PackedInt32Array, locked_ids: PackedInt32Array,
		selected_ids: PackedInt32Array, after_piece_id: int = -1) -> int:
	if group_ids.is_empty():
		return -1
	var locked: Dictionary = {}
	for id: int in locked_ids:
		locked[id] = true
	# Prefer an explicitly chosen loose piece; it may belong to a larger group.
	for id: int in selected_ids:
		if id >= 0 and id < group_ids.size() and not locked.has(id):
			return id
	var representatives: Dictionary = {}
	var ordered: Array[int] = []
	for id: int in range(group_ids.size()):
		if locked.has(id):
			continue
		var root: int = group_ids[id]
		if not representatives.has(root):
			representatives[root] = true
			ordered.append(id)
	if ordered.is_empty():
		return -1
	for id: int in ordered:
		if id > after_piece_id:
			return id
	return ordered[0]


static func coarse_region(home: Vector2, cell_size: Vector2, grid: Vector2i,
		divisions: int) -> Rect2:
	if divisions < 2 or grid.x <= 0 or grid.y <= 0 or cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Rect2()
	var board_size: Vector2 = cell_size * Vector2(grid)
	var center: Vector2 = home + cell_size * 0.5
	var col: int = clampi(floori(center.x / board_size.x * divisions), 0, divisions - 1)
	var row: int = clampi(floori(center.y / board_size.y * divisions), 0, divisions - 1)
	return Rect2(board_size * Vector2(col, row) / float(divisions),
		board_size / float(divisions))
