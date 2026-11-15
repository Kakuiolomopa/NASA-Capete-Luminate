extends CanvasLayer

signal closed

# Called when the node enters the scene tree for the first time.
func _ready():
	layer = 20


func _on_back_button_pressed():
	hide()
	closed.emit()
