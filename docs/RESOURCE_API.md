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
| `JigsawDeviceInputSettings` | Opt-in tablet gestures and handheld/controller gameplay |
| `JigsawTraySettings` | Optional named group holding areas and automatic shelf packing |
| `JigsawHintSettings` | Opt-in staged visual clues; limits precision and configures optional input |
| `JigsawHistorySettings` | Optional bounded in-memory undo/redo of completed player operations |
| `JigsawFeedbackSettings` | Built-in pickup/connect/failure tint feedback |
| `JigsawPuzzleState` | Serializable runtime progress: positions, rotations, connected groups and Mosaic locks |
| `JigsawGroupModel` (internal) | Node-free connected groups, memberships, joins and atomic state restoration |
| `JigsawConnectionResolver` (internal) | Pure grid-neighbor search, quarter-turn checks and snap offsets |
| `JigsawReaction[]` | Optional reusable reactions for audio, VFX or game-specific behavior |

## JigsawPuzzleConfig

| Property | Meaning |
| --- | --- |
| `puzzle_texture` | Image used by the puzzle; null uses the diagnostic checkerboard |
| `grid_mode` | Manual columns/rows (default) or Auto piece-count-driven grid |
| `target_piece_count` | Approximate desired count in Auto mode (4–4000); may differ from generated count |
| `columns` | Number of puzzle columns in Manual mode |
| `rows` | Number of puzzle rows in Manual mode |
| `silhouette_variants` | Number of connector profile families used during generation |
| `gameplay` | `JigsawGameplaySettings` |
| `appearance` | `JigsawAppearanceSettings` |
| `camera` | `JigsawCameraSettings` |
| `device_input` | `JigsawDeviceInputSettings`, disabled by default |
| `trays` | `JigsawTraySettings`, disabled by default |
| `hints` | `JigsawHintSettings`, disabled by default |
| `history` | `JigsawHistorySettings`, disabled by default |
| `feedback` | `JigsawFeedbackSettings` |
| `resume_state` | Optional `JigsawPuzzleState` applied after generation |
| `reactions` | Array of `JigsawReaction` Resources |

In **Manual**, the exact count is `columns * rows`. In **Auto**, source-image dimensions and `target_piece_count` determine a balanced grid; actual count can differ to avoid elongated pieces and respect minimum source resolution. `board.get_effective_grid()` returns resolved columns and rows; `board.get_piece_count()` returns the generated count. The board never modifies the original configuration Resource.

## Bounded action undo and redo (P3.4)

`JigsawPuzzleConfig.history` is a `JigsawHistorySettings` Resource, **disabled by default**. When enabled it records one bounded transaction per finished player operation, not per frame or cursor motion. Covered operations: release of a moved group (including multi-group packing, Free connections or Mosaic cell locks), quarter-turn rotations, and public tray store/retrieve operations. Rotation during a held drag is included in that drag transaction. An unchanged click is ignored.

```gdscript
config.history.enabled = true
config.history.maximum_actions = 20 # Valid range 1–64
config.history.standard_keyboard_shortcuts = true
# Optional InputMap aliases belonging to the host game:
config.history.undo_action = &"my_game_undo"
config.history.redo_action = &"my_game_redo"
board.configure(config)

if board.can_undo():
    board.undo()
if board.can_redo():
    board.redo()
var counts: Vector2i = board.get_history_counts()
var next_label: StringName = board.get_next_undo_label()
board.clear_history()
```

`history_changed(can_undo, can_redo)` signals button states. `history_applied(direction: StringName, label: StringName)` emits `&"undo"` or `&"redo"` and the recorded `&"drag"`, `&"rotate"`, `&"tray_store"` or `&"tray_retrieve"` label. These signals are separate from the serialized gameplay event-mask API: applying a snapshot does **not** re-emit piece placement, group connection, puzzle-completion, drag or failed-connection events. It updates progress and existing tray signals as appropriate. Host scoring systems should update from authoritative Board progress/state after `history_applied` rather than add/subtract rewards by replaying old events.

When enabled, the default optional keyboard shortcuts are **Ctrl+Z** (undo), **Ctrl+Y** and **Ctrl+Shift+Z** (redo). These use `_unhandled_input` so handled HUD input takes precedence; disable `standard_keyboard_shortcuts` for a host that owns those combinations. Explicit `undo_key`/`redo_key` default to `KEY_NONE`; custom InputMap action names are empty by default. Host menus, gamepad controls and tablets should call the Board API rather than simulate keyboard presses.

Undo/redo uses the existing `JigsawPuzzleState` validator: positions, rotations, connection roots, Mosaic locks, completion and tray assignments are restored atomically, but no history is serialized into the save. Restore/rebuild resets history; invalid external restore must leave it untouched. Undo/redo is unavailable during a drag, preview, pause, generation or incompatible state. The camera viewport, selection, hint markers and controller cursor are **not** part of the transaction. **History uses full snapshots**, not a delta encoding: set a bounded action count appropriate to your hardware; do not assume a fixed memory budget without profiling 2000-piece configurations.

## Progressive non-solving hints (P3.3)

The optional `JigsawPuzzleConfig.hints: JigsawHintSettings` Resource controls progressive guidance. `enabled=false` by default; `maximum_level=CANDIDATE` by default prevents unintentional exposure of an exact destination. Set `maximum_level=PRECISE` only for explicit stronger help.

| Level | Board enum | Reveals |
| --- | --- | --- |
| 0 | `OFF` | Nothing; overlay cleared |
| 1 | `REGION` | Coarse solved-image region containing a candidate piece (configured 2–5 bands/axis; automatically merged on small grids so a region cannot pinpoint one cell) |
| 2 | `CANDIDATE` | Previous region + visible bounds of the candidate's **currently movable connected group**, wherever it is |
| 3 | `PRECISE` | Previous hints + exact destination **cell** for one candidate piece (no orientation/automatic movement) |

```gdscript
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
config.hints.enabled = true
config.hints.maximum_level = JigsawHintSettings.MaximumLevel.PRECISE
config.hints.region_divisions = 3
config.hints.focus_on_request = true
board.configure(config)

board.request_hint(BoardScript.HintLevel.REGION) # Choose deterministic loose group
board.advance_hint() # Candidate group
board.advance_hint() # Precise home cell (requires PRECISE max)
var info: Dictionary = board.get_hint_info()
# Keys: level, piece_id, region, candidate_bounds, target_slot,
#       group_piece_ids, tray_index. Rect2 values are Board-local.
board.focus_hint() # Camera only
board.clear_hint()
```

`request_hint(level, piece_id=-1)` accepts an explicitly chosen unlocked piece or selects one deterministically: the player's current selection takes precedence, otherwise unplaced connected groups are cycled by representative piece ID. Mosaic-locked pieces are excluded. A candidate can be within a holding tray; level 2 highlights its current location there rather than teleporting it. `advance_hint()` cycles through the **configured maximum** and then turns hints off; the next full cycle advances to another group when no explicit selection exists. A requested hint does not expand into a more precise level automatically or when the camera moves. No hint is offered while dragging, paused, previewing, completed, or generating batches.

At REGION level the public `piece_id` is `-1`, the candidate and target rectangles are empty and `hint_changed` also reports piece `-1`. The resolver tracks a candidate privately so the host HUD cannot accidentally reveal level-2 details at level 1.

The `hint_changed(level, piece_id)` signal is presentation-only and does not enter the `JigsawPuzzleEvent` gameplay mask, increment progress, change group connectivity, emit snap results, or appear in `JigsawPuzzleState`. On a rebuild, compatible state restoration, solved puzzle or Mosaic piece lock, an obsolete hint is cleared. New Resource settings: `enabled`, `maximum_level`, `region_divisions`, `show_overlay`, `focus_on_request`, optional `advance_key` and host-owned `advance_action`. Both inputs default to disabled. The demo alone enables the H key and level 3.

The built-in overlay uses **static translucent rectangles** (no tween or screen blocking); the candidate marker follows current group bounds during movement. This is not a visual match/color classifier, automated placement or a full hint economy/cooldown framework. Game HUDs remain responsible for charging hints or showing localized copy.

## Named holding trays (P3.2)

The optional `JigsawPuzzleConfig.trays: JigsawTraySettings` Resource provides visible, **world-space** holding zones below the solved board. Set `trays.enabled=true` and choose up to four names with `trays.tray_names`. `show_background` controls the built-in low-contrast outlines; `allow_drop` controls drop-to-tray behavior. Neither setting is enabled in existing games.

```gdscript
config.trays.enabled = true
config.trays.tray_names = PackedStringArray(["Corners", "Edges", "Unsorted"])
board.configure(config)

var slots: int = board.get_tray_count()
var title: String = board.get_tray_name(0)
var area: Rect2 = board.get_tray_rect(0)  # Board-local coordinates
var stored: PackedInt32Array = board.get_tray_piece_ids(0)
var existing_slot: int = board.get_piece_tray_index(piece_id)  # -1 outside

board.put_group_in_tray(piece_id, 0)
board.put_selection_in_tray(1)  # Returns count of distinct groups
board.focus_tray(0)
board.retrieve_group_from_tray(piece_id)
```

These functions never split joined groups. Positioning uses deterministic shelf packing on the **authoritative connected components**; every group's exact relative transforms and quarter-turns stay intact. Dropping a dragged piece over a tray moves the entire selected group(s), whether input came from mouse, touchscreen or virtual gamepad. This is not a failed snap and does not emit connection-failure effects. To retrieve, drag the group out; `retrieve_group_from_tray()` moves it into a nonoverlapping *staging column* left of the board rather than its former scatter coordinates. `focus_tray()` frames a tray for controller-accessible HUD buttons. Host UI can listen to the `trays_changed` signal to update inventory counts.

Groups in a tray cannot accidentally join other groups or lock into Mosaic positions. Already locked Mosaic pieces cannot be put into trays. The normal overview (**End**) includes tray bounds; normal board focus (**Home**) stays on the assembly image.

The optional `JigsawPuzzleState.tray_indices` array stores one tray index per piece (`-1` means outside). Existing schema-1 snapshots with an empty array remain valid. **Restoring assigned tray data requires trays enabled and the same compatible index range**, and any inconsistent per-group assignments or truncated lists are rejected *before* live state is mutated. Resuming preserves saved piece coordinates; it does not pack groups anew on load. This addition does not change the schema version, group IDs, image or connector geometry.

**Limits:** these are world-space zones, not scrolling thumbnail inventories. Their visible size adapts as groups are added and a large number of stored pieces can expand the overall camera overview. Runtime and device usability still require a real Godot import/visual test.

## Corner, edge and interior organizer

Every piece retains a stable topology category in `BoardScript.PieceCategory`: `CORNER`, `EDGE` (outer border **excluding corners**) or `INTERIOR`. Categories come from the original solved grid, not current position, angle, Bézier silhouette or image color.

```gdscript
# Use after the puzzle_generated signal if generation is batched.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")
var category: int = board.get_piece_category(piece_id)  # -1 if invalid
var corners: PackedInt32Array = board.get_piece_ids_by_category(
    BoardScript.PieceCategory.CORNER
)
var borders: PackedInt32Array = board.get_piece_ids_by_category(
    BoardScript.PieceCategory.EDGE, true  # include already placed Mosaic pieces
)
var id: int = board.focus_next_piece_by_category(
    BoardScript.PieceCategory.CORNER
)
```

The ID queries are sorted by original piece ID and include all unlocked matching pieces by default. `include_locked=true` returns the full classification, including Mosaic-locked pieces. While the puzzle is incomplete due to **batched generation**, queries return an empty list and single-piece category returns `-1`.

`focus_next_piece_by_category(category)` returns the ID of the focused group representative, or `-1` when no candidate/camera is available, interactions are paused, a drag is active or the reference preview is open. It cycles deterministically through qualifying **distinct connected groups**, fits the group with camera zoom/margins, and respects camera restriction settings. It does **not** modify selected pieces, connect groups, move geometry, or write to `JigsawPuzzleState`; the browse position is reset on rebuild/restore.

For game menus or gamepad shortcuts, use **Gameplay → Optional Piece Organizer** to map `next_corner_action`, `next_edge_action`, `next_interior_action` to **host-defined** InputMap names. Or enable `next_corner_key`, `next_edge_key`, `next_interior_key` (all `KEY_NONE` by default). The included demo opts into **C / E / I**; these keys are not reserved in other games.

This is an **opt-in finding aid**, not sorting/trays or an automatic solver. The pure module `src/jigsaw_piece_catalog.gd` has its own topology tests for 2×2, 2×N, normal grids and 2000-piece puzzles.

## Group graph and connection architecture

`JigsawBoard` remains the only scene-facing component. Internally, `addons/jigsawg/src/jigsaw_group_model.gd` owns all parent/root identifiers, member lists and join operations. It does not need the scene tree, and it restores a serialized `piece_group_ids` map atomically. The anchored/dragged group's representative survives each merge, which preserves root IDs and multi-selection behavior.

`addons/jigsawg/src/jigsaw_connection_resolver.gd` independently determines legal grid neighbors and the exact shift needed for matching quarter-turn orientations within tolerance. `JigsawBoard` still controls Node2D transforms, visual motion adapters, snapping orchestration and public events. No host integration needs to access these internal classes; the existing public group/selection/state APIs and `GROUP_CONNECTED` events stay intact.

## Gameplay settings

`JigsawGameplaySettings` owns:

- `game_mode`
- `snap_tolerance`
- `snap_assist_extra_fraction` (default `0`, optional extra fraction of the shorter piece side, capped to a total 0.5)
- `selection_assist_radius_px` (default `0`, optional 0–24 extra **screen pixels** of silhouette picking allowance)
- `allow_piece_rotation`
- `random_rotation_on_shuffle`
- `enable_multi_select`
- `rotate_action` (optional host InputMap action; right-click remains)
- `preview_action` (optional host InputMap action; P remains)
- `shuffle_mode`
- `distribution_mode`
- `initial_scatter`
- `shuffle_spacing`
- `chaotic_spread`
- `chaotic_max_attempts`
- `generation_seed`
- `generation_batch_size` (0 synchronous, positive = pieces per yielded frame)
- `show_ghost_board`
- `ghost_opacity`
- `enable_preview`
- `preview_key`
- `preview_dim`

Use **Free** for classic group assembly. Use **Mosaic** when pieces should lock into their original image position.

### Optional accessibility assistance

In Gameplay → Accessibility, **Snap Assist Extra Fraction** adds to the existing `snap_tolerance` rather than overriding it. For example, `0.24` base + `0.10` extra accepts a 0.34-shorter-piece-side offset. This operates on **Free** group joining and **Mosaic** slot placement, but does not permit joining unrelated grid neighbors, mixing quarter-turn orientations, or changing the exact snap destination. Its total tolerance is capped at half the shorter piece side. Both gameplay modes still use their original failure/success events and serialization.

**Selection Assist Radius Px** relaxes only mouse picking, not piece geometry. Real polygon hits always take priority, including Ctrl-selected group priority. If nothing lies under the cursor, the Board checks nearby indexed pieces for the closest visible contour within the configured **screen-pixel radius**; Ctrl-highlighted candidates win equivalent ambiguous near-misses. The search uses a spatial rectangle in Board coordinates, so large puzzles do not require a full polygon scan. Render-only movement transforms and Camera2D zoom are respected.

Both settings default to `0`: old Resource presets, procedural geometry, group IDs and puzzle save snapshots remain compatible. These settings are intended for optional ergonomic presets, not as an automatic puzzle solver. A practical starting point is `0.08` extra snap and `8` screen pixels for easier picking.

A host options menu can change both **without restarting the puzzle**:

```gdscript
$JigsawBoard.set_accessibility_assists(0.10, 10.0)
var active_assists: Vector2 = $JigsawBoard.get_accessibility_assists()
```

This runtime override changes neither the shared `JigsawPuzzleConfig` Resource nor saved positions/groups. A subsequent `rebuild()` or `apply_configuration()` restores the Resource's configured values.

With `enable_multi_select=true`, Ctrl+click toggles complete connected groups in the current selection. Dragging a multi-selection automatically packs disconnected groups into compact, separated rows near the grabbed group while retaining existing connections and rotations. A simple click does not rearrange anything. Normal single clicks are visually unhighlighted; the highlight appears only after actual pointer motion during a drag, and disappears on release. Ctrl-selections stay highlighted to indicate intentional selection.

`Shuffle.CHAOTIC` uses continuous random placement with conservative collision footprints instead of visible grid slots. `chaotic_spread` controls the available area; `chaotic_max_attempts` controls how hard the placer tries before using a safe fallback.

## Appearance settings

`JigsawAppearanceSettings` owns:

- `connector_depth`
- `connector_family` (Classic, Rounded, Angular, Compact, Mixed or Organic)
- `connector_variation` (0.0–1.0)
- `recommended_pixels_per_piece` (native-artwork warning threshold; default 96 px)
- `visual_style`
- `texture_sampling`
- `bezier_detail`
- `piece_edge_opacity`
- `piece_edge_width`
- `piece_edge_color` (RGBA tint of the visible rim; combines with edge opacity)
- `piece_material`
- `highlight_enabled`
- `highlight_color`
- `highlight_width`
- `highlight_shadow_enabled`
- `highlight_shadow_color`
- `highlight_shadow_offset`

`piece_material` accepts an optional CanvasItem `Material`/`ShaderMaterial` shared by every generated piece; null uses the built-in renderer. Apply changes with `rebuild()`. Because the material is shared, set per-piece shader instance parameters through custom integrations if necessary.

**Shape difficulty:** Classic preserves existing contours. Rounded, Angular and Compact generate original Bézier silhouettes; Mixed chooses one of these families per seeded seam. Organic produces original, seeded asymmetric, more curved seams with shared complementary tokens. This takes inspiration from the mask *families* in the supplied C# puzzle reference, but does not copy its SVG mask assets. Low `connector_variation` makes connectors within a family more similar; high variation makes them more distinctive. Set `silhouette_variants` (1–8) in the root config to control how many seam variants are used. Geometry does not affect snap rules, but changing family or variation requires `rebuild()` and invalidates snapshots generated with different profile settings. Piece count, rotation, source image and reference guides also affect difficulty.

For visually dark or noisy artwork, use **Appearance → Piece Edge Color** with a lighter tint and adjust **Piece Edge Opacity** and **Piece Edge Width**. The default RGBA tint (`#141312` approximately), opacity and width preserve the older look. This is an optional extra contour stroke when edge opacity is positive; it does not alter the silhouette or snap rules.

`bezier_detail` changes contour tessellation, not source-image resolution. The highlight settings affect selected/multi-selected pieces only; they do not change snap geometry.

## Large puzzle generation

Set `gameplay.generation_batch_size > 0` to generate a puzzle across multiple frames without a background thread. Listen to `generation_progress_changed(generated, total)` or `puzzle_generated(piece_count)` for completion; `board.is_generating()` and `board.get_generation_progress()` provide pollable state. The prior synchronous contract remains the default at `generation_batch_size = 0`.

**First frame:** with automatic camera fitting enabled, the Board creates and displays the **entire mosaic guide**, centers the camera using the full source-image/grid dimensions, and yields one presentation frame **before the first piece batch**. During the build, the guide remains fully framed. When all pieces have been generated, scattered and optionally restored, the camera applies its normal configured final framing (Board, All Pieces or Auto). This avoids showing a cropped corner while pieces are loading. The initial frame reports progress `(0, total)`; the first nonzero batch appears after that frame. When `camera.auto_fit_camera = false`, the host camera is left alone. A synchronous `generation_batch_size = 0` keeps the previous immediate generation behavior.

Starting a second `rebuild()` or `configure()` invalidates the previous build's coroutine, discards partial pieces, and starts a new one. `capture_state()` is not supported during generation; wait for `puzzle_generated`. The deterministic scatter planner is based on concentric structured rings or a spatial hash for Chaotic mode.

## Artwork resolution and readable 2000-piece puzzles

Generated pieces sample **one source image texture** using piece-local UV coordinates. A 2000-piece puzzle made from an image that is only a few thousand pixels wide might provide just 40–80 native pixels per piece. Enlarging it does not recover fine details regardless of texture filter or Bézier tessellation.

`JigsawAppearanceSettings.recommended_pixels_per_piece` defaults to 96. If the smaller native piece dimension is below this advisory threshold, `JigsawBoard` emits `artwork_detail_warning(info)` and a console warning suggesting a source-image resolution. `get_artwork_detail_info()` returns `source_size`, `native_pixels_per_piece`, `minimum_native_side_pixels`, `recommended_source_size` and `below_recommendation`. The threshold is configurable, not an enforced generation limit. For sharp zoomed-in photo details prefer original high-resolution art over upscaling a low-resolution JPEG, while accounting for GPU texture size/VRAM limits.

Mipmaps are generated only for `texture_sampling = Mipmaps`, avoiding unnecessary mipmap generation and extra allocation in Nearest and Linear modes.

## Spatial piece picking for large puzzles

The Board uses a lazily refreshed **board-local spatial index**. Transform,
rotation or presentation-only display changes invalidate the index; only
nearby candidate pieces go through the exact Bézier polygon hit test. Descending
draw order and Ctrl-selected group priority remain unchanged. The lookup is
internal, so there is no new user-facing configuration or change to saved
state. Compare 200/500/2000 real-scene index-versus-linear query timings with
the optional heavy benchmark; a data structure alone does not prove an FPS gain.

## Optional device controls

`puzzle_config.device_input` adds `JigsawDeviceInputSettings`. Both `enable_touch` and `enable_controller` default to `false`, so existing scenes require no changes.

- **Touch:** one finger selects/drags/releases with the same Free/Mosaic snap logic as a mouse. A second finger cancels the drag and starts camera pan and pinch zoom; lifting one finger cannot restart a drag until all fingers are released. Control `touch_drag_threshold_px` and `touch_pinch_and_pan`. Disable Project Settings → Input Devices → Pointing → **Emulate Mouse From Touch** to avoid duplicate events in host UI.
- **Gamepad / Steam Deck:** enabling the controller creates a screen-space pointer that ignores mouse input. Standard Godot/SDL joypad controls on `joypad_device=0`: left stick cursor, A hold/release, B cancel, X toggle connected-group selection, Y reference preview, shoulder buttons rotate, triggers zoom, right stick pan. Set `use_joypad_defaults=false` to disable raw joypad controls and use only the optional host-owned InputMap action fields. Configure `cursor_speed_px`, `stick_deadzone`, `camera_pan_speed_px` and host action names for custom controllers.
- **Integration:** use `board.set_interaction_enabled(false)` while a menu or HUD owns input. The board does not add global InputMap actions, create transport services or serialize virtual pointer/touch state.

```gdscript
var config: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
config.device_input.enable_controller = true
config.device_input.enable_touch = true
$JigsawBoard.configure(config)
```

`tests/test_device_input.gd` exercises synthetic controller buttons, drag/release, camera movement, touch pinch and cancellation. Device-specific drivers, display density, frame pacing and platform export still require manual testing before claiming hardware compatibility.

## InputMap aliases and reduced motion

For alternative keyboard/gamepad shortcuts, first register actions in **your game's Project Settings → Input Map**, then put their names in the Camera and Gameplay settings. JigsawG does not register global actions and gracefully ignores empty/unregistered action names.

```gdscript
config.camera.focus_board_action = &"my_game_focus_board"
config.camera.zoom_in_action = &"my_game_zoom_in"
config.gameplay.rotate_action = &"my_game_rotate"
config.gameplay.preview_action = &"my_game_reference"
```

Existing Home / End / F / P, mouse wheel and right-click shortcuts remain available. The rotate action targets the group under the **current pointer**. Full keyboard-only piece selection/movement remains future work; the opt-in virtual controller cursor is now available.

**Feedback → Reduce Motion** disables the built-in motion adapter, camera/drag smoothing and temporary tint flashes. The runtime override applies immediately and cancels built-in piece display/tint tweens without changing logical transforms or saved groups:

```gdscript
$JigsawBoard.set_reduced_motion(true)
print($JigsawBoard.is_reduced_motion())
```

`rebuild()` restores the configured Feedback Resource value. Motion/event signals are still emitted. Host-owned custom reaction animations are outside the plugin's control and should consult `is_reduced_motion()` themselves.

## Camera settings

`JigsawCameraSettings` owns:

- `enable_camera_navigation`
- `invert_background_pan`
- `auto_fit_camera`
- `initial_focus` (Auto, All Pieces or Board)
- `large_puzzle_threshold` (200 pieces by default)
- `focus_board_key` (Home by default)
- `overview_key` (End by default)
- `focus_selection_key` (F by default; KEY_NONE disables it)
- `focus_board_action`, `overview_action`, `focus_selection_action` (optional host InputMap actions)
- `zoom_in_action`, `zoom_out_action` (optional host InputMap actions)
- `selection_focus_padding` (margin around the selection, measured in native piece sides)
- `selection_focus_max_zoom` (maximum zoom when focusing selected pieces; default 2.0)
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
- `reduce_motion` (default `false`, cancel built-in visual tween effects and use immediate navigation)
- `connect_animation_duration`
- `connect_tint`
- `pickup_tint`
- `enable_failure_feedback`
- `failure_tint`
- `failure_animation_duration`
- `motion_adapter` (optional `JigsawMotionAdapter`; rotation/arrangement timing and easing or custom subclass)

For project-specific sound, particles, UI or scoring, prefer the reaction/event API instead of extending built-in feedback. For **motion** effects, assign a `JigsawMotionAdapter` Resource to `feedback.motion_adapter`. The default (null) preserves instantaneous movement; the supplied adapter interpolates piece rendering independently of logical transforms. Custom Resources can override `animate(board, motion)`; `motion_requested` is the corresponding public signal. See [Events & Reactions](EVENTS_AND_REACTIONS.md).

## Reactions

`JigsawPuzzleConfig.reactions` can contain:

- `JigsawAudioReaction` (sound)
- `JigsawSpawnSceneReaction` (scene/VFX)
- `JigsawPlayAnimationReaction` (host `AnimationPlayer`)
- `JigsawCallMethodReaction` (invoke a host Node method)
- any custom Resource derived from `JigsawReaction`

The board snapshots the active reaction list when configuration is applied. Editing the Resource during a running puzzle takes effect on the next `rebuild()`, `apply_configuration()` or `configure()`.

## Create a puzzle in the Inspector

1. Add a `JigsawBoard` to a 2D scene.
2. Create **New JigsawPuzzleConfig** in **Puzzle Config**.
3. Assign `puzzle_texture`.
4. Choose **Manual** with `columns` and `rows`, or **Auto** with `target_piece_count`.
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
| `fit_view()` | Recenter on all scattered pieces; returns false without a camera |
| `focus_board()` | Frame only the assembly board for readable large puzzles |
| `focus_selection()` | Frame the last clicked or currently Ctrl-selected connected groups; does not move pieces or work during a drag |
| `is_generating()` | Whether a batched generation is in progress |
| `get_generation_progress()` | Generated and total piece counts as `Vector2i` |
| `toggle_reference_preview()` | Open/close the reference overlay |
| `is_reference_preview_visible()` | Read overlay state |
| `set_ghost_guide_visible(visible)` | Runtime ghost toggle, including Mosaic mode |
| `set_ghost_guide_opacity(opacity)` | Runtime ghost alpha |
| `is_ghost_guide_visible()` | Read ghost visibility |
| `get_connected_group_count()` | Query active connected groups |
| `get_locked_piece_count()` | Query locked Mosaic slots |

**Progress semantics:** Free = (total pieces − connected group count) / (total pieces − 1); Mosaic = locked pieces / total pieces. This is assembly progress, not a timer or board-area metric. Runtime guide overrides reset to config defaults on rebuild. These controls do not mutate shared Resources.

### HUD, pause menu and framing

Connect progress once; Free mode reports successful joins while Mosaic reports locked slots:

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    board.progress_changed.connect(_on_progress)
    _on_progress(board.get_progress())

func _on_progress(value: float) -> void:
    $HUD/ProgressBar.value = value * 100.0

func show_pause() -> void:
    board.set_interaction_enabled(false)
    $PauseMenu.show()

func hide_pause() -> void:
    $PauseMenu.hide()
    board.set_interaction_enabled(true)

func show_all_pieces() -> void:
    board.fit_view()

func focus_assembly() -> void:
    board.focus_board()
```

You can also call `toggle_reference_preview()`, `set_ghost_guide_visible(bool)` and `set_ghost_guide_opacity(float)`. Runtime overrides do not change the shared configuration and reset when the Board rebuilds.

### Resource ownership and integration limits

- Reuse external Gameplay, Appearance, Camera and Feedback Resources when presets share their settings; do not mutate shared Resources in response to a running session.
- Keep score, timers, achievements and save slots in host Nodes or autoloads. Reaction Resources should be stateless.
- Use `get_piece_node(piece_id)` as a **read-only** attachment point for VFX. Do not modify piece transforms, geometry, group IDs or UVs from host scripts.
- `rebuild()` replaces the generated piece Nodes. Do not keep references to them across regeneration.
- A single Board uses the viewport's active `Camera2D` and `_unhandled_input`. Multiple interactive Boards in **one viewport** are not an isolated input/camera setup; use separate `SubViewport` instances or enable interaction on only one Board at a time.
- A saved state checks geometry/grid/seed settings but does **not** cryptographically identify image contents. Associate save slots with your own puzzle/image ID.
- `piece_material` is shared across generated pieces. For different piece-specific shader values, use CanvasItem instance shader parameters; null leaves the default renderer.
- Gameplay input is currently focused on mouse and keyboard; touch/controller paths still need project-specific verification. Test performance and memory on target hardware.

For custom host reactions, audio, animation, and event contracts see [Events & Reactions](EVENTS_AND_REACTIONS.md).

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
- `get_artwork_detail_info()` — native pixels per piece and recommended source size
- `is_completed()`

For external effects and game logic, use the rich semantic signals and `JigsawPuzzleEvent` API documented in [Events & Reactions](EVENTS_AND_REACTIONS.md).
