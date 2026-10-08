# JigsawG

Experimental standalone Godot 4.7 plugin to generate interactive 2D jigsaw puzzles from an image.

## Run the prototype

1. Open the project in Godot 4.7 and enable the JigsawG editor plugin if it is disabled.
2. Run the project (F6 on `examples/puzzle_lab.tscn`, or F5 as the scene is configured as the main scene).
3. Drag pieces to their correct neighbors. Connected groups move as one and can merge with other groups.
4. To test a custom image, add your own PNG/JPEG/WebP files in `examples/images`, set `puzzle_texture` on the `JigsawBoard` node, and rerun.

No supplied texture uses a procedural checkerboard so the project can be tested without extra assets.

## Current functionality

- Exact rectangular grid (`columns` × `rows`), fixed reproducible seed and parameterized tab depths
- Procedural complementary piece edges and alpha-clipped image cutouts
- Group-aware mouse drag and snap to the correct topological neighbors
- Camera fit, picked-piece outline, drag shadow and action signals for future VFX

## Limitations

This is a foundation, **not yet a release**. It has not been executed in a Godot runtime by the authoring environment. The per-pixel CPU generation may be slow for large images and dense grids. Silhouettes currently vary by depth rather than by independently designed profile shapes. Rich VFX, pan/zoom, touch input, rotation, save/load and formal tests are planned. See [architecture and test plan](docs/ARCHITECTURE.md).

## License

See [LICENSE](LICENSE).
