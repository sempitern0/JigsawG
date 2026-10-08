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
