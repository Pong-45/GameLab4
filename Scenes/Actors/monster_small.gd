extends Enemy

func _ready() -> void:
	super._ready()
	var types = Array($Sprite/AnimateSprite.sprite_frames.get_animation_names())
	$Sprite/AnimateSprite.animation = types.pick_random()
	_on_state_changed(state)
	

func _on_state_changed(new_state: Enemy.State) -> void:
	# print("new state", new_state)
	if new_state == Enemy.State.IDLE || new_state == Enemy.State.DEAD:
		$Sprite/AnimateSprite.play("",0.1)
	else:
		$Sprite/AnimateSprite.play("",1.0)
	
