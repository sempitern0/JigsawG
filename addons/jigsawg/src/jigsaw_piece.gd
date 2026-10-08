extends Node2D
## Visual and hit-test representation of a single generated jigsaw piece.
var id: int
var home: Vector2
var image_texture: ImageTexture
var polygon: PackedVector2Array
var image_offset: Vector2
var bounds: Rect2
var selected := false

func configure(piece_id: int, home_position: Vector2, shape: PackedVector2Array, source: Image, sample_origin: Vector2i) -> void:
	id = piece_id
	home = home_position
	polygon = shape
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for vertex in shape:
		min_point = min_point.min(vertex)
		max_point = max_point.max(vertex)
	var min_pixel := Vector2i(floori(min_point.x), floori(min_point.y))
	var max_pixel := Vector2i(ceili(max_point.x), ceili(max_point.y))
	var dimensions := max_pixel - min_pixel + Vector2i.ONE
	var cropped := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var local_point := Vector2(x + min_pixel.x + 0.5, y + min_pixel.y + 0.5)
			if Geometry2D.is_point_in_polygon(local_point, polygon):
				var source_x := sample_origin.x + x + min_pixel.x
				var source_y := sample_origin.y + y + min_pixel.y
				if source_x >= 0 and source_y >= 0 and source_x < source.get_width() and source_y < source.get_height():
					cropped.set_pixel(x, y, source.get_pixel(source_x, source_y))
	image_texture = ImageTexture.create_from_image(cropped)
	image_offset = Vector2(min_pixel)
	bounds = Rect2(Vector2(min_pixel), Vector2(dimensions))
	queue_redraw()

func contains(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_point), polygon)

func _draw() -> void:
	if image_texture == null:
		return
	if selected:
		draw_texture(image_texture, image_offset + Vector2(3, 5), Color(0, 0, 0, 0.35))
	draw_texture(image_texture, image_offset)
	if selected:
		var closed := polygon.duplicate()
		closed.append(polygon[0])
		draw_polyline(closed, Color(1.0, 0.85, 0.35, 0.85), 1.8, true)
