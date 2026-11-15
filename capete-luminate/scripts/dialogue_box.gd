extends CanvasLayer

signal _advance
signal line_started(speaker: String)

# Portrete statice (Miss M. nu e aici: are animație)
const PORTRAITS := {
	"egg": "res://assets/portraits/egg.jpg",
}
const VOICES := {}
const VOICE_PITCH := {}

const MISSM_NAME := "Miss M."
const MISSM_FRAMES := "res://assets/portraits/missm_frames.tres"
const MISSM_SCALE := 4

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const FONT_SIZE := 28
const NAME_SIZE := 24
const CHAR_DELAY := 0.03

const C_BG := Color(0.02, 0.09, 0.12, 0.95)
const C_LINE := Color("2fe0f0")
const C_DIM := Color("1a8a99")
const C_TEXT := Color("bff6ff")

const PX := 4
const CUT := 12

var is_open := false
var _typing := false
var _skip := false
var _speaker := ""

var _root: Control
var _box: Control
var _portrait_frame: Control
var _tab: Control
var _label: Label
var _name_label: Label
var _face: TextureRect
var _anim_face: AnimatedSprite2D
var _arrow: Control
var _blip: AudioStreamPlayer
var _font: Font


class PixelPanel extends Control:
	var px := 4
	var cut := 12
	var fill := Color.BLACK
	var line := Color.CYAN
	var dim := Color.DARK_CYAN
	var c_tl := true
	var c_tr := true
	var c_bl := true
	var c_br := true

	func _inset(r: int, rows: int, steps: int, top_c: bool, bot_c: bool) -> int:
		var v := 0
		if top_c and r < steps:
			v = steps - r
		var rb := rows - 1 - r
		if bot_c and rb < steps:
			v = maxi(v, steps - rb)
		return v

	func _draw():
		var cols := int(size.x) / px
		var rows := int(size.y) / px
		var steps := maxi(cut / px, 1)

		for r in rows:
			var xl := _inset(r, rows, steps, c_tl, c_bl)
			var xr := cols - _inset(r, rows, steps, c_tr, c_br)
			draw_rect(Rect2(xl * px, r * px, (xr - xl) * px, px), line)

		for r in range(1, rows - 1):
			var xl := _inset(r, rows, steps, c_tl, c_bl) + 1
			var xr := cols - _inset(r, rows, steps, c_tr, c_br) - 1
			if xr > xl:
				draw_rect(Rect2(xl * px, r * px, (xr - xl) * px, px), fill)

		var m := 2
		var a := steps + m
		if cols > 2 * a and rows > 2 * m + 2:
			draw_rect(Rect2(a * px, m * px, (cols - 2 * a) * px, px), dim)
			draw_rect(Rect2(a * px, (rows - m - 1) * px, (cols - 2 * a) * px, px), dim)
		if rows > 2 * a:
			draw_rect(Rect2(m * px, a * px, px, (rows - 2 * a) * px), dim)
			draw_rect(Rect2((cols - m - 1) * px, a * px, px, (rows - 2 * a) * px), dim)


func _ready():
	layer = 30
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_build()
	_blip = AudioStreamPlayer.new()
	add_child(_blip)
	_root.hide()


# ---------- API ----------
func say(lines: Array, speaker := "", portrait_tex: Texture2D = null):
	var entries := []
	for l in lines:
		entries.append({"who": speaker, "text": str(l), "portrait": portrait_tex})
	await talk(entries)


func talk(entries: Array):
	await get_tree().process_frame
	is_open = true
	_root.show()
	for e in entries:
		_set_speaker(e.get("who", ""), e.get("portrait", null), e.get("voice", null))
		await _show_line(str(e["text"]))
	_root.hide()
	await get_tree().process_frame
	is_open = false


# ---------- Logică ----------
func _animate_portrait(talking: bool):
	if _speaker != MISSM_NAME or _anim_face == null or _anim_face.sprite_frames == null:
		return
	var anim := "talk" if talking else "idle"
	if _anim_face.animation != anim or not _anim_face.is_playing():
		_anim_face.play(anim)


func _show_line(text: String):
	line_started.emit(_speaker)
	_label.text = text
	_label.visible_characters = 0
	_arrow.hide()
	_typing = true
	_skip = false
	_animate_portrait(true)

	var i := 0
	while i < text.length() and not _skip:
		i += 1
		_label.visible_characters = i
		if i % 2 == 0 and text[i - 1] != " ":
			_play_blip()
		await get_tree().create_timer(CHAR_DELAY).timeout

	_label.visible_characters = -1
	_typing = false
	_animate_portrait(false)
	_arrow.show()
	await _advance
	_arrow.hide()


func _play_blip():
	if _blip.stream == null:
		return
	_blip.pitch_scale = VOICE_PITCH.get(_speaker, 1.0) * randf_range(0.93, 1.07)
	_blip.play()


func _unhandled_input(event):
	if not is_open or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_skip = true
	else:
		_advance.emit()


func _set_speaker(speaker: String, tex: Texture2D, voice: AudioStream = null):
	_speaker = speaker
	_tab.visible = speaker != ""
	_name_label.text = speaker.to_upper()

	var use_anim := false
	if speaker == MISSM_NAME and ResourceLoader.exists(MISSM_FRAMES):
		_anim_face.sprite_frames = load(MISSM_FRAMES)
		_anim_face.play("idle")
		use_anim = true
	_anim_face.visible = use_anim

	if not use_anim and tex == null and PORTRAITS.has(speaker):
		if ResourceLoader.exists(PORTRAITS[speaker]):
			tex = load(PORTRAITS[speaker])

	_face.texture = null if use_anim else tex
	_face.visible = not use_anim
	_portrait_frame.visible = use_anim or tex != null

	if voice == null and VOICES.has(speaker):
		if ResourceLoader.exists(VOICES[speaker]):
			voice = load(VOICES[speaker])
	_blip.stream = voice


# ---------- Interfață ----------
func _style_label(l: Label, size: int):
	l.add_theme_color_override("font_color", C_TEXT)
	l.add_theme_font_size_override("font_size", size)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		l.add_theme_font_override("font", _font)


func _panel(tl := true, tr := true, bl := true, br := true, cut := CUT) -> PixelPanel:
	var p := PixelPanel.new()
	p.px = PX
	p.cut = cut
	p.fill = C_BG
	p.line = C_LINE
	p.dim = C_DIM
	p.c_tl = tl
	p.c_tr = tr
	p.c_bl = bl
	p.c_br = br
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return p


func _build():
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var vp := get_viewport().get_visible_rect().size
	var margin := 32.0
	var h := 188.0
	var port := 188.0
	var y := float(int((vp.y - margin - h) / PX) * PX)

	# Portret
	_portrait_frame = _panel(false, true, true, false)
	_portrait_frame.position = Vector2(margin, y)
	_portrait_frame.size = Vector2(port, port)
	_root.add_child(_portrait_frame)

	_face = TextureRect.new()
	_face.position = Vector2(16, 16)
	_face.size = Vector2(port - 32, port - 32)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_frame.add_child(_face)

	_anim_face = AnimatedSprite2D.new()
	_anim_face.centered = true
	_anim_face.position = Vector2(port, port) / 2.0
	_anim_face.scale = Vector2(MISSM_SCALE, MISSM_SCALE)
	_anim_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anim_face.hide()
	_portrait_frame.add_child(_anim_face)
	_portrait_frame.clip_contents = true
	# Caseta principală
	var bx := margin + port + 16.0
	var bw := float(int((vp.x - bx - margin) / PX) * PX)
	_box = _panel(true, true, true, true)
	_box.position = Vector2(bx, y)
	_box.size = Vector2(bw, h)
	_root.add_child(_box)

	_label = Label.new()
	_label.position = Vector2(32, 24)
	_label.size = _box.size - Vector2(64, 48)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_style_label(_label, FONT_SIZE)
	_box.add_child(_label)

	# Tab nume
	_tab = _panel(true, true, false, false, 8)
	_tab.size = Vector2(260, 44)
	_tab.position = Vector2(bx + 24, y - 40)
	_root.add_child(_tab)

	_name_label = Label.new()
	_name_label.position = Vector2(20, 4)
	_name_label.size = Vector2(230, 32)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_name_label, NAME_SIZE)
	_tab.add_child(_name_label)

	# Săgeată
	_arrow = Control.new()
	_arrow.position = Vector2(_box.size.x - 64, _box.size.y - 60)
	_arrow.draw.connect(func():
		_arrow.draw_rect(Rect2(0, 0, 24, 4), C_LINE)
		_arrow.draw_rect(Rect2(4, 4, 16, 4), C_LINE)
		_arrow.draw_rect(Rect2(8, 8, 8, 4), C_LINE))
	_box.add_child(_arrow)
	_arrow.hide()

	var bounce := create_tween().set_loops()
	bounce.tween_property(_arrow, "position:y", _arrow.position.y + 4, 0.4)
	bounce.tween_property(_arrow, "position:y", _arrow.position.y, 0.4)
