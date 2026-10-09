# Events and reactions

JigsawG keeps puzzle mechanics independent from your game's presentation. Use the event API for particles, audio, UI, scoring, achievements, analytics, tutorials or any other host-game behavior.

There are three integration levels:

1. **Semantic signals** on `JigsawBoard`: easiest for scene scripts.
2. **`event_emitted(JigsawPuzzleEvent)`**: one event bus for centralized systems.
3. **`JigsawReaction` Resources** inside `JigsawPuzzleConfig.reactions`: reusable plug-and-play behavior.

The old lightweight signals such as `piece_picked`, `pieces_connected` and `puzzle_completed` remain available for compatibility.

## Event model

Every rich event is a `JigsawPuzzleEvent` with the same context fields:

| Field | Meaning |
| --- | --- |
| `type` | `JigsawPuzzleEvent.Type` semantic event kind |
| `board` | Board that emitted the event |
| `piece_id` | Primary piece, or -1 for board-level events |
| `piece_ids` | Current connected group membership |
| `group_size` | Size of `piece_ids` |
| `world_position` | World-space center suitable for VFX/audio |
| `quarter_turns` | Current 0–3 orientation of the primary piece |
| `success` | Whether the interaction succeeded |
| `reason` | Stable short reason such as `neighbor_snap` or `wrong_position_or_rotation` |
| `metadata` | Event-specific extra values |
| `timestamp_msec` | Engine tick time when the event was created |

### Event types

| Type | Typical use |
| --- | --- |
| `PUZZLE_RESET` | Clear temporary UI/VFX before regeneration |
| `PUZZLE_STARTED` | Start timer, music, tutorial or analytics session |
| `PIECE_DRAG_STARTED` | Pickup sound, glow, trail activation |
| `PIECE_DRAG_FINISHED` | Stop drag trail, update move counter |
| `PIECE_DRAG_CANCELLED` | Clean up drag effects when preview/rebuild interrupts input |
| `PIECE_PLACED` | Mosaic success particles/audio |
| `PIECE_PLACEMENT_FAILED` | Mosaic incorrect-placement feedback |
| `GROUP_CONNECTED` | Free-mode snap celebration, combo/scoring |
| `GROUP_CONNECTION_FAILED` | Free-mode failed snap feedback |
| `GROUP_ROTATED` | Rotation sound or orientation UI |
| `PREVIEW_TOGGLED` | Pause timer or update help HUD |
| `PUZZLE_COMPLETED` | Completion screen, persistence, rewards |

JigsawG deliberately does **not** emit a per-frame drag event. High-frequency effects should listen to `PIECE_DRAG_STARTED`, obtain the live piece with `board.get_piece_node(event.piece_id)`, follow it in their own `_process()`, and stop on `PIECE_DRAG_FINISHED` / `PIECE_DRAG_CANCELLED`. This keeps the event bus semantic and inexpensive.

## Option 1 — connect one specific signal

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    board.group_connection_succeeded.connect(_on_group_connected)
    board.puzzle_finished.connect(_on_puzzle_finished)

func _on_group_connected(event: JigsawPuzzleEvent) -> void:
    $SnapParticles.global_position = event.world_position
    $SnapParticles.restart()
    $SnapSound.play()

func _on_puzzle_finished(event: JigsawPuzzleEvent) -> void:
    $HUD.show_results()
```

## Option 2 — one event bus

Useful for score managers, telemetry or a centralized feedback controller:

```gdscript
func _ready() -> void:
    $JigsawBoard.event_emitted.connect(_on_puzzle_event)

func _on_puzzle_event(event: JigsawPuzzleEvent) -> void:
    match event.type:
        JigsawPuzzleEvent.Type.PUZZLE_STARTED:
            timer.start()
        JigsawPuzzleEvent.Type.GROUP_CONNECTED:
            score += event.group_size * 10
        JigsawPuzzleEvent.Type.PIECE_PLACEMENT_FAILED:
            mistakes += 1
        JigsawPuzzleEvent.Type.PUZZLE_COMPLETED:
            save_result()
```

## Option 3 — no-code / low-code Resource reactions

Add Resources to `JigsawPuzzleConfig.reactions`.

### JigsawAudioReaction

Create **JigsawAudioReaction**, select its event flags and assign an `AudioStream`. It can play globally or as 2D audio at `event.world_position`, with volume, bus and pitch variation.

Examples:
- `GROUP_CONNECTED` → cardboard click
- `PIECE_PLACEMENT_FAILED` + `GROUP_CONNECTION_FAILED` → soft error sound
- `PUZZLE_COMPLETED` → completion sting

### JigsawSpawnSceneReaction

Create **JigsawSpawnSceneReaction**, select event flags and assign a `PackedScene`. The root is spawned at the event position when it is a Node2D.

This works well for:
- GPUParticles2D bursts
- AnimatedSprite2D snap effects
- floating score labels
- short-lived custom VFX scenes

The spawned scene owns its own lifetime. If its root implements:

```gdscript
func setup_jigsaw_event(event: JigsawPuzzleEvent) -> void:
    # Customize text/color/intensity from event.group_size, event.success, etc.
    pass
```

the reaction passes the context automatically.

## Custom reusable reaction

Create a Resource script:

```gdscript
@tool
class_name ComboReaction
extends JigsawReaction

@export var points_per_piece := 25

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
    if event.type != JigsawPuzzleEvent.Type.GROUP_CONNECTED:
        return

    var score_manager = board.get_tree().get_first_node_in_group("score_manager")
    if score_manager:
        score_manager.add_points(event.group_size * points_per_piece)
```

Create a `ComboReaction.tres`, add it to `JigsawPuzzleConfig.reactions`, and reuse it in as many puzzle presets as needed.

Use the inherited **Event Mask** to avoid receiving unrelated events. An empty mask means “all events”.

### Reaction design rule

Reaction Resources may be shared by many boards, so treat them as **stateless definitions**. Keep session state in Nodes/autoloads. Do not store current combo, timer or piece references inside a shared Resource.

The Board snapshots the reaction list when a configuration is applied. Editing the Resource during play does not silently change the current event routing; call `apply_configuration()` or `configure()` to start a new puzzle with the new list. `PUZZLE_RESET` is delivered to the reactions that belonged to the puzzle being closed, while `PUZZLE_STARTED` is delivered to the newly applied list.

If a reaction needs to regenerate or switch puzzles in response to an event, defer that lifecycle change (for example with `call_deferred`) to avoid deeply nested rebuilds.

## Public helper queries

For custom systems JigsawBoard exposes:

- `get_piece_count()`
- `get_piece_node(piece_id)` — read-only transform hook for VFX
- `get_group_piece_ids(piece_id)`
- `get_piece_world_center(piece_id)`
- `get_dragged_piece_id()`
- `is_completed()`
- `get_configuration()`

Do not directly modify piece transforms returned by `get_piece_node()`; the board owns puzzle positioning and snapping.
