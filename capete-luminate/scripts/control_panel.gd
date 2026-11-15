extends StaticBody2D

const PLAYER_PORTRAIT := preload("res://assets/portraits/egg.jpg")
const DAISY_PORTRAIT := preload("res://assets/portraits/Daisy.png")
const PANEL := "CONTROL PANEL"
const SPEAKER := "D.A.I.S.Y"

const CHOICES := [
	"Did something hack the base?",
	"Hey! I'm here on a mission, who are you?",
	"Why does the control panel have sass...",
]

const HACK_REPLY := "Hey! I've been made for this base, thank you very much."
const NORMAL_REPLY := "Good. A straightforward answer. I can work with that."
const SASS_REPLY := "I am a very complex AI, you probably can't even imagine what I can do. >:("

const INTRO := [
	"I'm your very own Dynamic Autonomous Intelligence for Space & You, " +
	"or for short D.A.I.S.Y.! So you're here on a mission, huh?",
]

const STATUS_LINES := [
	"The base! Right, the base! Why didn't I think of that.",
	"Yes... yes... The base... let's see~! It's in almost ruin.",
]

const TASK_LINES := [
	"I need a while more to reach the entire facility, but for now you can " +
	"go clean the solar array outside. See you!",
]

const DONE_BOOT := [
	"Clean the solar array",
]

var _busy := false
var _time := 0.0
var _face_origin := Vector2.ZERO

@onready var _face: Sprite2D = $DaisyFace


func _ready():
	_face_origin = _face.position


func _process(delta):
	_time += delta
	if _face:
		_face.position.y = _face_origin.y + sin(_time * 2.2) * 2.0
		_face.modulate.a = 0.82 + sin(_time * 3.1) * 0.08


func interact(player = null):
	if _busy:
		return
	_busy = true
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()

	if not GameState.control_panel_booted:
		await _boot()
	else:
		await Dialogue.talk(_status_lines())

	if player:
		player.controls_enabled = true
	_busy = false


func _boot():
	await Dialogue.talk([
		_panel("Hey! You're ba-"),
		_panel("You're not part of the crew. Who are you?!"),
	])
	var choice: int = await Dialogue.choose(CHOICES)
	match choice:
		0:
			await Dialogue.talk([_panel(HACK_REPLY)])
		1:
			await Dialogue.talk([_panel(NORMAL_REPLY)])
		2:
			await Dialogue.talk([_panel(SASS_REPLY)])
	await Dialogue.talk(_build(INTRO))
	await Dialogue.talk([
		_player("Yes, I need you to tell me what the status of the base is."),
	])
	await Dialogue.talk(_build(STATUS_LINES))
	await Dialogue.talk([
		_player("..."),
		_player("Alright... It was to be expected. Why don't you tell me " +
			"what needs fixing so I can get to work?"),
	])
	await Dialogue.talk(_build(TASK_LINES))
	await Dialogue.talk([{"who": "TASK", "text": DONE_BOOT[0]}])

	GameState.control_panel_booted = true
	GameState.set_day1_stage(1)
	GameState.start_marker_seen = true
	get_tree().call_group("start_marker", "dismiss")
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint()


func _status_lines() -> Array:
	var lines := []
	if GameState.moxie_broken:
		lines.append(_d("I'm reading a fault in the MOXIE. You'll need to repair it again."))
	match GameState.day1_stage:
		0:
			lines.append(_d("The control room is this way. Let's get me booted up."))
		1:
			var total := maxi(1, GameState.solar_panel_count())
			lines.append(_d("The solar array outside is still coated in dust. %d/%d panels are clean." % [
				GameState.solar_cleaned_count(), total]))
		2:
			lines.append(_d("The array is holding steady. Next is the MOXIE, in the north-east corner."))
		3:
			lines.append(_d("The MOXIE is stable. That's everything for today, " +
				"{name}. Your bed is in the south-west room."))
		_:
			lines.append(_d("We made it through the night. The base is still " +
				"standing. Take a moment before we plan the next step."))
	return _build(lines)


func _build(src: Array) -> Array:
	var out := []
	for line in src:
		if line is String:
			out.append(_d(line))
			continue
		out.append(line)
	return out


func _panel(text: String) -> Dictionary:
	return {"who": PANEL, "text": text, "portrait": DAISY_PORTRAIT}


func _d(text: String) -> Dictionary:
	return {
		"who": SPEAKER,
		"text": str(text).replace("{name}", GameState.player_name),
		"portrait": DAISY_PORTRAIT,
	}


func _player(text: String) -> Dictionary:
	return {"who": GameState.player_name, "text": text, "portrait": PLAYER_PORTRAIT}
