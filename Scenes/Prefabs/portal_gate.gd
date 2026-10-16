@tool
extends Area2D

@export_enum("Warp", "Exit", "Checkpoint") var kind: int = 0
@export var destination = Vector2.ZERO
@export_file("*.tscn") var next_level = ""
@export var caption = "PORTAL"
var clock = 0.0
var activated = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("PortalGates")
	collision_layer = 0
	collision_mask = 2
	var shape = RectangleShape2D.new()
	shape.size = Vector2(58, 110)
	var collider = CollisionShape2D.new()
	collider.position.y = -55
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_entered)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _entered(body: Node2D) -> void:
	if not body is Player or body.is_dying:
		return
	if kind == 0:
		if body.portal_cooldown > 0:
			return
		body.portal_cooldown = 1.2
		body.global_position = destination
		body.velocity = Vector2.ZERO
		body.get_node("Camera2D").reset_smoothing()
		AudioManager.play_effect("portal", -10)
	elif kind == 1 and not activated:
		activated = true
		GameManager.save_player_position = Vector2.ZERO
		AudioManager.play_effect("portal", -8)
		get_tree().call_deferred("change_scene_to_file", next_level)
	elif kind == 2 and not activated:
		activated = true
		body.spawn_point = global_position + Vector2(68, 0)
		GameManager.add_hp(30)
		AudioManager.play_effect("checkpoint", -10)
		get_tree().call_group("GameHUD", "alert", "CHECKPOINT  /  +30 HP")

func _draw() -> void:
	var c = Color("dfcb7e") if kind == 1 else Color("79dfd4")
	if kind == 2:
		c = Color("e5d393") if activated else Color("819b7a")
		draw_rect(Rect2(-7, -90, 14, 90), Color("334b49"))
		draw_circle(Vector2(0, -80), 18, c.darkened(0.4))
		draw_circle(Vector2(0, -80), 10 + sin(clock * 2) * 2, c)
	else:
		draw_rect(Rect2(-49, -7, 98, 10), Color("263c40"))
		draw_rect(Rect2(-43, -112, 13, 112), Color("52655b"))
		draw_rect(Rect2(30, -112, 13, 112), Color("52655b"))
		draw_rect(Rect2(-43, -120, 86, 16), Color("91a37b"))
		_draw_portal_glow(Rect2(-28, -103, 56, 100), Color(c, 0.14))
		for i in range(4):
			var a = clock * 1.5 + i * PI / 2
			var points = PackedVector2Array()
			for step in range(22):
				var angle = a + step * 0.14
				points.append(Vector2(cos(angle) * 24, -55 + sin(angle) * 43))
			draw_polyline(points, Color(c, 0.7), 2, true)
		for y in [-92, -61, -30]:
			draw_line(Vector2(-39, y), Vector2(-34, y + 5), c, 3)
			draw_line(Vector2(34, y + 5), Vector2(39, y), c, 3)
	draw_string(ThemeDB.fallback_font, Vector2(-48, -136 if kind != 2 else -110), caption, HORIZONTAL_ALIGNMENT_CENTER, 96, 12, c)

func _draw_portal_glow(rect: Rect2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(32):
		points.append(rect.get_center() + Vector2(cos(i * TAU / 32), sin(i * TAU / 32)) * rect.size * 0.5)
	draw_colored_polygon(points, color)
