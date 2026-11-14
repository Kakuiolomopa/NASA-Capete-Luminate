extends Node2D

const O := Color("0a0a0f")   
const F := Color("e9efd8")  
const S := Color("c47fb3")   
const W := Color("ffffff") 


const OUTLINE := [
	[-5, 10], [-7, 14], [-8, 16], [-9, 18], [-9, 18], [-9, 18],
	[-9, 18], [-8, 16], [-7, 14], [-5, 10],
]

const TOP := -13 

var dots := 0:
	set(v):
		dots = v
		queue_redraw()

var _t := 0.0


func _ready():
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta):
	if not is_visible_in_tree():
		return
	_t += delta
	if _t >= 0.3:
		_t = 0.0
		dots = (dots + 1) % 4   


func _px(x: int, y: int, w: int, h: int, c: Color):
	draw_rect(Rect2(x, y, w, h), c)


func _draw():
	for i in OUTLINE.size():
		var r = OUTLINE[i]
		_px(r[0], TOP + i, r[1], 1, O)
	
	_px(-2, TOP + 10, 5, 1, O)
	_px(-1, TOP + 11, 3, 1, O)
	_px(0, TOP + 12, 1, 1, O)

	for i in range(1, OUTLINE.size() - 1):
		var r = OUTLINE[i]
		_px(r[0] + 1, TOP + i, r[1] - 2, 1, F)
	_px(-1, TOP + 10, 3, 1, F)
	_px(0, TOP + 11, 1, 1, F)

	_px(-6, TOP + 8, 12, 1, S)

	_px(-5, TOP + 1, 4, 1, W)


	for i in dots:
		_px(-5 + i * 4, TOP + 4, 2, 2, O)
	
