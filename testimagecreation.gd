extends MeshInstance3D

func _ready():
	# Create a local rendering device.

	var texturearray = create_texturearray()
	var meshmaterial=self.get_active_material( 0)
	#if self.material_override:
	meshmaterial.set_shader_parameter("Texture2DArrayParameter", texturearray)
	#meshmaterial.albedo_texture = texturearray

func create_texturearray():
	var texturearray :Texture2DArray = Texture2DArray.new()
	var imagelist =["sun.jpg", "Earth.jpeg","Mars.jpeg","Jupiter.jpeg","moon.png"]
	var images :Array[Image] = []
	for filename in imagelist:
		var img=Image.new()
		var file_path="res://"+filename
		var temptexture = load(file_path)
		img = temptexture.get_image()
		img.decompress()
		img.resize(256,256)
		img.convert(Image.FORMAT_RGB8)
		img.generate_mipmaps()
		images.append(img)
		print("Loaded image from: %s" % filename)
		#var loadimage = load("res://"+filename)
		#var tempimage = loadimage.get_image()
		
		#images.append([tempimage])
	texturearray.create_from_images(images)
	#texturearray.save_png("res:\\testtexturearray")
	return texturearray
