@tool
class_name JigsawSpawnSceneReaction
extends JigsawReaction
## No-code reaction that spawns a PackedScene for selected puzzle events.
## The spawned scene owns its own lifetime (AnimationPlayer, GPUParticles2D, etc.).

enum ParentMode { BOARD, BOARD_PARENT, CURRENT_SCENE }

@export_group("Spawn")
## Scene instantiated when this reaction accepts an event.
@export var scene: PackedScene
## Where the new node is added. Position remains event.world_position for Node2D roots.
@export var parent_mode: ParentMode = ParentMode.BOARD_PARENT
## World-space offset applied to Node2D roots.
@export var offset := Vector2.ZERO
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
	parent.add_child(instance)
	if instance is Node2D:
		instance.global_position = event.world_position + offset
	if pass_event_to_scene and instance.has_method("setup_jigsaw_event"):
		instance.call("setup_jigsaw_event", event)
