extends Node2D
## Pure presentation in Board-local coordinates. Does not intercept inputs.
## No tween: compliant with reduced-motion settings.

var hint_level := 0
var coarse_region := Rect2()
var candidate_bounds := Rect2()
var exact_target := Rect2()


func set_hint(level: int, region: Rect2, candidate: Rect2, target: Rect2) -> void:
	if hint_level == level and coarse_region == region and candidate_bounds == candidate and exact_target == target:
		return
	hint_level = level
	coarse_region = region
	candidate_bounds = candidate
	exact_target = target
	queue_redraw()


func _draw() -> void:
	if hint_level <= 0:
		return
	# Level 1: broad region only; never outline the exact target.
	draw_rect(coarse_region, Color(0.29, 0.61, 0.78, 0.11), true)
	draw_rect(coarse_region, Color(0.42, 0.79, 0.95, 0.74), false, 3.0)
	if hint_level >= 2 and candidate_bounds.size != Vector2.ZERO:
		# Level 2: highlight currently loose/selected GROUP (not a solution).
		var outline: Rect2 = candidate_bounds.grow(6.0)
		draw_rect(outline, Color(0.98, 0.82, 0.37, 0.11), true)
		draw_rect(outline, Color(0.98, 0.82, 0.37, 0.94), false, 3.0)
	if hint_level >= 3 and exact_target.size != Vector2.ZERO:
		# Level 3: exact cell position only. Never reveal orientation or auto-join.
		var target_rect: Rect2 = exact_target.grow(2.0)
		draw_rect(target_rect, Color(0.30, 0.92, 0.69, 0.13), true)
		draw_rect(target_rect, Color(0.43, 1.0, 0.76, 0.95), false, 3.0)
