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
layout(set = 0, binding = 1) restrict uniform ParameterBuffer {
    uint planetcount;
    uint dummy2;
    uint dummy3;
    uint dummy4;
    float BigG;
    float Mass;
    float DeltaTime;
    float packing;
}
parameter_buffer;

// velocity, acceleration and mass buffer
layout(set = 0, binding = 2, std430) restrict buffer VelocityBuffer {
    float velocitydata[];

//1:3 velocity, 4-mass 5:7 acceleration, 8 free
}
velocity_buffer;


vec3 planet_pos (uint planet){
uint planetdata=planet*12;
return vec3(my_data_buffer.data[planetdata+3],my_data_buffer.data[planetdata+7],my_data_buffer.data[planetdata+11]);

}

vec3 planet_vel(uint planet){
return vec3(velocity_buffer.velocitydata[planet*8],velocity_buffer.velocitydata[planet*8+1],velocity_buffer.velocitydata[planet*8+2]);

}

float planet_mass(uint planet){
return velocity_buffer.velocitydata[planet*8+3];
}

vec3 planet_acc(uint planet){
return vec3(velocity_buffer.velocitydata[planet*8+5], velocity_buffer.velocitydata[planet*8+6], velocity_buffer.velocitydata[planet*8+7]);

}

vec3 get_net_force(uint planet, uint other_planet) {
    float mass1=planet_mass(planet);
    float mass2=planet_mass(other_planet);
	vec3 net_force = vec3(0., 0., 0.);
	float distance = length(planet_pos(planet) - planet_pos(other_planet));
	if (distance == 0.) return net_force;
	float force = parameter_buffer.BigG*mass1*mass2 / (distance * distance);
	return normalize((planet_pos(other_planet) - planet_pos(planet)) * force);
}

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
uint planet=gl_GlobalInvocationID.x;
uint planetdata=planet*12;

	vec3 net_force = vec3(0., 0., 0.);
    float DeltaTime=0.0001;

			for (uint i = 0; i < parameter_buffer.planetcount; i++) {
				if (i == planet) continue;

				net_force+=get_net_force(planet, i)*DeltaTime/planet_mass(planet);
			}

vec3 newvelocity = planet_vel(planet) + net_force;
vec3 newplanet=planet_pos(planet)+newvelocity*0.001;

//set planet position in multimesh buffer
    my_data_buffer.data[planetdata+3] =newplanet.x;
    my_data_buffer.data[planetdata+7] =newplanet.y;
    my_data_buffer.data[planetdata+11] =newplanet.z;

//set planet velocity and acceleration in compute buffer
velocity_buffer.velocitydata[planet*8] =newvelocity.x;
velocity_buffer.velocitydata[planet*8+1]=newvelocity.y;
velocity_buffer.velocitydata[planet*8+2] =newvelocity.z;
//force
velocity_buffer.velocitydata[planet*8+4] =net_force.x;
velocity_buffer.velocitydata[planet*8+5]=net_force.y;
velocity_buffer.velocitydata[planet*8+6] =net_force.z;






}

