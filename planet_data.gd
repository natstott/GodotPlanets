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
		#print(temparray)
