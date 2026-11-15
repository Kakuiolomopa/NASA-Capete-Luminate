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

	await Dialogue.talk(_lines(["Urgent: pressure is dropping in the habitat. We have a leak."]))
	var choice := await Dialogue.choose(["Quick patch", "Full repair"])
	GameState.leak_repaired = true
	GameState.full_leak_repair = choice == 1
	if choice == 0:
		GameState.change_resource("oxygen", -15)
		GameState.change_resource("energy", -10)
		await Dialogue.talk(_lines([
			"The quick patch is holding. We used less energy, but we should inspect it later."]))
	else:
		GameState.change_resource("oxygen", -25)
		GameState.change_resource("energy", -20)
		await Dialogue.talk(_lines(["The leak is fully sealed. The habitat is safe again."]))
	_save_progress(4)

	GameState.logs_found = true
	await Dialogue.talk(_lines([
		"Behind the damaged panel is an old crew log.",
		"The previous crew kept working until the end. Their records mention an outpost called Aurora.",
	]))

	await Dialogue.talk(_lines([
		"Warning! Solar radiation is rising. Taking shelter is recommended."]))
	choice = await Dialogue.choose(["Shelter in the bunker", "Continue working"])
	if choice == 0:
		await Dialogue.talk(_lines(["Good. The shelter protected you from the radiation."]))
	else:
		GameState.radiation_exposure += 20
		GameState.change_resource("health", -10)
		await Dialogue.talk(_lines([
			"We finished the task, but the radiation exposure was not harmless."]))
	_save_progress(4)

	await Dialogue.talk(_lines(["Alert! The water extraction system has malfunctioned.",
		"Messages to Earth take about fourteen minutes. We can wait or act."]))
	choice = await Dialogue.choose(["Repair it now", "Wait and ration water"])
	if choice == 0:
		GameState.water_fixed = true
		GameState.change_resource("energy", -15)
		await Dialogue.talk(_lines(["The water system is working again." ]))
	else:
		GameState.water_fixed = false
		GameState.change_resource("water", -15)
		await Dialogue.talk(_lines([
			"We waited for help and rationed our water. The system is still weak."]))
	_save_progress(4)

	await Dialogue.talk(_lines([
		"Battery at about thirty percent. We can keep only two systems running tonight."]))
	choice = await Dialogue.choose(["Turn off greenhouse", "Turn off lab", "Turn off heating"])
	GameState.greenhouse_on = choice != 0
	GameState.lab_on = choice != 1
	GameState.heating_on = choice != 2
	if choice == 0:
		GameState.change_resource("food", -5)
	elif choice == 1:
		GameState.research_score = maxi(0, GameState.research_score - 5)
	else:
		GameState.change_resource("health", -5)
	_save_progress(4)

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
