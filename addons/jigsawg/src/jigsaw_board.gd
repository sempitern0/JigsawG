@tool
extends Node2D
## Public puzzle component. Persistent behavior comes from JigsawPuzzleConfig;
## host games integrate through signals, JigsawPuzzleEvent and JigsawReaction.
## Compact compatibility signals. Prefer the rich semantic API below for new integrations.
signal puzzle_generated(piece_count: int)
## Incremental generation progress, emitted after each configured piece batch.
signal generation_progress_changed(generated: int, total: int)
## Warning emitted if native source detail per puzzle piece is low.
signal artwork_detail_warning(info: Dictionary)
signal pieces_connected(group_size: int)
signal puzzle_completed
signal piece_picked(piece_id: int)
signal piece_released(piece_id: int, connected: bool)
signal connection_failed(piece_id: int)

## Rich event API. event_emitted receives every semantic puzzle event.
signal event_emitted(event: JigsawPuzzleEvent)
signal puzzle_reset(event: JigsawPuzzleEvent)
signal puzzle_started(event: JigsawPuzzleEvent)
signal piece_drag_started(event: JigsawPuzzleEvent)
signal piece_drag_finished(event: JigsawPuzzleEvent)
signal piece_drag_cancelled(event: JigsawPuzzleEvent)
signal piece_placement_succeeded(event: JigsawPuzzleEvent)
signal piece_placement_failed(event: JigsawPuzzleEvent)
signal group_connection_succeeded(event: JigsawPuzzleEvent)
signal group_connection_failed(event: JigsawPuzzleEvent)
signal group_rotation_changed(event: JigsawPuzzleEvent)
## Emitted when independent selected groups are compacted for dragging.
signal selection_arranged(event: JigsawPuzzleEvent)
signal reference_preview_changed(event: JigsawPuzzleEvent)
signal puzzle_finished(event: JigsawPuzzleEvent)
signal puzzle_state_applied(event: JigsawPuzzleEvent)
## Normalized [0, 1] puzzle assembly progress; connect directly to a HUD.
signal progress_changed(progress: float)
## Host can disable player input without pausing scene processing.
signal interaction_enabled_changed(enabled: bool)
## One typed snapshot for each animated gameplay movement (rotation/arrangement).
signal motion_requested(motion: JigsawMotionContext)

const PieceScript = preload("res://addons/jigsawg/src/jigsaw_piece.gd")
const Geometry = preload("res://addons/jigsawg/src/jigsaw_geometry.gd")
const GridResolver = preload("res://addons/jigsawg/src/jigsaw_grid_resolver.gd")
const SelectionLayout = preload("res://addons/jigsawg/src/jigsaw_selection_layout.gd")
const HitIndex = preload("res://addons/jigsawg/src/jigsaw_hit_index.gd")
const PieceCatalog = preload("res://addons/jigsawg/src/jigsaw_piece_catalog.gd")
const VirtualCursor = preload("res://addons/jigsawg/src/jigsaw_virtual_cursor.gd")
const ScatterLayout = preload("res://addons/jigsawg/src/jigsaw_scatter_layout.gd")
const GroupModel = preload("res://addons/jigsawg/src/jigsaw_group_model.gd")
const ConnectionResolver = preload("res://addons/jigsawg/src/jigsaw_connection_resolver.gd")
const StateValidator = preload("res://addons/jigsawg/src/jigsaw_state_validator.gd")
const PreviewOverlay = preload("res://addons/jigsawg/src/jigsaw_preview_overlay.gd")

enum GameMode { FREE, MOSAIC }
## Grid-topology categories, unaffected by connector shape or rotation.
enum PieceCategory { CORNER, EDGE, INTERIOR }
enum ShuffleMode { AROUND_BOARD, CENTER, BOTTOM, CHAOTIC }
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
var snap_assist_extra_fraction := 0.0
var selection_assist_radius_px := 0.0
var initial_scatter := true
var auto_fit_camera := true
var drag_smoothing := 22.0
var enable_camera_navigation := true
var invert_background_pan := false
var smooth_pan := true
var pan_smoothing := 26.0
var smooth_zoom := true
var zoom_smoothing := 12.0
var bezier_detail := 8
var shuffle_spacing := 0.14
var wheel_zoom_factor := 1.15
var min_zoom := 0.005
var initial_focus := JigsawCameraSettings.InitialFocus.AUTO
var large_puzzle_threshold := 200
var focus_board_key: Key = KEY_HOME
var overview_key: Key = KEY_END
var focus_selection_key: Key = KEY_F
var focus_board_action: StringName = &""
var overview_action: StringName = &""
var focus_selection_action: StringName = &""
var zoom_in_action: StringName = &""
var zoom_out_action: StringName = &""
var selection_focus_padding := 1.0
var selection_focus_max_zoom := 2.0
var max_zoom := 8.0
var edge_scroll_zone := 64.0
var edge_scroll_speed := 900.0
var edge_scroll_smoothing := 12.0
var texture_sampling := 0
var piece_edge_opacity := 0.0
var piece_edge_width := 0.7
var piece_edge_color := Color(0.08, 0.075, 0.07, 1.0)
var piece_material: Material
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
var preview_action: StringName = &""
var rotate_action: StringName = &""
var preview_dim := 0.82
var enable_preview := true
var visual_style: VisualStyle = VisualStyle.CLEAN
var animation_style: AnimationStyle = AnimationStyle.SUBTLE
var reduced_motion := false
var connect_animation_duration := 0.16
var allow_piece_rotation := false
var random_rotation_on_shuffle := true
var enable_multi_select := true
var chaotic_spread := 2.2
var chaotic_max_attempts := 64
var background_pan_delay_ms := 70
var background_pan_threshold_px := 4.0
var highlight_enabled := true
var highlight_color := Color(1.0, 0.84, 0.38, 0.85)
var highlight_width := 1.2
var highlight_shadow_enabled := true
var highlight_shadow_color := Color(0.0, 0.0, 0.0, 0.24)
var highlight_shadow_offset := Vector2(3.0, 4.0)

signal preview_toggled(visible: bool)
signal piece_placed(piece_id: int)
signal group_rotated(piece_id: int, quarter_turns: int, group_size: int)
## Emitted after a compatible JigsawPuzzleState has been applied.
signal puzzle_state_restored(state: JigsawPuzzleState)

var _preview_overlay: CanvasLayer
var _ghost_board: Sprite2D
var _locked_pieces: Dictionary = {}
var _pieces: Array[JigsawPiece] = []
var _hit_index := HitIndex.new()
## Node-independent connectivity model, not replicated by this scene controller.
var _groups := GroupModel.new()
var _selected_piece_ids: Dictionary = {}
## Only the organizer browsing cursor; intentionally not saved.
var _organizer_last_focused: Dictionary = {}
var _organizer_corner_action: StringName = &""
var _organizer_edge_action: StringName = &""
var _organizer_interior_action: StringName = &""
var _organizer_corner_key: Key = KEY_NONE
var _organizer_edge_key: Key = KEY_NONE
var _organizer_interior_key: Key = KEY_NONE
var _multi_selection_mode := false
var _drag_visual_active := false
var _drag_start_screen := Vector2.ZERO
var _finished := false
var _drag_root := -1
var _dragged_piece := -1
var _pointer_offset := Vector2.ZERO
var _desired_position := Vector2.ZERO
var _piece_size := Vector2.ZERO
var _source_size := Vector2i.ZERO
var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _camera_pan := false
var _camera_pan_button := 0
var _background_pan_pending := false
var _background_pan_press_msec := 0
var _background_pan_press_mouse := Vector2.ZERO
var _camera_target_position := Vector2.ZERO
var _camera_target_ready := false
var _edge_pan_velocity := Vector2.ZERO
var _zoom_goal := 1.0
var _zoom_anchor := Vector2.ZERO
var _zoom_anchor_valid := false
var _pan_last_mouse := Vector2.ZERO
var _pan_bounds := Rect2()
var _fit_bounds := Rect2()
var _rotations: Array[int] = []
var _connector_depth := 0.25
var _connector_family := 0
var _connector_variation := 1.0
var _recommended_pixels_per_piece := 96
var _active_feedback: JigsawFeedbackSettings
var _active_reactions: Array[JigsawReaction] = []
var _restored_from_state := false
var _interaction_enabled := true
var _ghost_visibility_override := -1
var _generation_batch_size := 0
var _generation_serial := 0
var _generating := false
var _generation_total := 0

## Runtime-only input state; never part of JigsawPuzzleState.
var _device_input: JigsawDeviceInputSettings
var _device_pointer_active := false
var _device_pointer_screen := Vector2.ZERO
var _controller_cursor_active := false
var _controller_cursor_ready := false
var _controller_hover_delay := 0.0
var _controller_cursor_layer: CanvasLayer
var _controller_cursor_ui: VirtualCursor
var _touch_positions: Dictionary = {}
var _touch_primary := -1
var _touch_gesture_active := false
var _touch_last_center := Vector2.ZERO
var _touch_last_distance := 0.0
var _touch_suppress_mouse_until := 0

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

## True while a batch-based generation job is still building piece nodes.
func is_generating() -> bool:
	return _generating


## Counts of generated and planned pieces for loading UI.
func get_generation_progress() -> Vector2i:
	return Vector2i(_pieces.size(), _generation_total)


## Number of generated runtime pieces (may differ from Auto mode's requested count).
func get_piece_count() -> int:
	return _pieces.size()

## Actual grid in use; does not change the shared configuration Resource.
func get_effective_grid() -> Vector2i:
	return Vector2i(columns, rows)


## Native source texture resolution per piece. No filter can add missing detail.
func get_artwork_detail_info() -> Dictionary:
	if _source_size.x <= 0 or _source_size.y <= 0 or columns <= 0 or rows <= 0:
		return {}
	var native_width := float(_source_size.x) / float(columns)
	var native_height := float(_source_size.y) / float(rows)
	var side := minf(native_width, native_height)
	return {
		"source_size": _source_size,
		"grid": Vector2i(columns, rows),
		"piece_count": columns * rows,
		"native_pixels_per_piece": Vector2(native_width, native_height),
		"minimum_native_side_pixels": side,
		"recommended_minimum_side_pixels": _recommended_pixels_per_piece,
		"recommended_source_size": Vector2i(columns * _recommended_pixels_per_piece, rows * _recommended_pixels_per_piece),
		"below_recommendation": side < float(_recommended_pixels_per_piece)
	}

## Read-only integration hook for VFX that need to follow a piece.
## Do not change its transform; JigsawBoard owns puzzle positioning.
func get_piece_node(piece_id: int) -> Node2D:
	if piece_id < 0 or piece_id >= _pieces.size():
		return null
	return _pieces[piece_id]

## Current connected-group membership for a piece.
func get_group_piece_ids(piece_id: int) -> PackedInt32Array:
	return _groups.members_for(piece_id)

func get_piece_world_center(piece_id: int) -> Vector2:
	if piece_id < 0 or piece_id >= _pieces.size():
		return global_position
	var piece := _pieces[piece_id]
	return piece.global_position + (_piece_size * 0.5).rotated(piece.global_rotation)

func get_dragged_piece_id() -> int:
	return _dragged_piece

func is_completed() -> bool:
	return _finished

## Temporarily disable mouse/keyboard puzzle input while keeping the board visible.
## Useful for pause menus, dialogs and inventory overlays. No config rebuild.
func set_interaction_enabled(enabled: bool) -> void:
	if _interaction_enabled == enabled:
		return
	if not enabled:
		_cancel_drag(JigsawPuzzleEvent.REASON_CANCELLED)
		_end_device_pointer()
		_touch_positions.clear()
		_touch_primary = -1
		_touch_gesture_active = false
		_background_pan_pending = false
		_camera_pan = false
		_camera_pan_button = 0
		_edge_pan_velocity = Vector2.ZERO
	_interaction_enabled = enabled
	interaction_enabled_changed.emit(enabled)

func is_interaction_enabled() -> bool:
	return _interaction_enabled


## Host HUDs can display their own controller cursor; coordinates are in
## viewport pixels and are not stored in puzzle snapshots.
func is_controller_cursor_active() -> bool:
	return _controller_cursor_active


func get_controller_cursor_screen_position() -> Vector2:
	return _device_pointer_screen


## Runtime accessibility override for an options menu. Does not rebuild,
## modify the shared JigsawPuzzleConfig or touch puzzle state. The configured
## Resource defaults are restored on the next rebuild/apply_configuration().
func set_accessibility_assists(extra_snap_fraction: float, pointer_radius_px: float) -> void:
	snap_assist_extra_fraction = clampf(extra_snap_fraction, 0.0, 0.25)
	selection_assist_radius_px = clampf(pointer_radius_px, 0.0, 24.0)


func get_accessibility_assists() -> Vector2:
	return Vector2(snap_assist_extra_fraction, selection_assist_radius_px)


## Changes in an options menu take effect immediately and do not reset the
## puzzle or mutate the shared Feedback Resource. Rebuild restores the preset.
func set_reduced_motion(enabled: bool) -> void:
	if reduced_motion == enabled:
		return
	reduced_motion = enabled
	if not enabled:
		return
	for piece in _pieces:
		if is_instance_valid(piece):
			piece.cancel_visual_animations()
	if _camera != null:
		if not is_equal_approx(_camera.zoom.x, _zoom_goal):
			_apply_zoom(_zoom_goal, _zoom_anchor if _zoom_anchor_valid else get_viewport_rect().size * 0.5)
		if _camera_target_ready:
			_camera.global_position = _camera_target_position
			_camera.force_update_scroll()
	_zoom_anchor_valid = false
	_edge_pan_velocity = Vector2.ZERO


func is_reduced_motion() -> bool:
	return reduced_motion

## Reframe the current scattered/assembled pieces using the configured camera.
## Returns false if there is no active Camera2D.
func fit_view() -> bool:
	if _camera == null:
		return false
	_update_camera_bounds()
	_fit_camera()
	_finish_camera_framing()
	return true


## Frame only the puzzle assembly mat, keeping large pieces readable.
## Press Home (configurable) to focus the board; End frames all scattered pieces.
func focus_board() -> bool:
	if _camera == null or _piece_size == Vector2.ZERO:
		return false
	_fit_camera_to(Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows)))
	_finish_camera_framing()
	return true


## Reframe the last clicked or Ctrl-selected connected groups; leaves puzzle
## transforms and selection unchanged. Never interrupt an active drag.
func focus_selection() -> bool:
	if _camera == null or _generating or _drag_root >= 0 or _selected_piece_ids.is_empty():
		return false
	var seen: Dictionary = {}
	var combined := Rect2()
	var has_bounds := false
	var ids: Array = _selected_piece_ids.keys()
	ids.sort()
	for piece_variant in ids:
		var piece_id := int(piece_variant)
		if piece_id < 0 or piece_id >= _pieces.size() or _locked_pieces.has(piece_id):
			continue
		var root := _groups.root_of(piece_id)
		if root < 0 or seen.has(root):
			continue
		seen[root] = true
		var bounds := _group_bounds_local(root)
		if not has_bounds:
			combined = bounds
			has_bounds = true
		else:
			combined = combined.merge(bounds)
	if not has_bounds:
		return false
	var margin := maxf(_piece_size.x, _piece_size.y) * selection_focus_padding
	# Piece groups can move beyond the scatter bounds during play. Recalculate
	# before clamping so restricted cameras can still reach those groups.
	if restrict_camera:
		_update_camera_bounds()
	_fit_camera_to(combined.grow(margin))
	_camera.zoom = Vector2.ONE * maxf(min_zoom, minf(_camera.zoom.x, selection_focus_max_zoom))
	_limit_camera()
	_finish_camera_framing()
	return true


func _finish_camera_framing() -> void:
	_sync_camera_target()
	_zoom_goal = _camera.zoom.x
	_edge_pan_velocity = Vector2.ZERO
	_zoom_anchor_valid = false

## Fullscreen reference image can also be controlled by an external HUD.
func toggle_reference_preview() -> void:
	set_preview_visible(not is_reference_preview_visible())

func is_reference_preview_visible() -> bool:
	return is_instance_valid(_preview_overlay) and _preview_overlay.is_preview_visible()

## Override automatic ghost visibility at runtime, including in Mosaic mode.
## Does not modify shared JigsawPuzzleConfig. Reset by rebuild().
func set_ghost_guide_visible(visible: bool) -> void:
	_ghost_visibility_override = 1 if visible else 0
	_update_ghost_board()

func is_ghost_guide_visible() -> bool:
	return is_instance_valid(_ghost_board) and _ghost_board.visible

## Set runtime alpha without changing the Resource. Reset by rebuild().
func set_ghost_guide_opacity(opacity: float) -> void:
	ghost_opacity = clampf(opacity, 0.0, 1.0)

## Count connected groups in Free mode (or unjoined generated groups in Mosaic).
func get_connected_group_count() -> int:
	return _groups.group_count()

func get_locked_piece_count() -> int:
	return _locked_pieces.size()

## Normalized progress based on successful joins (Free) or locked slots (Mosaic).
## Does not measure time, physical puzzle location, or aesthetic completeness.
func get_progress() -> float:
	var total := _pieces.size()
	if total == 0:
		return 0.0
	if game_mode == GameMode.MOSAIC:
		return float(_locked_pieces.size()) / float(total)
	if total == 1:
		return 1.0
	return clampf(float(total - _groups.group_count()) / float(total - 1), 0.0, 1.0)

## Useful for HUDs without reading private board state.
func get_progress_info() -> Dictionary:
	return {
		"progress": get_progress(),
		"mode": game_mode,
		"columns": columns,
		"rows": rows,
		"total_pieces": _pieces.size(),
		"locked_pieces": _locked_pieces.size(),
		"group_count": _groups.group_count(),
		"connections_made": maxi(0, _pieces.size() - _groups.group_count()),
		"connections_needed": maxi(0, _pieces.size() - 1),
		"completed": _finished
	}

func _emit_progress_changed() -> void:
	progress_changed.emit(get_progress())

## Capture current positions, rotations, group graph and Mosaic locks into a new Resource.
## Persist it with ResourceSaver yourself, or assign it to JigsawPuzzleConfig.resume_state.
## Create a standalone config snapshot suitable for ResourceSaver.
## The returned Resource is detached from the board's original config.
func capture_resume_config() -> JigsawPuzzleConfig:
	var config: JigsawPuzzleConfig
	if puzzle_config != null:
		config = puzzle_config.duplicate(true) as JigsawPuzzleConfig
	else:
		config = JigsawPuzzleConfig.new()
	config.resume_state = capture_state()
	return config

func capture_state() -> JigsawPuzzleState:
	if _generating:
		push_warning("JigsawG: capture_state() requires a completed puzzle; await puzzle_generated.")
		return null
	var state := JigsawPuzzleState.new()
	state.columns = columns
	state.rows = rows
	state.source_size = _source_size
	state.generation_seed = generation_seed
	state.silhouette_variants = silhouette_variants
	state.connector_family = _connector_family
	state.connector_variation = _connector_variation
	state.connector_depth = _connector_depth
	state.bezier_detail = bezier_detail
	state.game_mode = game_mode
	state.completed = _finished

	for i in range(_pieces.size()):
		state.piece_positions.append(_pieces[i].position)
		state.piece_rotations.append(_rotations[i])
	# Group IDs are captured atomically from the node-free model.

	state.piece_group_ids = _groups.group_ids()

	var locked_ids: Array = _locked_pieces.keys()
	locked_ids.sort()
	for piece_id in locked_ids:
		state.locked_piece_ids.append(int(piece_id))
	return state

## Apply a compatible snapshot to an already generated board.
## Returns false and leaves the current puzzle unchanged when validation fails.
func restore_state(state: JigsawPuzzleState, update_camera: bool = true, emit_event: bool = true) -> bool:
	if _generating and update_camera:
		return false
	if _pieces.size() != columns * rows:
		return false
	var reason: String = StateValidator.validate(
		state, columns, rows, _source_size, generation_seed, silhouette_variants,
		_connector_family, _connector_variation, _connector_depth, bezier_detail, game_mode
	)
	if not reason.is_empty():
		push_warning("JigsawG: cannot restore state: " + reason)
		return false
	var count := _pieces.size()
	# Build a replacement graph first: no live model, drag or transforms are
	# changed if restoring the serialized group graph is invalid.
	var restored_groups := GroupModel.new()
	if not restored_groups.restore(state.piece_group_ids):
		push_warning("JigsawG: invalid group graph in saved state.")
		return false

	if _dragged_piece >= 0:
		_cancel_drag(JigsawPuzzleEvent.REASON_CANCELLED)
	clear_selection()
	_organizer_last_focused.clear()
	_groups = restored_groups
	_hit_index.invalidate()
	_locked_pieces.clear()

	for i in range(count):
		_pieces[i].position = state.piece_positions[i]
		_set_piece_quarters(i, state.piece_rotations[i])

	for locked_id in state.locked_piece_ids:
		_locked_pieces[int(locked_id)] = true
	_finished = state.completed
	_refresh_selection_visuals(false)

	if update_camera and _camera != null:
		_update_camera_bounds()
		if auto_fit_camera:
			if initial_focus == JigsawCameraSettings.InitialFocus.BOARD or (
				initial_focus == JigsawCameraSettings.InitialFocus.AUTO and _pieces.size() >= large_puzzle_threshold
			):
				_fit_camera_to(Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows)))
			else:
				_fit_camera()
		_sync_camera_target()

	if emit_event:
		_emit_progress_changed()
		puzzle_state_restored.emit(state)
		_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PUZZLE_STATE_RESTORED, -1, true, JigsawPuzzleEvent.REASON_RESUMED, {
			"completed": state.completed,
			"piece_count": state.get_piece_count()
		}))
	return true

## Return the original grid-based category for a piece, or -1 if invalid.
## Works after generation, including rotated and connected pieces.
func get_piece_category(piece_id: int) -> int:
	if _generating or piece_id < 0 or piece_id >= _pieces.size():
		return -1
	return PieceCatalog.category_for(piece_id, columns, rows)


## Sorted IDs of corners, border pieces excluding corners, or interior pieces.
## Locked Mosaic pieces are excluded by default; filtering does not modify them.
func get_piece_ids_by_category(category: PieceCategory, include_locked: bool = false) -> PackedInt32Array:
	var result := PackedInt32Array()
	if _generating or _pieces.size() != columns * rows:
		return result
	var ids: PackedInt32Array = PieceCatalog.ids_for_category(columns, rows, int(category))
	if include_locked or _locked_pieces.is_empty():
		return ids
	for piece_id: int in ids:
		if not _locked_pieces.has(piece_id):
			result.append(piece_id)
	return result


## Browse detached candidate groups without selecting/dragging or changing
## the snapshot. Returns the focused representative ID, or -1 if unavailable.
## A connected group containing multiple pieces in this category is visited
## only once per cycle, to avoid repetitive focus jumps.
func focus_next_piece_by_category(category: PieceCategory) -> int:
	if _camera == null or not _interaction_enabled or _generating or _drag_root >= 0 or is_reference_preview_visible():
		return -1
	var ids: PackedInt32Array = get_piece_ids_by_category(category)
	if ids.is_empty():
		return -1
	var visited_roots: Dictionary = {}
	var representatives := PackedInt32Array()
	for piece_id: int in ids:
		var root: int = _groups.root_of(piece_id)
		if root < 0 or visited_roots.has(root):
			continue
		visited_roots[root] = true
		representatives.append(piece_id)
	if representatives.is_empty():
		return -1
	var last_id: int = int(_organizer_last_focused.get(int(category), -1))
	var last_position: int = representatives.find(last_id)
	var focused_id: int = representatives[(last_position + 1) % representatives.size()]
	var root: int = _groups.root_of(focused_id)
	var margin: float = maxf(_piece_size.x, _piece_size.y) * selection_focus_padding
	if restrict_camera:
		_update_camera_bounds()
	_fit_camera_to(_group_bounds_local(root).grow(margin))
	_camera.zoom = Vector2.ONE * maxf(min_zoom, minf(_camera.zoom.x, selection_focus_max_zoom))
	_limit_camera()
	_finish_camera_framing()
	_organizer_last_focused[int(category)] = focused_id
	return focused_id


## Current multi-selection. Connected groups are always selected/deselected as a unit.
func get_selected_piece_ids() -> PackedInt32Array:
	var result := PackedInt32Array()
	var ids: Array = _selected_piece_ids.keys()
	ids.sort()
	for id in ids:
		result.append(int(id))
	return result

## Clear the current selection without changing puzzle positions.
func clear_selection() -> void:
	_selected_piece_ids.clear()
	_multi_selection_mode = false
	_refresh_selection_visuals()

## Select a piece's complete connected group. additive=false replaces the selection.
func select_piece(piece_id: int, additive: bool = false) -> void:
	if piece_id < 0 or piece_id >= _pieces.size() or _locked_pieces.has(piece_id):
		return
	if not additive:
		_selected_piece_ids.clear()
	_multi_selection_mode = additive
	for member in _groups.members_for(piece_id):
		_selected_piece_ids[int(member)] = true
	_refresh_selection_visuals()

func _toggle_group_selection(piece_id: int) -> void:
	if piece_id < 0 or piece_id >= _pieces.size() or _locked_pieces.has(piece_id):
		return
	# A previous normal click may have left an invisible drag target.
	# The first Ctrl+click must add it visibly, not toggle it off.
	if not _multi_selection_mode:
		_selected_piece_ids.clear()
	var members := _groups.members_for(piece_id)
	var fully_selected := true
	for member in members:
		if not _selected_piece_ids.has(int(member)):
			fully_selected = false
			break
	for member in members:
		var id := int(member)
		if fully_selected:
			_selected_piece_ids.erase(id)
		else:
			_selected_piece_ids[id] = true
	_multi_selection_mode = not _selected_piece_ids.is_empty()
	_refresh_selection_visuals()

func _refresh_selection_visuals(active_drag: bool = false) -> void:
	# Normal single selection stays visually neutral until the pointer actually moves.
	var should_highlight := active_drag or (_multi_selection_mode and not _selected_piece_ids.is_empty())
	for i in range(_pieces.size()):
		var selected := _selected_piece_ids.has(i) and not _locked_pieces.has(i)
		_pieces[i].selected = selected and should_highlight
		_pieces[i].z_index = 10 if selected and active_drag else (5 if selected and _multi_selection_mode else 0)

## Build the index only after scene geometry changes. Hit queries then inspect
## nearby piece AABBs, followed by the original precise polygon test.
func _refresh_hit_index() -> void:
	if not _hit_index.is_dirty():
		return
	var rectangles: Array[Rect2] = []
	for piece in _pieces:
		var local_transform: Transform2D = piece.transform * piece.display_transform
		var corners := [
			piece.bounds.position,
			Vector2(piece.bounds.end.x, piece.bounds.position.y),
			piece.bounds.end,
			Vector2(piece.bounds.position.x, piece.bounds.end.y)
		]
		var bounds := Rect2(local_transform * corners[0], Vector2.ZERO)
		for i in range(1, corners.size()):
			bounds = bounds.expand(local_transform * corners[i])
		rectangles.append(bounds)
	_hit_index.rebuild(rectangles, maxf(16.0, minf(_piece_size.x, _piece_size.y)))


func _find_piece_at(world_position: Vector2) -> int:
	_refresh_hit_index()
	var candidates := _hit_index.query(to_local(world_position))
	# Preserve exactly the old visual priority: in Ctrl mode, raised selected
	# groups win overlap; otherwise the highest-ID (latest drawn) piece wins.
	if _multi_selection_mode:
		for id in candidates:
			if _selected_piece_ids.has(id) and not _locked_pieces.has(id) and _pieces[id].contains(world_position):
				return id
	for id in candidates:
		if not _locked_pieces.has(id) and _pieces[id].contains(world_position):
			return id
	# The generous picking radius is optional and never takes precedence
	# over an actual visible polygon beneath the pointer.
	if selection_assist_radius_px <= 0.0:
		return -1
	var radius := clampf(selection_assist_radius_px, 0.0, 24.0)
	var canvas_transform := get_global_transform_with_canvas()
	var canvas_position: Vector2 = canvas_transform * to_local(world_position)
	var inverse_canvas := canvas_transform.affine_inverse()
	var corners := [
		canvas_position + Vector2(-radius, -radius),
		canvas_position + Vector2(radius, -radius),
		canvas_position + Vector2(radius, radius),
		canvas_position + Vector2(-radius, radius)
	]
	var region := Rect2(inverse_canvas * corners[0], Vector2.ZERO)
	for j in range(1, corners.size()):
		region = region.expand(inverse_canvas * corners[j])
	var nearest_id := -1
	var nearest_dist_sq := radius * radius
	var nearest_selected := false
	for id in _hit_index.query_region(region):
		if _locked_pieces.has(id):
			continue
		var dist_sq: float = _pieces[id].outline_distance_sq_screen(canvas_position)
		if dist_sq > radius * radius:
			continue
		var is_selected := _multi_selection_mode and _selected_piece_ids.has(id)
		if nearest_id < 0 or (is_selected and not nearest_selected) or (is_selected == nearest_selected and dist_sq < nearest_dist_sq):
			nearest_id = id
			nearest_dist_sq = dist_sq
			nearest_selected = is_selected
	return nearest_id

func _begin_piece_drag(piece_id: int, mouse_position: Vector2) -> void:
	if not _selected_piece_ids.has(piece_id):
		select_piece(piece_id, false)
	_dragged_piece = piece_id
	_drag_root = _groups.root_of(piece_id)
	_drag_visual_active = false
	_drag_start_screen = _get_pointer_screen()
	_pointer_offset = _pieces[piece_id].global_position - mouse_position
	_desired_position = _pieces[piece_id].global_position
	_refresh_selection_visuals(false)
	piece_picked.emit(piece_id)
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PIECE_DRAG_STARTED, piece_id, true, JigsawPuzzleEvent.REASON_POINTER_DOWN, {
		"selected_piece_ids": get_selected_piece_ids()
	}))

## Activate visual dragging only after pointer movement, not on a simple click.
func _activate_drag() -> void:
	if _drag_visual_active or _drag_root < 0:
		return
	_drag_visual_active = true
	_compact_selected_groups()
	_refresh_selection_visuals(true)
	_animate_pickup(_selected_piece_ids.keys(), true)


## A selected connected group must remain rigid; only detached groups are packed.
func _compact_selected_groups() -> void:
	var roots: Array[int] = []
	var seen: Dictionary = {}
	var selected_ids: Array = _selected_piece_ids.keys()
	selected_ids.sort()
	for piece_variant in selected_ids:
		var root: int = _groups.root_of(int(piece_variant))
		if not seen.has(root):
			roots.append(root)
			seen[root] = true
	if roots.size() <= 1:
		return
	roots.erase(_drag_root)
	roots.push_front(_drag_root)
	var moved_ids := get_selected_piece_ids()
	var previous := _capture_display_transforms(moved_ids)
	var rectangles: Array[Rect2] = []
	for root in roots:
		rectangles.append(_group_bounds_local(root))
	var offsets := SelectionLayout.pack(rectangles, minf(_piece_size.x, _piece_size.y) * 0.45)
	_hit_index.invalidate()
	for i in range(roots.size()):
		for member_variant in _groups.members_of_root(roots[i]):
			var piece_id := int(member_variant)
			_pieces[piece_id].position += offsets[i]
	_emit_motion(JigsawMotionContext.Kind.ARRANGEMENT, moved_ids, previous)
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.SELECTION_ARRANGED, _dragged_piece, true, JigsawPuzzleEvent.REASON_SELECTION_PACKED, {
		"selected_piece_ids": moved_ids,
		"group_roots": roots,
		"group_count": roots.size()
	}))


## Bounds include rotated Bézier tabs, not just the original image cell.
## Capture currently displayed local transforms, including a previous in-flight tween.
func _capture_display_transforms(piece_ids: PackedInt32Array) -> Array[Transform2D]:
	var result: Array[Transform2D] = []
	for id in piece_ids:
		var piece: JigsawPiece = _pieces[id]
		result.append(piece.transform * piece.display_transform)
	return result


## Dispatch a motion snapshot after logical transforms have been committed.
## Custom adapters animate presentation only; save/snap positions never interpolate.
func _emit_motion(kind: JigsawMotionContext.Kind, piece_ids: PackedInt32Array, previous: Array[Transform2D]) -> void:
	var motion := JigsawMotionContext.new()
	motion.kind = kind
	motion.piece_ids = piece_ids
	motion.before_transforms = previous
	for id in piece_ids:
		motion.after_transforms.append(_pieces[id].transform)
	if not reduced_motion and _active_feedback != null and _active_feedback.motion_adapter != null:
		_active_feedback.motion_adapter.animate(self, motion)
	motion_requested.emit(motion)


func _group_bounds_local(root: int) -> Rect2:
	var first_point := true
	var rect := Rect2()
	for piece_variant in _groups.members_of_root(root):
		var piece: JigsawPiece = _pieces[int(piece_variant)]
		var corners: Array[Vector2] = [
			piece.bounds.position,
			Vector2(piece.bounds.end.x, piece.bounds.position.y),
			piece.bounds.end,
			Vector2(piece.bounds.position.x, piece.bounds.end.y)
		]
		for corner in corners:
			var point: Vector2 = piece.transform * corner
			if first_point:
				rect = Rect2(point, Vector2.ZERO)
				first_point = false
			else:
				rect = rect.expand(point)
	return rect


func rebuild() -> void:
	# Cancel a prior coroutine on its next frame before changing the scene graph.
	_generation_serial += 1
	var build_id := _generation_serial
	_generating = false
	_generation_total = 0
	if not _pieces.is_empty():
		if _dragged_piece >= 0:
			_cancel_drag(JigsawPuzzleEvent.REASON_REBUILD)
		_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PUZZLE_RESET, -1, true, JigsawPuzzleEvent.REASON_REBUILD, {
			"piece_count": _pieces.size()
		}))
	_apply_resource_presets()
	_end_device_pointer()
	_touch_positions.clear()
	_touch_primary = -1
	_touch_gesture_active = false
	_controller_cursor_ready = false
	_setup_controller_overlay()
	for piece in _pieces:
		if is_instance_valid(piece):
			remove_child(piece)
			piece.queue_free()
	_pieces.clear()
	_hit_index.clear()
	_locked_pieces.clear()
	if is_instance_valid(_ghost_board):
		_ghost_board.queue_free()
		_ghost_board = null
	_groups.clear()
	_rotations.clear()
	_selected_piece_ids.clear()
	_organizer_last_focused.clear()
	_multi_selection_mode = false
	_drag_visual_active = false
	_drag_root = -1
	_dragged_piece = -1
	_finished = false
	_restored_from_state = false
	_ghost_visibility_override = -1
	var source: Image
	if puzzle_texture != null:
		source = puzzle_texture.get_image()
	else:
		source = _make_demo_image()
	if source == null or source.is_empty():
		push_error("JigsawG: a readable source image is required.")
		return
	if puzzle_config != null and puzzle_config.grid_mode == JigsawPuzzleConfig.GridMode.AUTO:
		var effective_grid := GridResolver.resolve(puzzle_config.target_piece_count, source.get_size())
		if effective_grid == Vector2i.ZERO:
			push_error("JigsawG: no valid grid for the requested piece count and source image.")
			return
		columns = effective_grid.x
		rows = effective_grid.y
	if columns < 2 or rows < 2 or silhouette_variants < 1 or silhouette_variants > 8:
		push_error("JigsawG: invalid grid dimensions or silhouette variant count.")
		return
	if minf(float(source.get_width()) / float(columns), float(source.get_height()) / float(rows)) < 14.0:
		push_warning("JigsawG: image is too small for the selected grid. Use fewer pieces or a larger image.")
		return
	source.convert(Image.FORMAT_RGBA8)
	_source_size = source.get_size()
	# Mipmaps cost extra memory and are used only with the Mipmaps filter.
	if texture_sampling == 2 and not source.has_mipmaps():
		source.generate_mipmaps()
	var info := get_artwork_detail_info()
	if info.get("below_recommendation", false):
		var size: Vector2i = info["recommended_source_size"]
		push_warning("JigsawG: image %dx%d / grid %dx%d yields %.1f native pixels per piece side. Recommended >= %d px/piece (~%dx%d source). Larger contour detail or sampling changes cannot restore missing artwork detail." % [
			_source_size.x, _source_size.y, columns, rows,
			info["minimum_native_side_pixels"], _recommended_pixels_per_piece,
			size.x, size.y
		])
		artwork_detail_warning.emit(info)
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

	# The complete mosaic already exists as a single guide texture. Frame it
	# before yielding so the first displayed batch never shows only one corner.
	# The final fit is still applied after scatter/restore as configured.
	if _generation_batch_size > 0:
		_prepare_batch_camera()
	_rng.seed = generation_seed
	_groups.reset(columns * rows)
	_generation_total = columns * rows
	_generating = true
	generation_progress_changed.emit(0, _generation_total)
	if _generation_batch_size > 0:
		# process_frame is emitted BEFORE drawing the next frame. Two
		# yields guarantee at least one real frame with only the complete
		# assembly guide before creating the first piece batch. Verify the
		# generation token after each yield to support immediate cancellation.
		for _frame_index in range(2):
			await get_tree().process_frame
			if build_id != _generation_serial or not is_inside_tree():
				return
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
			var polygon: PackedVector2Array = Geometry.make_outline(_piece_size, sides[0], sides[1], sides[2], sides[3], bezier_detail, _connector_depth, _connector_family, _connector_variation)
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
			piece.configure(
				piece_id,
				home,
				polygon,
				shared_texture,
				texture_sampling,
				rim_opacity,
				rim_width,
				highlight_enabled,
				highlight_color,
				highlight_width,
				highlight_shadow_enabled,
				highlight_shadow_color,
				highlight_shadow_offset,
				piece_edge_color
			)
			if piece_material != null:
				piece.material = piece_material
			piece.hit_shape_changed.connect(_hit_index.invalidate)
			piece.position = home
			_pieces.append(piece)
			_rotations.append(0)
			if _generation_batch_size > 0 and _pieces.size() % _generation_batch_size == 0 and _pieces.size() < _generation_total:
				generation_progress_changed.emit(_pieces.size(), _generation_total)
				await get_tree().process_frame
				if build_id != _generation_serial or not is_inside_tree():
					return
	if initial_scatter:
		_scatter_non_overlapping()
		if allow_piece_rotation and random_rotation_on_shuffle:
			for i in range(_pieces.size()):
				var center_before := _pieces[i].position + _piece_size * 0.5
				_set_piece_quarters(i, _rng.randi_range(0, 3))
				_pieces[i].position = center_before - (_piece_size * 0.5).rotated(_pieces[i].rotation)

	if puzzle_config != null and puzzle_config.resume_state != null:
		_restored_from_state = restore_state(puzzle_config.resume_state, false, false)

	_camera = get_viewport().get_camera_2d()
	if _camera:
		if smooth_pan and _camera.position_smoothing_enabled:
			push_warning("JigsawG: Camera2D position_smoothing_enabled is also active. Disable it or JigsawCameraSettings.smooth_pan to avoid double smoothing.")
		_update_camera_bounds()
		if auto_fit_camera:
			if initial_focus == JigsawCameraSettings.InitialFocus.BOARD or (
				initial_focus == JigsawCameraSettings.InitialFocus.AUTO and _pieces.size() >= large_puzzle_threshold
			):
				_fit_camera_to(Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows)))
			else:
				_fit_camera()
		_sync_camera_target()
		_edge_pan_velocity = Vector2.ZERO
		_zoom_goal = _camera.zoom.x
	else:
		_camera_target_ready = false
	_generating = false
	generation_progress_changed.emit(_pieces.size(), _generation_total)
	puzzle_generated.emit(_pieces.size())
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PUZZLE_STARTED, -1, true, JigsawPuzzleEvent.REASON_GENERATED, {
		"piece_count": _pieces.size(),
		"requested_piece_count": puzzle_config.target_piece_count if puzzle_config != null and puzzle_config.grid_mode == JigsawPuzzleConfig.GridMode.AUTO else _pieces.size(),
		"columns": columns,
		"rows": rows,
		"game_mode": game_mode,
		"rotation_enabled": allow_piece_rotation,
		"resumed": _restored_from_state
	}))
	if _restored_from_state and puzzle_config != null and puzzle_config.resume_state != null:
		puzzle_state_restored.emit(puzzle_config.resume_state)
		_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PUZZLE_STATE_RESTORED, -1, true, JigsawPuzzleEvent.REASON_RESUMED, {
			"completed": puzzle_config.resume_state.completed,
			"piece_count": puzzle_config.resume_state.get_piece_count()
		}))
	_emit_progress_changed()

## Batched builds yield while piece nodes do not yet exist, so fitting to
## _pieces at this stage would only capture an incomplete corner of the grid.
## Use the entire board's logical dimensions / guide texture instead.
func _prepare_batch_camera() -> void:
	_camera = get_viewport().get_camera_2d()
	if _camera == null:
		_camera_target_ready = false
		return
	var board_rect := Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows))
	_fit_bounds = board_rect
	_pan_bounds = board_rect.grow(maxf(_piece_size.x, _piece_size.y) * camera_outer_margin)
	if auto_fit_camera:
		_fit_camera_to(board_rect)
		# Camera2D updates are normally deferred until the canvas redraw.
		# Synchronize the first loading frame with the new fit immediately.
		_camera.force_update_scroll()
	_finish_camera_framing()


func _random_edge() -> Vector2i:
	var polarity := 1 if _rng.randi_range(0, 1) == 0 else -1
	var archetype := _rng.randi_range(0, silhouette_variants - 1)
	if _connector_family == JigsawAppearanceSettings.ConnectorFamily.ORGANIC:
		# Additional per-seam entropy: two pieces share the same seam token.
		# Legacy connector families retain exactly their previous RNG sequence.
		return Vector2i(polarity, archetype * 4096 + _rng.randi_range(0, 4095))
	return Vector2i(polarity, archetype)

func _make_demo_image() -> Image:
	var image := Image.create(640, 480, false, Image.FORMAT_RGBA8)
	for y in range(480):
		for x in range(640):
			var checker := ((x / 80 + y / 80) % 2) == 0
			image.set_pixel(x, y, Color(0.20, 0.55, 0.77) if checker else Color(0.95, 0.64, 0.28))
	return image

## No required InputMap entries or global input remapping. Existing mouse and
## keyboard controls still work; host-defined actions extend those controls.
func _matches_input_action(event: InputEvent, action: StringName) -> bool:
	if action == &"" or not InputMap.has_action(action):
		return false
	if event is InputEventKey and event.echo:
		return false
	return event.is_action_pressed(action)


## Pointer abstraction: mouse by default, screen-space touch/gamepad if active.
func _get_pointer_screen() -> Vector2:
	return _device_pointer_screen if _device_pointer_active else get_viewport().get_mouse_position()


func _get_pointer_world() -> Vector2:
	if not _device_pointer_active:
		return get_global_mouse_position()
	return get_canvas_transform().affine_inverse() * _device_pointer_screen


func _drag_threshold_screen() -> float:
	if _device_input != null and _touch_primary >= 0:
		return _device_input.touch_drag_threshold_px
	return 4.0


func _end_device_pointer() -> void:
	_device_pointer_active = false
	_controller_cursor_active = false
	_controller_hover_delay = 0.0
	if is_instance_valid(_controller_cursor_ui):
		_controller_cursor_ui.visible = false


func _setup_controller_overlay() -> void:
	if is_instance_valid(_controller_cursor_layer):
		_controller_cursor_layer.queue_free()
	_controller_cursor_layer = null
	_controller_cursor_ui = null
	if _device_input == null or not _device_input.enable_controller:
		return
	_controller_cursor_layer = CanvasLayer.new()
	_controller_cursor_layer.layer = 40
	add_child(_controller_cursor_layer)
	_controller_cursor_ui = VirtualCursor.new()
	_controller_cursor_layer.add_child(_controller_cursor_ui)
	_controller_cursor_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controller_cursor_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controller_cursor_ui.visible = false


func _activate_controller_cursor() -> void:
	if _device_input == null or not _device_input.enable_controller or _touch_primary >= 0 or _touch_gesture_active:
		return
	if not _controller_cursor_ready:
		_device_pointer_screen = get_viewport_rect().size * 0.5
		_controller_cursor_ready = true
	_controller_cursor_active = true
	_device_pointer_active = true
	if is_instance_valid(_controller_cursor_ui):
		_controller_cursor_ui.visible = true
		_controller_cursor_ui.cursor_position = _device_pointer_screen


## Read four optional, host-owned analog InputMap actions without installing
## or changing any global bindings.
func _device_vector(left: StringName, right: StringName, up: StringName, down: StringName) -> Vector2:
	if left == &"" or right == &"" or up == &"" or down == &"":
		return Vector2.ZERO
	for action_name: StringName in [left, right, up, down]:
		if not InputMap.has_action(action_name):
			return Vector2.ZERO
	return Input.get_vector(left, right, up, down, _device_input.stick_deadzone)


func _process_controller(delta: float) -> void:
	if _device_input == null or not _device_input.enable_controller or not _interaction_enabled or _generating:
		return
	if is_reference_preview_visible() or _touch_primary >= 0 or _touch_gesture_active:
		return
	var movement: Vector2 = _device_vector(
		_device_input.cursor_left_action, _device_input.cursor_right_action,
		_device_input.cursor_up_action, _device_input.cursor_down_action
	)
	if _device_input.use_joypad_defaults and Input.get_connected_joypads().has(_device_input.joypad_device) and movement.length_squared() <= 0.001:
		var raw_cursor: Vector2 = Vector2(
			Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_LEFT_Y)
		)
		movement = raw_cursor if raw_cursor.length() > _device_input.stick_deadzone else Vector2.ZERO
	if movement.length_squared() > 0.001:
		_activate_controller_cursor()
		var screen_size: Vector2 = get_viewport_rect().size
		_device_pointer_screen = (_device_pointer_screen + movement * _device_input.cursor_speed_px * delta).clamp(
			Vector2.ZERO, screen_size
		)
	if _controller_cursor_active and is_instance_valid(_controller_cursor_ui):
		_controller_cursor_ui.cursor_position = _device_pointer_screen
		_controller_hover_delay -= delta
		if movement.length_squared() > 0.001 or _hit_index.is_dirty() or _controller_hover_delay <= 0.0:
			_controller_cursor_ui.over_piece = _find_piece_at(_get_pointer_world()) >= 0
			_controller_hover_delay = 0.10
	if not enable_camera_navigation or _camera == null:
		return
	var camera_vector: Vector2 = _device_vector(
		_device_input.camera_left_action, _device_input.camera_right_action,
		_device_input.camera_up_action, _device_input.camera_down_action
	)
	if _device_input.use_joypad_defaults and Input.get_connected_joypads().has(_device_input.joypad_device) and camera_vector.length_squared() <= 0.001:
		var raw_camera: Vector2 = Vector2(
			Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_RIGHT_Y)
		)
		camera_vector = raw_camera if raw_camera.length() > _device_input.stick_deadzone else Vector2.ZERO
	if camera_vector.length_squared() > 0.001:
		_offset_camera_target(camera_vector * _device_input.camera_pan_speed_px * delta / maxf(_camera.zoom.x, 0.001))
	if _device_input.use_joypad_defaults and Input.get_connected_joypads().has(_device_input.joypad_device):
		var left_trigger: float = maxf(0.0, Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_TRIGGER_LEFT))
		var right_trigger: float = maxf(0.0, Input.get_joy_axis(_device_input.joypad_device, JOY_AXIS_TRIGGER_RIGHT))
		var zoom_input: float = right_trigger - left_trigger
		if absf(zoom_input) > _device_input.stick_deadzone:
			_activate_controller_cursor()
			_zoom_at_screen(powf(wheel_zoom_factor, zoom_input * delta * 5.0), _device_pointer_screen)


## Standard joypad: A grab, B cancel, X group toggle, Y preview, shoulders rotate,
## triggers zoom, left stick / D-pad cursor, right stick pan.
func _handle_joypad_button(event: InputEventJoypadButton) -> bool:
	if not _device_input.use_joypad_defaults or event.device != _device_input.joypad_device:
		return false
	match event.button_index:
		JOY_BUTTON_A:
			_activate_controller_cursor()
			if not _controller_cursor_active:
				return false
			if event.pressed and _drag_root < 0:
				var piece_id: int = _find_piece_at(_get_pointer_world())
				if piece_id >= 0:
					_begin_piece_drag(piece_id, _get_pointer_world())
				else:
					clear_selection()
			elif not event.pressed and _drag_root >= 0:
				_finish_pointer_drag(_device_pointer_screen, _get_pointer_world())
			return true
		JOY_BUTTON_B:
			if event.pressed and _controller_cursor_active and _drag_root >= 0:
				_cancel_drag()
				return true
		JOY_BUTTON_X:
			if event.pressed and enable_multi_select:
				_activate_controller_cursor()
				var selected_id: int = _find_piece_at(_get_pointer_world())
				if selected_id >= 0:
					_toggle_group_selection(selected_id)
				return true
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			if event.pressed and allow_piece_rotation:
				_activate_controller_cursor()
				var hovered: int = _dragged_piece if _dragged_piece >= 0 else _find_piece_at(_get_pointer_world())
				if hovered >= 0:
					rotate_piece(hovered, event.button_index == JOY_BUTTON_RIGHT_SHOULDER)
				return true
	return false


func _handle_controller_action(event: InputEvent) -> bool:
	if _device_input == null or not _device_input.enable_controller:
		return false
	# Y opens/closes the fullscreen reference even while that overlay is up.
	if event is InputEventJoypadButton:
		var joypad: InputEventJoypadButton = event as InputEventJoypadButton
		if _device_input.use_joypad_defaults and joypad.device == _device_input.joypad_device and joypad.button_index == JOY_BUTTON_Y:
			if joypad.pressed and enable_preview:
				toggle_reference_preview()
			return true
	if is_reference_preview_visible():
		return false
	if event is InputEventJoypadButton and _handle_joypad_button(event as InputEventJoypadButton):
		return true
	if _matches_input_action(event, _device_input.cancel_action):
		if _drag_root >= 0 and _controller_cursor_active:
			_cancel_drag()
			return true
		return false
	if _matches_input_action(event, _device_input.add_group_action):
		_activate_controller_cursor()
		if _controller_cursor_active:
			var hit: int = _find_piece_at(_get_pointer_world())
			if hit >= 0 and enable_multi_select:
				_toggle_group_selection(hit)
			return true
	if _matches_input_action(event, _device_input.grab_action):
		_activate_controller_cursor()
		if not _controller_cursor_active:
			return false
		if _drag_root < 0:
			var hovered: int = _find_piece_at(_get_pointer_world())
			if hovered >= 0:
				_begin_piece_drag(hovered, _get_pointer_world())
			else:
				clear_selection()
		return true
	if _device_input.grab_action != &"" and InputMap.has_action(_device_input.grab_action) and event.is_action_released(_device_input.grab_action):
		if _controller_cursor_active and _drag_root >= 0:
			_finish_pointer_drag(_device_pointer_screen, _get_pointer_world())
		return _controller_cursor_active
	return false


## Core release path used by mouse, touch and gamepad without fake mouse
## events. Only actual drag travel may attempt joining / placing a group.
func _finish_pointer_drag(pointer_screen: Vector2, pointer_world: Vector2) -> void:
	if _drag_root == -1 or _dragged_piece == -1:
		return
	if not _drag_visual_active and pointer_screen.distance_to(_drag_start_screen) >= _drag_threshold_screen():
		_activate_drag()
	var connected := false
	if _drag_visual_active:
		_desired_position = pointer_world + _pointer_offset
		_move_group(_desired_position - _pieces[_dragged_piece].global_position)
		connected = _place_selected_in_mosaic() if game_mode == GameMode.MOSAIC else _connect_selected_groups()
		_animate_pickup(_selected_piece_ids.keys(), false)
	_refresh_selection_visuals(false)
	var released_piece_id := _dragged_piece
	if _drag_visual_active and not connected:
		connection_failed.emit(released_piece_id)
		_animate_failed_connection(_pieces[released_piece_id])
		if game_mode == GameMode.FREE:
			_dispatch_event(_make_event(JigsawPuzzleEvent.Type.GROUP_CONNECTION_FAILED, released_piece_id, false, JigsawPuzzleEvent.REASON_NO_COMPATIBLE_NEIGHBOR))
	piece_released.emit(released_piece_id, connected)
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PIECE_DRAG_FINISHED, released_piece_id, connected, JigsawPuzzleEvent.REASON_RELEASED, {
		"selected_piece_ids": get_selected_piece_ids()
	}))
	_drag_root = -1
	_dragged_piece = -1
	_drag_visual_active = false


## Touch input uses the same Board pointer operations as mouse/controller.
## A second finger cancels picking and changes the interaction to a camera
## gesture; lifting that finger never resumes an old piece drag implicitly.
func _handle_touch_event(event: InputEvent) -> bool:
	if _device_input == null or not _device_input.enable_touch:
		return false
	if is_reference_preview_visible():
		return event is InputEventScreenTouch or event is InputEventScreenDrag
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		_touch_suppress_mouse_until = Time.get_ticks_msec() + 250
		if touch.pressed:
			if _touch_positions.has(touch.index):
				return true
			if _controller_cursor_active:
				if _drag_root >= 0:
					_cancel_drag()
				_end_device_pointer()
			_touch_positions[touch.index] = touch.position
			if _touch_positions.size() == 1:
				_touch_primary = touch.index
				_device_pointer_active = true
				_device_pointer_screen = touch.position
				var picked: int = _find_piece_at(_get_pointer_world())
				if picked >= 0:
					_begin_piece_drag(picked, _get_pointer_world())
			elif _touch_positions.size() == 2:
				if _drag_root >= 0:
					_cancel_drag()
				_touch_gesture_active = true
				_touch_primary = -1
				_device_pointer_active = false
				_reset_touch_gesture()
			return true
		if not _touch_positions.has(touch.index):
			return true
		var was_primary: bool = touch.index == _touch_primary
		if was_primary and not _touch_gesture_active:
			_device_pointer_screen = touch.position
			if _drag_root >= 0:
				_finish_pointer_drag(touch.position, _get_pointer_world())
			elif _touch_positions.size() == 1:
				clear_selection()
		_touch_positions.erase(touch.index)
		if _touch_positions.is_empty():
			_touch_primary = -1
			_touch_gesture_active = false
			_device_pointer_active = false
			_touch_last_distance = 0.0
		return true
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if not _touch_positions.has(drag.index):
			return true
		_touch_suppress_mouse_until = Time.get_ticks_msec() + 250
		_touch_positions[drag.index] = drag.position
		if _touch_gesture_active:
			_update_touch_gesture()
		elif drag.index == _touch_primary:
			_device_pointer_screen = drag.position
			if _drag_root >= 0 and not _drag_visual_active and _device_pointer_screen.distance_to(_drag_start_screen) >= _drag_threshold_screen():
				_activate_drag()
		return true
	return false


func _touch_pair() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var ids: Array = _touch_positions.keys()
	ids.sort()
	for id_variant in ids:
		if result.size() == 2:
			break
		var position: Vector2 = _touch_positions[id_variant]
		result.append(position)
	return result


func _reset_touch_gesture() -> void:
	var points: Array[Vector2] = _touch_pair()
	if points.size() < 2:
		return
	_touch_last_center = (points[0] + points[1]) * 0.5
	_touch_last_distance = points[0].distance_to(points[1])


func _update_touch_gesture() -> void:
	if not _device_input.touch_pinch_and_pan or _camera == null or not enable_camera_navigation:
		return
	var points: Array[Vector2] = _touch_pair()
	if points.size() < 2:
		return
	var center: Vector2 = (points[0] + points[1]) * 0.5
	var distance: float = points[0].distance_to(points[1])
	if _touch_last_distance >= 2.0 and distance >= 2.0:
		var zoom: float = clampf(_camera.zoom.x * distance / _touch_last_distance, min_zoom, max_zoom)
		_zoom_goal = zoom
		_apply_zoom(zoom, center)
		_zoom_anchor_valid = false
	var screen_shift: Vector2 = center - _touch_last_center
	if _camera != null and screen_shift != Vector2.ZERO:
		_camera.global_position = _clamp_camera_position(
			_camera.global_position - screen_shift / maxf(_camera.zoom.x, 0.001)
		)
		_camera.force_update_scroll()
		_sync_camera_target()
	_touch_last_center = center
	_touch_last_distance = distance


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _interaction_enabled or _generating:
		return

	if _handle_touch_event(event):
		get_viewport().set_input_as_handled()
		return

	# Native touch is authoritative when enabled. Ignore OS-generated mouse
	# duplicates briefly; real mouse movement switches control afterward.
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if _device_input != null and _device_input.enable_touch and Time.get_ticks_msec() <= _touch_suppress_mouse_until:
			return
		if _controller_cursor_active:
			if _drag_root >= 0:
				_cancel_drag()
			_end_device_pointer()

	if _handle_controller_action(event):
		get_viewport().set_input_as_handled()
		return

	if enable_camera_navigation and _camera != null:
		if _matches_input_action(event, focus_board_action):
			if focus_board():
				get_viewport().set_input_as_handled()
			return
		if _matches_input_action(event, overview_action):
			if fit_view():
				get_viewport().set_input_as_handled()
			return
		if _matches_input_action(event, focus_selection_action):
			if focus_selection():
				get_viewport().set_input_as_handled()
			return
		if _matches_input_action(event, zoom_in_action):
			_zoom_at_cursor(wheel_zoom_factor)
			get_viewport().set_input_as_handled()
			return
		if _matches_input_action(event, zoom_out_action):
			_zoom_at_cursor(1.0 / wheel_zoom_factor)
			get_viewport().set_input_as_handled()
			return

	if enable_preview and _matches_input_action(event, preview_action):
		toggle_reference_preview()
		get_viewport().set_input_as_handled()
		return

	if allow_piece_rotation and _matches_input_action(event, rotate_action):
		if _rotate_under_cursor():
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and enable_camera_navigation and _camera != null:
		if event.keycode == focus_board_key and focus_board_key != KEY_NONE:
			if focus_board():
				get_viewport().set_input_as_handled()
			return
		if event.keycode == overview_key and overview_key != KEY_NONE:
			if fit_view():
				get_viewport().set_input_as_handled()
			return
		if event.keycode == focus_selection_key and focus_selection_key != KEY_NONE:
			if focus_selection():
				get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo and enable_preview and event.keycode == preview_key:
		set_preview_visible(not _preview_overlay.is_preview_visible())
		get_viewport().set_input_as_handled()
		return

	if is_instance_valid(_preview_overlay) and _preview_overlay.is_preview_visible():
		if event is InputEventMouseButton and not event.pressed:
			_cancel_drag()
		return

	# The host owns the optional binding. Browsing only reframes the camera,
	# leaving piece selection, group graph and saved state completely intact.
	if event is InputEventKey and event.pressed and not event.echo:
		var organizer_key: Key = event.keycode
		if organizer_key != KEY_NONE:
			var focused_category: bool = false
			var focused_id: int = -1
			if organizer_key == _organizer_corner_key:
				focused_category = true
				focused_id = focus_next_piece_by_category(PieceCategory.CORNER)
			elif organizer_key == _organizer_edge_key:
				focused_category = true
				focused_id = focus_next_piece_by_category(PieceCategory.EDGE)
			elif organizer_key == _organizer_interior_key:
				focused_category = true
				focused_id = focus_next_piece_by_category(PieceCategory.INTERIOR)
			if focused_category:
				if focused_id >= 0:
					get_viewport().set_input_as_handled()
				return
	if _matches_input_action(event, _organizer_corner_action):
		if focus_next_piece_by_category(PieceCategory.CORNER) >= 0:
			get_viewport().set_input_as_handled()
		return
	if _matches_input_action(event, _organizer_edge_action):
		if focus_next_piece_by_category(PieceCategory.EDGE) >= 0:
			get_viewport().set_input_as_handled()
		return
	if _matches_input_action(event, _organizer_interior_action):
		if focus_next_piece_by_category(PieceCategory.INTERIOR) >= 0:
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if enable_camera_navigation and _camera:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				_zoom_at_cursor(wheel_zoom_factor)
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				_zoom_at_cursor(1.0 / wheel_zoom_factor)
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				_background_pan_pending = false
				_camera_pan = event.pressed
				_camera_pan_button = MOUSE_BUTTON_MIDDLE if event.pressed else 0
				_pan_last_mouse = get_viewport().get_mouse_position()
				get_viewport().set_input_as_handled()
				return

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and allow_piece_rotation:
			if _rotate_under_cursor():
				get_viewport().set_input_as_handled()
				return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _drag_root == -1:
				var mouse_world := get_global_mouse_position()
				var hit_piece := _find_piece_at(mouse_world)
				if hit_piece >= 0:
					_background_pan_pending = false
					if enable_multi_select and event.ctrl_pressed:
						_toggle_group_selection(hit_piece)
						get_viewport().set_input_as_handled()
						return
					_begin_piece_drag(hit_piece, mouse_world)
					get_viewport().set_input_as_handled()
					return

				if enable_camera_navigation and _camera:
					_background_pan_pending = true
					_background_pan_press_msec = Time.get_ticks_msec()
					_background_pan_press_mouse = get_viewport().get_mouse_position()
					_pan_last_mouse = _background_pan_press_mouse
					get_viewport().set_input_as_handled()
					return
				if not event.ctrl_pressed:
					clear_selection()
				return

			if not event.pressed:
				if _drag_root != -1 and _dragged_piece != -1:
					_finish_pointer_drag(_get_pointer_screen(), _get_pointer_world())
					get_viewport().set_input_as_handled()
					return

				if _background_pan_pending:
					_background_pan_pending = false
					if not event.ctrl_pressed:
						clear_selection()
					get_viewport().set_input_as_handled()
					return

				if _camera_pan and _camera_pan_button == MOUSE_BUTTON_LEFT:
					_camera_pan = false
					_camera_pan_button = 0
					get_viewport().set_input_as_handled()
					return

	if event is InputEventMouseMotion and enable_camera_navigation and _camera:
		var current_mouse := get_viewport().get_mouse_position()
		if _background_pan_pending:
			var elapsed := Time.get_ticks_msec() - _background_pan_press_msec
			var moved := current_mouse.distance_to(_background_pan_press_mouse)
			if elapsed >= background_pan_delay_ms and moved >= background_pan_threshold_px:
				_background_pan_pending = false
				_camera_pan = true
				_camera_pan_button = MOUSE_BUTTON_LEFT
				_pan_last_mouse = current_mouse
			get_viewport().set_input_as_handled()
			return

		if _camera_pan:
			var pan_delta := (current_mouse - _pan_last_mouse) / _camera.zoom.x * (1.0 if invert_background_pan else -1.0)
			_pan_last_mouse = current_mouse
			_offset_camera_target(pan_delta)
			get_viewport().set_input_as_handled()
			return

func _process(delta: float) -> void:
	_process_controller(delta)
	if enable_camera_navigation and _camera:
		if smooth_zoom and not reduced_motion:
			_update_smooth_zoom(delta)
		_update_edge_pan_camera(delta)
		_update_smooth_pan(delta)
	if _drag_root == -1 or _dragged_piece == -1:
		return
	if not _drag_visual_active:
		if _get_pointer_screen().distance_to(_drag_start_screen) < _drag_threshold_screen():
			return
		# Pointer moved beyond threshold: mouse, touch and virtual
		# cursor share the same selection/packing path.
		_activate_drag()
	_desired_position = _get_pointer_world() + _pointer_offset
	var factor := 1.0 if reduced_motion else 1.0 - exp(-drag_smoothing * delta)
	_move_group((_desired_position - _pieces[_dragged_piece].global_position) * factor)

## Stop an unfinished drag without snapping (e.g. when preview is opened).
func _cancel_drag(reason: StringName = JigsawPuzzleEvent.REASON_CANCELLED) -> void:
	_background_pan_pending = false
	if _dragged_piece < 0:
		_camera_pan = false
		_camera_pan_button = 0
		return
	var cancelled_piece_id := _dragged_piece
	for member in _selected_piece_ids.keys():
		var piece := _pieces[int(member)]
		piece.modulate = Color.WHITE
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PIECE_DRAG_CANCELLED, cancelled_piece_id, false, reason, {
		"selected_piece_ids": get_selected_piece_ids()
	}))
	_drag_root = -1
	_dragged_piece = -1
	_drag_visual_active = false
	_camera_pan = false
	_camera_pan_button = 0
	_refresh_selection_visuals(false)

## Translate the current multi-selection during pointer dragging.
func _move_group(offset: Vector2) -> void:
	if _drag_root == -1 or offset == Vector2.ZERO:
		return
	_hit_index.invalidate()
	for piece_id in _selected_piece_ids.keys():
		var id := int(piece_id)
		if not _locked_pieces.has(id):
			_pieces[id].global_position += offset

func _move_root(root: int, offset: Vector2) -> void:
	_hit_index.invalidate()
	for member in _groups.members_of_root(root):
		_pieces[int(member)].global_position += offset

## Assist changes acceptance radius only: rotation and canonical seams
## remain untouched, and connected groups keep their authoritative roots.
func _effective_snap_tolerance_pixels() -> float:
	return minf(_piece_size.x, _piece_size.y) * clampf(
		snap_tolerance + snap_assist_extra_fraction, 0.0, 0.5
	)


func _connect_selected_groups() -> bool:
	var any_connection := false
	var seen_roots: Dictionary = {}
	var selected_snapshot: Array = _selected_piece_ids.keys()
	selected_snapshot.sort()
	for piece_variant in selected_snapshot:
		var piece_id := int(piece_variant)
		if piece_id < 0 or piece_id >= _groups.piece_count():
			continue
		var root := _groups.root_of(piece_id)
		if seen_roots.has(root):
			continue
		seen_roots[root] = true
		if _connect_group_from(piece_id):
			any_connection = true
	_refresh_selection_visuals(false)
	return any_connection

func _connect_group_from(anchor_piece_id: int) -> bool:
	if _groups.root_of(anchor_piece_id) < 0:
		return false
	var any_connection := false
	var still_connecting := true
	while still_connecting:
		still_connecting = false
		var active_members := _groups.members_for(anchor_piece_id)
		for index in active_members:
			for neighbor in ConnectionResolver.neighbor_ids(index, columns, rows):
				if _groups.same_group(index, neighbor):
					continue
				var shift: Vector2 = ConnectionResolver.snap_offset(
					_pieces[index].home,
					_pieces[neighbor].home,
					_pieces[index].global_position,
					_pieces[neighbor].global_position,
					_rotations[index],
					_rotations[neighbor],
					_effective_snap_tolerance_pixels()
				)
				if not shift.is_finite():
					continue

				var anchor_root := _groups.root_of(anchor_piece_id)
				_move_root(anchor_root, shift)
				var joined_members := _groups.merge(anchor_piece_id, neighbor)
				for member in joined_members:
					_selected_piece_ids[member] = true

				var group_size := _groups.members_for(anchor_piece_id).size()
				pieces_connected.emit(group_size)
				_dispatch_event(_make_event(JigsawPuzzleEvent.Type.GROUP_CONNECTED, index, true, JigsawPuzzleEvent.REASON_NEIGHBOR_SNAP, {
					"neighbor_piece_id": neighbor,
					"group_size": group_size
				}))
				_animate_connection(_pieces[index])
				any_connection = true
				still_connecting = true
				break
			if still_connecting:
				break
	if any_connection:
		_emit_progress_changed()
	if _groups.group_count() == 1:
		_finish_puzzle()
	return any_connection

func _update_camera_bounds() -> void:
	_fit_bounds = Rect2(Vector2.ZERO, _piece_size * Vector2(columns, rows))
	for piece in _pieces:
		# The first/last rectangle corners are insufficient after quarter turns.
		# Include all rotated contour bounds so the overview never crops pieces.
		var bounds := piece.bounds
		for local_corner in [
			bounds.position,
			Vector2(bounds.end.x, bounds.position.y),
			bounds.end,
			Vector2(bounds.position.x, bounds.end.y)
		]:
			_fit_bounds = _fit_bounds.expand(piece.transform * local_corner)
	_pan_bounds = _fit_bounds.grow(maxf(_piece_size.x, _piece_size.y) * camera_outer_margin)

func _fit_camera() -> void:
	_fit_camera_to(_fit_bounds)


func _fit_camera_to(bounds: Rect2) -> void:
	if _camera == null:
		return
	var frame := bounds.size * 1.08
	var screen := get_viewport_rect().size
	if frame.x <= 0.0 or frame.y <= 0.0 or screen.x <= 0.0 or screen.y <= 0.0:
		return
	_camera.global_position = to_global(bounds.get_center())
	var zoom := minf(screen.x / frame.x, screen.y / frame.y)
	_camera.zoom = Vector2.ONE * clampf(zoom, min_zoom, max_zoom)

func _zoom_at_cursor(multiplier: float) -> void:
	_zoom_at_screen(multiplier, _get_pointer_screen())


func _zoom_at_screen(multiplier: float, screen_position: Vector2) -> void:
	_zoom_goal = clampf(_zoom_goal * multiplier, min_zoom, max_zoom)
	if smooth_zoom and not reduced_motion:
		_zoom_anchor = screen_position
		_zoom_anchor_valid = true
	else:
		_apply_zoom(_zoom_goal, screen_position)

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
	var anchor_correction := world_before - world_after
	_camera.global_position += anchor_correction
	if _camera_target_ready:
		_camera_target_position += anchor_correction
	_limit_camera()

func _update_edge_pan_camera(delta: float) -> void:
	var desired_velocity := Vector2.ZERO
	if _drag_root != -1 and _dragged_piece != -1:
		var viewport_size := get_viewport_rect().size
		var cursor := _get_pointer_screen()
		if cursor.x >= 0.0 and cursor.y >= 0.0 and cursor.x <= viewport_size.x and cursor.y <= viewport_size.y:
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
				desired_velocity = movement.limit_length(1.0) * edge_scroll_speed / maxf(_camera.zoom.x, 0.001)

	var velocity_factor := 1.0 if reduced_motion else 1.0 - exp(-edge_scroll_smoothing * delta)
	_edge_pan_velocity = _edge_pan_velocity.lerp(desired_velocity, velocity_factor)
	if _edge_pan_velocity.length_squared() < 0.01:
		_edge_pan_velocity = Vector2.ZERO
	if _edge_pan_velocity != Vector2.ZERO:
		_offset_camera_target(_edge_pan_velocity * delta)

func _sync_camera_target() -> void:
	if _camera == null:
		_camera_target_ready = false
		return
	_camera_target_position = _camera.global_position
	_camera_target_ready = true

func _offset_camera_target(offset: Vector2) -> void:
	if _camera == null:
		return
	if not _camera_target_ready:
		_sync_camera_target()
	_camera_target_position = _clamp_camera_position(_camera_target_position + offset)
	if not smooth_pan or reduced_motion:
		_camera.global_position = _camera_target_position
		_camera.force_update_scroll()

func _update_smooth_pan(delta: float) -> void:
	if _camera == null or not _camera_target_ready:
		return
	_camera_target_position = _clamp_camera_position(_camera_target_position)
	if not smooth_pan or reduced_motion:
		_camera.global_position = _camera_target_position
		_camera.force_update_scroll()
		return
	var factor := 1.0 - exp(-pan_smoothing * delta)
	_camera.global_position = _camera.global_position.lerp(_camera_target_position, factor)
	if _camera.global_position.distance_squared_to(_camera_target_position) < 0.01:
		_camera.global_position = _camera_target_position
	_camera.force_update_scroll()

func _clamp_camera_position(position: Vector2) -> Vector2:
	if _camera == null or not restrict_camera:
		return position
	var half_screen := get_viewport_rect().size / (_camera.zoom * 2.0)
	var limits := Rect2(to_global(_pan_bounds.position), _pan_bounds.size)
	var center := position
	for axis in range(2):
		if limits.size[axis] <= half_screen[axis] * 2.0:
			center[axis] = limits.get_center()[axis]
		else:
			center[axis] = clampf(center[axis], limits.position[axis] + half_screen[axis], limits.end[axis] - half_screen[axis])
	return center

func _limit_camera() -> void:
	if _camera == null:
		return
	_camera.global_position = _clamp_camera_position(_camera.global_position)
	if _camera_target_ready:
		_camera_target_position = _clamp_camera_position(_camera_target_position)

## Plan positions without creating tens of thousands of temporary slots or
## scanning every previously placed chaotic piece.
func _scatter_non_overlapping() -> void:
	var board_size := _piece_size * Vector2(columns, rows)
	var positions: Array[Vector2]
	if shuffle_mode == ShuffleMode.CHAOTIC:
		positions = ScatterLayout.chaotic(
			_pieces.size(), board_size, _piece_size, shuffle_spacing,
			chaotic_spread, chaotic_max_attempts, _rng
		)
	else:
		positions = ScatterLayout.structured(
			_pieces.size(), board_size, _piece_size,
			shuffle_mode, distribution_mode, shuffle_spacing, _rng
		)
	for i in range(mini(_pieces.size(), positions.size())):
		_pieces[i].position = positions[i]


## Legacy integration helper retained for internal scripts.
func _scatter_chaotic() -> void:
	var positions := ScatterLayout.chaotic(
		_pieces.size(), _piece_size * Vector2(columns, rows), _piece_size,
		shuffle_spacing, chaotic_spread, chaotic_max_attempts, _rng
	)
	for i in range(mini(_pieces.size(), positions.size())):
		_pieces[i].position = positions[i]


func _update_ghost_board() -> void:
	if not is_instance_valid(_ghost_board):
		return
	_ghost_board.visible = (_ghost_visibility_override == 1) if _ghost_visibility_override != -1 else (show_ghost_board or game_mode == GameMode.MOSAIC)
	_ghost_board.modulate.a = ghost_opacity

func set_preview_visible(visible: bool) -> void:
	if not enable_preview or not is_instance_valid(_preview_overlay):
		return
	if is_reference_preview_visible() == visible:
		return
	if visible:
		_cancel_drag(JigsawPuzzleEvent.REASON_PREVIEW_OPENED)
		_touch_positions.clear()
		_touch_primary = -1
		_touch_gesture_active = false
		_device_pointer_active = _controller_cursor_active
	_preview_overlay.set_preview_visible(visible)
	if is_instance_valid(_controller_cursor_ui):
		_controller_cursor_ui.visible = not visible and _controller_cursor_active
	preview_toggled.emit(visible)
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PREVIEW_TOGGLED, -1, true, JigsawPuzzleEvent.REASON_VISIBLE if visible else JigsawPuzzleEvent.REASON_HIDDEN, {
		"visible": visible
	}))

func _place_selected_in_mosaic() -> bool:
	var any_success := false
	var selected_snapshot: Array = _selected_piece_ids.keys()
	for piece_variant in selected_snapshot:
		var piece_id := int(piece_variant)
		if _locked_pieces.has(piece_id):
			continue
		var piece := _pieces[piece_id]
		var valid := _rotations[piece_id] == 0 and piece.position.distance_to(piece.home) <= _effective_snap_tolerance_pixels()
		if not valid:
			_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PIECE_PLACEMENT_FAILED, piece_id, false, JigsawPuzzleEvent.REASON_WRONG_POSITION_OR_ROTATION))
			_animate_failed_connection(piece)
			continue

		piece.position = piece.home
		_locked_pieces[piece_id] = true
		_selected_piece_ids.erase(piece_id)
		piece_placed.emit(piece_id)
		_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PIECE_PLACED, piece_id, true, JigsawPuzzleEvent.REASON_MOSAIC_SLOT))
		_animate_connection(piece)
		any_success = true

	if any_success:
		_emit_progress_changed()
	if _locked_pieces.size() == _pieces.size():
		_finish_puzzle()
	_refresh_selection_visuals(false)
	return any_success

func _animate_pickup(members: Array, active: bool) -> void:
	# Tint only: scaling the nodes would change their visible seams and pointer hit test.
	if reduced_motion:
		return
	var tint := (_active_feedback.pickup_tint if _active_feedback != null else Color(1.12, 1.09, 1.02, 1.0)) if active and animation_style == AnimationStyle.PLAYFUL else Color.WHITE
	for member in members:
		var piece := _pieces[int(member)]
		_tween_piece_tint(piece, tint)

func _animate_failed_connection(piece: JigsawPiece) -> void:
	if reduced_motion or _active_feedback == null or not _active_feedback.enable_failure_feedback:
		return
	piece.tween_tint(_active_feedback.failure_tint, _active_feedback.failure_animation_duration, true)

func _animate_connection(piece: JigsawPiece) -> void:
	if reduced_motion or animation_style == AnimationStyle.NONE:
		return
	var peak := _active_feedback.connect_tint if _active_feedback != null else (Color(1.22, 1.18, 0.93, 1.0) if animation_style == AnimationStyle.PLAYFUL else Color(1.10, 1.10, 1.02, 1.0))
	piece.tween_tint(peak, connect_animation_duration * 1.5, true)

func _tween_piece_tint(piece: JigsawPiece, tint: Color) -> void:
	if reduced_motion or animation_style == AnimationStyle.NONE:
		piece.modulate = Color.WHITE
		return
	piece.tween_tint(tint, connect_animation_duration * 0.5)

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
	snap_assist_extra_fraction = gameplay.snap_assist_extra_fraction
	selection_assist_radius_px = gameplay.selection_assist_radius_px
	allow_piece_rotation = gameplay.allow_piece_rotation
	rotate_action = gameplay.rotate_action
	random_rotation_on_shuffle = gameplay.random_rotation_on_shuffle
	enable_multi_select = gameplay.enable_multi_select
	_organizer_corner_action = gameplay.next_corner_action
	_organizer_edge_action = gameplay.next_edge_action
	_organizer_interior_action = gameplay.next_interior_action
	_organizer_corner_key = gameplay.next_corner_key
	_organizer_edge_key = gameplay.next_edge_key
	_organizer_interior_key = gameplay.next_interior_key
	match gameplay.shuffle_mode:
		JigsawGameplaySettings.Shuffle.CENTER:
			shuffle_mode = ShuffleMode.CENTER
		JigsawGameplaySettings.Shuffle.BOTTOM:
			shuffle_mode = ShuffleMode.BOTTOM
		JigsawGameplaySettings.Shuffle.CHAOTIC:
			shuffle_mode = ShuffleMode.CHAOTIC
		_:
			shuffle_mode = ShuffleMode.AROUND_BOARD
	distribution_mode = DistributionMode.RADIAL if gameplay.distribution_mode == JigsawGameplaySettings.Distribution.RADIAL else DistributionMode.RANDOM
	initial_scatter = gameplay.initial_scatter
	shuffle_spacing = gameplay.shuffle_spacing
	chaotic_spread = gameplay.chaotic_spread
	chaotic_max_attempts = gameplay.chaotic_max_attempts
	generation_seed = gameplay.generation_seed
	_generation_batch_size = gameplay.generation_batch_size
	show_ghost_board = gameplay.show_ghost_board
	ghost_opacity = gameplay.ghost_opacity
	enable_preview = gameplay.enable_preview
	preview_key = gameplay.preview_key
	preview_action = gameplay.preview_action
	preview_dim = gameplay.preview_dim

	var appearance := config.appearance
	if appearance == null:
		appearance = JigsawAppearanceSettings.new()
	_connector_depth = appearance.connector_depth
	_connector_family = appearance.connector_family
	_connector_variation = appearance.connector_variation
	_recommended_pixels_per_piece = appearance.recommended_pixels_per_piece
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
	piece_edge_color = appearance.piece_edge_color
	piece_material = appearance.piece_material
	highlight_enabled = appearance.highlight_enabled
	highlight_color = appearance.highlight_color
	highlight_width = appearance.highlight_width
	highlight_shadow_enabled = appearance.highlight_shadow_enabled
	highlight_shadow_color = appearance.highlight_shadow_color
	highlight_shadow_offset = appearance.highlight_shadow_offset

	_device_input = config.device_input
	if _device_input == null:
		_device_input = JigsawDeviceInputSettings.new()

	var camera_options := config.camera
	if camera_options == null:
		camera_options = JigsawCameraSettings.new()
	enable_camera_navigation = camera_options.enable_camera_navigation
	invert_background_pan = camera_options.invert_background_pan
	auto_fit_camera = camera_options.auto_fit_camera
	initial_focus = camera_options.initial_focus
	large_puzzle_threshold = camera_options.large_puzzle_threshold
	focus_board_key = camera_options.focus_board_key
	overview_key = camera_options.overview_key
	focus_selection_key = camera_options.focus_selection_key
	focus_board_action = camera_options.focus_board_action
	overview_action = camera_options.overview_action
	focus_selection_action = camera_options.focus_selection_action
	zoom_in_action = camera_options.zoom_in_action
	zoom_out_action = camera_options.zoom_out_action
	selection_focus_padding = camera_options.selection_focus_padding
	selection_focus_max_zoom = camera_options.selection_focus_max_zoom
	smooth_pan = camera_options.smooth_pan
	pan_smoothing = camera_options.pan_smoothing
	restrict_camera = camera_options.restrict_camera
	camera_outer_margin = camera_options.camera_outer_margin
	background_pan_delay_ms = camera_options.background_pan_delay_ms
	background_pan_threshold_px = camera_options.background_pan_threshold_px
	smooth_zoom = camera_options.smooth_zoom
	zoom_smoothing = camera_options.zoom_smoothing
	wheel_zoom_factor = camera_options.wheel_zoom_factor
	min_zoom = camera_options.min_zoom
	max_zoom = camera_options.max_zoom
	drag_smoothing = camera_options.drag_smoothing
	edge_scroll_zone = camera_options.edge_scroll_zone
	edge_scroll_speed = camera_options.edge_scroll_speed
	edge_scroll_smoothing = camera_options.edge_scroll_smoothing

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
	reduced_motion = _active_feedback.reduce_motion

	_active_reactions.clear()
	for reaction in config.reactions:
		if reaction != null:
			_active_reactions.append(reaction)

func _set_piece_quarters(piece_index: int, quarters: int) -> void:
	_hit_index.invalidate()
	_rotations[piece_index] = posmod(quarters, 4)
	_pieces[piece_index].rotation = float(_rotations[piece_index]) * PI * 0.5

func _rotate_under_cursor() -> bool:
	var hovered := -1
	var point := _get_pointer_world()
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
	var group_id := _groups.root_of(piece_index)
	var members := _groups.members_for(piece_index)
	var motion_ids := PackedInt32Array()
	for member in members:
		motion_ids.append(int(member))
	var previous := _capture_display_transforms(motion_ids)
	for member in members:
		var id: int = int(member)
		var old_center := _pieces[id].global_position + Vector2(_piece_size.x * 0.5, _piece_size.y * 0.5).rotated(_pieces[id].global_rotation)
		var next_center := pivot + (old_center - pivot).rotated(float(turn) * PI * 0.5)
		_set_piece_quarters(id, _rotations[id] + turn)
		_pieces[id].global_position = next_center - Vector2(_piece_size.x * 0.5, _piece_size.y * 0.5).rotated(_pieces[id].global_rotation)
	if _dragged_piece >= 0 and _groups.root_of(_dragged_piece) == group_id:
		_pointer_offset = _pieces[_dragged_piece].global_position - _get_pointer_world()
		_desired_position = _pieces[_dragged_piece].global_position
	_emit_motion(JigsawMotionContext.Kind.ROTATION, motion_ids, previous)
	group_rotated.emit(piece_index, _rotations[piece_index], members.size())
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.GROUP_ROTATED, piece_index, true, JigsawPuzzleEvent.REASON_CLOCKWISE if clockwise else JigsawPuzzleEvent.REASON_COUNTER_CLOCKWISE, {
		"quarter_turns": _rotations[piece_index],
		"group_size": members.size()
	}))


## Build a stable event context from current board state.
func _make_event(
	event_type: JigsawPuzzleEvent.Type,
	piece_id: int = -1,
	success: bool = false,
	reason: StringName = &"",
	metadata: Dictionary = {}
) -> JigsawPuzzleEvent:
	var event := JigsawPuzzleEvent.new(event_type)
	event.board = self
	event.piece_id = piece_id
	event.success = success
	event.reason = reason
	event.metadata = metadata.duplicate(true)
	if piece_id >= 0 and piece_id < _pieces.size():
		event.piece_ids = get_group_piece_ids(piece_id)
		event.group_size = event.piece_ids.size()
		event.world_position = get_piece_world_center(piece_id)
		event.quarter_turns = _rotations[piece_id]
	else:
		var board_center := _piece_size * Vector2(columns, rows) * 0.5
		event.world_position = to_global(board_center) if _piece_size != Vector2.ZERO else global_position
	return event

## Emit the umbrella signal, a semantic signal, then configured Resource reactions.
## This is the central extension point for host games.
func _dispatch_event(event: JigsawPuzzleEvent) -> void:
	event_emitted.emit(event)
	match event.type:
		JigsawPuzzleEvent.Type.PUZZLE_RESET:
			puzzle_reset.emit(event)
		JigsawPuzzleEvent.Type.PUZZLE_STARTED:
			puzzle_started.emit(event)
		JigsawPuzzleEvent.Type.PIECE_DRAG_STARTED:
			piece_drag_started.emit(event)
		JigsawPuzzleEvent.Type.PIECE_DRAG_FINISHED:
			piece_drag_finished.emit(event)
		JigsawPuzzleEvent.Type.PIECE_DRAG_CANCELLED:
			piece_drag_cancelled.emit(event)
		JigsawPuzzleEvent.Type.PIECE_PLACED:
			piece_placement_succeeded.emit(event)
		JigsawPuzzleEvent.Type.PIECE_PLACEMENT_FAILED:
			piece_placement_failed.emit(event)
		JigsawPuzzleEvent.Type.GROUP_CONNECTED:
			group_connection_succeeded.emit(event)
		JigsawPuzzleEvent.Type.GROUP_CONNECTION_FAILED:
			group_connection_failed.emit(event)
		JigsawPuzzleEvent.Type.GROUP_ROTATED:
			group_rotation_changed.emit(event)
		JigsawPuzzleEvent.Type.SELECTION_ARRANGED:
			selection_arranged.emit(event)
		JigsawPuzzleEvent.Type.PREVIEW_TOGGLED:
			reference_preview_changed.emit(event)
		JigsawPuzzleEvent.Type.PUZZLE_COMPLETED:
			puzzle_finished.emit(event)
		JigsawPuzzleEvent.Type.PUZZLE_STATE_RESTORED:
			puzzle_state_applied.emit(event)

	# Iterate a snapshot so a reaction may schedule/reconfigure safely without
	# invalidating the current dispatch loop.
	var reaction_snapshot: Array[JigsawReaction] = _active_reactions.duplicate()
	for reaction in reaction_snapshot:
		if reaction.accepts(event):
			reaction.react(self, event)

func _finish_puzzle() -> void:
	if _finished:
		return
	_finished = true
	puzzle_completed.emit()
	_dispatch_event(_make_event(JigsawPuzzleEvent.Type.PUZZLE_COMPLETED, -1, true, JigsawPuzzleEvent.REASON_SOLVED, {
		"piece_count": _pieces.size(),
		"game_mode": game_mode
	}))
