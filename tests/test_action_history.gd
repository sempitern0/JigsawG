extends SceneTree
## godot --headless --path . --script res://tests/test_action_history.gd
const ActionHistory = preload("res://addons/jigsawg/src/jigsaw_action_history.gd")


func _state(x: float) -> JigsawPuzzleState:
	var state: JigsawPuzzleState = JigsawPuzzleState.new()
	state.piece_positions = PackedVector2Array([Vector2(x, 0.0)])
	state.piece_rotations = PackedInt32Array([0])
	state.piece_group_ids = PackedInt32Array([0])
	return state


func _initialize() -> void:
	var history: ActionHistory = ActionHistory.new()
	history.maximum_actions = 2
	assert(history.undo_count() == 0)
	assert(history.next_undo() == null)
	assert(not history.push(_state(0), _state(0), &"noop"))
	assert(history.push(_state(0), _state(10), &"move"))
	assert(history.push(_state(10), _state(20), &"move"))
	assert(history.push(_state(20), _state(30), &"move"))
	assert(history.undo_count() == 2 and history.redo_count() == 0)
	assert(history.next_undo().piece_positions[0] == Vector2(20, 0))
	assert(history.undo_label() == &"move")
	history.accept_undo()
	assert(history.next_undo().piece_positions[0] == Vector2(10, 0))
	history.accept_undo()
	assert(history.next_undo() == null and history.redo_count() == 2)
	assert(history.next_redo().piece_positions[0] == Vector2(20, 0))
	history.accept_redo()
	assert(history.undo_count() == 1 and history.redo_count() == 1)
	# Committing an action from an undone position removes the old future.
	assert(history.push(_state(20), _state(25), &"rotate"))
	assert(history.redo_count() == 0 and history.undo_label() == &"rotate")
	var held: JigsawPuzzleState = _state(25)
	assert(history.push(held, _state(27), &"move"))
	var changed_positions: PackedVector2Array = held.piece_positions
	changed_positions[0] = Vector2(999, 999)
	held.piece_positions = changed_positions
	assert(history.next_undo().piece_positions[0] == Vector2(25, 0))
	history.clear()
	assert(history.undo_count() == 0 and history.redo_count() == 0)
	print("JigsawG bounded action history and redo branching: PASS")
	quit()
