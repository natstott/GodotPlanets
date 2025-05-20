#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 32, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script. data[] matches format of multimesh buffer - so it will have more fields if the multimesh has colour and custom data.

layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
    float data[];
}
my_data_buffer;

// Parameters
layout(set = 0, binding = 1, std430) restrict buffer ParameterBuffer {
    uint planetcount;
    uint dummy1;
    uint dummy2;
    uint dummy3;
}
parameter_buffer;

// velocity, acceleration and mass buffer
layout(set = 0, binding = 2, std430) restrict buffer VelocityBuffer {
    float velocitydata[];

//1:4 velocity, 5:8 acceleration
}
velocity_buffer;


vec3 planet_pos (uint planet){
uint planetdata=planet*12;
return vec3(my_data_buffer.data[planetdata+3],my_data_buffer.data[planetdata+7],my_data_buffer.data[planetdata+11]);

}

vec3 planet_vel(uint planet){
return vec3(velocity_buffer.velocitydata[planet*8],velocity_buffer.velocitydata[planet*8+1],velocity_buffer.velocitydata[planet*8+2]);

}

vec3 planet_acc(uint planet){
return vec3(velocity_buffer.velocitydata[planet*8+5], velocity_buffer.velocitydata[planet*8+6], velocity_buffer.velocitydata[planet*8+7]);

}

vec3 get_net_force(uint planet, uint other_planet) {
	vec3 net_force = vec3(0., 0., 0.);
	float distance = length(planet_pos(planet) - planet_pos(other_planet));
	if (distance == 0.) return net_force;
	float force = (0.0000001) / (distance * distance);
	return normalize((planet_pos(other_planet) - planet_pos(planet)) * force);
}

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
uint planet=gl_GlobalInvocationID.x;
uint planetdata=planet*12;

		vec3 net_force = vec3(0., 0., 0.);

			for (uint i = 0; i < parameter_buffer.planetcount; i++) {
				if (i == planet) continue;

				net_force+=get_net_force(planet, i);
			}

vec3 newvelocity = planet_vel(planet) + net_force*.0001;
vec3 newplanet=planet_pos(planet)+newvelocity*0.001;

//set planet position
    my_data_buffer.data[planetdata+3] =newplanet.x;
    my_data_buffer.data[planetdata+7] =newplanet.y;
    my_data_buffer.data[planetdata+11] =newplanet.z;

//set planet velocity
velocity_buffer.velocitydata[planet*8] =newvelocity.x;
velocity_buffer.velocitydata[planet*8+1]=newvelocity.y;
velocity_buffer.velocitydata[planet*8+2] =newvelocity.z;






}

