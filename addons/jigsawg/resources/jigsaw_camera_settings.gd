@tool
class_name JigsawCameraSettings
extends Resource
## Reusable camera and input-navigation settings for JigsawBoard.

@export_group("Navigation")
## Enable mouse-wheel zoom, empty-space/middle-button pan and edge scroll.
@export var enable_camera_navigation := true
## Reverse direction of mouse dragging empty space; live after refresh.
@export var invert_background_pan := false
## Fit board and scattered pieces when generated.
@export var auto_fit_camera := true
## Smooth camera position toward drag/edge-scroll targets instead of snapping each input sample.
@export var smooth_pan := true
## Exponential pan response per second; higher follows the pointer more immediately.
@export_range(1.0, 60.0, 0.5) var pan_smoothing := 26.0
## Stop pan at bounds, expanded by camera_outer_margin.
@export var restrict_camera := false
## Additional pan space outside content, in longest piece sides.
@export_range(0.0, 20.0, 0.5) var camera_outer_margin := 5.0

@export_group("Zoom")
## Animate wheel zoom instead of jumping between values.
@export var smooth_zoom := true
## Exponential zoom response per second; higher is faster.
@export_range(1.0, 30.0, 0.5) var zoom_smoothing := 12.0
## Scale multiplier applied for one wheel notch.
@export_range(1.05, 2.0, 0.05) var wheel_zoom_factor := 1.15
## Smallest permitted camera zoom.
@export_range(0.01, 10.0, 0.01) var min_zoom := 0.025
## Largest permitted camera zoom.
@export_range(0.25, 16.0, 0.25) var max_zoom := 8.0

@export_group("Drag")
## Piece-to-cursor smoothing rate; higher feels more immediate.
@export_range(1.0, 60.0, 0.5) var drag_smoothing := 22.0
## Viewport-edge activation distance while dragging a piece, in pixels.
@export_range(8.0, 128.0, 1.0) var edge_scroll_zone := 64.0
## Edge-pan speed expressed as viewport pixels per second.
@export_range(100.0, 2500.0, 25.0) var edge_scroll_speed := 900.0
## Edge-pan acceleration/deceleration response; higher reaches target speed sooner.
@export_range(1.0, 40.0, 0.5) var edge_scroll_smoothing := 12.0
