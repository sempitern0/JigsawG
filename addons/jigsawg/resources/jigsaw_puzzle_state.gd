@tool
class_name JigsawPuzzleState
extends Resource
## Serializable snapshot of a JigsawBoard session.
## JigsawBoard creates/reads this Resource but never saves it to disk for you.

const SCHEMA_VERSION := 1

@export_group("Compatibility")
## State schema used to reject incompatible future formats.
@export var schema_version := SCHEMA_VERSION
## Grid dimensions captured with this state.
@export var columns := 0
@export var rows := 0
## Source image dimensions used by the board.
@export var source_size := Vector2i.ZERO
## Generation seed used to create matching silhouettes.
@export var generation_seed := 0
## Silhouette-family count used by the generated puzzle.
@export var silhouette_variants := 0
## Defaults preserve schema-1 saves produced with classic silhouettes.
@export var connector_family := 0
@export var connector_variation := 1.0

@export_group("Runtime State")
## Local JigsawBoard positions, one entry per piece.
@export var piece_positions := PackedVector2Array()
## Quarter-turn orientation (0–3), one entry per piece.
@export var piece_rotations := PackedInt32Array()
## Logical group id per piece. Equal ids belong to one connected group.
@export var piece_group_ids := PackedInt32Array()
## Mosaic pieces already locked to their solved positions.
@export var locked_piece_ids := PackedInt32Array()
## Whether the snapshot was already completed.
@export var completed := false

func get_piece_count() -> int:
	return piece_positions.size()
