class_name JigsawPiece
extends Node2D
## GPU polygon renderer. All pieces sample ONE original image texture via UVs.
## This avoids per-piece CPU rasterization and keeps source detail when zoomed.

var id: int
var home: Vector2
var polygon: PackedVector2Array
var bounds: Rect2
var selected := false

var _source_texture: Texture2D
var _uvs := PackedVector2Array()
var _closed_outline := PackedVector2Array()
var _shadow_outline := PackedVector2Array()
var _bevel_colors := PackedColorArray()

const SHADOW_OFFSET := Vector2(3.5, 5.0)
const LIGHT_DIRECTION := Vector2(-0.6, -0.8)
const EDGE_WIDTH := 1.2

func configure(piece_id: int, home_position: Vector2, shape: PackedVector2Array, source: Texture2D) -> void:
	id = piece_id
	home = home_position
	polygon = shape
	_source_texture = source
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	var image_dimensions := Vector2(source.get_size())
	_uvs.clear()
	_closed_outline.clear()
	_shadow_outline.clear()
	_bevel_colors.clear()
	for point in polygon:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
		# UVs belong to the ORIGINAL source image, not the cropped piece.
		_uvs.append((home + point) / image_dimensions)
		_closed_outline.append(point)
		_shadow_outline.append(point + SHADOW_OFFSET)
	bounds = Rect2(min_point, max_point - min_point)
	if polygon.size() >= 3:
		_closed_outline.append(polygon[0])
		_shadow_outline.append(polygon[0] + SHADOW_OFFSET)
		for i in range(_closed_outline.size()):
			var before: Vector2 = _closed_outline[(i - 1 + polygon.size()) % polygon.size()]
			var after: Vector2 = _closed_outline[(i + 1) % polygon.size()]
			var tangent := (after - before).normalized()
			var outward := Vector2(tangent.y, -tangent.x)
			var facing := outward.dot(LIGHT_DIRECTION)
			_bevel_colors.append(Color(1.0, 0.98, 0.88, 0.24) if facing > 0.0 else Color(0.11, 0.09, 0.07, 0.25))
	queue_redraw()

func contains(world_point: Vector2) -> bool:
	if not bounds.has_point(to_local(world_point)):
		return false
	return Geometry2D.is_point_in_polygon(to_local(world_point), polygon)

func _draw() -> void:
	if _source_texture == null or polygon.size() < 3:
		return
	if selected:
		draw_colored_polygon(_shadow_outline, Color(0.0, 0.0, 0.0, 0.28))
	# The engine triangulates the concave contour and samples the full-resolution
	# source texture on the GPU. MSAA is enabled by the sample scene.
	draw_colored_polygon(polygon, Color.WHITE, _uvs, _source_texture)
	# Subtle cardboard rim; do not draw chunky opaque black outlines.
	draw_polyline_colors(_closed_outline, _bevel_colors, EDGE_WIDTH, true)
	if selected:
		draw_polyline(_closed_outline, Color(1.0, 0.82, 0.37, 0.86), 1.8, true)
