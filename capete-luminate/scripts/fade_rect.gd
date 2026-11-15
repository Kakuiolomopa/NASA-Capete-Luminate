extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var player = get_tree().get_first_node_in_group("player")


func fade_to_black(to_base: bool):
	await _fade(Color.BLACK, 1.5)
	if player:
		if to_base:
			player.global_position = GameState.base_pos
		else:
			player.global_position = GameState.outside_pos
	await _fade(Color.TRANSPARENT, 1.5)
	if player:
		player.controls_enabled = true


func fade_sleep(out_time := 0.9, hold := 0.5, in_time := 0.9):
	if player:
		player.controls_enabled = false
	await _fade(Color.BLACK, out_time)
	await get_tree().create_timer(hold).timeout
	await _fade(Color.TRANSPARENT, in_time)
	if player:
		player.controls_enabled = true


func fade_black_flash(out_time := 0.12, hold := 0.06, in_time := 0.2):
	var was_enabled := true
	if player:
		was_enabled = player.controls_enabled
		player.controls_enabled = false
	await _fade(Color.BLACK, out_time)
	await get_tree().create_timer(hold).timeout
	await _fade(Color.TRANSPARENT, in_time)
	if player:
		player.controls_enabled = was_enabled


func _fade(color: Color, time: float):
	var tween := create_tween()
	tween.tween_property(fade_rect, "color", color, time)
	await tween.finished
