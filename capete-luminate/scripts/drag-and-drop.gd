extends Panel

signal placed(order: int)
signal item_dropped(item, drop_target, applied_target)

enum OutlineType { NONE, ONE_ITEM, MULTI_ITEM }
@export var group_accepts:String = "electrolyzer-slot"
@export var texture_load:Texture2D
@export var order:int = 1
@export var order_needed:bool = true
@export var deletion_needed:bool = true
@export var hide_mechanic:bool = true
@export var outline_type:OutlineType = OutlineType.NONE
@export var node_name:String
@export var related_to_object:bool = false
@export var meta:String
var drop_place
var initial_global_position:Vector2
var mouse:bool = false
var group_length:int
var target


func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	initial_global_position = global_position
	drop_place = get_tree().get_nodes_in_group(group_accepts)
	group_length = get_tree().get_node_count_in_group(group_accepts)
	if order_needed and order <= GameState.moxie_progress():
		_restore_placed()


func _restore_placed():
	for target in drop_place:
		var style = StyleBoxTexture.new()
		style.texture = texture_load
		target.add_theme_stylebox_override("panel", style)
		target.show()
	queue_free()


func _process(_delta):
	var touching = get_global_rect().has_point(get_global_mouse_position())
	if mouse:
		global_position = get_global_mouse_position() - size / 2
		if outline_type == OutlineType.MULTI_ITEM:
			for target in drop_place:
				var intersecting = get_global_rect().intersects(target.get_global_rect())
				target.get_node(node_name).visible = intersecting
	if Input.is_action_just_pressed("mouse_click") and not mouse and touching:
		if not order_needed or order == GameState.moxie_progress() + 1:
			mouse = true
			if outline_type == OutlineType.ONE_ITEM:
				drop_place[0].show()
	if Input.is_action_just_released("mouse_click") and mouse:
		mouse = false
		if outline_type == OutlineType.ONE_ITEM:
			drop_place[0].hide()
		var dropped = false
		for target in drop_place:
			if get_global_rect().intersects(target.get_global_rect()):
				var drop_target = target
				if related_to_object:
					target = target.get_meta(meta)
				var style = StyleBoxTexture.new()
				style.texture = texture_load
				target.add_theme_stylebox_override("panel", style)
				if order_needed:
					if GameState.moxie_broken:
						GameState.moxie_repair_step = maxi(GameState.moxie_repair_step, order)
					else:
						GameState.story_step = maxi(GameState.story_step, order)
					placed.emit(order)
				item_dropped.emit(self, drop_target, target)
				dropped = true
				if outline_type == OutlineType.MULTI_ITEM:
					for item in drop_place:
						item.get_node(node_name).hide()
				if deletion_needed:
					queue_free()
				else:
					global_position = initial_global_position
				break
		if not dropped:
			global_position = initial_global_position
		elif outline_type == OutlineType.ONE_ITEM:
			drop_place[0].show()
