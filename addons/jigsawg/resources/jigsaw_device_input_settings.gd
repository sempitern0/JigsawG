@tool
class_name JigsawDeviceInputSettings
extends Resource
## Optional input adapters. JigsawG does not add global InputMap bindings.

@export_group("Touch")
## Enable native touch events. Hosts should disable emulate_mouse_from_touch
## to avoid duplicate simulated mouse events on tablets.
@export var enable_touch := false
## Two fingers pan/zoom the active Camera2D, cancelling any pending piece drag.
@export var touch_pinch_and_pan := true
@export_range(2.0, 24.0, 1.0) var touch_drag_threshold_px := 6.0

@export_group("Virtual Cursor / Gamepad")
## Disabled by default so existing games keep all their input ownership.
@export var enable_controller := false
## InputMap movement actions, usually bound to the left analog stick / D-pad.
@export var cursor_left_action: StringName = &"ui_left"
@export var cursor_right_action: StringName = &"ui_right"
@export var cursor_up_action: StringName = &"ui_up"
@export var cursor_down_action: StringName = &"ui_down"
## Pick up / release a piece with the same action (hold and release).
@export var grab_action: StringName = &"ui_accept"
## Optional action toggles a complete group in the multi-selection.
@export var add_group_action: StringName = &""
## Optional action cancels an unfinished drag without snapping.
@export var cancel_action: StringName = &"ui_cancel"
@export_range(120.0, 2400.0, 20.0) var cursor_speed_px := 900.0
@export_range(0.0, 0.6, 0.01) var stick_deadzone := 0.18

@export_group("Right Stick / Camera")
## Optional InputMap actions for the right stick. Leave empty to disable.
@export var camera_left_action: StringName = &""
@export var camera_right_action: StringName = &""
@export var camera_up_action: StringName = &""
@export var camera_down_action: StringName = &""
@export_range(100.0, 2400.0, 20.0) var camera_pan_speed_px := 600.0
