extends Control

const INTRO_SCENE := "res://scenes/intro.tscn"
const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const MAX_LEN := 6
const ALLOWED := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

const C_LINE := Color("2fe0f0")
const C_TEXT := Color("bff6ff")
const C_BG := Color(0.02, 0.09, 0.12, 1.0)
const C_WARN := Color("e08a2f")

var _font: Font
var _edit: LineEdit
var _hint: Label
var _fade: ColorRect
var _busy := false


func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)

	box.add_child(_label("ENTER YOUR NAME", 40, C_LINE))

	_edit = LineEdit.new()
	_edit.max_length = MAX_LEN
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.custom_minimum_size = Vector2(460, 90)
	_edit.placeholder_text = "......"
	_edit.context_menu_enabled = false
	_edit.add_theme_font_size_override("font_size", 48)
	_edit.add_theme_color_override("font_color", C_TEXT)
	_edit.add_theme_color_override("caret_color", C_WARN)
	_edit.add_theme_color_override("font_placeholder_color", Color(0.3, 0.5, 0.55))
	_edit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		_edit.add_theme_font_override("font", _font)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.set_border_width_all(4)
	sb.border_color = C_LINE
	sb.anti_aliasing = false
	_edit.add_theme_stylebox_override("normal", sb)
	_edit.add_theme_stylebox_override("focus", sb)
	_edit.text_changed.connect(_on_changed)
	_edit.text_submitted.connect(func(_t): _confirm())
	box.add_child(_edit)

	_hint = _label("MAX %d CHARACTERS" % MAX_LEN, 20, Color(0.4, 0.65, 0.7))
	box.add_child(_hint)

	var ok := Button.new()
	ok.text = "CONFIRM"
	ok.custom_minimum_size = Vector2(320, 64)
	ok.add_theme_font_size_override("font_size", 24)
	ok.add_theme_color_override("font_color", C_TEXT)
	ok.add_theme_color_override("font_hover_color", Color.WHITE)
	if _font:
		ok.add_theme_font_override("font", _font)
	var nb := sb.duplicate()
	var hb := sb.duplicate()
	hb.bg_color = Color(0.5, 0.28, 0.08)
	hb.border_color = C_WARN
	ok.add_theme_stylebox_override("normal", nb)
	ok.add_theme_stylebox_override("hover", hb)
	ok.add_theme_stylebox_override("pressed", hb)
	ok.add_theme_stylebox_override("focus", hb)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_confirm)
	box.add_child(ok)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_edit.grab_focus()
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, 0.8)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		l.add_theme_font_override("font", _font)
	return l


func _on_changed(t: String):
	var clean := ""
	for c in t.to_upper():
		if ALLOWED.contains(c):
			clean += c
	if clean != t:
		var col := _edit.caret_column
		_edit.text = clean
		_edit.caret_column = mini(col, clean.length())
	_hint.text = "MAX %d CHARACTERS" % MAX_LEN
	_hint.add_theme_color_override("font_color", Color(0.4, 0.65, 0.7))


func _confirm():
	if _busy:
		return
	var n := _edit.text.strip_edges()
	if n.is_empty():
		_hint.text = "NAME CANNOT BE EMPTY"
		_hint.add_theme_color_override("font_color", C_WARN)
		return
	_busy = true
	GameState.player_name = n
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.8)
	await t.finished
	get_tree().change_scene_to_file(INTRO_SCENE)
