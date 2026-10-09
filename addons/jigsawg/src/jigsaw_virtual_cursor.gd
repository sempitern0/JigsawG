extends Control
## Lightweight screen-space indicator. Host HUDs may replace/hide it.
## It never captures pointer input or modifies puzzle gameplay.

var cursor_position := Vector2.ZERO:
	set(value):
		cursor_position = value
		queue_redraw()

var over_piece := false:
	set(value):
		over_piece = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if not visible:
		return
	var color := Color(0.93, 0.83, 0.37) if over_piece else Color(0.93, 0.96, 1.0)
	draw_circle(cursor_position, 11.0, Color(0.04, 0.06, 0.09, 0.86))
	draw_arc(cursor_position, 11.0, 0.0, TAU, 32, color, 2.5, true)
	draw_line(cursor_position + Vector2(-17, 0), cursor_position + Vector2(-5, 0), color, 2.0, true)
	draw_line(cursor_position + Vector2(5, 0), cursor_position + Vector2(17, 0), color, 2.0, true)
	draw_line(cursor_position + Vector2(0, -17), cursor_position + Vector2(0, -5), color, 2.0, true)
	draw_line(cursor_position + Vector2(0, 5), cursor_position + Vector2(0, 17), color, 2.0, true)
