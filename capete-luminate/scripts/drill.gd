extends StaticBody2D

const SPEAKER := "D.A.I.S.Y"
const PLAYER_PORTRAIT := preload("res://assets/portraits/egg.jpg")

const LOCKED_LINES := [
	{"text": "The drill can wait. We need to finish the hydroponics setup first."},
]
const REPAIR_LINES := [
	{"text": "The drill is outside by the survey markers. It needs to be brought back online."},
	{"text": "There. It is reading the Martian ground again. I am detecting a " +
		"water-bearing layer below the habitat."},
	{"text": "Next, repair the water tank inside the base so we can store what the drill finds."},
]

var _busy := false


func interact(player = null):
	if _busy or GameState.drill_repaired:
		return
	_busy = true
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()
	if GameState.day2_stage < 1:
		await Dialogue.talk(_build(LOCKED_LINES))
	else:
		await Dialogue.talk(_build(REPAIR_LINES))
		GameState.drill_repaired = true
		GameState.day2_stage = 2
		_save_progress()
	_release(player)


func _build(lines: Array) -> Array:
	var out := []
	for line in lines:
		out.append({
			"who": SPEAKER,
			"text": str(line["text"]).replace("{name}", GameState.player_name),
		})
	return out


func _save_progress():
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint(GameState.day)


func _release(player):
	if player:
		player.controls_enabled = true
	_busy = false
