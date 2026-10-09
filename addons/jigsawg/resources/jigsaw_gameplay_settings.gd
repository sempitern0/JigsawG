@tool
class_name JigsawGameplaySettings
extends Resource
## Reusable rules and reference-image options for JigsawPuzzleConfig.
## Changes take effect when the board applies the configuration.

enum Mode { FREE, MOSAIC }
enum Shuffle { AROUND_BOARD, CENTER, BOTTOM }
enum Distribution { RANDOM, RADIAL }

@export_group("Rules")
## Free joins neighboring groups; Mosaic locks correctly placed individual pieces.
@export var game_mode: Mode = Mode.FREE
## Accept snapping within this fraction of a piece side.
@export_range(0.05, 0.5, 0.01) var snap_tolerance := 0.24
## Allow right-click quarter-turn rotation of an unlocked piece or connected group.
@export var allow_piece_rotation := false
## Start scattered pieces at random 0°, 90°, 180° or 270° when rotation is enabled.
@export var random_rotation_on_shuffle := true

@export_group("Shuffle")
## Choose where scattered pieces are placed.
@export var shuffle_mode: Shuffle = Shuffle.AROUND_BOARD
## Random mixes slots; Radial assigns them from nearest to farthest.
@export var distribution_mode: Distribution = Distribution.RANDOM
## Scatter on build; disabling it starts pieces in their solved locations.
@export var initial_scatter := true
## Gap between scatter slots, as a fraction of the largest piece dimension.
@export_range(0.02, 0.35, 0.01) var shuffle_spacing := 0.14
## Reproducible profile and scatter seed.
@export var generation_seed := 4729

@export_group("Reference")
## Draw the original image faintly under the assembly area.
@export var show_ghost_board := false
## Reference-image alpha; 0 hides it, 1 makes it fully opaque.
@export_range(0.0, 1.0, 0.01) var ghost_opacity := 0.25
## Allow a fullscreen reference overlay.
@export var enable_preview := true
## Key used to toggle the fullscreen preview.
@export var preview_key: Key = KEY_P
## Background darkness of fullscreen image preview; 0 transparent, 1 opaque.
@export_range(0.0, 1.0, 0.01) var preview_dim := 0.82
