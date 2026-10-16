extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/swamp_previews")
	for number in range(1, 5):
		change_scene_to_file("res://Scenes/Levels/level_%02d.tscn" % number)
		await create_timer(0.5).timeout
		var player = current_scene.get_node("Player")
		player.get_node("Camera2D").reset_smoothing()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/swamp_previews/level_%02d.png" % number)
		player.position.x = 1950 if number == 1 else 2850
		player.position.y = 500
		player.get_node("Camera2D").reset_smoothing()
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/swamp_previews/level_%02d_middle.png" % number)
	for ending in ["game_over", "game_win"]:
		change_scene_to_file("res://Scenes/Levels/" + ending + ".tscn")
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/swamp_previews/" + ending + ".png")
	print("Saved ten rendered previews to .godot/swamp_previews")
	quit()
