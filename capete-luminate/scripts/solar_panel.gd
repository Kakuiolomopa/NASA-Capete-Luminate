extends StaticBody2D

const SPEAKER := "D.A.I.S.Y"
const PLAYER_PORTRAIT := preload("res://assets/portraits/portraitas.png")
const DUSTY := preload("res://assets/DustyPanel.png")
const CLEAN := preload("res://assets/Panel.png")

const LOCKED_LINES := [
	{"text": "These panels are covered in dust. I should boot the base's control system first."},
]
const INTRO_LINES := [
	{"text": "There they are. The storm coated the whole array in dust."},
	{"text": "Clean them off when you can, {name}. The base needs the power."},
]
const ARRAY_DONE_LINES := [
	{"text": "That's the whole array. Power's stable."},
	{"text": "Next: the MOXIE unit inside the base. It's not making breathable air yet."},
]
const ARRAY_DONE_MOXIE_READY := [
	{"text": "That's the whole array. Power's stable."},
	{"text": "The MOXIE is already running, so that's everything for today. Get some sleep."},
]

@export var panel_id := "solar_0"

var _unlocked := false
var _busy := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _detect: Area2D = $DetectArea


func _ready():
	add_to_group("solar_panels")
	_unlocked = true
	_apply_texture()


func set_unlocked(enabled: bool):
	_unlocked = enabled
	visible = enabled
	$CollisionShape2D.disabled = not enabled
	$DetectArea/CollisionShape2D.disabled = not enabled
	_detect.monitoring = enabled
	_detect.monitorable = enabled


func interact(player = null):
	if _busy:
		return
	_busy = true
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()

	if not GameState.control_panel_booted or GameState.day1_stage < 1:
		await Dialogue.talk([{
			"who": GameState.player_name,
			"text": LOCKED_LINES[0]["text"],
			"portrait": PLAYER_PORTRAIT,
		}])
		_release(player)
		return

	var cleaned := bool(GameState.solar_cleaned.get(panel_id, false))
	if cleaned:
		pass
	else:
		if not GameState.solar_intro_seen:
			GameState.solar_intro_seen = true
			await Dialogue.talk(_build(INTRO_LINES))
		GameState.solar_cleaned[panel_id] = true
		_apply_texture()
		await _check_array_complete()

	_release(player)


func _check_array_complete():
	if GameState.solar_cleaned_count() < GameState.solar_panel_count():
		return
	if GameState.solar_task_done:
		return
	GameState.solar_task_done = true
	if GameState.story_step >= 3:
		GameState.set_day1_stage(3)
		await Dialogue.talk(_build(ARRAY_DONE_MOXIE_READY))
	else:
		GameState.set_day1_stage(2)
		await Dialogue.talk(_build(ARRAY_DONE_LINES))


func _release(player):
	if player:
		player.controls_enabled = true
	_busy = false


func _build(src: Array) -> Array:
	var out := []
	for line in src:
		out.append({
			"who": SPEAKER,
			"text": str(line["text"]).replace("{name}", GameState.player_name),
		})
	return out


func _apply_texture():
	if _sprite == null:
		return
	_sprite.texture = CLEAN if bool(GameState.solar_cleaned.get(panel_id, false)) else DUSTY
