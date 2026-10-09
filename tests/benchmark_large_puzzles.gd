extends SceneTree
## Explicit heavy benchmark (not run in the normal regression suite):
## godot --headless --path . --script res://tests/benchmark_large_puzzles.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
var _board: BoardScript
var _camera: Camera2D
var _source: Texture2D

func _initialize() -> void:
	call_deferred("_run")

func _config(target: int, chaotic: bool) -> JigsawPuzzleConfig:
	var result: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	result.puzzle_texture = _source
	result.grid_mode = JigsawPuzzleConfig.GridMode.AUTO
	result.target_piece_count = target
	result.gameplay.initial_scatter = true
	result.gameplay.generation_seed = 2026
	result.gameplay.generation_batch_size = 96
	if chaotic:
		result.gameplay.shuffle_mode = JigsawGameplaySettings.Shuffle.CHAOTIC
	return result

## Compare equal live-scene queries to the legacy O(N) polygon scan.
## No speed or latency threshold is assumed; measurements depend on hardware.
func _measure_hits(board: BoardScript, count: int) -> void:
	var probes: Array[Vector2] = []
	for sample in range(160):
		var id: int = floori(float(sample * count) / 160.0)
		var piece: JigsawPiece = board.get_piece_node(id) as JigsawPiece
		probes.append(piece.to_global(piece.bounds.get_center()))
	board._find_piece_at(probes[0]) # Lazy index build; exclude from warm query cost.
	var indexed_ids: PackedInt32Array = PackedInt32Array()
	var candidates: int = 0
	var start: int = Time.get_ticks_usec()
	for probe in probes:
		indexed_ids.append(board._find_piece_at(probe))
		candidates += board._hit_index.last_candidate_count()
	var indexed_us: int = Time.get_ticks_usec() - start
	start = Time.get_ticks_usec()
	for j in range(probes.size()):
		var expected: int = -1
		for id in range(count - 1, -1, -1):
			if board.get_piece_node(id).contains(probes[j]):
				expected = id
				break
		assert(expected == indexed_ids[j], "Spatial lookup changed exact picking result.")
	var linear_us: int = Time.get_ticks_usec() - start
	print("HITS pieces=%d probes=%d avg_candidates=%.2f indexed_us=%d linear_us=%d" % [
		count, probes.size(), float(candidates) / float(probes.size()), indexed_us, linear_us
	])


func _run() -> void:
	var scene: Node2D = Node2D.new()
	get_root().add_child(scene)
	_camera = Camera2D.new()
	scene.add_child(_camera)
	_camera.make_current()
	var image: Image = Image.create(4096, 3072, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.5, 0.7))
	_source = ImageTexture.create_from_image(image)
	_board = BoardScript.new()
	_board.puzzle_config = _config(200, false)
	var started: int = Time.get_ticks_msec()
	scene.add_child(_board)
	for target in [200, 500, 2000]:
		if target != 200:
			started = Time.get_ticks_msec()
			_board.configure(_config(target, target == 500))
		if _board.is_generating():
			await _board.puzzle_generated
		var elapsed: int = Time.get_ticks_msec() - started
		var grid: Vector2i = _board.get_effective_grid()
		var count: int = _board.get_piece_count()
		assert(not _board.is_generating())
		assert(count == grid.x * grid.y)
		assert(abs(count - target) <= maxi(12, roundi(float(target) * 0.08)))
		assert(_board.get_generation_progress() == Vector2i(count, count))
		assert(_board.get_connected_group_count() == count)
		assert(_board.capture_state().get_piece_count() == count)
		assert(_board.focus_board())
		var board_zoom: float = _camera.zoom.x
		assert(_board.fit_view())
		var all_zoom: float = _camera.zoom.x
		assert(all_zoom <= board_zoom + 0.0001)
		print("BOARD target=%d actual=%d grid=%dx%d build_ms=%d board_zoom=%.4f overview_zoom=%.4f" % [target, count, grid.x, grid.y, elapsed, board_zoom, all_zoom])
		_measure_hits(_board, count)
	var long_config: JigsawPuzzleConfig = _config(2000, true)
	long_config.gameplay.generation_batch_size = 16
	_board.configure(long_config)
	assert(_board.is_generating())
	_board.configure(_config(200, false))
	if _board.is_generating():
		await _board.puzzle_generated
	await process_frame
	assert(_board.get_piece_count() < 300)
	assert(_board.get_piece_count() == _board.get_effective_grid().x * _board.get_effective_grid().y)
	print("JigsawG generation and cancellation benchmark: PASS")
	scene.queue_free()
	quit()
