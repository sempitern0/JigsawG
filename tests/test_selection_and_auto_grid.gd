extends SceneTree
## Run: godot --headless --path . --script res://tests/test_selection_and_auto_grid.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
const GridResolver = preload("res://addons/jigsawg/src/jigsaw_grid_resolver.gd")
const SelectionLayout = preload("res://addons/jigsawg/src/jigsaw_selection_layout.gd")

func _initialize() -> void:
	var landscape := GridResolver.resolve(100, Vector2i(1920, 1080))
	assert(landscape.x >= landscape.y)
	assert(abs(landscape.x * landscape.y - 100) <= 12)
	var tile_aspect := (1920.0 / float(landscape.x)) / (1080.0 / float(landscape.y))
	assert(tile_aspect > 0.7 and tile_aspect < 1.4)
	var portrait := GridResolver.resolve(49, Vector2i(720, 1280))
	assert(portrait.x < portrait.y)
	assert(GridResolver.resolve(7, Vector2i(800, 600)).x >= 2)
	assert(GridResolver.resolve(40, Vector2i(20, 20)) == Vector2i.ZERO)

	var rects: Array[Rect2] = [
		Rect2(Vector2(0, 0), Vector2(130, 90)),
		Rect2(Vector2(8000, 9000), Vector2(70, 90)),
		Rect2(Vector2(-6000, -3000), Vector2(140, 45)),
		Rect2(Vector2(400, -500), Vector2(80, 100))
	]
	var offsets := SelectionLayout.pack(rects, 25.0)
	assert(offsets[0] == Vector2.ZERO)
	for i in range(rects.size()):
		var moved_i := Rect2(rects[i].position + offsets[i], rects[i].size)
		for k in range(i):
			var moved_k := Rect2(rects[k].position + offsets[k], rects[k].size)
			assert(not moved_i.intersects(moved_k), "Compacted selected groups overlap.")

	var host := Node2D.new()
	get_root().add_child(host)
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	board.puzzle_config = config
	host.add_child(board)
	call_deferred("_verify_board", board, host)

func _verify_board(board: Node2D, host: Node2D) -> void:
	assert(board.get_effective_grid() == Vector2i(3, 3))
	board.select_piece(0)
	assert(not board.get_piece_node(0).selected, "Single click cannot leave a selected outline.")
	# First Ctrl+click after an invisible normal selection must visibly select.
	board._toggle_group_selection(0)
	assert(board.get_piece_node(0).selected, "Ctrl selection must highlight on first click.")
	assert(board.get_selected_piece_ids() == PackedInt32Array([0]))
	board._toggle_group_selection(0)
	assert(not board.get_piece_node(0).selected, "Ctrl toggling off must remove highlight.")
	assert(board.get_selected_piece_ids().is_empty())
	board._toggle_group_selection(0)
	board._toggle_group_selection(1)
	assert(board.get_piece_node(0).selected and board.get_piece_node(1).selected)
	board.clear_selection()
	assert(not board.get_piece_node(0).selected and not board.get_piece_node(1).selected)
	board.select_piece(0)
	board._begin_piece_drag(0, board.get_piece_node(0).global_position)
	assert(not board.get_piece_node(0).selected, "A click without pointer travel must not highlight.")
	board._activate_drag()
	assert(board.get_piece_node(0).selected, "Dragging a piece must highlight it.")
	board._cancel_drag()
	assert(not board.get_piece_node(0).selected, "Highlight must disappear after drag.")

	board.get_piece_node(0).position = Vector2(-4000, -3000)
	board.get_piece_node(8).position = Vector2(5000, 6000)
	board.clear_selection()
	board.select_piece(0, true)
	board.select_piece(8, true)
	assert(board.get_piece_node(0).selected and board.get_piece_node(8).selected)
	board._begin_piece_drag(0, board.get_piece_node(0).global_position)
	board._activate_drag()
	assert(board.get_piece_node(0).position == Vector2(-4000, -3000))
	var a: Rect2 = board._group_bounds_local(0)
	var b: Rect2 = board._group_bounds_local(8)
	assert(not a.intersects(b), "Selected pieces overlap after compaction.")
	assert(a.get_center().distance_to(b.get_center()) < 1000.0, "Distant groups were not compacted.")
	board._cancel_drag()
	board.clear_selection()

	# A genuine connected pair stays rigid when packed with another distant group.
	board.rebuild()
	for i in range(2, board.get_piece_count()):
		board.get_piece_node(i).position = Vector2(9000.0 + float(i) * 900.0, 10000.0 + float(i) * 900.0)
	assert(board._connect_group_from(0), "Expected two neighboring pieces to join.")
	assert(board.get_group_piece_ids(0).size() == 2)
	board.get_piece_node(8).position = Vector2(-7000, 5000)
	var relative_before: Vector2 = board.get_piece_node(1).position - board.get_piece_node(0).position
	board.select_piece(0, true)
	board.select_piece(8, true)
	board._begin_piece_drag(0, board.get_piece_node(0).global_position)
	board._activate_drag()
	var relative_after: Vector2 = board.get_piece_node(1).position - board.get_piece_node(0).position
	assert(relative_before.is_equal_approx(relative_after), "Existing connected group was distorted.")
	assert(not board._group_bounds_local(0).intersects(board._group_bounds_local(8)))
	board._cancel_drag()
	board.clear_selection()

	var auto := JigsawPuzzleConfig.new()
	auto.grid_mode = JigsawPuzzleConfig.GridMode.AUTO
	auto.target_piece_count = 35
	auto.columns = 2
	auto.rows = 2
	auto.gameplay.initial_scatter = false
	board.configure(auto)
	var grid: Vector2i = board.get_effective_grid()
	assert(grid.x >= 2 and grid.y >= 2)
	assert(board.get_piece_count() == grid.x * grid.y)
	assert(grid != Vector2i(2, 2), "Auto grid must override the manual grid.")
	assert(auto.columns == 2 and auto.rows == 2, "Board must not mutate the shared Resource.")
	print("JigsawG selection and auto-grid regression: PASS")
	host.queue_free()
	quit()
