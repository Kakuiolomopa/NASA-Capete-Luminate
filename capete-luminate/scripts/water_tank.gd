extends StaticBody2D

const SPEAKER := "D.A.I.S.Y"

const LOCKED_LINES := [
	{"text": "The water tank is not the next step yet. Follow the objective order."},
]
const REPAIR_LINES := [
	{"text": "This chamber is not a water tank, but it can hold the system " +
		"together until we replace the proper unit."},
	{"text": "Placeholder or not, the storage line is stable again. We can start " +
		"working with the water the drill finds."},
]

var _busy := false


func interact(player = null):
	if _busy or GameState.water_tank_repaired:
		return
	_busy = true
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()
	if GameState.day2_stage < 2:
		await Dialogue.talk(_build(LOCKED_LINES))
	else:
		await Dialogue.talk(_build(REPAIR_LINES))
		GameState.water_tank_repaired = true
		GameState.day2_stage = 3
		_save_progress()
	_release(player)


func _build(lines: Array) -> Array:
	var out := []
	for line in lines:
		out.append({"who": SPEAKER, "text": line["text"]})
	return out


func _save_progress():
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint(GameState.day)


func _release(player):
	if player:
		player.controls_enabled = true
	_busy = false
