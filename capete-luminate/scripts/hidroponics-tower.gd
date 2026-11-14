extends VBoxContainer

@export var shelf_number:int = 3
# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in range(shelf_number):
		var panel = Panel.new()
		panel.name = "Shelf"+str(i+1)
		
		panel.custom_minimum_size = Vector2(200,130)
		panel.global_position.x +=100
		
		var style = StyleBoxTexture.new()
		style.texture = load("res://assets/HidroShelf.png")
		
		panel.add_theme_stylebox_override("panel",style)
		if(i!=0):
			panel.add_to_group("hidro-panels")
		$".".add_child(panel)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
