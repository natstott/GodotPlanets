//Shader "Complete Sphere Impostor"
// https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c attempted
//port to Godot - ChatGPT had to help in the end to suggest the right matrices.
//mostly working. Still a seem where uvs wrap around, fwidth() function to find gradient?

shader_type spatial;
render_mode
 unshaded,
 //depth_draw_always,
 cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float Total_layers;
uniform sampler2DArray Texture2DArrayParameter : filter_nearest_mipmap;

uniform float sphere_radius = 1.0; // match Unity's hardcoded 0.5
//varying float var_ArrayLayer;
varying float id;
varying vec3 rayDir;
varying vec3 rayOrigin;
varying vec3 vertexpos;
varying vec4 i_color;

void vertex() {

	//instance layer of image for Tecture2Darray layer. Used to avoid shadow on sun
id=float(INSTANCE_ID);
//var_ArrayLayer =float(int(mod(id+0.5,Total_layers)))+0.1;
	i_color = COLOR.rgba;


//camera position
vec3 worldSpaceViewerPos=CAMERA_POSITION_WORLD;
vec3 worldSpacePivotPos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
// offset between pivot and camera
vec3 worldSpacePivotToView = worldSpaceViewerPos - worldSpacePivotPos;

// Camera-facing billboard logic = BGolus
//Make the quad face the camera, not the view direction
vec3 cam_up     = normalize(MAIN_CAM_INV_VIEW_MATRIX[1].xyz);
vec3 cam_forward = normalize(worldSpacePivotToView);
vec3 cam_right = normalize(cross(cam_forward, cam_up));
//redo cam_up to ensure it is perpendicular - Not sure why it wouldnt be but hey.
cam_up = cross(cam_right, cam_forward);

float scale = max(length(MODEL_MATRIX[0].xyz), max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
//BGolus quad scaling to fit
                    float maxRadius=sphere_radius*scale;
                    // get the sine of the right triangle with the hyp of the sphere pivot distance and the opp of the sphere radius
                    float sinAngle = maxRadius / length(worldSpacePivotToView);
                    // convert to cosine
                    float cosAngle = sqrt(1.0 - sinAngle * sinAngle);
                    // convert to tangent
                    float tanAngle = sinAngle / cosAngle;
                    // basically this, but should be faster
                    //tanAngle = tan(asin(sinAngle));
                    // get the opp of the right triangle with the 90 degree at the sphere pivot * 2
                    float quadScale = tanAngle * length(worldSpacePivotToView) * 2.0;


vec3 quad_pos = (mat3(cam_right,cam_up,cam_forward)*VERTEX.xyz)*quadScale+worldSpacePivotPos;

	//vec3 worldPos =worldSpacePivotPos + quadOriemtationMatrix*(VERTEX.xyz*maxScale);

    vec3 worldSpaceRayOrigin = worldSpaceViewerPos;
    vec3 worldSpaceRayDir = quad_pos - worldSpaceRayOrigin;
mat4    INV_MODEL_MATRIX = inverse(MODEL_MATRIX);



// ray direction and origin 
// convert to model space to use in fragment, after varying adjustment
	rayDir=(INV_MODEL_MATRIX*vec4(worldSpaceRayDir,0.0)).xyz;
	rayOrigin=(INV_MODEL_MATRIX*vec4(worldSpaceRayOrigin,1.0)).xyz;
	VERTEX = (INV_MODEL_MATRIX * vec4(quad_pos, 1.0)).xyz;
	vertexpos=quad_pos;
	//pos = vec4(quad_pos,1.0); //Do we need to calculate new clip position?
}// End of Vertex

// calculate length of ray to sphere
// https://www.iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
float ray_sphere_intersect(vec3 ro, vec3 rd, vec3 center, float radius) {
    vec3 oc = ro - center;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - radius * radius;
    float h = b * b - c;
    if (h < 0.0) return -1.0;
    return -b - sqrt(h);
}

void fragment() {

	vec3 ray_origin = rayOrigin;

    vec3 ray_dir = normalize(rayDir);
    vec3 obj_origin = vec3(0.0, 0.0, 0.0);

    float t = ray_sphere_intersect(ray_origin, ray_dir, obj_origin, sphere_radius);

    if (t < 0.0) {
        discard;
    }

    vec3 hit_pos = ray_origin + ray_dir * t;
    //vec3 local_pos = (INV_MODEL_MATRIX * vec4(hit_pos, 1.0)).xyz;
    vec3 normal = normalize(hit_pos);

        float phi = atan(normal.z, normal.x) / (2.0 * PI)+i_color.g;
        float phi_frac = fract(phi);
        float theta = -acos(-normal.y) / PI;
		//i.color= COLOR from multimesh. R used for layer. G is being used for fake rotation. 
		// Trying G for rotation and B for rotation rate
		// uses a small bias to prefer the first 'UV set'
		vec2 uv = vec2(fwidth(phi) < fwidth(phi_frac) - 0.001 ? phi : phi_frac, theta);
		
		//vec3 tex_coord = vec3(-phi_frac, theta, i_color.r);
		vec3 tex_coord = vec3(uv, i_color.r);
		//vec3 tex_coord = vec3(-phi_frac, theta, var_ArrayLayer);
		vec4 col = texture(Texture2DArrayParameter, tex_coord);

		// cast shadows on everything but sun (id=o)
		float brightness=(id>0.5)? max(0.05,dot(normal,-normalize(vertexpos))):1.0;
        ALBEDO = col.rgb*brightness;


    // Optional: Manual lighting (Godot 4.x has `LIGHT` keyword but lighting here is unshaded)
}
