extends SceneTree
## Run: godot --headless --path . --script res://tests/test_group_integration.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
var joins: Array[int] = []

func _initialize() -> void:
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	board.puzzle_config = config
	board.pieces_connected.connect(func(size: int) -> void: joins.append(size))
	get_root().add_child(board)
	call_deferred("_verify", board)

func _verify(board: Node2D) -> void:
	assert(board.get_connected_group_count() == 9)
	for id in range(2, 9):
		board.get_piece_node(id).position = Vector2(10000 + id * 1000, 10000)
	assert(board._connect_group_from(0))
	assert(board.get_group_piece_ids(0) == PackedInt32Array([0, 1]))
	assert(board.get_connected_group_count() == 8)
	assert(joins == [2], "Legacy connection signal size changed.")
	board.select_piece(0)
	assert(board.get_selected_piece_ids() == PackedInt32Array([0, 1]))
	board.rotate_piece(0)
	var snapshot := board.capture_state()
	assert(snapshot.piece_rotations[0] == 1 and snapshot.piece_rotations[1] == 1)
	assert(snapshot.piece_group_ids[0] == 0 and snapshot.piece_group_ids[1] == 0)
	assert(board.restore_state(snapshot))
	assert(board.get_group_piece_ids(1) == PackedInt32Array([0, 1]))
	board.rebuild()
	assert(board.get_connected_group_count() == 9)
	assert(board.restore_state(snapshot))
	assert(board.get_group_piece_ids(1) == PackedInt32Array([0, 1]))
	assert(board.get_progress() > 0.0)
	print("JigsawG group model / Board integration: PASS")
	board.queue_free()
	quit()
