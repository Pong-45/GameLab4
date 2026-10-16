@tool
extends AnimatableBody2D

@export_enum("MovingPlatform", "Elevator") var kind: int = 0
@export var travel = Vector2(256, 0)
@export var duration: float = 4.0
@export var platform_width: float = 128.0
@export var phase: float = 0.0
var origin = Vector2.ZERO
var clock = 0.0

func _ready() -> void:
	origin = position
	clock = phase
	if Engine.is_editor_hint():
		return
	add_to_group("MovingPlatforms")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var shape = RectangleShape2D.new()
	shape.size = Vector2(platform_width, 18)
	var collider = CollisionShape2D.new()
	collider.shape = shape
	collider.one_way_collision = true
	collider.one_way_collision_margin = 10
	add_child(collider)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	clock += delta
	position = origin + travel * (0.5 - cos(clock * TAU / max(duration, 0.1)) * 0.5)

func _draw() -> void:
	var rect = Rect2(-platform_width / 2, -9, platform_width, 18)
	draw_rect(rect.grow(3), Color("182e32"))
	draw_rect(rect, Color("86694b"))
	draw_rect(Rect2(rect.position, Vector2(platform_width, 5)), Color("bcb577"))
	for x in range(int(-platform_width / 2 + 8), int(platform_width / 2), 24):
		draw_line(Vector2(x, -2), Vector2(x, 9), Color("4e493a"), 2)
	var accent = Color("7ad5cb") if kind == 1 else Color("dcd18b")
	draw_circle(Vector2(-platform_width / 2 + 10, 1), 3, accent)
	draw_circle(Vector2(platform_width / 2 - 10, 1), 3, accent)
	if kind == 1:
		draw_line(Vector2(0, 12), Vector2(0, 25), accent, 2)
		draw_line(Vector2(-5, 20), Vector2(0, 25), accent, 2)
		draw_line(Vector2(5, 20), Vector2(0, 25), accent, 2)
