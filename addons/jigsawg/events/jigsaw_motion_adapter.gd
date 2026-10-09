@tool
class_name JigsawMotionAdapter
extends Resource
## Reusable, stateless motion styling for a JigsawPuzzleConfig.
## Override animate() to provide your own tween/visual effects. Never tween the
## JigsawPiece.position or .rotation: the board owns authoritative transforms.

@export_group("Motion Timing")
## Zero duration applies the result without a presentation transition.
@export_range(0.0, 1.0, 0.01) var rotation_duration := 0.18
@export_range(0.0, 1.0, 0.01) var arrangement_duration := 0.22
@export var transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var easing: Tween.EaseType = Tween.EASE_OUT

func animate(board: Node2D, motion: JigsawMotionContext) -> void:
	var duration := rotation_duration if motion.kind == JigsawMotionContext.Kind.ROTATION else arrangement_duration
	for index in range(motion.piece_ids.size()):
		var piece := board.get_piece_node(motion.piece_ids[index]) as JigsawPiece
		if is_instance_valid(piece):
			piece.animate_display_from(motion.before_transforms[index], duration, transition, easing)
