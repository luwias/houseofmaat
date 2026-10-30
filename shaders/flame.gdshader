// Parázstartók és mécsesek lángja: áttetsző, additív, lobogó.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 core : source_color = vec4(1.0, 0.86, 0.55, 1.0);
uniform vec4 edge : source_color = vec4(1.0, 0.36, 0.06, 1.0);
uniform float intensity = 1.0;

void fragment() {
	float f = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float n = 0.5 + 0.5 * sin(TIME * 13.0 + UV.y * 24.0 + UV.x * 9.0);
	vec3 c = mix(edge.rgb, core.rgb, pow(f, 2.2));
	float a = pow(f, 1.6) * (0.7 + 0.3 * n) * intensity;
	ALBEDO = c * a * 2.2;
	ALPHA = a;
}
