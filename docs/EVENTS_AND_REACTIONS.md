# Events and reactions

JigsawG keeps puzzle mechanics independent from your game's presentation. The board solves dragging, snapping, grouping, rotation and completion; your game decides what should happen visually or logically when those things occur.

There are three ways to react:

1. **No-code Resources** in `JigsawPuzzleConfig.reactions` — fastest for audio and reusable VFX.
2. **Typed signals** on `JigsawBoard` — ideal for scene-local UI or gameplay.
3. **`event_emitted(JigsawPuzzleEvent)`** — one event bus for score, analytics, progression or centralized feedback.

The compact legacy signals such as `piece_picked`, `pieces_connected` and `puzzle_completed` remain available for compatibility.

## Custom motion adapter: rotation and group arrangement

`JigsawPlayAnimationReaction` already plays host `AnimationPlayer` clips after events (including `GROUP_ROTATED`). It does **not** interpolate the JigsawPiece positions or rotation. To animate those movements, set **JigsawPuzzleConfig → Feedback → Motion Adapter** to a **New JigsawMotionAdapter** Resource. The included demo preset uses one, with separate rotation and arrangement timings, transition and easing. A null adapter retains instantaneous legacy gameplay.

The Board commits authoritative Node2D transforms immediately, then calls `motion_adapter.animate(board, motion)`. Each `JigsawMotionContext` describes the affected piece IDs, exact prior visual transforms, exact final logical transforms and `Kind.ROTATION` / `Kind.ARRANGEMENT`. The default adapter tweens only `JigsawPiece.display_transform` in `_draw()`. This preserves group adjacency, snapping, saved positions and rotation quantization. Piece hit tests follow the displayed silhouette while the tween runs. Overlapping tweens are replaced per piece and cleaned up when pieces are freed.

Custom example (save the script as a Resource, create an instance in the Inspector):

```gdscript
@tool
class_name GentleJigsawMotion
extends JigsawMotionAdapter

func animate(board: Node2D, motion: JigsawMotionContext) -> void:
    super.animate(board, motion)
    if motion.kind == JigsawMotionContext.Kind.ARRANGEMENT:
        # Add project-specific feedback here; all affected IDs are available.
        for piece_id in motion.piece_ids:
            var piece := board.get_piece_node(piece_id)
            if piece != null:
                piece.queue_redraw()
```

For a central handler without a Resource, connect `board.motion_requested.connect(func(motion): ...)`. For regular gameplay signals, `group_rotation_changed` and the new `selection_arranged` typed signal use `JigsawPuzzleEvent`, and both are emitted through `event_emitted` and available to `JigsawReaction` Resources. The `SELECTION_ARRANGED` event provides `metadata.selected_piece_ids` and `metadata.group_roots`. This event is emitted only when two or more detached groups are packed on drag start.

Avoid animating `JigsawPiece.position`, `rotation` or `global_transform` in custom effects: these are owned by JigsawBoard. Use `display_transform`, colors, shader parameters, particle scenes or other presentation-only properties. The motion adapter is a stateless Resource definition shared safely across boards.

---

---

## No-code quick start

Open the `JigsawPuzzleConfig` assigned to your `JigsawBoard`.

1. Expand **Reactions**.
2. Add an array element.
3. Choose **New JigsawAudioReaction** or **New JigsawSpawnSceneReaction**.
4. Expand the new Resource.
5. Under **Reaction → Event Mask**, tick the puzzle events that should trigger it.
6. Configure the sound or scene.
7. Run the puzzle.

An empty Event Mask means **every event**, so for normal effects select at least one flag.

Reactions execute in array order. You can stack several reactions on the same event—for example sound + particles + floating score text on a successful group connection.

### Recipe: sound when pieces/groups connect

Create a **JigsawAudioReaction**:

```text
Puzzle Config
└── Reactions
    └── JigsawAudioReaction
        ├── Event Mask
        │   └── Group Connected ✓
        ├── Stream: res://audio/puzzle_snap.ogg
        ├── Spatial: true
        ├── Bus: SFX
        ├── Volume Db: -2
        ├── Pitch Min: 0.96
        └── Pitch Max: 1.04
```

Every successful Free-mode connection now plays the sound at the snap position. The temporary `AudioStreamPlayer2D` is removed automatically when playback finishes.

### Recipe: one error sound for both gameplay modes

A single **JigsawAudioReaction** can listen to multiple events:

```text
Event Mask
├── Piece Placement Failed ✓
└── Group Connection Failed ✓
```

Assign a soft error sound. The same preset then works in both Mosaic and Free mode.

### Recipe: sparkle when a Mosaic piece is placed

Create a small scene such as:

```text
piece_sparkle.tscn
└── GPUParticles2D
```

Set the particles to start emitting when instantiated. Then create:

```text
JigsawSpawnSceneReaction
├── Event Mask
│   └── Piece Placed ✓
├── Scene: piece_sparkle.tscn
├── Parent Mode: Board Parent
├── Offset: (0, 0)
└── Auto Free After: 1.5
```

The scene is instantiated at `event.world_position` and removed after 1.5 seconds. No script is required on the effect.

### Recipe: effect that follows the dragged piece

Use **Piece Drag Started** and set:

```text
Parent Mode: Primary Piece
```

The spawned Node2D becomes a child of the piece and therefore follows its movement automatically. The Offset is local to that piece in this mode.

For a short pickup glow:

```text
JigsawSpawnSceneReaction
├── Event Mask
│   └── Piece Drag Started ✓
├── Scene: pickup_glow.tscn
├── Parent Mode: Primary Piece
└── Auto Free After: 0.4
```

For a continuous drag trail, let the spawned scene manage its own lifetime or combine it with a small custom reaction/script that stops it on **Piece Drag Finished** and **Piece Drag Cancelled**.

### Recipe: completion celebration

Create a scene containing your confetti, animation or full-screen effect, then:

```text
JigsawSpawnSceneReaction
├── Event Mask
│   └── Puzzle Completed ✓
├── Scene: puzzle_complete_fx.tscn
├── Parent Mode: Current Scene
└── Auto Free After: 4.0
```

Board-level events use the center of the solved puzzle as `event.world_position`, which is useful for world-space completion effects.

### Recommended reaction setup

A practical reusable puzzle preset can look like:

```text
JigsawPuzzleConfig
└── Reactions
    ├── [0] AudioReaction       → Piece Drag Started
    ├── [1] AudioReaction       → Group Connected
    ├── [2] SpawnSceneReaction  → Group Connected
    ├── [3] AudioReaction       → Placement Failed + Connection Failed
    ├── [4] SpawnSceneReaction  → Piece Placed
    ├── [5] AudioReaction       → Puzzle Completed
    └── [6] SpawnSceneReaction  → Puzzle Completed
```

Save individual reactions as external `.tres` files when you want to reuse the same sound/VFX language across many puzzle configs.

---

## Built-in reaction Resources

### JigsawAudioReaction

Plays a one-shot `AudioStream` when one of its selected events occurs.

| Property | Effect |
| --- | --- |
| `event_mask` | Events that trigger the reaction; empty means all |
| `stream` | AudioStream to play |
| `spatial` | true = AudioStreamPlayer2D at event position; false = global audio |
| `bus` | Host project's audio bus |
| `volume_db` | Playback volume |
| `pitch_min/max` | Random pitch range for subtle variation |

Programmatic equivalent:

```gdscript
var snap_sound := JigsawAudioReaction.new()
snap_sound.stream = load("res://audio/puzzle_snap.ogg")
snap_sound.event_mask = JigsawReaction.mask_for(
    JigsawPuzzleEvent.Type.GROUP_CONNECTED
)
config.reactions.append(snap_sound)
```

### JigsawPlayAnimationReaction

Use an existing `AnimationPlayer` in the host scene without writing Board scripts.

```text
JigsawPlayAnimationReaction
├── Event Mask            → Puzzle Completed ✓
├── Animation Player Path → ../WinAnimationPlayer
├── Animation Name        → celebrate
├── Speed                 → 1.0
└── Blend Time            → -1 (AnimationPlayer default)
```

The path resolves relative to the JigsawBoard. The target scene must contain an `AnimationPlayer` with that animation name. Common uses are celebratory transitions, UI animations and score flashes.

### JigsawCallMethodReaction

Invoke an existing method on a host-scene node. For example, show a previously hidden `Control` at puzzle completion, entirely through Resources:

```text
JigsawCallMethodReaction
├── Event Mask  → Puzzle Completed ✓
├── Target Path → ../ResultsPanel
├── Method Name → show
└── Pass Event  → false
```

Set `pass_event=true` if the receiver method accepts a single `JigsawPuzzleEvent` parameter. `target_path` is relative to the Board, not to the Resource location. Missing target nodes or methods result in warnings and are skipped. Only use developer-authored Resource configurations.

### JigsawSpawnSceneReaction

Instantiates a `PackedScene` when one of its selected events occurs.

| Property | Effect |
| --- | --- |
| `scene` | Scene to instantiate |
| `parent_mode` | Board, Board Parent, Current Scene or Primary Piece |
| `offset` | World offset, or local offset in Primary Piece mode |
| `auto_free_after` | Seconds before automatic cleanup; 0 = scene manages lifetime |
| `pass_event_to_scene` | Calls `setup_jigsaw_event(event)` when the spawned root implements it |

Use **Primary Piece** for short effects that should move with the source piece. Use **Board Parent** for normal world-space VFX. Use **Current Scene** for overlays or effects managed by the host scene.

If the spawned scene needs event data, optionally add:

```gdscript
func setup_jigsaw_event(event: JigsawPuzzleEvent) -> void:
    $Label.text = "+%d" % (event.group_size * 10)
```

The effect remains reusable because JigsawG passes the same event context to every scene.

---

## Event model

Every rich event is a `JigsawPuzzleEvent` with a common context:

| Field | Meaning |
| --- | --- |
| `type` | Semantic event type |
| `board` | Board that emitted the event |
| `piece_id` | Primary piece, or -1 for board-level events |
| `piece_ids` | Connected group membership at emission time |
| `group_size` | Number of pieces represented by `piece_ids` |
| `world_position` | World-space position intended for effects/audio |
| `quarter_turns` | Current orientation from 0 to 3 |
| `success` | Whether the interaction succeeded |
| `reason` | Stable `JigsawPuzzleEvent.REASON_*` value |
| `metadata` | Event-specific additional data |
| `timestamp_msec` | Engine tick time when the event was built |

### Event types

| Type | Typical use |
| --- | --- |
| `PUZZLE_RESET` | Clear temporary UI/VFX before regeneration |
| `PUZZLE_STARTED` | Start timer, music or tutorial |
| `PIECE_DRAG_STARTED` | Pickup audio, glow, short trail |
| `PIECE_DRAG_FINISHED` | Stop drag feedback, count a move |
| `PIECE_DRAG_CANCELLED` | Cleanup when preview/rebuild interrupts drag |
| `PIECE_PLACED` | Mosaic success feedback |
| `PIECE_PLACEMENT_FAILED` | Mosaic error feedback |
| `GROUP_CONNECTED` | Free-mode snap feedback, combo/scoring |
| `GROUP_CONNECTION_FAILED` | Free-mode invalid connection feedback |
| `GROUP_ROTATED` | Rotation sound or orientation UI |
| `PREVIEW_TOGGLED` | Pause timer or update help UI |
| `PUZZLE_COMPLETED` | Results, rewards, persistence |
| `PUZZLE_STATE_RESTORED` | Refresh HUD/timers after a saved session is applied |

JigsawG deliberately does **not** emit a per-frame drag event. High-frequency effects can follow the live piece returned by `board.get_piece_node(event.piece_id)` after **Piece Drag Started** and stop on Drag Finished/Cancelled. When multi-selection is active, drag lifecycle events also expose `event.metadata.selected_piece_ids`. This keeps the event API semantic and inexpensive.

---

## Signals: scene-local integration

Connect only what the scene needs:

```gdscript
@onready var board = $JigsawBoard

func _ready() -> void:
    board.group_connection_succeeded.connect(_on_group_connected)
    board.puzzle_finished.connect(_on_puzzle_finished)

func _on_group_connected(event: JigsawPuzzleEvent) -> void:
    score += event.group_size * 10

func _on_puzzle_finished(_event: JigsawPuzzleEvent) -> void:
    $ResultsScreen.open()
```

## One central event bus

For a score manager, analytics system or game-state controller:

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

---

## Custom reusable reaction

When the built-ins are not enough, extend `JigsawReaction`:

```gdscript
@tool
class_name ComboReaction
extends JigsawReaction

@export var points_per_piece := 25

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
    if event.type != JigsawPuzzleEvent.Type.GROUP_CONNECTED:
        return

    var score_manager := board.get_tree().get_first_node_in_group("score_manager")
    if score_manager:
        score_manager.add_points(event.group_size * points_per_piece)
```

Save it as `ComboReaction.tres`, place it in `JigsawPuzzleConfig.reactions`, and reuse it across puzzles.

### Reaction lifecycle rules

- Treat shared Reaction Resources as **stateless definitions**.
- Keep changing session state in Nodes/autoloads, not in shared Resources.
- The Board snapshots the reaction list when a configuration is applied.
- Resource edits during a running puzzle take effect on the next `apply_configuration()`, `configure()` or rebuild.
- `PUZZLE_RESET` goes to the reactions of the puzzle being closed; `PUZZLE_STARTED` goes to the newly applied set. When a config contains `resume_state`, `PUZZLE_STATE_RESTORED` follows `PUZZLE_STARTED`.
- If a reaction switches puzzles, defer that transition rather than rebuilding recursively inside the current event callback.

---

## Public helper queries

Custom systems can query the Board without touching its internals:

- `get_piece_count()`
- `get_piece_node(piece_id)` — read-only transform hook for effects
- `get_group_piece_ids(piece_id)`
- `get_piece_world_center(piece_id)`
- `get_dragged_piece_id()`
- `is_completed()`
- `get_configuration()`

Do not directly modify transforms returned by `get_piece_node()`; JigsawBoard owns puzzle positioning and snapping.
