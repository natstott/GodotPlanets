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

uint stride=12;// 12 by default, this will need to be 16 or 20 if colour/custom is used
//custom is now used so 16 stride

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
    //mat3x3 basis;
    float mass;
    float rad;
    };

Planet get_planet(uint planet){
    Planet thisplanet;

    thisplanet.vel = vec3(velocity_buffer.velocitydata[planet*8],velocity_buffer.velocitydata[planet*8+1],velocity_buffer.velocitydata[planet*8+2]);
    thisplanet.mass = velocity_buffer.velocitydata[planet*8+3];
    thisplanet.acc = vec3(velocity_buffer.velocitydata[planet*8+4], velocity_buffer.velocitydata[planet*8+5], velocity_buffer.velocitydata[planet*8+6]);
    uint planetdata=planet*stride;// this will need to be 16 or 20 if colour/custom is used
    thisplanet.pos = vec3(my_data_buffer.data[planetdata+3],my_data_buffer.data[planetdata+7],my_data_buffer.data[planetdata+11]);// based on transform buffer in multimesh

    thisplanet.rad= my_data_buffer.data[planetdata]; //actually scale.x
    return thisplanet;
}

/*
Adding rotation matrix
For Transform3D the float-order is: (basis.x.x, basis.y.x, basis.z.x, origin.x, basis.x.y, basis.y.y, basis.z.y, origin.y, basis.x.z, basis.y.z, basis.z.z, origin.z).

    thisplanet.basis=mat3x3(my_data_buffer.data[planetdata],my_data_buffer.data[planetdata+1],my_data_buffer.data[planetdata+2],
                            my_data_buffer.data[planetdata+4],my_data_buffer.data[planetdata+5],my_data_buffer.data[planetdata+6],
                            my_data_buffer.data[planetdata+8],my_data_buffer.data[planetdata+9],my_data_buffer.data[planetdata+10]);

*/


// The code we want to execute in each invocation
void main() {


    uint planetID=gl_GlobalInvocationID.x+1;
    Planet thisplanet=get_planet(planetID);


float DeltaTime=parameter_buffer.DeltaTime;

thisplanet.pos += thisplanet.vel * DeltaTime + 0.50*thisplanet.acc*DeltaTime;


// Write data to buffers
uint planetdata=planetID*stride;
//set planet position in multimesh buffer
    my_data_buffer.data[planetdata+3] =thisplanet.pos.x;
    my_data_buffer.data[planetdata+7] =thisplanet.pos.y;
    my_data_buffer.data[planetdata+11] =thisplanet.pos.z;

//set planet velocity and acceleration in compute buffer
//velocity_buffer.velocitydata[planetID*8] =newvelocity.x;
//velocity_buffer.velocitydata[planetID*8+1]=newvelocity.y;
//velocity_buffer.velocitydata[planetID*8+2] =newvelocity.z;
//force
//velocity_buffer.velocitydata[planetID*8+4] =net_force.x;
//velocity_buffer.velocitydata[planetID*8+5]=net_force.y;
//velocity_buffer.velocitydata[planetID*8+6] =net_force.z;






}

