extends SceneTree

var failures: Array[String] = []
var gm: Node
var player: CharacterBody2D
var level: Node2D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	gm = root.get_node("GameManager")
	# A watchdog converts a stuck coroutine into a failing test rather than a hung run.
	create_timer(50).timeout.connect(func(): push_error("Test timeout"); quit(2))
	var tiles: TileSet = load("res://Scenes/Prefabs/swamp_tileset.tres")
	check(tiles.get_source_count() == 60, "Expected all 60 swamp tiles")
	for n in 60:
		var source = tiles.get_source(n) as TileSetAtlasSource
		var tile = source.get_tile_data(Vector2i.ZERO, 0)
		check(tile.get_collision_polygons_count(0) > 0, "Tile %d has no collision polygon" % n)
		for p in tile.get_collision_polygons_count(0):
			check(tile.get_collision_polygon_points(0, p).size() >= 3, "Tile polygon is invalid")
	for n in range(1, 5):
		gm.restart()
		change_scene_to_file("res://Scenes/Levels/level_%02d.tscn" % n)
		await frames(30)
		level = current_scene
		player = level.get_node("Player")
		check(player.is_on_floor(), "Player spawn is not on terrain in chapter %d" % n)
		check(level.get_node("Terrain").get_used_cells().size() > 500, "Level is too small")
		check(level.level_width >= 6000, "Level width below design size")
		check(get_nodes_in_group("Hazards").size() >= 7, "Missing hazards")
		check(get_nodes_in_group("JumpBoards").size() >= 3, "Missing jumpboards")
		check(get_nodes_in_group("MovingPlatforms").size() >= 3, "Missing elevators/platforms")
		check(get_nodes_in_group("Pickups").size() >= 40, "Missing collectibles")
		var gates = get_nodes_in_group("PortalGates")
		var exits = gates.filter(func(g): return g.kind == 1)
		check(exits.size() == 1, "Expected a single exit")
		check(exits[0].next_level.ends_with("level_%02d.tscn" % (n + 1)) if n < 4 else exits[0].next_level.ends_with("game_win.tscn"), "Broken level progression")
	print("Checked all four levels, player spawns, tile polygons and exit chain")

	# Isolate behavior tests in chapter one, keeping the ordinary player and physics.
	gm.restart()
	change_scene_to_file("res://Scenes/Levels/level_01.tscn")
	await frames(25)
	level = current_scene
	player = level.get_node("Player")
	for enemy in get_nodes_in_group("Enemy"):
		if enemy is CharacterBody2D:
			enemy.queue_free()
	await frames(2)
	var start = player.position.x
	Input.action_press("Right")
	await frames(15)
	Input.action_release("Right")
	check(player.position.x > start + 60, "Walking input did not move the player")
	await frames(15)
	player.jump()
	check(player.velocity.y < -600, "Jump impulse missing")
	await frames(4)
	player.jump()
	check(player.velocity.y < -600, "Double jump missing")
	await frames(55)

	# Speed and jump buffs are temporary, capped, and shown through the same player state.
	var speed = load("res://Scenes/Prefabs/speed_boost.tscn").instantiate()
	level.add_child(speed)
	speed._collect(player)
	check(player.speed_time > 11, "Speed pickup failed")
	Input.action_press("Right")
	await frames(2)
	check(player.velocity.x > 440, "Speed multiplier not applied")
	Input.action_release("Right")
	var leap = load("res://Scenes/Prefabs/jump_boost.tscn").instantiate()
	level.add_child(leap)
	leap._collect(player)
	player.jump()
	check(player.velocity.y < -800, "Jump buff not applied")
	player.speed_time = 0.02
	player.jump_time = 0.02
	await frames(5)
	check(player.speed_time == 0 and player.jump_time == 0, "Buffs did not expire")
	var hearts_before = gm.get_stat("life")
	gm.player_stats.data_set("hp", 40)
	var heart = load("res://Scenes/Prefabs/heart.tscn").instantiate()
	level.add_child(heart)
	heart._collect(player)
	check(gm.get_stat("life") == hearts_before + 1 and gm.get_stat("hp") == 75, "Heart effect incorrect")
	var score_before = gm.get_stat("score")
	var gem = load("res://Scenes/Prefabs/diamond.tscn").instantiate()
	level.add_child(gem)
	gem._collect(player)
	check(gm.get_stat("diamonds") == 1 and gm.get_stat("score") == score_before + 100, "Diamond effect incorrect")
	var coin = load("res://Scenes/Prefabs/gold_coin.tscn").instantiate()
	level.add_child(coin)
	coin._collect(player)
	check(gm.get_stat("coins") >= 1, "Coin effect incorrect")
	print("Checked movement, jumps and all five item effects")

	# An elevator must transport the standing character using Godot's platform velocity.
	player.position = Vector2(320, 338)
	player.velocity = Vector2.ZERO
	var lift = load("res://Scenes/Prefabs/elevator.tscn").instantiate()
	lift.position = Vector2(320, 350)
	lift.travel = Vector2(0, -160)
	lift.duration = 4
	level.add_child(lift)
	await frames(10)
	var rider_y = player.position.y
	await frames(35)
	check(player.is_on_floor() and player.position.y < rider_y - 25, "Elevator did not carry the player")
	lift.queue_free()
	await frames(2)
	player.position = Vector2(320, 338)
	player.velocity = Vector2.ZERO
	var moving = load("res://Scenes/Prefabs/moving_platform.tscn").instantiate()
	moving.position = Vector2(320, 350)
	moving.travel = Vector2(160, 0)
	moving.duration = 4
	level.add_child(moving)
	await frames(45)
	check(player.is_on_floor() and player.position.x > 350, "MovingPlatform did not carry the player horizontally")
	moving.queue_free()
	player.position = Vector2(320, 400)
	player.velocity = Vector2(0, 100)
	var board = load("res://Scenes/Prefabs/jump_board.tscn").instantiate()
	board.position = Vector2(320, 414)
	level.add_child(board)
	await frames(5)
	check(player.velocity.y < -800, "JumpBoard did not launch the player")
	board.queue_free()
	var portal = get_nodes_in_group("PortalGates").filter(func(g): return g.kind == 0)[0]
	player.portal_cooldown = 0
	portal._entered(player)
	check(player.position.distance_to(portal.destination) < 1, "Portal destination incorrect")
	var warped = player.position
	var other = get_nodes_in_group("PortalGates").filter(func(g): return g.kind == 0)[1]
	other._entered(player)
	check(player.position.distance_to(warped) < 1, "Portal bounced player back immediately")
	var checkpoint = get_nodes_in_group("PortalGates").filter(func(g): return g.kind == 2)[0]
	checkpoint._entered(player)
	check(player.spawn_point.distance_to(checkpoint.position + Vector2(68, 0)) < 1, "Checkpoint spawn not updated")
	print("Checked elevator passenger, springboard, portals and checkpoint")

	# Arrow collision has one owner: 25 damage per arrow, no duplicate Area2D hit.
	player.set_physics_process(false)
	player.position = Vector2(160, 600)
	var target = load("res://Scenes/Actors/monster_slim.tscn").instantiate()
	target.hp = 50
	target.hp_max = 50
	target.position = Vector2(450, 640)
	level.add_child(target)
	target.set_physics_process(false)
	var arrow = load("res://Scenes/Prefabs/arrow.tscn").instantiate()
	level.add_child(arrow)
	arrow.position = Vector2(250, 612)
	arrow.shoot(Vector2.RIGHT, 780, 2.5)
	await frames(22)
	check(target.hp == 25, "Arrow damage should be exactly 25")
	var arrow2 = load("res://Scenes/Prefabs/arrow.tscn").instantiate()
	level.add_child(arrow2)
	arrow2.position = Vector2(250, 612)
	arrow2.shoot(Vector2.RIGHT, 780, 2.5)
	await frames(22)
	check(not target.alive, "Two arrows did not defeat enemy")
	player.can_damage = true
	var hp_before = gm.get_stat("hp")
	player.receive_hit(30, player.position + Vector2(20, 0))
	player.receive_hit(30, player.position + Vector2(20, 0))
	check(gm.get_stat("hp") == hp_before - 30, "Hazard invincibility not respected")
	await create_timer(1.9).timeout
	# Check actual Area2D contacts, including the fire's safe and active phases.
	player.position = Vector2(320, 300)
	player.velocity = Vector2.ZERO
	gm.player_stats.data_set("hp", 100)
	player.can_damage = true
	var blade = load("res://Scenes/Prefabs/blade_trap.tscn").instantiate()
	blade.position = Vector2(320, 267)
	level.add_child(blade)
	await frames(5)
	check(gm.get_stat("hp") == 70, "Blade collider did not deal exactly 30 damage")
	blade.queue_free()
	await create_timer(1.9).timeout
	var fire = load("res://Scenes/Prefabs/fire_trap.tscn").instantiate()
	fire.position = Vector2(320, 267)
	level.add_child(fire)
	await frames(5)
	check(gm.get_stat("hp") == 70, "Fire dealt damage during its safe phase")
	fire.clock = 1.8
	await frames(3)
	check(gm.get_stat("hp") == 50, "Active fire did not deal 20 damage")
	fire.queue_free()
	await create_timer(1.9).timeout
	player.set_physics_process(true)
	print("Checked arrow damage, enemy defeat and damage invincibility")

	# Save tests use a dedicated temporary file, preserving the user's saved game.
	var real_save = gm.save_path
	gm.save_path = "user://swamp-smoke-test.save"
	player.position = Vector2(200, 638)
	player.speed_time = 8
	var saved_score = gm.get_stat("score")
	gm.save_game()
	var checkpoint_before = player.spawn_point
	gm.restart()
	gm.load_game()
	await scene_changed
	await frames(4)
	player = current_scene.get_node("Player")
	check(gm.get_stat("score") == saved_score, "Score did not reload")
	check(player.speed_time > 7, "Active buff did not reload")
	check(player.spawn_point.distance_to(checkpoint_before) < 1, "Checkpoint did not reload")
	check(gm.collected.size() > 0, "Collected item state did not reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gm.save_path))
	gm.save_path = real_save
	print("Checked save/load for score, checkpoint, collected items and buffs")

	# Final-life death reaches GameOver; buttons really restart and return to menu.
	gm.player_stats.data_set("life", 1)
	player.set_physics_process(false)
	var lava = load("res://Scenes/Prefabs/lava_pool.tscn").instantiate()
	lava.position = player.position + Vector2(0, -30)
	current_scene.add_child(lava)
	await create_timer(1.65).timeout
	check(current_scene.scene_file_path.ends_with("game_over.tscn"), "Last life did not reach GameOver")
	current_scene._again()
	await scene_changed
	await frames(5)
	check(current_scene.scene_file_path.ends_with("level_01.tscn") and gm.get_stat("life") == 4, "Try Again did not reset the run")
	change_scene_to_file("res://Scenes/Levels/level_04.tscn")
	await scene_changed
	await frames(4)
	var final_exit = get_nodes_in_group("PortalGates").filter(func(g): return g.kind == 1)[0]
	final_exit._entered(current_scene.get_node("Player"))
	await scene_changed
	await frames(5)
	check(current_scene.scene_file_path.ends_with("game_win.tscn"), "Fourth exit did not reach WinGame")
	current_scene._menu()
	await scene_changed
	await frames(4)
	check(current_scene.scene_file_path.ends_with("menu.tscn"), "Ending Main Menu button failed")
	print("Checked GameOver, Try Again, final portal, WinGame and Main Menu")
	current_scene.queue_free()
	await frames(3)
	if failures.is_empty():
		print("PASS: swamp gameplay integration")
		quit(0)
	else:
		print("FAIL: ", failures)
		quit(1)
