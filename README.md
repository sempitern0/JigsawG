<div align="center">

<img src="addons/jigsawg/icon.svg" width="96" alt="JigsawG puzzle icon">

# JigsawG

**Resource-driven 2D jigsaw puzzles for Godot 4.7**

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status: Preview](https://img.shields.io/badge/Status-Preview-orange)](docs/TESTING.md)
[![GDScript](https://img.shields.io/badge/Language-GDScript-478CBF)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![Issues](https://img.shields.io/badge/Feedback-Issues-blue)](https://github.com/sempitern0/JigsawG/issues)

Turn an image into a playable jigsaw board, then customize generation, difficulty, interaction, camera and feedback with reusable Godot Resources. **JigsawG handles puzzle mechanics; your project owns art direction, UI, sound and progression.**

</div>

> **Release status — preview.** The public API is usable and under active validation. Before shipping a game, run the included regression checklist against your target Godot version and hardware.

## Highlights

| Feature | What it provides |
| --- | --- |
| Procedural puzzle pieces | Complementary Bézier tabs and sockets; configurable piece count, connector depth and shape variety |
| Group-aware assembly | Build independent groups, Ctrl-select several groups and move them together |
| Resumable puzzle state | Capture progress into a Resource and resume later without adopting a save-game framework |
| Rotation difficulty | Optional right-click quarter-turns and seeded random 90° rotations on shuffle |
| Two gameplay modes | **Free:** assemble groups anywhere; **Mosaic:** place each piece in its matching position |
| Guided play | Semi-transparent image mat and a fullscreen reference preview |
| Large-puzzle navigation | Mouse-wheel zoom, background/middle-button pan and edge scrolling |
| Visual feedback | Clean/Cardboard/High Contrast styles, configurable pickup/connection/failure tint effects |
| Resource-first API | One `JigsawPuzzleConfig` asset on `JigsawBoard`; reuse configurations across puzzles |
| Natural shuffle | Deterministic grid layouts or a non-grid Chaotic mode with collision-aware random placement |
| Event/reaction API | Typed events plus sound, VFX scenes, AnimationPlayer and method-call Resources; no Board overrides |

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
| **JigsawGameplaySettings** | Free/Mosaic, snapping, multi-select, 90° rotation, grid/chaotic shuffle, ghost mat, preview |
| **JigsawAppearanceSettings** | Bézier shape, edge rendering, texture sampling, optional CanvasItem material and selection-highlight styling |
| **JigsawCameraSettings** | Initial framing, smooth pan/zoom, empty-board pan grace, optional bounds and eased edge scrolling |
| **JigsawFeedbackSettings** | None/Subtle/Playful built-in animation preset, pickup/connect/failure tint and timing |
| **JigsawPuzzleState** | Serializable piece positions, rotations, connected groups and Mosaic locks |
| **JigsawReaction[]** | Optional reusable host-game reactions: audio, VFX scenes or custom Resource scripts |

Nested Resources can be saved as external `.tres` assets and reused between levels. `board.configure(config)`, `board.apply_configuration()` and `board.rebuild()` regenerate the puzzle **and discard the current assembly progress**. The board reads but does not intentionally modify your Resources. Reaction lists are snapshotted when a configuration is applied, so live edits only take effect on the next apply/rebuild.

More detail: [Resource API reference](docs/RESOURCE_API.md).

## Add feedback in under a minute

No scripting is required for common audio and VFX.

1. Select the `JigsawPuzzleConfig` used by your board.
2. Expand **Reactions** and add an array element.
3. Choose **New JigsawAudioReaction**, **JigsawSpawnSceneReaction**, **JigsawPlayAnimationReaction**, or **JigsawCallMethodReaction**.
4. Tick the desired **Event Mask** entries.
5. Assign the sound or PackedScene and run the puzzle.

Example — play a snap sound:

```text
JigsawPuzzleConfig
└── Reactions
    └── JigsawAudioReaction
        ├── Event Mask → Group Connected ✓
        ├── Stream → puzzle_snap.ogg
        ├── Spatial → true
        └── Pitch → 0.96 .. 1.04
```

Example — spawn particles when a Mosaic piece is correct:

```text
JigsawSpawnSceneReaction
├── Event Mask → Piece Placed ✓
├── Scene → piece_sparkle.tscn
├── Parent Mode → Board Parent
└── Auto Free After → 1.5
```

Reactions can be stacked, saved as reusable `.tres` files and shared by many puzzle presets. For pickup effects that must follow a moving piece, use **Parent Mode → Primary Piece**.

**No-script examples for host scenes:** Add a `JigsawPlayAnimationReaction` listening to **Puzzle Completed** and target `../WinAnimationPlayer`, animation `celebrate`. Or add a `JigsawCallMethodReaction`, choose **Puzzle Completed**, target `../ResultsPanel`, method `show` and leave **Pass Event** off. Paths are relative to JigsawBoard.

See [Events & Reactions](docs/EVENTS_AND_REACTIONS.md) for detailed Inspector recipes, event definitions, custom reactions and lifecycle rules.

## Inputs

| Mouse/key | Behavior |
| --- | --- |
| Left drag on piece | Move that piece/group; if it belongs to a multi-selection, move all selected groups |
| Ctrl + left-click | Toggle a piece's whole connected group in the current multi-selection |
| Right-click on piece | Rotate the piece/group by 90° when enabled |
| Left drag empty space or middle drag | Pan; empty-space left drag uses configurable delay/threshold to avoid accidental panning |
| Mouse wheel | Zoom around cursor; smoothing is configurable |
| Drag a piece near the screen edge | Automatically pan the camera |
| **P** (configurable) | Show/hide the full reference image |

## Modes and example use cases

**Relaxed picture puzzle:** choose `MOSAIC`, turn rotation off, enable the ghost mat and allow a larger snap tolerance. Players place each piece into the original image.

**Classic tabletop puzzle:** choose `FREE`, disable the ghost mat, allow groups to be assembled independently, and shuffle around the board. Enable Ctrl multi-selection when players should be able to reorganize several loose groups at once.

**Challenging puzzle:** enable random 90° orientation, choose **Chaotic** shuffle, increase connector families and reduce snap tolerance. Chaotic shuffle keeps conservative spacing but removes the obvious slot-grid presentation.

**Embedded mini-game / education / gallery:** host the board inside your existing scene, use a reusable preset per image, and connect JigsawBoard signals to your own HUD, score, timer, sound or achievements. The plugin intentionally does not impose a game menu or campaign system.

## Event-driven integration

Every important interaction has a semantic `JigsawPuzzleEvent`: puzzle reset/start/completion, restored state, drag start/finish/cancel, Mosaic placement success/failure, Free group connection success/failure, group rotation and preview visibility.

Use whichever integration level matches your project:

1. Connect a specific rich signal such as `piece_placement_failed` or `group_connection_succeeded`.
2. Connect `event_emitted(event)` once and route all puzzle behavior centrally.
3. Add `JigsawReaction` Resources to the puzzle preset for reusable plug-and-play behavior.
4. Existing compact signals (`piece_picked`, `pieces_connected`, `puzzle_completed`, etc.) remain for compatibility.

```gdscript
func _ready() -> void:
    $JigsawBoard.event_emitted.connect(_on_jigsaw_event)

func _on_jigsaw_event(event: JigsawPuzzleEvent) -> void:
    match event.type:
        JigsawPuzzleEvent.Type.PUZZLE_STARTED:
            timer.start()
        JigsawPuzzleEvent.Type.PIECE_PLACEMENT_FAILED:
            mistakes += 1
        JigsawPuzzleEvent.Type.GROUP_CONNECTED:
            combo += event.group_size
        JigsawPuzzleEvent.Type.PUZZLE_COMPLETED:
            save_progress()
```

The context exposes `piece_id`, all `piece_ids` in the current group, `group_size`, `world_position`, rotation, success, a documented reason and event-specific metadata. JigsawG intentionally avoids per-frame drag events; custom trails can follow `board.get_piece_node(piece_id)` between drag-start and drag-end events.

Full reference: [Events & Reactions](docs/EVENTS_AND_REACTIONS.md).

## Plug into your own game without overriding Board

The Board exposes a small integration facade for HUDs and menus, independent of internal puzzle logic.

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    board.progress_changed.connect(_on_progress)
    _on_progress(board.get_progress())

func _on_progress(progress: float) -> void:
    $HUD/ProgressBar.value = progress * 100.0

func open_pause_menu() -> void:
    board.set_interaction_enabled(false)
    $PauseMenu.show()

func close_pause_menu() -> void:
    $PauseMenu.hide()
    board.set_interaction_enabled(true)

func _on_reference_pressed() -> void:
    board.toggle_reference_preview()

func _on_recenter_pressed() -> void:
    board.fit_view()
```

For accessibility/guide controls use `set_ghost_guide_visible(bool)` and `set_ghost_guide_opacity(float)`. These are runtime overrides, not modifications to shared `.tres` assets.

Free-mode progress counts completed group joins; Mosaic progress counts locked pieces. Use `get_progress_info()` for detailed HUD data.

You can also assign a CanvasItem `Material` or `ShaderMaterial` under **Appearance → Piece Material**. The default remains unchanged if no material is supplied; no custom `JigsawPiece` subclass is necessary.

**Advanced users:** [Advanced integration and public API boundaries](docs/ADVANCED_USAGE.md) explains custom reactions, state ownership, multiple Boards, scene routing and lifecycle rules.

## Camera feel

Camera behavior lives in `JigsawCameraSettings`. The default setup aims to remain responsive while removing abrupt movement:

| Setting | Default | Effect |
| --- | ---: | --- |
| `smooth_pan` | true | Interpolates camera position toward pointer/edge-scroll targets |
| `pan_smoothing` | 26 | Higher values feel more immediate; lower values feel softer |
| `smooth_zoom` | true | Interpolates wheel zoom |
| `zoom_smoothing` | 12 | Zoom response speed |
| `edge_scroll_speed` | 900 | Maximum auto-pan speed while carrying pieces |
| `edge_scroll_smoothing` | 12 | Acceleration/deceleration of edge scrolling |
| `background_pan_delay_ms` | 70 | Short grace before an empty-space click can become a pan |
| `background_pan_threshold_px` | 4 | Minimum pointer travel before that pan starts |

Suggested starting points:

- **Responsive desktop:** pan 24–30, edge 10–14, zoom 10–14.
- **Soft/cinematic:** pan 10–16, edge 6–10, zoom 7–10.
- **Fully direct:** disable `smooth_pan` and/or `smooth_zoom`.

If the host `Camera2D` already has Godot's own **Position Smoothing** enabled, disable either that setting or JigsawG's `smooth_pan` to avoid applying smoothing twice.

## Resume a puzzle without a save framework

JigsawG exposes progress as a Resource. It does **not** impose slots, UI, filenames or save policies.

Capture only the runtime state:

```gdscript
var state: JigsawPuzzleState = $JigsawBoard.capture_state()
ResourceSaver.save(state, "user://forest_progress.tres")
```

Restore it on a compatible generated board:

```gdscript
var state := ResourceLoader.load("user://forest_progress.tres") as JigsawPuzzleState
$JigsawBoard.restore_state(state)
```

Or persist one complete resumable puzzle configuration:

```gdscript
# Save:
var resume_config := $JigsawBoard.capture_resume_config()
ResourceSaver.save(resume_config, "user://forest_resume.tres")

# Load later:
var resume_config := ResourceLoader.load("user://forest_resume.tres") as JigsawPuzzleConfig
$JigsawBoard.configure(resume_config)
```

`JigsawPuzzleState` stores positions, 90° rotations, connected-group ids, Mosaic locks and completion state. It validates grid dimensions, source-image size, seed and silhouette settings before applying. `JigsawBoard.puzzle_state_restored(state)` is emitted after a successful restore. UI and save-slot management remain entirely in the host game.

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
  resources/                 # Public .tres configuration types
  events/                    # Public event context and reusable reactions
  src/                       # Internal puzzle runtime
examples/                    # Development-only Godot scene and presets
tests/                       # Geometry / behavior checks
docs/
  RESOURCE_API.md            # Configuration reference
  EVENTS_AND_REACTIONS.md    # No-code VFX/audio + event extension API
  TESTING.md                 # Release acceptance checklist
```

## Known limitations and release readiness

This is a **preview**, not a certified stable release. Current priorities include regression tests for group merging and rotation, clean-project installation, memory/performance measurement, reconfiguration lifecycle and verifying the redistribution rights for demo assets. Input support currently focuses on mouse and keyboard; touchscreen/controller support is not yet certified. Puzzle progress can be captured/restored as Resources, while save-slot UI and persistence policy remain the host game’s responsibility.

Found a bug? Please open an [issue](https://github.com/sempitern0/JigsawG/issues) with your Godot version, operating system, minimal reproduction scene, relevant Resource settings and engine logs. See [Events & Reactions](docs/EVENTS_AND_REACTIONS.md), [Testing](docs/TESTING.md), [Changelog](CHANGELOG.md) and [Contributing](CONTRIBUTING.md).

## License

[MIT](LICENSE). Review third-party artwork licenses separately before redistributing example images.
