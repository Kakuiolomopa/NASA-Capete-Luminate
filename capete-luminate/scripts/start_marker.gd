extends Node2D

const FONT_PATH := "res://assets/Silkscreen/Silkscreen-Regular.ttf"
const C_LINE := Color("2fe0f0")
const C_TEXT := Color("bff6ff")

var _time := 0.0
var _font: Font


func _ready():
	add_to_group("start_marker")
	z_index = 10
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	queue_redraw()


func _process(delta):
	_time += delta
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > 180.0:
		dismiss()
		return
	queue_redraw()


func dismiss():
	if GameState.start_marker_seen:
		hide()
		return
	GameState.start_marker_seen = true
	hide()


func _draw():
	if _font == null:
		return
	var bob := sin(_time * 3.0) * 3.0
	var pulse := 0.55 + sin(_time * 3.0) * 0.15
	draw_line(Vector2(0, -36 + bob), Vector2(0, -14 + bob), Color(C_LINE, pulse), 3.0)
	draw_arc(Vector2(0, bob), 20.0, 0.0, TAU, 32, Color(C_LINE, pulse), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -10 + bob),
		Vector2(10, bob),
		Vector2(0, 10 + bob),
		Vector2(-10, bob),
	]), Color(C_LINE, 0.9))
	draw_string(_font, Vector2(-28, 48 + bob), "START",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_TEXT)
