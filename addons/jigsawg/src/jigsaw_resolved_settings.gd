extends RefCounted
## Snapshot of effective options for one board. Never shared or persisted.
## Keeps the runtime insulated from editor Resources and legacy board fields.

var puzzle_texture: Texture2D
var columns: int = 5
var rows: int = 4
var silhouette_variants: int = 3
var connector_depth: float = 0.25
var generation_seed: int = 4729
var snap_tolerance: float = 0.24
var initial_scatter: bool = true
var auto_fit_camera: bool = true
var drag_smoothing: float = 22.0
var enable_camera_navigation: bool = true
var invert_background_pan: bool = false
var smooth_zoom: bool = true
var zoom_smoothing: float = 12.0
var bezier_detail: int = 8
var shuffle_spacing: float = 0.14
var wheel_zoom_factor: float = 1.15
var min_zoom: float = 0.025
var max_zoom: float = 8.0
var edge_scroll_zone: float = 64.0
var edge_scroll_speed: float = 900.0
var texture_sampling: int = 0
var piece_edge_opacity: float = 0.0
var piece_edge_width: float = 0.7
var camera_outer_margin: float = 5.0
var restrict_camera: bool = false
var game_mode: int = 0
var shuffle_mode: int = 0
var distribution_mode: int = 0
var show_ghost_board: bool = false
var ghost_opacity: float = 0.25
var preview_key: Key = KEY_P
var preview_dim: float = 0.82
var enable_preview: bool = true
var visual_style: int = 0
var animation_style: int = 1
var connect_animation_duration: float = 0.16
var connect_tint: Color = Color(1.10, 1.10, 1.02, 1.0)
var pickup_tint: Color = Color(1.12, 1.09, 1.02, 1.0)
var enable_failure_feedback: bool = false
var failure_tint: Color = Color(1.16, 0.72, 0.72, 1.0)
var failure_animation_duration: float = 0.18
var allow_piece_rotation: bool = false
var random_rotation_on_shuffle: bool = true
