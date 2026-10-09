@tool
class_name JigsawPlayAnimationReaction
extends JigsawReaction
## No-code integration: play an AnimationPlayer animation in the host scene.
## Paths are relative to the JigsawBoard, e.g. "../HUD/AnimationPlayer".

@export_group("Animation")
## Path from JigsawBoard to the host AnimationPlayer.
@export_node_path("AnimationPlayer") var animation_player_path: NodePath
## Animation name inside the targeted AnimationPlayer.
@export var animation_name: StringName = &""
## Playback speed; negative values play backwards when supported by the animation.
@export_range(-4.0, 4.0, 0.05) var speed := 1.0
## Animation blending time (-1 uses AnimationPlayer's own default).
@export_range(-1.0, 3.0, 0.05) var blend_time := -1.0

func react(board: Node2D, _event: JigsawPuzzleEvent) -> void:
	if not is_instance_valid(board) or animation_player_path.is_empty() or animation_name.is_empty():
		return
	var player := board.get_node_or_null(animation_player_path) as AnimationPlayer
	if player == null:
		push_warning("JigsawG: Animation reaction could not find AnimationPlayer at %s." % animation_player_path)
		return
	if not player.has_animation(animation_name):
		push_warning("JigsawG: AnimationPlayer has no animation '%s'." % animation_name)
		return
	player.play(animation_name, blend_time, speed, speed < 0.0)
