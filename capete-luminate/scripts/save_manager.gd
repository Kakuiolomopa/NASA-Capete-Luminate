extends Node

const INTRO_SCENE := "res://scenes/intro.tscn"
const SLOTS := 3
const SAVE_DIR := "user://saves/"
const CHECKPOINT_DIR := "user://checkpoints/"
const GAME_SCENE := "res://scenes/main.tscn"
const NAME_SCENE := "res://scenes/name_picker.tscn"

var current_slot := -1
var pending_data := {}
var play_time := 0.0
var counting := false
var autosave_on_start := false


func _ready():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHECKPOINT_DIR))


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


func _build_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return {}
	return {
		"version": 3,
		"date": Time.get_datetime_string_from_system(false, true),
		"play_time": play_time,
		"quests_done": GameState.done_count(),
		"quests": GameState.quests,
		"items": GameState.items,
		"story_step": GameState.story_step,
		"hydro": GameState.hydro,
		"hydro_intro_seen": GameState.hydro_intro_seen,
		"hydro_crop_hint": GameState.hydro_crop_hint,
		"hydro_nutrient_hint": GameState.hydro_nutrient_hint,
		"day": GameState.day,
		"first_night_done": GameState.first_night_done,
		"first_night_choice": GameState.first_night_choice,
		"bed_prompted": GameState.bed_prompted,
		"solar_intro_seen": GameState.solar_intro_seen,
		"solar_cleaned": GameState.solar_cleaned,
		"moxie_broken": GameState.moxie_broken,
		"moxie_repair_step": GameState.moxie_repair_step,
		"day1_stage": GameState.day1_stage,
		"control_panel_booted": GameState.control_panel_booted,
		"start_marker_seen": GameState.start_marker_seen,
		"solar_task_done": GameState.solar_task_done,
		"day2_stage": GameState.day2_stage,
		"drill_repaired": GameState.drill_repaired,
		"water_tank_repaired": GameState.water_tank_repaired,
		"energy": GameState.energy,
		"oxygen": GameState.oxygen,
		"water": GameState.water,
		"food": GameState.food,
		"health": GameState.health,
		"research_score": GameState.research_score,
		"day3_complete": GameState.day3_complete,
		"day4_complete": GameState.day4_complete,
		"day5_complete": GameState.day5_complete,
		"panels_cleaned": GameState.panels_cleaned,
		"greenhouse_heated": GameState.greenhouse_heated,
		"research_done": GameState.research_done,
		"sent_signal": GameState.sent_signal,
		"leak_repaired": GameState.leak_repaired,
		"full_leak_repair": GameState.full_leak_repair,
		"logs_found": GameState.logs_found,
		"radiation_exposure": GameState.radiation_exposure,
		"water_fixed": GameState.water_fixed,
		"greenhouse_on": GameState.greenhouse_on,
		"lab_on": GameState.lab_on,
		"heating_on": GameState.heating_on,
		"ship_ready": GameState.ship_ready,
		"ending_type": GameState.ending_type,
		"intro_done": true,
		"player": {
			"x": player.global_position.x,
			"y": player.global_position.y,
		},
		"player_name": GameState.player_name,
	}


func save_game(slot: int) -> bool:
	var data := _build_data()
	if data.is_empty():
		return false
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	current_slot = slot
	return true


func save_checkpoint(day := -1) -> bool:
	if day < 0:
		day = GameState.day
	var data := _build_data()
	if data.is_empty():
		return false
	data["checkpoint"] = true
	data["checkpoint_day"] = day
	var f := FileAccess.open(CHECKPOINT_DIR + "day_%02d.json" % day, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func first_empty_slot() -> int:
	for i in SLOTS:
		if not has_save(i):
			return i
	return -1


func oldest_slot() -> int:
	var oldest := -1
	var oldest_time := 9223372036854775807
	for i in SLOTS:
		if not has_save(i):
			continue
		var stamp := FileAccess.get_modified_time(_path(i))
		if stamp < oldest_time:
			oldest_time = stamp
			oldest = i
	return oldest


func select_new_game_slot() -> int:
	var empty := first_empty_slot()
	if empty >= 0:
		return empty
	return oldest_slot()


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
	GameState.story_step = int(pending_data.get("story_step", 0))
	if GameState.story_step == 0 and bool(pending_data.get("moxie_interacted", false)):
		GameState.story_step = 3
	GameState.hydro = pending_data.get("hydro", {})
	GameState.hydro_intro_seen = bool(pending_data.get("hydro_intro_seen", false))
	GameState.hydro_crop_hint = bool(pending_data.get("hydro_crop_hint", false))
	GameState.hydro_nutrient_hint = bool(pending_data.get("hydro_nutrient_hint", false))
	GameState.day = maxi(1, int(pending_data.get("day", 1)))
	GameState.first_night_done = bool(pending_data.get("first_night_done", false))
	GameState.first_night_choice = int(pending_data.get("first_night_choice", -1))
	GameState.bed_prompted = bool(pending_data.get("bed_prompted", false))
	GameState.solar_intro_seen = bool(pending_data.get("solar_intro_seen", false))
	var cleaned = pending_data.get("solar_cleaned", {})
	GameState.solar_cleaned = cleaned if cleaned is Dictionary else {}
	GameState.moxie_broken = bool(pending_data.get("moxie_broken", false))
	GameState.moxie_repair_step = int(pending_data.get("moxie_repair_step", 0))
	if pending_data.has("day1_stage"):
		GameState.day1_stage = int(pending_data.get("day1_stage", 0))
	else:
		GameState.day1_stage = _legacy_day1_stage(pending_data)
	GameState.control_panel_booted = bool(pending_data.get(
		"control_panel_booted", GameState.day1_stage > 0))
	GameState.start_marker_seen = bool(pending_data.get("start_marker_seen", true))
	GameState.solar_task_done = bool(pending_data.get(
		"solar_task_done", GameState.day1_stage >= 2))
	GameState.day2_stage = int(pending_data.get("day2_stage", 0))
	GameState.drill_repaired = bool(pending_data.get("drill_repaired", false))
	GameState.water_tank_repaired = bool(
		pending_data.get("water_tank_repaired", false))
	GameState.energy = int(pending_data.get("energy", 100))
	GameState.oxygen = int(pending_data.get("oxygen", 100))
	GameState.water = int(pending_data.get("water", 100))
	GameState.food = int(pending_data.get("food", 100))
	GameState.health = int(pending_data.get("health", 100))
	GameState.research_score = int(pending_data.get("research_score", 0))
	GameState.day3_complete = bool(pending_data.get("day3_complete", false))
	GameState.day4_complete = bool(pending_data.get("day4_complete", false))
	GameState.day5_complete = bool(pending_data.get("day5_complete", false))
	GameState.panels_cleaned = bool(pending_data.get("panels_cleaned", false))
	GameState.greenhouse_heated = bool(
		pending_data.get("greenhouse_heated", false))
	GameState.research_done = bool(pending_data.get("research_done", false))
	GameState.sent_signal = bool(pending_data.get("sent_signal", false))
	GameState.leak_repaired = bool(pending_data.get("leak_repaired", false))
	GameState.full_leak_repair = bool(
		pending_data.get("full_leak_repair", false))
	GameState.logs_found = bool(pending_data.get("logs_found", false))
	GameState.radiation_exposure = int(
		pending_data.get("radiation_exposure", 0))
	GameState.water_fixed = bool(pending_data.get("water_fixed", false))
	GameState.greenhouse_on = bool(pending_data.get("greenhouse_on", true))
	GameState.lab_on = bool(pending_data.get("lab_on", true))
	GameState.heating_on = bool(pending_data.get("heating_on", true))
	GameState.ship_ready = bool(pending_data.get("ship_ready", false))
	GameState.ending_type = str(pending_data.get("ending_type", ""))
	GameState.player_name = pending_data.get("player_name", "AGENT")
	autosave_on_start = false
	counting = true
	get_tree().change_scene_to_file(GAME_SCENE)
	return true


func _legacy_day1_stage(data: Dictionary) -> int:
	if bool(data.get("first_night_done", false)):
		return 4
	var cleaned = data.get("solar_cleaned", {})
	var cleaned_count := 0
	if cleaned is Dictionary:
		for id in cleaned:
			if bool(cleaned[id]):
				cleaned_count += 1
	var story := int(data.get("story_step", 0))
	if cleaned_count >= 10:
		return 3 if story >= 3 else 2
	if bool(data.get("control_panel_booted", false)) or story > 0 or cleaned_count > 0:
		return 1
	return 0


func new_game(slot := -1):
	pending_data = {}
	if slot < 0:
		slot = select_new_game_slot()
	current_slot = slot
	play_time = 0.0
	GameState.quests = {}
	GameState.items = {}
	GameState.story_step = 0
	GameState.hydro = {}
	GameState.hydro_intro_seen = false
	GameState.hydro_crop_hint = false
	GameState.hydro_nutrient_hint = false
	GameState.day = 1
	GameState.first_night_done = false
	GameState.first_night_choice = -1
	GameState.bed_prompted = false
	GameState.solar_intro_seen = false
	GameState.solar_cleaned = {}
	GameState.moxie_broken = false
	GameState.moxie_repair_step = 0
	GameState.day1_stage = 0
	GameState.control_panel_booted = false
	GameState.start_marker_seen = false
	GameState.solar_task_done = false
	GameState.day2_stage = 0
	GameState.drill_repaired = false
	GameState.water_tank_repaired = false
	GameState.energy = 100
	GameState.oxygen = 100
	GameState.water = 100
	GameState.food = 100
	GameState.health = 100
	GameState.research_score = 0
	GameState.day3_complete = false
	GameState.day4_complete = false
	GameState.day5_complete = false
	GameState.panels_cleaned = false
	GameState.greenhouse_heated = false
	GameState.research_done = false
	GameState.sent_signal = false
	GameState.leak_repaired = false
	GameState.full_leak_repair = false
	GameState.logs_found = false
	GameState.radiation_exposure = 0
	GameState.water_fixed = false
	GameState.greenhouse_on = true
	GameState.lab_on = true
	GameState.heating_on = true
	GameState.ship_ready = false
	GameState.ending_type = ""
	autosave_on_start = true
	counting = true
	get_tree().change_scene_to_file(NAME_SCENE)


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
