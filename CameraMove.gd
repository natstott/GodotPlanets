extends Camera3D
var rotate_speed = 0.03
var move_speed = 0.05

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func _physics_process(delta):
	# We create a local variable to store the input direction.


	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		rotate_y(-rotate_speed)
	if Input.is_action_pressed("move_left"):
		rotate_y(rotate_speed)
	if Input.is_action_pressed("Forward"):
		translate_object_local(Vector3(0,0,-move_speed))

	if Input.is_action_pressed("back"):
		translate_object_local(Vector3(0,0,move_speed))
		
	if Input.is_action_pressed("Up"):
		translate_object_local(Vector3(0,-move_speed,0))

	if Input.is_action_pressed("Down"):
		translate_object_local(Vector3(0,move_speed,0))	
