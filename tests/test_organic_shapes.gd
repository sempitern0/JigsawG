extends SceneTree
## godot --headless --path . --script res://tests/test_organic_shapes.gd
const Geometry = preload("res://addons/jigsawg/src/jigsaw_geometry.gd")
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

func _initialize() -> void:
	# Tabs/sockets reverse one shared mathematical seam, not approximate masks.
	var distinct: Dictionary = {}
	for token in [3, 14, 212, 4096 + 7, 4096 + 341, 3 * 4096 + 1777]:
		var tab := Geometry.edge_points(Vector2.ZERO, Vector2(100, 0), Vector2.DOWN,
			Vector2i(1, token), 26.0, 12, 5, 1.0)
		var socket := Geometry.edge_points(Vector2.ZERO, Vector2(100, 0), Vector2.DOWN,
			Vector2i(-1, token), 26.0, 12, 5, 1.0)
		assert(tab.size() == socket.size())
		assert(tab.size() >= 90)
		for k in range(tab.size()):
			assert(is_equal_approx(tab[k].x, socket[k].x))
			assert(is_equal_approx(tab[k].y, -socket[k].y))
		assert(tab[0].is_equal_approx(Vector2.ZERO))
		assert(tab[tab.size() - 1].is_equal_approx(Vector2(100, 0)))
		distinct[str(token)] = tab[tab.size() / 2]
	var unique_contours: Dictionary = {}
	for token in [3, 14, 212, 4096 + 7, 4096 + 341, 3 * 4096 + 1777]:
		var profile := Geometry.edge_points(Vector2.ZERO, Vector2(100, 0), Vector2.DOWN,
			Vector2i(1, token), 26.0, 12, 5, 1.0)
		var signature := str(profile[profile.size() / 3], profile[profile.size() * 2 / 3])
		unique_contours[signature] = true
	assert(unique_contours.size() >= 5, "Organic seams must vary per shared token.")

	# Exercise a rare near-shoulder contour that could fold back on itself.
	# Contour segments may touch their immediate neighbors only.
	var pathological := Geometry.edge_points(Vector2.ZERO, Vector2(100, 0), Vector2.DOWN,
		Vector2i(1, 12974), 26.0, 12, 5, 1.0)
	for i in range(pathological.size() - 1):
		for j in range(i + 2, pathological.size() - 1):
			var intersection = Geometry2D.segment_intersects_segment(
				pathological[i], pathological[i + 1],
				pathological[j], pathological[j + 1]
			)
			assert(intersection == null, "Organic contour crossed itself.")

	var older := JigsawAppearanceSettings.new()
	assert(older.connector_family == JigsawAppearanceSettings.ConnectorFamily.CLASSIC)
	assert(JigsawAppearanceSettings.ConnectorFamily.MIXED == 4)
	assert(JigsawAppearanceSettings.ConnectorFamily.ORGANIC == 5)
	var board := BoardScript.new()
	var config := JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.appearance.connector_family = JigsawAppearanceSettings.ConnectorFamily.ORGANIC
	config.appearance.connector_variation = 1.0
	board.puzzle_config = config
	get_root().add_child(board)
	call_deferred("_verify", board)

func _verify(board: Node2D) -> void:
	assert(board.get_piece_count() == 9)
	var state = board.capture_state()
	assert(state.connector_family == JigsawAppearanceSettings.ConnectorFamily.ORGANIC)
	assert(board.restore_state(state))
	assert(board.get_group_piece_ids(0).size() == 1)
	var detail = board.get_artwork_detail_info()
	assert(detail["piece_count"] == 9)
	assert(detail["source_size"] == Vector2i(640, 480))
	assert(not detail["below_recommendation"])
	print("JigsawG organic shared contours and state compatibility: PASS")
	board.queue_free()
	quit()
