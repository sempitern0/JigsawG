extends SceneTree
## Run: godot --headless --path . --script res://tests/test_motion_adapter.gd
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

var movements: Array[JigsawMotionContext] = []
var events: Array[JigsawPuzzleEvent] = []

func _initialize() -> void:
	var host := Node2D.new()
	get_root().add_child(host)
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	var motion_adapter := JigsawMotionAdapter.new()
	motion_adapter.rotation_duration = 0.18
	motion_adapter.arrangement_duration = 0.22
	config.feedback.motion_adapter = motion_adapter
	board.puzzle_config = config
	board.motion_requested.connect(func(motion: JigsawMotionContext) -> void: movements.append(motion))
	board.event_emitted.connect(func(event: JigsawPuzzleEvent) -> void: events.append(event))
	host.add_child(board)
	call_deferred("_verify", board, host)

func _verify(board: Node2D, host: Node2D) -> void:
	var piece := board.get_piece_node(0) as JigsawPiece
	var original_position := piece.position
	var before := piece.transform
	board.rotate_piece(0)
	assert(movements.size() == 1, "Expected rotation motion.")
	var rotation: JigsawMotionContext = movements[0]
	assert(rotation.kind == JigsawMotionContext.Kind.ROTATION)
	assert(rotation.piece_ids == PackedInt32Array([0]))
	assert(rotation.before_transforms[0] == before)
	assert(rotation.after_transforms[0] == piece.transform)
	assert(piece.rotation != 0.0, "Logical rotation must commit immediately.")
	assert(piece.display_transform != Transform2D.IDENTITY, "Rotation should animate visually.")
	assert(piece.position != original_position or piece.rotation != 0.0)

	board.get_piece_node(0).position = Vector2(-4000, -3000)
	board.get_piece_node(8).position = Vector2(5000, 6000)
	board.select_piece(0, true)
	board.select_piece(8, true)
	var before_arrangement := board.get_piece_node(8).position
	board._begin_piece_drag(0, board.get_piece_node(0).global_position)
	board._activate_drag()
	assert(movements.size() == 2)
	var arrangement: JigsawMotionContext = movements[1]
	assert(arrangement.kind == JigsawMotionContext.Kind.ARRANGEMENT)
	assert(arrangement.piece_ids.has(0) and arrangement.piece_ids.has(8))
	assert(before_arrangement != board.get_piece_node(8).position)
	assert(board.get_piece_node(8).display_transform != Transform2D.IDENTITY)
	var notified := false
	for event in events:
		if event.type == JigsawPuzzleEvent.Type.SELECTION_ARRANGED:
			notified = true
			assert(event.metadata["selected_piece_ids"].size() == 2)
	assert(notified, "Selection-arranged event is missing.")
	board._cancel_drag()
	var snapshot := board.capture_state()
	assert(snapshot.piece_rotations[0] == 1)
	assert(snapshot.piece_positions[8] == board.get_piece_node(8).position)

	# Disabled adapter makes transitions instantaneous without changing gameplay.
	var no_motion := JigsawPuzzleConfig.new()
	no_motion.gameplay.initial_scatter = false
	no_motion.gameplay.allow_piece_rotation = true
	board.configure(no_motion)
	movements.clear()
	var bare_piece := board.get_piece_node(0) as JigsawPiece
	board.rotate_piece(0)
	assert(movements.size() == 1)
	assert(bare_piece.display_transform == Transform2D.IDENTITY, "Null motion adapter must retain legacy look.")
	print("JigsawG motion adapter tests: PASS")
	host.queue_free()
	quit()
