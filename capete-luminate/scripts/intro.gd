extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const SPEAKER := "Miss M."
const FRAME_SIZE := Vector2(720, 360)
const C_LINE := Color("2fe0f0")

const STORY := [
	{"img": "res://assets/intro/scene1.png", "text": "Greetings, {name}, I’m terribly sorry for this being our first meeting. I would’ve appreciated talking face to face, but this will have to do. "},
	{"text": "You have been previously informed that your mission is to start a colony on Mars…"},
	{"text": "Well, as you know, every country on earth has been battling with various global problems,  but most importantly, global warming and pollution have spiralled out of control."},
	{"img": "res://assets/intro/scene2.png", "text": "This has put the whole world on edge, living in general has become more and more difficult for the everyday person. So we had to make a very tough decision…"},
	{"text": "We’ve put a good amount of our last resources into the very ship you’re in."},
	{"text": "And so, you’re going there with two goals in mind."},
	{"img": "res://assets/intro/scene3.png", "text": " First, there’s an old base that was set up a few decades ago, you need to repair it and, after you’re done with that, you need to send a message reporting back to earth. "},
	{"text": "I’ll tell you this now in order to make make things easier for you."},
	{"img": "res://assets/intro/scene4.png", "text": "Somewhere in the base there’s a control room, you need to find it and access the base’s control operating system."},
	{"text": "Your other task is related to the status of the earth… "},
	{"text": "You need to find and collect samples of ores you find on Mars to bring back to us. The earth is running out of resources and we need to see if the ores there can help our planet recover."},
	{"img": "res://assets/intro/scene5.png", "text": "Now, we need to cut this short. Not to worry you, but you are the very last hope for us on earth. {name}, you are the very best earth still has to offer."},
	{"text": "We believe in you."},
]

var _pic: TextureRect
var _fade: ColorRect
var _frame_box: Control


func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vp := get_viewport_rect().size
	_frame_box = Control.new()
	_frame_box.size = FRAME_SIZE
	_frame_box.position = Vector2((vp.x - FRAME_SIZE.x) / 2.0, 40)
	add_child(_frame_box)

	var border := ColorRect.new()
	border.color = C_LINE
	border.size = FRAME_SIZE
	_frame_box.add_child(border)
	var inner := ColorRect.new()
	inner.color = Color.BLACK
	inner.position = Vector2(4, 4)
	inner.size = FRAME_SIZE - Vector2(8, 8)
	_frame_box.add_child(inner)

	_pic = TextureRect.new()
	_pic.position = Vector2(4, 4)
	_pic.size = FRAME_SIZE - Vector2(8, 8)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.clip_contents = true
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pic.modulate.a = 0.0
	_frame_box.add_child(_pic)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_run()


func _run():
	await _fade_to(0.0, 1.0)
	await get_tree().create_timer(0.5).timeout

	for line in STORY:
		if line.has("img"):
			await _change_image(line["img"])
		var txt: String = line["text"].replace("{name}", GameState.player_name)
		await Dialogue.say([txt], SPEAKER)

	await _fade_to(1.0, 1.2)
	get_tree().change_scene_to_file(GAME_SCENE)


func _change_image(path: String):
	if _pic.texture != null:
		var t := create_tween()
		t.tween_property(_pic, "modulate:a", 0.0, 0.3)
		await t.finished
	if ResourceLoader.exists(path):
		_pic.texture = load(path)
	var t2 := create_tween()
	t2.tween_property(_pic, "modulate:a", 1.0, 0.4)
	await t2.finished


func _fade_to(a: float, time: float):
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", a, time)
	await t.finished


func _unhandled_input(event):
	# Esc sare peste intro
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(GAME_SCENE)
