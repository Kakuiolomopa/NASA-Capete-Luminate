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

	await Dialogue.talk(_lines([
		"Day five. Final systems check.",
		"Oxygen: %d. Water: %d. Food: %d. Energy: %d. Health: %d." % [
			GameState.oxygen, GameState.water, GameState.food,
			GameState.energy, GameState.health],
	]))
	if not GameState.water_fixed:
		await Dialogue.talk(_lines(["Critical: the water purifier is still unstable."]))
		var choice := await Dialogue.choose([
			"Use emergency energy to stabilize it", "Launch with the warning"])
		if choice == 0 and GameState.energy >= 20:
			GameState.change_resource("energy", -20)
			GameState.water_fixed = true
			await Dialogue.talk(_lines(["Emergency power stabilized the purifier." ]))
		else:
			await Dialogue.talk(_lines(["We will launch carefully and ration water on the journey." ]))

	var critical := GameState.oxygen < 20 or GameState.water < 20 or GameState.health < 20
	var strong := GameState.oxygen >= 60 and GameState.water >= 60
	strong = strong and GameState.food >= 60 and GameState.energy >= 60
	strong = strong and GameState.health >= 60 and GameState.water_fixed
	GameState.ship_ready = not critical
	if critical:
		GameState.ending_type = "delayed"
		await Dialogue.talk(_lines([
			"We cannot lift off safely today.",
			"I am sending an emergency signal to Earth. The mission ends here, but we learned a great deal.",
		]))
	elif strong and GameState.sent_signal and GameState.logs_found:
		GameState.ending_type = "secret"
		await Dialogue.talk(_lines([
			"All systems are ready. The Aurora records and the safe-arrival signal are both secure.",
			"Good work, Commander. Earth will know what the previous crew began here.",
		]))
	elif strong:
		GameState.ending_type = "success"
		await Dialogue.talk(_lines(["All systems are ready. Good work, Commander. Safe journey home."]))
	else:
		GameState.ending_type = "emergency"
		await Dialogue.talk(_lines([
			"We have enough to launch, but some systems are weak.",
			"We are leaving safely, but the next mission will need to finish what we started.",
		]))

	await Dialogue.talk(_lines(["Initiating final launch sequence."]))
	await Dialogue.talk(_lines(["5... 4... 3... 2... 1..."]))
	GameState.day5_complete = true
	_save_progress(5)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _lines(texts: Array) -> Array:
	var lines := []
	for text in texts:
		lines.append({"who": SPEAKER, "text": text})
	return lines


func _save_progress(day: int):
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint(day)
