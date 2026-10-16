extends Control

const Style = preload("res://Scenes/UI/game_style.gd")
const SWAMP = "res://Assets/BG/2/craftpix-net-672461-free-swamp-game-tileset-pixel-art/"
@export var victory: bool = false

func _ready() -> void:
	GameManager.player = null
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = TextureRect.new()
	background.texture = load(SWAMP + "2 Background/Background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color("7b9287") if victory else Color("595a72")
	add_child(background)
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.08, 0.74)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = Panel.new()
	panel.position = Vector2(64, 102)
	panel.size = Vector2(620, 470)
	panel.add_theme_stylebox_override("panel", Style.box(Color(0.04, 0.12, 0.13, 0.96), Style.GOLD if victory else Color("8d6873"), 20))
	add_child(panel)
	Style.label(panel, "THE EMERALD BOW   /   " + ("YOU WIN" if victory else "GAME OVER"), Rect2(32, 26, 560, 32), 13, Style.GOLD)
	Style.label(panel, "THE FOREST IS SAFE" if victory else "THE FOREST REMEMBERS", Rect2(32, 79, 570, 58), 30, Style.PAPER)
	Style.label(panel, "Four paths. One guardian. A brighter dawn." if victory else "Rest, archer. Every journey begins again.", Rect2(32, 146, 560, 36), 17, Style.MUTED)
	var score = "SCORE  %05d     COINS  %d     GEMS  %d" % [GameManager.get_stat("score"), GameManager.get_stat("coins"), GameManager.get_stat("diamonds")]
	Style.label(panel, score, Rect2(32, 220, 560, 32), 19, Style.GOLD)
	Style.label(panel, "ENEMIES DEFEATED  /  %d" % GameManager.get_stat("killed_enemy"), Rect2(32, 261, 560, 30), 14, Style.MUTED)
	var again = Style.button(panel, "PLAY AGAIN" if victory else "TRY AGAIN", Rect2(32, 338, 267, 58), _again, true)
	Style.button(panel, "MAIN MENU", Rect2(315, 338, 273, 58), _menu)
	Style.label(panel, "A new trail is always waiting.", Rect2(32, 414, 550, 24), 12, Style.MUTED)
	var aura = Node2D.new()
	aura.set_script(load("res://Scenes/Levels/ending_aura.gd"))
	aura.position = Vector2(925, 380)
	aura.set("victory", victory)
	add_child(aura)
	var hero = load("res://Scenes/Sprites/avatar.tscn").instantiate()
	hero.position = Vector2(925, 480)
	hero.scale = Vector2(3.4, 3.4)
	add_child(hero)
	hero.get_node("AnimationPlayer").play("Idle" if victory else "Die")
	Style.label(self, "GUARDIAN OF THE MOSS", Rect2(780, 537, 350, 36), 15, Style.GOLD if victory else Style.MUTED)
	AudioManager.start_music(2 if victory else 1, -29)
	AudioManager.play_effect("win" if victory else "lose", -7)
	again.grab_focus()

func _again() -> void:
	GameManager.restart()
	get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")

func _menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/menu.tscn")
