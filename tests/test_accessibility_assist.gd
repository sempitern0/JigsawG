extends SceneTree
## godot --headless --path . --script res://tests/test_accessibility_assist.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")


func _initialize() -> void:
	call_deferred("_run")


func _config(mosaic: bool, extra_snap: float, pointer_radius: float) -> JigsawPuzzleConfig:
	var cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	cfg.columns = 3
	cfg.rows = 3
	cfg.gameplay.initial_scatter = false
	cfg.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC if mosaic else JigsawGameplaySettings.Mode.FREE
	cfg.gameplay.allow_piece_rotation = true
	cfg.gameplay.snap_assist_extra_fraction = extra_snap
	cfg.gameplay.selection_assist_radius_px = pointer_radius
	return cfg


func _isolate_other_pieces(board: BoardScript) -> void:
	for i in range(2, board.get_piece_count()):
		board.get_piece_node(i).position = Vector2(6000.0 + i * 750.0, 8000.0)


func _run() -> void:
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var board: BoardScript = BoardScript.new()
	var normal: JigsawPuzzleConfig = _config(false, 0.0, 0.0)
	board.puzzle_config = normal
	host.add_child(board)
	_isolate_other_pieces(board)
	var first: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	first.position = Vector2(450, 350)
	var local_outside: Vector2 = Vector2(-6, board._piece_size.y * 0.15)
	var near_left: Vector2 = first.to_global(local_outside)
	assert(not first.contains(near_left))
	assert(board._find_piece_at(near_left) == -1, "Zero pointer assist must retain exact picking.")
	assert(is_equal_approx(board._effective_snap_tolerance_pixels(), board._piece_size.y * 0.24))

	# Opt in through the shared Resource and reapply; no puzzle state schema changes.
	var easy: JigsawPuzzleConfig = _config(false, 0.12, 8.0)
	board.configure(easy)
	_isolate_other_pieces(board)
	first = board.get_piece_node(0) as JigsawPiece
	first.position = Vector2(450, 350)
	near_left = first.to_global(local_outside)
	assert(board._find_piece_at(near_left) == 0)
	assert(board._find_piece_at(first.to_global(Vector2(-30, board._piece_size.y * 0.15))) == -1)
	board.set_accessibility_assists(0.0, 0.0)
	assert(board._find_piece_at(near_left) == -1, "Runtime opt-out must not require rebuilding.")
	assert(board.get_accessibility_assists() == Vector2.ZERO)
	assert(is_equal_approx(easy.gameplay.snap_assist_extra_fraction, 0.12), "Runtime override changed a shared Resource.")
	board.set_accessibility_assists(0.12, 8.0)
	assert(board._find_piece_at(near_left) == 0)
	assert(board.get_accessibility_assists().is_equal_approx(Vector2(0.12, 8.0)))

	# An actual hit on another piece MUST win over a fuzzy hit near this one.
	var second: JigsawPiece = board.get_piece_node(1) as JigsawPiece
	second.position = first.position + Vector2(-45, 0)
	assert(second.contains(near_left))
	assert(board._find_piece_at(near_left) == 1)
	second.position = first.position + Vector2(board._piece_size.x + 12.0, 0)
	var gap_point: Vector2 = first.to_global(Vector2(board._piece_size.x + 6.0, board._piece_size.y * 0.10))
	assert(not first.contains(gap_point) and not second.contains(gap_point))
	board.select_piece(0, true)
	assert(board._find_piece_at(gap_point) == 0, "A Ctrl-selected group should win an ambiguous fuzzy hit.")
	board.clear_selection()
	second.position = Vector2(10000, 9000)

	# Quarter-turns transform the enlarged hit area but not the actual shape.
	first.rotation = PI * 0.5
	var rotated_outside: Vector2 = first.to_global(local_outside)
	assert(not first.contains(rotated_outside))
	assert(board._find_piece_at(rotated_outside) == 0)
	first.rotation = 0.0

	# The allowance is measured in screen pixels, even when zoomed out.
	camera.zoom = Vector2.ONE * 0.5
	camera.force_update_scroll()
	var zoomed_outside: Vector2 = first.to_global(Vector2(-12, board._piece_size.y * 0.15))
	assert(not first.contains(zoomed_outside))
	assert(board._find_piece_at(zoomed_outside) == 0)
	camera.zoom = Vector2.ONE
	camera.force_update_scroll()

	# Visual-only animation also changes the clickable contour.
	first.display_transform = Transform2D(0.0, Vector2(90, 0))
	var animated_point: Vector2 = first.to_global(first.display_transform * local_outside)
	assert(board._find_piece_at(animated_point) == 0)
	first.display_transform = Transform2D.IDENTITY

	# Same near-miss distance cannot snap by default but does with assistance.
	board.configure(normal)
	_isolate_other_pieces(board)
	var neighbor: JigsawPiece = board.get_piece_node(1) as JigsawPiece
	var offset: float = board._piece_size.y * 0.30
	neighbor.position += Vector2(offset, 0)
	assert(not board._connect_group_from(0))
	assert(board.get_connected_group_count() == 9)
	board.configure(easy)
	_isolate_other_pieces(board)
	neighbor = board.get_piece_node(1) as JigsawPiece
	neighbor.position += Vector2(offset, 0)
	assert(board._connect_group_from(0))
	assert(board.get_group_piece_ids(0) == PackedInt32Array([0, 1]))
	assert(board.get_connected_group_count() == 8)
	var saved: JigsawPuzzleState = board.capture_state()
	assert(saved != null and board.restore_state(saved))
	assert(board.get_group_piece_ids(0) == PackedInt32Array([0, 1]))
	assert(is_equal_approx(easy.gameplay.snap_assist_extra_fraction, 0.12))

	# Mosaic uses exactly the same configured tolerance and still needs 0°.
	var mosaic_hard: JigsawPuzzleConfig = _config(true, 0.0, 0.0)
	board.configure(mosaic_hard)
	board.get_piece_node(0).position += Vector2(offset, 0)
	board.select_piece(0, true)
	assert(not board._place_selected_in_mosaic())
	assert(board.get_locked_piece_count() == 0)
	var mosaic_easy: JigsawPuzzleConfig = _config(true, 0.12, 8.0)
	board.configure(mosaic_easy)
	board.get_piece_node(0).position += Vector2(offset, 0)
	board.rotate_piece(0)
	board.select_piece(0, true)
	assert(not board._place_selected_in_mosaic(), "Assist must never bypass orientation.")
	assert(board.get_locked_piece_count() == 0)
	board.configure(mosaic_easy)
	board.get_piece_node(0).position += Vector2(offset, 0)
	board.select_piece(0, true)
	assert(board._place_selected_in_mosaic())
	assert(board.get_locked_piece_count() == 1)
	assert(board.get_piece_node(0).position.is_equal_approx(board.get_piece_node(0).home))
	print("JigsawG optional accessibility assists: PASS")
	host.queue_free()
	quit()
