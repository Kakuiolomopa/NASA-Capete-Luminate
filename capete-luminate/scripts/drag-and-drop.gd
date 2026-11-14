extends Panel

enum Outline_type{NONE,ONE_ITEM,MULTI_ITEM}
var drop_place
var initial_position:Vector2
var mouse:bool = false
var group_length:int
var target
static var order_next:int = 1
@export var group_accepts:String = "electrolyzer-slot"
@export var texture_load:Texture2D
@export var order:int = 1
@export var order_needed:bool = true
@export var deletion_needed:bool = true
@export var hide_mechanic:bool = true
@export var outline_type:Outline_type = Outline_type.NONE
@export var node_name:String
@export var related_to_object:bool = false
@export var meta:String


func _ready():
	await get_tree().process_frame
	initial_position = $".".position
	drop_place = get_tree().get_nodes_in_group(group_accepts)
	group_length = get_tree().get_node_count_in_group(group_accepts)


func _process(_delta):
	var touching = get_global_rect().has_point(get_global_mouse_position())
	if mouse:
		global_position = get_global_mouse_position() - size / 2
		if outline_type == Outline_type.MULTI_ITEM:
			for target in drop_place:
				var intersecting = get_global_rect().intersects(target.get_global_rect())
				target.get_node(node_name).visible = intersecting
	if Input.is_action_just_pressed("mouse_click"):
		if !mouse and touching:
			if !order_needed or order == order_next:
				mouse = true
				if(outline_type == Outline_type.ONE_ITEM):
					drop_place[0].show()
		elif mouse:
			mouse = false
			if outline_type == Outline_type.ONE_ITEM :
				drop_place[0].hide()
			var dropped = false
			for target in drop_place:
				if get_global_rect().intersects(target.get_global_rect()):
					if related_to_object:
						target = target.get_meta(meta)
					var style = StyleBoxTexture.new()
					style.texture = texture_load
					target.add_theme_stylebox_override("panel",style)
					if order_needed:
						order_next += 1
					dropped = true
					if(outline_type == Outline_type.MULTI_ITEM):
						for item in drop_place:
							item.get_node(node_name).hide()
					if deletion_needed:
						queue_free()
					else:
						position = initial_position
					break
			if !dropped:
				position = initial_position
			else:
				if outline_type == Outline_type.ONE_ITEM:
					drop_place[0].show()
