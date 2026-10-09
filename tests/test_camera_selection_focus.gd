extends SceneTree
## godot --headless --path . --script res://tests/test_camera_selection_focus.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

func _initialize() -> void:
	var host := Node2D.new()
	get_root().add_child(host)
	var camera := Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var cfg := JigsawPuzzleConfig.new()
	cfg.columns = 4
	cfg.rows = 3
	cfg.gameplay.initial_scatter = false
	cfg.camera.selection_focus_max_zoom = 1.5
	cfg.camera.selection_focus_padding = 0.75
	cfg.camera.focus_selection_key = KEY_F
	var board := BoardScript.new()
	board.puzzle_config = cfg
	host.add_child(board)
	call_deferred("_verify", host, camera, board, cfg)

func _verify(host: Node2D, camera: Camera2D, board: Node2D, cfg: JigsawPuzzleConfig) -> void:
	assert(board.get_piece_count() == 12)
	assert(not board.focus_selection(), "Without a selection, the view must not jump.")
	var before := camera.global_position
	board.select_piece(0)
	assert(not board.get_piece_node(0).selected, "Plain selection is not highlighted.")
	board.get_piece_node(0).position = Vector2(-2300, -700)
	board.get_piece_node(11).position = Vector2(3700, 1900)
	assert(board.focus_selection())
	assert(camera.zoom.x <= 1.5 + 0.0001)
	assert(camera.global_position.distance_to(before) > 10.0)
	assert(camera.global_position.is_equal_approx(board.to_global(board._group_bounds_local(0).get_center())))
	assert(cfg.camera.selection_focus_max_zoom == 1.5)
	board.select_piece(11, true)
	assert(board.focus_selection(), "Two disconnected groups must fit together.")
	var both := board._group_bounds_local(0).merge(board._group_bounds_local(11))
	assert(camera.global_position.is_equal_approx(board.to_global(both.get_center())))
	assert(camera.zoom.x <= 1.5 + 0.0001)
	assert(board.get_selected_piece_ids() == PackedInt32Array([0, 11]))
	board.clear_selection()
	assert(not board.focus_selection())
	board.select_piece(11, true)
	board._begin_piece_drag(11, board.get_piece_node(11).global_position)
	assert(not board.focus_selection(), "Focus must not interrupt dragging.")
	board._cancel_drag()
	assert(board.focus_selection())
	var snapshot := board.capture_state()
	board.clear_selection()
	assert(board.restore_state(snapshot))
	assert(not board.focus_selection(), "Restore resets the prior selection.")
	assert(board.get_piece_node(0).position == Vector2(-2300, -700))
	print("JigsawG selection camera framing: PASS")
	host.queue_free()
	quit()
