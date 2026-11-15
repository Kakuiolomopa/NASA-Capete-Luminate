extends CanvasLayer

const SPEAKER := "D.A.I.S.Y"
var _running := false


func _ready():
	layer = 25
	await get_tree().process_frame
	_run()


func _run():
	if _running:
		return
	_running = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()
	await ColonySystems.begin_day(4)

	await Dialogue.talk(_lines(["Urgent: pressure is dropping in the habitat. We have a leak."]))
	var choice := await ColonySystems.choose_action([
		"Quick patch",
		"Full diagnosis and repair",
		"Ignore it for now",
	], [2, 3, 0])
	GameState.leak_repaired = choice != 2
	GameState.full_leak_repair = choice == 1
	if choice == 0:
		GameState.change_resource("oxygen", -15)
		GameState.change_resource("energy", -10)
		await Dialogue.talk(_lines([
			"The quick patch is holding. We used less energy, but we should inspect it later."]))
	elif choice == 1:
		GameState.change_resource("oxygen", -25)
		GameState.change_resource("energy", -20)
		await Dialogue.talk(_lines(["The leak is fully sealed. The habitat is safe again."]))
	else:
		await Dialogue.talk(_lines(["The leak is still venting oxygen. We will have to watch the reserves."]))
	await ColonySystems.handle_leak(self, choice)
	_save_progress(4)

	GameState.logs_found = true
	if ColonySystems.consume_hours(1):
		await Dialogue.talk(_lines([
			"Behind the damaged panel is an old crew log.",
			"The previous crew kept working until the end. Their records mention an outpost called Aurora.",
		]))
		ColonySystems.record_crew_log(true)
	else:
		GameState.logs_found = false
		await Dialogue.talk(_lines([
			"There is an old crew log behind the panel, but there is no time to read it today.",
		]))

	await Dialogue.talk(_lines([
		"Warning! Solar radiation is rising. Taking shelter is recommended."]))
	choice = await ColonySystems.choose_action([
		"Shelter in the bunker",
		"Continue working through the storm",
		"Reallocate power between shelter, lab and greenhouse",
	], [1, 0, 1])
	if choice == 0:
		await Dialogue.talk(_lines(["Good. The shelter protected you from the radiation."]))
	elif choice == 1:
		GameState.radiation_exposure += 20
		GameState.change_resource("health", -10)
		await Dialogue.talk(_lines([
			"We finished the task, but the radiation exposure was not harmless."]))
	await ColonySystems.handle_radiation(self, choice)
	_save_progress(4)

	await Dialogue.talk(_lines(["Alert! The water extraction system has malfunctioned.",
		"Messages to Earth take about fourteen minutes. We can wait or act."]))
	choice = await ColonySystems.choose_action([
		"Repair it now", "Wait and ration water",
	], [2, 0])
	if choice == 0:
		GameState.water_fixed = true
		GameState.change_resource("energy", -15)
		await Dialogue.talk(_lines(["The water system is working again." ]))
	else:
		GameState.water_fixed = false
		GameState.change_resource("water", -15)
		await Dialogue.talk(_lines([
			"We waited for help and rationed our water. The system is still weak."]))
	await ColonySystems.repair_day_four_water(self, choice)
	_save_progress(4)

	await Dialogue.talk(_lines([
		"Battery at about thirty percent. We can keep only two systems running tonight."]))
	choice = await ColonySystems.choose_action([
		"Turn off greenhouse", "Turn off lab", "Turn off heating",
	], [0, 0, 0])
	GameState.greenhouse_on = choice != 0
	GameState.lab_on = choice != 1
	GameState.heating_on = choice != 2
	if choice == 0:
		GameState.change_resource("food", -5)
	elif choice == 1:
		GameState.research_score = maxi(0, GameState.research_score - 5)
	else:
		GameState.change_resource("health", -5)
	await ColonySystems.handle_day_four_power(self)
	_save_progress(4)

	await ColonySystems.end_day(self, 4)
	GameState.day4_complete = true
	_save_progress(4)
	await Dialogue.talk(_lines(["Tomorrow is departure day. Prepare for the final check." ]))
	GameState.day = 5
	_save_progress(5)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _lines(texts: Array) -> Array:
	var lines := []
	for text in texts:
		lines.append({"who": SPEAKER, "text": text})
	return lines


func _save_progress(day: int):
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint(day)
