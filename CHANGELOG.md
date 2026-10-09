# Changelog

All notable changes to JigsawG will be documented here.

JigsawG is currently in preview; public API may still evolve before 1.0, but breaking changes should be called out explicitly.

## Unreleased (public integration improvements)

### Added
- Optional shared piece CanvasItem Material/ShaderMaterial via JigsawAppearanceSettings, without subclassing JigsawPiece.
- Public Board facade for HUD progress, interaction pause, reference/ghost controls and camera refit.
- `progress_changed` and `interaction_enabled_changed` signals.
- `JigsawPlayAnimationReaction` and `JigsawCallMethodReaction` to reuse host-scene functionality without Board overrides.
- Public API smoke test and host-game integration guidance (consolidated into the Resource API and Events references).

### Notes
- Added `docs/ROADMAP.md` to prioritize validation, large-puzzle ergonomics, accessibility and release readiness, and root `AGENTS.md` for AI-assisted development and regression guidance.
- Accessibility: host-defined InputMap shortcut aliases, reduced-motion Feedback preset and live toggling. Built-in visual tweens are cancelled without altering snap and save semantics.
- Test maintenance: explicit local/script types in the recent nine GDScript regression scripts to avoid Variant type inference errors in Godot.
- Accessibility: optional Free/Mosaic extra snap tolerance and viewport-pixel contour picking margin under Gameplay → Accessibility. Existing defaults are unchanged; exact polygon hits and orientation rules remain authoritative. Added broad-phase and end-to-end regression scripts.
- Batched puzzle generation now preframes and displays the complete mosaic before the first node batch, then restores configured final camera fitting. Host-controlled cameras remain opt-out. Added a regression for first-frame framing and cancellation.
- Readability: added configurable RGBA piece contour color without changing the default render style.
- Auto piece-count grid, Organic connectors, standalone group graph, optional motion adapter, cancellable batch generation and improved large-puzzle camera/chaotic scatter are documented in their respective references.
- Consolidated overlapping advanced-guide examples into the Resource API and Events guides, and streamlined README navigation.
- Existing saved-state schema and legacy shape/gameplay defaults remain compatible.
- Godot editor/runtime regression validation remains required before tagging a stable release.

## 0.4.0-dev

### Added
- Empty-board pan grace: configurable delay and screen-space drag threshold reduce accidental camera movement.
- Ctrl+click multi-selection of complete connected groups, with joint dragging and selection helper API.
- Chaotic shuffle mode using deterministic continuous random placement rather than visible grid slots.
- `JigsawPuzzleState` Resource plus `capture_state()`, `restore_state()` and `capture_resume_config()` for resumable puzzles without a built-in save UI.
- Configurable selection highlight outline, color, width, shadow color and offset.

### Changed
- Drag lifecycle rich events include `metadata.selected_piece_ids` for multi-selection-aware integrations.
- Mosaic release can evaluate several selected pieces in one drag.
- Free-mode snapping can process several selected groups without breaking group rigidity.
- Plugin metadata version bumped to `0.4.0-dev`.

## 0.3.0-dev

### Added
- Configurable smooth camera pan with target interpolation and eased edge-scroll acceleration/deceleration.
- `JigsawSpawnSceneReaction` Primary Piece parenting and optional automatic cleanup for no-code drag/VFX workflows.
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
- Public documentation now focuses on installation, Resources, events/reactions and release validation; internal engineering/architecture notes were removed.
- No-code reaction documentation includes step-by-step Inspector recipes.
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
- State capture/restore is provided; host-game save-slot UI and persistence policy are not.
- Example artwork must have redistribution rights verified before a public packaged release.
