# JigsawG — resource-first API

## One asset per puzzle

Create **JigsawPuzzleConfig** in Godot's Create Resource dialog and save it as a `.tres`. Drag that Resource to the **Puzzle Config** export on a **JigsawBoard** node. The component reads the referenced settings when it enters the scene tree and whenever `rebuild()` / `apply_configuration()` is called.

You can create one config per level and multiple boards may reuse the same config. Board code never alters Resource objects.

| Resource | Responsibilities |
|---|---|
| **JigsawPuzzleConfig** | Source texture, rows, columns, connector family count; references the other Resources |
| **JigsawGameplaySettings** | Mode, snapping, rotation, initial placement/shuffle, preview and ghost board |
| **JigsawAppearanceSettings** | Bézier connector depth/detail, edges, texture filtering, rendering style |
| **JigsawCameraSettings** | Zoom, pan, camera bounds, initial fitting and edge scrolling |
| **JigsawFeedbackSettings** | Pickup/success/failure tint animations and durations |

The root Resource creates default subresources automatically; expand and adjust them in the Inspector. To share a subresource across different puzzle configs, save it as an external `.tres` and assign it to each config. `JigsawGameplaySettings` and `JigsawAppearanceSettings` may also be assigned directly to older boards for backward compatibility. The **root configuration wins** if both are present.

## Programmatic setup

```gdscript
extends Node2D

@onready var board: Node2D = $JigsawBoard

func _ready() -> void:
    var config := JigsawPuzzleConfig.new()
    config.puzzle_texture = load("res://art/my_image.png")
    config.columns = 10
    config.rows = 8
    config.silhouette_variants = 8

    config.gameplay.allow_piece_rotation = true
    config.gameplay.random_rotation_on_shuffle = true
    config.gameplay.game_mode = JigsawGameplaySettings.Mode.FREE

    config.appearance.connector_depth = 0.23
    config.appearance.visual_style = JigsawAppearanceSettings.VisualStyle.CARDBOARD
    config.feedback.connect_animation_duration = 0.23
    config.feedback.enable_failure_feedback = true
    config.camera.smooth_zoom = true

    board.configure(config)
    board.puzzle_completed.connect(_on_completed)

func _on_completed() -> void:
    print("Solved!")
```

To reuse assets, save `res://puzzles/forest.tres` and call:

```gdscript
board.configure(load("res://puzzles/forest.tres"))
```

`board.get_configuration()` retrieves the assigned root Resource. `board.apply_configuration()` regenerates the puzzle using the latest values in it. **Regeneration deliberately resets gameplay progress**; do not call it every frame.

## Inspector compatibility

Legacy direct `JigsawBoard` properties are still available for previously built scenes. In resource-first projects, set **Puzzle Config** and configure its children; do not mix direct and resource values for the same setting.

Configuration resolution:
1. If a root **Puzzle Config** exists, take dimensions/texture from it and use its nested resources.
2. If there is no root config, allow legacy **Gameplay Settings** and **Appearance Settings** exports.
3. If neither exists, use the individual legacy board exports.

A null nested config section leaves the corresponding legacy properties in use. Configs are not edited or duplicated by the Board, but legacy exported board fields receive an effective copy when `rebuild()` applies Resources. To switch away from a root config completely, explicitly reset the individual legacy fields or instantiate a fresh Board.

## Signals and extension points

`puzzle_generated(piece_count)`, `piece_picked(piece_id)`, `piece_released(piece_id, connected)`, `pieces_connected(group_size)`, `piece_placed(piece_id)`, `group_rotated(piece_id, quarter_turns, group_size)`, `preview_toggled(visible)`, `connection_failed(piece_id)` and `puzzle_completed()` let host games add HUD, audio, analytics, achievements or custom effects.

The internal `JigsawPiece` and `jigsaw_geometry.gd` scripts are implementation details, not required as integration entry points. The public component remains `JigsawBoard`.
