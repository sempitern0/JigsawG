extends SceneTree
## Lightweight async/cancel regression, no large image required.
## godot --headless --path . --script res://tests/test_generation_batching.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

var progress: Array[Vector2i] = []
var completed: Array[int] = []


func _config(columns: int, rows: int, batch_size: int) -> JigsawPuzzleConfig:
	var cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	cfg.columns = columns
	cfg.rows = rows
	cfg.gameplay.initial_scatter = false
	cfg.gameplay.allow_piece_rotation = true
	cfg.gameplay.generation_batch_size = batch_size
	return cfg


func _initialize() -> void:
	var board: Node2D = BoardScript.new()
	board.puzzle_config = _config(6, 6, 7)
	board.generation_progress_changed.connect(func(done: int, total: int) -> void:
		progress.append(Vector2i(done, total))
	)
	board.puzzle_generated.connect(func(count: int) -> void:
		completed.append(count)
	)
	get_root().add_child(board)
	assert(board.is_generating())
	# The mosaic has an entire presentation frame before the first piece batch.
	assert(board.get_generation_progress() == Vector2i(0, 36))
	assert(board.get_piece_count() == 0)
	call_deferred("_verify_async", board)


func _verify_async(board: Node2D) -> void:
	await board.puzzle_generated
	assert(not board.is_generating())
	assert(board.get_piece_count() == 36)
	assert(board.get_generation_progress() == Vector2i(36, 36))
	assert(progress.size() > 2 and progress[0] == Vector2i(0, 36))
	assert(progress.back() == Vector2i(36, 36))
	var last: int = -1
	for sample in progress:
		assert(sample.y == 36 and sample.x >= last and sample.x <= 36)
		last = sample.x

	# Two consecutive reconfigurations: the first coroutine must terminate.
	board.configure(_config(10, 10, 1))
	assert(board.is_generating())
	board.configure(_config(5, 5, 7))
	assert(board.is_generating())
	await board.puzzle_generated
	await process_frame
	assert(completed == [36, 25], "Cancelled job must not emit PUZZLE_GENERATED.")
	assert(board.get_piece_count() == 25)
	assert(not board.is_generating())
	assert(board.get_connected_group_count() == 25)
	assert(board.capture_state().get_piece_count() == 25)

	# A zero batch remains synchronous for legacy consumers.
	board.configure(_config(4, 4, 0))
	assert(not board.is_generating())
	assert(board.get_piece_count() == 16)
	assert(completed == [36, 25, 16])
	print("JigsawG batched generation / cancellation: PASS")
	board.queue_free()
	quit()
