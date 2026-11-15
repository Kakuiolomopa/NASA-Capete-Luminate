extends Node2D

const BASE_ORIGIN := Vector2(4832, 3008)
const BASE_COLS := 18
const BASE_ROWS := 12
const TILE := 16
const ROOM_TILE := 32
const FLOOR_TEXTURE_PATH := "res://assets/BaseFloor.png"
const WALL_TEXTURE_PATH := "res://assets/BaseWall.png"
const HUD_SCENE := preload("res://scenes/objective_hud.tscn")
const SURVIVAL_HUD_SCENE := preload("res://scenes/survival_hud.tscn")
const DAY3_SCENE := preload("res://scenes/day3_event.tscn")
const DAY4_SCENE := preload("res://scenes/day4_event.tscn")
const DAY5_SCENE := preload("res://scenes/day5_event.tscn")

var _base_layer: TileMapLayer
var _base_body: StaticBody2D

@onready var player = $Player
@onready var layer: TileMapLayer = $TileMapLayer


func _ready():
	# The old terrain TileMapLayer contains scattered legacy physics cells.
	# Keep Mars visual-only; base and interactable objects own their collisions.
	layer.collision_enabled = false
	_clear_old_base()
	_paint_mars_apron()
	_build_base_room()
	_add_hud()
	SaveManager.apply_pending(player)
	_ensure_player_position()
	_add_survival_content()
	if SaveManager.autosave_on_start:
		SaveManager.autosave_on_start = false
		if SaveManager.current_slot >= 0:
			SaveManager.save_game(SaveManager.current_slot)
			SaveManager.save_checkpoint()


func _clear_old_base():
	var room_rect := Rect2i(
		floori(BASE_ORIGIN.x / 16.0), floori(BASE_ORIGIN.y / 16.0),
		BASE_COLS * 2, BASE_ROWS * 2)
	for y in range(room_rect.position.y, room_rect.end.y):
		for x in range(room_rect.position.x, room_rect.end.x):
			layer.erase_cell(Vector2i(x, y))


func _paint_mars_apron():
	var room_rect := Rect2i(
		floori(BASE_ORIGIN.x / 16.0), floori(BASE_ORIGIN.y / 16.0),
		BASE_COLS * 2, BASE_ROWS * 2)
	var apron := room_rect.grow(32)
	for y in range(apron.position.y, apron.end.y):
		for x in range(apron.position.x, apron.end.x):
			var cell := Vector2i(x, y)
			if room_rect.has_point(cell) or layer.get_cell_source_id(cell) >= 0:
				continue
			var atlas := Vector2i((x + y) & 1, (x * 3 + y) & 1)
			layer.set_cell(cell, 0, atlas)


func _build_base_room():
	if is_instance_valid(_base_layer):
		return
	_base_layer = TileMapLayer.new()
	_base_layer.name = "BaseRoom"
	_base_layer.position = BASE_ORIGIN
	_base_layer.z_index = -2
	_base_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_layer.tile_set = _make_tileset()
	add_child(_base_layer)
	_paint_room()
	_add_base_collision()


func _make_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = load(FLOOR_TEXTURE_PATH)
	floor_source.texture_region_size = Vector2i(TILE, TILE)
	for y in range(2):
		for x in range(2):
			floor_source.create_tile(Vector2i(x, y))
	tileset.add_source(floor_source, 0)
	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = load(WALL_TEXTURE_PATH)
	wall_source.texture_region_size = Vector2i(TILE, TILE)
	for y in range(2):
		for x in range(2):
			wall_source.create_tile(Vector2i(x, y))
	tileset.add_source(wall_source, 1)
	return tileset


func _paint_room():
	var width := BASE_COLS * 2
	var height := BASE_ROWS * 2
	for y in range(2, height - 2):
		for x in range(2, width - 2):
			_set_base_tile(x, y, 0, Vector2i(x & 1, y & 1))
	for x in range(width):
		_set_base_tile(x, 0, 1, Vector2i(x & 1, 1))
		_set_base_tile(x, 1, 1, Vector2i(x & 1, 1))
		_set_base_tile(x, height - 2, 1, Vector2i(x & 1, 1))
		_set_base_tile(x, height - 1, 1, Vector2i(x & 1, 1))
	for y in range(height):
		if y not in [12, 13]:
			_set_base_tile(0, y, 1, Vector2i(y & 1, 1))
			_set_base_tile(1, y, 1, Vector2i(y & 1, 1))
		_set_base_tile(width - 2, y, 1, Vector2i(y & 1, 1))
		_set_base_tile(width - 1, y, 1, Vector2i(y & 1, 1))
	_set_base_tile(0, 12, 0, Vector2i(0, 0))
	_set_base_tile(0, 13, 0, Vector2i(0, 1))
	_set_base_tile(1, 12, 0, Vector2i(1, 0))
	_set_base_tile(1, 13, 0, Vector2i(1, 1))
	for x in range(2, width - 2):
		if x < 8 or x > 15:
			_set_base_tile(x, 12, 1, Vector2i(x & 1, 1))
			_set_base_tile(x, 13, 1, Vector2i(x & 1, 1))


func _set_base_tile(x: int, y: int, source_id: int, atlas := Vector2i.ZERO):
	_base_layer.set_cell(Vector2i(x, y), source_id, atlas)


func _add_base_collision():
	_base_body = StaticBody2D.new()
	_base_body.name = "BaseWalls"
	_base_body.collision_layer = 1
	_base_body.collision_mask = 1
	_base_body.position = BASE_ORIGIN
	add_child(_base_body)
	_add_wall(Vector2(288, 16), Vector2(576, 32))
	_add_wall(Vector2(288, 368), Vector2(576, 32))
	_add_wall(Vector2(16, 104), Vector2(32, 176))
	_add_wall(Vector2(16, 304), Vector2(32, 160))
	_add_wall(Vector2(560, 192), Vector2(32, 384))
	_add_wall(Vector2(80, 208), Vector2(96, 32))
	_add_wall(Vector2(400, 208), Vector2(288, 32))


func _add_wall(center: Vector2, size: Vector2):
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.position = center
	collision.shape = shape
	_base_body.add_child(collision)


func _add_cave_entrance():
	var soil := Polygon2D.new()
	soil.name = "CaveSoil"
	soil.position = Vector2(4848, 3216)
	soil.z_index = 0
	soil.color = Color("71372d")
	soil.polygon = PackedVector2Array([
		Vector2(-72, -96), Vector2(-24, -112), Vector2(32, -104),
		Vector2(72, -72), Vector2(72, 72), Vector2(32, 104),
		Vector2(-40, 104), Vector2(-80, 64), Vector2(-88, -24),
	])
	add_child(soil)
	var mouth := Polygon2D.new()
	mouth.name = "CaveMouth"
	mouth.position = Vector2(4848, 3216)
	mouth.z_index = 1
	mouth.color = Color("1a1117")
	mouth.polygon = PackedVector2Array([
		Vector2(-24, -64), Vector2(24, -64), Vector2(40, -40),
		Vector2(40, 40), Vector2(24, 64), Vector2(-24, 64),
		Vector2(-40, 40), Vector2(-40, -40),
	])
	add_child(mouth)
	var rim := Line2D.new()
	rim.name = "CaveRim"
	rim.position = mouth.position
	rim.z_index = 1
	rim.width = 6.0
	rim.default_color = Color("a64f2b")
	rim.joint_mode = Line2D.LINE_JOINT_ROUND
	rim.points = PackedVector2Array([
		Vector2(-24, -64), Vector2(24, -64), Vector2(40, -40),
		Vector2(40, 40), Vector2(24, 64), Vector2(-24, 64),
		Vector2(-40, 40), Vector2(-40, -40), Vector2(-24, -64),
	])
	add_child(rim)


func _add_hud():
	add_child(HUD_SCENE.instantiate())


func _add_survival_content():
	if GameState.day < 3:
		return
	add_child(SURVIVAL_HUD_SCENE.instantiate())
	var event_scene = null
	if (GameState.day == 3 and GameState.day2_stage >= 4 and
			not GameState.day3_complete):
		event_scene = DAY3_SCENE.instantiate()
	elif (GameState.day == 4 and GameState.day3_complete and
			not GameState.day4_complete):
		event_scene = DAY4_SCENE.instantiate()
	elif GameState.day >= 5 and GameState.day4_complete and not GameState.day5_complete:
		event_scene = DAY5_SCENE.instantiate()
	if event_scene != null:
		add_child(event_scene)


func _ensure_player_position():
	var room := Rect2(BASE_ORIGIN, Vector2(BASE_COLS * ROOM_TILE, BASE_ROWS * ROOM_TILE))
	if not room.has_point(player.global_position):
		return
	var cell := Vector2i(
		floori((player.global_position.x - BASE_ORIGIN.x) / ROOM_TILE),
		floori((player.global_position.y - BASE_ORIGIN.y) / ROOM_TILE)
	)
	if _base_cell_blocked(cell):
		player.global_position = GameState.base_pos


func _base_cell_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= BASE_COLS or cell.y >= BASE_ROWS:
		return false
	if cell.y == 0 or cell.y == BASE_ROWS - 1 or cell.x == BASE_COLS - 1:
		return true
	if cell.x == 0:
		return cell.y != 7
	if cell.y == 6:
		return cell.x < 4 or cell.x > 7
	return false
