//Shader "Complete Sphere Impostor"
// https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c attempted
//port to Godot - ChatGPT had to help in the end.

shader_type spatial;
render_mode unshaded ;
 //depth_draw_always,
 //cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2DArray Texture2DArrayParameter : filter_nearest_mipmap;
uniform float Total_layers;
//uniform mat4 inv_model_matrix;

uniform float sphere_radius = 1.0; // match Unity's hardcoded 0.5
varying vec3 WORLD_VERTEX;
varying mat4 INV_MODEL_MATRIX;
varying mat4 model_matrix_instance;
varying float var_ArrayLayer;
varying vec3 ray_origin;

void vertex() {
float id=float(INSTANCE_ID);
float layers=float(Total_layers);
var_ArrayLayer=mod(id,layers);
    // Camera-aligned billboard logic (simplified)
vec3 cam_right  = normalize(MAIN_CAM_INV_VIEW_MATRIX[0].xyz);
vec3 cam_up     = normalize(MAIN_CAM_INV_VIEW_MATRIX[1].xyz);
vec3 cam_forward = normalize(-MAIN_CAM_INV_VIEW_MATRIX[2].xyz); // negated to match Godot’s forward
vec3 cam_pos    = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
    vec3 pivot = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    float scale = max(length(MODEL_MATRIX[0].xyz), max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
    vec3 quad_pos = pivot +
                    (VERTEX.x * scale) * cam_right +
                    (VERTEX.y * scale) * cam_up;
    INV_MODEL_MATRIX = inverse(MODEL_MATRIX);
	model_matrix_instance=MODEL_MATRIX;
	//ray_origin = CAMERA_POSITION_WORLD;
	
    VERTEX = (INV_MODEL_MATRIX * vec4(quad_pos, 1.0)).xyz;

    // Pass world space ray info to fragment
    WORLD_VERTEX = quad_pos;
}

float ray_sphere_intersect(vec3 ro, vec3 rd, vec3 center, float radius) {
    vec3 oc = ro - center;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - radius * radius;
    float h = b * b - c;
    if (h < 0.0) return -1.0;
    return -b - sqrt(h);
}

void fragment() {
   ray_origin = CAMERA_POSITION_WORLD;
    vec3 ray_dir = normalize(WORLD_VERTEX - ray_origin);

    vec3 obj_origin = (model_matrix_instance * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

    float t = ray_sphere_intersect(ray_origin, ray_dir, obj_origin, sphere_radius);

    if (t < 0.0) {
        discard;
    }

    vec3 hit_pos = ray_origin + ray_dir * t;
    vec3 local_pos = (INV_MODEL_MATRIX * vec4(hit_pos, 1.0)).xyz;
    vec3 normal = normalize(local_pos);

    vec3 color;
        float phi = atan(normal.z, normal.x) / (2.0 * PI);
        float phi_frac = fract(phi);
        float theta = acos(-normal.y) / PI;
        //vec2 uv = vec2(phi_frac, theta);
		vec3 tex_coord = vec3(phi_frac, theta, var_ArrayLayer);
        //color = texture(equirect_texture, tex_coord).rgb;
        //ALBEDO = color * albedo_color.rgb;
		ALBEDO=texture(Texture2DArrayParameter, tex_coord).rgb;
		//ALBEDO=vec3(var_ArrayLayer/10.0,1.0-var_ArrayLayer/10.0,0.5);

    // Optional: Manual lighting (Godot 4.x has `LIGHT` keyword but lighting here is unshaded)
}
