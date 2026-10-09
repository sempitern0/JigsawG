class_name JigsawMotionContext
extends RefCounted
## Snapshot for presentation-only movement. The Board commits logical transforms first.
## Arrays correspond by index to piece_ids and must be treated as read-only.

enum Kind { ROTATION, ARRANGEMENT }

var kind: Kind = Kind.ROTATION
var piece_ids := PackedInt32Array()
var before_transforms: Array[Transform2D] = []
var after_transforms: Array[Transform2D] = []
