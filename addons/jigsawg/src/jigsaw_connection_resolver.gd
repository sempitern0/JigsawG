extends RefCounted
## Pure grid-neighbor lookup and quarter-turn snap geometry.
## The board owns world transforms, moving pieces, sounds and events.

static func neighbor_ids(piece_id: int, columns: int, rows: int) -> PackedInt32Array:
	var found := PackedInt32Array()
	if columns < 1 or rows < 1 or piece_id < 0 or piece_id >= columns * rows:
		return found
	var row := floori(float(piece_id) / float(columns))
	var col := piece_id % columns
	if row > 0:
		found.append(piece_id - columns)
	if col < columns - 1:
		found.append(piece_id + 1)
	if row < rows - 1:
		found.append(piece_id + columns)
	if col > 0:
		found.append(piece_id - 1)
	return found


## Shift to apply to the anchor group. An infinite vector means "no snap".
static func snap_offset(
	first_home: Vector2,
	second_home: Vector2,
	first_position: Vector2,
	second_position: Vector2,
	first_quarters: int,
	second_quarters: int,
	tolerance_pixels: float
) -> Vector2:
	if first_quarters != second_quarters:
		return Vector2(INF, INF)
	var expected := (first_home - second_home).rotated(float(first_quarters) * PI * 0.5)
	var actual := first_position - second_position
	if not actual.is_finite() or actual.distance_to(expected) > maxf(0.0, tolerance_pixels):
		return Vector2(INF, INF)
	return expected - actual
