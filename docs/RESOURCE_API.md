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
| `JigsawPuzzleConfig` | Source texture, grid dimensions, silhouette variety, optional resume state and references to the sections below |
| `JigsawGameplaySettings` | Free/Mosaic rules, snapping, rotation, shuffle, ghost guide and preview |
| `JigsawAppearanceSettings` | Bézier connector shape, texture sampling and piece-edge rendering |
| `JigsawCameraSettings` | Auto-fit, pan, zoom, bounds, drag response and edge scrolling |
| `JigsawFeedbackSettings` | Built-in pickup/connect/failure tint feedback |
| `JigsawPuzzleState` | Serializable runtime progress: positions, rotations, connected groups and Mosaic locks |
| `JigsawReaction[]` | Optional reusable reactions for audio, VFX or game-specific behavior |

## JigsawPuzzleConfig

| Property | Meaning |
| --- | --- |
| `puzzle_texture` | Image used by the puzzle; null uses the diagnostic checkerboard |
| `grid_mode` | Manual columns/rows (default) or Auto piece-count-driven grid |
| `target_piece_count` | Approximate desired count in Auto mode; may differ from generated count |
| `columns` | Number of puzzle columns in Manual mode |
| `rows` | Number of puzzle rows in Manual mode |
| `silhouette_variants` | Number of connector profile families used during generation |
| `gameplay` | `JigsawGameplaySettings` |
| `appearance` | `JigsawAppearanceSettings` |
| `camera` | `JigsawCameraSettings` |
| `feedback` | `JigsawFeedbackSettings` |
| `resume_state` | Optional `JigsawPuzzleState` applied after generation |
| `reactions` | Array of `JigsawReaction` Resources |

In **Manual**, the exact count is `columns * rows`. In **Auto**, source-image dimensions and `target_piece_count` determine a balanced grid; actual count can differ to avoid elongated pieces and respect minimum source resolution. `board.get_effective_grid()` returns resolved columns and rows; `board.get_piece_count()` returns the generated count. The board never modifies the original configuration Resource.

## Gameplay settings

`JigsawGameplaySettings` owns:

- `game_mode`
- `snap_tolerance`
- `allow_piece_rotation`
- `random_rotation_on_shuffle`
- `enable_multi_select`
- `shuffle_mode`
- `distribution_mode`
- `initial_scatter`
- `shuffle_spacing`
- `chaotic_spread`
- `chaotic_max_attempts`
- `generation_seed`
- `show_ghost_board`
- `ghost_opacity`
- `enable_preview`
- `preview_key`
- `preview_dim`

Use **Free** for classic group assembly. Use **Mosaic** when pieces should lock into their original image position.

With `enable_multi_select=true`, Ctrl+click toggles complete connected groups in the current selection. Dragging a multi-selection automatically packs disconnected groups into compact, separated rows near the grabbed group while retaining existing connections and rotations. A simple click does not rearrange anything. Normal single clicks are visually unhighlighted; the highlight appears only after actual pointer motion during a drag, and disappears on release. Ctrl-selections stay highlighted to indicate intentional selection.

`Shuffle.CHAOTIC` uses continuous random placement with conservative collision footprints instead of visible grid slots. `chaotic_spread` controls the available area; `chaotic_max_attempts` controls how hard the placer tries before using a safe fallback.

## Appearance settings

`JigsawAppearanceSettings` owns:

- `connector_depth`
- `connector_family` (Classic, Rounded, Angular, Compact or Mixed)
- `connector_variation` (0.0–1.0)
- `visual_style`
- `texture_sampling`
- `bezier_detail`
- `piece_edge_opacity`
- `piece_edge_width`
- `piece_material`
- `highlight_enabled`
- `highlight_color`
- `highlight_width`
- `highlight_shadow_enabled`
- `highlight_shadow_color`
- `highlight_shadow_offset`

`piece_material` accepts an optional CanvasItem `Material`/`ShaderMaterial` shared by every generated piece; null uses the built-in renderer. Apply changes with `rebuild()`. Because the material is shared, set per-piece shader instance parameters through custom integrations if necessary.

**Shape difficulty:** Classic preserves existing contours. Rounded, Angular and Compact generate original Bézier silhouettes; Mixed chooses one of these families per seeded seam. Low `connector_variation` makes connectors within a family more similar; high variation makes them more distinctive. Set `silhouette_variants` (1–8) in the root config to control how many seam variants are used. Geometry does not affect snap rules, but changing family or variation requires `rebuild()` and invalidates snapshots generated with different profile settings. Piece count, rotation, source image and reference guides also affect difficulty.

`bezier_detail` changes contour tessellation, not source-image resolution. The highlight settings affect selected/multi-selected pieces only; they do not change snap geometry.

## Camera settings

`JigsawCameraSettings` owns:

- `enable_camera_navigation`
- `invert_background_pan`
- `auto_fit_camera`
- `smooth_pan`
- `pan_smoothing`
- `restrict_camera`
- `camera_outer_margin`
- `background_pan_delay_ms`
- `background_pan_threshold_px`
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

## Resume state

`JigsawPuzzleState` is deliberately separate from save-slot/UI concerns. It stores:

- local piece positions
- quarter-turn rotations
- connected-group ids
- Mosaic locked-piece ids
- completion state
- compatibility metadata (rows/columns, source dimensions, seed, silhouette count, connector family/variation, depth, tessellation detail and game mode). Legacy states lacking the last three values remain readable.

Capture:

```gdscript
var state := $JigsawBoard.capture_state()
```

Apply to the current compatible board:

```gdscript
$JigsawBoard.restore_state(state)
```

For the simplest persistence workflow, capture one complete configuration containing the snapshot:

```gdscript
var resume_config := $JigsawBoard.capture_resume_config()
ResourceSaver.save(resume_config, "user://puzzle_resume.tres")
```

Later:

```gdscript
var resume_config := ResourceLoader.load("user://puzzle_resume.tres") as JigsawPuzzleConfig
$JigsawBoard.configure(resume_config)
```

The Board validates compatibility and group/rotation invariants before applying a state and returns `false` from `restore_state()` if it does not match. It never writes files itself. `puzzle_state_restored(state)` is emitted after a compatible snapshot is applied.

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

## Integrating an existing game UI

`JigsawBoard` exposes high-level methods so menus and HUDs do not need to override puzzle mechanics:

| API | Typical use |
| --- | --- |
| `progress_changed(progress)` | Bind a `ProgressBar` or objectives HUD |
| `get_progress()` | Read normalized progress (0–1) |
| `get_progress_info()` | Read counts, game mode and completion |
| `set_interaction_enabled(enabled)` | Suspend puzzle mouse/keyboard input while a menu is open |
| `is_interaction_enabled()` | Check whether puzzle input is enabled |
| `fit_view()` | Recenter and refit the active `Camera2D`; returns false without a camera |
| `toggle_reference_preview()` | Open/close the reference overlay |
| `is_reference_preview_visible()` | Read overlay state |
| `set_ghost_guide_visible(visible)` | Runtime ghost toggle, including Mosaic mode |
| `set_ghost_guide_opacity(opacity)` | Runtime ghost alpha |
| `is_ghost_guide_visible()` | Read ghost visibility |
| `get_connected_group_count()` | Query active connected groups |
| `get_locked_piece_count()` | Query locked Mosaic slots |

**Progress semantics:** Free = (total pieces − connected group count) / (total pieces − 1); Mosaic = locked pieces / total pieces. This is assembly progress, not a timer or board-area metric. Runtime guide overrides reset to config defaults on rebuild. These controls do not mutate shared Resources.

For higher-level use, see [Advanced integration](ADVANCED_USAGE.md).

## Public Board helpers

Useful integration methods:

- `configure(config, regenerate = true)`
- `apply_configuration()`
- `rebuild()`
- `get_configuration()`
- `set_preview_visible(visible)`
- `rotate_piece(piece_id, clockwise = true)`
- `get_piece_count()`
- `get_effective_grid()` — actual columns and rows (especially useful in Auto mode)
- `get_piece_node(piece_id)`
- `get_group_piece_ids(piece_id)`
- `get_piece_world_center(piece_id)`
- `get_dragged_piece_id()`
- `get_selected_piece_ids()`
- `select_piece(piece_id, additive = false)`
- `clear_selection()`
- `capture_state()`
- `restore_state(state, update_camera = true)`
- `capture_resume_config()`
- `is_completed()`

For external effects and game logic, use the rich semantic signals and `JigsawPuzzleEvent` API documented in [Events & Reactions](EVENTS_AND_REACTIONS.md).
