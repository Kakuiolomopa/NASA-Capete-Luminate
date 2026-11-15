extends CanvasLayer

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"

var _label: Label


func _ready():
	layer = 11
	var panel := PanelContainer.new()
	panel.position = Vector2(1020, 16)
	panel.size = Vector2(244, 132)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.09, 0.12, 0.9)
	style.set_border_width_all(3)
	style.border_color = Color("2fe0f0")
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color("bff6ff"))
	if ResourceLoader.exists(FONT_PATH):
		_label.add_theme_font_override("font", load(FONT_PATH))
	panel.add_child(_label)
	_refresh()


func _process(_delta):
	_refresh()


func _refresh():
	if _label == null:
		return
	_label.text = "DAY %d\nENERGY  %3d\nOXYGEN  %3d\nWATER   %3d\nFOOD    %3d\nHEALTH  %3d" % [
		GameState.day,
		GameState.energy, GameState.oxygen, GameState.water,
		GameState.food, GameState.health]
