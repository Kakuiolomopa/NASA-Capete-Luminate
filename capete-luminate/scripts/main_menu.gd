extends Control

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"

const C_SKY_TOP := Color("7fc8e8")
const C_SKY_BOTTOM := Color("cfeef0")
const C_WOOD := Color("8a3a22")
const C_OUTLINE := Color("2a0f0a")
const C_TEXT := Color("ffd9a0")
const C_DISABLED := Color("8a7a66")
const TITLE := "MISSION ON MARS"
const C_TITLE := Color("ffe9b0")
const C_TITLE_SHADOW := Color("5a1f14")
const MUSIC_PATH := "res://assets/audio/jolly_music.mp3"

const BTN_SIZE := Vector2(320, 64)

var _starting := false
var _music_player: AudioStreamPlayer
var _controls_panel: Control
var _font: Font
var _menu_box: VBoxContainer
var _load_panel: Control
var _slot_box: VBoxContainer


func _ready():
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_main_buttons()
	_build_title()
	_build_load_panel()
	_start_music()


func _build_background():
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprite/mars_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(bg, 0)


func _box(color: Color, bottom := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_border_width_all(4)
	s.border_width_bottom = 4 + bottom
	s.border_color = C_OUTLINE
	s.anti_aliasing = false
	return s


func _make_button(text: String, size := BTN_SIZE) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_ALL
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", C_DISABLED)
	b.add_theme_color_override("font_outline_color", C_OUTLINE)
	b.add_theme_constant_override("outline_size", 4)
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_stylebox_override("normal", _box(C_WOOD))
	b.add_theme_stylebox_override("hover", _box(C_WOOD.lightened(0.15)))
	b.add_theme_stylebox_override("focus", _box(C_WOOD.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", _box(C_WOOD.darkened(0.1), 0))
	b.add_theme_stylebox_override("disabled", _box(C_WOOD.darkened(0.4)))
	return b


func _build_main_buttons():
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 16)
	center.add_child(_menu_box)

	var b_new := _make_button("NEW")
	var b_load := _make_button("LOAD")
	var b_set := _make_button("CONTROLS")
	var b_exit := _make_button("EXIT")
	for b in [b_new, b_load, b_set, b_exit]:
		_menu_box.add_child(b)

	b_load.pressed.connect(_open_load)
	b_new.pressed.connect(_start_new_game)
	b_set.pressed.connect(_open_controls)
	b_exit.pressed.connect(func(): get_tree().quit())
	b_new.grab_focus()

func _build_load_panel():
	_load_panel = Control.new()
	_load_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_panel.hide()
	add_child(_load_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_panel.add_child(center)

	_slot_box = VBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 16)
	center.add_child(_slot_box)


func _open_load():
	_menu_box.get_parent().hide()
	_load_panel.show()
	_refresh_slots()


func _close_load():
	_load_panel.hide()
	_menu_box.get_parent().show()
	_menu_box.get_child(1).grab_focus()


func _refresh_slots():
	for c in _slot_box.get_children():
		_slot_box.remove_child(c)
		c.queue_free()

	var title := Label.new()
	title.text = "LOAD GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_TEXT)
	title.add_theme_color_override("font_outline_color", C_OUTLINE)
	title.add_theme_constant_override("outline_size", 6)
	title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		title.add_theme_font_override("font", _font)
	_slot_box.add_child(title)

	var first: Button = null
	for i in SaveManager.SLOTS:
		var text := "SLOT %d - EMPTY" % (i + 1)
		var has: bool = SaveManager.has_save(i)
		if has:
			var info: Dictionary = SaveManager.get_info(i)
			text = "SLOT %d  %s  %s" % [i + 1, info["date"], SaveManager.format_time(info["play_time"])]
		var b := _make_button(text, Vector2(560, 64))
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not has
		var slot: int = i
		b.pressed.connect(func(): SaveManager.load_game(slot))
		_slot_box.add_child(b)
		if has and first == null:
			first = b

	var back := _make_button("BACK", Vector2(560, 64))
	back.pressed.connect(_close_load)
	_slot_box.add_child(back)

	if first:
		first.grab_focus()
	else:
		back.grab_focus()


func _unhandled_input(event):
	if _controls_panel and event.is_action_pressed("ui_cancel"):
		_close_controls()
		
func _build_title():
	var title := Label.new()
	title.text = TITLE
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	title.offset_bottom = 140
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", C_TITLE)
	title.add_theme_color_override("font_outline_color", C_TITLE_SHADOW)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 8)
	if _font:
		title.add_theme_font_override("font", _font)
	add_child(title)
	
	var tw := create_tween().set_loops()
	tw.tween_property(title, "position:y", 8.0, 1.4).as_relative().set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "position:y", -8.0, 1.4).as_relative().set_trans(Tween.TRANS_SINE)

func _open_controls():
	_menu_box.get_parent().hide()
	_controls_panel = Control.new()
	_controls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_controls_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)
	box.add_child(preload("res://scripts/controls_panel.gd").new())
	var back := _make_button("BACK", Vector2(320, 64))
	back.pressed.connect(_close_controls)
	box.add_child(back)
	back.grab_focus()


func _close_controls():
	if _controls_panel:
		_controls_panel.queue_free()
		_controls_panel = null
	_menu_box.get_parent().show()

func _start_music():
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(MUSIC_PATH)
	p.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	p.volume_db = -6.0
	add_child(p)
	p.play()
	
func _start_new_game():
	if _starting:
		return
	_starting = true

	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_STOP  
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var t := create_tween().set_parallel(true)
	t.tween_property(fade, "modulate:a", 1.0, 1.2)
	if _music_player:
		t.tween_property(_music_player, "volume_db", -40.0, 1.2)
	await t.finished
	await get_tree().create_timer(0.3).timeout

	SaveManager.new_game()
