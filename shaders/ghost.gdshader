// A Duat szellemei: billboardolt, áttetsző, lebegő alakok.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.45, 0.6, 1.0, 1.0);
uniform float intensity = 0.8;
uniform float phase = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float sway = sin(TIME * 2.0 + uv.y * 5.0 + phase) * 0.12 * (uv.y + 1.0);
	float x = uv.x - sway;
	float width = mix(0.28, 0.06, clamp((uv.y + 1.0) * 0.5, 0.0, 1.0));
	float body = exp(-(x * x) / (width * width));
	float head = exp(-((uv.x) * (uv.x) + (uv.y + 0.62) * (uv.y + 0.62)) * 22.0);
	float fade = smoothstep(1.0, 0.1, uv.y) * smoothstep(-1.0, -0.8, uv.y);
	float flicker = 0.8 + 0.2 * sin(TIME * 7.0 + phase * 3.0);
	float a = clamp((body * 0.7 + head) * fade, 0.0, 1.0) * intensity * flicker;
	ALBEDO = color.rgb * a;
	ALPHA = a;
}
