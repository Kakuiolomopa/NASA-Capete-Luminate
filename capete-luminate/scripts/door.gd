extends StaticBody2D

@export var to_base:bool = true
var _player_near := false
@onready var detect: Area2D = $DetectArea
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
		var fade = get_tree().get_first_node_in_group("fade")
		if not to_base:
			var outside_door = get_tree().get_first_node_in_group("outside_door")
			if outside_door != null:
				var marker = outside_door.get_node_or_null("OutsideMarker")
				if marker != null:
					GameState.outside_pos = marker.global_position
		if fade:
			await fade.fade_to_black(to_base)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
