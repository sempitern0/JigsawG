@tool
class_name JigsawFeedbackSettings
extends Resource
## Interaction feedback presets. Motion animation is presentation-only; logical transforms stay authoritative.

enum AnimationStyle { NONE, SUBTLE, PLAYFUL }

@export_group("Animation")
## None disables built-in tint tweens; an explicit Motion Adapter remains independent.
@export var animation_style: AnimationStyle = AnimationStyle.SUBTLE
## Total connect feedback duration in seconds.
@export_range(0.04, 0.8, 0.01) var connect_animation_duration := 0.16
## Flash color on a successful snap (RGB can exceed 1 for emphasis).
@export var connect_tint := Color(1.10, 1.10, 1.02, 1.0)
## Optional motion adapter for actual piece rotations and multi-selection packing.
## Leave null to preserve instantaneous movement; set a JigsawMotionAdapter for
## Tween interpolation or a custom Resource subclass for proprietary effects.
@export var motion_adapter: JigsawMotionAdapter
## Applied while a dragged piece/group is selected in Playful mode.
@export var pickup_tint := Color(1.12, 1.09, 1.02, 1.0)
## Enable red-tinted feedback when released outside a valid connection.
@export var enable_failure_feedback := false
## Feedback flash tint when placement fails.
@export var failure_tint := Color(1.16, 0.72, 0.72, 1.0)
## Total failed-connection flash duration.
@export_range(0.04, 0.8, 0.01) var failure_animation_duration := 0.18
