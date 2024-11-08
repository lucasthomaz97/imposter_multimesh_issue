shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_toon, specular_toon, unshaded;

group_uniforms BaseProperties;
uniform sampler2D texture_albedo : source_color, repeat_enable;
uniform sampler2D gradient_texture : hint_default_black, repeat_enable;
uniform sampler2D noise_texture: filter_nearest;
uniform sampler2D noise_texture2: filter_nearest;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.001);
group_uniforms;

group_uniforms Wind;
uniform float WindScale = 1.0;
uniform float WindSpeed = 1.0;
uniform float WindStr = 1.0;
uniform float WindDensity = 5.0;
uniform vec3 WindDirection = vec3(1., 0., 1.);
uniform bool deactivate_global_variation = false;
uniform float clamp_top : hint_range(0.0, 1.0) = 1.0;
uniform float clamp_bottom: hint_range(-1.0, 0.0) = 0.0;
group_uniforms;

group_uniforms Tiling;
uniform vec3 uv1_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv1_offset;
group_uniforms;

float approx_sin(float x, float smooth_val) {
    const float B = 4.0 / PI;
    const float C = -4.0 / (PI * PI);
    const float P = 0.225;
    return (B * x + C * x + (P * (abs(x) - 1.0) + 1.0) + abs(x))/smooth_val;
}

float approx_cos(float x, float smooth_val) {
    const float P = 0.225;
    x = x + PI / 2.0; // Shift by 90 degrees to approximate cos using sin
    const float B = 4.0 / PI;
    const float C = -4.0 / (PI * PI);
    return (B * x + C * x + (P * (abs(x) - 1.0) + 1.0) + abs(x))/smooth_val;
}

float split_specular(float specular) {
	return step(0.5f, specular);
}

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;

    // Billboard Mode: Enabled
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            MAIN_CAM_INV_VIEW_MATRIX[0],
            MAIN_CAM_INV_VIEW_MATRIX[1],
            MAIN_CAM_INV_VIEW_MATRIX[2],
            MODEL_MATRIX[3]);
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float contribution = 1.0 * (1.0 - float(deactivate_global_variation));
	vec3 world_pos_offset = world_pos * contribution;
	float positional_influence = -VERTEX.x -VERTEX.z - world_pos_offset.x - world_pos_offset.z;
	float offset = fract(positional_influence * (1.0/ WindScale) + (TIME*WindScale/1000.0));
	offset = min(1.0 - offset, offset);
	offset = (1.0 - offset) * offset * 2.0;
	
	float t = TIME + approx_sin(TIME + offset + approx_cos(TIME + offset * WindStr * 2.0, 5.0) * WindStr, 2.0) * WindSpeed;
	float mask = clamp(VERTEX.y + WindDensity, 0.0, 1.0) * (clamp_top - clamp_bottom) * clamp_bottom;
	float si = sin(t)/20.0 * WindStr * offset;
	float csi = approx_cos(t, 1.0) / 20.0 * WindStr * offset;
	
	vec3 wind_offset = vec3(VERTEX.x * si * mask, VERTEX.y * si * mask, VERTEX.z * csi * mask);
	
	VERTEX += uv1_offset.xyz + wind_offset;
}

void fragment() {
	vec2 base_uv = UV;
	ALPHA *= texture(texture_albedo, base_uv).a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;

	vec3 light_direction = VERTEX - LIGHT_VERTEX;
	vec2 light_direction_2d = vec2(light_direction.x, light_direction.y);
	float angle = atan(light_direction_2d.y, light_direction.x);
	mat2 rot_mat = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle),  cos(angle)));

	vec2 rotated_uv = rot_mat * base_uv;
	vec2 noise_uv = -rotated_uv + vec2(texture(noise_texture, base_uv).r, texture(noise_texture2, base_uv).r);
	vec3 gradient_color = texture(gradient_texture, noise_uv).rgb;

	ALBEDO = gradient_color;
}

