@tool
class_name JigsawPuzzleConfig
extends Resource
## Complete reusable puzzle definition. Assign one instance to JigsawBoard.
## The board reads this Resource; it never edits it.

@export_group("Puzzle")
## Source image. Null uses JigsawG's diagnostic checkerboard.
@export var puzzle_texture: Texture2D

enum GridMode { MANUAL, AUTO }
## Manual uses columns x rows. Auto resolves a balanced grid near target_piece_count.
@export var grid_mode: GridMode = GridMode.MANUAL
## Desired (approximate) number of pieces in Auto mode. The generated count may differ.
@export_range(4, 4000, 1) var target_piece_count := 100
## Exact piece count in Manual mode is columns multiplied by rows.
@export_range(2, 80, 1) var columns := 5
## Used only in Manual mode. Auto ignores columns/rows.
@export_range(2, 80, 1) var rows := 4
## Number of connector silhouette families; rebuild to regenerate.
@export_range(1, 8, 1) var silhouette_variants := 3

@export_group("Preset Resources")
## Game rules, initial shuffle, rotation and reference image.
@export var gameplay: JigsawGameplaySettings = JigsawGameplaySettings.new()
## Bézier profile, edge appearance and texture rendering.
@export var appearance: JigsawAppearanceSettings = JigsawAppearanceSettings.new()
## Pan, zoom and auto-fit behavior.
@export var camera: JigsawCameraSettings = JigsawCameraSettings.new()
## Optional touch and gamepad input; entirely inactive in existing presets.
@export var device_input: JigsawDeviceInputSettings = JigsawDeviceInputSettings.new()
## Optional named areas for connected groups. Disabled unless opted in.
@export var trays: JigsawTraySettings = JigsawTraySettings.new()
## Selection, successful connection and failed-connection feedback.
@export var feedback: JigsawFeedbackSettings = JigsawFeedbackSettings.new()

@export_group("Resume")
## Optional session snapshot applied after generation. Null starts a fresh puzzle.
## JigsawBoard never mutates this Resource; capture_state() returns a new snapshot.
@export var resume_state: JigsawPuzzleState

@export_group("Reactions")
## Optional reusable event handlers. Empty means signals-only integration.
## Shared reactions should be stateless and must not mutate this config.
@export var reactions: Array[JigsawReaction] = []
