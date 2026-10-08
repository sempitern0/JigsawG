# JigsawG manual release validation

Godot 4.7, GL Compatibility, mouse and keyboard. Use a real high-resolution photo for visual tests. The authoring environment does not run Godot; mark each check only after executing it locally.

## Core
- [ ] Open the project with the plugin enabled; no GDScript parse errors, missing image dependency or GLES3 2D MSAA warning.
- [ ] Run 5x4, 10x8 and 20x15. Generated pieces all use matching Bézier edges.
- [ ] Connect two groups independently in Free mode; rotate one group and verify that incompatible orientations cannot snap.
- [ ] Rotate the group back to the same orientation as its neighbor, position it at the correct rotated offset, then merge the groups.
- [ ] Complete a small Free-mode puzzle in a consistent orientation and verify that completion emits exactly once.
- [ ] In Mosaic, correctly place a piece at 90°, 180° and 270°: none may lock. Rotate to 0°, align it and verify that it locks.
- [ ] Right-click on a piece rotates by 90°, including when it is already part of a group.
- [ ] Rotate a piece while left-dragging; it must not jump away from the cursor.
- [ ] Test portrait and landscape images; rotated non-square pieces must not collide with shuffled neighbors.
- [ ] Random 90° shuffle is reproducible for the same seed and is disabled when the corresponding property is false.
- [ ] Confirm free camera pan, zoom, edge scrolling, and P toggle still work while rotation is on.

## Plugin embedding
- [ ] Copy only `addons/jigsawg` into a fresh Godot project; enable the plugin and add JigsawBoard via Add Node.
- [ ] Create `JigsawGameplaySettings.tres` and `JigsawAppearanceSettings.tres`, assign them on two separate boards and check both apply identical configuration.
- [ ] Change a Resource property, call `rebuild()` and verify that updated values take effect.
- [ ] Remove Resources and confirm the board's directly exported fields work.
- [ ] Connect to `group_rotated`, `pieces_connected` and `puzzle_completed` from a host game scene.
- [ ] No hardcoded path to `examples/images`, and no external addons required.
- [ ] Test repeated `rebuild()`, game-mode switches, fullscreen preview and shuffled rotation without leaked nodes or stale connections.

## Publishing
- [ ] Validate package metadata and license attribution.
- [ ] Perform parse/headless tests and inspect performance for at least 300 pieces.
- [ ] Attach images/video of Free/Mosaic/Rotation in a release.
- [ ] Tag only after regression test results and documentation match the shipped package.
