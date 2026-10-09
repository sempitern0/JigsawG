extends RefCounted
## Deterministic shelf packing for detached selected groups.
## Every input is a group AABB in board-local coordinates; the first remains fixed.
## Offsets preserve internal piece spacing, rotation and established connections.

static func pack(group_rects: Array[Rect2], padding: float) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	if group_rects.is_empty():
		return offsets
	var gap := maxf(padding, 0.0)
	var max_width := 0.0
	var total_area := 0.0
	for rect in group_rects:
		var width := maxf(rect.size.x, 1.0)
		var height := maxf(rect.size.y, 1.0)
		max_width = maxf(max_width, width)
		total_area += (width + gap) * (height + gap)
	var row_width_limit := maxf(max_width, sqrt(total_area) * 1.3)
	var origin := group_rects[0].position
	var cursor_x := 0.0
	var cursor_y := 0.0
	var row_height := 0.0
	for rect in group_rects:
		var width := maxf(rect.size.x, 1.0)
		var height := maxf(rect.size.y, 1.0)
		if cursor_x > 0.0 and cursor_x + width > row_width_limit:
			cursor_x = 0.0
			cursor_y += row_height + gap
			row_height = 0.0
		var next_position := origin + Vector2(cursor_x, cursor_y)
		offsets.append(next_position - rect.position)
		cursor_x += width + gap
		row_height = maxf(row_height, height)
	return offsets
