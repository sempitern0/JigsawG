# Advanced integration

JigsawG is a **puzzle runtime**, not a complete game framework. Its responsibilities are generating and rendering complementary pieces, dragging and rotating connected groups, detecting legal joins, managing the assembly state and emitting semantic events. Menus, scoring, audio direction, art style, campaign progression, save slots and achievements belong to your game.

You should rarely need to inherit from or edit `jigsaw_board.gd`. Choose the lightest integration level that fits your project.

## Internal group model

The group ownership and snapping checks are independently testable. `JigsawGroupModel` holds the connected component graph without Nodes and provides `reset()`, `members_for()`, `merge()`, `group_ids()` and `restore()`. `JigsawConnectionResolver` computes nearby grid-neighbor IDs and potential positional offsets. The Board is the only code allowed to move piece Nodes, reconcile selection, dispatch reactions or persist state.

Keep using `JigsawBoard.get_group_piece_ids(piece_id)` and `get_connected_group_count()`; do not depend on private group data from host scripts. Animation adapters remain presentation-only.

## The three integration levels

| Level | Technique | Suitable for |
| --- | --- | --- |
| **No code** | `JigsawPuzzleConfig` + built-in `JigsawReaction` Resources | Puzzle generation, presentation, sound, scene VFX, AnimationPlayer and built-in node methods |
| **Small scene script** | Public Board methods + typed signals | HUD progress, pause menus, accessibility controls, tutorials, scoring and game state |
| **Custom advanced logic** | `JigsawReaction` subclass or `event_emitted` router | Combos, achievements, telemetry, adaptive difficulty, persistence and per-project effects |

`JigsawBoard` exports **only** the root `puzzle_config` Resource. Do not add new Board exports for artistic or gameplay decisions that can live in a Resource or host scene.

## Use an existing AnimationPlayer without Board scripts

Scene example:

```text
PuzzleScreen (Node2D)
├── JigsawBoard         (puzzle_config = level_01.tres)
├── Camera2D
├── HUD (Control)
└── WinAnimationPlayer
```

In `JigsawPuzzleConfig → Reactions`, add a `JigsawPlayAnimationReaction`:

```text
Reaction
  Event Mask             → Puzzle Completed
Animation
  Animation Player Path  → ../WinAnimationPlayer
  Animation Name         → celebrate
  Speed                  → 1
  Blend Time             → -1  (AnimationPlayer's own default)
```

The reaction plays the named AnimationPlayer clip. The path is **relative to the JigsawBoard**, not relative to the .tres file, so a reusable preset requires equivalent scene structure or an adjusted path.

## Call built-in methods on host nodes — no script required

To reveal an existing hidden `Control` named `HUD` after completion, add a `JigsawCallMethodReaction`:

```text
Reaction
  Event Mask   → Puzzle Completed
Target
  Target Path  → ../HUD
  Method Name  → show
  Pass Event   → false
```

This invokes the built-in `Control.show()` without inheriting any Board methods. Set `pass_event = true` only for methods that accept exactly one `JigsawPuzzleEvent` argument.

Paths are resolved through `JigsawBoard.get_node_or_null()`. If a target is missing, JigsawG warns and skips the reaction. Do not use the method reaction to invoke untrusted or user-supplied method names; configuration Resources are developer-authored assets.

## HUD progress with one signal

`get_progress()` returns a number from 0 to 1. In Free mode it measures **successful group joins**, not percentage of board area filled; in Mosaic it measures **pieces locked into slots**.

```gdscript
extends Control

@onready var board = $"../JigsawBoard"
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
    board.progress_changed.connect(_on_progress_changed)
    _on_progress_changed(board.get_progress())

func _on_progress_changed(value: float) -> void:
    progress_bar.value = value * 100.0
```

The `get_progress_info()` dictionary also includes `mode`, `total_pieces`, `locked_pieces`, `group_count`, `connections_made`, `connections_needed` and `completed`. This deliberately avoids exposing private dictionaries or letting HUD scripts change group internals.

## Pause menu: disable interaction without pausing the scene

```gdscript
func open_pause_menu() -> void:
    $JigsawBoard.set_interaction_enabled(false)
    $PauseMenu.show()

func close_pause_menu() -> void:
    $PauseMenu.hide()
    $JigsawBoard.set_interaction_enabled(true)
```

Disabling interaction cancels any current drag and stops camera input. Puzzle rendering remains visible; other host-system processes can continue.

Alternatively, handle the `interaction_enabled_changed(enabled: bool)` signal to update accessibility hints or menu state.

## Provide your own tutorial/help controls

External UI can trigger built-in features without editing core input handlers:

```gdscript
func on_reference_pressed() -> void:
    $JigsawBoard.toggle_reference_preview()

func on_guide_pressed(enabled: bool) -> void:
    $JigsawBoard.set_ghost_guide_visible(enabled)

func on_guide_opacity_changed(value: float) -> void:
    $JigsawBoard.set_ghost_guide_opacity(value)

func on_fit_view_pressed() -> void:
    $JigsawBoard.fit_view()
```

Runtime guide overrides do **not mutate the shared Resource**. They reset to Resource defaults on `rebuild()`. `fit_view()` returns false if no active `Camera2D` is available.

## Implement custom scoring with a stateless Resource

```gdscript
@tool
class_name ScoreOnJoinReaction
extends JigsawReaction

@export var points_per_join := 50

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
    if event.type != JigsawPuzzleEvent.Type.GROUP_CONNECTED:
        return
    var manager := board.get_tree().get_first_node_in_group("score_manager")
    if manager != null:
        manager.add_points(points_per_join)
```

Save `ScoreOnJoinReaction.tres`, select `Group Connected` in its Event Mask and put it in the config's Reactions array. The changing score belongs in `ScoreManager`, not in a shared Resource.

For custom event routing, connect `event_emitted(event)` once. Do not emit per-frame drag events just to animate particles; track the source piece's transform from `get_piece_node(piece_id)` between drag-start and drag-end.

## Resume and switch levels

```gdscript
# Save a standalone .tres containing the configuration and current piece state:
ResourceSaver.save($JigsawBoard.capture_resume_config(), "user://puzzle_resume.tres")

# Load it later:
var next_config := load("user://puzzle_resume.tres") as JigsawPuzzleConfig
if next_config != null:
    $JigsawBoard.configure(next_config)
```

Capture only the state with `capture_state()` if you already have a save-slot or cloud-save system. For advanced validation and callbacks, use `restore_state(state)` and `puzzle_state_applied(event)`.

**Important:** State compatibility currently checks dimensions, source size, generation seed and silhouette count. It does **not** cryptographically identify the image content. Host games must associate a save with the intended image/puzzle ID to avoid restoring on a different image of the same dimensions.

Reconfiguration deliberately resets current progress. If an event handler switches scenes or configs, defer the operation rather than rebuilding recursively from inside an event callback.

## Resource reuse and ownership

- Create one `JigsawPuzzleConfig` per level or difficulty preset.
- Share external Gameplay, Appearance, Camera and Feedback Resources across levels when they have identical design.
- Share **stateless** reactions; keep mutable session state in Nodes, Managers, or Autoloads.
- Do not mutate `get_piece_node()` transforms yourself; Board exclusively owns motion, rotation and snapping.
- Avoid caching piece-node references through `rebuild()`; they are replaced.
- Reactions are activated from a snapshot of the assigned Resource array on build, so call `apply_configuration()` for edited reaction lists.
- For scene method and animation reactions, NodePaths are relative to Board and require a matching host-scene hierarchy.

## Multiple puzzles, cameras and input ownership

The built-in Board uses `_unhandled_input` and the viewport's current `Camera2D`. For **multiple simultaneously interactive boards in the same viewport**, event routing and camera ownership are not isolated. Do not assume this is supported out of the box.

Safe approaches: one interactive Board per viewport, separate `SubViewport` containers, or enabling input on only one Board at a time with `set_interaction_enabled()`. Test routing before shipping split-screen or multiplayer puzzle scenes.

## Custom piece materials without replacing the renderer

Assign an optional `CanvasItemMaterial` or `ShaderMaterial` to `JigsawAppearanceSettings.piece_material`. JigsawG applies it to every generated piece after polygon setup; the original texture/UV source and Bézier geometry are preserved.

The `Material` Resource is **shared** across pieces. Prefer material uniforms for effects common to the whole puzzle. If different pieces need independent shader values, use CanvasItem instance shader parameters from your own presentation controller and reapply them when pieces are regenerated. Avoid changing `JigsawPiece`'s transform or outline data.

With `piece_material = null`, the normal renderer remains unchanged. See [Resource API](RESOURCE_API.md) for the exported field.

## Rendering and performance

The source image is a shared texture; silhouette geometry is procedurally triangulated. Source-image size, texture filtering, curve sampling (`bezier_detail`) and piece count have different performance costs. Increasing curve detail does not increase texture resolution. Benchmark large configurations on the actual renderers/devices.

The core controller is intentionally stable, but it is still a relatively large script. Future extraction into separate camera/input, board generation and graph-state internals should be accompanied by regression tests; those internal scripts should not become part of the public API.

## Supported boundaries and extension policy

**Public surface:** `JigsawPuzzleConfig`, its settings Resources, `JigsawPuzzleEvent`, `JigsawReaction`, built-in reaction Resources, Board public methods and typed signals.

**Internal implementation:** `JigsawPiece`, node names, group dictionaries, generated image textures, scene hierarchy and methods beginning with `_`. These may change without being stable integration contracts.

**Not guaranteed yet:** touch/controller input, simultaneous Boards in one viewport, GPU/performance budgets for very large puzzles, binary save compatibility across future versions, or deterministic placement under arbitrary custom source images. Review [Testing](TESTING.md) before publishing a stable release.
