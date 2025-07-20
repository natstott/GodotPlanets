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

Now using Texture2DArray to store planet images and using simple instance id to
draw them using a sphere impostor based on :https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c
by Ben Golus

Basic function - implement gravity attraction between particles.
F=GMm/r^2


Images from NASA and wikipedia and https://www.solarsystemscope.com/textures/
