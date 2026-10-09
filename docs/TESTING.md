# JigsawG — release validation

## Headless regression command

Run the Godot 4.7.2 editor import and all fast `tests/test_*.gd` tests with one command:

```bash
python3 scripts/ci/run_tests.py --godot /path/to/godot
python3 scripts/ci/run_tests.py --godot /path/to/godot --test test_camera_selection_focus
```

The runner rejects non-zero exits, script/import errors and missing PASS markers. The separate `benchmark_large_puzzles.gd` is excluded; run it on named hardware for actual performance evidence. The GitHub Actions file `.github/workflows/godot-regression.yml` still requires a verified green run before CI success can be claimed.

## Plugin startup and icon (Godot 4.7.2)

- [ ] Start the editor with the JigsawG plugin enabled; `plugin.gd` must resolve both the board script and icon by UID without parse/import errors.
- [ ] Verify the custom JigsawBoard icon depicts the puzzle-piece and right-hand gear.
- [ ] Copy only `addons/jigsawg` to a fresh Godot project; after Godot imports the addon, the icon UID must resolve without any root `res://icon.svg`.
- [ ] Run `godot --headless --path . --script res://tests/test_plugin_icon.gd` and confirm the UID resolves to a valid Texture2D.

## Configuration
- [ ] Install only `addons/jigsawg` in a clean Godot project; JigsawBoard appears in Add Node.
- [ ] JigsawBoard Inspector exposes only `Puzzle Config` (no duplicated exported settings).
- [ ] Create a root JigsawPuzzleConfig, including texture and four nested Resources.
- [ ] Load `examples/puzzle_lab.tscn`; verify it uses `examples/configs/standard_puzzle.tres`.
- [ ] Confirm all appearance, camera, gameplay and feedback options take effect after `rebuild()`.
- [ ] Verify a missing subresource receives defaults without null access or stale state.
- [ ] Share one .tres across multiple board instances; no Resource is mutated.
- [ ] Use `configure(config)` and `apply_configuration()` and confirm both reset game progress.
- [ ] Test migration from an old scene by moving legacy board exports into a .tres.

## Gameplay regression
- [ ] 5x4, 10x8 and 20x15 generate correct mirrored Bézier connections.
- [ ] Test Classic, Rounded, Angular, Compact, Mixed and Organic families with low/high variation.
- [ ] Run `godot --headless --path . --script res://tests/test_organic_shapes.gd` and verify complementary Organic contour samples and variation.
- [ ] Confirm legacy Classic silhouettes and rejection of incompatible profile snapshots.
- [ ] Run `godot --headless --path . --script res://tests/test_shape_profiles.gd`.
- [ ] Left drag, group union and completion work in Free mode.
- [ ] Run `godot --headless --path . --script res://tests/test_group_model.gd` to verify independent connected components, atomic restores, snapping neighbors and rotated offsets.
- [ ] Run `godot --headless --path . --script res://tests/test_group_integration.gd` to verify Board selection, merge signals, rotation, progress and resumed groups.
- [ ] Confirm the dragged group's ID survives joins, and saved `piece_group_ids` remain compatible.
- [ ] Pieces lock in Mosaic only in the correct position and orientation.
- [ ] Right-click rotation and shuffle at 90° multiples preserve group connections.
- [ ] Empty-space left press does not start panning until both `background_pan_delay_ms` and `background_pan_threshold_px` are satisfied.
- [ ] Quick clicks on empty space clear selection without visible camera movement.
- [ ] Ctrl+click adds/removes complete connected groups from multi-selection.
- [ ] After a plain click, the first Ctrl+click immediately highlights the piece (not toggles off a hidden selection).
- [ ] Turning Ctrl selection off removes the highlight, while a plain click stays unhighlighted.
- [ ] Normal single click produces no lingering highlight, click-without-drag does not trigger failure feedback, and actual drag highlights only while moving.
- [ ] Dragging distant Ctrl-selected groups packs them without overlap while preserving rigid already-connected groups and their rotations.
- [ ] Auto grid chooses balanced rows/columns near the target piece count; manual dimensions remain unchanged.
- [ ] Run `godot --headless --path . --script res://tests/test_selection_and_auto_grid.gd`.
- [ ] Run `godot --headless --path . --script res://tests/test_hit_index.gd` (200/500/2000 broad phase and deterministic order).
- [ ] Run `godot --headless --path . --script res://tests/test_hit_index_board.gd` (Ctrl priority, movement, rotation, animation, save/restore).
- [ ] Compare indexed and full-scan queries in `tests/benchmark_large_puzzles.gd` on actual hardware; record before/after times.
- [ ] Run `godot --headless --path . --script res://tests/test_motion_adapter.gd`; verify animated rotation and packed selection with the demo's Motion Adapter.
- [ ] Confirm that `capture_state()`, `restore_state()`, snap and group membership are unaffected by presentation tweens.
- [ ] Confirm custom Motion Adapter subclasses receive motion context and can animate without changing the logical transforms.
- [ ] Dragging any selected group moves every selected group together and preserves their internal connections.
- [ ] Releasing a multi-selection can snap selected groups independently without breaking already connected groups.
- [ ] Chaotic shuffle produces deterministic results for the same seed, avoids overlaps, and does not visibly align pieces to a regular grid.
- [ ] Highlight enable/color/width/shadow settings update all selected pieces consistently.
- [ ] Preview shortcut, ghost image transparency and full-image overlay render correctly.
- [ ] Run `godot --headless --path . --script res://tests/test_camera_selection_focus.gd`; verify last-click focus, multi-group bounds and configured zoom limit.
- [ ] After selecting a distant piece, press F to return to it without moving pieces or leaving a persistent single-selection outline.
- [ ] Ctrl-select detached groups and press F; no selection or a current drag must leave the camera unchanged.
- [ ] Camera drag follows the pointer smoothly without visible jumps.
- [ ] `smooth_pan=false` restores direct camera movement.
- [ ] `pan_smoothing` visibly changes responsiveness without changing final pan distance.
- [ ] Smooth wheel zoom keeps the cursor anchor stable.
- [ ] Edge auto-pan accelerates/decelerates smoothly and stops after leaving the edge zone.
- [ ] `edge_scroll_smoothing` changes acceleration without changing configured maximum speed.
- [ ] Restricted camera margins still clamp both actual and target camera positions.
- [ ] Enabling both Camera2D position smoothing and JigsawG smooth_pan produces the documented warning.
- [ ] Style edge alpha, connector depth, texture sampling and profile resolution work.
- [ ] Change Appearance → Piece Edge Color on a dark photographic puzzle and confirm the new tint appears without changing snap geometry; verify defaults reproduce legacy contours.
- [ ] Assign a CanvasItemMaterial through Appearance → Piece Material and confirm every generated piece uses it; null preserves existing visuals.
- [ ] Connect success/failure/pickup animations use JigsawFeedbackSettings.
- [ ] `capture_state()` followed by `restore_state()` restores piece positions, rotations, group membership and Mosaic locks.
- [ ] Incompatible state (grid/source size/seed/silhouette count) is rejected without mutating the current board.
- [ ] `capture_resume_config()` can be saved with ResourceSaver and loaded/configured later to resume the puzzle.
- [ ] Run `godot --headless --path . --script res://tests/test_state_and_selection.gd`.

## Event and reaction API
- [ ] `PUZZLE_STARTED` fires once after a valid board generation.
- [ ] Rebuilding an existing board emits `PUZZLE_RESET` followed by a fresh `PUZZLE_STARTED`.
- [ ] Pickup/release emits drag started/finished with the correct primary piece/group and `metadata.selected_piece_ids` for multi-selection.
- [ ] Opening preview during drag emits `PIECE_DRAG_CANCELLED` and leaves no selected/z-raised piece.
- [ ] Mosaic success/failure emits `PIECE_PLACED` / `PIECE_PLACEMENT_FAILED`.
- [ ] Free-mode snap/failure emits `GROUP_CONNECTED` / `GROUP_CONNECTION_FAILED`.
- [ ] Right-click rotation emits `GROUP_ROTATED` with group members and quarter turns.
- [ ] Completion emits the legacy `puzzle_completed`, rich `puzzle_finished` and umbrella `event_emitted` exactly once.
- [ ] Loading a config with `resume_state` emits `PUZZLE_STARTED` followed by `PUZZLE_STATE_RESTORED`.
- [ ] `JigsawReaction.event_mask` filters correctly; empty mask receives all event types.
- [ ] `JigsawAudioReaction` cleans up one-shot players after playback.
- [ ] `JigsawSpawnSceneReaction` places Node2D roots at event.world_position and calls optional `setup_jigsaw_event`.
- [ ] `ParentMode.PRIMARY_PIECE` attaches spawned Node2D effects to the source piece.
- [ ] `auto_free_after` removes temporary spawned scenes without leaks.
- [ ] Run `godot --headless --path . --script res://tests/test_event_api.gd`.

## Host-game integration
- [ ] `get_progress()` returns 0 for a newly generated 2×2 Free board and updates after successful joins.
- [ ] `progress_changed(progress)` emits on generation, restoration and successful Free/Mosaic progress.
- [ ] Disabling `set_interaction_enabled(false)` cancels active drags, stops camera input and does not reset progress.
- [ ] Enabling interaction restores normal board controls without rebuilding.
- [ ] `fit_view()` gracefully returns false without an active Camera2D and recenters when one is active.
- [ ] Reference toggle and ghost visibility/opacity can be controlled by an external HUD; rebuild restores Resource defaults.
- [ ] `JigsawPlayAnimationReaction` plays an AnimationPlayer clip found relative to the Board.
- [ ] `JigsawCallMethodReaction` invokes a no-argument host method and an event-argument method.
- [ ] Invalid Resource target paths do not crash puzzle gameplay.
- [ ] Run `godot --headless --path . --script res://tests/test_public_integration.gd`.

## 200/500/2000 stress scenarios

- [ ] Run `godot --headless --path . --script res://tests/test_large_scatter_layout.gd` for exact layout count, deterministic seeding and collision-free footprints.
- [ ] Run `godot --headless --path . --script res://tests/benchmark_large_puzzles.gd` for actual Godot node generation, camera fit and cancellation at **200, 500 and 2000 pieces**.
- [ ] Run `godot --headless --path . --script res://tests/test_generation_batching.gd` to confirm piece-batch progress (starting at zero), old-job cancellation and synchronous compatibility.
- [ ] Run `godot --headless --path . --script res://tests/test_batch_camera_framing.gd`; assert a complete visible Mosaic guide and correct zoom/center **before** the first piece batch, no unexpected changes mid-batch, camera opt-out and cancellation before the first frame.
- [ ] In the actual viewport, start a 2000-piece Mosaic puzzle with a remote initial camera position and batch size 64–128. Confirm the complete guide is visible first, pieces appear progressively, and camera fitting after completion follows Camera settings.
- [ ] Compare `generation_batch_size = 0` (synchronous) and `96` (yielding) with a progress HUD and verify that a new `configure()` cancels the old build.
- [ ] At 2000 pieces, test `focus_board()` / Home versus `fit_view()` / End on 1080p and 1440p screens.
- [ ] Test Chaotic and Around Board scatter, grouping, rotated drag and snapping at 2000 pieces.
- [ ] Record build time, 1% low FPS, draw calls, allocation memory and pointer input latency on target hardware. Pure planner results alone do **not** measure scene-build performance.
- [ ] Verify that `get_artwork_detail_info()` reports real source pixels per piece and the warning suggests adequate artwork resolution.
- [ ] Verify zoomed-in Organic tabs have smooth asymmetrical profiles, without self-intersections.
- [ ] Verify that too-small source textures reject unresolvable 2000-piece grids without a crash.

## Publication
- [ ] Godot parser and import logs show no GDScript warnings/errors.
- [ ] Measure large-image memory and the performance of a 300-piece puzzle.
- [ ] Verify plugin.cfg metadata, license and the packaged addons directory.
- [ ] Validate all Markdown links after documentation consolidation and keep installation instructions within the root README.
- [ ] Confirm example image redistribution rights and replace unlicensed third-party media before packaging.
- [ ] Publish a test release only after the checklist has been executed.
