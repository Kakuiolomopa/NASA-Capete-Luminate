class_name ColonyMinigame
extends Control

signal finished(score: float, result: Dictionary)

const GREENHOUSE_SETTINGS := ["humidity", "temperature", "light"]
const DUST_SPOTS := 12

var _mode := ""
var _done := false
var _elapsed := 0.0
var _time_left := 0.0
var _duration := 15.0
var _zone := 0.5
var _cursor := 0.5
var _in_zone := 0.0
var _phase := "play"
var _recipe := {}
var _guess := {"humidity": 0, "temperature": 0, "light": 0}
var _value_labels := {}
var _sliders := {}
var _channels: Array = []
var _needs := {}
var _budget := 0.0
var _dust_spots: Array[Vector2] = []
var _dust_cleaned: Array[bool] = []
var _instructions: Label
var _timer_label: Label
var _content: VBoxContainer


func start(mode: String, context: Dictionary = {}) -> void:
	_mode = mode
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_shell()

	match _mode:
		"scrub":
			_start_scrub()
		"hold_zone":
			_start_hold_zone(context)
		"greenhouse_controls":
			_start_greenhouse_controls()
		"valves":
			_start_valves()
		"power":
			_start_power(context)
		_:
			push_error("Unknown colony minigame: " + _mode)
			_finish(0.0)


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color(0.025, 0.055, 0.09, 0.97)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	center.add_child(_content)

	_instructions = Label.new()
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_instructions)
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_timer_label)


func _start_scrub() -> void:
	_instructions.text = "Hold the left mouse button and scrub across every dust patch."
	_time_left = 15.0
	for i in DUST_SPOTS:
		_dust_spots.append(Vector2(randf_range(0.2, 0.8), randf_range(0.25, 0.78)))
		_dust_cleaned.append(false)
	queue_redraw()


func _start_hold_zone(context: Dictionary) -> void:
	_instructions.text = "Move the cursor into the moving green band and keep it there."
	_duration = float(context.get("duration", 15.0))
	_time_left = _duration
	_cursor = 0.5
	queue_redraw()


func _start_greenhouse_controls() -> void:
	_instructions.text = "Memorize the greenhouse settings."
	_phase = "memorize"
	_time_left = 3.5
	for setting in GREENHOUSE_SETTINGS:
		_recipe[setting] = randi_range(1, 5)
	_instructions.text += "\nHumidity %d     Temperature %d     Light %d" % [
		_recipe["humidity"], _recipe["temperature"], _recipe["light"]]

	var rows := VBoxContainer.new()
	rows.name = "GreenhouseRows"
	rows.visible = false
	_content.add_child(rows)
	for setting in GREENHOUSE_SETTINGS:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var name_label := Label.new()
		name_label.text = setting.capitalize()
		var value := Label.new()
		value.text = "0"
		value.custom_minimum_size.x = 40
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var minus := Button.new()
		minus.text = "-"
		minus.pressed.connect(_adjust_greenhouse_setting.bind(setting, -1))
		var plus := Button.new()
		plus.text = "+"
		plus.pressed.connect(_adjust_greenhouse_setting.bind(setting, 1))
		_value_labels[setting] = value
		row.add_child(name_label)
		row.add_child(minus)
		row.add_child(value)
		row.add_child(plus)
		rows.add_child(row)
	var submit := Button.new()
	submit.text = "Set greenhouse controls"
	submit.pressed.connect(_submit_greenhouse_controls)
	rows.add_child(submit)


func _start_valves() -> void:
	_instructions.text = "Rotate each filter until every valve reads 0 degrees."
	_time_left = 25.0
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(row)
	for i in 5:
		var button := Button.new()
		button.custom_minimum_size = Vector2(76, 76)
		button.pressed.connect(_rotate_valve.bind(i))
		row.add_child(button)
		_sliders["valve_%d" % i] = {"angle": randi_range(1, 3) if i < 4 else randi_range(0, 3), "button": button}
	_refresh_valves()


func _start_power(context: Dictionary) -> void:
	_channels = context.get("channels", ["life_support", "greenhouse", "lab", "comms"])
	_needs = context.get("needs", {})
	_budget = float(context.get("budget", 60.0))
	_time_left = 60.0
	_instructions.text = "Split the limited power between systems. Total allocation cannot exceed %d." % int(_budget)

	for channel in _channels:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s (needs %d)" % [
			String(channel).replace("_", " ").capitalize(), int(_needs.get(channel, 0))]
		name_label.custom_minimum_size.x = 190
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size.x = 240
		slider.value_changed.connect(_power_changed.bind(channel))
		var value_label := Label.new()
		value_label.text = "0"
		value_label.custom_minimum_size.x = 36
		row.add_child(name_label)
		row.add_child(slider)
		row.add_child(value_label)
		_content.add_child(row)
		_sliders[channel] = slider
		_value_labels[channel] = value_label

	var confirm := Button.new()
	confirm.text = "Confirm allocation"
	confirm.pressed.connect(_confirm_power)
	_content.add_child(confirm)
	_update_power_labels()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _mode == "hold_zone":
		_zone = 0.5 + 0.32 * sin(_elapsed * 1.4) + 0.08 * sin(_elapsed * 3.3)
		_cursor = clampf(get_local_mouse_position().y / maxf(size.y, 1.0), 0.0, 1.0)
		if absf(_cursor - _zone) < 0.08:
			_in_zone += delta
		queue_redraw()
	if _mode in ["scrub", "hold_zone", "valves"]:
		_timer_label.text = "Time left: %ds" % maxi(0, int(_time_left))

	if _mode == "greenhouse_controls" and _phase == "memorize":
		_time_left -= delta
		if _time_left <= 0.0:
			_phase = "mix"
			_instructions.text = "Now recreate the settings from memory."
			_content.get_node("GreenhouseRows").show()
	elif _mode == "scrub" or _mode == "hold_zone" or _mode == "valves":
		_time_left -= delta
		if _time_left <= 0.0:
			_timeout()
	elif _mode == "power":
		_time_left -= delta
		_timer_label.text = "Time left: %ds" % maxi(0, int(_time_left))
		if _time_left <= 0.0:
			_confirm_power()


func _input(event: InputEvent) -> void:
	if _done or _mode != "scrub":
		return
	var scrub := false
	var position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		scrub = true
		position = event.position
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		scrub = true
		position = event.position
	if scrub:
		_scrub_at(position)


func _scrub_at(position: Vector2) -> void:
	var normalized := position / Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	for i in _dust_spots.size():
		if not _dust_cleaned[i] and _dust_spots[i].distance_to(normalized) < 0.07:
			_dust_cleaned[i] = true
			queue_redraw()
	var cleaned := 0
	for cleared in _dust_cleaned:
		if cleared:
			cleaned += 1
	if cleaned == DUST_SPOTS:
		_finish(1.0)


func _adjust_greenhouse_setting(setting: String, amount: int) -> void:
	_guess[setting] = clampi(int(_guess[setting]) + amount, 0, 6)
	_value_labels[setting].text = str(_guess[setting])


func _submit_greenhouse_controls() -> void:
	var difference := 0
	for setting in GREENHOUSE_SETTINGS:
		difference += absi(int(_guess[setting]) - int(_recipe[setting]))
	_finish(1.0 - float(difference) / 15.0)


func _refresh_valves() -> void:
	for key in _sliders:
		var valve: Dictionary = _sliders[key]
		valve["button"].text = "%d°" % (int(valve["angle"]) * 90)


func _rotate_valve(index: int) -> void:
	var key := "valve_%d" % index
	var valve: Dictionary = _sliders[key]
	valve["angle"] = (int(valve["angle"]) + 1) % 4
	_sliders[key] = valve
	_refresh_valves()
	var aligned := true
	for valve_key in _sliders:
		if int(_sliders[valve_key]["angle"]) != 0:
			aligned = false
			break
	if aligned:
		_finish(0.6 + 0.4 * _time_left / 25.0)


func _used_power() -> float:
	var total := 0.0
	for channel in _channels:
		total += float(_sliders[channel].value)
	return total


func _power_changed(value: float, channel: String) -> void:
	var overflow := _used_power() - _budget
	if overflow > 0.0:
		_sliders[channel].set_value_no_signal(maxf(0.0, value - overflow))
	_update_power_labels()


func _update_power_labels() -> void:
	for channel in _channels:
		_value_labels[channel].text = str(int(_sliders[channel].value))
	_timer_label.text = "Available power: %d / %d" % [
		int(maxf(0.0, _budget - _used_power())), int(_budget)]


func _confirm_power() -> void:
	if _done:
		return
	var allocation := {}
	var matched := 0.0
	var counted := 0
	for channel in _channels:
		allocation[channel] = float(_sliders[channel].value)
		var need := float(_needs.get(channel, 0.0))
		if need > 0.0:
			matched += minf(float(allocation[channel]), need) / need
			counted += 1
	_finish(matched / maxi(counted, 1), allocation)


func _timeout() -> void:
	match _mode:
		"scrub":
			var cleaned := 0
			for cleared in _dust_cleaned:
				if cleared:
					cleaned += 1
			_finish(float(cleaned) / DUST_SPOTS)
		"hold_zone":
			_finish(_in_zone / maxf(_duration, 1.0))
		"valves":
			var aligned := 0
			for key in _sliders:
				if int(_sliders[key]["angle"]) == 0:
					aligned += 1
			_finish(0.5 * float(aligned) / _sliders.size())


func _finish(score: float, result: Dictionary = {}) -> void:
	if _done:
		return
	_done = true
	finished.emit(clampf(score, 0.0, 1.0), result)


func _draw() -> void:
	if _mode == "hold_zone":
		var x := size.x * 0.42
		var width := size.x * 0.16
		draw_rect(Rect2(x, 0.0, width, size.y), Color(0.2, 0.22, 0.28))
		draw_rect(Rect2(x, (_zone - 0.08) * size.y, width, 0.16 * size.y), Color(0.2, 0.8, 0.35, 0.9))
		var inside := absf(_cursor - _zone) < 0.08
		draw_rect(Rect2(x - 18.0, _cursor * size.y - 4.0, width + 36.0, 8.0), Color.WHITE if inside else Color(0.95, 0.35, 0.25))
	elif _mode == "scrub":
		for i in _dust_spots.size():
			var color := Color(0.2, 0.85, 0.55) if _dust_cleaned[i] else Color(0.82, 0.68, 0.44)
			draw_circle(_dust_spots[i] * size, 14.0, color)
			if not _dust_cleaned[i]:
				draw_circle(_dust_spots[i] * size, 7.0, Color(0.25, 0.2, 0.16))
