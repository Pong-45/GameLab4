extends Node2D

@export var level_index: int = 1
@export var level_title = "Mosslight Trail"
@export var level_width: float = 6144.0
@onready var player: Player = $Player

func _ready() -> void:
	GameManager.player = player
	GameManager.current_level = scene_file_path
	var camera: Camera2D = player.get_node("Camera2D")
	camera.position = Vector2(0, -80)
	camera.limit_left = 0
	camera.limit_right = int(level_width)
	camera.limit_top = -160
	camera.limit_bottom = 950
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	if GameManager.saved_checkpoint != Vector2.ZERO:
		player.spawn_point = GameManager.saved_checkpoint
		GameManager.saved_checkpoint = Vector2.ZERO
	player.hit_enemy.connect(_enemy_hit)
	player.hit_trap.connect(GameManager.death)
	AudioManager.start_music(level_index)
	get_tree().call_group("GameHUD", "set_chapter", level_index, level_title)
	$UserInterface.alert("%02d  /  %s" % [level_index, level_title.to_upper()])

func _process(_delta: float) -> void:
	if is_instance_valid(player) and player.global_position.y > 1080 and not player.is_dying:
		GameManager.death()

func _enemy_hit() -> void:
	GameManager.damage(15)
	AudioManager.play_effect("hurt", -12)

func _exit_tree() -> void:
	if GameManager.player == player:
		GameManager.player = null
