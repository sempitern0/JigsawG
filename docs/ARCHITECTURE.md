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
