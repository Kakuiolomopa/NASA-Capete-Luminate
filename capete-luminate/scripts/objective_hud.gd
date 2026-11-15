extends CanvasLayer

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const CONTROLS_SCRIPT := preload("res://scripts/controls_panel.gd")
const C_LINE := Color("2fe0f0")
const C_TEXT := Color("bff6ff")
const C_DIM := Color(0.45, 0.65, 0.7)
const C_ACCENT := Color("e08a2f")

var _font: Font
var _objective: Label
var _status: Label
var _controls_panel: PanelContainer
var _last_objective := ""


func _ready():
	layer = 10
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_build_objectives()
	_build_controls()
	_refresh()


func _process(_delta):
	_refresh()


func _panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.09, 0.12, 0.9)
	box.set_border_width_all(4)
	box.border_color = C_LINE
	box.anti_aliasing = false
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _build_objectives():
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(16, 16)
	panel.size = Vector2(430, 128)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	column.add_child(_label("OBJECTIVES", 28, C_LINE))

	_objective = _label("", 20, C_TEXT)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.custom_minimum_size = Vector2(398, 0)
	column.add_child(_objective)

	_status = _label("", 16, C_ACCENT)
	column.add_child(_status)


func _build_controls():
	_controls_panel = PanelContainer.new()
	_controls_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_controls_panel.offset_left = 16
	_controls_panel.offset_top = -150
	_controls_panel.offset_right = 430
	_controls_panel.offset_bottom = -12
	_controls_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_controls_panel)
	_controls_panel.hide()

	var controls := VBoxContainer.new()
	controls.set_script(CONTROLS_SCRIPT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_panel.add_child(controls)

	var button := Button.new()
	button.text = "TOOLS"
	button.position = Vector2(16, 580)
	button.size = Vector2(76, 36)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(func(): _controls_panel.visible = not _controls_panel.visible)
	add_child(button)


func _refresh():
	if _objective == null:
		return
	var text := _objective_text()
	if text != _last_objective:
		_last_objective = text
		_objective.text = text
	if GameState.control_panel_booted:
		_status.text = "D.A.I.S.Y. ONLINE"
		_status.add_theme_color_override("font_color", C_ACCENT)
	else:
		_status.text = "D.A.I.S.Y. OFFLINE"
		_status.add_theme_color_override("font_color", C_DIM)


func _objective_text() -> String:
	var text := ""
	if GameState.moxie_broken:
		text = "Repair the MOXIE fault."
	elif GameState.day >= 2 and GameState.day2_stage < 4:
		match GameState.day2_stage:
			0:
				text = "Check in with D.A.I.S.Y."
			1:
				text = "Repair the drill outside."
			2:
				text = "Repair the water tank inside."
			3:
				text = "Get some sleep."
	else:
		match GameState.day1_stage:
			0:
				text = "Find the base and boot the control panel."
			1:
				var total := maxi(1, GameState.solar_panel_count())
				text = "Clean the solar array: %d/%d" % [
					GameState.solar_cleaned_count(), total]
			2:
				text = "Repair the MOXIE system."
			3:
				text = "Get some sleep."
			_:
				text = "Check in with D.A.I.S.Y. at the control panel."
	return text


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _font:
		label.add_theme_font_override("font", _font)
	return label
