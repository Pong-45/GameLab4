@tool
extends Area2D

@export_enum("Blade", "Fire", "Lava") var kind: int = 0
@export var hazard_size = Vector2(128, 32)
@export var travel = Vector2.ZERO
@export var period: float = 3.0
@export var phase: float = 0.0
var clock: float = 0.0
var origin = Vector2.ZERO
var blade: Sprite2D

func _ready() -> void:
	origin = position
	clock = phase
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	var collider = CollisionShape2D.new()
	if kind == 0:
		var shape = CircleShape2D.new()
		shape.radius = 32
		collider.shape = shape
		blade = Sprite2D.new()
		blade.texture = load("res://Assets/Swamp/blade.svg")
		add_child(blade)
	else:
		var shape = RectangleShape2D.new()
		shape.size = hazard_size
		collider.shape = shape
	add_child(collider)
	add_to_group("Hazards")

func _physics_process(delta: float) -> void:
	clock += delta
	if Engine.is_editor_hint():
		queue_redraw()
		return
	position = origin + travel * (0.5 - 0.5 * cos(clock * TAU / max(period, 0.1)))
	if blade != null:
		blade.rotation += delta * 5
	var active = kind != 1 or fmod(clock, period) > period * 0.4
	if active:
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dying:
				if kind == 2:
					GameManager.death()
				else:
					body.receive_hit(30 if kind == 0 else 20, global_position)
	queue_redraw()

func _draw() -> void:
	if kind == 0:
		if Engine.is_editor_hint():
			draw_texture_rect(load("res://Assets/Swamp/blade.svg"), Rect2(-40, -40, 80, 80), false)
		return
	var half = hazard_size * 0.5
	if kind == 2:
		draw_rect(Rect2(-half, hazard_size), Color("a52c39"))
		draw_rect(Rect2(-half, Vector2(hazard_size.x, 8)), Color("ffd977"))
		for x in range(int(-half.x), int(half.x), 20):
			var y = sin(clock * 3 + x) * 4 - half.y
			draw_rect(Rect2(x, y, 15, 6), Color("ff924b"))
			var rise = fmod(clock * 30 + x * 4, 50)
			draw_circle(Vector2(x + 5, -half.y - rise), 2, Color(1, 0.7, 0.25, 1 - rise / 50))
	else:
		draw_style_box(_hearth_style(), Rect2(-half.x - 5, half.y - 14, hazard_size.x + 10, 18))
		var active = fmod(clock, period) > period * 0.4
		var height = hazard_size.y if active else 14.0
		for x in range(int(-half.x), int(half.x), 15):
			var h = height * (0.7 + 0.2 * sin(clock * 12 + x))
			var points = PackedVector2Array([Vector2(x - 8, half.y - 5), Vector2(x + 4, half.y - h), Vector2(x + 15, half.y - 5)])
			draw_colored_polygon(points, Color("ed683e") if active else Color("9c603b"))
			draw_line(Vector2(x + 3, half.y - 8), Vector2(x + 4, half.y - h * 0.7), Color("ffe09a"), 5)

func _hearth_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("394345")
	style.border_color = Color("677470")
	style.set_border_width_all(3)
	return style
