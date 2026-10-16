extends Control

# A compact meter whose height is independent of the project's ProgressBar theme.
var value: float = 100:
	set(new_value):
		value = new_value
		queue_redraw()
var max_value: float = 100
var fill_color = Color("8cdbc0")
var background_color = Color("293e3c")

func _draw() -> void:
	var background = StyleBoxFlat.new()
	background.bg_color = background_color
	background.set_corner_radius_all(3)
	draw_style_box(background, Rect2(Vector2.ZERO, size))
	var ratio = clampf(value / maxf(max_value, 0.001), 0, 1)
	if ratio > 0:
		var fill = background.duplicate()
		fill.bg_color = fill_color
		draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)))
