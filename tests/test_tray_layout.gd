extends SceneTree
## godot --headless --path . --script res://tests/test_tray_layout.gd
const TrayLayout = preload("res://addons/jigsawg/src/jigsaw_tray_layout.gd")


func _initialize() -> void:
	var rects: Array[Rect2] = [
		Rect2(Vector2(-50, 5), Vector2(60, 35)),
		Rect2(Vector2(420, 200), Vector2(30, 60)),
		Rect2(Vector2(300, -80), Vector2(65, 45))
	]
	var arrangement: Dictionary = TrayLayout.arrange(rects, Vector2(100, 500), 210.0, 15.0, 100.0)
	var slots: Array[Vector2] = arrangement["offsets"]
	var tray: Rect2 = arrangement["rect"]
	assert(slots.size() == rects.size())
	assert(tray.size.x >= 210.0 and tray.size.y >= 100.0)
	var placed: Array[Rect2] = []
	for i: int in range(rects.size()):
		var next_rect: Rect2 = Rect2(rects[i].position + slots[i], rects[i].size)
		assert(tray.encloses(next_rect))
		for prior: Rect2 in placed:
			assert(not prior.intersects(next_rect), "Tray groups must never overlap.")
		placed.append(next_rect)
	var another: Dictionary = TrayLayout.arrange(rects, Vector2(100, 500), 210.0, 15.0, 100.0)
	assert(another["rect"] == tray and another["offsets"] == slots)
	var empty: Dictionary = TrayLayout.arrange([], Vector2.ZERO, 120.0, 10.0, 80.0)
	assert(empty["rect"] == Rect2(Vector2.ZERO, Vector2(120, 80)))
	var rotated: Transform2D = Transform2D(PI * 0.5, Vector2(30, 40))
	var world_point: Vector2 = rotated * tray.get_center()
	assert(TrayLayout.contains_world_point(world_point, rotated, [tray]) == 0)
	assert(TrayLayout.contains_world_point(Vector2(-1000, -1000), rotated, [tray]) == -1)
	print("JigsawG tray shelf layout: PASS")
	quit()
