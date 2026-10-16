extends Node2D

var clock = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var center = camera.get_screen_center_position()
	for i in range(46):
		var x = fposmod(i * 179.7 + sin(clock * 0.3 + i) * 20 - center.x * 0.15, 1500) - 750
		var y = fposmod(i * 93.1 - clock * 9, 700) - 350
		var alpha = 0.25 + sin(clock * 1.4 + i * 5.0) * 0.2
		var point = center + Vector2(x, y)
		draw_circle(point, 6, Color(0.8, 0.96, 0.57, alpha * 0.14))
		draw_circle(point, 1.5, Color(0.9, 1, 0.7, alpha))
