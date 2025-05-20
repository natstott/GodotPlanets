extends Marker3D
var rd: RenderingDevice
var rdlocal :RenderingDevice
var multimeshid :RID
@export var TestMesh :MeshInstance3D
@export var meshcount :int
var thismesh
var meshbuffer :RID
var firstrun :bool
var tempbuffer
var shader
var uniform_set
var velocities = []



func _ready():
	# Create a local rendering device.
	rd = RenderingServer.get_rendering_device() # global rd has access to main drawing thread
	rdlocal = RenderingServer.create_local_rendering_device()# local rd is in separate thread
	thismesh=CreateMultimesh(meshcount)
	makeComputeShader()
	


func _process(delta):
	# Create a compute pipeline
	var pipeline := rdlocal.compute_pipeline_create(shader)
	var compute_list := rdlocal.compute_list_begin()
	rdlocal.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rdlocal.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rdlocal.compute_list_dispatch(compute_list,meshcount/32+1 , 1, 1)
	rdlocal.compute_list_end()
	# Submit to GPU and wait for sync
	rdlocal.submit()
	rdlocal.sync()
	# return bytes from compute shader and send to meshbuffer
	var output_bytes := rdlocal.buffer_get_data(meshbuffer)
	var output := output_bytes.to_float32_array()
	RenderingServer.multimesh_set_buffer(thismesh,output)
	#print("instances: ",RenderingServer.multimesh_get_visible_instances(thismesh))



func makeComputeShader():
	
	var shader_file := load("res://Planetcompute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rdlocal.shader_create_from_spirv(shader_spirv)
	# Create a uniform to assign the buffer to the rendering device
	var meshuniform := RDUniform.new()
	meshuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	meshuniform.binding = 0 # this needs to match the "binding" in our shader file
	var bufferbytes=tempbuffer.to_byte_array()
	meshbuffer = rdlocal.storage_buffer_create(bufferbytes.size(), bufferbytes)
	meshuniform.add_id(meshbuffer)
	#velocities and accelerations in one buffer
	var velocityuniform := RDUniform.new()
	velocityuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velocityuniform.binding = 2 # this needs to match the "binding" in our shader file
	var velocitybytes=PackedFloat32Array(velocities).to_byte_array()
	var velocitybuffer = rdlocal.storage_buffer_create(velocitybytes.size(), velocitybytes)
	velocityuniform.add_id(velocitybuffer)
	var paramuniform := RDUniform.new()
	paramuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	paramuniform.binding =1
	var byte_array_int = PackedInt32Array([meshcount, 1, 1, 1] ).to_byte_array()
	var parambuffer = rdlocal.storage_buffer_create(byte_array_int.size(), byte_array_int)
	paramuniform.add_id(parambuffer)
	uniform_set = rdlocal.uniform_set_create([meshuniform, paramuniform, velocityuniform], shader, 0) 
	# the last parameter (the 0) needs to match the "set" in our shader file	



### Make test buffer in multimesh transform format
func maketestbuffer():
	var interimarray=[]
	for i in range (meshcount):
		var temppos = Transform3D().scaled(Vector3(0.2,0.2,0.2))
		var circrand=randf_range(-PI,PI)
		temppos = temppos.translated(Vector3((6+i/500.0)*cos(circrand), randf_range(-1.0,1.0),\
		 (6+i/500.0)*sin(circrand)))
		var tempbasis = temppos.basis
		# values laid out to match multimesh array
		interimarray.append_array([tempbasis.x.x, tempbasis.y.x, tempbasis.z.x, temppos.origin.x, \
	tempbasis.x.y, tempbasis.y.y, tempbasis.z.y, temppos.origin.y, \
	tempbasis.x.z, tempbasis.y.z, tempbasis.z.z, temppos.origin.z])
		velocities.append_array([8*temppos.origin.z+randf_range(-.1,.1),randf_range(-0.1,.1),-8*temppos.origin.x+randf_range(-.1,.1),1.0])
		velocities.append_array([0.0,0.0,0.0,0.0])
	var mesharray = PackedFloat32Array(interimarray)
	#var buffertest := rd.storage_buffer_create(mesharray.size(), mesharray)
	return mesharray
	#end of test buffer

func CreateMultimesh(size):
	multimeshid = RenderingServer.multimesh_create()
	RenderingServer.multimesh_allocate_data(\
	multimeshid,\
	size,\
	RenderingServer.MultimeshTransformFormat.MULTIMESH_TRANSFORM_3D,\
	false, false) #colours, custom
	tempbuffer = maketestbuffer()
	RenderingServer.multimesh_set_mesh(multimeshid, TestMesh.mesh.get_rid())
	RenderingServer.multimesh_set_buffer(multimeshid,tempbuffer)
	var aabb = Vector3(512.0, 1000.0, 512.0)
	var instance = RenderingServer.instance_create()
	var scenario =  get_world_3d().scenario
	RenderingServer.instance_set_custom_aabb(instance,AABB(Vector3.ZERO,aabb))
	RenderingServer.instance_set_scenario(instance,scenario)
	RenderingServer.instance_set_base(instance,multimeshid)
	return multimeshid
	
