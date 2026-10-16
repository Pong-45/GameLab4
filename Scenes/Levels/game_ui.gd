extends CanvasLayer

const Style = preload("res://Scenes/UI/game_style.gd")
const Meter = preload("res://Scenes/UI/meter.gd")
var hp: Control
var stats: Label
var chapter: Label
var boosts: Label
var toast: Label
var progress: Control
var pause_panel: Panel
var toast_time = 0.0
var resume_button: Button
var music_button: Button
var sound_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("GameHUD")
	var bar = Panel.new()
	bar.position = Vector2(20, 18)
	bar.size = Vector2(1160, 92)
	bar.add_theme_stylebox_override("panel", Style.box(Color(0.035, 0.10, 0.11, 0.94)))
	add_child(bar)
	chapter = Style.label(bar, "THE EMERALD BOW", Rect2(20, 10, 360, 27), 18, Style.GOLD)
	Style.label(bar, "HEALTH", Rect2(20, 44, 66, 26), 11, Style.MUTED)
	hp = Meter.new()
	hp.position = Vector2(92, 50)
	hp.size = Vector2(172, 12)
	bar.add_child(hp)
	stats = Style.label(bar, "", Rect2(310, 13, 530, 30), 20)
	boosts = Style.label(bar, "X  DRAW BOW    /    SPACE  DOUBLE JUMP", Rect2(310, 51, 620, 22), 12, Style.MUTED)
	Style.button(bar, "SAVE", Rect2(905, 20, 100, 46), _save)
	Style.button(bar, "MENU  II", Rect2(1017, 20, 123, 46), _toggle_pause)
	progress = Meter.new()
	progress.position = Vector2(36, 108)
	progress.size = Vector2(1128, 3)
	progress.set("background_color", Color(0, 0, 0, 0))
	progress.set("fill_color", Style.GOLD)
	add_child(progress)
	toast = Style.label(self, "", Rect2(225, 133, 750, 50), 20, Style.PAPER)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_stylebox_override("normal", Style.box(Color(0.04, 0.12, 0.12, 0.9)))
	toast.visible = false
	Style.label(self, "A / D   MOVE       SPACE   DOUBLE JUMP       X   BOW       ESC   PAUSE", Rect2(30, 638, 1000, 24), 12, Style.PAPER)
	_make_pause()
	if DisplayServer.is_touchscreen_available():
		for data in [["<", "Left", 25], [">", "Right", 130], ["JUMP", "Jump", 940], ["BOW", "Shoot", 1060]]:
			var button = Style.button(self, data[0], Rect2(data[2], 550, 95, 70), func(): pass)
			button.focus_mode = Control.FOCUS_NONE
			button.button_down.connect(func(): Input.action_press(data[1]))
			button.button_up.connect(func(): Input.action_release(data[1]))

func _make_pause() -> void:
	pause_panel = Panel.new()
	pause_panel.position = Vector2(350, 160)
	pause_panel.size = Vector2(500, 390)
	pause_panel.add_theme_stylebox_override("panel", Style.box(Color("10282d"), Style.GOLD, 18))
	add_child(pause_panel)
	Style.label(pause_panel, "TAKE A BREATH", Rect2(30, 22, 440, 40), 28, Style.GOLD)
	Style.label(pause_panel, "The forest will wait.", Rect2(30, 65, 440, 30), 16, Style.MUTED)
	resume_button = Style.button(pause_panel, "RESUME JOURNEY", Rect2(30, 116, 440, 50), _toggle_pause, true)
	music_button = Style.button(pause_panel, "MUSIC", Rect2(30, 180, 212, 48), _music)
	sound_button = Style.button(pause_panel, "SOUND", Rect2(258, 180, 212, 48), _sound)
	Style.button(pause_panel, "RESTART RUN", Rect2(30, 244, 440, 48), _restart)
	Style.button(pause_panel, "RETURN TO MENU", Rect2(30, 308, 440, 48), _menu)
	pause_panel.hide()

func _process(delta: float) -> void:
	hp.max_value = GameManager.get_stat("hp_max", 100)
	hp.value = GameManager.get_stat("hp", 100)
	stats.text = "LIFE %d    COIN %d    GEM %d    SCORE %d" % [GameManager.get_stat("life"), GameManager.get_stat("coins"), GameManager.get_stat("diamonds"), GameManager.get_stat("score")]
	var player = GameManager.player
	if is_instance_valid(player):
		var active: Array[String] = []
		if player.speed_time > 0:
			active.append("SPEED x1.5  %ds" % ceili(player.speed_time))
		if player.jump_time > 0:
			active.append("JUMP x1.3  %ds" % ceili(player.jump_time))
		boosts.text = "   /   ".join(active) if not active.is_empty() else "X  DRAW BOW    /    SPACE  DOUBLE JUMP"
		if get_tree().current_scene.get("level_width") != null:
			progress.value = 100 * player.global_position.x / get_tree().current_scene.level_width
	if not get_tree().paused:
		toast_time -= delta
		toast.visible = toast_time > 0
	music_button.text = "MUSIC  " + ("ON" if GameManager.music_on else "OFF")
	sound_button.text = "SOUND  " + ("ON" if GameManager.sfx_on else "OFF")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func set_chapter(number: int, title: String) -> void:
	chapter.text = "%02d   /   %s" % [number, title.to_upper()]

func alert(text: String) -> void:
	toast.text = text
	toast_time = 3.0
	toast.show()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	for action in ["Left", "Right", "Jump", "Shoot"]:
		Input.action_release(action)
	if get_tree().paused:
		resume_button.grab_focus()

func _save() -> void:
	if is_instance_valid(GameManager.player) and not GameManager.player.is_dying:
		GameManager.save_game()
		alert("JOURNEY SAVED")

func _music() -> void:
	GameManager.music_on = not GameManager.music_on
	GameManager.update_option()
	GameManager.save_option()

func _sound() -> void:
	GameManager.sfx_on = not GameManager.sfx_on
	GameManager.update_option()
	GameManager.save_option()

func _restart() -> void:
	get_tree().paused = false
	GameManager.restart()
	get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")

func _menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Levels/menu.tscn")
