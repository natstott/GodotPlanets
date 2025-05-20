extends Label
const FPS_EXPRESSION = "FPS: %d"
func _process(_delta):
	var fps = Engine.get_frames_per_second()
	self.text = FPS_EXPRESSION % int(fps)
