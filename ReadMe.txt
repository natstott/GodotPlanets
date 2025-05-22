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
be able to control when it is dispatched.

Basic function - implement gravity attraction between particles.
F=GMm/r^2
Scaling- for realistic planets - to be updated
1 screen unit =	1.00E+09	m	
1 mass unit = 1.00E+24	kilograms
1 second gamtime 1.00E+05	seconds
G unscaled	6.67E-11m3⋅kg−1⋅s−2
G Scale	0.0000001
G rescaled	0.00066743			

Check			scaled	
Mass Earth	5.97E+24	Kg	5.972	massunits
Earth moon 384400000	M	0.3844	Screen units
T=2Pi.sqrt(a3/GM)	2371877.06400035	seconds	23.7187706400035	seconds
	27.4522808333374	days		

Images from https://nasa3d.arc.nasa.gov/images
