# JigsawG: foundation and migration notes

## Legacy audit
The legacy plugin lives under `Barebone/addons/puzzle_generator` and is named `ConnectaPuzzle`. Useful ideas to keep: editor-registered 2D node, configurable dimensions, complementary piece shapes, shader-based borders and emitted connection signals. Avoid carrying over the OmniKit/Draggable2D dependencies, 81 fixed mask PNGs and Area2D-based snap detection scanning every piece after each release.

## Experimental implementation
JigsawBoard generates exactly `columns * rows` pieces. Each adjacent edge shares one deterministic profile, and pieces receive a polygon-clipped part of the input image. A fallback diagnostic checkerboard is available if no texture is provided. Piece groups move together; snap candidates are only topological neighbors, and an accepted connection merges the two independent groups. The editor plugin registers the `JigsawBoard` custom type.

Signals: `puzzle_generated`, `piece_picked`, `piece_released`, `connection_failed`, `pieces_connected`, and `puzzle_completed`. The selected-piece outline and drag shadow are provisional visual feedback.

## Manual verification
Create a 2D scene containing Camera2D (enabled) and JigsawBoard; enable the plugin and run. Add sample source files to `examples/images`. Verify generation, dragging, selection, correct/incorrect neighbor snap, merging two separately assembled groups and complete puzzle detection. Repeat with 5x4, 10x8, 20x15, landscape/portrait/transparent images.

## Production roadmap
This is untested against a running Godot editor in the present environment. The CPU-side per-pixel masking should be replaced with a cached GPU masking pipeline for high counts or large source images. Profiles currently vary tab amplitude, not the whole silhouette contour. Add multi-profile presets, camera pan/zoom, dynamic fit, touch input, animation/tween and particles/audio, save/load, performance tests and automated group-merge tests. Test exact geometry and clipping across non-integral source dimensions.


## Iteration 2: shared seam geometry
The previous prototype inverted the edge polarity when assigning upper/left neighbors, accidentally allowing a pair of tabs or a pair of slots to face one another. The new `jigsaw_geometry.gd` module generates one canonical edge profile per seam and walks it in reverse for the adjoining piece. Tabs now use piecewise cubic Bézier shoulders, neck, undercut head and depth/profile variations, rather than a raised sine curve. A single descriptor is shared on both sides, so geometry is identical in solved-space coordinates. The next major improvement should be cached antialiased GPU masks: the original Barebone shader/mask design is valuable for rendering, but its 81 pre-rendered PNG masks impose fixed silhouette combinations.

Regression entry point (requires Godot 4.7): `godot --headless --path . --script res://tests/test_geometry.gd`. The test checks matching vertical seams across 8 profiles and both polarities. It has not been run in the current environment.

## Returning legacy features in order
1. **Foundation:** exact complementary geometry, alpha/visual edges, deterministic snap, and robust group merging. Confirm regression tests and a real editor run before widening scope.
2. **PuzzleMode:** `Free` (group-based puzzle assembly) and `Mosaic` (pieces placed in their matching board sockets with configurable reference-opacity).
3. **ShuffleMode:** `AroundTheViewport`, `Center`, `Bottom`, preserving seed, safe margins and piece non-overlap where possible.
4. **SpawnDistributionMode:** `Random` and `Radial`, designed as placement strategies independent of the puzzle's logical graph.
5. **Juice:** distinct VFX/audio for pickup, hover, release, missed join, single-piece join, group merge and completion, using existing signals without hardwiring effects to mechanics.

Do not conflate difficulty with piece count: profile family count, rotation, reference-image visibility, false-positive decoy profiles, available tray area and snap tolerance are separate settings. Keep default behavior deterministic and guarantee physically matching seams even with maximum profile diversity.


## Iteration 3: image fidelity and large-board camera

`JigsawPiece` no longer rasterizes each shape into a separate `ImageTexture` using `Geometry2D.is_point_in_polygon()`. `JigsawBoard` creates one source `ImageTexture` with mipmaps and passes it to all pieces. Each piece draws its canonical Bézier polygon with UV coordinates in full-image space. This removes per-pixel CPU masking at build time and preserves original texels for zoomed-in viewing. The sandbox enables 4x MSAA for polygon contour edges and adds understated directional rim and selected-piece shadow. Source quality cannot exceed the original image resolution; for a 300-piece puzzle, test photographs at several megapixels and profile the cost of triangles, texture memory and draw calls.

Camera: mouse wheel zoom around the world point under the cursor, middle-mouse drag pan, and proportional edge-pan while carrying a piece. Configurable zoom limits, wheel factor, edge activation band and pan speed. Fit uses the initial scattered-piece world bounds. Bounds deliberately leave extra space outside the board but are static during play.

**Mandatory manual checks:** inspect piece geometry for transparent images; verify concave polygons triangulate without self-overlap; zoom over an off-center seam (point under cursor must remain stable); scroll to edges during drag and complete a snap; drag a previously joined group; test 5x4, 10x8 and 20x15 with a high-resolution real image. Need to run and profile inside Godot before calling this production-ready. Consider batching by group or MultiMesh-like approaches only after actual profiling.


## Iteration 4: image feedback, navigation and shuffle
Reference images from October 8 showed unnaturally hard shoulders, visible contour outlines, overlapping scatter and frustrating camera navigation. The curve code now uses six joined cubic Bézier sections with gentler shoulders and a rounded crown; both sides still share the same canonical seam descriptor. Increase `bezier_detail` to sample more finely (at a draw-call/triangulation cost). Further profiling and visual iteration with real images is required; the renderer currently still draws a subtle cardboard rim.

Camera controls:
- Mouse wheel sets a configurable zoom target. `smooth_zoom` and `zoom_smoothing` control exponential zoom convergence at a fixed screen-space anchor.
- Middle mouse drag pans.
- Left mouse drag on **empty** canvas pans, without taking a piece; `invert_background_pan` reverses the direction.
- Left mouse drag on a piece moves its entire connected group, with edge scrolling at the viewport perimeter.

Scatter uses deterministic Fisher-Yates shuffling of unique candidate cells outside the assembly area. Cell stride includes tab protrusion and a configurable `shuffle_spacing` gap. It chooses the nearest slots before randomizing, keeping the initial camera more usable on large boards. Non-overlap is based on conservative rectangular footprints rather than expensive shape intersection checks.

Pending Godot verification: texture UV behavior with negative tab extents, polygon triangulation on irregular silhouettes, camera anchor during repeated wheel events and zoom limits, mixed middle/left-button release order, group movement during edge pan, and shuffle for 20x15 / 40x40 grids. No Godot executable available here; do not merge without runtime checks.


## Iteration 5: image crispness, inspector, camera limits and GLES3

An increased `bezier_detail` samples more points along each geometric cubic; **it cannot add image resolution**. The previous renderer added a permanently visible bevel to every polygon edge, which made zoomed outlines appear fuzzy. The bevel is now off by default and the optional edge opacity/width are exposed. `texture_sampling` offers Linear (default, sharper at native scale), Nearest (pixelated), or Mipmaps (useful far away but can soften detail). All options use the original shared image texture. Changes to piece appearance or generation settings require `rebuild()`.

The existing GL Compatibility/GLES3 renderer does not support the project 2D MSAA setting; `msaa_2d=0` removes the warning. Thin AA outlines are optional; future rendering experimentation should be undertaken under a compatible renderer, not by setting unsupported GLES3 MSAA.

Camera panning with an empty-space left drag or middle drag is direct, without interpolation. `restrict_camera=false` now allows unlimited navigation beyond the scattered board, while `camera_outer_margin` controls the added space (in larger piece dimensions) if restrictions are enabled. Initial auto-fit uses actual content bounds, *not* the extra camera margin.

The inspector export annotations now explain impact and apply timing. Godot runtime verification remains required, especially the fullscreen CanvasItem polygon triangulation, visual comparisons at different filter modes and camera behavior on successive clicks.


## Iteration 6 — Gameplay, visual references and styles (experimental)

- `game_mode=FREE`: existing logical neighbor snapping and group-union behavior remains intact. Neighbor group connections emit `pieces_connected` and tint feedback.
- `game_mode=MOSAIC`: release a piece within the configured snap distance of its canonical `home` position to lock that piece to its slot; emits `piece_placed`. Mosaic does *not* require a piece-group union. Completion is determined by the number of locked pieces.
- `show_ghost_board` creates a non-interactive `Sprite2D` beneath all pieces at the exact source-image size, using configurable alpha; Mosaic enables it by default.
- `preview_key` toggles a camera-independent fullscreen `CanvasLayer` with the entire source texture. The preview does not steal pointer input but the board suspends gameplay input while it is open. `set_preview_visible(bool)` provides programmatic control.
- `shuffle_mode` switches between surrounding, centered and lower tray candidate areas. `distribution_mode` chooses deterministic random slot assignment or radial order, with unique grid slots and margin for tab extents.
- `visual_style` changes edge weight; `animation_style` changes short tint tweens on pickup and successful joins. Neither modifies geometric transforms or snapping.
- These modes reuse the same geometry, image texture and solved-space grid. Gameplay and visual effects are opt-in settings rather than separate hardwired generators.

**Runtime QA outstanding** (Godot executable is not installed here):
1. Confirm P overlay fits the viewport and closes without stealing drag state. Verify `show_ghost_board` while camera pans and zooms.
2. In Free mode, connect two pairs independently and merge groups; ensure completion emitted only once.
3. In Mosaic mode, place an incorrect piece near another socket (must not lock), then place it on its own socket (must lock), and complete a small board.
4. Try all shuffle modes at 5×4 and 20×15: no inter-piece overlaps, and bottom-only candidates remain beneath the solved board.
5. Rebuild multiple times and ensure old overlay nodes, texture resources and animations do not leak. Inspect signal counts and inspector property descriptions.
6. Compare Clean/Cardboard/High Contrast and None/Subtle/Playful modes, including low-resolution and transparent source images.

Known future work: configurable full-screen preview UI, input remapping/action maps, sound/particles, rotation-aware Mosaic, accessibility, optional tray panel, richer zoom-in help and performance profiling.
