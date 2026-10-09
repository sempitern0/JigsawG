@tool
class_name JigsawAppearanceSettings
extends Resource
## Reusable jigsaw silhouette and rendering options for JigsawPuzzleConfig.
## Animation controls live exclusively in JigsawFeedbackSettings.

enum VisualStyle { CLEAN, CARDBOARD, HIGH_CONTRAST }
## Classic retains legacy contours; other families are original procedural variants.
enum ConnectorFamily { CLASSIC, ROUNDED, ANGULAR, COMPACT, MIXED, ORGANIC }

@export_group("Artwork")
## Tab depth as a fraction of the shortest piece side (rebuild required).
@export_range(0.12, 0.34, 0.01) var connector_depth := 0.25
## Alternative round, angular, compact or asymmetric Organic tabs. Mixed preserves classic family mixing.
@export var connector_family: ConnectorFamily = ConnectorFamily.CLASSIC
## 0 = uniform connectors (harder to recognize); 1 = maximum variant diversity.
@export_range(0.0, 1.0, 0.05) var connector_variation := 1.0
## Clean has no rim; Cardboard adds a soft border; High Contrast adds a dark one.
@export var visual_style: VisualStyle = VisualStyle.CLEAN
## Linear favors smooth pixels, Nearest is sharp/blocky, Mipmaps favors distance.
@export_enum("Linear", "Nearest", "Mipmaps") var texture_sampling := 0
## Draw more Bézier samples without increasing source image resolution.
@export_range(4, 16, 1) var bezier_detail := 8
## Warn when the native source provides fewer pixels per generated piece side.
## Raising this value does not upscale artwork or affect generated topology.
@export_range(32, 256, 8) var recommended_pixels_per_piece := 96
## Optional manual edge tint; 0 removes the rim.
@export_range(0.0, 1.0, 0.01) var piece_edge_opacity := 0.0
## Thickness of an enabled edge rim in texture pixels.
@export_range(0.1, 3.0, 0.1) var piece_edge_width := 0.7
## Optional shared CanvasItem Material/ShaderMaterial applied to generated pieces.
## Null preserves the default textured polygon renderer; rebuild to apply.
@export var piece_material: Material

@export_group("Selection Highlight")
## Draw an outline around selected pieces/groups.
@export var highlight_enabled := true
## Highlight outline color.
@export var highlight_color := Color(1.0, 0.84, 0.38, 0.85)
## Highlight outline width in local image pixels.
@export_range(0.1, 6.0, 0.1) var highlight_width := 1.2
## Draw a soft offset shadow below selected pieces.
@export var highlight_shadow_enabled := true
## Selected-piece shadow tint.
@export var highlight_shadow_color := Color(0.0, 0.0, 0.0, 0.24)
## Selected-piece shadow offset in local pixels.
@export var highlight_shadow_offset := Vector2(3.0, 4.0)

