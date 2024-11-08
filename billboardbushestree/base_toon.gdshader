shader_type spatial;

render_mode diffuse_toon, specular_toon;

uniform vec4 color: source_color;
uniform float metallic: hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float roughness: hint_range(0.0, 1.0, 0.1) = 0.0;
uniform sampler2D color_gradient;
uniform sampler2D fresnel_gradient;
uniform float fresnel_amount: hint_range(0.0, 1.0, 0.1) = 0.4;

float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 00, 1.0)), amount);
}

void fragment() {
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
	float base_fresnel = fresnel(fresnel_amount, NORMAL, LIGHT_VERTEX);
	vec2 base_uv = UV;
	ALPHA = color.a;
	ALBEDO = color.rgb * (base_fresnel * texture(fresnel_gradient, vec2(base_fresnel, 0.0))).rgb;
}

void light() {
	float dot_product = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dot_product+1.0) * ATTENUATION/2.1, 0.05, 0.95);
	vec4 shaded = texture(color_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}