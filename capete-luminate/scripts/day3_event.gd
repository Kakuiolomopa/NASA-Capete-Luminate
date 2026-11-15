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
		"Day three. Dust storm expected in about eight hours.",
		"We need to choose how to protect our power supply.",
	]))
	var choice := await Dialogue.choose([
		"Clean the solar panels outside", "Stay inside and conserve oxygen"])
	if choice == 0:
		GameState.panels_cleaned = true
		GameState.change_resource("energy", 20)
		GameState.change_resource("oxygen", -10)
		await Dialogue.talk(_lines(["Good choice. The panels will make more power tomorrow."]))
	else:
		GameState.panels_cleaned = false
		GameState.change_resource("energy", -20)
		await Dialogue.talk(_lines(["We are safe inside, but the dust will reduce tomorrow's power."]))
	_save_progress(3)

	await Dialogue.talk(_lines(["Greenhouse temperature dropping. The plants need heat."]))
	choice = await Dialogue.choose(["Turn on extra heating", "Use minimal heating"])
	if choice == 0:
		GameState.greenhouse_heated = true
		GameState.change_resource("energy", -15)
		await Dialogue.talk(_lines([
			"The plants are warm and healthy. That costs energy, but food is important."]))
	else:
		GameState.greenhouse_heated = false
		await Dialogue.talk(_lines(["The plants can survive, but they will grow more slowly."]))
	_save_progress(3)

	await Dialogue.talk(_lines(["Sensors detect a small anomaly under the ice."]))
	choice = await Dialogue.choose(["Investigate with the rover", "Ignore it for now"])
	if choice == 0:
		GameState.research_done = true
		GameState.research_score += 10
		GameState.change_resource("energy", -10)
		await Dialogue.talk(_lines([
			"The rover found useful data. I have saved it for the mission report."]))
	else:
		GameState.research_done = false
		await Dialogue.talk(_lines(["We will focus on survival and leave the anomaly for later."]))
	_save_progress(3)

	await Dialogue.talk(_lines([
		"The communications array is ready. Should we send a safe-arrival signal to Earth?"]))
	choice = await Dialogue.choose(["Send the signal", "Skip the signal"])
	GameState.sent_signal = choice == 0
	if GameState.sent_signal:
		GameState.change_resource("energy", -5)
		await Dialogue.talk(_lines(["Signal sent. Someone on Earth will know we arrived safely."]))
	else:
		await Dialogue.talk(_lines(["Understood. We will save the power for the habitat."]))
	_save_progress(3)

	GameState.day3_complete = true
	_save_progress(3)
	await Dialogue.talk(_lines([
		"Day three is complete. Tomorrow we will check the habitat and water systems."]))
	GameState.day = 4
	_save_progress(4)
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
