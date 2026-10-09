# JigsawG — release validation

The resource-first refactor requires local Godot 4.7 verification. The authoring environment cannot run Godot.

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
- [ ] Preview shortcut, ghost image transparency and full-image overlay render correctly.
- [ ] Camera drag, smooth wheel zoom, auto-pan and camera margins work.
- [ ] Style edge alpha, connector depth, texture sampling and profile resolution work.
- [ ] Connect success/failure/pickup animations use JigsawFeedbackSettings.

## Publication
- [ ] Godot parser and import logs show no GDScript warnings/errors.
- [ ] Measure large-image memory and the performance of a 300-piece puzzle.
- [ ] Verify plugin.cfg metadata, license and the packaged addons directory.
- [ ] Publish a test release only after the checklist has been executed.
