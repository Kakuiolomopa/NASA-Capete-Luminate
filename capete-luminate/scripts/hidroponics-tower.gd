extends VBoxContainer

@export var shelf_number:int = 3
# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(shelf_number):
		var hbox = HBoxContainer.new()
		hbox.name = "Container"
		var nutrient_meter = Panel.new()
		var panel = Panel.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 25)
		

		panel.name = "Shelf" + str(i)
		panel.set_meta("shelf_index", i)
		nutrient_meter.name = "Nutrient"
		

		panel.custom_minimum_size = Vector2(200, 100)
		nutrient_meter.custom_minimum_size = Vector2(50, 50)
		nutrient_meter.custom_maximum_size = Vector2(50,50)

		var style = StyleBoxTexture.new()
		var nutrient_style = StyleBoxTexture.new()

		if i != 0:
			style.texture = load("res://assets/HidroShelf.png")
			nutrient_style.texture = load("res://assets/nutrient_bad.png")
		else:
			style.texture = load("res://assets/HidroShelfN.png")


		if i != 0:
			var glow = Panel.new()
			glow.name = "Outline"
			glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var glow_style = StyleBoxFlat.new()
			glow_style.bg_color = Color(0, 0, 0, 0)
			glow_style.border_color = Color.CYAN
			glow_style.set_border_width_all(3)

			glow.add_theme_stylebox_override("panel", glow_style)
			glow.hide()
			panel.add_child(glow)

			panel.add_to_group("hidro-panels")

		panel.add_theme_stylebox_override("panel", style)
		nutrient_meter.add_theme_stylebox_override("panel", nutrient_style)

		var vbox = VBoxContainer.new()
		
		panel.set_meta("nutrient",nutrient_meter)

		hbox.add_child(panel)
		vbox.add_child(margin)
		vbox.add_child(nutrient_meter)
		hbox.add_child(vbox)

		add_child(hbox)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for shelf in get_tree().get_nodes_in_group("hidro-panels"):
		var nutrient = shelf.get_meta("nutrient")
		var shelf_style = shelf.get_theme_stylebox("panel") as StyleBoxTexture

		if shelf_style.texture == load("res://assets/HidroShelf.png"):
			var style = StyleBoxTexture.new()
			style.texture = load("res://assets/nutrient_bad.png")
			nutrient.add_theme_stylebox_override("panel", style)
	
