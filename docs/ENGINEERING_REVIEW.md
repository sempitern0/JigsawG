# Senior engineering review — JigsawG 0.2 preview

Review date: 2026-10-09. Scope: addon source, Resources, Godot scene, package icon, tests, README, templates and license metadata. This is a source audit plus incremental fixes, not a Godot runtime certification.

## Assessment
The developer-facing model (one `JigsawBoard.puzzle_config`, nested Resources, optional camera, signals) is a viable public API. Shared canonical Bézier edge profiles and connected-group semantics provide a useful foundation. The project is **not yet qualified as stable**.

## Release blockers (P0/P1)
- **Regression coverage:** existing tests check shared vertical seams only and are not run in CI. Add horizontal seam invariants, rotational group alignment, Mosaic slot locking, completion uniqueness, deterministic shuffle and rebuild lifecycle tests.
- **Lifecycles & ownership:** puzzle generation and interaction remain in one >600-line script. More importantly, the preview, concurrent feedback Tweens, multiple Board instances and rebuild while dragging require execution tests.
- **Content licensing:** `examples/images/wallpaperflare.com_wallpaper.jpg` has no verified redistribution rights in the repository. Do not publish releases bundling that image until provenance/permission is documented; replace it with an original or clearly licensed example. This applies separately from the MIT source-code license.
- **Clean install:** independently import `addons/jigsawg` into a fresh Godot 4.7 project and verify the Board icon, typed resources, plugin initialization, and generated checkerboard.
- **Performance:** stress/profile 80/300 pieces, 4K/8K imagery, pan/zoom/rotation and repeated rebuilds. Memory usage is influenced by source texture and temporary images, while geometry triangle count scales with `bezier_detail`.

## Medium priority
- Configure a CI pipeline with Godot headless import/test for every PR, then add a release smoke test. An editor-only parser pass is not enough.
- Keep public signals stable and document exact semantics; remove unused signals or implement them deliberately.
- For multiple boards, avoid global input contention (right click, preview key, camera ownership). Consider explicit active-board/input routing.
- Consider extracting Input/Camera controller and group graph from `jigsaw_board.gd` after tests are established; avoid a behavior-changing rewrite right before release.
- Define API stability and backwards-compatibility policy for the resource schema before 1.0.

## Completed for this review
- README restructured with honest Preview badges, installation, API examples, configuration, limitations and contribution flow.
- Editor addon icon bundled and referenced through `res://addons/jigsawg/icon.svg`; no dependency on host project's root icon.
- Source-image dimension guard before allocation and generation to avoid invalid tiny pieces.
- Preview-opening drag cancellation to avoid stuck active-drag state.
- Fixed canonical default depth in the existing seam regression test.
- Engineering/release checklist and issue/contributing templates updated.

## Suggested release plan
1. **0.2.0-preview:** publish only after clean-install and basic Free/Mosaic/Rotation QA; remove/replace unlicensed artwork.
2. **0.2.0-beta:** add geometry/group/rotation CI tests, deterministic shuffle profiling, screen recording of UX.
3. **0.2.0 stable:** pass 300-piece target-device performance budget, lifecycle tests, documented compatibility and packaging review.

Do not cut the stable tag merely because the project opens without errors in the author's development scene.