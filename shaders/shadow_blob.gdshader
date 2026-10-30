// A folyosókon mozgó árnyak (magas Duat).
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform float intensity = 0.6;
uniform float phase = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float wob = sin(TIME * 1.7 + phase + uv.x * 3.0) * 0.12;
	float d = length(uv * vec2(1.0, 1.0 + wob));
	float a = smoothstep(1.0, 0.2, d) * intensity;
	ALBEDO = vec3(0.02, 0.0, 0.05);
	ALPHA = a;
}
