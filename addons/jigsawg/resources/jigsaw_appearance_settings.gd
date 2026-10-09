@tool
class_name JigsawAppearanceSettings
extends Resource
## Reusable visual preset. These overrides apply when JigsawBoard.rebuild()
## is called; VFX signals remain available for a custom presentation layer.

enum VisualStyle { CLEAN, CARDBOARD, HIGH_CONTRAST }
enum AnimationStyle { NONE, SUBTLE, PLAYFUL }

@export_group("Artwork")
## Tab depth as a fraction of the shortest piece side (rebuild required).
@export_range(0.12, 0.34, 0.01) var connector_depth := 0.25
## Clean has no rim; Cardboard adds a soft border; High Contrast adds a dark one.
@export var visual_style: VisualStyle = VisualStyle.CLEAN
## Linear favors smooth pixels, Nearest is sharp/blocky, Mipmaps favors distance.
@export_enum("Linear", "Nearest", "Mipmaps") var texture_sampling := 0
## Draw more Bézier samples without increasing source image resolution.
@export_range(4, 16, 1) var bezier_detail := 8
## Optional manual edge tint; 0 removes the rim.
@export_range(0.0, 1.0, 0.01) var piece_edge_opacity := 0.0
## Thickness of an enabled edge rim in texture pixels.
@export_range(0.1, 3.0, 0.1) var piece_edge_width := 0.7

@export_group("Feedback")
## None disables tweens; Subtle/Playful vary tint intensity.
@export var animation_style: AnimationStyle = AnimationStyle.SUBTLE
## Feedback animation duration in seconds.
@export_range(0.04, 0.6, 0.01) var connect_animation_duration := 0.16
