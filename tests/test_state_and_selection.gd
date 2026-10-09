extends SceneTree
## Run:
## godot --headless --path . --script res://tests/test_state_and_selection.gd

const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

func _initialize() -> void:
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 2
	config.rows = 2
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	config.gameplay.enable_multi_select = true
	get_root().add_child(board)
	board.configure(config)
	call_deferred("_verify", board, config)

func _verify(board: Node2D, config: JigsawPuzzleConfig) -> void:
	assert(board.get_piece_count() == 4)

	board.select_piece(0)
	board.select_piece(1, true)
	var selected = board.get_selected_piece_ids()
	assert(selected.size() == 2)
	assert(selected.has(0) and selected.has(1))

	board.rotate_piece(0)
	var snapshot = board.capture_state()
	assert(snapshot.get_piece_count() == 4)
	assert(snapshot.columns == 2 and snapshot.rows == 2)
	assert(snapshot.piece_rotations[0] == 1)

	var bad_rotation := snapshot.duplicate(true) as JigsawPuzzleState
	bad_rotation.piece_rotations[0] = 5
	assert(not board.restore_state(bad_rotation))
	assert(board.capture_state().piece_rotations[0] == 1)
	var bad_group := snapshot.duplicate(true) as JigsawPuzzleState
	bad_group.piece_group_ids[0] = 99
	assert(not board.restore_state(bad_group))
	assert(board.capture_state().piece_group_ids == snapshot.piece_group_ids)

	board.rebuild()
	assert(board.restore_state(snapshot))
	var restored = board.capture_state()
	assert(restored.piece_rotations[0] == 1)
	assert(restored.piece_positions == snapshot.piece_positions)
	assert(restored.piece_group_ids == snapshot.piece_group_ids)

	var resumed_config := config.duplicate(true) as JigsawPuzzleConfig
	resumed_config.resume_state = snapshot
	board.configure(resumed_config)
	assert(board.capture_state().piece_rotations[0] == 1)

	board.clear_selection()
	assert(board.get_selected_piece_ids().is_empty())

	var alternative := config.duplicate(true) as JigsawPuzzleConfig
	alternative.appearance.connector_family = JigsawAppearanceSettings.ConnectorFamily.ANGULAR
	alternative.resume_state = null
	board.configure(alternative)
	assert(board.get_piece_count() == 4)
	assert(not board.restore_state(snapshot), "Different geometry must reject incompatible saved state.")
	assert(board.capture_state().connector_family == JigsawAppearanceSettings.ConnectorFamily.ANGULAR)
	var angular_state := board.capture_state()
	var other_depth := alternative.duplicate(true) as JigsawPuzzleConfig
	other_depth.appearance.connector_depth = 0.31
	board.configure(other_depth)
	assert(not board.restore_state(angular_state), "Different connector depth must reject a saved state.")
	var depth_state := board.capture_state()
	var other_variation := other_depth.duplicate(true) as JigsawPuzzleConfig
	other_variation.appearance.connector_variation = 0.4
	board.configure(other_variation)
	assert(not board.restore_state(depth_state), "Different connector variation must reject a saved state.")
	var free_state := board.capture_state()
	var mosaic := other_variation.duplicate(true) as JigsawPuzzleConfig
	mosaic.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC
	board.configure(mosaic)
	assert(not board.restore_state(free_state), "Different game modes must reject a saved state.")

	var chaotic := JigsawPuzzleConfig.new()
	chaotic.columns = 3
	chaotic.rows = 3
	chaotic.gameplay.shuffle_mode = JigsawGameplaySettings.Shuffle.CHAOTIC
	chaotic.gameplay.initial_scatter = true
	chaotic.gameplay.generation_seed = 1234
	board.configure(chaotic)

	var positions := {}
	for i in range(board.get_piece_count()):
		positions[board.get_piece_node(i).position] = true
	assert(positions.size() == board.get_piece_count(), "Chaotic shuffle produced duplicate positions.")

	print("JigsawG state/multi-selection/chaotic-shuffle smoke test: PASS")
	board.queue_free()
	quit()
