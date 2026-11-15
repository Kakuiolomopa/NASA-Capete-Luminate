extends Node

var player_name := "AGENT"
var quests := {}
var items := {}
var story_step := 0
var base_pos := Vector2.ZERO
var outside_pos := Vector2.ZERO

var hydro := {}
var hydro_intro_seen := false
var hydro_crop_hint := false
var hydro_nutrient_hint := false

var day := 0
var first_night_done := false
var first_night_choice := -1
var bed_prompted := false
var solar_intro_seen := false
var solar_cleaned := {}
var moxie_broken := false
var moxie_repair_step := 0

var day1_stage := 0
var control_panel_booted := false
var start_marker_seen := false
var solar_task_done := false

var day2_stage := 0
var drill_repaired := false
var water_tank_repaired := false


func done_count() -> int:
	var n := 0
	for id in quests:
		if quests[id] == "done":
			n += 1
	return n


func hydro_station_ready(station_id: String) -> bool:
	var shelves = hydro.get(station_id)
	if not (shelves is Array):
		return false
	for shelf in shelves:
		if not (shelf is Dictionary):
			continue
		var crop := str(shelf.get("crop", "none"))
		var fed := bool(shelf.get("nutrient", false))
		if crop != "none" and fed:
			return true
	return false


func all_hydro_ready() -> bool:
	for id in ["hydro_1", "hydro_2", "hydro_3"]:
		if not hydro_station_ready(id):
			return false
	return true


func moxie_progress() -> int:
	return moxie_repair_step if moxie_broken else story_step


func solar_cleaned_count() -> int:
	var n := 0
	for id in solar_cleaned:
		if bool(solar_cleaned[id]):
			n += 1
	return n


func solar_panel_count() -> int:
	return get_tree().get_nodes_in_group("solar_panels").size()


func set_day1_stage(value: int):
	day1_stage = maxi(day1_stage, value)
	if day1_stage >= 1:
		control_panel_booted = true
