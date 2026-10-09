class_name JigsawPuzzleEvent
extends RefCounted
## Immutable-by-convention context emitted by JigsawBoard.
## Consumers should read this object, not mutate puzzle state through it.

const REASON_REBUILD := &"rebuild"
const REASON_GENERATED := &"generated"
const REASON_POINTER_DOWN := &"pointer_down"
const REASON_RELEASED := &"released"
const REASON_PREVIEW_OPENED := &"preview_opened"
const REASON_CANCELLED := &"cancelled"
const REASON_WRONG_POSITION_OR_ROTATION := &"wrong_position_or_rotation"
const REASON_NO_COMPATIBLE_NEIGHBOR := &"no_compatible_neighbor"
const REASON_NEIGHBOR_SNAP := &"neighbor_snap"
const REASON_MOSAIC_SLOT := &"mosaic_slot"
const REASON_VISIBLE := &"visible"
const REASON_HIDDEN := &"hidden"
const REASON_SOLVED := &"solved"
const REASON_CLOCKWISE := &"clockwise"
const REASON_COUNTER_CLOCKWISE := &"counter_clockwise"
const REASON_RESUMED := &"resumed"
const REASON_SELECTION_PACKED := &"selection_packed"

enum Type {
	PUZZLE_RESET,
	PUZZLE_STARTED,
	PIECE_DRAG_STARTED,
	PIECE_DRAG_FINISHED,
	PIECE_DRAG_CANCELLED,
	PIECE_PLACED,
	PIECE_PLACEMENT_FAILED,
	GROUP_CONNECTED,
	GROUP_CONNECTION_FAILED,
	GROUP_ROTATED,
	PREVIEW_TOGGLED,
	PUZZLE_COMPLETED,
	PUZZLE_STATE_RESTORED,
	SELECTION_ARRANGED, # Appended to preserve saved event-mask bit indices.
}

var type: Type = Type.PUZZLE_STARTED
var board: Node2D
var piece_id := -1
var piece_ids := PackedInt32Array()
var group_size := 0
var world_position := Vector2.ZERO
var quarter_turns := 0
var success := false
var reason: StringName = &""
var metadata: Dictionary = {}
var timestamp_msec := 0

func _init(event_type: Type = Type.PUZZLE_STARTED) -> void:
	type = event_type
	timestamp_msec = Time.get_ticks_msec()

func get_type_name() -> StringName:
	return StringName(Type.keys()[int(type)])
