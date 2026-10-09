extends SceneTree
## Runtime smoke test for the public semantic event contract.
## Run:
## godot --headless --path . --script res://tests/test_board_events.gd

const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

var observed: Array[int] = []

func _initialize() -> void:
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 2
	config.rows = 2
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	config.gameplay.enable_preview = true
	board.puzzle_config = config
	board.event_emitted.connect(_on_event)
	get_root().add_child(board)
	call_deferred("_verify_contract", board)

func _on_event(event: JigsawPuzzleEvent) -> void:
	observed.append(int(event.type))

func _verify_contract(board: Node2D) -> void:
	assert(observed.has(JigsawPuzzleEvent.Type.PUZZLE_STARTED), "Missing PUZZLE_STARTED.")

	board.rotate_piece(0)
	assert(observed.has(JigsawPuzzleEvent.Type.GROUP_ROTATED), "Missing GROUP_ROTATED.")

	board.set_preview_visible(true)
	assert(observed.has(JigsawPuzzleEvent.Type.PREVIEW_TOGGLED), "Missing PREVIEW_TOGGLED.")

	board.rebuild()
	assert(observed.has(JigsawPuzzleEvent.Type.PUZZLE_RESET), "Missing PUZZLE_RESET.")
	assert(observed.count(JigsawPuzzleEvent.Type.PUZZLE_STARTED) == 2, "Expected one started event per build.")

	assert(board.get_piece_count() == 4)
	assert(board.get_group_piece_ids(0).size() == 1)
	assert(board.get_piece_node(0) != null)
	assert(not board.is_completed())

	print("JigsawG board event contract smoke test: PASS")
	board.queue_free()
	quit()
