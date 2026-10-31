// Illesztett kőlapok (bazalt padló és falak): eltolt sorokban vágott lapok, lapra szabott
// színeltérés, fugák, finom kopás. Világtérben vetítve, így bármilyen hasábon működik.
shader_type spatial;

uniform vec4 stone : source_color = vec4(0.13, 0.12, 0.12, 1.0);
uniform vec4 stone_b : source_color = vec4(0.18, 0.16, 0.14, 1.0);
uniform vec4 grout : source_color = vec4(0.05, 0.045, 0.04, 1.0);
uniform vec2 slab = vec2(1.6, 1.1);
uniform float polish = 0.35;
uniform sampler2D detail : hint_normal, repeat_enable;
uniform sampler2D grain : source_color, repeat_enable;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec3 n = abs(wnorm);
	vec2 p = n.y > 0.6 ? wpos.xz : (n.x > n.z ? wpos.zy : wpos.xy);
	vec2 g = p / slab;
	float row = floor(g.y);
	g.x += mod(row, 2.0) * 0.5;
	vec2 id = floor(g);
	vec2 f = fract(g);
	float edge = min(min(f.x, 1.0 - f.x) * slab.x, min(f.y, 1.0 - f.y) * slab.y);
	float joint = 1.0 - smoothstep(0.006, 0.022, edge);
	float r = h21(id);
	vec3 base = mix(stone.rgb, stone_b.rgb, r);
	float gr = texture(grain, p * 0.35).r;
	base *= 0.82 + gr * 0.45;
	base = mix(base, grout.rgb, joint);
	ALBEDO = base;
	ROUGHNESS = mix(1.0 - polish, 0.95, joint) + (gr - 0.5) * 0.2;
	NORMAL_MAP = texture(detail, p * 0.5).rgb;
	NORMAL_MAP_DEPTH = 0.6 + joint * 1.5;
	SPECULAR = 0.45;
}
