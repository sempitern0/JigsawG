# Changelog

All notable changes to JigsawG will be documented here.

JigsawG is currently in preview; public API may still evolve before 1.0, but breaking changes should be called out explicitly.

## 0.3.0-dev

### Added
- Resource-first `JigsawPuzzleConfig` API with Gameplay, Appearance, Camera and Feedback subresources.
- Procedural complementary Bézier puzzle-piece geometry.
- Free and Mosaic gameplay modes.
- Connected-group drag, merge and 90° group rotation.
- Seeded, non-overlapping shuffle strategies.
- Ghost-board guide and fullscreen reference preview.
- Smooth cursor-centered zoom, background pan and drag-edge camera scrolling.
- Rich semantic `JigsawPuzzleEvent` API and umbrella `event_emitted` signal.
- Specific rich signals for puzzle lifecycle, drag, placement, group connection, rotation and preview state.
- Reusable `JigsawReaction` Resource extension point.
- Built-in `JigsawAudioReaction` and `JigsawSpawnSceneReaction`.
- Public query helpers for piece/group state used by external VFX and UI.
- Headless smoke tests for geometry, icon UID loading, event data and board event contract.

### Changed
- `JigsawBoard` exposes only `puzzle_config` in the Inspector.
- Plugin icon is bundled inside the addon and resolved through Godot's native UID/import mechanism.
- Interaction animations and custom reactions are separated from core puzzle mechanics.
- Plugin metadata version bumped to `0.3.0-dev`.

### Removed
- Unused `group_placed` signal, which was never emitted.
- Direct Board Inspector exports superseded by Resource configuration.

### Known preview limitations
- Full regression/performance validation for very large puzzles is still pending.
- Mouse/keyboard is the documented input path; touch/controller support is not yet certified.
- Save/load of in-progress assembly is not yet provided.
- Example artwork must have redistribution rights verified before a public packaged release.
