extends VBoxContainer

const EMPTY_SHELF := preload("res://assets/sprite/HidroShelf.png")
const EMPTY_SHELF_N := preload("res://assets/sprite/HidroShelfN.png")
const BAD_NUTRIENT := preload("res://assets/sprite/nutrient_bad.png")

@export var shelf_number: int = 3


func _ready():
	for i in range(shelf_number):
		var hbox := HBoxContainer.new()
		hbox.name = "ShelfRow%d" % i
		var nutrient_meter := Panel.new()
		var panel := Panel.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 25)

		panel.name = "Shelf%d" % i
		panel.set_meta("shelf_index", i)
		nutrient_meter.name = "Nutrient"
		panel.custom_minimum_size = Vector2(200, 100)
		nutrient_meter.custom_minimum_size = Vector2(50, 50)
		nutrient_meter.custom_maximum_size = Vector2(50, 50)

		var style := StyleBoxTexture.new()
		var nutrient_style := StyleBoxTexture.new()
		if i != 0:
			style.texture = EMPTY_SHELF
			nutrient_style.texture = BAD_NUTRIENT
		else:
			style.texture = EMPTY_SHELF_N

		if i != 0:
			var glow := Panel.new()
			glow.name = "Outline"
			glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var glow_style := StyleBoxFlat.new()
			glow_style.bg_color = Color(0, 0, 0, 0)
			glow_style.border_color = Color.CYAN
			glow_style.set_border_width_all(3)
			glow.add_theme_stylebox_override("panel", glow_style)
			glow.hide()
			panel.add_child(glow)
			panel.add_to_group("hidro-panels")

		panel.add_theme_stylebox_override("panel", style)
		nutrient_meter.add_theme_stylebox_override("panel", nutrient_style)
		panel.set_meta("nutrient", nutrient_meter)

		var vbox := VBoxContainer.new()
		hbox.add_child(panel)
		vbox.add_child(margin)
		vbox.add_child(nutrient_meter)
		hbox.add_child(vbox)
		add_child(hbox)


func _process(_delta):
	for shelf in get_tree().get_nodes_in_group("hidro-panels"):
		var nutrient = shelf.get_meta("nutrient")
		var shelf_style := shelf.get_theme_stylebox("panel") as StyleBoxTexture
		if shelf_style != null and shelf_style.texture == EMPTY_SHELF:
			var style := StyleBoxTexture.new()
			style.texture = BAD_NUTRIENT
			nutrient.add_theme_stylebox_override("panel", style)
