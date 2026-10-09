extends RefCounted
## Puzzle piece categories derived exclusively from the solved grid topology.
## No scene nodes, image pixels, rotation, appearance or group state involved.
## Stable enum order is mirrored by JigsawBoard.PieceCategory.
enum Category { CORNER, EDGE, INTERIOR }


static func category_for(piece_id: int, columns: int, rows: int) -> int:
	if columns < 2 or rows < 2 or piece_id < 0 or piece_id >= columns * rows:
		return -1
	var col: int = piece_id % columns
	var row: int = piece_id / columns
	var on_left_or_right: bool = col == 0 or col == columns - 1
	var on_top_or_bottom: bool = row == 0 or row == rows - 1
	if on_left_or_right and on_top_or_bottom:
		return Category.CORNER
	if on_left_or_right or on_top_or_bottom:
		return Category.EDGE
	return Category.INTERIOR


static func ids_for_category(columns: int, rows: int, category: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	if columns < 2 or rows < 2 or category < Category.CORNER or category > Category.INTERIOR:
		return result
	for piece_id in range(columns * rows):
		if category_for(piece_id, columns, rows) == category:
			result.append(piece_id)
	return result
