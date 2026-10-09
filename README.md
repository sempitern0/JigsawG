<div align="center">

<img src="addons/jigsawg/icon.svg" width="96" alt="JigsawG puzzle icon">

# JigsawG

**Resource-driven 2D jigsaw puzzles for Godot 4.7**

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status: Preview](https://img.shields.io/badge/Status-Preview-orange)](docs/TESTING.md)
[![GDScript](https://img.shields.io/badge/Language-GDScript-478CBF)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![Issues](https://img.shields.io/badge/Feedback-Issues-blue)](https://github.com/sempitern0/JigsawG/issues)

Turn an image into a playable jigsaw board, then customize generation, difficulty, interaction, camera and feedback with reusable Godot Resources.

</div>

> **Release status — preview.** The project owner has tested previous iterations in the Godot editor. This release-preparation branch has not completed the full regression, clean-install and performance checklist. Do not describe it as production-stable yet.

## Highlights

| Feature | What it provides |
| --- | --- |
| Procedural puzzle pieces | Complementary Bézier tabs and sockets; configurable piece count, connector depth and shape variety |
| Group-aware assembly | Build independent groups and join them later, with orientation-aware snapping |
| Rotation difficulty | Optional right-click quarter-turns and seeded random 90° rotations on shuffle |
| Two gameplay modes | **Free:** assemble groups anywhere; **Mosaic:** place each piece in its matching position |
| Guided play | Semi-transparent image mat and a fullscreen reference preview |
| Large-puzzle navigation | Mouse-wheel zoom, background/middle-button pan and edge scrolling |
| Visual feedback | Clean/Cardboard/High Contrast styles, configurable pickup/connection/failure tint effects |
| Resource-first API | One `JigsawPuzzleConfig` asset on `JigsawBoard`; reuse configurations across puzzles |

## Installation

**Requirements:** Godot **4.7**, GDScript and a 2D scene. JigsawG has no dependencies on other addons.

1. Download or clone this repository.
2. Copy **`addons/jigsawg/`** into your game at **`res://addons/jigsawg/`**. Do not copy the project root, demo images or testing folders unless you want the development sandbox.
3. In Godot, open **Project → Project Settings → Plugins** and enable **JigsawG**.
4. Add a **JigsawBoard** node through **Add Child Node**. Add an active **Camera2D** to the scene if you want built-in navigation.
5. In the `JigsawBoard` Inspector, create or assign a **JigsawPuzzleConfig** to its **Puzzle Config** property.
6. Set **Puzzle Texture**, **Columns** and **Rows** on the Resource, then expand **Gameplay**, **Appearance**, **Camera** and **Feedback** to tailor the experience.

Your scene can be as small as:

```text
PuzzleScene (Node2D)
├── Camera2D       # enabled/current
└── JigsawBoard    # puzzle_config = your .tres
```

**Note:** Without a source image JigsawG shows a generated checkerboard useful for diagnostics. Supply your own licensed artwork for published games.

## Quick start: reusable puzzle asset

1. In the **FileSystem** dock choose **New Resource → JigsawPuzzleConfig**, and save it as `res://puzzles/forest.tres`.
2. Set a source image and a grid such as **10 columns × 8 rows** (80 pieces).
3. In **Gameplay**, optionally enable **Allow Piece Rotation** and **Random Rotation On Shuffle**.
4. In **Appearance**, choose the connector depth, visual style and texture sampling.
5. Assign `forest.tres` to **JigsawBoard → Puzzle Config**, then run the scene.

To switch puzzles from code:

```gdscript
@onready var board = $JigsawBoard

func load_puzzle(resource_path: String) -> void:
    var config := load(resource_path) as JigsawPuzzleConfig
    if config == null:
        push_error("Expected a JigsawPuzzleConfig: " + resource_path)
        return
    board.configure(config)  # Rebuilds and resets current progress.
```

Or build a configuration entirely in code:

```gdscript
func create_beginner_puzzle(image: Texture2D) -> JigsawPuzzleConfig:
    var config := JigsawPuzzleConfig.new()
    config.puzzle_texture = image
    config.columns = 5
    config.rows = 4
    config.gameplay.game_mode = JigsawGameplaySettings.Mode.MOSAIC
    config.gameplay.allow_piece_rotation = false
    config.gameplay.show_ghost_board = true
    config.gameplay.ghost_opacity = 0.3
    config.appearance.visual_style = JigsawAppearanceSettings.VisualStyle.CLEAN
    config.camera.smooth_zoom = true
    config.feedback.animation_style = JigsawFeedbackSettings.AnimationStyle.SUBTLE
    return config

func start_beginner(image: Texture2D) -> void:
    $JigsawBoard.configure(create_beginner_puzzle(image))
```

## Resources and configuration

**`JigsawBoard` exports only `puzzle_config`.** All gameplay settings belong to this Resource tree:

| Resource | Configure |
| --- | --- |
| **JigsawPuzzleConfig** | Source texture, grid rows/columns and number of connector silhouette families |
| **JigsawGameplaySettings** | Free/Mosaic, snapping tolerance, 90° rotation, seeded shuffle, ghost mat, preview key |
| **JigsawAppearanceSettings** | Bézier depth and detail, edge styles, border width/opacity, texture sampling |
| **JigsawCameraSettings** | Initial framing, wheel zoom, interpolation, panning direction, optional bounds, edge scroll |
| **JigsawFeedbackSettings** | None/Subtle/Playful animation preset, pickup/connect/failure tint and timing |

Nested Resources can be saved as external `.tres` assets and reused between levels. `board.configure(config)`, `board.apply_configuration()` and `board.rebuild()` regenerate the puzzle **and discard the current assembly progress**. The board reads but does not intentionally modify your Resources.

More detail: [Resource API and migration guide](docs/RESOURCE_API.md).

## Inputs

| Mouse/key | Behavior |
| --- | --- |
| Left drag on piece | Move that piece or its connected group |
| Right-click on piece | Rotate the piece/group by 90° when enabled |
| Left drag empty space or middle drag | Pan; direction optionally inverted |
| Mouse wheel | Zoom around cursor; smoothing is configurable |
| Drag a piece near the screen edge | Automatically pan the camera |
| **P** (configurable) | Show/hide the full reference image |

## Modes and example use cases

**Relaxed picture puzzle:** choose `MOSAIC`, turn rotation off, enable the ghost mat and allow a larger snap tolerance. Players place each piece into the original image.

**Classic tabletop puzzle:** choose `FREE`, disable the ghost mat, allow groups to be assembled independently, and shuffle around the board.

**Challenging puzzle:** enable random 90° orientation during shuffle, increase the number of connector families and reduce the snap tolerance. Piece rotation preserves assembled groups.

**Embedded mini-game / education / gallery:** host the board inside your existing scene, use a reusable preset per image, and connect JigsawBoard signals to your own HUD, score, timer, sound or achievements. The plugin intentionally does not impose a game menu or campaign system.

## Integration events

Connect signals from `JigsawBoard` rather than editing internal scripts.

| Signal | When it fires |
| --- | --- |
| `puzzle_generated(piece_count)` | A new board has been generated |
| `piece_picked(piece_id)` | The player starts dragging a piece |
| `piece_released(piece_id, connected)` | A dragged piece is released |
| `pieces_connected(group_size)` | Neighbor groups are successfully joined |
| `piece_placed(piece_id)` | Mosaic piece locks into position |
| `group_rotated(piece_id, quarter_turns, group_size)` | A piece or group is turned |
| `connection_failed(piece_id)` | Release produced no valid connection |
| `preview_toggled(visible)` | Reference-image overlay changes |
| `puzzle_completed()` | Puzzle completion has been detected |

For example:

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    board.pieces_connected.connect(_on_pieces_connected)
    board.puzzle_completed.connect(_on_puzzle_completed)

func _on_pieces_connected(group_size: int) -> void:
    print("Connected group contains ", group_size, " pieces")
    # Hook in your own audio or VFX here.

func _on_puzzle_completed() -> void:
    print("Puzzle complete!")
    # Open your own results screen here.
```

## Image quality and performance

- Use a sufficiently high-resolution source image for dense puzzles. Increasing `bezier_detail` smooths **geometry**, not image pixels.
- All pieces reference a shared source texture. Rendering performance still depends on image dimensions, piece count, GPU and rendering backend.
- The demo runs under **GL Compatibility**; unsupported GLES3 2D MSAA is disabled.
- Benchmark your intended device and puzzle sizes before shipping. Large-image generation, high piece counts and touch input are not yet certified.

## Repository structure

```text
addons/jigsawg/              # Distributable plugin: copy this directory
  icon.svg                   # Bundled node icon, imported/resolved by Godot UID
  plugin.cfg / plugin.gd
  resources/                 # Public .tres resource types
  src/                       # Internal puzzle runtime
examples/                    # Development-only Godot scene and presets
tests/                       # Geometry / behavior checks
docs/
  RESOURCE_API.md            # Configuration reference
  TESTING.md                 # Release acceptance checklist
  ARCHITECTURE.md            # Design and migration notes
```

## Known limitations and release readiness

This is a **preview**, not a certified stable release. Current priorities include regression tests for group merging and rotation, clean-project installation, memory/performance measurement, reconfiguration lifecycle and verifying the redistribution rights for demo assets. Input support currently focuses on mouse and keyboard; touchscreen/controller and save/load are outside the documented support scope.

Found a bug? Please open an [issue](https://github.com/sempitern0/JigsawG/issues) with your Godot version, operating system, minimal reproduction scene, relevant Resource settings and engine logs. See [Engineering Review](docs/ENGINEERING_REVIEW.md), [Testing](docs/TESTING.md) and [Contributing](CONTRIBUTING.md).

## License

[MIT](LICENSE). Review third-party artwork licenses separately before redistributing example images.
