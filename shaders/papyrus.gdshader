// Papirusz-felület: vízszintes és függőleges rostok, foltok, sötétedő szélek.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.914, 0.847, 0.675, 1.0);
uniform vec2 rect_size = vec2(400.0, 300.0);
uniform float edge_dark = 0.32;
uniform float seed = 0.0;
uniform float fiber = 1.0;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = lp + vec2(seed * 37.0, seed * 91.0);
	float fh = noise(vec2(p.x * 0.015, p.y * 0.85));
	float fh2 = noise(vec2(p.x * 0.05, p.y * 2.3) + 17.0);
	float fv = noise(vec2(p.x * 0.85, p.y * 0.015) + 31.0);
	float blot = noise(p * 0.008) * 0.6 + noise(p * 0.03) * 0.4;
	float v = ((fh - 0.5) * 0.06 + (fh2 - 0.5) * 0.03 + (fv - 0.5) * 0.035) * fiber + (blot - 0.5) * 0.12;
	vec3 col = COLOR.rgb * tint.rgb / vec3(0.914, 0.847, 0.675) * (1.0 + v * 1.25);
	vec2 d = min(lp, rect_size - lp);
	float e = clamp(min(d.x, d.y) / 46.0, 0.0, 1.0);
	col *= mix(1.0 - edge_dark, 1.0, smoothstep(0.0, 1.0, e));
	// meleg, régi festék: a sötétebb foltok barnulnak, nem szürkülnek
	col = mix(col, col * vec3(1.05, 0.97, 0.84), clamp(-v * 4.0 + (1.0 - e) * 0.6, 0.0, 1.0));
	COLOR = vec4(col, COLOR.a);
}
