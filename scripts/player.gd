extends CharacterBody2D


const SPEED = 80.0
var controls_enabled := true
var last_direction: Vector2= Vector2.RIGHT


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea


func _ready():
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	if not controls_enabled or Dialogue.is_open:
		velocity = Vector2.ZERO
		_force_idle()
		move_and_slide()
		return

	process_movement()
	process_animation()
	move_and_slide()
	
func _force_idle():
	var a: AnimatedSprite2D = $AnimatedSprite2D
	var cur := String(a.animation)
	if cur.begins_with("Run"):
		var dir := cur.get_slice(" ", 1)
		a.play("Idle " + dir)
	
	
	
# --------------------------------------------------
# MOVEMENT & ANIMATION
# --------------------------------------------------
	
func process_movement() -> void:
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	
	
func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("Run", last_direction)
	else:
		play_animation("Idle", last_direction)
	
func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + " right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + " up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + " down")
		
# --------------------------------------------------
# INTERACTION
# --------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or Dialogue.is_open:
		return
	if event.is_action_pressed("interact"):
		try_interact()

func try_interact() -> void:
	#daca corpul area un interaction area
	for area in interaction_area.get_overlapping_areas():
		var target = area.get_parent()
		if target.has_method("interact"):
			target.interact()
			return
			
	for body in interaction_area.get_overlapping_bodies():
		if body.has_method("interact"):
			body.interact()
			return
			
func freeze_idle(_direction := "down"):
	controls_enabled = false
	velocity = Vector2.ZERO
	var a: AnimatedSprite2D = $AnimatedSprite2D
	var name := String(a.animation)         
	var dir := name.get_slice(" ", 1)        
	if dir == "":
		dir = "down"
	a.play("Idle " + dir)
