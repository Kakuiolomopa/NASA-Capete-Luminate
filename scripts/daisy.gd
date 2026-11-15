extends CharacterBody2D

@export var npc_name := "D.A.I.S.Y"
@export_multiline var lines: Array[String] = [
	"N: Salut! Nu te-am mai văzut pe aici.",
	"P: Sunt nou. Unde suntem?",
	"N: Într-un loc ciudat. Ai grijă pe unde calci.",
]

@onready var detect: Area2D = $DetectArea

var bubble: Node2D
var _talking := false
var _player_near := false


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	bubble = preload("res://scripts/bubble.gd").new()
	bubble.position = Vector2(0, -11)
	bubble.scale = Vector2(0.7, 0.7)
	bubble.hide()
	add_child(bubble)
	detect.body_entered.connect(_on_enter)
	detect.body_exited.connect(_on_exit)


func _on_enter(body):
	if "controls_enabled" in body:
		_player_near = true
		_refresh()


func _on_exit(body):
	if "controls_enabled" in body:
		_player_near = false
		_refresh()


func _refresh():
	bubble.visible = _player_near and not _talking


func interact(player = null):
	if _talking:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_talking = true
	_refresh()
	if player:
		player.freeze_idle()
	await Dialogue.talk(_build(lines))
	if player:
		player.controls_enabled = true
	_talking = false
	_refresh()


func _build(src: Array) -> Array:
	var out := []
	for l in src:
		if l.begins_with("P:"):
			out.append({"who": "egg", "text": l.substr(2).strip_edges()})
		elif l.begins_with("N:"):
			out.append({"who": npc_name, "text": l.substr(2).strip_edges()})
		else:
			out.append({"who": npc_name, "text": l})
	return out
