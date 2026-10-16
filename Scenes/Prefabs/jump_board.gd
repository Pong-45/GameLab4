@tool
extends Area2D

@export var launch_speed: float = 1000.0
var compression: float = 0.0
var cooldown: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	add_to_group("JumpBoards")
	var shape = RectangleShape2D.new()
	shape.size = Vector2(76, 20)
	var collider = CollisionShape2D.new()
	collider.position.y = -10
	collider.shape = shape
	add_child(collider)

func _physics_process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	compression = move_toward(compression, 0, delta * 3)
	if not Engine.is_editor_hint() and cooldown <= 0:
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dying and body.velocity.y >= 0 and body.global_position.y <= global_position.y + 12:
				body.velocity.y = -launch_speed
				body.jump_count = body.max_jump_count
				compression = 1
				cooldown = 0.5
				AudioManager.play_effect("spring", -9)
	queue_redraw()

func _draw() -> void:
	var y = -18 + compression * 10
	draw_rect(Rect2(-42, -4, 84, 10), Color("233637"))
	for x in [-24, 24]:
		draw_polyline(PackedVector2Array([Vector2(x, 0), Vector2(x - 8, y * 0.25), Vector2(x + 8, y * 0.6), Vector2(x, y)]), Color("c0dbac"), 3)
	draw_rect(Rect2(-40, y - 6, 80, 8), Color("7cbd82"))
	draw_line(Vector2(-7, y - 10), Vector2(0, y - 16), Color("e5edb8"), 3)
	draw_line(Vector2(7, y - 10), Vector2(0, y - 16), Color("e5edb8"), 3)
