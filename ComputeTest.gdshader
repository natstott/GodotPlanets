shader_type spatial;

//uniform float height_scale = 0.5;

//varying vec2 tex_position;

void vertex() {
	// Called for every vertex the material is visible on.
}
void fragment() {
 vec2 spheremap= UV*2.0-vec2(1.0);
  NORMAL_MAP = normalize(vec3(spheremap,1.0));
}



//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
