extends SceneTree
## The assembly guide must be correctly framed before the FIRST batch frame.
## godot --headless --path . --script res://tests/test_batch_camera_framing.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")


func _initialize() -> void:
	call_deferred("_run")


func _config() -> JigsawPuzzleConfig:
	var cfg := JigsawPuzzleConfig.new()
	cfg.columns = 6
	cfg.rows = 4
	cfg.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC
	cfg.gameplay.initial_scatter = true
	cfg.gameplay.generation_batch_size = 3
	cfg.camera.initial_focus = JigsawCameraSettings.InitialFocus.BOARD
	return cfg


func _run() -> void:
	var host := Node2D.new()
	get_root().add_child(host)
	var camera := Camera2D.new()
	camera.position = Vector2(4800, -3100)
	camera.zoom = Vector2.ONE * 0.25
	host.add_child(camera)
	camera.make_current()
	var cfg := _config()
	var board := BoardScript.new()
	board.puzzle_config = cfg
	host.add_child(board)
	assert(board.is_generating())
	assert(board.get_generation_progress() == Vector2i(0, 24))
	assert(board.get_piece_count() == 0, "No pieces should spawn before the first correctly framed guide frame.")
	assert(is_instance_valid(board._ghost_board) and board._ghost_board.visible)
	assert(board._camera == camera)
	var board_size := board._piece_size * Vector2(cfg.columns, cfg.rows)
	var bounds := board.get_viewport_rect().size
	var expected_zoom := clampf(
		minf(bounds.x / (board_size.x * 1.08), bounds.y / (board_size.y * 1.08)),
		cfg.camera.min_zoom, cfg.camera.max_zoom
	)
	var focus := board.to_global(board_size * 0.5)
	assert(camera.global_position.is_equal_approx(focus), "Camera must center the entire mosaic before generating.")
	assert(is_equal_approx(camera.zoom.x, expected_zoom), "Camera must fit both dimensions before the first yield.")
	assert(board._camera_target_ready)
	assert(is_equal_approx(board._zoom_goal, camera.zoom.x))
	assert(board._ghost_board.texture.get_size() == Vector2i(640, 480))
	assert(board_size.x * camera.zoom.x <= bounds.x + 0.5)
	assert(board_size.y * camera.zoom.y <= bounds.y + 0.5)

	# After the first process frame, the entire mosaic still renders by
	# itself: individual piece creation starts only on the following frame.
	await process_frame
	assert(board.is_generating())
	assert(board.get_piece_count() == 0)
	assert(is_instance_valid(board._ghost_board) and board._ghost_board.visible)
	await process_frame
	if board.get_piece_count() == 0:
		await process_frame
	assert(board.is_generating())
	assert(board.get_piece_count() > 0 and board.get_piece_count() < 24)
	assert(camera.global_position.is_equal_approx(focus))
	assert(is_equal_approx(camera.zoom.x, expected_zoom))
	await board.puzzle_generated
	assert(not board.is_generating())
	assert(board.get_piece_count() == 24)
	assert(camera.global_position.is_equal_approx(focus))
	assert(is_equal_approx(camera.zoom.x, expected_zoom))

	# Preserve the opting-out contract: custom camera framing is never overwritten.
	var unmanaged := _config()
	unmanaged.camera.auto_fit_camera = false
	camera.global_position = Vector2(-2400, 3600)
	camera.zoom = Vector2.ONE * 0.4
	var unmanaged_position := camera.global_position
	board.configure(unmanaged)
	assert(board.is_generating())
	assert(camera.global_position.is_equal_approx(unmanaged_position))
	assert(is_equal_approx(camera.zoom.x, 0.4))
	await board.puzzle_generated
	assert(camera.global_position.is_equal_approx(unmanaged_position))
	assert(is_equal_approx(camera.zoom.x, 0.4))

	# Free mode must still apply its requested ALL_PIECES framing after
	# the scatter step, even though the first frame focuses the full board.
	var scattered := _config()
	scattered.gameplay.game_mode = JigsawGameplaySettings.Mode.FREE
	scattered.camera.initial_focus = JigsawCameraSettings.InitialFocus.ALL_PIECES
	board.configure(scattered)
	var initial_scattered_focus := board.to_global(board._piece_size * Vector2(3, 2))
	assert(camera.global_position.is_equal_approx(initial_scattered_focus))
	assert(board.get_piece_count() == 0)
	await board.puzzle_generated
	assert(camera.global_position.is_equal_approx(board.to_global(board._fit_bounds.get_center())))
	assert(board.get_piece_count() == 24)

	# Cancel while still in the initial, empty pre-batch presentation frame.
	var cancelled := _config()
	board.configure(cancelled)
	assert(board.get_piece_count() == 0)
	var replacement := _config()
	replacement.columns = 4
	replacement.rows = 3
	board.configure(replacement)
	assert(board.get_generation_progress() == Vector2i(0, 12))
	assert(camera.global_position.is_equal_approx(board.to_global(board._piece_size * Vector2(2, 1.5))))
	await board.puzzle_generated
	await process_frame
	assert(board.get_piece_count() == 12)
	assert(board.get_generation_progress() == Vector2i(12, 12))
	print("JigsawG batch mosaic early camera framing: PASS")
	host.queue_free()
	quit()
