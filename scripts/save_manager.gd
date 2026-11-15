extends Node

const SLOTS := 3
const SAVE_DIR := "user://saves/"
const GAME_SCENE := "res://scenes/main.tscn"

var current_slot := -1          
var pending_data := {}          
var play_time := 0.0            
var counting := false           


func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _process(delta):
	if counting:
		play_time += delta


func _path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))


func get_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var data := _read(slot)
	return {
		"date": data.get("date", ""),
		"play_time": data.get("play_time", 0.0),
		"quests_done": data.get("quests_done", 0),
	}


func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func save_game(slot: int) -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false

	var data := {
		"version": 1,
		"date": Time.get_datetime_string_from_system(false, true),
		"play_time": play_time,
		"quests_done": GameState.done_count(),
		"quests": GameState.quests,
		"items": GameState.items,
		"intro_done": true,
		"player": {
			"x": player.global_position.x,
			"y": player.global_position.y,
		},
	}
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	current_slot = slot
	return true


func _read(slot: int) -> Dictionary:
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}

func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false
	pending_data = _read(slot)
	if pending_data.is_empty():
		return false
	current_slot = slot
	play_time = pending_data.get("play_time", 0.0)
	GameState.quests = pending_data.get("quests", {})
	GameState.items = pending_data.get("items", {})
	counting = true
	get_tree().change_scene_to_file(GAME_SCENE)
	return true


func new_game(slot := -1):
	pending_data = {}
	current_slot = slot
	play_time = 0.0
	GameState.quests = {}
	GameState.items = {}
	counting = true
	get_tree().change_scene_to_file(GAME_SCENE)


func apply_pending(player) -> bool:
	if pending_data.is_empty():
		return false
	var p: Dictionary = pending_data.get("player", {})
	player.global_position = Vector2(p.get("x", 0.0), p.get("y", 0.0))
	pending_data = {}
	return true


func delete_save(slot: int):
	if has_save(slot):
		DirAccess.remove_absolute(_path(slot))


func stop_counting():
	counting = false
