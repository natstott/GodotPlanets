extends Node3D

var solarmass=50000.0
var num_planets=9
var velocities = []
var planetdata =[]
var meshcount
var BigG = 0.667; #0.00066743


func _ready() -> void:
	get_csv_data()


func get_csv_data():
	var file :FileAccess
	var filename="planetdata.csv"
	var file_path="res://"+filename
	var csv = []
	file=FileAccess.open(file_path,FileAccess.READ)
	print("csv loaded?")
	#else: print("Error loading file")
	while !file.eof_reached():
		var csv_rows = file.get_csv_line(",") # I use comma as delimiter
		csv.append(csv_rows)
	file.close()
	csv.pop_back() #remove last empty array get_csv_line() has created 
	#headers = Array(csv[0])
	
	for i in range(1,csv.size()):
		var temparray=[]
		for element in csv[i]:
			if element.is_valid_float():
				temparray.append(element.to_float())
			else:
				temparray.append(element)
		planetdata.append(temparray)
		print(temparray)

func create_texturearray():
	# textures from https://www.solarsystemscope.com/textures/
	var texturearray :Texture2DArray = Texture2DArray.new()
	var images :Array[Image] = []
	
	var imagelist =["4k_sun.jpg", "4k_mercury.jpg", "4k_venus_surface.jpg", \
	"4k_earth_daymap.jpg","4k_mars.jpg","4k_jupiter.jpg", "4k_saturn.jpg", \
	"4k_uranus.jpg", "4k_neptune.jpg", "4k_pluto.jpg", \
	"4k_moon.jpg","4k_ceres_fictional.jpg","4k_eris_fictional.jpg","4k_makemake_fictional.jpg", \
	 "4k_haumea_fictional.jpg" ]
	
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
		
	print("numer of images ", images.size())
	texturearray.create_from_images(images)
	#texturearray.save_png("res:\\testtexturearray")
	return texturearray
	
func maketestbuffer():
	var interimarray=[]
	
	var totalplanetmass=0
	
	
	for i in range (meshcount):
		var circrand=randf_range(-PI,PI)
		var massrand=randf_range(.3,0.5)
		var radiusrand=randf_range(4.0,20.0) 
		if (i<num_planets): massrand=randf_range(50,200)
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
		#velocities.append_array([6*temppos.origin.z+randf_range(-.1,.1),0.0\
		#, -6*temppos.origin.x+randf_range(-.1,.1),massrand]);
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
	var multimeshid = RenderingServer.multimesh_create()
	RenderingServer.multimesh_allocate_data(\
	multimeshid,\
	size,\
	RenderingServer.MultimeshTransformFormat.MULTIMESH_TRANSFORM_3D,\
	false, false,false) #colours, custom, useindirect
	return multimeshid
	
func displaymultimesh(multimeshid, TestMesh,):
	RenderingServer.multimesh_set_mesh(multimeshid, TestMesh.mesh.get_rid())
	var instance = RenderingServer.instance_create()
	var scenario =  get_world_3d().scenario
	var aabb = Vector3(512.0, 100.0, 512.0) # arbitrary size? Match solar system size?
	RenderingServer.instance_set_custom_aabb(instance,AABB(-aabb,2*aabb))
	RenderingServer.instance_set_scenario(instance,scenario)
	RenderingServer.instance_set_base(instance,multimeshid)
	
