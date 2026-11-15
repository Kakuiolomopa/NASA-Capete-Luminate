extends VBoxContainer

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const C_TEXT := Color("bff6ff")
const C_LINE := Color("2fe0f0")
const C_KEY := Color("e08a2f")

const KEYS := [
	["Move", "W A S D / Arrows"],
	["Interact / Next", "E / Space"],
	["Drag / place", "Mouse"],
	["Pause menu", "Esc"],
]

var _font: Font


func _ready():
	add_theme_constant_override("separation", 6)
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	add_child(_label("CONTROLS", 18, C_LINE))
	for k in KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var a := _label(k[0], 14, C_TEXT)
		a.custom_minimum_size.x = 165
		row.add_child(a)
		row.add_child(_label(k[1], 14, C_KEY))
		add_child(row)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		l.add_theme_font_override("font", _font)
	return l
