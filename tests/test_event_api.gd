extends SceneTree
## Run:
## godot --headless --path . --script res://tests/test_event_api.gd

func _initialize() -> void:
	var event := JigsawPuzzleEvent.new(JigsawPuzzleEvent.Type.GROUP_CONNECTED)
	event.piece_id = 4
	event.piece_ids = PackedInt32Array([4, 5])
	event.group_size = 2
	event.success = true
	event.reason = &"neighbor_snap"

	assert(event.get_type_name() == &"GROUP_CONNECTED")
	assert(event.group_size == 2)
	assert(event.success)

	var reaction := JigsawReaction.new()
	assert(reaction.accepts(event), "Empty event mask should accept every event.")

	reaction.event_mask = 1 << int(JigsawPuzzleEvent.Type.PUZZLE_COMPLETED)
	assert(not reaction.accepts(event), "Filtered reaction accepted the wrong event.")

	var completed := JigsawPuzzleEvent.new(JigsawPuzzleEvent.Type.PUZZLE_COMPLETED)
	assert(reaction.accepts(completed), "Filtered reaction rejected its configured event.")

	var config := JigsawPuzzleConfig.new()
	config.reactions = [reaction]
	assert(config.reactions.size() == 1)
	assert(config.reactions[0] == reaction)

	var spawn := JigsawSpawnSceneReaction.new()
	spawn.parent_mode = JigsawSpawnSceneReaction.ParentMode.PRIMARY_PIECE
	spawn.auto_free_after = 0.5
	assert(spawn.parent_mode == JigsawSpawnSceneReaction.ParentMode.PRIMARY_PIECE)
	assert(is_equal_approx(spawn.auto_free_after, 0.5))

	var camera := JigsawCameraSettings.new()
	assert(camera.smooth_pan)
	assert(camera.pan_smoothing > 0.0)
	assert(camera.edge_scroll_smoothing > 0.0)

	print("JigsawG event/reaction API smoke test: PASS")
	quit()
