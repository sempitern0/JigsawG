extends RefCounted
## Deterministic shelf packing of connected-group AABBs in board coordinates.
## Returns offsets for each group without changing their rotations or members.


static func arrange(bounds: Array[Rect2], origin: Vector2, min_width: float, gap: float, min_height: float) -> Dictionary:
	var padding: float = maxf(gap, 0.0)
	var max_piece_width: float = 0.0
	var area: float = 0.0
	for rect: Rect2 in bounds:
		max_piece_width = maxf(max_piece_width, rect.size.x)
		area += (rect.size.x + padding) * (rect.size.y + padding)
	var width: float = maxf(maxf(min_width, max_piece_width + padding * 2.0), sqrt(area) * 1.25)
	var cursor: Vector2 = origin + Vector2(padding, padding)
	var row_height: float = 0.0
	var offsets: Array[Vector2] = []
	for rect: Rect2 in bounds:
		if cursor.x > origin.x + padding and cursor.x + rect.size.x + padding > origin.x + width:
			cursor.x = origin.x + padding
			cursor.y += row_height + padding
			row_height = 0.0
		offsets.append(cursor - rect.position)
		row_height = maxf(row_height, rect.size.y)
		cursor.x += rect.size.x + padding
	var height: float = maxf(min_height, cursor.y + row_height + padding - origin.y)
	return {"rect": Rect2(origin, Vector2(width, height)), "offsets": offsets}


static func contains_world_point(world_point: Vector2, board_transform: Transform2D, tray_rects: Array[Rect2]) -> int:
	var board_point: Vector2 = board_transform.affine_inverse() * world_point
	for index: int in range(tray_rects.size()):
		if tray_rects[index].has_point(board_point):
			return index
	return -1
