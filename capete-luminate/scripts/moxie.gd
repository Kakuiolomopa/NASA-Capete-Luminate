extends StaticBody2D

const OVERLAY := preload("res://scenes/MOXIE-interaction.tscn")
const SOLVED_STEP := 3
const SPEAKER := "D.A.I.S.Y"
const PLAYER_PORTRAIT := preload("res://assets/portraits/portraitas.png")

const LOCKED_LINES := [
	{"text": "The solar array still needs cleaning. We need power before I can " +
		"bring the MOXIE online."},
]

const INTRO_LINES := [
	{"text": "Good, you made it inside. First things first: we need breathable air."},
	{"text": "The MOXIE unit is in the north-east corner. It turns the Martian air into oxygen."},
	{"text": "Three modules came loose: electrolysis chamber, motor compressor and electrical box."},
	{"text": "Drag them in order: electrolysis, then the motor, then the electrical box."},
	{"text": "Take your time, {name}. The whole base is counting on this."},
]

const RESUME_LINES := [
	{"text": "The MOXIE still needs more modules, {name}. Pick up where you left off."},
]

const DONE_LINES := [
	{"text": "That's it, the MOXIE is running again. You just gave this base its first breath."},
	{"text": "I've logged the repair in the mission order. One step closer to a livable base."},
	{"text": "That's everything for today. Your bed is in the south-west room. " +
		"Get some sleep, {name}."},
]

const BROKEN_LINES := [
	{"text": "The MOXIE is still down. Rebuild the three modules and we'll get the air back online."},
]

const REPAIRED_LINES := [
	{"text": "That did it. The MOXIE is breathing again."},
	{"text": "And this repair stays off the mission log. Just between us."},
]

var _busy := false
var _finishing := false
var _player_near := false
var _overlay: CanvasLayer

@onready var detect: Area2D = $DetectArea


func _ready():
	detect.body_entered.connect(_on_enter)
	detect.body_exited.connect(_on_exit)


func _on_enter(body):
	if "controls_enabled" in body:
		_player_near = true


func _on_exit(body):
	if "controls_enabled" in body:
		_player_near = false


func interact(player = null):
	if _busy:
		return
	if not GameState.moxie_broken and GameState.story_step >= SOLVED_STEP:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_busy = true
	if player:
		player.freeze_idle()
	if not GameState.moxie_broken and GameState.day1_stage < 2:
		await Dialogue.say(["Let's leave that for later."], GameState.player_name,
			PLAYER_PORTRAIT)
		_release_player()
		_busy = false
		return
	if GameState.moxie_broken:
		await Dialogue.talk(_build(BROKEN_LINES))
	elif GameState.story_step == 0:
		await Dialogue.talk(_build(INTRO_LINES))
	else:
		await Dialogue.talk(_build(RESUME_LINES))
	_open_overlay()


func _build(src: Array) -> Array:
	var out := []
	for l in src:
		out.append({
			"who": SPEAKER,
			"text": str(l["text"]).replace("{name}", GameState.player_name),
		})
	return out


func _open_overlay():
	if is_instance_valid(_overlay):
		return
	_overlay = OVERLAY.instantiate()
	add_child(_overlay)
	_overlay.connect("closed", _on_overlay_closed)
	for n in _overlay.find_children("*", "", true, false):
		if n.has_signal("placed"):
			n.connect("placed", _on_placed)


func _on_placed(_order: int):
	if _finishing:
		return
	if GameState.moxie_broken:
		if GameState.moxie_repair_step >= SOLVED_STEP:
			_finish_break()
	elif GameState.story_step >= SOLVED_STEP:
		_finish()


func _finish():
	_finishing = true
	await get_tree().create_timer(0.6).timeout
	_close_overlay()
	GameState.set_day1_stage(3)
	await Dialogue.talk(_build(DONE_LINES))
	_release_player()
	_busy = false
	_finishing = false


func _finish_break():
	_finishing = true
	await get_tree().create_timer(0.6).timeout
	_close_overlay()
	GameState.moxie_broken = false
	GameState.moxie_repair_step = 0
	await Dialogue.talk(_build(REPAIRED_LINES))
	_release_player()
	_busy = false
	_finishing = false


func _on_overlay_closed():
	if _finishing:
		return
	_close_overlay()
	_release_player()
	_busy = false


func _close_overlay():
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _release_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.controls_enabled = true
