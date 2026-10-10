extends SceneTree
## godot --headless --path . --script res://tests/test_progressive_hints.gd
## All local variables explicitly typed to avoid Variant infer errors.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
const HINT_ACTION: StringName = &"jigsawg_test_advance_hint"

var _notifications: Array[Vector2i] = []


func _initialize() -> void:
	call_deferred("_verify")


func _config(mosaic: bool = false, allow_precise: bool = true) -> JigsawPuzzleConfig:
	var cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	cfg.columns = 4
	cfg.rows = 3
	cfg.gameplay.initial_scatter = false
	cfg.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC if mosaic else JigsawGameplaySettings.Mode.FREE
	cfg.hints.enabled = true
	cfg.hints.maximum_level = JigsawHintSettings.MaximumLevel.PRECISE if allow_precise else JigsawHintSettings.MaximumLevel.CANDIDATE
	cfg.hints.advance_key = KEY_H
	cfg.hints.advance_action = HINT_ACTION
	cfg.hints.focus_on_request = false
	return cfg


func _action() -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = HINT_ACTION
	event.pressed = true
	return event


func _key() -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_H
	event.pressed = true
	return event


func _verify() -> void:
	assert(not InputMap.has_action(HINT_ACTION))
	InputMap.add_action(HINT_ACTION)
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var cfg: JigsawPuzzleConfig = _config()
	var board: BoardScript = BoardScript.new()
	board.puzzle_config = cfg
	board.hint_changed.connect(func(level: int, id: int) -> void:
		_notifications.append(Vector2i(level, id))
	)
	host.add_child(board)
	var baseline: JigsawPuzzleState = board.capture_state()
	assert(baseline != null)
	assert(board.get_hint_info()["level"] == BoardScript.HintLevel.OFF)
	assert(not board.request_hint(0))
	assert(not board.request_hint(4))
	assert(not board.request_hint(BoardScript.HintLevel.PRECISE, -2))
	board.select_piece(3, true)
	var chosen: PackedInt32Array = board.get_selected_piece_ids()

	# Tier 1 reveals ONLY the broad source-image area.
	assert(board.request_hint(BoardScript.HintLevel.REGION))
	var first: Dictionary = board.get_hint_info()
	assert(first["piece_id"] == 3)
	assert(first["region"].size.x > board._piece_size.x)
	assert(first["candidate_bounds"] == Rect2())
	assert(first["target_slot"] == Rect2())
	assert(first["group_piece_ids"].is_empty())
	assert(board._hint_overlay.hint_level == 1)
	assert(board._hint_overlay.candidate_bounds == Rect2())

	# Tier 2 adds a real movable candidate group without revealing its slot.
	assert(board.advance_hint() == BoardScript.HintLevel.CANDIDATE)
	var second: Dictionary = board.get_hint_info()
	assert(second["piece_id"] == first["piece_id"])
	assert(second["region"] == first["region"])
	assert(second["group_piece_ids"] == PackedInt32Array([3]))
	assert(second["candidate_bounds"] == board._group_bounds_local(3))
	assert(second["target_slot"] == Rect2())
	assert(board._hint_overlay.hint_level == 2)

	# Drawn boxes track group movement without altering gameplay.
	var piece: JigsawPiece = board.get_piece_node(3) as JigsawPiece
	piece.position += Vector2(90.0, -70.0)
	board._process(0.016)
	assert(board._hint_overlay.candidate_bounds == board._group_bounds_local(3))
	var before_hint: JigsawPuzzleState = board.capture_state()

	# Tier 3 requires a fresh request, shows cell (but no rotation or joining).
	assert(board.advance_hint() == BoardScript.HintLevel.PRECISE)
	var third: Dictionary = board.get_hint_info()
	assert(third["target_slot"] == Rect2(piece.home, board._piece_size))
	assert(board._hint_overlay.exact_target == third["target_slot"])
	assert(board.focus_hint())
	assert(camera.global_position.is_equal_approx(board.to_global(third["target_slot"].get_center())))
	assert(board.get_selected_piece_ids() == chosen)
	var after_hint: JigsawPuzzleState = board.capture_state()
	assert(after_hint.piece_positions == before_hint.piece_positions)
	assert(after_hint.piece_rotations == before_hint.piece_rotations)
	assert(after_hint.piece_group_ids == before_hint.piece_group_ids)
	assert(after_hint.locked_piece_ids == before_hint.locked_piece_ids)
	assert(after_hint.tray_indices == before_hint.tray_indices)
	assert(not board.is_completed())

	# Wrap to OFF and the next cycle to the next deterministic root.
	assert(board.advance_hint() == BoardScript.HintLevel.OFF)
	assert(board._hint_overlay.hint_level == 0)
	board.clear_selection()
	board._unhandled_input(_key())
	assert(board.get_hint_info()["level"] == BoardScript.HintLevel.REGION)
	assert(board.get_hint_info()["piece_id"] != 3)
	board._unhandled_input(_action())
	assert(board.get_hint_info()["level"] == BoardScript.HintLevel.CANDIDATE)
	assert(_notifications.size() >= 6)

	# Invalid contexts do not change an existing hint.
	board._drag_root = 0
	assert(not board.request_hint(BoardScript.HintLevel.REGION, 0))
	board._drag_root = -1
	board.set_preview_visible(true)
	assert(not board.request_hint(BoardScript.HintLevel.REGION, 0))
	board.set_preview_visible(false)
	board.set_interaction_enabled(false)
	assert(board.get_hint_info()["level"] == 0)
	assert(not board.request_hint(BoardScript.HintLevel.REGION, 0))
	board.set_interaction_enabled(true)

	# Maximum tier can be capped to area+candidate; precise is opt-in.
	var limited: JigsawPuzzleConfig = _config(false, false)
	board.configure(limited)
	assert(board.request_hint(BoardScript.HintLevel.REGION, 2))
	assert(not board.request_hint(BoardScript.HintLevel.PRECISE, 2))
	assert(board.advance_hint() == 2)
	assert(board.advance_hint() == 0)

	# Compatible saves do not carry hint state; restore clears it.
	assert(board.request_hint(BoardScript.HintLevel.REGION, 2))
	assert(board.restore_state(board.capture_state()))
	assert(board.get_hint_info()["level"] == 0)

	# Locked Mosaic pieces are never hinted; a newly locked hint clears.
	var mosaic: JigsawPuzzleConfig = _config(true)
	board.configure(mosaic)
	assert(board.request_hint(BoardScript.HintLevel.CANDIDATE, 0))
	board.select_piece(0, true)
	assert(board._place_selected_in_mosaic())
	board._process(0.016)
	assert(board.get_hint_info()["level"] == 0)
	assert(not board.request_hint(BoardScript.HintLevel.REGION, 0))
	assert(board.request_hint(BoardScript.HintLevel.REGION))
	assert(board.get_hint_info()["piece_id"] != 0)

	# Generation batches must never leak partial candidate / image regions.
	var pending: JigsawPuzzleConfig = _config()
	pending.gameplay.generation_batch_size = 3
	board.configure(pending)
	assert(board.is_generating())
	assert(not board.request_hint(BoardScript.HintLevel.REGION))
	assert(board.get_hint_info()["level"] == 0)
	await board.puzzle_generated
	assert(board.request_hint(BoardScript.HintLevel.REGION))
	assert(board.get_hint_info()["level"] == 1)

	# All source presets leave hints disabled unless the host opted in.
	var default_cfg: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	board.configure(default_cfg)
	assert(not board.request_hint(BoardScript.HintLevel.REGION))
	assert(board.get_hint_info()["level"] == 0)

	InputMap.erase_action(HINT_ACTION)
	print("JigsawG optional 3-tier hints and save invariants: PASS")
	host.queue_free()
	quit()
