# Resource API

JigsawG is configured through one root Resource: `JigsawPuzzleConfig`.

A `JigsawBoard` exposes only:

```gdscript
@export var puzzle_config: JigsawPuzzleConfig
```

Everything else belongs to the configuration tree so presets can be copied, shared and assigned from the Inspector or code.

## Resource tree

| Resource | Responsibility |
| --- | --- |
| `JigsawPuzzleConfig` | Source texture, grid dimensions, silhouette variety and references to the sections below |
| `JigsawGameplaySettings` | Free/Mosaic rules, snapping, rotation, shuffle, ghost guide and preview |
| `JigsawAppearanceSettings` | Bézier connector shape, texture sampling and piece-edge rendering |
| `JigsawCameraSettings` | Auto-fit, pan, zoom, bounds, drag response and edge scrolling |
| `JigsawFeedbackSettings` | Built-in pickup/connect/failure tint feedback |
| `JigsawReaction[]` | Optional reusable reactions for audio, VFX or game-specific behavior |

## JigsawPuzzleConfig

| Property | Meaning |
| --- | --- |
| `puzzle_texture` | Image used by the puzzle; null uses the diagnostic checkerboard |
| `columns` | Number of puzzle columns |
| `rows` | Number of puzzle rows |
| `silhouette_variants` | Number of connector profile families used during generation |
| `gameplay` | `JigsawGameplaySettings` |
| `appearance` | `JigsawAppearanceSettings` |
| `camera` | `JigsawCameraSettings` |
| `feedback` | `JigsawFeedbackSettings` |
| `reactions` | Array of `JigsawReaction` Resources |

The exact piece count is `columns * rows`.

## Gameplay settings

`JigsawGameplaySettings` owns:

- `game_mode`
- `snap_tolerance`
- `allow_piece_rotation`
- `random_rotation_on_shuffle`
- `shuffle_mode`
- `distribution_mode`
- `initial_scatter`
- `shuffle_spacing`
- `generation_seed`
- `show_ghost_board`
- `ghost_opacity`
- `enable_preview`
- `preview_key`
- `preview_dim`

Use **Free** for classic group assembly. Use **Mosaic** when pieces should lock into their original image position.

## Appearance settings

`JigsawAppearanceSettings` owns:

- `connector_depth`
- `visual_style`
- `texture_sampling`
- `bezier_detail`
- `piece_edge_opacity`
- `piece_edge_width`

`bezier_detail` changes contour tessellation, not source-image resolution.

## Camera settings

`JigsawCameraSettings` owns:

- `enable_camera_navigation`
- `invert_background_pan`
- `auto_fit_camera`
- `smooth_pan`
- `pan_smoothing`
- `restrict_camera`
- `camera_outer_margin`
- `smooth_zoom`
- `zoom_smoothing`
- `wheel_zoom_factor`
- `min_zoom`
- `max_zoom`
- `drag_smoothing`
- `edge_scroll_zone`
- `edge_scroll_speed`
- `edge_scroll_smoothing`

Recommended desktop baseline:

```text
smooth_pan = true
pan_smoothing = 26
smooth_zoom = true
zoom_smoothing = 12
edge_scroll_speed = 900
edge_scroll_smoothing = 12
```

Higher smoothing values respond faster. Lower values feel softer but introduce more visual lag.

If the host `Camera2D` already has Godot's own `position_smoothing_enabled`, disable either that smoothing or JigsawG's `smooth_pan` to avoid double interpolation.

## Feedback settings

`JigsawFeedbackSettings` owns the lightweight feedback shipped with the board:

- `animation_style`
- `connect_animation_duration`
- `connect_tint`
- `pickup_tint`
- `enable_failure_feedback`
- `failure_tint`
- `failure_animation_duration`

For project-specific sound, particles, UI or scoring, prefer the reaction/event API instead of extending built-in feedback. See [Events & Reactions](EVENTS_AND_REACTIONS.md).

## Reactions

`JigsawPuzzleConfig.reactions` can contain:

- `JigsawAudioReaction`
- `JigsawSpawnSceneReaction`
- any custom Resource derived from `JigsawReaction`

The board snapshots the active reaction list when configuration is applied. Editing the Resource during a running puzzle takes effect on the next `rebuild()`, `apply_configuration()` or `configure()`.

## Create a puzzle in the Inspector

1. Add a `JigsawBoard` to a 2D scene.
2. Create **New JigsawPuzzleConfig** in **Puzzle Config**.
3. Assign `puzzle_texture`.
4. Choose `columns` and `rows`.
5. Expand Gameplay, Appearance, Camera and Feedback.
6. Add optional Reactions.
7. Run the scene.

Save the root Resource as a `.tres` if the same puzzle/configuration should be reused elsewhere.

## Configure from code

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    var config := JigsawPuzzleConfig.new()
    config.puzzle_texture = load("res://art/forest.png")
    config.columns = 10
    config.rows = 8

    config.gameplay.allow_piece_rotation = true
    config.gameplay.show_ghost_board = false

    config.appearance.connector_depth = 0.23
    config.appearance.visual_style = JigsawAppearanceSettings.VisualStyle.CARDBOARD

    config.camera.smooth_pan = true
    config.camera.pan_smoothing = 26.0
    config.camera.smooth_zoom = true

    board.configure(config)
```

Load a saved preset:

```gdscript
var config := load("res://puzzles/forest.tres") as JigsawPuzzleConfig
$JigsawBoard.configure(config)
```

## Configuration lifecycle

`board.configure(config)`, `board.apply_configuration()` and `board.rebuild()` regenerate the board and reset current puzzle progress.

The Board reads configuration Resources but does not intentionally mutate them. Multiple boards may share the same preset.

If a nested Resource is null, JigsawG creates runtime defaults for that section.

## Public Board helpers

Useful integration methods:

- `configure(config, regenerate = true)`
- `apply_configuration()`
- `rebuild()`
- `get_configuration()`
- `set_preview_visible(visible)`
- `rotate_piece(piece_id, clockwise = true)`
- `get_piece_count()`
- `get_piece_node(piece_id)`
- `get_group_piece_ids(piece_id)`
- `get_piece_world_center(piece_id)`
- `get_dragged_piece_id()`
- `is_completed()`

For external effects and game logic, use the rich semantic signals and `JigsawPuzzleEvent` API documented in [Events & Reactions](EVENTS_AND_REACTIONS.md).
