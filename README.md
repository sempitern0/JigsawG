# JigsawG

Experimental Godot 4.7 plugin for interactive 2D jigsaw puzzles with complementary procedural Bézier connectors.

## Run the lab
Open `examples/puzzle_lab.tscn` and run the scene. Assign your own image to the `JigsawBoard.puzzle_texture` property; without one, the board generates a diagnostic checkerboard. Store test images in `examples/images/`.

## Input
- Left-click a piece: drag it (and its connected group in Free mode).
- Left-drag empty canvas or middle-drag: pan the camera; optionally invert direction.
- Wheel: smooth cursor-centered zoom; drag a piece to the edge for autoscroll.
- **P** (or configurable `preview_key`): toggle fullscreen reference preview.

## Gameplay and difficulty
- **Free** (`game_mode=FREE`): assemble arbitrary independent neighbor groups, merging them until the image is complete.
- **Mosaic** (`game_mode=MOSAIC`): move each piece to its correct place on the assembly board. Correctly placed pieces lock; completion occurs when all slots are filled.
- **Ghost board** (`show_ghost_board`): optionally reveal a translucent copy of the finished picture at its solved position. Control its alpha with `ghost_opacity`; Mosaic shows this guide by default.
- **Shuffle**: `AROUND_BOARD`, `CENTER`, `BOTTOM`, and placement-order strategies `RANDOM`/`RADIAL`. Unique placement slots use clearance for Bézier tabs.
- **Styles**: `CLEAN`, `CARDBOARD`, `HIGH_CONTRAST`; connect and pickup feedback `NONE`, `SUBTLE`, `PLAYFUL`. Visual feedback does not scale/offset snapped geometry.
- Render controls: `bezier_detail`, texture filter, outline alpha/width. Avoid conflating contour detail with source image resolution.

`rebuild()` regenerates the puzzle, resets groups, and reapplies layout/style fields. Inspector export documentation distinguishes live controls from rebuild settings. Direct API calls `set_preview_visible(bool)` and `rebuild()` are available.

## Technical status
The plugin targets GL Compatibility and intentionally leaves unsupported GLES3 2D MSAA disabled. Canonical seam geometry, shared GPU-textured polygons, zoom/pan and group graph logic remain separate. **This branch has not been executed in Godot in the authoring environment**; see `docs/ARCHITECTURE.md` for manual QA and limitations. See `LICENSE`.
