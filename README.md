# JigsawG

**A reusable 2D jigsaw-puzzle plugin for Godot 4.7.** Generate puzzle pieces from any supported image, connect independent groups, or place pieces onto an optional image guide. Silhouettes use complementary procedural Bézier curves, not fixed mask atlases.

## Installation

1. Copy **only** `addons/jigsawg/` into your game's `res://addons/` directory.
2. Enable **JigsawG** in **Project → Project Settings → Plugins**.
3. Add a **JigsawBoard** custom Node2D to your scene, and provide a Camera2D if you want the built-in camera navigation.
4. Assign **Puzzle Texture**, and set **Columns** and **Rows**. Run the scene. The board constructs its pieces automatically.
5. Customize settings directly in the inspector or assign reusable `JigsawGameplaySettings` and `JigsawAppearanceSettings` resources.

The standalone `examples/puzzle_lab.tscn` is a *development sandbox*, not a required dependency. Without a texture the board uses a generated checkerboard.

## Features

- Pixel-accurate shared texture with complementary Bézier connector profiles, configurable tessellation and rendering styles
- Free (neighbor-group assembly) and Mosaic (lock into correct image position) modes
- Optional ghost image on the workspace and **P** key full-image reference
- Deterministic no-overlap scatter positions: Around Board / Center / Bottom, Random / Radial
- **Optional right-click rotation in 90° increments** for individual pieces or connected groups; optionally randomized during shuffle
- Rotation-aware snapping: Free requires equal group orientation and correct rotated displacement; Mosaic requires the original 0° orientation
- Wheel zoom, drag on empty space to pan, middle-button pan and auto-pan when dragging near a screen edge
- Signals for adding custom VFX, sound, scoring, timers and completion screens

## Rotation mode

Set `allow_piece_rotation = true` to allow right-click quarter-turns. With `random_rotation_on_shuffle = true` and `initial_scatter = true`, pieces start at reproducible random multiples of 90°. Turn off either flag to suppress randomized orientation.

A connected group rotates **as one** around the clicked piece's center, preserving the relative placement of every piece. A group with angle 90° cannot be joined to another group at 0° unless rotated to match. Right-click also works during an active left-drag. Mosaic only locks pieces at angle 0°.

API: `rotate_piece(piece_index, clockwise = true)`. Signal: `group_rotated(piece_id, quarter_turns, group_size)`.

## Reusable Resources

Create Resource files from the FileSystem panel using **New Resource → JigsawGameplaySettings** and **JigsawAppearanceSettings**. Set them on a `JigsawBoard` under **Reusable Presets**.

| Resource | Examples |
|---|---|
| `JigsawGameplaySettings` | Free/Mosaic, snapping, rotation, shuffled angles, spawn mode, reference image, preview key |
| `JigsawAppearanceSettings` | Piece outlines, Bézier detail, texture filtering, feedback style, animation timing |

Presets take precedence over matching individual board properties when `rebuild()` runs. The resources are read and **not mutated** by the board; sharing the same preset between multiple boards is supported. For board-specific overrides, omit the corresponding Resource (this first version applies an entire preset, rather than selectively overriding each field).

## Controls

| Input | Behavior |
|---|---|
| Left drag on piece | Drag a piece or connected group |
| Right-click on piece | Rotate selected group 90° clockwise, when enabled |
| Left drag empty space / middle drag | Pan camera |
| Mouse wheel | Smooth, cursor-centered zoom |
| Drag piece against window border | Edge autopan |
| P (configurable) | Fullscreen completed-image preview |

## Embedding and API

Use the signals on `JigsawBoard` instead of modifying internal implementation: `puzzle_generated(piece_count)`, `piece_picked(piece_id)`, `piece_released(piece_id, connected)`, `pieces_connected(group_size)`, `piece_placed(piece_id)`, `group_rotated(piece_id, quarter_turns, group_size)`, `preview_toggled(visible)`, `connection_failed(piece_id)`, `puzzle_completed()`.

Call `board.rebuild()` to regenerate from updated image/settings (clears group progress). Call `board.set_preview_visible(true/false)` to control the preview in your UI. Call `board.rotate_piece(piece_id)` to implement alternate controls. Connect signals to your own effects, HUD and gameplay managers.

The plugin **does not require** OmniKit or Draggable2D from the old Barebone prototype. Only the `addons/jigsawg` folder is required. GLES3/GL Compatibility does not support 2D MSAA, so the sample project deliberately leaves it disabled.

## Source and quality

Higher-resolution source textures preserve detail for zoomed puzzle pieces. `bezier_detail` controls only edge geometry and does **not** increase texture resolution. Prefer high-quality images for large piece counts. The built-in texture sampling can be changed to Linear, Nearest or Mipmaps independently.

## Status and contributing

The feature branch is an **experimental release candidate**. Gameplay and appearance have been verified manually by the project owner in earlier iterations; the latest rotation/Resource changes have **not** been executed in Godot by the authoring environment. Confirm right-click behavior and large puzzle performance locally before tagging a release.

- Development test scene: `examples/puzzle_lab.tscn`
- Technical notes: `docs/ARCHITECTURE.md`
- Testing checklist: `docs/TESTING.md`
- Issues: https://github.com/sempitern0/JigsawG/issues
- License: [LICENSE](LICENSE)
