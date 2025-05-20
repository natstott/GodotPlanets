extends MultiMeshInstance3D
var rd: RenderingDevice
var rdlocal = RenderingServer.create_local_rendering_device()
var multimeshid :RID
var thismesh
var meshbuffer :RID
var firstrun :bool

func _ready():
	# Create a local rendering device.
	rd = RenderingServer.get_rendering_device() # global rd has access to main drawing thread
	rdlocal = RenderingServer.create_local_rendering_device()# local rd is in separate thread
	thismesh=self.get_multimesh().get_rid()
	meshbuffer = RenderingServer.multimesh_get_buffer_rd_rid(thismesh)
	var output_bytes = RenderingServer.multimesh_get_buffer(thismesh)
	#prove that multimesh exists in this context
	print("Output multimesh_get_buffer: ", output_bytes)
	var output := rd.buffer_get_data(meshbuffer).to_float32_array()
	print("Output rd.get_buffer: ", output)
	var outputlocal := rdlocal.buffer_get_data(meshbuffer).to_float32_array()
	print("Output rdlocal.get_buffer: ", outputlocal)	
	firstrun= true
	makeComputeShader()
	


func _process(delta):
	pass
	#print("instances: ",RenderingServer.multimesh_get_visible_instances(thismesh))
	#rdlocal.submit()
	#rdlocal.sync()
	
	
func CPUrotation():
	#var meshbuffer = RenderingServer.multimesh_get_buffer_rd_rid(thismesh)
	
	#var multimeshArray = RenderingServer.multimesh_get_buffer(thismesh)
	#print ("RID: ", meshbuffer, " Array: ", multimeshArray)
	var interimarray=[]
	var TIME = Time.get_ticks_msec()/1000.0
	for i in range (8):
		var temppos = Transform3D()
		temppos = temppos.translated(Vector3(cos(TIME+i), 1,\
		 sin(TIME+i)))
		var tempbasis = temppos.basis
		interimarray.append_array([tempbasis.x.x, tempbasis.y.x, tempbasis.z.x, temppos.origin.x, \
	tempbasis.x.y, tempbasis.y.y, tempbasis.z.y, temppos.origin.y, \
	tempbasis.x.z, tempbasis.y.z, tempbasis.z.z, temppos.origin.z])
	
	var mesharray = PackedFloat32Array(interimarray)
	RenderingServer.multimesh_set_buffer(thismesh,mesharray)
	

func makeComputeShader():
	
	var shader_file := load("res://Planetcompute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(meshbuffer)
	print("uniforms: ", uniform, "RIDs: ", uniform.get_ids())
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) 
	# the last parameter (the 0) needs to match the "set" in our shader file	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1, 1, 1)
	rd.compute_list_end()
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()


### Make test buffer in multimesh transform format
func maketestbuffer():
	var interimarray=[]
	var TIME = Time.get_ticks_msec()/1000.0
	for i in range (8):
		var temppos = Transform3D()
		temppos = temppos.translated(Vector3(cos(TIME+i), 1,\
		 sin(TIME+i)))
		var tempbasis = temppos.basis
		interimarray.append_array([tempbasis.x.x, tempbasis.y.x, tempbasis.z.x, temppos.origin.x, \
	tempbasis.x.y, tempbasis.y.y, tempbasis.z.y, temppos.origin.y, \
	tempbasis.x.z, tempbasis.y.z, tempbasis.z.z, temppos.origin.z])
	
	var mesharray = PackedFloat32Array(interimarray).to_byte_array()
	var buffertest := rd.storage_buffer_create(mesharray.size(), mesharray)
	#end of test buffer
