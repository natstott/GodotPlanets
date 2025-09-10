extends Camera3D
var rotate_speed = 0.03
var move_speed = 0.05
@export var mousespeed =0.01;
var planet_Multimesh :RID
var watchingplanet :int =0
var followdistance=10
var orbitalDistance = 1
var planetlastposition

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	planetlastposition=Vector3(0,0,0)
	

func _process(delta):
	#Testing following object
	var flyspeed=1
	var buffer=Get_Planet(watchingplanet) # xyz=position, w= size
	var planetPosition = Vector3(buffer.get(3), buffer.get(7),buffer.get(11))# based on transform buffer in multimesh
	var planetSize=buffer.get(0)
	look_at(Vector3(planetPosition),Vector3.UP,false)
	var planetvel=planetPosition-planetlastposition
	var watchingdistance=max(planetvel.length()*planetSize,planetSize*2)
	var targetPosition=planetPosition-(planetvel.normalized()*watchingdistance)
	position=position.lerp(targetPosition,delta*flyspeed)
	planetlastposition=planetPosition
	
	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		rotate_object_local(Vector3.UP, -rotate_speed)
	if Input.is_action_pressed("move_left"):
		rotate_object_local(Vector3.UP,rotate_speed)
	if Input.is_action_pressed("Forward"):
		followdistance-=move_speed

	if Input.is_action_pressed("back"):
		followdistance+=move_speed
	followdistance = clamp(followdistance,1,20)
	if Input.is_action_pressed("Up"):
		translate_object_local(Vector3(0,-move_speed,0))

	if Input.is_action_pressed("Down"):
		translate_object_local(Vector3(0,move_speed,0))	
	
	if Input.is_action_just_pressed("Changeplanet"):
		watchingplanet=(watchingplanet+1)%12

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT ):
		var screen=get_viewport().get_visible_rect().size
	
		var mouse =get_viewport().get_mouse_position()/screen-Vector2(0.5,0.5)
		rotate_object_local(Vector3.UP, -mouse.x*mousespeed)
		rotate_object_local(Vector3.RIGHT, -mouse.y*mousespeed)
		

		

func Set_multimesh(id):
	planet_Multimesh=id

func Get_Planet(planetid):
	var stride = 80 #20*4 bytes as using custom and color
	var buffer_rid = RenderingServer.multimesh_get_buffer_rd_rid(planet_Multimesh)
	var main_rd = RenderingServer.get_rendering_device()
	var buffer = main_rd.buffer_get_data(buffer_rid,planetid*stride,stride).to_float32_array()
		# parse the buffer data
	return buffer
