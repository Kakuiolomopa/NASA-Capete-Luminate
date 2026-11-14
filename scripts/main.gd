extends Node2D

@onready var player = $Player


func _ready():
	SaveManager.apply_pending(player)


func _input(event):
	pass
