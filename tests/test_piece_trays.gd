extends SceneTree
## godot --headless --path . --script res://tests/test_piece_trays.gd
## Typed locals: Godot warning-as-error projects must import this cleanly.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

var _tray_notifications: int = 0
var _failed_joins: int = 0


func _initialize() -> void:
	call_deferred("_verify")


func _config(mosaic: bool = false, enabled: bool = true) -> JigsawPuzzleConfig:
	var config: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	config.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC if mosaic else JigsawGameplaySettings.Mode.FREE
	config.trays.enabled = enabled
	config.trays.tray_names = PackedStringArray(["Corners", "Border", "Unsorted"])
	return config


func _verify() -> void:
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var config: JigsawPuzzleConfig = _config()
	var board: BoardScript = BoardScript.new()
	board.puzzle_config = config
	board.trays_changed.connect(func() -> void: _tray_notifications += 1)
	board.connection_failed.connect(func(_piece_id: int) -> void: _failed_joins += 1)
	host.add_child(board)
	assert(board.get_piece_count() == 9)
	assert(board.get_tray_count() == 3)
	assert(board.get_tray_name(0) == "Corners")
	assert(board.get_tray_name(-1).is_empty())
	assert(board.get_tray_rect(0).size.x > 0)
	assert(board.get_tray_rect(1).position.x > board.get_tray_rect(0).end.x)
	assert(board.get_tray_rect(0).position.y > board._piece_size.y * 3.0)
	assert(board.focus_tray(0))
	assert(camera.global_position.is_equal_approx(board.to_global(board.get_tray_rect(0).get_center())))
	assert(not board.put_group_in_tray(-1, 0))
	assert(not board.put_group_in_tray(0, 40))
	assert(board.get_piece_tray_index(0) == -1)

	# Make exactly one authoritative two-piece group.
	for id: int in range(2, 9):
		board.get_piece_node(id).position = Vector2(5000.0 + id * 800.0, 5000.0)
	assert(board._connect_group_from(0))
	assert(board.get_connected_group_count() == 8)
	var first: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	var second: JigsawPiece = board.get_piece_node(1) as JigsawPiece
	var relative: Vector2 = second.global_position - first.global_position
	assert(board.put_group_in_tray(0, 0))
	assert(board.get_tray_piece_ids(0) == PackedInt32Array([0, 1]))
	assert(board.get_piece_tray_index(1) == 0)
	assert(board.get_connected_group_count() == 8)
	assert((second.global_position - first.global_position).is_equal_approx(relative))
	var one: Rect2 = board._group_bounds_local(0)
	assert(board.get_tray_rect(0).encloses(one))
	assert(not board._connect_group_from(0), "Stored groups cannot snap to neighbors.")
	assert(board.get_connected_group_count() == 8)

	# API placement of a second group packs independently and never overlaps.
	assert(board.put_group_in_tray(2, 0))
	var two: Rect2 = board._group_bounds_local(2)
	assert(not one.intersects(two))
	assert(board.get_tray_piece_ids(0) == PackedInt32Array([0, 1, 2]))
	board.select_piece(0, true)
	board.select_piece(3, true)
	assert(board.put_selection_in_tray(1) == 2)
	assert(board.get_piece_tray_index(1) == 1)
	assert(board.get_piece_tray_index(3) == 1)
	assert(board.get_piece_tray_index(2) == 0)
	assert(board.get_connected_group_count() == 8)

	# Rotation changes only geometry/orientation and reflows stored groups.
	board.rotate_piece(0)
	assert(board.get_tray_rect(1).encloses(board._group_bounds_local(0)))
	assert(board.get_tray_piece_ids(1) == PackedInt32Array([0, 1, 3]))
	assert(board.get_connected_group_count() == 8)
	var snapshot: JigsawPuzzleState = board.capture_state()
	assert(snapshot != null and snapshot.tray_indices.size() == 9)
	assert(snapshot.tray_indices[0] == 1 and snapshot.tray_indices[1] == 1)
	assert(snapshot.tray_indices[2] == 0 and snapshot.tray_indices[4] == -1)
	var positions_before: PackedVector2Array = snapshot.piece_positions.duplicate()
	var rotations_before: PackedInt32Array = snapshot.piece_rotations.duplicate()

	# Retrieving changes only positions and tray membership, not rotations/joins.
	assert(board.retrieve_group_from_tray(0))
	assert(board.get_piece_tray_index(0) == -1)
	assert(board.get_piece_tray_index(1) == -1)
	assert(board.get_connected_group_count() == 8)
	assert(board._rotations[0] == rotations_before[0])

	# Load restores both original piece transforms and optional tray metadata.
	assert(board.restore_state(snapshot))
	assert(board.capture_state().piece_positions == positions_before)
	assert(board.capture_state().piece_rotations == rotations_before)
	assert(board.get_piece_tray_index(0) == 1)
	assert(board.get_piece_tray_index(2) == 0)

	# Corrupt membership must be rejected before any live puzzle mutation.
	var corrupt: JigsawPuzzleState = snapshot.duplicate(true) as JigsawPuzzleState
	corrupt.tray_indices[1] = 2  # Same connected group as piece 0.
	assert(not board.restore_state(corrupt))
	assert(board.capture_state().piece_positions == positions_before)
	assert(board.get_piece_tray_index(0) == 1)
	var truncated: JigsawPuzzleState = snapshot.duplicate(true) as JigsawPuzzleState
	truncated.tray_indices.resize(3)
	assert(not board.restore_state(truncated))
	assert(board.capture_state().piece_positions == positions_before)

	# A legacy schema-1 save without the optional field still restores.
	var legacy: JigsawPuzzleState = snapshot.duplicate(true) as JigsawPuzzleState
	legacy.tray_indices = PackedInt32Array()
	assert(board.restore_state(legacy))
	assert(board.get_piece_tray_index(0) == -1)
	assert(board.get_connected_group_count() == 8)
	assert(board.capture_state().tray_indices.is_empty())

	# Dropping with the same mouse/touch/controller release path stores pieces
	# without emitting a spurious failed-connection event.
	board.select_piece(2)
	board._begin_piece_drag(2, board.get_piece_node(2).global_position)
	board._activate_drag()
	board._pointer_offset = Vector2.ZERO
	var tray_world: Vector2 = board.to_global(board.get_tray_rect(2).get_center())
	board._finish_pointer_drag(Vector2(300, 200), tray_world)
	assert(board.get_dragged_piece_id() == -1)
	assert(board.get_piece_tray_index(2) == 2)
	assert(_failed_joins == 0)
	board.select_piece(2)
	board._begin_piece_drag(2, board.get_piece_node(2).global_position)
	board._activate_drag()
	board._pointer_offset = Vector2.ZERO
	board._finish_pointer_drag(Vector2(250, 150), board.to_global(Vector2(-1100, -800)))
	assert(board.get_piece_tray_index(2) == -1, "Dragging out must retrieve.")
	assert(board.get_connected_group_count() == 8)
	assert(_tray_notifications > 3)

	# Pausing, generating and missing trays block API mutations.
	board.set_interaction_enabled(false)
	assert(not board.put_group_in_tray(3, 0))
	assert(not board.focus_tray(0))
	board.set_interaction_enabled(true)
	var no_trays: JigsawPuzzleConfig = _config(false, false)
	board.configure(no_trays)
	assert(board.get_tray_count() == 0)
	assert(not board.put_group_in_tray(0, 0))
	assert(board.capture_state().tray_indices.is_empty())
	assert(not board.restore_state(snapshot), "Saved trays require compatible enabled tray settings.")

	var mosaic: JigsawPuzzleConfig = _config(true)
	board.configure(mosaic)
	board.select_piece(0, true)
	assert(board._place_selected_in_mosaic())
	assert(not board.put_group_in_tray(0, 0), "Locked Mosaic pieces cannot be stored.")
	assert(board.put_group_in_tray(1, 0))
	board.select_piece(1, true)
	assert(not board._place_selected_in_mosaic(), "Stored Mosaic pieces cannot auto-lock.")
	assert(board.get_piece_tray_index(1) == 0)

	var batching: JigsawPuzzleConfig = _config()
	batching.gameplay.generation_batch_size = 3
	board.configure(batching)
	assert(board.is_generating())
	assert(not board.put_group_in_tray(0, 0))
	assert(board.get_tray_piece_ids(0).is_empty())
	await board.puzzle_generated
	assert(board.get_tray_count() == 3)
	assert(board.get_tray_piece_ids(0).is_empty())
	print("JigsawG named tray group preservation and save compatibility: PASS")
	host.queue_free()
	quit()
