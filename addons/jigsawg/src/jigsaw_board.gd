@tool
extends Node2D
## Self-contained prototype: procedural tabs, grouping, smooth drag and deterministic regeneration.
signal puzzle_generated(piece_count: int)
signal pieces_connected(group_size: int)
signal puzzle_completed
signal piece_picked(piece_id: int)
signal piece_released(piece_id: int, connected: bool)
signal connection_failed(piece_id: int)

const PieceScript = preload("res://addons/jigsawg/src/jigsaw_piece.gd")
const Geometry = preload("res://addons/jigsawg/src/jigsaw_geometry.gd")
const PreviewOverlay = preload("res://addons/jigsawg/src/jigsaw_preview_overlay.gd")

enum GameMode { FREE, MOSAIC }
enum ShuffleMode { AROUND_BOARD, CENTER, BOTTOM }
enum DistributionMode { RANDOM, RADIAL }
enum VisualStyle { CLEAN, CARDBOARD, HIGH_CONTRAST }
enum AnimationStyle { NONE, SUBTLE, PLAYFUL }

## Assign a JigsawPuzzleConfig with texture, geometry, gameplay, camera and VFX.
## This is the only Inspector setting; rebuild() applies the Resource.
@export var puzzle_config: JigsawPuzzleConfig

# Runtime-only effective values, never serialized on the board.
var puzzle_texture: Texture2D
var columns := 5
var rows := 4
var silhouette_variants := 3
var generation_seed := 4729
var snap_tolerance := 0.24
var initial_scatter := true
var auto_fit_camera := true
var drag_smoothing := 22.0
var enable_camera_navigation := true
var invert_background_pan := false
var smooth_zoom := true
var zoom_smoothing := 12.0
var bezier_detail := 8
var shuffle_spacing := 0.14
var wheel_zoom_factor := 1.15
var min_zoom := 0.025
var max_zoom := 8.0
var edge_scroll_zone := 64.0
var edge_scroll_speed := 900.0
var texture_sampling := 0
var piece_edge_opacity := 0.0
var piece_edge_width := 0.7
var camera_outer_margin := 5.0
var restrict_camera := false
var game_mode: GameMode = GameMode.FREE
var shuffle_mode: ShuffleMode = ShuffleMode.AROUND_BOARD
var distribution_mode: DistributionMode = DistributionMode.RANDOM
var show_ghost_board := false:
	set(value):
		show_ghost_board = value
		_update_ghost_board()
var ghost_opacity := 0.25:
	set(value):
		ghost_opacity = value
		_update_ghost_board()
var preview_key: Key = KEY_P
var preview_dim := 0.82
var enable_preview := true
var visual_style: VisualStyle = VisualStyle.CLEAN
var animation_style: AnimationStyle = AnimationStyle.SUBTLE
var connect_animation_duration := 0.16
var allow_piece_rotation := false
var random_rotation_on_shuffle := true

signal preview_toggled(visible: bool)
signal piece_placed(piece_id: int)
signal group_placed(group_size: int)
signal group_rotated(piece_id: int, quarter_turns: int, group_size: int)

var _preview_overlay: CanvasLayer
var _ghost_board: Sprite2D
var _locked_pieces: Dictionary = {}
var _pieces: Array[JigsawPiece] = []
var _parents: Array[int] = []
var _members: Dictionary = {}
var _finished := false
var _drag_root := -1
var _dragged_piece := -1
var _pointer_offset := Vector2.ZERO
var _desired_position := Vector2.ZERO
var _piece_size := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _camera_pan := false
var _zoom_goal := 1.0
var _zoom_anchor := Vector2.ZERO
var _zoom_anchor_valid := false
var _pan_last_mouse := Vector2.ZERO
var _pan_bounds := Rect2()
var _fit_bounds := Rect2()
var _rotations: Array[int] = []
var _connector_depth := 0.25
var _active_feedback: JigsawFeedbackSettings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	rebuild()

## Assign a reusable config from code, optionally rebuilding immediately.
## This method never mutates the supplied Resource.
func configure(config: JigsawPuzzleConfig, regenerate: bool = true) -> void:
	puzzle_config = config
	if regenerate and is_inside_tree() and not Engine.is_editor_hint():
		rebuild()

## Reapply the currently assigned Resource (or legacy fields).
## Regeneration clears placement progress, groups and current shuffling.
func apply_configuration() -> void:
	if is_inside_tree() and not Engine.is_editor_hint():
		rebuild()

func get_configuration() -> JigsawPuzzleConfig:
	return puzzle_config

func rebuild() -> void:
	_apply_resource_presets()
	for piece in _pieces:
		if is_instance_valid(piece):
			remove_child(piece)
			piece.queue_free()
	_pieces.clear()
	_locked_pieces.clear()
	if is_instance_valid(_ghost_board):
		_ghost_board.queue_free()
		_ghost_board = null
	_parents.clear()
	_rotations.clear()
	_members.clear()
	_drag_root = -1
	_dragged_piece = -1
	_finished = false
	var source: Image
	if puzzle_texture != null:
		source = puzzle_texture.get_image()
	else:
		source = _make_demo_image()
	if source == null or source.is_empty():
		push_error("JigsawG: a readable source image is required.")
		return
	if columns < 2 or rows < 2 or silhouette_variants < 1 or silhouette_variants > 8:
		push_error("JigsawG: invalid grid dimensions or silhouette variant count.")
		return
	if minf(float(source.get_width()) / float(columns), float(source.get_height()) / float(rows)) < 14.0:
		push_warning("JigsawG: image is too small for the selected grid. Use fewer pieces or a larger image.")
		return
	source.convert(Image.FORMAT_RGBA8)
	if not source.has_mipmaps():
		source.generate_mipmaps()
	var shared_texture := ImageTexture.create_from_image(source)
	_piece_size = Vector2(source.get_size()) / Vector2(columns, rows)
	if not is_instance_valid(_preview_overlay):
		_preview_overlay = PreviewOverlay.new()
		_preview_overlay.name = "JigsawReferencePreview"
		add_child(_preview_overlay)
	_preview_overlay.configure(shared_texture, preview_dim, "%s · Close preview" % OS.get_keycode_string(preview_key))
	_preview_overlay.set_preview_visible(false)
	_ghost_board = Sprite2D.new()
	_ghost_board.name = "AssemblyGuide"
	_ghost_board.texture = shared_texture
	_ghost_board.centered = false
	_ghost_board.z_index = -10
	add_child(_ghost_board)
	_update_ghost_board()
	_rng.seed = generation_seed
	var horizontal: Dictionary = {}
	var vertical: Dictionary = {}
	for r in range(rows - 1):
		for c in range(columns):
			horizontal[Vector2i(c, r)] = _random_edge()
	for r in range(rows):
		for c in range(columns - 1):
			vertical[Vector2i(c, r)] = _random_edge()
	for r in range(rows):
		for c in range(columns):
			var piece_id := r * columns + c
			var home := Vector2(c, r) * _piece_size
			var sides := [
				horizontal.get(Vector2i(c, r - 1), Vector2i.ZERO) if r > 0 else Vector2i.ZERO,
				vertical.get(Vector2i(c, r), Vector2i.ZERO) if c < columns - 1 else Vector2i.ZERO,
				horizontal.get(Vector2i(c, r), Vector2i.ZERO) if r < rows - 1 else Vector2i.ZERO,
				vertical.get(Vector2i(c - 1, r), Vector2i.ZERO) if c > 0 else Vector2i.ZERO
			]
			var polygon: PackedVector2Array = Geometry.make_outline(_piece_size, sides[0], sides[1], sides[2], sides[3], bezier_detail, _connector_depth)
			var piece: JigsawPiece = PieceScript.new()
			piece.name = "Piece_%d_%d" % [c, r]
			add_child(piece)
			var rim_opacity := piece_edge_opacity
			var rim_width := piece_edge_width
			match visual_style:
				VisualStyle.CARDBOARD:
					rim_opacity = maxf(rim_opacity, 0.14)
					rim_width = maxf(rim_width, 0.8)
				VisualStyle.HIGH_CONTRAST:
					rim_opacity = maxf(rim_opacity, 0.55)
					rim_width = maxf(rim_width, 1.3)
			piece.configure(piece_id, home, polygon, shared_texture, texture_sampling, rim_opacity, rim_width)
			piece.position = home
			_pieces.append(piece)
			_rotations.append(0)
			_parents.append(piece_id)
			_members[piece_id] = [piece_id]
	if initial_scatter:
		_scatter_non_overlapping()
		if allow_piece_rotation and random_rotation_on_shuffle:
			for i in range(_pieces.size()):
				var center_before := _pieces[i].position + _piece_size * 0.5
				_set_piece_quarters(i, _rng.randi_range(0, 3))
				_pieces[i].position = center_before - (_piece_size * 0.5).rotated(_pieces[i].rotation)
	_camera = get_viewport().get_camera_2d()
	if _camera:
		_update_camera_bounds()
		if auto_fit_camera:
			_fit_camera()
		_zoom_goal = _camera.zoom.x
	puzzle_generated.emit(_pieces.size())

func _random_edge() -> Vector2i:
	return Vector2i(1 if _rng.randi_range(0, 1) == 0 else -1, _rng.randi_range(0, silhouette_variants - 1))

func _make_demo_image() -> Image:
	var image := Image.create(640, 480, false, Image.FORMAT_RGBA8)
	for y in range(480):
		for x in range(640):
			var checker := ((x / 80 + y / 80) % 2) == 0
			image.set_pixel(x, y, Color(0.20, 0.55, 0.77) if checker else Color(0.95, 0.64, 0.28))
	return image

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo and enable_preview and event.keycode == preview_key:
		set_preview_visible(not _preview_overlay.is_preview_visible())
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_preview_overlay) and _preview_overlay.is_preview_visible():
		if event is InputEventMouseButton and not event.pressed:
			_cancel_drag()
		return
	if enable_camera_navigation and _camera:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				_zoom_at_cursor(wheel_zoom_factor)
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				_zoom_at_cursor(1.0 / wheel_zoom_factor)
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _camera_pan:
				_camera_pan = false
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				_camera_pan = event.pressed
				_pan_last_mouse = get_viewport().get_mouse_position()
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseMotion and _camera_pan:
			var current_mouse := get_viewport().get_mouse_position()
			_camera.global_position += (current_mouse - _pan_last_mouse) / _camera.zoom.x * (1.0 if invert_background_pan else -1.0)
			_pan_last_mouse = current_mouse
			_limit_camera()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and allow_piece_rotation:
		if _rotate_under_cursor():
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _drag_root == -1:
			var mouse_position := get_global_mouse_position()
			for i in range(_pieces.size() - 1, -1, -1):
				if not _locked_pieces.has(i) and _pieces[i].contains(mouse_position):
					_dragged_piece = i
					_drag_root = _parents[i]
					_pointer_offset = _pieces[i].global_position - mouse_position
					_desired_position = _pieces[i].global_position
					for member in _members[_drag_root]:
						_pieces[member].selected = true
						_pieces[member].z_index = 10
						_pieces[member].queue_redraw()
					_animate_pickup(_members[_drag_root], true)
					piece_picked.emit(i)
					get_viewport().set_input_as_handled()
					break
			if _drag_root == -1 and enable_camera_navigation and _camera:
				_camera_pan = true
				_pan_last_mouse = get_viewport().get_mouse_position()
				get_viewport().set_input_as_handled()
		elif not event.pressed and _drag_root != -1:
			# Commit the intended pointer position, not the last smoothed visual position.
			_move_group(_desired_position - _pieces[_dragged_piece].global_position)
			var connected := _place_in_mosaic() if game_mode == GameMode.MOSAIC else _connect_adjacent_groups()
			for member in _members[_parents[_dragged_piece]]:
				_pieces[member].selected = false
				_pieces[member].z_index = 0
				_pieces[member].queue_redraw()
			_animate_pickup(_members[_parents[_dragged_piece]], false)
			if not connected:
				connection_failed.emit(_dragged_piece)
				_animate_failed_connection(_pieces[_dragged_piece])
			piece_released.emit(_dragged_piece, connected)
			_drag_root = -1
			_dragged_piece = -1
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if enable_camera_navigation and _camera and smooth_zoom:
		_update_smooth_zoom(delta)
	if _drag_root == -1 or _dragged_piece == -1:
		return
	if enable_camera_navigation and _camera:
		_edge_pan_camera(delta)
	_desired_position = get_global_mouse_position() + _pointer_offset
	var factor := 1.0 - exp(-drag_smoothing * delta)
	_move_group((_desired_position - _pieces[_dragged_piece].global_position) * factor)

## Stop an unfinished drag without snapping (e.g. when preview is opened).
func _cancel_drag() -> void:
	if _dragged_piece < 0:
		_camera_pan = false
		return
	for member in _members.get(_parents[_dragged_piece], []):
		var piece := _pieces[int(member)]
		piece.selected = false
		piece.z_index = 0
		piece.modulate = Color.WHITE
	_drag_root = -1
	_dragged_piece = -1
	_camera_pan = false

func _move_group(offset: Vector2) -> void:
	if _drag_root == -1:
		return
	for index in _members[_drag_root]:
		_pieces[index].global_position += offset

func _connect_adjacent_groups() -> bool:
	var any_connection := false
	var still_connecting := true
	while still_connecting:
		still_connecting = false
		var active_members: Array = _members[_parents[_dragged_piece]].duplicate()
		for index in active_members:
			var r: int = floori(float(index) / float(columns))
			var c: int = index % columns
			for neighbor in [index - columns if r > 0 else -1, index + 1 if c < columns - 1 else -1, index + columns if r < rows - 1 else -1, index - 1 if c > 0 else -1]:
				if neighbor == -1 or _parents[index] == _parents[neighbor]:
					continue
				if _rotations[index] != _rotations[neighbor]:
					continue
				var expected: Vector2 = (_pieces[index].home - _pieces[neighbor].home).rotated(float(_rotations[index]) * PI * 0.5)
				var actual: Vector2 = _pieces[index].global_position - _pieces[neighbor].global_position
				if actual.distance_to(expected) > minf(_piece_size.x, _piece_size.y) * snap_tolerance:
					continue
				var shift := expected - actual
				_move_group(shift)
				var old_root: int = _parents[neighbor]
				var new_root: int = _parents[_dragged_piece]
				for member in _members[old_root]:
					_parents[member] = new_root
					_members[new_root].append(member)
				_members.erase(old_root)
				pieces_connected.emit(_members[new_root].size())
				_animate_connection(_pieces[index])
				any_connection = true
				still_connecting = true
				break
			if still_connecting:
				break
	if _members.size() == 1 and not _finished:
		_finished = true
		puzzle_completed.emit()
	return any_connection

func _update_camera_bounds() -> void:
	_fit_bounds = Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows))
	for piece in _pieces:
		_fit_bounds = _fit_bounds.expand(piece.position + piece.bounds.position)
		_fit_bounds = _fit_bounds.expand(piece.position + piece.bounds.end)
	_pan_bounds = _fit_bounds.grow(maxf(_piece_size.x, _piece_size.y) * camera_outer_margin)

func _fit_camera() -> void:
	if _camera == null:
		return
	var frame := _fit_bounds.size * 1.08
	var screen := get_viewport_rect().size
	if frame.x <= 0.0 or frame.y <= 0.0 or screen.x <= 0.0 or screen.y <= 0.0:
		return
	_camera.global_position = to_global(_fit_bounds.get_center())
	var zoom := minf(screen.x / frame.x, screen.y / frame.y)
	_camera.zoom = Vector2.ONE * clampf(zoom, min_zoom, max_zoom)

func _zoom_at_cursor(multiplier: float) -> void:
	_zoom_goal = clampf(_zoom_goal * multiplier, min_zoom, max_zoom)
	if smooth_zoom:
		_zoom_anchor = get_viewport().get_mouse_position()
		_zoom_anchor_valid = true
	else:
		_apply_zoom(_zoom_goal, get_viewport().get_mouse_position())

func _update_smooth_zoom(delta: float) -> void:
	if absf(_camera.zoom.x - _zoom_goal) < 0.0001:
		return
	var factor := 1.0 - exp(-zoom_smoothing * delta)
	var zoom := lerpf(_camera.zoom.x, _zoom_goal, factor)
	_apply_zoom(zoom, _zoom_anchor if _zoom_anchor_valid else get_viewport_rect().size * 0.5)

func _apply_zoom(zoom: float, screen_anchor: Vector2) -> void:
	var world_before := _camera.get_canvas_transform().affine_inverse() * screen_anchor
	_camera.zoom = Vector2.ONE * zoom
	_camera.force_update_scroll()
	var world_after := _camera.get_canvas_transform().affine_inverse() * screen_anchor
	_camera.global_position += world_before - world_after
	_limit_camera()

func _edge_pan_camera(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	var cursor := get_viewport().get_mouse_position()
	if cursor.x < 0 or cursor.y < 0 or cursor.x > viewport_size.x or cursor.y > viewport_size.y:
		return
	var movement := Vector2.ZERO
	if cursor.x < edge_scroll_zone:
		movement.x = -1.0 + cursor.x / edge_scroll_zone
	elif cursor.x > viewport_size.x - edge_scroll_zone:
		movement.x = 1.0 - (viewport_size.x - cursor.x) / edge_scroll_zone
	if cursor.y < edge_scroll_zone:
		movement.y = -1.0 + cursor.y / edge_scroll_zone
	elif cursor.y > viewport_size.y - edge_scroll_zone:
		movement.y = 1.0 - (viewport_size.y - cursor.y) / edge_scroll_zone
	if movement != Vector2.ZERO:
		_camera.global_position += movement.limit_length(1.0) * edge_scroll_speed * delta / _camera.zoom.x
		_limit_camera()
		_camera.force_update_scroll()

func _limit_camera() -> void:
	if _camera == null or not restrict_camera:
		return
	var half_screen := get_viewport_rect().size / (_camera.zoom * 2.0)
	var limits := Rect2(to_global(_pan_bounds.position), _pan_bounds.size)
	var center := _camera.global_position
	for axis in range(2):
		if limits.size[axis] <= half_screen[axis] * 2.0:
			center[axis] = limits.get_center()[axis]
		else:
			center[axis] = clampf(center[axis], limits.position[axis] + half_screen[axis], limits.end[axis] - half_screen[axis])
	_camera.global_position = center

func _scatter_non_overlapping() -> void:
	# Conservative slot footprints avoid overlap, including Bézier protrusions.
	# Use a square footprint: a 90-degree turn swaps width and height.
	var footprint_side := maxf(_piece_size.x, _piece_size.y)
	var stride := Vector2.ONE * footprint_side * (1.65 + shuffle_spacing)
	var count := _pieces.size()
	var side_count := maxi(columns + 6, ceili(sqrt(float(count) * 3.0)))
	var slots: Array[Vector2] = []
	var board_rect := Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows))
	var forbidden := board_rect.grow(maxf(stride.x, stride.y))
	for y in range(-side_count, side_count + 1):
		for x in range(-side_count, side_count + 1):
			var slot := Vector2(x * stride.x, y * stride.y)
			var footprint := Rect2(slot - Vector2.ONE * footprint_side * 0.33, Vector2.ONE * footprint_side * 1.66)
			match shuffle_mode:
				ShuffleMode.AROUND_BOARD:
					if forbidden.intersects(footprint):
						continue
				ShuffleMode.BOTTOM:
					if footprint.position.y < board_rect.end.y + stride.y * 0.5:
						continue
				ShuffleMode.CENTER:
					pass
			slots.append(slot)
	var center := board_rect.get_center()
	if distribution_mode == DistributionMode.RADIAL:
		slots.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.distance_squared_to(center) < b.distance_squared_to(center))
	else:
		# Keep the closest slots; the seeded Fisher-Yates shuffle below assigns pieces.
		slots.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.distance_squared_to(center) < b.distance_squared_to(center))
	if slots.size() < count:
		push_warning("JigsawG: insufficient shuffle slots; increase available placement range.")
		return
	slots.resize(count)
	if distribution_mode == DistributionMode.RANDOM:
		for i in range(count - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var tmp: Vector2 = slots[i]
			slots[i] = slots[j]
			slots[j] = tmp
	for i in range(count):
		_pieces[i].position = slots[i]

func _update_ghost_board() -> void:
	if not is_instance_valid(_ghost_board):
		return
	_ghost_board.visible = show_ghost_board or game_mode == GameMode.MOSAIC
	_ghost_board.modulate.a = ghost_opacity

func set_preview_visible(visible: bool) -> void:
	if not enable_preview or not is_instance_valid(_preview_overlay):
		return
	if visible:
		_cancel_drag()
	_preview_overlay.set_preview_visible(visible)
	preview_toggled.emit(visible)

func _place_in_mosaic() -> bool:
	var piece := _pieces[_dragged_piece]
	if _rotations[_dragged_piece] != 0 or piece.position.distance_to(piece.home) > minf(_piece_size.x, _piece_size.y) * snap_tolerance:
		return false
	_move_group(piece.home - piece.position)
	_locked_pieces[_dragged_piece] = true
	piece_placed.emit(_dragged_piece)
	_animate_connection(piece)
	if _locked_pieces.size() == _pieces.size() and not _finished:
		_finished = true
		puzzle_completed.emit()
	return true

func _animate_pickup(members: Array, active: bool) -> void:
	# Tint only: scaling the nodes would change their visible seams and pointer hit test.
	var tint := (_active_feedback.pickup_tint if _active_feedback != null else Color(1.12, 1.09, 1.02, 1.0)) if active and animation_style == AnimationStyle.PLAYFUL else Color.WHITE
	for member in members:
		var piece := _pieces[int(member)]
		_tween_piece_tint(piece, tint)

func _animate_failed_connection(piece: JigsawPiece) -> void:
	if _active_feedback == null or not _active_feedback.enable_failure_feedback:
		return
	var tween := create_tween()
	tween.tween_property(piece, "modulate", _active_feedback.failure_tint, _active_feedback.failure_animation_duration * 0.5)
	tween.tween_property(piece, "modulate", Color.WHITE, _active_feedback.failure_animation_duration * 0.5)

func _animate_connection(piece: JigsawPiece) -> void:
	if animation_style == AnimationStyle.NONE:
		return
	var peak := _active_feedback.connect_tint if _active_feedback != null else (Color(1.22, 1.18, 0.93, 1.0) if animation_style == AnimationStyle.PLAYFUL else Color(1.10, 1.10, 1.02, 1.0))
	_tween_piece_tint(piece, peak)
	var tween := create_tween()
	tween.tween_property(piece, "modulate", Color.WHITE, connect_animation_duration)

func _tween_piece_tint(piece: JigsawPiece, tint: Color) -> void:
	if animation_style == AnimationStyle.NONE:
		piece.modulate = Color.WHITE
		return
	var tween := create_tween()
	tween.tween_property(piece, "modulate", tint, connect_animation_duration * 0.5)

## A Resource is a shared preset. Do not mutate it while applying it:
## assign only the board instance's properties.
## Apply only a complete root Resource. Null sections use their own defaults.
func _apply_resource_presets() -> void:
	var config := puzzle_config
	if config == null:
		config = JigsawPuzzleConfig.new()
	puzzle_texture = config.puzzle_texture
	columns = config.columns
	rows = config.rows
	silhouette_variants = config.silhouette_variants

	var gameplay := config.gameplay
	if gameplay == null:
		gameplay = JigsawGameplaySettings.new()
	game_mode = GameMode.MOSAIC if gameplay.game_mode == JigsawGameplaySettings.Mode.MOSAIC else GameMode.FREE
	snap_tolerance = gameplay.snap_tolerance
	allow_piece_rotation = gameplay.allow_piece_rotation
	random_rotation_on_shuffle = gameplay.random_rotation_on_shuffle
	match gameplay.shuffle_mode:
		JigsawGameplaySettings.Shuffle.CENTER:
			shuffle_mode = ShuffleMode.CENTER
		JigsawGameplaySettings.Shuffle.BOTTOM:
			shuffle_mode = ShuffleMode.BOTTOM
		_:
			shuffle_mode = ShuffleMode.AROUND_BOARD
	distribution_mode = DistributionMode.RADIAL if gameplay.distribution_mode == JigsawGameplaySettings.Distribution.RADIAL else DistributionMode.RANDOM
	initial_scatter = gameplay.initial_scatter
	shuffle_spacing = gameplay.shuffle_spacing
	generation_seed = gameplay.generation_seed
	show_ghost_board = gameplay.show_ghost_board
	ghost_opacity = gameplay.ghost_opacity
	enable_preview = gameplay.enable_preview
	preview_key = gameplay.preview_key
	preview_dim = gameplay.preview_dim

	var appearance := config.appearance
	if appearance == null:
		appearance = JigsawAppearanceSettings.new()
	_connector_depth = appearance.connector_depth
	match appearance.visual_style:
		JigsawAppearanceSettings.VisualStyle.CARDBOARD:
			visual_style = VisualStyle.CARDBOARD
		JigsawAppearanceSettings.VisualStyle.HIGH_CONTRAST:
			visual_style = VisualStyle.HIGH_CONTRAST
		_:
			visual_style = VisualStyle.CLEAN
	texture_sampling = appearance.texture_sampling
	bezier_detail = appearance.bezier_detail
	piece_edge_opacity = appearance.piece_edge_opacity
	piece_edge_width = appearance.piece_edge_width

	var camera_options := config.camera
	if camera_options == null:
		camera_options = JigsawCameraSettings.new()
	enable_camera_navigation = camera_options.enable_camera_navigation
	invert_background_pan = camera_options.invert_background_pan
	auto_fit_camera = camera_options.auto_fit_camera
	restrict_camera = camera_options.restrict_camera
	camera_outer_margin = camera_options.camera_outer_margin
	smooth_zoom = camera_options.smooth_zoom
	zoom_smoothing = camera_options.zoom_smoothing
	wheel_zoom_factor = camera_options.wheel_zoom_factor
	min_zoom = camera_options.min_zoom
	max_zoom = camera_options.max_zoom
	drag_smoothing = camera_options.drag_smoothing
	edge_scroll_zone = camera_options.edge_scroll_zone
	edge_scroll_speed = camera_options.edge_scroll_speed

	_active_feedback = config.feedback
	if _active_feedback == null:
		_active_feedback = JigsawFeedbackSettings.new()
	match _active_feedback.animation_style:
		JigsawFeedbackSettings.AnimationStyle.NONE:
			animation_style = AnimationStyle.NONE
		JigsawFeedbackSettings.AnimationStyle.PLAYFUL:
			animation_style = AnimationStyle.PLAYFUL
		_:
			animation_style = AnimationStyle.SUBTLE
	connect_animation_duration = _active_feedback.connect_animation_duration

func _set_piece_quarters(piece_index: int, quarters: int) -> void:
	_rotations[piece_index] = posmod(quarters, 4)
	_pieces[piece_index].rotation = float(_rotations[piece_index]) * PI * 0.5

func _rotate_under_cursor() -> bool:
	var hovered := -1
	var point := get_global_mouse_position()
	# Prefer the currently dragged group so rotation doesn't conflict with
	# the visual order or make the pointer jump to a different piece.
	if _dragged_piece >= 0:
		hovered = _dragged_piece
	else:
		for index in range(_pieces.size() - 1, -1, -1):
			if not _locked_pieces.has(index) and _pieces[index].contains(point):
				hovered = index
				break
	if hovered < 0:
		return false
	rotate_piece(hovered)
	return true

## Rotate a complete connected group by 90 degrees clockwise around this
## piece's center. Uses exact quarter-turns and never changes its UV mapping.
func rotate_piece(piece_index: int, clockwise: bool = true) -> void:
	if not allow_piece_rotation or piece_index < 0 or piece_index >= _pieces.size() or _locked_pieces.has(piece_index):
		return
	var turn := 1 if clockwise else -1
	var pivot := _pieces[piece_index].global_position + Vector2(_piece_size.x * 0.5, _piece_size.y * 0.5).rotated(_pieces[piece_index].global_rotation)
	var group_id := _parents[piece_index]
	var members: Array = _members[group_id]
	for member in members:
		var id: int = int(member)
		var old_center := _pieces[id].global_position + Vector2(_piece_size.x * 0.5, _piece_size.y * 0.5).rotated(_pieces[id].global_rotation)
		var next_center := pivot + (old_center - pivot).rotated(float(turn) * PI * 0.5)
		_set_piece_quarters(id, _rotations[id] + turn)
		_pieces[id].global_position = next_center - Vector2(_piece_size.x * 0.5, _piece_size.y * 0.5).rotated(_pieces[id].global_rotation)
	if _dragged_piece >= 0 and _parents[_dragged_piece] == group_id:
		_pointer_offset = _pieces[_dragged_piece].global_position - get_global_mouse_position()
		_desired_position = _pieces[_dragged_piece].global_position
	group_rotated.emit(piece_index, _rotations[piece_index], members.size())
