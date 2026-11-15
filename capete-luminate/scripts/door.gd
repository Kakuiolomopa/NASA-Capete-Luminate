extends StaticBody2D

@onready var detect: Area2D = $DetectArea
@export var to_base:bool = true
var _player_near := false
# Called when the node enters the scene tree for the first time.
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
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()
		get_tree().get_first_node_in_group("fade").fade_to_black(to_base)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
