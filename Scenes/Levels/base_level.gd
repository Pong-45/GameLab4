extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.player = %Player
	$MusicPlayer.stop()
	AudioManager.start_music(1)
	$UserInterface.alert("THE EMERALD BOW")

func _on_player_hit_enemy() -> void:
	GameManager.damage(5)	

func _on_player_hit_trap() -> void:
	GameManager.death()


func _on_music_player_finished() -> void:
	pass
