extends RefCounted
## Resolve a requested approximate number of pieces into a visually balanced grid.
## Do not force thin 1xN strips for prime numbers; actual count can differ slightly.

static func resolve(
	requested_count: int,
	source_size: Vector2i,
	max_axis: int = 80,
	min_piece_side: float = 14.0
) -> Vector2i:
	if requested_count < 4 or source_size.x <= 0 or source_size.y <= 0:
		return Vector2i.ZERO
	var best := Vector2i.ZERO
	var best_score := INF
	var best_count_error := INF
	var source_width := float(source_size.x)
	var source_height := float(source_size.y)
	for columns in range(2, maxi(2, max_axis) + 1):
		if source_width / float(columns) < min_piece_side:
			break
		for rows in range(2, maxi(2, max_axis) + 1):
			if source_height / float(rows) < min_piece_side:
				break
			var count := columns * rows
			var error := absf(float(count - requested_count)) / float(requested_count)
			var cell_ratio := (source_width / float(columns)) / (source_height / float(rows))
			# The ratio term protects tile aesthetics; count fidelity remains important.
			var score := 2.0 * error + 0.4 * absf(log(cell_ratio))
			if score < best_score - 0.000001 or (is_equal_approx(score, best_score) and error < best_count_error):
				best = Vector2i(columns, rows)
				best_score = score
				best_count_error = error
	return best
