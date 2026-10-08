# JigsawG

Experimental Godot 4.7 puzzle plugin focused on procedural Bézier cardboard silhouettes and independent group assembly.

## Run

Open `examples/puzzle_lab.tscn` with Godot 4.7 and press F6. Assign an image on `JigsawBoard.puzzle_texture` or leave it blank to use the generated checkerboard. Place additional local images in `examples/images/`.

**Controls:** left-click on a piece to move it or its connected group; left-drag on empty space or middle-drag to pan (invert with `invert_background_pan`); mouse wheel zooms smoothly around the cursor (`smooth_zoom`, `zoom_smoothing`); dragging a piece near an edge scrolls the camera.

## Graphics foundation

- Canonical complementary Bézier contours; eight configurable profile variants
- One full-resolution GPU texture with mipmaps shared by all pieces, instead of per-piece CPU-rasterized cutouts
- Source UV mapping, 4x MSAA in the sandbox and subtle cardboard rim/shadow feedback
- Zoom range, zoom factor, smoothing, invertible background pan, edge-scroll zone and speed exposed on `JigsawBoard`
- Deterministic shuffle into nearby non-overlapping cells (`shuffle_spacing`)
- No 81-mask PNG atlas required

## Roadmap

Validate large-board camera controls and geometry; then restore Free/Mosaic gameplay modes, shuffle (AroundViewport/Center/Bottom), and Random/Radial distribution. VFX/audio will follow mechanics.

## QA

This code has **not been executed in Godot** in the authoring environment. Test with a real photograph at 5×4, 10×8 and 20×15; examine opaque/transparent art, contour seams, pan/zoom focal position, edge scrolling and group merging. Source detail is bounded by the original image resolution. Godot executable: `godot --headless --path . --script res://tests/test_geometry.gd`.

See `docs/ARCHITECTURE.md` for details. See `LICENSE` for license.
