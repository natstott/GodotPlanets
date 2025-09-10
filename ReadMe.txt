Inspired by https://github.com/yunusey/ComputeShadersExperiment

I noticed it updates the planet position and velocity data
in the compute shader but then reads it back to CPU and updates the
planet objects with the data for Godot pipeline to render. 

I changed the drawing of the planets to use a multimesh.
The compute shader now generates the planet positions in the 
format needed for the multimesh buffer. The idea was that
the multimesh buffer can be linked to the compute shader so
it can be updated on the GPU - Originally I couldnt get this to work
using multimesh_get_command_buffer_rd_rid until u/godot_clayjohn explained
that a compute shader can run on the global renderingdevice but you will not
be able to control when exactly it is dispatched.

Using Texture2DArray to store planet images and using simple instance id to
draw them using a sphere impostor based on :https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c
by Ben Golus
Haven't yet fixed the seam, he used fwidth() hlsl function which doesn't solve it in glsl
See: https://bgolus.medium.com/distinctive-derivative-differences-cce38d36797b for an explanation
of mipmap choice and wrapping uvs.

The number of planets are just set by the number of images. The rest are set to random moons


Basic function - implement gravity attraction between particles.
F=GMm/r^2
calculated for every obect on every other object in compute shader to update positions.

Images from NASA and wikipedia and https://www.solarsystemscope.com/textures/
These are not included in the github verions, you will have to download the 4K images or use your own


The camera follows a planet position, selected by left ctrl.

I found the multimesh_instance_get_transform() function doesn't retrieve live values from the 
buffer, just the local cache, so as I am updating multimesh positions on the GPU,
I had to use:
	func Get_Planet(planetid):
in CameraMove.gd to retrieve the buffer section I need each frame.
