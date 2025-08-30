extends Marker3D

@export var TestMesh :MeshInstance3D
@export var meshcount :int
@export var cameralink :Camera3D
#@export var testlayermaterial :Material
#var testlayernum=0.0
var rd: RenderingDevice
#var multimeshid :RID
var compute_list
var pipeline
var planet_Multimesh :RID
var meshbuffer :RID
var firstrun :bool
var tempbuffer
var shader
var uniform_set
var verletpipeline
var verletshader
var verletuniform_set
var velocities = []
var BigG = 0.667; #0.00066743
var DeltaTime=0.001
var solarmass=50000.0
var num_planets=15
var paused=false
var firstframe = true






func _ready():
	# Create a global rendering device which can access multimesh data
	rd = RenderingServer.get_rendering_device() # global rd has access to main drawing thread
	var texturearray = create_texturearray() #doing this first to count number of planets!
	var meshmaterial=TestMesh.get_active_material( 0)
	meshmaterial.set_shader_parameter("Texture2DArrayParameter", texturearray)
	meshmaterial.set_shader_parameter("Total_Layers", num_planets*1.0)
	
	#print("v3: ", velocities[3])
	planet_Multimesh=CreateMultimesh(meshcount)
	cameralink.Set_multimesh(planet_Multimesh)
	maketestbuffer() #starting values
	makeComputeShader()
	#tempbuffer.clear() #free memory
	#testlayermaterial.set_shader_parameter("Texture2DArrayParameter", texturearray)
	print("pipeline ready:" ,rd.compute_pipeline_is_valid(pipeline))
	print("verletpipeline ready:" ,rd.compute_pipeline_is_valid(verletpipeline))	



func _process(_delta):
	# Create a compute pipeline
	if(!paused and !firstframe):
		var dispatchnumber=meshcount # not updating sun
		compute_list = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_dispatch(compute_list,dispatchnumber/32+1 , 1, 1)
		rd.compute_list_end()
		compute_list = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, verletpipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_dispatch(compute_list,dispatchnumber/32+1 , 1, 1)
		rd.compute_list_end()
	else : firstframe=false # planet data doesnt seem to be initialised on first frame
	
	if Input.is_action_just_pressed("Pause"): paused =!paused
	


func makeComputeShader():
	
	var shader_file := load("res://Planetcompute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	shader = rd.shader_create_from_spirv(shader_spirv)
	shader_file = load("res://PlanetVerlet.glsl")
	shader_spirv = shader_file.get_spirv()
	verletshader = rd.shader_create_from_spirv(shader_spirv)
	
	# Create a uniform to assign the multimesh buffer to the rendering device
	var meshuniform := RDUniform.new()
	meshuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	meshuniform.binding = 0 # this needs to match the "binding" in our shader file
	meshbuffer=RenderingServer.multimesh_get_buffer_rd_rid(planet_Multimesh)
	meshuniform.add_id(meshbuffer)
	
	#velocities and accelerations in one buffer
	var velocityuniform := RDUniform.new()
	velocityuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velocityuniform.binding = 2 # this needs to match the "binding" in our shader file
	var velocitybytes=PackedFloat32Array(velocities).to_byte_array()
	var velocitybuffer = rd.storage_buffer_create(velocitybytes.size(), velocitybytes)
	velocityuniform.add_id(velocitybuffer)
	
	#uint planetcount;  #uint dummy2;  #uint dummy3;  #uint dummy4;
	#float BigG;  #float DummyMass;  #float DeltaTime;  #float packing(so 4floats);
	var paramuniform := RDUniform.new()
	paramuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	paramuniform.binding =1
	var byte_array_int = PackedInt32Array([meshcount, 1, 1, 1] ).to_byte_array()
	var byte_array_float = PackedFloat32Array([BigG, 1.0, DeltaTime, 1.0]).to_byte_array()
	var byte_array_params=byte_array_int+byte_array_float
	var parambuffer = rd.uniform_buffer_create(byte_array_params.size(), byte_array_params)
	paramuniform.add_id(parambuffer)
	
	
	uniform_set = rd.uniform_set_create([meshuniform, paramuniform, velocityuniform], shader, 0) 
	pipeline = rd.compute_pipeline_create(shader)
	verletuniform_set = rd.uniform_set_create([meshuniform, paramuniform, velocityuniform], verletshader, 0) 
	verletpipeline= rd.compute_pipeline_create(verletshader)

### Make data buffer in mutimesh
func maketestbuffer():
	var suns=1
	var planetindex=0
	if(suns>0):
		#Make the Suns
		var temppos = Transform3D.IDENTITY.scaled(Vector3(3,3,3))
		makeplanet(temppos,[0.0,0.0,0.0,solarmass],planetindex)
	
	var totalplanetmass=0
	for i in range (1,meshcount):
		var circrand=randf_range(-PI,PI)
		var massrand=randf_range(.3,0.5)
		var radiusrand=randf_range(20.,34.) #asteroid belt
		if (i<num_planets):
			radiusrand=3+2**i
			massrand=randf_range(50,200)

		var planetvel=sqrt(BigG*solarmass/radiusrand) # assume orbital velocity
		totalplanetmass+=massrand
		var size=sqrt(massrand)*0.1
		var Planetscale =Vector3(size,size,size)
		#if size<1:
		#	Planetscale*=Vector3(randf_range(0.1,3),randf_range(0.1,3),randf_range(0.1,3))
	
		var temppos = Transform3D.IDENTITY.scaled(Planetscale)
		temppos = temppos.translated(Vector3(radiusrand*cos(circrand), randf_range(-.10,.10), radiusrand*sin(circrand)))
		var planetvelocity =[-planetvel*sin(circrand),0.0, planetvel*cos(circrand),massrand]
		#velocities.append_array([0.0,0.0,0.0,0.0]) #zero acceleration
		planetindex+=1
		makeplanet(temppos,planetvelocity,planetindex)
	
	#var mesharray = PackedFloat32Array(interimarray)
	print ("planets total mass: ",totalplanetmass)
	#return mesharray
	#end of test buffer

func makeplanet(planettransform,velocity,planetindex):
	RenderingServer.multimesh_instance_set_transform(planet_Multimesh, planetindex, planettransform)
	var planetcolor
	var rotation_speed=randf_range(0.1,5)
	if planetindex<num_planets:
		planetcolor=Color(planetindex,0,rotation_speed,0)
	else:
		var moonimages=randi_range(10,14)
		planetcolor=Color(moonimages,0,rotation_speed,0)
	RenderingServer.multimesh_instance_set_color(planet_Multimesh,planetindex, planetcolor)
	# Array 1:3 velocity, 4-mass 5:7 acceleration, 8 free
	velocities.append_array(velocity) #x,y,z,mass
	velocities.append_array([0.0,0.0,0.0,0.0]) #zero acceleration


func CreateMultimesh(size):
	var multimeshid = RenderingServer.multimesh_create()
	RenderingServer.multimesh_allocate_data(\
	multimeshid,\
	size,\
	RenderingServer.MultimeshTransformFormat.MULTIMESH_TRANSFORM_3D,\
	true, true,false) #colours, custom, useindirect
	
	RenderingServer.multimesh_set_mesh(multimeshid, TestMesh.mesh.get_rid())
	#RenderingServer.multimesh_set_buffer(multimeshid,tempbuffer)
	var aabb = Vector3(512.0, 1000.0, 512.0)
	var scenario =  get_world_3d().scenario
	var instance = RenderingServer.instance_create2(multimeshid, scenario)
	RenderingServer.instance_set_custom_aabb(instance,AABB(-aabb,2*aabb))
	return multimeshid
	
#Move to planet_data
func create_texturearray():
	# textures from https://www.solarsystemscope.com/textures/
	var texturearray :Texture2DArray = Texture2DArray.new()
	var images :Array[Image] = []
	var imagelist =["4k_sun.jpg", "4k_mercury.jpg", "4k_venus_clouds.jpg", \
	"4k_earth_daymap.jpg","4k_mars.jpg","4k_jupiter.jpg", "4k_saturn.jpg", \
	"4k_uranus.jpg", "4k_neptune.jpg", "4k_pluto.jpg", \
	"4k_moon.jpg","4k_ceres_fictional.jpg","4k_eris_fictional.jpg","4k_makemake_fictional.jpg",  "4k_haumea_fictional.jpg" ]
	
	#var imagelist =["2k_sun.jpg","testerror.jpg", "mercury.png", "venus.png", "Earth.jpeg","Mars.jpeg","Jupiter.jpeg", "saturn.jpg", "uranus.jpg","moon.png" ]
	
	for filename in imagelist:
		var img=Image.new()
		var file_path="res://"+filename
		if ResourceLoader.exists(file_path):
			var temptexture = load(file_path)
			img = temptexture.get_image()
			#Dont need these steps if all images same size and format
			#img.decompress()
			#img.resize(4096,2048)
			#img.convert(Image.FORMAT_RGB8)
			img.generate_mipmaps()
			images.append(img)
			print("Loaded image from: %s" % filename)
		else:print("Error loading: %s" %filename )
		
	num_planets=images.size()
	print("numer of planet ", num_planets)
	texturearray.create_from_images(images)
	#texturearray.save_png("res:\\testtexturearray")
	return texturearray
	
	


func _on_h_slider_value_changed(value: float) -> void:
	TestMesh.get_active_material(0).set_shader_parameter("sphere_radius", value)
