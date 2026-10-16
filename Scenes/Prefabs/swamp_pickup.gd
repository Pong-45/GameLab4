@tool
extends Area2D

@export_enum("Coin", "Diamond", "Heart", "Speed", "Jump") var kind: int = 0
@export var amount: int = 1
@export var buff_duration: float = 12.0
var clock = 0.0
var collected = false
var sprite: Sprite2D
var frames: Array[Texture2D] = []
var origin = Vector2.ZERO
var pickup_key = ""
const COINS = "res://Assets/BG/2/craftpix-513237-free-game-coins-sprite-sheets/PNG/Gold/Gold_%d.png"
const ICONS = ["", "res://Assets/Swamp/diamond.svg", "res://Assets/Icons/icons8-heart-48.png", "res://Assets/Swamp/speed.svg", "res://Assets/Swamp/jump.svg"]

func _ready() -> void:
	origin = position
	clock = position.x * 0.01
	if Engine.is_editor_hint():
		return
	pickup_key = str(get_tree().current_scene.scene_file_path) + ":" + str(get_path())
	if GameManager.collected.has(pickup_key):
		queue_free()
		return
	add_to_group("Pickups")
	collision_layer = 0
	collision_mask = 2
	var collider = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 23
	collider.shape = shape
	add_child(collider)
	sprite = Sprite2D.new()
	add_child(sprite)
	if kind == 0:
		for i in range(1, 31):
			frames.append(load(COINS % i))
		sprite.texture = frames[0]
		sprite.scale = Vector2.ONE * 0.055
	else:
		sprite.texture = load(ICONS[kind])
		sprite.scale = Vector2.ONE * (0.7 if kind == 2 else 0.85)
	body_entered.connect(_collect)

func _process(delta: float) -> void:
	clock += delta
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if collected:
		return
	position = origin + Vector2(0, sin(clock * 3) * 5)
	if kind == 0 and sprite != null:
		sprite.texture = frames[int(clock * 22) % frames.size()]
	queue_redraw()

func _collect(body: Node2D) -> void:
	if collected or not body is Player or body.is_dying:
		return
	collected = true
	GameManager.collected[pickup_key] = true
	match kind:
		0:
			GameManager.player_stats.data_add("coins", amount)
			GameManager.add_score(10 * amount)
		1:
			GameManager.player_stats.data_add("diamonds", amount)
			GameManager.add_score(100 * amount)
		2:
			GameManager.add_life()
			GameManager.add_hp(35)
		3:
			body.speed_time = buff_duration
		4:
			body.jump_time = buff_duration
	AudioManager.play_effect("pickup", -12, 1.25 if kind == 1 else 1)
	if kind >= 2:
		get_tree().call_group("GameHUD", "alert", ["", "", "+1 HEART  /  +35 HP", "SPEED BOOST  /  12s", "HIGH JUMP  /  12s"][kind])
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 36, 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	await tween.finished
	queue_free()

func _draw() -> void:
	var colors = [Color("efcd6d"), Color("7de5e0"), Color("ed8996"), Color("efdc78"), Color("bea5ee")]
	draw_circle(Vector2.ZERO, 25 + sin(clock * 2) * 2, Color(colors[kind], 0.07))
	if Engine.is_editor_hint():
		var icon: Texture2D = load(COINS % 1 if kind == 0 else ICONS[kind])
		draw_texture_rect(icon, Rect2(-16, -16, 32, 32), false)
