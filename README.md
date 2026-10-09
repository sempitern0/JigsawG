# JigsawG

Godot 4.7 plugin to create interactive 2D jigsaw puzzles with procedural Bézier connectors, connected-piece groups, optional 90° rotation, Free/Mosaic gameplay, camera navigation and configurable feedback.

## Installation

1. Copy `addons/jigsawg/` into your project's `res://addons/`.
2. Enable **JigsawG** at **Project > Project Settings > Plugins**.
3. Add a **JigsawBoard** Node2D to your scene, with an active Camera2D for built-in navigation.
4. Create a **JigsawPuzzleConfig** resource (.tres) and drag it onto the board's **Puzzle Config** property.
5. Assign an image and dimensions in that resource; expand Gameplay, Appearance, Camera and Feedback to customize the entire puzzle.

The plugin requires no other addons. The development lab scene lives at `examples/puzzle_lab.tscn`; its Resource example is `examples/configs/standard_puzzle.tres`.

## Resource-first public API

**JigsawBoard exposes only `puzzle_config` in the Inspector.** Everything else is defined through Resources:

| Type | Responsibilities |
|---|---|
| `JigsawPuzzleConfig` | Puzzle texture, rows, columns, silhouette count, nested presets |
| `JigsawGameplaySettings` | Free/Mosaic, snapping, rotation, shuffle, transparent guide, preview and shortcut |
| `JigsawAppearanceSettings` | Connector depth, Bézier detail, outline and texture filtering |
| `JigsawCameraSettings` | Zoom, panning, edge movement, camera limits |
| `JigsawFeedbackSettings` | Pickup, connection and failure tint effects and their duration |

A developer can assign the entire puzzle by code:

```gdscript
var config := load("res://puzzles/my_puzzle.tres") as JigsawPuzzleConfig
$JigsawBoard.configure(config)
```

`configure(config)` and `apply_configuration()` regenerate the puzzle and clear previous progress. `get_configuration()` returns the assigned Resource. The board never changes the source Resource. See [Resource API](docs/RESOURCE_API.md) for examples, complete property inventory and migration notes.

## Controls

| Input | Action |
|---|---|
| Left drag on a piece | Drag piece or connected group |
| Right click | Turn the selected piece/group 90° when enabled |
| Left drag on empty space / middle drag | Move the camera |
| Mouse wheel | Smooth zoom around cursor |
| Drag near viewport edge | Auto-pan camera |
| P (configurable) | Show/hide complete picture |

## Gameplay

- Free: join pieces into independently assembled groups and merge them.
- Mosaic: lock each piece at its matching board location with the correct orientation.
- Optional semitransparent source-image guide and fullscreen preview.
- Seeded shuffle, randomized 90° piece orientations and configurable silhouette variants.
- Configurable Clean/Cardboard/High Contrast styles and interaction animations.
- Signals for integration with your game's own scoring, HUD, audio and VFX: `puzzle_generated`, `piece_picked`, `piece_released`, `pieces_connected`, `piece_placed`, `group_rotated`, `connection_failed`, `preview_toggled`, `puzzle_completed`.

## Compatibility and testing

**Breaking Inspector change:** individual board exports have been removed. Existing scenes must migrate their settings into `JigsawPuzzleConfig`. Runtime options remain internal, but the Resource is the authoritative configuration.

Use high-resolution source images for large puzzles; Bézier sampling does not increase texture resolution. GL Compatibility/GLES3 is supported, without unsupported 2D MSAA.

The refactor has not yet been tested in a local Godot executable. See [testing checklist](docs/TESTING.md) before tagging a release. License: [LICENSE](LICENSE).
