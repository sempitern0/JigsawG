extends RefCounted
## Pure bounded undo/redo cursor. The Board performs validated restores.
## Each entry owns independent snapshots; no state is serialized to disk.

var maximum_actions := 20
var _entries: Array[Dictionary] = []
var _cursor := 0


func clear() -> void:
	_entries.clear()
	_cursor = 0


func undo_count() -> int:
	return _cursor


func redo_count() -> int:
	return _entries.size() - _cursor


func _same_state(a: JigsawPuzzleState, b: JigsawPuzzleState) -> bool:
	return a != null and b != null and a.completed == b.completed \
		and a.piece_positions == b.piece_positions \
		and a.piece_rotations == b.piece_rotations \
		and a.piece_group_ids == b.piece_group_ids \
		and a.locked_piece_ids == b.locked_piece_ids \
		and a.tray_indices == b.tray_indices


func push(before: JigsawPuzzleState, after: JigsawPuzzleState, label: StringName) -> bool:
	if before == null or after == null or _same_state(before, after):
		return false
	# A new action after undo invalidates the redo branch.
	while _entries.size() > _cursor:
		_entries.pop_back()
	_entries.append({
		"before": before.duplicate(true),
		"after": after.duplicate(true),
		"label": label
	})
	_cursor += 1
	while _entries.size() > maxi(1, maximum_actions):
		_entries.pop_front()
		_cursor -= 1
	return true


func next_undo() -> JigsawPuzzleState:
	if _cursor <= 0:
		return null
	return _entries[_cursor - 1]["before"] as JigsawPuzzleState


func next_redo() -> JigsawPuzzleState:
	if _cursor >= _entries.size():
		return null
	return _entries[_cursor]["after"] as JigsawPuzzleState


func undo_label() -> StringName:
	return _entries[_cursor - 1]["label"] if _cursor > 0 else &""


func redo_label() -> StringName:
	return _entries[_cursor]["label"] if _cursor < _entries.size() else &""


## Move the cursor ONLY after the Board accepted the snapshot.
func accept_undo() -> void:
	if _cursor > 0:
		_cursor -= 1


func accept_redo() -> void:
	if _cursor < _entries.size():
		_cursor += 1
