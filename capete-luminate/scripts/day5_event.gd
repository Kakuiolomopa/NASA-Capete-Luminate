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
	await ColonySystems.begin_day(5)

	await Dialogue.talk(_lines([
		"Day five. Final systems check.",
		"Oxygen: %d. Water: %d. Food: %d. Energy: %d." % [
			GameState.oxygen, GameState.water, GameState.food,
			GameState.energy],
	]))
	if not GameState.water_fixed:
		await Dialogue.talk(_lines(["Critical: the water purifier is still unstable."]))
		var choice := await ColonySystems.choose_action([
			"Use emergency energy to stabilize it", "Launch with the warning",
		], [1, 0])
		if choice == 0 and GameState.energy >= 20:
			GameState.change_resource("energy", -20)
			GameState.water_fixed = true
			await Dialogue.talk(_lines(["Emergency power stabilized the purifier." ]))
		else:
			await Dialogue.talk(_lines(["We will launch carefully and ration water on the journey." ]))

	await ColonySystems.run_day_five_events(self)
	await ColonySystems.end_day(self, 5)

	var critical := GameState.oxygen < 20 or GameState.water < 20 or GameState.health < 20
	var strong := GameState.oxygen >= 60 and GameState.water >= 60
	strong = strong and GameState.food >= 60 and GameState.energy >= 60
	strong = strong and GameState.health >= 60 and GameState.water_fixed
	strong = strong and GameState.greenhouse_health >= 50 and GameState.water_efficiency >= 65
	GameState.ship_ready = not critical
	if critical:
		GameState.ending_type = "delayed"
		await Dialogue.talk(_lines([
			"We cannot lift off safely today.",
			"I am sending an emergency signal to Earth. The mission ends here, but we learned a great deal.",
		]))
	elif strong and GameState.confirmation_sent and GameState.logs_found:
		GameState.ending_type = "secret"
		await Dialogue.talk(_lines([
			"All systems are ready. The confirmation reached Earth, and the Aurora records are secure.",
			"Good work, Commander. Earth will know what the previous crew began here.",
		]))
	elif GameState.research_score >= 15:
		GameState.ending_type = "science"
		await Dialogue.talk(_lines([
			"Our research will outlast this base. The colony is fragile, but the science is safe.",
		]))
	elif strong and GameState.sent_signal and GameState.logs_found:
		GameState.ending_type = "secret"
		await Dialogue.talk(_lines([
			"All systems are ready. The Aurora records and the safe-arrival signal are both secure.",
			"Good work, Commander. Earth will know what the previous crew began here.",
		]))
	elif strong and not GameState.confirmation_sent:
		GameState.ending_type = "silent_mars"
		await Dialogue.talk(_lines([
			"The colony is stable, but Earth has no confirmation from us.",
			"We will stay and keep the outpost alive until another mission finds us.",
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
