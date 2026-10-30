// Kattintható tárgyak kiemelése: arany perem-izzás.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float strength = 0.7;

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float pulse = 0.75 + 0.25 * sin(TIME * 4.0);
	ALBEDO = color.rgb * (f + 0.08) * strength * pulse;
	ALPHA = 1.0;
}
