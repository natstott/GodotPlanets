//Shader "Complete Sphere Impostor"
// https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c attempted
//port to Godot - ChatGPT had to help in the end.

shader_type spatial;
render_mode
 unshaded,
 depth_draw_always,
 cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
//uniform sampler2D equirect_texture;
uniform float Total_layers;
uniform sampler2DArray Texture2DArrayParameter : filter_nearest_mipmap;
//uniform mat4 inv_model_matrix;

uniform float sphere_radius = 1.0; // match Unity's hardcoded 0.5
varying vec3 WORLD_VERTEX;
varying mat4 INV_MODEL_MATRIX;
varying mat4 Model_Matrix;
varying float sphere_scaled;
varying float var_ArrayLayer;
varying vec3 camera_position;
varying vec3 rayDir;
varying vec3 rayOrigin;

void vertex() {

	//instance layer of image
	float id=float(INSTANCE_ID);
//float layers=float(Total_layers);

//float layernum = mod(id,layers);
float layernum =0.0;
	var_ArrayLayer =layernum;

    // Camera-aligned billboard logic (simplified)
vec3 cam_right  = normalize(MAIN_CAM_INV_VIEW_MATRIX[0].xyz);
vec3 cam_up     = normalize(MAIN_CAM_INV_VIEW_MATRIX[1].xyz);
vec3 cam_forward = normalize(-MAIN_CAM_INV_VIEW_MATRIX[2].xyz); // negated to match Godot’s forward
vec3 worldSpaceViewerPos    = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
    vec3 worldSpacePivotPos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    float scale = max(length(MODEL_MATRIX[0].xyz), max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
    vec3 quad_pos = worldSpacePivotPos +
                    (VERTEX.x * scale) * cam_right +
                    (VERTEX.y * scale) * cam_up;
    INV_MODEL_MATRIX = inverse(MODEL_MATRIX);
	Model_Matrix=MODEL_MATRIX;

    VERTEX = (INV_MODEL_MATRIX * vec4(quad_pos, 1.0)).xyz;

    // Pass world space ray info to fragment
    //WORLD_VERTEX = VERTEX; //quad_pos;
	   // BG calculate world space view ray direction and origin for perspective or orthographic
       vec3 worldSpaceRayOrigin = worldSpaceViewerPos;
       vec3 worldSpaceRayDir = quad_pos - worldSpaceRayOrigin;
	rayDir=(MODEL_MATRIX*vec4(worldSpaceRayDir,0.0)).xyz;
	rayOrigin=(MODEL_MATRIX*vec4(worldSpaceRayOrigin,1.0)).xyz;

	WORLD_VERTEX = quad_pos;
	camera_position=worldSpaceViewerPos;
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
    //vec3 ray_origin = CAMERA_POSITION_WORLD;
	vec3 ray_origin = rayOrigin;

    vec3 ray_dir = normalize(rayDir);
    vec3 obj_origin = (Model_Matrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    //vec3 obj_origin = vec3(0.0, 0.0, 0.0);

    float t = ray_sphere_intersect(ray_origin, ray_dir, obj_origin, sphere_radius);

    if (t < 0.0) {
        discard;
    }

    vec3 hit_pos = ray_origin + ray_dir * t;
    //vec3 local_pos = (INV_MODEL_MATRIX * vec4(hit_pos, 1.0)).xyz;
    vec3 normal = normalize(hit_pos);

    vec3 color;
        float phi = atan(normal.z, normal.x) / (2.0 * PI);
        float phi_frac = fract(phi);
        float theta = acos(-normal.y) / PI;
        //vec2 uv = vec2(phi_frac, theta);
        //color = texture(equirect_texture, uv).rgb;
		vec3 tex_coord = vec3(phi_frac, theta, var_ArrayLayer);
		vec4 col = texture(Texture2DArrayParameter, tex_coord);
        ALBEDO = col.rgb;
	//NORMAL=normalize(hit_pos);

    // Optional: Manual lighting (Godot 4.x has `LIGHT` keyword but lighting here is unshaded)
}
