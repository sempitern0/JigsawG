extends SceneTree
## Public API smoke test:
## godot --headless --path . --script res://tests/test_public_integration.gd

const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
const ReceiverScript = preload("res://tests/fixtures/reaction_receiver.gd")

var progress_values: Array[float] = []

func _initialize() -> void:
	var host := Node2D.new()
	host.name = "PuzzleHost"
	get_root().add_child(host)

	var receiver := Node.new()
	receiver.name = "HUD"
	receiver.set_script(ReceiverScript)
	host.add_child(receiver)

	var board := BoardScript.new()
	board.name = "JigsawBoard"
	var config := JigsawPuzzleConfig.new()
	config.columns = 2
	config.rows = 2
	config.gameplay.initial_scatter = false
	board.puzzle_config = config
	board.progress_changed.connect(func(value: float) -> void:
		progress_values.append(value)
	)
	host.add_child(board)
	call_deferred("_verify", board, receiver, host)

func _verify(board: Node2D, receiver: Node, host: Node2D) -> void:
	assert(board.get_piece_count() == 4)
	assert(is_equal_approx(board.get_progress(), 0.0))
	assert(board.get_progress_info()["connections_needed"] == 3)
	assert(progress_values.size() >= 1, "No initial HUD progress signal.")

	board.set_interaction_enabled(false)
	assert(not board.is_interaction_enabled())
	board.set_interaction_enabled(true)
	assert(board.is_interaction_enabled())

	board.set_ghost_guide_visible(true)
	assert(board.is_ghost_guide_visible())
	board.set_ghost_guide_visible(false)
	assert(not board.is_ghost_guide_visible())
	board.set_ghost_guide_opacity(0.4)

	board.set_preview_visible(true)
	assert(board.is_reference_preview_visible())
	board.toggle_reference_preview()
	assert(not board.is_reference_preview_visible())

	var event := JigsawPuzzleEvent.new(JigsawPuzzleEvent.Type.PUZZLE_COMPLETED)
	event.board = board

	var plain := JigsawCallMethodReaction.new()
	plain.target_path = NodePath("../HUD")
	plain.method_name = &"on_simple_event"
	plain.react(board, event)
	assert(receiver.no_arg_calls == 1, "No-argument reaction failed.")

	var detailed := JigsawCallMethodReaction.new()
	detailed.target_path = NodePath("../HUD")
	detailed.method_name = &"on_puzzle_event"
	detailed.pass_event = true
	detailed.react(board, event)
	assert(receiver.last_event == event, "Event-context reaction failed.")

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	host.add_child(animation_player)
	var library := AnimationLibrary.new()
	var animation := Animation.new()
	animation.length = 1.0
	assert(library.add_animation(&"win", animation) == OK)
	assert(animation_player.add_animation_library(&"", library) == OK)

	var animation_reaction := JigsawPlayAnimationReaction.new()
	animation_reaction.animation_player_path = NodePath("../AnimationPlayer")
	animation_reaction.animation_name = &"win"
	animation_reaction.react(board, event)
	assert(animation_player.current_animation == "win", "Animation reaction did not play.")

	print("JigsawG public integration smoke test: PASS")
	host.queue_free()
	quit()
