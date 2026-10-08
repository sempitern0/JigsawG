class_name JigsawPiece
extends Node2D
## One GPU-textured Bézier polygon per piece. No per-piece rasterized image.

var id: int
var home: Vector2
var polygon: PackedVector2Array
var bounds: Rect2
var selected := false:
	set(value):
		if selected == value:
			return
		selected = value
		queue_redraw()

var _source_texture: Texture2D
var _uvs := PackedVector2Array()
var _closed_outline := PackedVector2Array()
var _shadow_outline := PackedVector2Array()
var _edge_opacity := 0.0
var _edge_width := 0.7

const SHADOW_OFFSET := Vector2(3.0, 4.0)

func configure(piece_id: int, home_position: Vector2, shape: PackedVector2Array, source: Texture2D, sampling_mode: int = 0, edge_opacity: float = 0.0, edge_width: float = 0.7) -> void:
	id = piece_id
	home = home_position
	polygon = shape
	_source_texture = source
	_edge_opacity = clampf(edge_opacity, 0.0, 1.0)
	_edge_width = maxf(edge_width, 0.1)

	# Mipmaps are valuable at very small scales, but can soften image detail;
	# leave that choice to the caller, independently of Bézier tessellation.
	match sampling_mode:
		1:
			texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		2:
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_:
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var image_size := Vector2(source.get_size())
	_uvs.clear()
	_closed_outline.clear()
	_shadow_outline.clear()

	for point in polygon:
		low = low.min(point)
		high = high.max(point)
		_uvs.append((home + point) / image_size)
		_closed_outline.append(point)
		_shadow_outline.append(point + SHADOW_OFFSET)
	bounds = Rect2(low, high - low)
	if polygon.size() >= 3:
		_closed_outline.append(polygon[0])
	queue_redraw()

func contains(world_point: Vector2) -> bool:
	var local := to_local(world_point)
	return bounds.has_point(local) and Geometry2D.is_point_in_polygon(local, polygon)

func _draw() -> void:
	if _source_texture == null or polygon.size() < 3:
		return
	if selected:
		draw_colored_polygon(_shadow_outline, Color(0.0, 0.0, 0.0, 0.24))

	# UVs reference a single full-resolution source image for every piece.
	draw_colored_polygon(polygon, Color.WHITE, _uvs, _source_texture)

	# A dark/beveled outline drawn for every Bézier sample looked like a fuzzy
	# halo when zoomed out. Keep it opt-in and antialiased instead.
	if _edge_opacity > 0.001:
		draw_polyline(_closed_outline, Color(0.08, 0.075, 0.07, _edge_opacity), _edge_width, true)
	if selected:
		draw_polyline(_closed_outline, Color(1.0, 0.84, 0.38, 0.85), 1.2, true)
