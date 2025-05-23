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
    float DummyMass;
    float DeltaTime;
    float packing;
}
parameter_buffer;

// velocity, acceleration and mass buffer
layout(set = 0, binding = 2, std430) restrict buffer VelocityBuffer {
    float velocitydata[];

//0:2 velocity, 3-mass 4:6 acceleration, 7 free
}
velocity_buffer;




struct Planet{
    vec3 vel;
    vec3 acc;
    vec3 pos;
    float mass;
    float rad;
    };

Planet get_planet(uint planet){
    Planet thisplanet;

    thisplanet.vel = vec3(velocity_buffer.velocitydata[planet*8],velocity_buffer.velocitydata[planet*8+1],velocity_buffer.velocitydata[planet*8+2]);
    thisplanet.mass = velocity_buffer.velocitydata[planet*8+3];
    thisplanet.acc = vec3(velocity_buffer.velocitydata[planet*8+4], velocity_buffer.velocitydata[planet*8+5], velocity_buffer.velocitydata[planet*8+6]);
    uint planetdata=planet*12;// this will need to be 16 or 20 if colour/custom is used
    thisplanet.pos = vec3(my_data_buffer.data[planetdata+3],my_data_buffer.data[planetdata+7],my_data_buffer.data[planetdata+11]);// based on transform buffer in multimesh
    thisplanet.rad= my_data_buffer.data[planetdata]; //actually scale.x
    return thisplanet;
}


vec3 get_net_force(float Gfactor,Planet planet, Planet other_planet) {

	float distance = length(planet.pos - other_planet.pos);

    float force = (distance < planet.rad)? -4.0*(planet.rad-distance) : Gfactor*other_planet.mass / (distance * distance);
	return normalize((other_planet.pos - planet.pos)) * force;
}

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups

    uint planetID=gl_GlobalInvocationID.x;
    Planet thisplanet=get_planet(planetID);

    vec3 oldacc=thisplanet.acc;

	vec3 net_force = vec3(0., 0., 0.);

    float Gfactor=parameter_buffer.BigG;


//net-force is actually acceeration as planets own mass ignored.

	   		for (uint i = 0; i < parameter_buffer.planetcount; i++) {
				if (i == planetID) continue;
            	net_force+=get_net_force(Gfactor, thisplanet, get_planet(i));
			}

float DeltaTime=0.001;


//vec3 newvelocity=thisplanet.vel + net_force*DeltaTime;
//thisplanet.pos+=newvelocity*DeltaTime;
	//boidBuffer[instanceId].acceleration = DeltaTime*LJForce / boidBuffer[instanceId].boidmass;

	//boidBuffer[id.x].velocity =(boidBuffer[id.x].velocity + 0.5* (old_acc+boidBuffer[id.x].acceleration) * DeltaTime)*Cooling;
    
    thisplanet.acc = net_force*DeltaTime;
    thisplanet.vel+= 0.5*(oldacc+thisplanet.acc);


uint planetdata=planetID*12;
//set planet position in multimesh buffer
    my_data_buffer.data[planetdata+3] =thisplanet.pos.x;
    my_data_buffer.data[planetdata+7] =thisplanet.pos.y;
    my_data_buffer.data[planetdata+11] =thisplanet.pos.z;

//set planet velocity and acceleration in compute buffer
velocity_buffer.velocitydata[planetID*8] =thisplanet.vel.x;
velocity_buffer.velocitydata[planetID*8+1]=thisplanet.vel.y;
velocity_buffer.velocitydata[planetID*8+2] =thisplanet.vel.z;
//force
velocity_buffer.velocitydata[planetID*8+4] =thisplanet.acc.x;
velocity_buffer.velocitydata[planetID*8+5]=thisplanet.acc.y;
velocity_buffer.velocitydata[planetID*8+6] =thisplanet.acc.z;






}

