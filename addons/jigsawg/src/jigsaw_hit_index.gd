extends RefCounted
## Spatial broad phase in board-local coordinates. The returned IDs are in
## descending scene order; the Board still runs exact polygon hit-testing.

var _cells: Dictionary = {}
var _cell_size := 64.0
var _dirty := true
var _last_candidate_count := 0


func invalidate() -> void:
	_dirty = true


func is_dirty() -> bool:
	return _dirty


func clear() -> void:
	_cells.clear()
	_dirty = true
	_last_candidate_count = 0


func rebuild(rectangles: Array[Rect2], cell_size: float) -> void:
	_cells.clear()
	_cell_size = maxf(cell_size, 1.0)
	for piece_id in range(rectangles.size()):
		var bounds := rectangles[piece_id]
		if not bounds.position.is_finite() or not bounds.size.is_finite():
			continue
		var low := _cell(bounds.position)
		var high := _cell(bounds.end)
		for y in range(low.y, high.y + 1):
			for x in range(low.x, high.x + 1):
				var key := Vector2i(x, y)
				if not _cells.has(key):
					_cells[key] = []
				_cells[key].append(piece_id)
	_dirty = false


func query(point: Vector2) -> PackedInt32Array:
	var result := PackedInt32Array()
	_last_candidate_count = 0
	if _dirty or not point.is_finite():
		return result
	var members: Array = _cells.get(_cell(point), [])
	_last_candidate_count = members.size()
	for index in range(members.size() - 1, -1, -1):
		result.append(int(members[index]))
	return result


func last_candidate_count() -> int:
	return _last_candidate_count


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / _cell_size), floori(point.y / _cell_size))
