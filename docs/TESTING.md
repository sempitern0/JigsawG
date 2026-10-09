# JigsawG — release validation

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
- [ ] Left drag, group union and completion work in Free mode.
- [ ] Pieces lock in Mosaic only in the correct position and orientation.
- [ ] Right-click rotation and shuffle at 90° multiples preserve group connections.
- [ ] Empty-space left press does not start panning until both `background_pan_delay_ms` and `background_pan_threshold_px` are satisfied.
- [ ] Quick clicks on empty space clear selection without visible camera movement.
- [ ] Ctrl+click adds/removes complete connected groups from multi-selection.
- [ ] Dragging any selected group moves every selected group together and preserves their internal connections.
- [ ] Releasing a multi-selection can snap selected groups independently without breaking already connected groups.
- [ ] Chaotic shuffle produces deterministic results for the same seed, avoids overlaps, and does not visibly align pieces to a regular grid.
- [ ] Highlight enable/color/width/shadow settings update all selected pieces consistently.
- [ ] Preview shortcut, ghost image transparency and full-image overlay render correctly.
- [ ] Camera drag follows the pointer smoothly without visible jumps.
- [ ] `smooth_pan=false` restores direct camera movement.
- [ ] `pan_smoothing` visibly changes responsiveness without changing final pan distance.
- [ ] Smooth wheel zoom keeps the cursor anchor stable.
- [ ] Edge auto-pan accelerates/decelerates smoothly and stops after leaving the edge zone.
- [ ] `edge_scroll_smoothing` changes acceleration without changing configured maximum speed.
- [ ] Restricted camera margins still clamp both actual and target camera positions.
- [ ] Enabling both Camera2D position smoothing and JigsawG smooth_pan produces the documented warning.
- [ ] Style edge alpha, connector depth, texture sampling and profile resolution work.
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
- [ ] `JigsawReaction.event_mask` filters correctly; empty mask receives all event types.
- [ ] `JigsawAudioReaction` cleans up one-shot players after playback.
- [ ] `JigsawSpawnSceneReaction` places Node2D roots at event.world_position and calls optional `setup_jigsaw_event`.
- [ ] `ParentMode.PRIMARY_PIECE` attaches spawned Node2D effects to the source piece.
- [ ] `auto_free_after` removes temporary spawned scenes without leaks.
- [ ] Run `godot --headless --path . --script res://tests/test_event_api.gd`.

## Publication
- [ ] Godot parser and import logs show no GDScript warnings/errors.
- [ ] Measure large-image memory and the performance of a 300-piece puzzle.
- [ ] Verify plugin.cfg metadata, license and the packaged addons directory.
- [ ] Publish a test release only after the checklist has been executed.
