extends SceneTree

# Run once with --headless --path . --script res://scripts/build_swamp_levels.gd.
# The resulting TileMaps and objects are saved into ordinary, editable .tscn files.
const ART = "res://Assets/BG/2/craftpix-net-672461-free-swamp-game-tileset-pixel-art/"
var LEVEL_SCRIPT: Script
var HAZARD: Script
var PLATFORM: Script
var BOARD: Script
var GATE: Script
var PICKUP: Script

var scene: Node2D
var terrain: TileMapLayer
var ground_heights: Dictionary
var tiles: TileSet
var platform_tiles: TileSet
var serial: int = 0

const CHAPTERS = [
	{"title": "Mosslight Trail", "width": 96,
	 "floor": [[0, 16, 10], [20, 37, 10], [41, 56, 9], [60, 76, 10], [80, 95, 10]],
	 "islands": [[7, 10, 7], [25, 29, 7], [44, 49, 6], [65, 69, 7], [84, 89, 7]],
	 "blades": [[32, 10, 0, 0], [67, 10, 90, 0]], "fires": [[52, 9]],
	 "boards": [5, 42, 82], "elevators": [[26, 10, 0, -192]],
	 "movers": [[18, 10, 96, 0], [58, 10, 96, 0]],
	 "warps": [[71, 10, 86, 7]], "checks": [23, 62],
	 "enemies": [12, 28, 47, 73, 88], "buffs": [[4, 3], [22, 4], [46, 2], [64, 3], [82, 4]]},
	{"title": "Canopy Ascent", "width": 112,
	 "floor": [[0, 15, 11], [19, 35, 10], [40, 59, 9], [63, 81, 10], [86, 111, 10]],
	 "islands": [[6, 10, 8], [24, 29, 5], [45, 50, 5], [69, 74, 6], [92, 99, 5]],
	 "blades": [[31, 10, 0, -80], [54, 9, 100, 0], [95, 10, 0, -100]],
	 "fires": [[76, 10]], "boards": [4, 43, 90],
	 "elevators": [[23, 10, 0, -260], [68, 10, 0, -256], [101, 10, 0, -300]],
	 "movers": [[37, 10, 110, -64], [83, 10, 110, 0]],
	 "warps": [[73, 6, 95, 5]], "checks": [21, 65, 89],
	 "enemies": [12, 29, 47, 57, 72, 96, 105], "buffs": [[4, 4], [20, 3], [43, 2], [66, 4], [88, 3], [103, 2]]},
	{"title": "Emberfen Crossing", "width": 120,
	 "floor": [[0, 14, 10], [18, 33, 10], [37, 53, 9], [57, 72, 10], [76, 95, 10], [99, 119, 10]],
	 "islands": [[8, 11, 7], [23, 28, 7], [43, 48, 6], [62, 66, 7], [82, 87, 7], [105, 111, 7]],
	 "blades": [[26, 10, 90, 0], [65, 10, 0, -90], [108, 10, 100, 0]],
	 "fires": [[11, 10], [45, 9], [69, 10], [88, 10], [114, 10]],
	 "boards": [6, 41, 80, 103], "elevators": [[61, 10, 0, -200]],
	 "movers": [[35, 10, 100, -64], [74, 10, 90, 0], [97, 10, 90, 0]],
	 "warps": [[50, 9, 63, 7]], "checks": [20, 59, 101],
	 "enemies": [23, 41, 50, 64, 83, 93, 106], "buffs": [[5, 3], [19, 4], [39, 2], [58, 3], [78, 4], [100, 2]]},
	{"title": "The Rune Sanctuary", "width": 128,
	 "floor": [[0, 16, 10], [20, 36, 9], [40, 55, 10], [59, 77, 9], [81, 96, 10], [100, 127, 10]],
	 "islands": [[7, 11, 7], [25, 30, 5], [45, 50, 6], [65, 71, 5], [86, 92, 6], [107, 114, 6]],
	 "blades": [[13, 10, 80, 0], [32, 9, 0, -70], [69, 9, 110, 0], [111, 10, 0, -100]],
	 "fires": [[48, 10], [74, 9], [91, 10], [119, 10]],
	 "boards": [5, 43, 84, 105],
	 "elevators": [[24, 9, 0, -260], [64, 9, 0, -256], [104, 10, 0, -256]],
	 "movers": [[18, 10, 96, -64], [57, 10, 96, -64], [98, 10, 90, 0]],
	 "warps": [[28, 5, 47, 6], [70, 5, 89, 6], [113, 6, 123, 10]],
	 "checks": [22, 61, 102], "enemies": [11, 27, 43, 53, 67, 85, 94, 109, 122],
	 "buffs": [[4, 3], [21, 4], [42, 2], [60, 3], [83, 4], [101, 2]]}
]

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	LEVEL_SCRIPT = load("res://Scenes/Levels/swamp_level.gd")
	HAZARD = load("res://Scenes/Prefabs/swamp_hazard.gd")
	PLATFORM = load("res://Scenes/Prefabs/moving_platform.gd")
	BOARD = load("res://Scenes/Prefabs/jump_board.gd")
	GATE = load("res://Scenes/Prefabs/portal_gate.gd")
	PICKUP = load("res://Scenes/Prefabs/swamp_pickup.gd")
	tiles = _tileset()
	ResourceSaver.save(tiles, "res://Scenes/Prefabs/swamp_tileset.tres")
	tiles = load("res://Scenes/Prefabs/swamp_tileset.tres")
	platform_tiles = tiles.duplicate(true)
	for n in platform_tiles.get_source_count():
		var source = platform_tiles.get_source(platform_tiles.get_source_id(n)) as TileSetAtlasSource
		var data = source.get_tile_data(Vector2i.ZERO, 0)
		for polygon in data.get_collision_polygons_count(0):
			data.set_collision_polygon_one_way(0, polygon, true)
			data.set_collision_polygon_one_way_margin(0, polygon, 5)
	ResourceSaver.save(platform_tiles, "res://Scenes/Prefabs/swamp_platform_tileset.tres")
	platform_tiles = load("res://Scenes/Prefabs/swamp_platform_tileset.tres")
	_save_prefabs()
	for i in CHAPTERS.size():
		_build_chapter(i + 1, CHAPTERS[i])
	print("Built four editable swamp levels and 60 tiles with silhouette collision polygons")
	quit()

func _tileset() -> TileSet:
	var result = TileSet.new()
	result.tile_size = Vector2i(32, 32)
	result.add_physics_layer()
	result.set_physics_layer_collision_layer(0, 1)
	result.set_physics_layer_collision_mask(0, 0)
	for n in range(1, 61):
		var texture: Texture2D = load(ART + "1 Tiles/Tile_%02d.png" % n)
		var atlas = TileSetAtlasSource.new()
		atlas.texture = texture
		atlas.texture_region_size = Vector2i(32, 32)
		atlas.create_tile(Vector2i.ZERO)
		result.add_source(atlas, n - 1)
		var data = atlas.get_tile_data(Vector2i.ZERO, 0)
		var bitmap = BitMap.new()
		bitmap.create_from_image_alpha(texture.get_image(), 0.5)
		var polygons = bitmap.opaque_to_polygons(Rect2i(0, 0, 32, 32), 0.8)
		var count = 0
		for polygon in polygons:
			if polygon.size() < 3:
				continue
			data.add_collision_polygon(0)
			var points = PackedVector2Array()
			for point in polygon:
				points.append(point - Vector2(16, 16))
			data.set_collision_polygon_points(0, count, points)
			count += 1
		if count == 0:
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]))
	return result

func _put(node: Node, label: String, parent: Node = null) -> Node:
	serial += 1
	node.name = "%s_%03d" % [label, serial]
	(parent if parent != null else scene).add_child(node)
	node.owner = scene
	return node

func _build_chapter(number: int, data: Dictionary) -> void:
	serial = 0
	ground_heights = {}
	scene = Node2D.new()
	scene.name = "SwampLevel%02d" % number
	scene.set_script(LEVEL_SCRIPT)
	scene.level_index = number
	scene.level_title = data.title
	scene.level_width = data.width * 64.0
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background(number)
	terrain = _put(TileMapLayer.new(), "SwampTerrain")
	terrain.name = "Terrain"
	terrain.tile_set = tiles
	terrain.scale = Vector2(2, 2)
	for floor in data.floor:
		_land(floor[0], floor[1], floor[2], 17 - floor[2])
		for x in range(floor[0], floor[1] + 1):
			ground_heights[x] = floor[2]
	var ground = terrain
	terrain = _put(TileMapLayer.new(), "CanopyPlatforms")
	terrain.name = "CanopyPlatforms"
	terrain.tile_set = platform_tiles
	terrain.scale = Vector2(2, 2)
	for island in data.islands:
		_land(island[0], island[1], island[2], 1)
		_pickup(island[0] * 64 + 90, island[2] * 64 - 55, 1)
		for x in range(island[0] + 2, island[1] + 1):
			_pickup(x * 64 + 32, island[2] * 64 - 45, 0)
	terrain = ground
	for floor in data.floor:
		_decorate(floor, number)
		for x in range(floor[0] + 3, floor[1] - 1, 3):
			_pickup(x * 64 + 32, floor[2] * 64 - 47, 0)
	# Coin arcs communicate where to jump across each gap.
	for j in range(data.floor.size() - 1):
		var left = data.floor[j]
		var right = data.floor[j + 1]
		var gap_start = (left[1] + 1) * 64
		var gap_end = right[0] * 64
		var gap_y = min(left[2], right[2]) * 64
		for step in range(4):
			_pickup(lerpf(gap_start, gap_end, (step + 0.5) / 4.0), gap_y - 85 - sin((step + 0.5) * PI / 4) * 65, 0)
		_hazard(Vector2((gap_start + gap_end) / 2.0, gap_y + 80), 2, Vector2(gap_end - gap_start, 110))
	for blade in data.blades:
		_hazard(Vector2(blade[0] * 64, blade[1] * 64 - 48), 0, Vector2(64, 64), Vector2(blade[2], blade[3]))
	for fire in data.fires:
		_hazard(Vector2(fire[0] * 64, fire[1] * 64 - 35), 1, Vector2(66, 70))
	for x in data.boards:
		var board = Area2D.new()
		board.set_script(BOARD)
		board.position = Vector2(x * 64 + 32, ground_heights.get(x, 10) * 64 - 4)
		_put(board, "JumpBoard")
	for lift in data.elevators:
		_platform(lift, 1)
	for mover in data.movers:
		_platform(mover, 0)
	for pair in data.warps:
		_gate(Vector2(pair[0] * 64 + 32, pair[1] * 64), 0, "WARP", Vector2(pair[2] * 64 + 32, pair[3] * 64 - 5))
		_gate(Vector2(pair[2] * 64 + 32, pair[3] * 64), 0, "WARP", Vector2(pair[0] * 64 + 32, pair[1] * 64 - 5))
	for x in data.checks:
		_gate(Vector2(x * 64 + 32, ground_heights.get(x, 10) * 64), 2, "REST")
	for entry in data.buffs:
		_pickup(entry[0] * 64 + 32, ground_heights.get(entry[0], 10) * 64 - 44, entry[1])
	for j in data.enemies.size():
		var x = data.enemies[j]
		var enemy = load("res://Scenes/Actors/monster_slim.tscn" if j % 2 == 0 else "res://Scenes/Actors/monster_mushroom.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		enemy.position = Vector2(x * 64 + 32, ground_heights.get(x, 10) * 64 - 4)
		enemy.speed = 55 + number * 8
		enemy.hp = 50 + (25 if number == 4 else 0)
		enemy.hp_max = enemy.hp
		enemy.score = 25
		enemy.type = 1
		enemy.direction = -1
		enemy.label = "Moss Slime" if j % 2 == 0 else "Sporeling"
		_put(enemy, "Enemy")
	var player = load("res://Scenes/Actors/player.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_put(player, "Player")
	player.name = "Player"
	player.position = Vector2(160, data.floor[0][2] * 64 - 8)
	player.double_jump = true
	player.rotation = 0
	var camera: Camera2D = player.get_node("Camera2D")
	camera.position = Vector2(0, -80)
	camera.limit_left = 0
	camera.limit_right = data.width * 64
	camera.limit_top = -160
	camera.limit_bottom = 950
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	var finish = _gate(Vector2((data.width - 3) * 64 + 32, 640), 1, "SANCTUARY" if number == 4 else "NEXT TRAIL")
	finish.next_level = "res://Scenes/Levels/level_%02d.tscn" % (number + 1) if number < 4 else "res://Scenes/Levels/game_win.tscn"
	var hud = load("res://Scenes/Levels/game_ui.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_put(hud, "UserInterface")
	hud.name = "UserInterface"
	_sign(Vector2(110, data.floor[0][2] * 64 - 200), "%02d  /  %s" % [number, data.title.to_upper()], "A / D  MOVE    SPACE  DOUBLE JUMP    X  BOW" if number == 1 else ["", "", "RIDE THE LIFTS. FOLLOW THE GOLD.", "WATCH THE FIRE. TIME YOUR CROSSING.", "AWAKEN THE RUNES. REACH THE SANCTUARY."][number])
	_sign(Vector2(data.boards[0] * 64 - 64, ground_heights.get(data.boards[0], 10) * 64 - 135), "SPRINGBOARD", "LAND ON IT TO SOAR")
	for x in data.checks:
		_sign(Vector2(x * 64 - 80, ground_heights.get(x, 10) * 64 - 190), "A PLACE TO REST", "CHECKPOINT  /  RECOVER HEALTH")
	var packed = PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://Scenes/Levels/level_%02d.tscn" % number) == OK)
	print("Saved chapter ", number, ": ", data.title, " (", data.width * 64, " px)")
	scene.free()

func _land(left: int, right: int, top: int, depth: int) -> void:
	for x in range(left, right + 1):
		for y in range(top, top + depth):
			var tile = 12
			if y == top:
				tile = 1 if x == left else (3 if x == right else 2)
			elif y == top + depth - 1:
				tile = 21 if x == left else (23 if x == right else 22)
			elif x == left:
				tile = 11
			elif x == right:
				tile = 13
			terrain.set_cell(Vector2i(x, y), tile - 1, Vector2i.ZERO)

func _background(number: int) -> void:
	var backdrop = CanvasLayer.new()
	backdrop.layer = -20
	_put(backdrop, "Sky")
	var color = ColorRect.new()
	color.size = Vector2(2000, 1200)
	color.color = [Color("3b4f50"), Color("344c50"), Color("51434c"), Color("323e50")][number - 1]
	color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(color, "SkyColor", backdrop)
	for layer in range(1, 6):
		var parallax = Parallax2D.new()
		parallax.scroll_scale = Vector2(0.05 + layer * 0.08, 0.08)
		parallax.repeat_size = Vector2(1382.4, 0)
		parallax.repeat_times = 3
		parallax.z_index = -15 + layer
		_put(parallax, "ForestLayer")
		var sprite = Sprite2D.new()
		sprite.texture = load(ART + "2 Background/Layers/%d.png" % layer)
		sprite.centered = false
		sprite.position = Vector2(0, -220)
		sprite.scale = Vector2(2.4, 2.4)
		sprite.modulate = [Color("a5bdaa"), Color("90bbb5"), Color("c7a29c"), Color("a49cce")][number - 1]
		_put(sprite, "Forest", parallax)
	var motes = Node2D.new()
	motes.set_script(load("res://Scenes/Levels/swamp_motes.gd"))
	_put(motes, "Fireflies")

func _decorate(floor: Array, chapter_number: int) -> void:
	for x in range(floor[0] + 1, floor[1], 4):
		var tree = Sprite2D.new()
		tree.texture = load(ART + "3 Objects/Willows/%d.png" % (1 + x % 3))
		tree.position = Vector2(x * 64 + 32, floor[2] * 64 + 2)
		tree.offset.y = -tree.texture.get_height() * 0.5
		tree.scale = Vector2(2.4, 2.4)
		tree.z_index = -3
		tree.modulate = Color("839c87") if chapter_number < 3 else Color("a3a18f")
		_put(tree, "Willow")
	for x in range(floor[0] + 1, floor[1], 2):
		var grass = Sprite2D.new()
		grass.texture = load(ART + "3 Objects/Grass/%d.png" % (1 + x % 10))
		grass.position = Vector2(x * 64 + 14, floor[2] * 64 + 4)
		grass.offset.y = -grass.texture.get_height() * 0.5
		grass.scale = Vector2(2, 2)
		grass.z_index = 2
		_put(grass, "Grass")

func _pickup(x: float, y: float, kind: int) -> void:
	var node = Area2D.new()
	node.set_script(PICKUP)
	node.position = Vector2(x, y)
	node.kind = kind
	_put(node, "Pickup")

func _hazard(at: Vector2, kind: int, size: Vector2, travel: Vector2 = Vector2.ZERO) -> void:
	var node = Area2D.new()
	node.set_script(HAZARD)
	node.position = at
	node.kind = kind
	node.hazard_size = size
	node.travel = travel
	node.phase = serial * 0.17
	_put(node, ["Blade", "Fire", "Lava"][kind])

func _platform(data: Array, kind: int) -> void:
	var node = AnimatableBody2D.new()
	node.set_script(PLATFORM)
	node.position = Vector2(data[0] * 64 + 32, data[1] * 64 - 14)
	node.kind = kind
	node.travel = Vector2(data[2], data[3])
	node.duration = 4.2 if kind == 1 else 3.6
	_put(node, "Elevator" if kind == 1 else "MovingPlatform")

func _gate(at: Vector2, kind: int, caption: String, destination: Vector2 = Vector2.ZERO) -> Area2D:
	var node = Area2D.new()
	node.set_script(GATE)
	node.position = at
	node.kind = kind
	node.caption = caption
	node.destination = destination
	return _put(node, ["WarpGate", "ExitGate", "Checkpoint"][kind])

func _sign(at: Vector2, title: String, hint: String) -> void:
	var label = Label.new()
	label.position = at
	label.size = Vector2(440, 85)
	label.text = title + "\n" + hint
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("e7e6bd"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color("203b39"))
	_put(label, "TrailSign")

func _save_prefabs() -> void:
	var definitions = [
		["blade_trap", Area2D, HAZARD, {"kind": 0}],
		["fire_trap", Area2D, HAZARD, {"kind": 1, "hazard_size": Vector2(64, 70)}],
		["lava_pool", Area2D, HAZARD, {"kind": 2, "hazard_size": Vector2(192, 64)}],
		["elevator", AnimatableBody2D, PLATFORM, {"kind": 1, "travel": Vector2(0, -256)}],
		["moving_platform", AnimatableBody2D, PLATFORM, {"kind": 0}],
		["jump_board", Area2D, BOARD, {}],
		["portal_gate", Area2D, GATE, {}],
		["checkpoint", Area2D, GATE, {"kind": 2, "caption": "REST"}],
		["gold_coin", Area2D, PICKUP, {"kind": 0}],
		["diamond", Area2D, PICKUP, {"kind": 1}],
		["heart", Area2D, PICKUP, {"kind": 2}],
		["speed_boost", Area2D, PICKUP, {"kind": 3}],
		["jump_boost", Area2D, PICKUP, {"kind": 4}]]
	for entry in definitions:
		var node = entry[1].new()
		node.name = entry[0].to_pascal_case()
		node.set_script(entry[2])
		for key in entry[3]:
			node.set(key, entry[3][key])
		var packed = PackedScene.new()
		packed.pack(node)
		ResourceSaver.save(packed, "res://Scenes/Prefabs/" + entry[0] + ".tscn")
		node.free()
