extends Node2D

var victory = false
var clock = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var color = Color("92d6ba") if victory else Color("b591aa")
	for r in [120, 147, 156]:
		draw_arc(Vector2.ZERO, r, clock * 0.12, clock * 0.12 + TAU - 0.5, 100, Color(color, 0.2), 2, true)
	for i in range(16):
		var a = i * TAU / 16 + clock * 0.08
		draw_circle(Vector2(cos(a), sin(a)) * (155 + sin(clock + i) * 8), 3, Color(color, 0.65))
	for i in range(24):
		var x = sin(i * 13.7) * 210
		var y = fmod(clock * (10 + i % 5) + i * 71, 400) - 200
		draw_circle(Vector2(x, y), 1.5, Color(color, 0.3 + sin(clock + i) * 0.2))
