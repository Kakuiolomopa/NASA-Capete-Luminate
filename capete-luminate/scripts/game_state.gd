extends Node

const MAX_HOURS := 8

var player_name := "AGENT"
var quests := {}
var items := {}
var story_step := 0
var base_pos := Vector2.ZERO
var outside_pos := Vector2.ZERO

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

var energy := 100
var oxygen := 100
var water := 100
var food := 100
var health := 100
var research_score := 0
var day3_complete := false
var day4_complete := false
var day5_complete := false
var panels_cleaned := false
var greenhouse_heated := false
var research_done := false
var sent_signal := false
var leak_repaired := false
var full_leak_repair := false
var logs_found := false
var radiation_exposure := 0
var water_fixed := false
var greenhouse_on := true
var lab_on := true
var heating_on := true
var ship_ready := false
var ending_type := ""

var water_efficiency := 80
var greenhouse_health := 100
var greenhouse_neglect := 0
var greenhouse_fed_today := false
var solar_efficiency := 1.0
var panels_dirty := false
var total_oxygen_lost := 0
var leak_active := false
var antenna_charged := false
var confirmation_sent := false
var ice_samples := false
var antenna_hint := false
var flags := {}
var colony_day_settled := 0
var hours_left := MAX_HOURS


func change_resource(resource: String, amount: int):
	var before := int(get(resource))
	set(resource, clampi(int(get(resource)), 0, 100) + amount)
	set(resource, clampi(int(get(resource)), 0, 100))
	if resource == "oxygen" and int(get(resource)) < before:
		total_oxygen_lost += before - int(get(resource))


func done_count() -> int:
	var n := 0
	for id in quests:
		if quests[id] == "done":
			n += 1
	return n


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
