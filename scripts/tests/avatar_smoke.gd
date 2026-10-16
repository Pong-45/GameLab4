extends SceneTree

# Run with Godot --headless --path . --script res://scripts/tests/avatar_smoke.gd
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = Node2D.new()
	root.add_child(world)
	current_scene = world
	var player = load("res://Scenes/Actors/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	# Keep the player's processing enabled: AnimationPlayer inherits its process owner.
	var manager = root.get_node("GameManager")
	manager.player = player
	var animator: AnimationPlayer = player.get_node("Avatar/AnimationPlayer")
	var sprite: Sprite2D = player.get_node("Avatar/Sprite")
	for name in ["Idle", "Walk", "Run", "Jump", "Attack", "Hurt", "Die"]:
		assert(animator.has_animation(name), "Missing animation: " + name)
		var animation = animator.get_animation(name)
		assert(animation.track_get_key_count(0) == 10, name + " must use all ten frames")
		animator.play(name)
		animator.advance(0)
		var first_texture = sprite.texture
		animator.advance(animation.length * 0.5)
		assert(sprite.texture != first_texture, name + " did not advance frames")
		assert(sprite.texture is AtlasTexture)

	# A completed jump holds its final pose rather than restarting in midair.
	animator.play("Jump")
	animator.advance(1)
	player._play_animation("Jump")
	assert(not animator.is_playing(), "Jump restarted after completion")
	player.flip_x = true
	player.flip_player()
	assert(player.player_node.scale.x == -1)
	assert(player.bullet_marker.position.x < 0, "Left-facing shot starts on wrong side")
	player.shoot()
	assert(player.is_attacking)
	assert(animator.assigned_animation == "Attack")
	await create_timer(0.2).timeout
	var bullet = world.get_child(world.get_child_count() - 1)
	assert(bullet.is_in_group("Bullet"))
	assert(bullet.position.x < player.bullet_marker.position.x, "Arrow did not travel left")
	bullet.queue_free()
	await create_timer(0.5).timeout
	assert(not player.is_attacking)
	player.damage_tween()
	assert(player.is_hurt and not player.can_damage)
	await create_timer(0.5).timeout
	assert(not player.is_hurt)
	await create_timer(1.4).timeout
	assert(player.can_damage)
	var lives_before = manager.get_stat("life")
	manager.death()
	assert(player.is_dying)
	assert(animator.assigned_animation == "Die")
	manager.death()
	await create_timer(1.5).timeout
	assert(not player.is_dying and player.movement_enabled)
	assert(manager.get_stat("life") == lives_before - 1, "Death counted multiple times")
	assert(manager.get_stat("hp") == manager.get_stat("hp_max"))
	assert(player.scale.is_equal_approx(Vector2.ONE))
	assert(player.global_position.is_equal_approx(player.spawn_point))
	print("PASS: seven animations, jump hold, facing, projectile, hurt, death and respawn")
	manager.player = null
	world.queue_free()
	await process_frame
	quit()
