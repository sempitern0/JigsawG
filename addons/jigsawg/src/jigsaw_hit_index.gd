extends RefCounted
## Spatial broad phase in board-local coordinates. The returned IDs are in
## descending scene order; the Board still runs exact polygon hit-testing.

var _cells: Dictionary = {}
var _rectangles: Array[Rect2] = []
var _cell_size := 64.0
var _dirty := true
var _last_candidate_count := 0


func invalidate() -> void:
	_dirty = true


func is_dirty() -> bool:
	return _dirty


func clear() -> void:
	_cells.clear()
	_rectangles.clear()
	_dirty = true
	_last_candidate_count = 0


func rebuild(rectangles: Array[Rect2], cell_size: float) -> void:
	_cells.clear()
	_rectangles = rectangles.duplicate()
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


## All broad-phase candidates intersecting a board-local rectangle.
## Useful for accessibility hit margins without expanding stored puzzle shapes.
## Results are deduplicated, with the old descending scene order preserved.
func query_region(region: Rect2) -> PackedInt32Array:
	var result := PackedInt32Array()
	_last_candidate_count = 0
	if _dirty or not region.position.is_finite() or not region.size.is_finite():
		return result
	if region.size.x < 0.0 or region.size.y < 0.0:
		return result
	var low := _cell(region.position)
	var high := _cell(region.end)
	var found: Dictionary = {}
	var width := high.x - low.x + 1
	var height := high.y - low.y + 1
	# At extreme zoom, a fixed on-screen margin can span many grid cells.
	# Iterating the stored rectangles avoids millions of empty-cell queries.
	if width * height > 4096:
		for id in range(_rectangles.size()):
			var rect := _rectangles[id]
			if rect.intersects(region) or region.has_point(rect.position):
				found[id] = true
	else:
		for y in range(low.y, high.y + 1):
			for x in range(low.x, high.x + 1):
				for id in _cells.get(Vector2i(x, y), []):
					found[id] = true
	var ids: Array = found.keys()
	ids.sort()
	_last_candidate_count = ids.size()
	for j in range(ids.size() - 1, -1, -1):
		result.append(int(ids[j]))
	return result


func last_candidate_count() -> int:
	return _last_candidate_count


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / _cell_size), floori(point.y / _cell_size))
