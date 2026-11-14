extends Panel

@export var group_name:String = "motor-compressor-slot"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(group_name)
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
