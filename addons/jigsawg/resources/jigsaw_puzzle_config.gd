@tool
class_name JigsawPuzzleConfig
extends Resource
## Complete reusable puzzle definition. Assign one instance to JigsawBoard.
## The board reads this Resource; it never edits it.

@export_group("Puzzle")
## Source image. Null uses JigsawG's diagnostic checkerboard.
@export var puzzle_texture: Texture2D
## Exact piece count is columns multiplied by rows; rebuild to regenerate.
@export_range(2, 40, 1) var columns := 5
## Exact piece count is columns multiplied by rows; rebuild to regenerate.
@export_range(2, 40, 1) var rows := 4
## Number of connector silhouette families; rebuild to regenerate.
@export_range(1, 8, 1) var silhouette_variants := 3

@export_group("Preset Resources")
## Game rules, initial shuffle, rotation and reference image.
@export var gameplay: JigsawGameplaySettings = JigsawGameplaySettings.new()
## Bézier profile, edge appearance and texture rendering.
@export var appearance: JigsawAppearanceSettings = JigsawAppearanceSettings.new()
## Pan, zoom and auto-fit behavior.
@export var camera: JigsawCameraSettings = JigsawCameraSettings.new()
## Selection, successful connection and failed-connection feedback.
@export var feedback: JigsawFeedbackSettings = JigsawFeedbackSettings.new()

@export_group("Reactions")
## Optional reusable event handlers. Empty means signals-only integration.
## Shared reactions should be stateless and must not mutate this config.
@export var reactions: Array[JigsawReaction] = []
