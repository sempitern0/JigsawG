extends SceneTree
## godot --headless --path . --script res://tests/test_hit_index_board.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

func _initialize() -> void:
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var config: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	var board: BoardScript = BoardScript.new()
	board.puzzle_config = config
	host.add_child(board)
	call_deferred("_verify", host, board)

func _brute_hit(board: BoardScript, world: Vector2) -> int:
	var ids: PackedInt32Array = board.get_selected_piece_ids()
	if board._multi_selection_mode:
		for index in range(board.get_piece_count() - 1, -1, -1):
			if ids.has(index) and board.get_piece_node(index).contains(world):
				return index
	for index in range(board.get_piece_count() - 1, -1, -1):
		if board.get_piece_node(index).contains(world):
			return index
	return -1

func _check_hit(board: BoardScript, point: Vector2) -> int:
	var expected: int = _brute_hit(board, point)
	var actual: int = board._find_piece_at(point)
	assert(actual == expected, "Spatial index changed hit priority or skipped a piece.")
	return actual

func _verify(host: Node2D, board: BoardScript) -> void:
	assert(board.get_piece_count() == 9)
	for i in range(2, board.get_piece_count()):
		board.get_piece_node(i).position = Vector2(10000 + i * 650, -10000)
	var first: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	var second: JigsawPiece = board.get_piece_node(1) as JigsawPiece
	first.position = Vector2(110, 200)
	second.position = first.position
	var point: Vector2 = first.to_global(first.bounds.get_center())
	assert(first.contains(point) and second.contains(point))
	assert(_check_hit(board, point) == 1, "Latest drawn overlapping piece should win.")
	assert(not board._hit_index.is_dirty(), "First query should build the index.")
	assert(board._hit_index.last_candidate_count() <= 2)

	board.select_piece(0, true)
	assert(_check_hit(board, point) == 0, "Highlighted group should win the overlap.")
	first.position = Vector2(-3200, 2200)
	assert(board._hit_index.is_dirty(), "Direct Node2D movement must invalidate hit caching.")
	var moved_point: Vector2 = first.to_global(first.bounds.get_center())
	assert(_check_hit(board, moved_point) == 0)
	board.clear_selection()
	assert(_check_hit(board, point) == 1)

	# Quarter turns and drawing-only motion both change the projected hit shape.
	first.rotation = PI * 0.5
	assert(board._hit_index.is_dirty())
	var rotated_point: Vector2 = first.to_global(first.bounds.get_center())
	assert(_check_hit(board, rotated_point) == 0)
	first.display_transform = Transform2D(0.0, Vector2(1500, 650))
	assert(board._hit_index.is_dirty())
	var displayed_point: Vector2 = first.to_global(first.display_transform * first.bounds.get_center())
	assert(_check_hit(board, displayed_point) == 0)
	assert(_check_hit(board, rotated_point) == -1, "Previous visible location must not remain selectable.")
	first.display_transform = Transform2D.IDENTITY
	assert(_check_hit(board, rotated_point) == 0)

	# Moving the entire Board should not require invalidating board-local bins.
	host.position = Vector2(450, -300)
	var moved_host_point: Vector2 = first.to_global(first.bounds.get_center())
	assert(_check_hit(board, moved_host_point) == 0)

	# Save/restore and rebuild must invalidate/refill index without stale piece IDs.
	var saved: JigsawPuzzleState = board.capture_state()
	assert(saved != null)
	first.position = Vector2(-7000, 5500)
	assert(_check_hit(board, first.to_global(first.bounds.get_center())) == 0)
	assert(board.restore_state(saved))
	assert(_check_hit(board, first.to_global(first.bounds.get_center())) == 0)
	board.rebuild()
	assert(board._hit_index.is_dirty())
	var reset_point: Vector2 = board.get_piece_node(0).to_global(Vector2(100, 80))
	assert(_check_hit(board, reset_point) == 0)
	assert(board._hit_index.last_candidate_count() < board.get_piece_count())
	print("JigsawG spatial Board hit testing: PASS")
	host.queue_free()
	quit()
