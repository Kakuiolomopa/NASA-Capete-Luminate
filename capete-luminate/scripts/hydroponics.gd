extends StaticBody2D

const OVERLAY := preload("res://scenes/hidroponics_interaction.tscn")
const TUTORIAL_STEP := 4
const SHELF_COUNT := 5
const SPEAKER := "D.A.I.S.Y"

const EMPTY_SHELF := preload("res://assets/sprite/HidroShelf.png")
const CROP_TEXTURES := {
	"tomato": preload("res://assets/sprite/TomatoShelf.png"),
	"lettuce": preload("res://assets/sprite/LettuceShelf.png"),
}
const NUTRIENT_GOOD := preload("res://assets/sprite/nutrient_good.png")
const NUTRIENT_BAD := preload("res://assets/sprite/nutrient_bad.png")

const LOCKED_LINES := [
	{"text": "Not today, {name}. Let's finish today's priorities first. " +
		"Food can wait until we're settled."},
]

const TUTORIAL_LINES := [
	{"text": "Next: food. A colony can't live on rations alone."},
	{"text": "These hydroponics towers grow crops in nutrient-rich water instead of soil."},
	{"text": "Drag a crop onto an empty shelf, then feed it nutrients to keep it healthy."},
	{"text": "We have three units online. Each tower remembers what you planted."},
	{"text": "The towers are yours now. Come back any time to cultivate more."},
]

const CROP_HINT := [
	{"text": "Good. Now drag nutrients onto that shelf so the crop stays healthy."},
]

const NUTRIENT_HINT := [
	{"text": "Green means the nutrients are balanced. Keep an eye on the meters."},
]

const BED_PROMPT := [
	{"text": "All three towers are stable. That's enough for today, {name}. " +
		"Your bed is in the southwest room. You should get some sleep."},
]

const ARCADIA_LINES := [
	{"text": "The hydroponics tutorial is saved. Good work, {name}."},
	{"text": "We are in Arcadia Planitia, a broad plain chosen because the ground " +
		"may hold accessible water."},
	{"text": "Water is the next limit: drinking reserves, crops, fuel, and every " +
		"system that keeps this habitat alive."},
	{"text": "The drill outside is offline. Repair it first, then bring the water " +
		"tank inside back online."},
]

@export var station_id: String = "hydro_1"

var _busy := false
var _player_near := false
var _overlay: CanvasLayer
var _hint_busy := false

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
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_busy = true
	if player:
		player.freeze_idle()
	if GameState.day1_stage < 4:
		await Dialogue.talk(_build(LOCKED_LINES))
		_release_player()
		_busy = false
		return
	if not GameState.hydro_intro_seen:
		await Dialogue.talk(_build(TUTORIAL_LINES))
		GameState.hydro_intro_seen = true
		_save_progress()
	GameState.story_step = maxi(GameState.story_step, TUTORIAL_STEP)
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
	_overlay.layer = 20
	_overlay.set_meta("station_id", station_id)
	add_child(_overlay)
	_overlay.connect("visibility_changed", _on_overlay_visibility_changed)
	_restore_shelves()
	_connect_drops()


func _tower():
	if not is_instance_valid(_overlay):
		return null
	return _overlay.get_node_or_null("Tower")


func _restore_shelves():
	var tower = _tower()
	if tower == null:
		return
	var state = _station_state()
	for i in range(tower.get_child_count()):
		var hbox = tower.get_child(i)
		if not (hbox is HBoxContainer):
			continue
		var shelf = hbox.get_node_or_null("Shelf%d" % i)
		if shelf == null or i == 0:
			continue
		var data = state[i] if i < state.size() and state[i] is Dictionary else {}
		var crop := str(data.get("crop", "none"))
		var shelf_style := StyleBoxTexture.new()
		shelf_style.texture = CROP_TEXTURES.get(crop, EMPTY_SHELF)
		shelf.add_theme_stylebox_override("panel", shelf_style)
		var nutrient = shelf.get_meta("nutrient")
		var nutrient_style := StyleBoxTexture.new()
		nutrient_style.texture = NUTRIENT_GOOD if bool(data.get("nutrient", false)) else NUTRIENT_BAD
		nutrient.add_theme_stylebox_override("panel", nutrient_style)


func _connect_drops():
	if not is_instance_valid(_overlay):
		return
	var items := [
		[_overlay.get_node_or_null("PlantsContainer/VBoxContainer/TomatoPlant"), "tomato"],
		[_overlay.get_node_or_null("PlantsContainer/VBoxContainer/Lettuce"), "lettuce"],
		[_overlay.get_node_or_null("Nutrients/Nutrient"), "nutrient"],
	]
	for pair in items:
		var item = pair[0]
		if item != null and item.has_signal("item_dropped"):
			item.item_dropped.connect(_on_item_dropped.bind(pair[1]))


func _on_item_dropped(_item, drop_target, _applied, kind: String):
	if not drop_target.has_meta("shelf_index"):
		return
	var idx := int(drop_target.get_meta("shelf_index"))
	if idx <= 0 or idx >= SHELF_COUNT:
		return
	var state = _station_state()
	if idx >= state.size():
		return
	var data = state[idx]
	if kind == "nutrient":
		data["nutrient"] = true
		if not GameState.hydro_nutrient_hint:
			GameState.hydro_nutrient_hint = true
			_play_hint(NUTRIENT_HINT)
	else:
		data["crop"] = kind
		if not GameState.hydro_crop_hint:
			GameState.hydro_crop_hint = true
			_play_hint(CROP_HINT)
	_save_progress()


func _play_hint(lines: Array):
	if _hint_busy:
		return
	_hint_busy = true
	if is_instance_valid(_overlay):
		_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	await Dialogue.talk(_build(lines))
	if is_instance_valid(_overlay):
		_overlay.process_mode = Node.PROCESS_MODE_INHERIT
	_hint_busy = false


func _station_state() -> Array:
	var stored = GameState.hydro.get(station_id)
	if not (stored is Array) or stored.size() < SHELF_COUNT:
		stored = _default_state()
		GameState.hydro[station_id] = stored
	var state: Array = stored
	for i in range(state.size()):
		if not (state[i] is Dictionary):
			state[i] = {"crop": "none", "nutrient": false}
	return state


func _default_state() -> Array:
	var out := []
	for i in range(SHELF_COUNT):
		out.append({"crop": "none", "nutrient": false})
	return out


func _on_overlay_visibility_changed():
	if is_instance_valid(_overlay) and not _overlay.visible:
		_close_overlay()
		_release_player()
		_busy = false
		_maybe_prompt_bed()


func _maybe_prompt_bed():
	if (GameState.day == 2 and GameState.day2_stage == 0 and
			GameState.all_hydro_ready()):
		GameState.day2_stage = 1
		_save_progress()
		await Dialogue.talk(_build(ARCADIA_LINES))
		return
	if GameState.first_night_done or GameState.bed_prompted:
		return
	if not GameState.all_hydro_ready():
		return
	GameState.bed_prompted = true
	await Dialogue.talk(_build(BED_PROMPT))


func _save_progress():
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint(GameState.day)


func _close_overlay():
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _release_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.controls_enabled = true
