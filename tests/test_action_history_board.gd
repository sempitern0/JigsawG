extends SceneTree
## godot --headless --path . --script res://tests/test_action_history_board.gd
## Typed locals throughout: never infer a Variant with :=.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
const UNDO_ACTION: StringName = &"jigsawg_test_history_undo"
const REDO_ACTION: StringName = &"jigsawg_test_history_redo"

var _applied: Array[StringName] = []
var _join_events: int = 0
var _completion_events: int = 0


func _initialize() -> void:
	call_deferred("_verify")


func _config(mode: JigsawGameplaySettings.Mode = JigsawGameplaySettings.Mode.FREE,
		pieces: int = 3, trays_enabled: bool = false) -> JigsawPuzzleConfig:
	var cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	cfg.columns = pieces
	cfg.rows = pieces
	cfg.gameplay.game_mode = mode
	cfg.gameplay.initial_scatter = false
	cfg.gameplay.allow_piece_rotation = true
	cfg.history.enabled = true
	cfg.history.maximum_actions = 2
	cfg.history.undo_action = UNDO_ACTION
	cfg.history.redo_action = REDO_ACTION
	cfg.trays.enabled = trays_enabled
	return cfg


func _event(name: StringName) -> InputEventAction:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = name
	ev.pressed = true
	return ev


func _same(a: JigsawPuzzleState, b: JigsawPuzzleState) -> bool:
	return a.piece_positions == b.piece_positions and a.piece_rotations == b.piece_rotations \
		and a.piece_group_ids == b.piece_group_ids and a.locked_piece_ids == b.locked_piece_ids \
		and a.tray_indices == b.tray_indices and a.completed == b.completed


func _verify() -> void:
	assert(not InputMap.has_action(UNDO_ACTION) and not InputMap.has_action(REDO_ACTION))
	InputMap.add_action(UNDO_ACTION)
	InputMap.add_action(REDO_ACTION)
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var board: BoardScript = BoardScript.new()
	board.puzzle_config = _config()
	host.add_child(board)
	board.history_applied.connect(func(direction: StringName, _label: StringName) -> void:
		_applied.append(direction)
	)
	board.group_connection_succeeded.connect(func(_event: JigsawPuzzleEvent) -> void:
		_join_events += 1
	)
	board.puzzle_completed.connect(func() -> void:
		_completion_events += 1
	)
	assert(board.get_piece_count() == 9)
	assert(board.get_history_counts() == Vector2i.ZERO)
	assert(not board.undo() and not board.redo())
	var before_rotate: JigsawPuzzleState = board.capture_state()
	board.rotate_piece(0)
	assert(board.can_undo() and not board.can_redo())
	assert(board.get_next_undo_label() == &"rotate")
	assert(board.get_history_counts() == Vector2i(1, 0))
	var rotated: JigsawPuzzleState = board.capture_state()
	assert(not _same(before_rotate, rotated))
	assert(board.undo())
	assert(_same(before_rotate, board.capture_state()))
	assert(board.can_redo() and not board.can_undo())
	assert(board.get_next_redo_label() == &"rotate")
	# Host-defined action goes through the same validated history path.
	board._unhandled_input(_event(REDO_ACTION))
	assert(_same(rotated, board.capture_state()))
	assert(board.get_history_counts() == Vector2i(1, 0))

	# Direct second rotation creates a second transaction. Third evicts first.
	board.rotate_piece(1)
	board.rotate_piece(2)
	assert(board.get_history_counts() == Vector2i(2, 0))
	assert(board.undo() and board.undo())
	assert(not board.undo())
	assert(board.get_history_counts() == Vector2i(0, 2))
	board._unhandled_input(_event(REDO_ACTION))
	assert(board.get_history_counts() == Vector2i(1, 1))
	# Branching after one redo removes the remaining redo future.
	board.rotate_piece(3)
	assert(board.get_history_counts() == Vector2i(2, 0))
	assert(not board.redo())

	# A click with no travel doesn't waste a history slot.
	board.clear_history()
	var first: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	board._begin_piece_drag(0, first.global_position)
	board._finish_pointer_drag(board._drag_start_screen, first.global_position)
	assert(board.get_history_counts() == Vector2i.ZERO)

	# A full drag is ONE action, irrespective of mouse motion/frame count.
	var drag_baseline: JigsawPuzzleState = board.capture_state()
	board._begin_piece_drag(0, first.global_position)
	board._activate_drag()
	board._finish_pointer_drag(Vector2(250, 250), board.to_global(Vector2(2100, -1600)))
	var dragged: JigsawPuzzleState = board.capture_state()
	assert(not _same(drag_baseline, dragged))
	assert(board.get_history_counts() == Vector2i(1, 0))
	assert(board.undo() and _same(drag_baseline, board.capture_state()))
	assert(board.redo() and _same(dragged, board.capture_state()))

	# A rotation during a held drag remains part of that ONE transaction.
	board.clear_history()
	var second: JigsawPiece = board.get_piece_node(4) as JigsawPiece
	var composite_before: JigsawPuzzleState = board.capture_state()
	board._begin_piece_drag(4, second.global_position)
	board._activate_drag()
	board.rotate_piece(4)
	board._finish_pointer_drag(Vector2(250, 250), board.to_global(Vector2(1700, -1500)))
	assert(board.get_history_counts() == Vector2i(1, 0))
	assert(board.undo())
	assert(_same(composite_before, board.capture_state()))

	# Host pause, preview and an open drag block history application.
	board.redo()
	board.set_interaction_enabled(false)
	assert(not board.undo())
	board.set_interaction_enabled(true)
	board.set_preview_visible(true)
	assert(not board.undo())
	board.set_preview_visible(false)
	second = board.get_piece_node(4) as JigsawPiece
	board._begin_piece_drag(4, second.global_position)
	assert(not board.undo())
	board._cancel_drag()
	assert(board.undo())

	# External, validated restore invalidates the old replay history.
	board.rotate_piece(2)
	assert(board.can_undo())
	var saved: JigsawPuzzleState = board.capture_state()
	assert(board.restore_state(saved))
	assert(board.get_history_counts() == Vector2i.ZERO)

	# Tray API operations include membership, shelf repacking and retrieval.
	var with_trays: JigsawPuzzleConfig = _config(JigsawGameplaySettings.Mode.FREE, 3, true)
	board.configure(with_trays)
	assert(board.get_history_counts() == Vector2i.ZERO)
	var outside: JigsawPuzzleState = board.capture_state()
	assert(board.put_group_in_tray(0, 0))
	assert(board.get_piece_tray_index(0) == 0)
	var inside: JigsawPuzzleState = board.capture_state()
	assert(board.undo() and _same(outside, board.capture_state()))
	assert(board.redo() and _same(inside, board.capture_state()))
	assert(board.retrieve_group_from_tray(0))
	assert(board.get_piece_tray_index(0) == -1)
	assert(board.undo())
	assert(_same(inside, board.capture_state()))

	# Free group connectivity can be UNDONE; redo restores the graph exactly.
	board.configure(_config())
	for id: int in range(2, board.get_piece_count()):
		board.get_piece_node(id).position = Vector2(5000 + id * 700, 6000)
	first = board.get_piece_node(0) as JigsawPiece
	second = board.get_piece_node(1) as JigsawPiece
	second.position += Vector2(130, 0)
	var separate: JigsawPuzzleState = board.capture_state()
	board._begin_piece_drag(1, second.global_position)
	board._activate_drag()
	board._finish_pointer_drag(Vector2(150, 150), board.to_global(second.home))
	assert(board.get_connected_group_count() == 8)
	var united: JigsawPuzzleState = board.capture_state()
	var joins: int = _join_events
	assert(board.undo())
	assert(board.get_connected_group_count() == 9)
	assert(_same(separate, board.capture_state()))
	assert(board.redo())
	assert(board.get_connected_group_count() == 8)
	assert(_same(united, board.capture_state()))
	assert(_join_events == joins, "History replay must not fake gameplay joins.")

	# Mosaic locked cells are captured; undo unlocks without false placement.
	board.configure(_config(JigsawGameplaySettings.Mode.MOSAIC))
	first = board.get_piece_node(0) as JigsawPiece
	board._begin_piece_drag(0, first.global_position)
	board._activate_drag()
	board._finish_pointer_drag(Vector2(300, 300), first.global_position)
	assert(board.get_locked_piece_count() == 1)
	assert(board.undo() and board.get_locked_piece_count() == 0)
	assert(board.redo() and board.get_locked_piece_count() == 1)

	# Completed puzzles reopen on undo; redo does not re-emit completion.
	board.configure(_config(JigsawGameplaySettings.Mode.FREE, 2))
	first = board.get_piece_node(0) as JigsawPiece
	board._begin_piece_drag(0, first.global_position)
	board._activate_drag()
	board._finish_pointer_drag(Vector2(300, 300), first.global_position)
	assert(board.is_completed())
	var completions: int = _completion_events
	assert(board.undo() and not board.is_completed())
	assert(board.redo() and board.is_completed())
	assert(_completion_events == completions)

	# Reset/rebuild and opt-out configs leave history empty and inert.
	board.rebuild()
	assert(board.get_history_counts() == Vector2i.ZERO)
	var disabled: JigsawPuzzleConfig = _config()
	disabled.history.enabled = false
	board.configure(disabled)
	board.rotate_piece(0)
	assert(not board.can_undo() and board.get_history_counts() == Vector2i.ZERO)
	assert(_applied.has(&"undo") and _applied.has(&"redo"))
	InputMap.erase_action(UNDO_ACTION)
	InputMap.erase_action(REDO_ACTION)
	print("JigsawG bounded Board action history, Free/Mosaic and group undo/redo: PASS")
	host.queue_free()
	quit()
