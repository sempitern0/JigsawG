class_name JigsawPiece
extends Node2D
## Signals a changed bounding area (including animation-only transforms).
signal hit_shape_changed


func _init() -> void:
	# Board's spatial lookup must also notice direct Node2D transform changes.
	set_notify_local_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		hit_shape_changed.emit()
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

## Draw-only transform. The actual Node2D position/rotation remain authoritative.
## Custom motion adapters can animate this without corrupting snap, save or groups.
var display_transform := Transform2D.IDENTITY:
	set(value):
		display_transform = value
		queue_redraw()
		hit_shape_changed.emit()

var _display_tween: Tween

var _source_texture: Texture2D
var _uvs := PackedVector2Array()
var _closed_outline := PackedVector2Array()
var _shadow_outline := PackedVector2Array()
var _edge_opacity := 0.0
var _edge_width := 0.7
var _edge_color := Color(0.08, 0.075, 0.07, 1.0)
var _highlight_enabled := true
var _highlight_color := Color(1.0, 0.84, 0.38, 0.85)
var _highlight_width := 1.2
var _highlight_shadow_enabled := true
var _highlight_shadow_color := Color(0.0, 0.0, 0.0, 0.24)
var _highlight_shadow_offset := Vector2(3.0, 4.0)

func configure(
	piece_id: int,
	home_position: Vector2,
	shape: PackedVector2Array,
	source: Texture2D,
	sampling_mode: int = 0,
	edge_opacity: float = 0.0,
	edge_width: float = 0.7,
	highlight_enabled: bool = true,
	highlight_color: Color = Color(1.0, 0.84, 0.38, 0.85),
	highlight_width: float = 1.2,
	highlight_shadow_enabled: bool = true,
	highlight_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.24),
	highlight_shadow_offset: Vector2 = Vector2(3.0, 4.0),
	edge_color: Color = Color(0.08, 0.075, 0.07, 1.0)
) -> void:
	id = piece_id
	home = home_position
	polygon = shape
	_source_texture = source
	_edge_opacity = clampf(edge_opacity, 0.0, 1.0)
	_edge_width = maxf(edge_width, 0.1)
	_edge_color = edge_color
	_highlight_enabled = highlight_enabled
	_highlight_color = highlight_color
	_highlight_width = maxf(highlight_width, 0.1)
	_highlight_shadow_enabled = highlight_shadow_enabled
	_highlight_shadow_color = highlight_shadow_color
	_highlight_shadow_offset = highlight_shadow_offset

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
		_shadow_outline.append(point + _highlight_shadow_offset)
	bounds = Rect2(low, high - low)
	hit_shape_changed.emit()
	if polygon.size() >= 3:
		_closed_outline.append(polygon[0])
	queue_redraw()

## Start/replace a presentation tween while retaining the final logical transform.
## previous_board_transform must be in the same board-local coordinate system.
func animate_display_from(
	previous_board_transform: Transform2D,
	duration: float,
	transition: Tween.TransitionType = Tween.TRANS_CUBIC,
	easing: Tween.EaseType = Tween.EASE_OUT
) -> void:
	if _display_tween != null and _display_tween.is_valid():
		_display_tween.kill()
	display_transform = transform.affine_inverse() * previous_board_transform
	if duration <= 0.0:
		display_transform = Transform2D.IDENTITY
		return
	_display_tween = create_tween()
	_display_tween.tween_property(self, "display_transform", Transform2D.IDENTITY, duration).set_trans(transition).set_ease(easing)


func contains(world_point: Vector2) -> bool:
	var local := display_transform.affine_inverse() * to_local(world_point)
	return bounds.has_point(local) and Geometry2D.is_point_in_polygon(local, polygon)

func _draw() -> void:
	if _source_texture == null or polygon.size() < 3:
		return
	draw_set_transform_matrix(display_transform)
	if selected and _highlight_enabled and _highlight_shadow_enabled:
		draw_colored_polygon(_shadow_outline, _highlight_shadow_color)

	# UVs reference a single full-resolution source image for every piece.
	draw_colored_polygon(polygon, Color.WHITE, _uvs, _source_texture)

	# A dark/beveled outline drawn for every Bézier sample looked like a fuzzy
	# halo when zoomed out. Keep it opt-in and antialiased instead.
	if _edge_opacity > 0.001:
		draw_polyline(_closed_outline, Color(_edge_color.r, _edge_color.g, _edge_color.b, _edge_opacity * _edge_color.a), _edge_width, true)
	if selected and _highlight_enabled:
		draw_polyline(_closed_outline, _highlight_color, _highlight_width, true)
