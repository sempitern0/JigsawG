extends RefCounted
## Validate serialized state before touching any live puzzle nodes.
## An empty result is valid; otherwise the caller can display the reason.

static func validate(
	state: JigsawPuzzleState,
	columns: int,
	rows: int,
	source_size: Vector2i,
	seed: int,
	silhouette_variants: int,
	connector_family: int,
	connector_variation: float,
	connector_depth: float,
	bezier_detail: int,
	game_mode: int
) -> String:
	if state == null:
		return "missing state"
	if state.schema_version != JigsawPuzzleState.SCHEMA_VERSION:
		return "unsupported schema version"
	if state.columns != columns or state.rows != rows or state.source_size != source_size:
		return "grid or source dimensions do not match"
	if state.generation_seed != seed or state.silhouette_variants != silhouette_variants:
		return "generation seed or silhouette count does not match"
	if state.connector_family != connector_family or not is_equal_approx(state.connector_variation, connector_variation):
		return "connector profile settings do not match"
	if state.connector_depth >= 0.0 and not is_equal_approx(state.connector_depth, connector_depth):
		return "connector depth does not match"
	if state.bezier_detail >= 0 and state.bezier_detail != bezier_detail:
		return "Bézier sampling detail does not match"
	if state.game_mode >= 0 and state.game_mode != game_mode:
		return "puzzle game mode does not match"
	var count := columns * rows
	if state.piece_positions.size() != count or state.piece_rotations.size() != count or state.piece_group_ids.size() != count:
		return "piece array lengths do not match"
	var group_representatives: Dictionary = {}
	for i in range(count):
		var group_id := state.piece_group_ids[i]
		if group_id < 0 or group_id >= count:
			return "group id is out of range"
		if state.piece_rotations[i] < 0 or state.piece_rotations[i] > 3:
			return "rotation is not a quarter-turn"
		if not state.piece_positions[i].is_finite():
			return "position contains a non-finite coordinate"
		if not group_representatives.has(group_id):
			group_representatives[group_id] = i
		else:
			var first_id: int = group_representatives[group_id]
			if state.piece_rotations[first_id] != state.piece_rotations[i]:
				return "connected group has inconsistent rotations"
	for group_id in group_representatives:
		if state.piece_group_ids[int(group_id)] != int(group_id):
			return "group id is not a valid representative"
	var seen_locks: Dictionary = {}
	for locked_id in state.locked_piece_ids:
		if locked_id < 0 or locked_id >= count or seen_locks.has(locked_id):
			return "locked piece id is invalid or duplicated"
		seen_locks[locked_id] = true
		if state.piece_rotations[locked_id] != 0:
			return "locked piece has a nonzero rotation"
	if game_mode == 0: # Free mode; locks belong to Mosaic.
		if not seen_locks.is_empty():
			return "Free mode snapshot contains Mosaic locks"
		if state.completed and group_representatives.size() != 1:
			return "completed Free puzzle contains multiple groups"
	elif state.completed and seen_locks.size() != count:
		return "completed Mosaic puzzle is missing locked pieces"
	return ""
