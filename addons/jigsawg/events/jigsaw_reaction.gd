@tool
class_name JigsawReaction
extends Resource
## Base Resource for reusable reactions to JigsawBoard events.
##
## Extend this class and override react(). Keep shared Resource instances
## stateless; use the event context and board API for per-board state.

@export_group("Reaction")
## Disable this reaction without removing it from a puzzle config.
@export var enabled := true
## Empty mask listens to every event. Select flags to filter event types.
@export_flags(
	"Puzzle Reset",
	"Puzzle Started",
	"Piece Drag Started",
	"Piece Drag Finished",
	"Piece Drag Cancelled",
	"Piece Placed",
	"Piece Placement Failed",
	"Group Connected",
	"Group Connection Failed",
	"Group Rotated",
	"Preview Toggled",
	"Puzzle Completed"
) var event_mask := 0

func accepts(event: JigsawPuzzleEvent) -> bool:
	if not enabled:
		return false
	return event_mask == 0 or (event_mask & (1 << int(event.type))) != 0

## Override in a custom Resource script.
## Do not mutate shared configuration Resources from this callback.
func react(_board: Node2D, _event: JigsawPuzzleEvent) -> void:
	pass
