extends SceneTree
## godot --headless --path . --script res://tests/test_piece_organizer.gd
## Explicit types keep Godot's Variant-inference warnings from breaking CI.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
const ACTION_EDGE: StringName = &"jigsawg_test_organizer_edge"
const ACTION_INTERIOR: StringName = &"jigsawg_test_organizer_interior"


func _initialize() -> void:
	call_deferred("_verify")


func _config(mosaic: bool = false) -> JigsawPuzzleConfig:
	var config: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	config.columns = 4
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	config.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC if mosaic else JigsawGameplaySettings.Mode.FREE
	config.gameplay.next_corner_key = KEY_C
	config.gameplay.next_edge_action = ACTION_EDGE
	config.gameplay.next_interior_action = ACTION_INTERIOR
	return config


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


func _action(name: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


func _verify() -> void:
	assert(not InputMap.has_action(ACTION_EDGE))
	assert(not InputMap.has_action(ACTION_INTERIOR))
	InputMap.add_action(ACTION_EDGE)
	InputMap.add_action(ACTION_INTERIOR)
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var config: JigsawPuzzleConfig = _config()
	var board: BoardScript = BoardScript.new()
	board.puzzle_config = config
	host.add_child(board)
	assert(board.get_piece_count() == 12)
	assert(board.get_piece_category(-1) == -1)
	assert(board.get_piece_category(12) == -1)
	assert(board.get_piece_category(0) == BoardScript.PieceCategory.CORNER)
	assert(board.get_piece_category(1) == BoardScript.PieceCategory.EDGE)
	assert(board.get_piece_category(5) == BoardScript.PieceCategory.INTERIOR)
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.CORNER) == PackedInt32Array([0, 3, 8, 11]))
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.EDGE) == PackedInt32Array([1, 2, 4, 7, 9, 10]))
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.INTERIOR) == PackedInt32Array([5, 6]))

	# Changing a piece's draw shape or position cannot affect original topology.
	var first: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	first.position = Vector2(-2200, 800)
	board.rotate_piece(0)
	assert(board.get_piece_category(0) == BoardScript.PieceCategory.CORNER)
	board.select_piece(3, true)
	var chosen: PackedInt32Array = board.get_selected_piece_ids()
	var prior_state: JigsawPuzzleState = board.capture_state()
	var target: int = board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER)
	assert(target == 0)
	assert(camera.global_position.is_equal_approx(board.to_global(board._group_bounds_local(0).get_center())))
	assert(board.get_selected_piece_ids() == chosen)
	target = board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER)
	assert(target == 3)
	board._unhandled_input(_key(KEY_C))
	assert(camera.global_position.is_equal_approx(board.to_global(board._group_bounds_local(8).get_center())))
	board._unhandled_input(_action(ACTION_EDGE))
	assert(camera.global_position.is_equal_approx(board.to_global(board._group_bounds_local(1).get_center())))
	board._unhandled_input(_action(ACTION_INTERIOR))
	assert(camera.global_position.is_equal_approx(board.to_global(board._group_bounds_local(5).get_center())))
	var after_state: JigsawPuzzleState = board.capture_state()
	assert(prior_state.piece_positions == after_state.piece_positions, "Organizer cannot move pieces.")
	assert(prior_state.piece_rotations == after_state.piece_rotations, "Organizer cannot rotate pieces.")
	assert(prior_state.piece_group_ids == after_state.piece_group_ids, "Organizer cannot modify groups.")
	assert(board.get_selected_piece_ids() == chosen, "Organizer must not steal selection.")

	# Disabled input, a held piece, or the reference overlay must block browsing.
	board.set_interaction_enabled(false)
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.EDGE) == -1)
	board.set_interaction_enabled(true)
	board._drag_root = 0
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.EDGE) == -1)
	board._drag_root = -1
	board.set_preview_visible(true)
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.EDGE) == -1)
	board.set_preview_visible(false)

	# Arrange a valid solved layout before joining: the earlier visibility
	# check intentionally moved and rotated piece 0 far from its neighbors.
	# The organizer never performs this step; the test creates a valid join.
	for piece_id: int in range(board.get_piece_count()):
		var member: JigsawPiece = board.get_piece_node(piece_id) as JigsawPiece
		member.position = member.home
		board._set_piece_quarters(piece_id, 0)
	# Unions stay authoritative: joined groups are visited once per category.
	var connected: bool = board._connect_group_from(0)
	assert(connected)
	assert(board.get_connected_group_count() == 1)
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER) == 0)
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER) == 0)

	# Restoring a snapshot resets browsing state and does not change topology.
	assert(board.restore_state(prior_state))
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER) == 0)
	assert(board.get_piece_category(0) == BoardScript.PieceCategory.CORNER)

	# Mosaic locks are omitted by default, but visible in explicit metadata queries.
	var mosaic: JigsawPuzzleConfig = _config(true)
	board.configure(mosaic)
	board.select_piece(0, true)
	assert(board._place_selected_in_mosaic())
	assert(board.get_locked_piece_count() == 1)
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.CORNER) == PackedInt32Array([3, 8, 11]))
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.CORNER, true) == PackedInt32Array([0, 3, 8, 11]))
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER) == 3)

	# A partially generated batch cannot be reported as a complete catalog.
	var pending: JigsawPuzzleConfig = _config()
	pending.gameplay.generation_batch_size = 3
	board.configure(pending)
	assert(board.is_generating())
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.CORNER).is_empty())
	assert(board.focus_next_piece_by_category(BoardScript.PieceCategory.CORNER) == -1)
	await board.puzzle_generated
	assert(board.get_piece_ids_by_category(BoardScript.PieceCategory.CORNER).size() == 4)
	InputMap.erase_action(ACTION_EDGE)
	InputMap.erase_action(ACTION_INTERIOR)
	print("JigsawG organizer camera browsing and classification: PASS")
	host.queue_free()
	quit()
