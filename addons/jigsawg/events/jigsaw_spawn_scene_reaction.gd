@tool
class_name JigsawSpawnSceneReaction
extends JigsawReaction
## No-code reaction that spawns a PackedScene for selected puzzle events.
## The spawned scene owns its own lifetime (AnimationPlayer, GPUParticles2D, etc.).

enum ParentMode { BOARD, BOARD_PARENT, CURRENT_SCENE, PRIMARY_PIECE }

@export_group("Spawn")
## Scene instantiated when this reaction accepts an event.
@export var scene: PackedScene
## Where the new node is added. Position remains event.world_position for Node2D roots.
@export var parent_mode: ParentMode = ParentMode.BOARD_PARENT
## Position offset. World-space normally; local-space when parented to the primary piece.
@export var offset := Vector2.ZERO
## Seconds before the spawned root is freed automatically; 0 lets the scene own its lifetime.
@export_range(0.0, 30.0, 0.05) var auto_free_after := 0.0
## If present, call setup_jigsaw_event(event) on the spawned root.
@export var pass_event_to_scene := true

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
	if scene == null or not is_instance_valid(board):
		return
	var instance := scene.instantiate()
	var parent: Node = board
	match parent_mode:
		ParentMode.BOARD_PARENT:
			parent = board.get_parent() if board.get_parent() != null else board
		ParentMode.CURRENT_SCENE:
			parent = board.get_tree().current_scene if board.get_tree().current_scene != null else board
		ParentMode.PRIMARY_PIECE:
			if event.piece_id >= 0 and board.has_method("get_piece_node"):
				var piece := board.call("get_piece_node", event.piece_id)
				if piece is Node:
					parent = piece
	parent.add_child(instance)
	if instance is Node2D:
		if parent_mode == ParentMode.PRIMARY_PIECE and parent != board:
			instance.position = offset
		else:
			instance.global_position = event.world_position + offset
	if pass_event_to_scene and instance.has_method("setup_jigsaw_event"):
		instance.call("setup_jigsaw_event", event)
	if auto_free_after > 0.0:
		var timer := board.get_tree().create_timer(auto_free_after)
		timer.timeout.connect(instance.queue_free)
