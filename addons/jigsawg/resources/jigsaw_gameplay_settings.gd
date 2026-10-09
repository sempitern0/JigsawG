@tool
class_name JigsawGameplaySettings
extends Resource
## Reusable rules and reference-image options for JigsawPuzzleConfig.
## Changes take effect when the board applies the configuration.

enum Mode { FREE, MOSAIC }
enum Shuffle { AROUND_BOARD, CENTER, BOTTOM, CHAOTIC }
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
## Ctrl+click toggles complete connected groups; a drag packs distant groups into a compact non-overlapping arrangement.
@export var enable_multi_select := true
## Optional host InputMap action for rotating the group under the pointer.
## Does not replace the standard right-mouse click unless the host maps it.
@export var rotate_action: StringName = &""

@export_group("Accessibility")
## Additional fraction of the shorter piece side allowed for joining neighbors.
## Zero retains the current puzzle difficulty without altering join geometry.
@export_range(0.0, 0.25, 0.01) var snap_assist_extra_fraction := 0.0
## Extra pointer tolerance just outside a contour, in viewport pixels.
## Exact hits always win. Zero retains the existing input behavior.
@export_range(0.0, 24.0, 1.0) var selection_assist_radius_px := 0.0

@export_group("Optional Piece Organizer")
## Your game's InputMap can bind corner/edge/interior camera browsing.
## Empty action names disable all organizer shortcuts by default.
@export var next_corner_action: StringName = &""
@export var next_edge_action: StringName = &""
@export var next_interior_action: StringName = &""

@export_group("Shuffle")
## Choose where scattered pieces are placed.
@export var shuffle_mode: Shuffle = Shuffle.AROUND_BOARD
## Random mixes slots; Radial assigns them from nearest to farthest.
@export var distribution_mode: Distribution = Distribution.RANDOM
## Scatter on build; disabling it starts pieces in their solved locations.
@export var initial_scatter := true
## Gap between scatter slots, as a fraction of the largest piece dimension.
@export_range(0.02, 0.35, 0.01) var shuffle_spacing := 0.14
## Chaotic mode spread around the solved board; higher uses a wider natural scatter area.
@export_range(1.0, 5.0, 0.1) var chaotic_spread := 2.2
## Maximum random placement attempts per piece before falling back to deterministic slots.
@export_range(8, 200, 1) var chaotic_max_attempts := 64
## Reproducible profile and scatter seed.
@export var generation_seed := 4729

@export_group("Large Puzzle Generation")
## 0 = legacy synchronous rebuild; positive = yield a frame after this many pieces.
## Allows the host to render loading UI and configure() to cancel a pending build.
@export_range(0, 512, 1) var generation_batch_size := 0

@export_group("Reference")
## Draw the original image faintly under the assembly area.
@export var show_ghost_board := false
## Reference-image alpha; 0 hides it, 1 makes it fully opaque.
@export_range(0.0, 1.0, 0.01) var ghost_opacity := 0.25
## Allow a fullscreen reference overlay.
@export var enable_preview := true
## Key used to toggle the fullscreen preview.
@export var preview_key: Key = KEY_P
## Optional InputMap action for displaying the reference without pressing P.
@export var preview_action: StringName = &""
## Background darkness of fullscreen image preview; 0 transparent, 1 opaque.
@export_range(0.0, 1.0, 0.01) var preview_dim := 0.82
