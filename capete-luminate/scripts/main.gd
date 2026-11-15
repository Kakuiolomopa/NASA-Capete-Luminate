extends Node2D

const BASE_ORIGIN := Vector2(4832, 3008)
const BASE_COLS := 22
const BASE_ROWS := 14
const TILE := 32
const FLOOR_TEXTURE_PATH := "res://assets/BaseFloor.png"
const WALL_TEXTURE_PATH := "res://assets/BaseWall.png"
const HUD_SCENE := preload("res://scenes/objective_hud.tscn")

var _base_layer: TileMapLayer
var _base_body: StaticBody2D

@onready var player = $Player
@onready var layer: TileMapLayer = $TileMapLayer


func _ready():
	_clear_old_base()
	_paint_mars_apron()
	_build_base_room()
	_add_cave_entrance()
	_add_hud()
	SaveManager.apply_pending(player)
	_ensure_player_position()
	if SaveManager.autosave_on_start:
		SaveManager.autosave_on_start = false
		if SaveManager.current_slot >= 0:
			SaveManager.save_game(SaveManager.current_slot)
			SaveManager.save_checkpoint()


func _clear_old_base():
	var room_rect := Rect2i(
		floori(BASE_ORIGIN.x / 16.0), floori(BASE_ORIGIN.y / 16.0),
		BASE_COLS * 2, BASE_ROWS * 2)
	var clear_rect := room_rect.grow(6)
	for y in range(clear_rect.position.y, clear_rect.end.y):
		for x in range(clear_rect.position.x, clear_rect.end.x):
			layer.erase_cell(Vector2i(x, y))


func _paint_mars_apron():
	var room_rect := Rect2i(
		floori(BASE_ORIGIN.x / 16.0), floori(BASE_ORIGIN.y / 16.0),
		BASE_COLS * 2, BASE_ROWS * 2)
	var apron := room_rect.grow(6)
	for y in range(apron.position.y, apron.end.y):
		for x in range(apron.position.x, apron.end.x):
			var atlas := Vector2i((x + y) & 1, (x * 3 + y) & 1)
			layer.set_cell(Vector2i(x, y), 0, atlas)
	for y in range(room_rect.position.y, room_rect.end.y):
		for x in range(room_rect.position.x, room_rect.end.x):
			layer.erase_cell(Vector2i(x, y))


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
	floor_source.create_tile(Vector2i.ZERO)
	tileset.add_source(floor_source, 0)
	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = load(WALL_TEXTURE_PATH)
	wall_source.texture_region_size = Vector2i(TILE, TILE)
	wall_source.create_tile(Vector2i.ZERO)
	tileset.add_source(wall_source, 1)
	return tileset


func _paint_room():
	for y in range(1, BASE_ROWS - 1):
		for x in range(1, BASE_COLS - 1):
			_set_base_tile(x, y, 0)
	for x in range(0, BASE_COLS):
		_set_base_tile(x, 0, 1)
		_set_base_tile(x, BASE_ROWS - 1, 1)
	for y in range(0, BASE_ROWS):
		if y != 7:
			_set_base_tile(0, y, 1)
		_set_base_tile(BASE_COLS - 1, y, 1)
	_set_base_tile(0, 7, 0)
	for x in range(1, BASE_COLS - 1):
		if x < 5 or x > 8:
			_set_base_tile(x, 7, 1)


func _set_base_tile(x: int, y: int, source_id: int):
	_base_layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)


func _add_base_collision():
	_base_body = StaticBody2D.new()
	_base_body.name = "BaseWalls"
	_base_body.position = BASE_ORIGIN
	add_child(_base_body)
	_add_wall(Vector2(352, 16), Vector2(704, 32))
	_add_wall(Vector2(352, 432), Vector2(704, 32))
	_add_wall(Vector2(16, 112), Vector2(32, 192))
	_add_wall(Vector2(16, 352), Vector2(32, 160))
	_add_wall(Vector2(688, 224), Vector2(32, 448))
	_add_wall(Vector2(112, 240), Vector2(160, 32))
	_add_wall(Vector2(480, 240), Vector2(384, 32))


func _add_wall(center: Vector2, size: Vector2):
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.position = center
	collision.shape = shape
	_base_body.add_child(collision)


func _add_cave_entrance():
	var mouth := Polygon2D.new()
	mouth.name = "CaveMouth"
	mouth.position = Vector2(4848, 3248)
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


func _ensure_player_position():
	var room := Rect2(BASE_ORIGIN, Vector2(BASE_COLS * TILE, BASE_ROWS * TILE))
	if not room.has_point(player.global_position):
		return
	var cell := Vector2i(
		floori((player.global_position.x - BASE_ORIGIN.x) / TILE),
		floori((player.global_position.y - BASE_ORIGIN.y) / TILE)
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
	if cell.y == 7:
		return cell.x < 5 or cell.x > 8
	return false
