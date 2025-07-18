extends Marker3D

@export var TestMesh :MeshInstance3D
@export var meshcount :int
@export var testlayermaterial :Material
var testlayernum=0.0
var rd: RenderingDevice
var multimeshid :RID
var compute_list
var pipeline
var thismesh
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






func _ready():
	# Create a global rendering device which can access multimesh data
	rd = RenderingServer.get_rendering_device() # global rd has access to main drawing thread
	var texturearray = create_texturearray() #doing this first to count number of planets!
	var meshmaterial=TestMesh.get_active_material( 0)
	meshmaterial.set_shader_parameter("Texture2DArrayParameter", texturearray)
	meshmaterial.set_shader_parameter("Total_Layers", num_planets*1.0)
	tempbuffer = maketestbuffer() #starting values
	print("v3: ", velocities[3])
	thismesh=CreateMultimesh(meshcount)
	makeComputeShader()
	tempbuffer.clear() #free memory
	testlayermaterial.set_shader_parameter("Texture2DArrayParameter", texturearray)

	


func _process(delta):
	# Create a compute pipeline
	if(!paused):
		var dispatchnumber=meshcount-1 # not updating sun
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
	if Input.is_action_just_pressed("Pause"): paused =!paused
	
	if Input.is_action_just_pressed("Flipcolour"):
		testlayermaterial.set_shader_parameter("Layer", testlayernum)
		testlayernum = (testlayernum+.10)-int(testlayernum/num_planets)*num_planets
		
	
	




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
	meshbuffer=RenderingServer.multimesh_get_buffer_rd_rid(thismesh)
	meshuniform.add_id(meshbuffer)
	
	#velocities and accelerations in one buffer
	var velocityuniform := RDUniform.new()
	velocityuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velocityuniform.binding = 2 # this needs to match the "binding" in our shader file
	var velocitybytes=PackedFloat32Array(velocities).to_byte_array()
	var velocitybuffer = rd.storage_buffer_create(velocitybytes.size(), velocitybytes)
	velocityuniform.add_id(velocitybuffer)
	
	#uint planetcount;  #uint dummy2;  #uint dummy3;  #uint dummy4;
	#float BigG;  #float DummyMass;  #float DeltaTime;  #float packing;
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

### Make test buffer in multimesh transform format
func maketestbuffer():
	var interimarray=[]
	var suns=1
	if(suns>0):
		#Make the Suns
		
		var temppos = Transform3D.IDENTITY.scaled(Vector3(3,3,3))
		var tempbasis = temppos.basis
		# values laid out to match multimesh array
		interimarray.append_array([tempbasis.x.x, tempbasis.y.x, tempbasis.z.x, temppos.origin.x, \
	tempbasis.x.y, tempbasis.y.y, tempbasis.z.y, temppos.origin.y, \
	tempbasis.x.z, tempbasis.y.z, tempbasis.z.z, temppos.origin.z])
		#Velocity buffer - 1:3 velocity, 4-mass 5:7 acceleration, 8 free
		velocities.append_array([0.0, 0.0, 0.0, solarmass]); #Vx,Vy,Vz, M
		velocities.append_array([0.0,0.0,0.0,0.0]) #zero acceleration
	
	var totalplanetmass=0
	for i in range (meshcount-suns):
		var circrand=randf_range(-PI,PI)
		var massrand=randf_range(.3,0.5)
		var radiusrand=5+i #randf_range(4.0,20.0) 
		if (i<num_planets):
			radiusrand=4+1.4**i
			massrand=randf_range(50,200)
		totalplanetmass+=massrand
		var size=sqrt(massrand)*0.1
		var planetvel=sqrt(BigG*solarmass/radiusrand) # assume orbital velocity
		#print("Mass: ",massrand," size: ", size," vel: ",planetvel, "surfaceg: ", BigG*massrand*massrand/(size*size),)
		
		#if (i==(meshcount/5)): planetvel=0; #testing collisions
		var temppos = Transform3D.IDENTITY.scaled(Vector3(size,size,size))
		#temppos = temppos.translated(Vector3((6+i/5000.0)*cos(circrand), randf_range(-1.0,1.0), (6+i/5000.0)*sin(circrand)))
		temppos = temppos.translated(Vector3(radiusrand*cos(circrand), randf_range(-.10,.10), radiusrand*sin(circrand)))
		var tempbasis = temppos.basis
		var custom :Vector4 = Vector4(0,0,0,0)
		var colour :Vector4 = Vector4(0,0,0,0)
		# values laid out to match multimesh array
		interimarray.append_array([tempbasis.x.x, tempbasis.y.x, tempbasis.z.x, temppos.origin.x, \
	tempbasis.x.y, tempbasis.y.y, tempbasis.z.y, temppos.origin.y, \
	tempbasis.x.z, tempbasis.y.z, tempbasis.z.z, temppos.origin.z ])#, \
	#colour, custom.x])
	
		# Array 1:3 velocity, 4-mass 5:7 acceleration, 8 free
		velocities.append_array([-planetvel*sin(circrand),0.0\
	, planetvel*cos(circrand),massrand]);	# initial velocity is orbital
		
		#velocities.append_array([0.0,randf_range(-0.1,.1), 0.0, massrand]);
		velocities.append_array([0.0,0.0,0.0,0.0]) #zero acceleration
	
	
	var mesharray = PackedFloat32Array(interimarray)
	#var buffertest := rd.storage_buffer_create(mesharray.size(), mesharray)
	print ("planets total mass: ",totalplanetmass)
	return mesharray
	#end of test buffer

func CreateMultimesh(size):
	multimeshid = RenderingServer.multimesh_create()
	RenderingServer.multimesh_allocate_data(\
	multimeshid,\
	size,\
	RenderingServer.MultimeshTransformFormat.MULTIMESH_TRANSFORM_3D,\
	false, false,false) #colours, custom, useindirect
	
	RenderingServer.multimesh_set_mesh(multimeshid, TestMesh.mesh.get_rid())
	RenderingServer.multimesh_set_buffer(multimeshid,tempbuffer)
	var aabb = Vector3(512.0, 1000.0, 512.0)
	var instance = RenderingServer.instance_create()
	var scenario =  get_world_3d().scenario
	#RenderingServer.instance_set_custom_aabb(instance,AABB(-aabb,2*aabb))
	RenderingServer.instance_set_scenario(instance,scenario)
	RenderingServer.instance_set_base(instance,multimeshid)
	return multimeshid
	
#Move to planet_data
func create_texturearray():
	# textures from https://www.solarsystemscope.com/textures/
	var texturearray :Texture2DArray = Texture2DArray.new()
	var images :Array[Image] = []
	#var imagelist =["8k_sun.jpg", "8k_mercury.jpg", "8k_venus_surface.jpg", \
	#"8k_earth_daymap.jpg","8k_mars.jpg","8k_jupiter.jpg", "8k_saturn.jpg", \
	#"2k_uranus.jpg", "2k_neptune.jpg", "8k_moon.jpg","4k_ceres_fictional.jpg","4k_eris_fictional.jpg" ]
	
	var imagelist =["4k_sun.jpg", "4k_mercury.jpg", "4k_venus_surface.jpg", \
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
