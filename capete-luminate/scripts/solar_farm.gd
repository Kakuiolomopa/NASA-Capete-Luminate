extends Node2D

const PANEL_SCENE := preload("res://scenes/solar_panel.tscn")

@export var panel_count := 15
@export var columns := 5
@export var spacing := Vector2(96, 80)


func _ready():
	add_to_group("solar_farm")
	z_index = 2
	for i in panel_count:
		var panel = PANEL_SCENE.instantiate()
		panel.panel_id = "solar_%d" % i
		panel.position = Vector2(
			(i % columns) * spacing.x,
			floori(i / float(columns)) * spacing.y
		)
		add_child(panel)
	refresh()


func refresh():
	for child in get_children():
		if child.has_method("set_unlocked"):
			child.set_unlocked(true)
