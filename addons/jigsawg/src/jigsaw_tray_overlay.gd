extends Node2D
## Presentation only: the Board owns tray geometry and group placement.
## Draws beneath pieces and never handles mouse, touch or joypad input.

var tray_rectangles: Array[Rect2] = []
var tray_labels: PackedStringArray = PackedStringArray()


func update_trays(rectangles: Array[Rect2], labels: PackedStringArray) -> void:
	tray_rectangles = rectangles.duplicate()
	tray_labels = labels.duplicate()
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for i: int in range(tray_rectangles.size()):
		var rect: Rect2 = tray_rectangles[i]
		draw_rect(rect, Color(0.12, 0.18, 0.22, 0.24), true)
		draw_rect(rect, Color(0.52, 0.68, 0.73, 0.74), false, 2.0)
		if i < tray_labels.size() and font != null:
			draw_string(font, rect.position + Vector2(14, -8), tray_labels[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.92, 0.96, 1.0))
