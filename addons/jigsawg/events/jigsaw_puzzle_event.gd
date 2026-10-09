class_name JigsawPuzzleEvent
extends RefCounted
## Immutable-by-convention context emitted by JigsawBoard.
## Consumers should read this object, not mutate puzzle state through it.

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
