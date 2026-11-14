extends Panel

var texture:Texture2D = $".".texture
var drop_place
var initial_position:Vector2
var mouse:bool = false
var group_length:int
static var order_next:int = 1
@export var group_accepts:String = "electrolyzer-slot"
@export var texture_load:Texture2D
@export var order:int = 1
@export var order_needed:bool = true
@export var deletion_needed:bool = true


# Called when the node enters the scene tree for the first time.
func _ready():
	order_next = 1
	await get_tree().process_frame
	initial_position = $".".position
	drop_place = get_tree().get_nodes_in_group(group_accepts)
	group_length = get_tree().get_node_count_in_group(group_accepts)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if mouse:
		global_position = get_global_mouse_position() - size / 2
	if Input.is_action_just_pressed("mouse_click"):
		var touching = get_global_rect().has_point(get_global_mouse_position())
		if !mouse and touching:
			if !order_needed or order == order_next:
				mouse = true
		elif mouse:
			mouse = false
			var dropped = false
			for target in drop_place:
				if get_global_rect().intersects(target.get_global_rect()):
					var style = StyleBoxTexture.new()
					style.texture = texture_load
					target.add_theme_stylebox_override("panel", style)
					if order_needed:
						order_next += 1
					dropped = true
					if deletion_needed:
						queue_free()
					else:
						position = initial_position
					break
			if !dropped:
				position = initial_position
