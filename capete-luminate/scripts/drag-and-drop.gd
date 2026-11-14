extends Panel

var texture:Texture2D = $".".texture
var drop_place
var initial_position:Vector2
var mouse:bool = false
static var order_next:int = 1
@export var group_accepts:String = "electrolyzer-slot"
@export var texture_load:Texture2D
@export var order:int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	order_next = 1
	await get_tree().process_frame
	initial_position = $".".position
	drop_place = get_tree().get_first_node_in_group(group_accepts)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var touching = get_global_rect().has_point(get_global_mouse_position())
	if Input.is_action_just_pressed("mouse_click") && touching && order==order_next:
		mouse=!mouse
		if !mouse:
			if($'.'.get_global_rect().intersects(drop_place.get_global_rect())):
				var style = StyleBoxTexture.new()
				style.texture = texture_load
				drop_place.add_theme_stylebox_override("panel",style)
				order_next+=1
				queue_free()
			else:
				drop_place.hide()
			$".".position = initial_position
	if mouse:
		drop_place.show()
		global_position = get_global_mouse_position() - size / 2
		
