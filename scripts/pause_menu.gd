extends CanvasLayer

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"

const C_PANEL := Color(0.04, 0.1, 0.14, 0.95)
const C_LINE := Color("2fe0f0")
const C_TEXT := Color("bff6ff")
const C_SEL := Color("e08a2f")
const C_DIM := Color("5a7a85")

var is_open := false
var _font: Font
var _root: Control
var _left: VBoxContainer
var _right: VBoxContainer
var _msg: Label


func _ready():
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_build()
	_root.hide()


func _in_game() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == GAME_SCENE


func _unhandled_input(event):
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_open:
		_close()
		get_viewport().set_input_as_handled()
	elif _in_game() and not Dialogue.is_open:
		_open()
		get_viewport().set_input_as_handled()


func _open():
	is_open = true
	get_tree().paused = true
	_root.show()
	_clear_right()
	_left.get_child(0).grab_focus()


func _close():
	is_open = false
	get_tree().paused = false
	_root.hide()


func _box(c: Color, border := C_LINE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_border_width_all(4)
	s.border_color = border
	s.anti_aliasing = false
	s.set_content_margin_all(12)
	return s


func _button(text: String, w := 280) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 56)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", C_DIM)
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_stylebox_override("normal", _box(Color(0.02, 0.07, 0.1, 0.9), C_DIM))
	b.add_theme_stylebox_override("hover", _box(Color(0.5, 0.28, 0.08, 0.95), C_SEL))
	b.add_theme_stylebox_override("focus", _box(Color(0.5, 0.28, 0.08, 0.95), C_SEL))
	b.add_theme_stylebox_override("pressed", _box(Color(0.5, 0.28, 0.08, 0.95), C_SEL))
	b.add_theme_stylebox_override("disabled", _box(Color(0.02, 0.07, 0.1, 0.6), C_DIM))
	return b


func _label(text: String, size := 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", C_TEXT)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font:
		l.add_theme_font_override("font", _font)
	return l


func _build():
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 48)
	_root.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	margin.add_child(row)

	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 12)
	row.add_child(_left)

	var b_resume := _button("RESUME")
	var b_save := _button("SAVE")
	var b_load := _button("LOAD")
	var b_menu := _button("MAIN MENU")
	for b in [b_resume, b_save, b_load, b_menu]:
		_left.add_child(b)
	b_resume.pressed.connect(_close)
	b_save.pressed.connect(func(): _show_slots(true))
	b_load.pressed.connect(func(): _show_slots(false))
	b_menu.pressed.connect(_ask_menu)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(C_PANEL))
	row.add_child(panel)

	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 12)
	panel.add_child(_right)


func _clear_right():
	for c in _right.get_children():
		_right.remove_child(c)
		c.queue_free()


func _slot_text(i: int) -> String:
	if not SaveManager.has_save(i):
		return "SLOT %d - EMPTY" % (i + 1)
	var info := SaveManager.get_info(i)
	return "SLOT %d  %s  %s" % [i + 1, info["date"], SaveManager.format_time(info["play_time"])]


func _show_slots(saving: bool):
	_clear_right()
	_right.add_child(_label("SAVE GAME" if saving else "LOAD GAME", 28))
	_msg = _label("")
	for i in SaveManager.SLOTS:
		var b := _button(_slot_text(i), 560)
		b.add_theme_font_size_override("font_size", 16)
		var slot := i
		if saving:
			b.pressed.connect(func(): _do_save(slot))
		else:
			b.disabled = not SaveManager.has_save(i)
			b.pressed.connect(func(): _do_load(slot))
		_right.add_child(b)
	_right.add_child(_msg)


func _do_save(slot: int):
	if SaveManager.has_save(slot):
		_confirm("Overwrite slot %d?" % (slot + 1), func(): _save_now(slot), func(): _show_slots(true))
	else:
		_save_now(slot)


func _save_now(slot: int):
	var ok := SaveManager.save_game(slot)
	_show_slots(true)
	_msg.text = "Game saved!" if ok else "Save failed."


func _do_load(slot: int):
	_close()
	SaveManager.load_game(slot)


func _confirm(question: String, on_yes: Callable, on_no: Callable):
	_clear_right()
	_right.add_child(_label(question, 26))
	var yes := _button("YES", 280)
	var no := _button("NO", 280)
	yes.pressed.connect(on_yes)
	no.pressed.connect(on_no)
	_right.add_child(yes)
	_right.add_child(no)
	no.grab_focus()


func _ask_menu():
	_confirm("Go to the main menu?", _ask_save_first, _clear_right)


func _ask_save_first():
	_confirm("Save before leaving?",
		func(): _show_slots_then_exit(),
		_go_menu)


func _show_slots_then_exit():
	_clear_right()
	_right.add_child(_label("SAVE BEFORE LEAVING", 26))
	for i in SaveManager.SLOTS:
		var b := _button(_slot_text(i), 560)
		b.add_theme_font_size_override("font_size", 16)
		var slot := i
		b.pressed.connect(func():
			SaveManager.save_game(slot)
			_go_menu())
		_right.add_child(b)
	var cancel := _button("CANCEL", 280)
	cancel.pressed.connect(_clear_right)
	_right.add_child(cancel)


func _go_menu():
	_close()
	SaveManager.stop_counting()
	get_tree().change_scene_to_file(MENU_SCENE)
