shader_type spatial;
render_mode
 unshaded,
 //depth_draw_always,
 cull_disabled;

uniform float Layer;
uniform sampler2DArray Texture2DArrayParameter : filter_nearest_mipmap;


void vertex() {
	// Called for every vertex the material is visible on.
}
void fragment() {
 vec2 spheremap= UV*2.0-vec2(1.0);
  NORMAL_MAP = normalize(vec3(spheremap,1.0));
	vec3 tex_coord = vec3(UV, Layer);
	vec4 col = texture(Texture2DArrayParameter, tex_coord);
	ALBEDO=col.rgb;
}



//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
