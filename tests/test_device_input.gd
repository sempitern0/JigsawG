extends SceneTree
## godot --headless --path . --script res://tests/test_device_input.gd
## Touch and controller both operate Board state; no emulated mouse events.
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

const PICK: StringName = &"jigsawg_device_test_pick"
const CURSOR_LEFT: StringName = &"jigsawg_device_test_left"
const CURSOR_RIGHT: StringName = &"jigsawg_device_test_right"
const CURSOR_UP: StringName = &"jigsawg_device_test_up"
const CURSOR_DOWN: StringName = &"jigsawg_device_test_down"
const CAMERA_LEFT: StringName = &"jigsawg_device_test_camera_left"
const CAMERA_RIGHT: StringName = &"jigsawg_device_test_camera_right"
const CAMERA_UP: StringName = &"jigsawg_device_test_camera_up"
const CAMERA_DOWN: StringName = &"jigsawg_device_test_camera_down"

var _events: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _action(name: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = name
	event.pressed = pressed
	return event


func _joypad_button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	return event


func _touch(index: int, pressed: bool, point: Vector2) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = point
	return event


func _drag(index: int, point: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = point
	return event


func _config(controller: bool, touch_enabled: bool) -> JigsawPuzzleConfig:
	var config: JigsawPuzzleConfig = JigsawPuzzleConfig.new()
	config.columns = 3
	config.rows = 3
	config.gameplay.initial_scatter = false
	config.gameplay.allow_piece_rotation = true
	config.gameplay.generation_batch_size = 0
	config.camera.smooth_pan = false
	config.camera.smooth_zoom = false
	config.device_input.enable_controller = controller
	config.device_input.enable_touch = touch_enabled
	config.device_input.cursor_left_action = CURSOR_LEFT
	config.device_input.cursor_right_action = CURSOR_RIGHT
	config.device_input.cursor_up_action = CURSOR_UP
	config.device_input.cursor_down_action = CURSOR_DOWN
	config.device_input.grab_action = PICK
	config.device_input.camera_left_action = CAMERA_LEFT
	config.device_input.camera_right_action = CAMERA_RIGHT
	config.device_input.camera_up_action = CAMERA_UP
	config.device_input.camera_down_action = CAMERA_DOWN
	return config


func _run() -> void:
	var actions: Array[StringName] = [PICK, CURSOR_LEFT, CURSOR_RIGHT, CURSOR_UP, CURSOR_DOWN, CAMERA_LEFT, CAMERA_RIGHT, CAMERA_UP, CAMERA_DOWN]
	for action: StringName in actions:
		assert(not InputMap.has_action(action))
		InputMap.add_action(action)
	var host: Node2D = Node2D.new()
	get_root().add_child(host)
	var camera: Camera2D = Camera2D.new()
	host.add_child(camera)
	camera.make_current()
	var board: BoardScript = BoardScript.new()
	var config: JigsawPuzzleConfig = _config(true, false)
	board.puzzle_config = config
	board.piece_released.connect(func(id: int, joined: bool) -> void:
		_events.append("released:%d" % id)
	)
	board.piece_drag_cancelled.connect(func(_event: JigsawPuzzleEvent) -> void:
		_events.append("cancelled")
	)
	host.add_child(board)
	assert(board.get_piece_count() == 9)
	assert(not board.is_controller_cursor_active())
	assert(not board._device_pointer_active)

	# The virtual cursor moves independently of mouse position.
	board._activate_controller_cursor()
	assert(board.is_controller_cursor_active())
	var piece: JigsawPiece = board.get_piece_node(0) as JigsawPiece
	for i in range(1, board.get_piece_count()):
		board.get_piece_node(i).position = Vector2(7000 + i * 450, 7000)
	var screen: Vector2 = piece.get_global_transform_with_canvas() * piece.bounds.get_center()
	board._device_pointer_screen = screen
	var original: Vector2 = piece.position
	assert(board._handle_controller_action(_action(PICK, true)))
	assert(board.get_dragged_piece_id() == 0)
	Input.action_press(CURSOR_RIGHT)
	board._process_controller(0.08)
	Input.action_release(CURSOR_RIGHT)
	board._process(0.08)
	assert(board._drag_visual_active)
	assert(piece.position != original)
	assert(board._handle_controller_action(_action(PICK, false)))
	assert(board.get_dragged_piece_id() == -1)
	assert(_events.has("released:0"))
	assert(board.get_piece_count() == 9)

	# Standard Steam Deck/SDL buttons require no new InputMap entries.
	board._device_pointer_screen = piece.get_global_transform_with_canvas() * piece.bounds.get_center()
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_A, true)))
	assert(board.get_dragged_piece_id() == 0)
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_B, true)))
	assert(board.get_dragged_piece_id() == -1)
	assert(_events.has("cancelled"))
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_Y, true)))
	assert(board.is_reference_preview_visible())
	assert(not board._handle_controller_action(_joypad_button(JOY_BUTTON_A, true)), "Preview must block piece interaction.")
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_Y, true)))
	assert(not board.is_reference_preview_visible())
	var prior_quarters: int = board._rotations[0]
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_RIGHT_SHOULDER, true)))
	assert(board._rotations[0] == posmod(prior_quarters + 1, 4))
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_LEFT_SHOULDER, true)))
	assert(board._rotations[0] == prior_quarters)
	assert(board._handle_controller_action(_joypad_button(JOY_BUTTON_X, true)))
	assert(board._selected_piece_ids.has(0))
	# Disabling the built-in profile must leave host actions unaffected.
	board._device_input.use_joypad_defaults = false
	assert(not board._handle_controller_action(_joypad_button(JOY_BUTTON_X, true)))
	board._device_input.use_joypad_defaults = true

	# Right stick camera action must not mutate puzzle positions.
	var previous_position: Vector2 = piece.position
	var pan_from: Vector2 = camera.global_position
	Input.action_press(CAMERA_RIGHT)
	board._process_controller(0.15)
	Input.action_release(CAMERA_RIGHT)
	board._process(0.016)
	assert(camera.global_position.x > pan_from.x)
	assert(piece.position == previous_position)
	board.set_interaction_enabled(false)
	assert(not board.is_controller_cursor_active())
	board.set_interaction_enabled(true)

	# An existing game can leave both modes disabled: no cursor or touch grab.
	var old_config: JigsawPuzzleConfig = _config(false, false)
	board.configure(old_config)
	assert(not board._handle_controller_action(_action(PICK, true)))
	assert(not board._handle_touch_event(_touch(0, true, Vector2(150, 150))))
	assert(board.get_dragged_piece_id() == -1)

	# One finger holds/drags a piece; second finger cancels the pending drag.
	var touch_config: JigsawPuzzleConfig = _config(false, true)
	board.configure(touch_config)
	piece = board.get_piece_node(0) as JigsawPiece
	screen = piece.get_global_transform_with_canvas() * piece.bounds.get_center()
	assert(board._handle_touch_event(_touch(0, true, screen)))
	assert(board.get_dragged_piece_id() == 0)
	assert(board._handle_touch_event(_touch(1, true, screen + Vector2(170, 30))))
	assert(board._touch_gesture_active)
	assert(board.get_dragged_piece_id() == -1)
	assert(_events.has("cancelled"))
	var before_gesture: Vector2 = piece.position
	var zoom_before: float = camera.zoom.x
	var finger_2: Vector2 = screen + Vector2(225, 30)
	assert(board._handle_touch_event(_drag(1, finger_2)))
	assert(camera.zoom.x > zoom_before, "Pinch must update zoom immediately.")
	assert(piece.position == before_gesture)
	assert(board._handle_touch_event(_touch(0, false, screen)))
	assert(board._touch_gesture_active, "Lifting one finger must not begin another drag.")
	assert(board._handle_touch_event(_touch(1, false, finger_2)))
	assert(not board._touch_gesture_active)
	assert(board._touch_positions.is_empty())

	# Single-finger travel uses the same group movement and release events.
	screen = piece.get_global_transform_with_canvas() * piece.bounds.get_center()
	assert(board._handle_touch_event(_touch(2, true, screen)))
	assert(board.get_dragged_piece_id() == 0)
	var old_position: Vector2 = piece.position
	var destination: Vector2 = screen + Vector2(52, 37)
	assert(board._handle_touch_event(_drag(2, destination)))
	board._process(0.08)
	assert(piece.position != old_position)
	assert(board._handle_touch_event(_touch(2, false, destination)))
	assert(board.get_dragged_piece_id() == -1)
	assert(_events.count("released:0") >= 2)

	for action: StringName in actions:
		Input.action_release(action)
		InputMap.erase_action(action)
	print("JigsawG virtual cursor and touch gesture input: PASS")
	host.queue_free()
	quit()
