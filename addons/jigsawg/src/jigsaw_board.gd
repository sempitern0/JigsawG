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

@export var puzzle_texture: Texture2D
@export_range(2, 40, 1) var columns := 5
@export_range(2, 40, 1) var rows := 4
@export_range(1, 8, 1) var silhouette_variants := 3
@export var generation_seed := 4729
@export_range(0.05, 0.5, 0.01) var snap_tolerance := 0.24
@export var initial_scatter := true
@export var auto_fit_camera := true
@export var drag_smoothing := 22.0

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

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	rebuild()

func rebuild() -> void:
	for piece in _pieces:
		if is_instance_valid(piece):
			remove_child(piece)
			piece.queue_free()
	_pieces.clear()
	_parents.clear()
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
	source.convert(Image.FORMAT_RGBA8)
	_piece_size = Vector2(source.get_size()) / Vector2(columns, rows)
	if _piece_size.x < 14 or _piece_size.y < 14:
		push_warning("JigsawG: source image is too small for this many pieces.")
		return
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
			var polygon: PackedVector2Array = Geometry.make_outline(_piece_size, sides[0], sides[1], sides[2], sides[3])
			var piece: JigsawPiece = PieceScript.new()
			piece.name = "Piece_%d_%d" % [c, r]
			add_child(piece)
			piece.configure(piece_id, home, polygon, source, Vector2i(floori(home.x), floori(home.y)))
			if initial_scatter:
				var radius := maxf(columns * _piece_size.x, rows * _piece_size.y) * 0.7
				var angle := _rng.randf_range(0, TAU)
				piece.position = home + Vector2(cos(angle), sin(angle)) * _rng.randf_range(radius * 0.45, radius)
			else:
				piece.position = home
			_pieces.append(piece)
			_parents.append(piece_id)
			_members[piece_id] = [piece_id]
	_camera = get_viewport().get_camera_2d()
	if auto_fit_camera and _camera:
		_fit_camera()
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _drag_root == -1:
			var mouse_position := get_global_mouse_position()
			for i in range(_pieces.size() - 1, -1, -1):
				if _pieces[i].contains(mouse_position):
					_dragged_piece = i
					_drag_root = _parents[i]
					_pointer_offset = _pieces[i].global_position - mouse_position
					_desired_position = _pieces[i].global_position
					for member in _members[_drag_root]:
						_pieces[member].selected = true
						_pieces[member].z_index = 10
						_pieces[member].queue_redraw()
					piece_picked.emit(i)
					get_viewport().set_input_as_handled()
					break
		elif not event.pressed and _drag_root != -1:
			# Commit the intended pointer position, not the last smoothed visual position.
			_move_group(_desired_position - _pieces[_dragged_piece].global_position)
			var connected := _connect_adjacent_groups()
			for member in _members[_parents[_dragged_piece]]:
				_pieces[member].selected = false
				_pieces[member].z_index = 0
				_pieces[member].queue_redraw()
			if not connected:
				connection_failed.emit(_dragged_piece)
			piece_released.emit(_dragged_piece, connected)
			_drag_root = -1
			_dragged_piece = -1
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _drag_root == -1 or _dragged_piece == -1:
		return
	_desired_position = get_global_mouse_position() + _pointer_offset
	var factor := 1.0 - exp(-drag_smoothing * delta)
	_move_group((_desired_position - _pieces[_dragged_piece].global_position) * factor)

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
				var expected: Vector2 = _pieces[index].home - _pieces[neighbor].home
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
				any_connection = true
				still_connecting = true
				break
			if still_connecting:
				break
	if _members.size() == 1 and not _finished:
		_finished = true
		puzzle_completed.emit()
	return any_connection

func _fit_camera() -> void:
	var extents := Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows))
	for piece in _pieces:
		extents = extents.expand(piece.position + piece.bounds.position)
		extents = extents.expand(piece.position + piece.bounds.end)
	var viewport_size := get_viewport_rect().size
	var frame := extents.size * 1.12
	if frame.x <= 0 or frame.y <= 0 or viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	_camera.global_position = to_global(extents.get_center())
	var zoom := minf(viewport_size.x / frame.x, viewport_size.y / frame.y)
	_camera.zoom = Vector2.ONE * clampf(zoom, 0.1, 4.0)
