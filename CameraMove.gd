extends Camera3D
var rotate_speed = 0.03
var move_speed = 0.05
@export var mousespeed =0.01;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func _physics_process(delta):
	# We create a local variable to store the input direction.


	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		rotate_object_local(Vector3.UP, -rotate_speed)
	if Input.is_action_pressed("move_left"):
		rotate_object_local(Vector3.UP,rotate_speed)
	if Input.is_action_pressed("Forward"):
		translate_object_local(Vector3(0,0,-move_speed))

	if Input.is_action_pressed("back"):
		translate_object_local(Vector3(0,0,move_speed))
		
	if Input.is_action_pressed("Up"):
		translate_object_local(Vector3(0,-move_speed,0))

	if Input.is_action_pressed("Down"):
		translate_object_local(Vector3(0,move_speed,0))	
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT ):
		var screen=get_viewport().get_visible_rect().size
	
		var mouse =get_viewport().get_mouse_position()/screen-Vector2(0.5,0.5)
		rotate_object_local(Vector3.UP, -mouse.x*mousespeed)
		rotate_object_local(Vector3.RIGHT, -mouse.y*mousespeed)
		
