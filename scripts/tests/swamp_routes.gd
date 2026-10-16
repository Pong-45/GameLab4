extends SceneTree

# Verify every mandatory gap using real player physics and two jump impulses.
# Combat is disabled here; damage and moving-object behavior have separate tests.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var builder = load("res://scripts/build_swamp_levels.gd")
	var chapters = builder.CHAPTERS
	var count = 0
	for number in range(1, 5):
		root.get_node("GameManager").restart()
		change_scene_to_file("res://Scenes/Levels/level_%02d.tscn" % number)
		await scene_changed
		var player = current_scene.get_node("Player")
		for hazard in get_nodes_in_group("Hazards"):
			hazard.set_physics_process(false)
		for enemy in get_nodes_in_group("Enemy"):
			if enemy is CharacterBody2D:
				enemy.queue_free()
		await process_frame
		var floors = chapters[number - 1].floor
		for i in range(floors.size() - 1):
			var left = floors[i]
			var right = floors[i + 1]
			var edge = (left[1] + 1) * 64
			var target_x = right[0] * 64 + 75
			player.position = Vector2(edge - 115, left[2] * 64 - 4)
			player.velocity = Vector2.ZERO
			player.speed_time = 0
			player.jump_time = 0
			player.can_damage = false
			for tick in 4:
				await physics_frame
			Input.action_press("Right")
			var first = false
			var second = false
			var reached = false
			for tick in 180:
				await physics_frame
				if not first and player.position.x > edge - 65 and player.is_on_floor():
					player.jump()
					player.jump_count -= 1
					first = true
				elif first and not second and player.velocity.y > -60 and not player.is_on_floor():
					player.jump()
					player.jump_count -= 1
					second = true
				if player.position.x >= target_x:
					reached = true
					break
				if player.position.y > 1000:
					break
			Input.action_release("Right")
			if not reached:
				failures.append("Chapter %d, gap %d (%d px): stopped at %s" % [number, i + 1, right[0] * 64 - edge, player.position])
			count += 1
		print("Checked main path gaps in chapter ", number)
	current_scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: all ", count, " main-route gaps crossed using player physics")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
