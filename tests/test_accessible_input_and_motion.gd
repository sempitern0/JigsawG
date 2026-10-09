extends SceneTree
## godot --headless --path . --script res://tests/test_accessible_input_and_motion.gd
## All locals are deliberately typed: Variant inference warnings are build errors.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

const ACTION_BOARD: StringName = &"jigsawg_test_accessible_focus_board"
const ACTION_OVERVIEW: StringName = &"jigsawg_test_accessible_overview"
const ACTION_SELECTION: StringName = &"jigsawg_test_accessible_focus_selection"
const ACTION_ZOOM_IN: StringName = &"jigsawg_test_accessible_zoom_in"
const ACTION_ZOOM_OUT: StringName = &"jigsawg_test_accessible_zoom_out"
const ACTION_ROTATE: StringName = &"jigsawg_test_accessible_rotate"
const ACTION_PREVIEW: StringName = &"jigsawg_test_accessible_preview"


func _initialize() -> void:
	call_deferred("_verify")


func _press(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _verify() -> void:
	var names: Array[StringName] = [
		ACTION_BOARD, ACTION_OVERVIEW, ACTION_SELECTION,
		ACTION_ZOOM_IN, ACTION_ZOOM_OUT, ACTION_ROTATE, ACTION_PREVIEW
	]
	for action: StringName in names:
		assert(not InputMap.has_action(action), "The test must not overwrite host InputMap actions.")
		InputMap.add_action(action)
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	cfg.columns = 4
	cfg.rows = 3
	cfg.gameplay.initial_scatter = false
	cfg.gameplay.allow_piece_rotation = true
	cfg.gameplay.rotate_action = ACTION_ROTATE
	cfg.gameplay.preview_action = ACTION_PREVIEW
	cfg.camera.focus_board_action = ACTION_BOARD
	cfg.camera.overview_action = ACTION_OVERVIEW
	cfg.camera.focus_selection_action = ACTION_SELECTION
	cfg.camera.zoom_in_action = ACTION_ZOOM_IN
	cfg.camera.zoom_out_action = ACTION_ZOOM_OUT
	cfg.feedback.motion_adapter = JigsawMotionAdapter.new()
	var board: Node2D = BoardScript.new()
	board.puzzle_config = cfg
	host.add_child(board)
	assert(not board.is_reduced_motion())
	assert(not board._matches_input_action(_press(&"jigsawg_missing_action"), &"jigsawg_missing_action"))
	assert(board._matches_input_action(_press(ACTION_ROTATE), ACTION_ROTATE))
	assert(not board._matches_input_action(_press(ACTION_ROTATE), ACTION_BOARD))

	# Host-defined focus actions do not mutate pieces and do not replace keys.
	camera.global_position = Vector2(-2000, 1300)
	board._unhandled_input(_press(ACTION_BOARD))
	var center: Vector2 = board.to_global(board._piece_size * Vector2(2, 1.5))
	assert(camera.global_position.is_equal_approx(center))
	camera.global_position = Vector2(-1500, 1750)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_HOME
	key.pressed = true
	board._unhandled_input(key)
	assert(camera.global_position.is_equal_approx(center))
	var before_zoom: float = board._zoom_goal
	board._unhandled_input(_press(ACTION_ZOOM_IN))
	assert(board._zoom_goal > before_zoom)
	board._unhandled_input(_press(ACTION_ZOOM_OUT))
	assert(is_equal_approx(board._zoom_goal, before_zoom))
	assert(not board.is_reference_preview_visible())
	board._unhandled_input(_press(ACTION_PREVIEW))
	assert(board.is_reference_preview_visible())
	board._unhandled_input(_press(ACTION_PREVIEW))
	assert(not board.is_reference_preview_visible())

	# An optional motion adapter interpolates only visual transforms.
	var piece: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	var emitted: Array[JigsawMotionContext] = []
	board.motion_requested.connect(func(motion: JigsawMotionContext) -> void:
		emitted.append(motion)
	)
	board.rotate_piece(0)
	assert(piece.display_transform != Transform2D.IDENTITY)
	var logical_transform: Transform2D = piece.transform
	var pre_toggle: JigsawPuzzleState = board.capture_state()
	board.set_reduced_motion(true)
	assert(board.is_reduced_motion())
	assert(piece.display_transform == Transform2D.IDENTITY)
	assert(piece.modulate == Color.WHITE)
	assert(piece.transform == logical_transform)
	assert(board.capture_state().piece_rotations == pre_toggle.piece_rotations)
	board.rotate_piece(0)
	assert(piece.display_transform == Transform2D.IDENTITY)
	assert(piece.modulate == Color.WHITE)
	assert(emitted.size() == 2, "Reduced motion cannot suppress semantic motion notifications.")
	board._animate_connection(piece)
	board._animate_failed_connection(piece)
	assert(piece.modulate == Color.WHITE, "Reduced motion must avoid transient tint feedback.")

	# Zoom and pan become immediate; user preferences remain on the Resource.
	var old_zoom: float = camera.zoom.x
	board._zoom_at_cursor(1.15)
	assert(camera.zoom.x > old_zoom)
	assert(is_equal_approx(camera.zoom.x, board._zoom_goal))
	board._offset_camera_target(Vector2(70, 0))
	assert(camera.global_position.is_equal_approx(board._camera_target_position))
	assert(not cfg.feedback.reduce_motion)
	assert(cfg.camera.smooth_zoom and cfg.camera.smooth_pan)

	board.set_reduced_motion(false)
	assert(not board.is_reduced_motion())
	board.rotate_piece(0)
	assert(piece.display_transform != Transform2D.IDENTITY)
	cfg.feedback.reduce_motion = true
	board.configure(cfg)
	assert(board.is_reduced_motion(), "Config Resource must reapply reduced motion after rebuild.")
	assert(board.get_piece_count() == 12)
	var current_piece: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	board.rotate_piece(0)
	assert(current_piece.display_transform == Transform2D.IDENTITY)
	for action: StringName in names:
		InputMap.erase_action(action)
	print("JigsawG InputMap and reduced-motion accessibility: PASS")
	host.queue_free()
	quit()
