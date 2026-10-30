// Világtérben vetített, procedurális hieroglifa-felület. A „glow” a Ma'at-tal nő,
// a „decay” az alacsony Ma'at-nál fakítja a festett berakást.
shader_type spatial;

uniform vec4 stone : source_color = vec4(0.78, 0.63, 0.44, 1.0);
uniform vec4 carve : source_color = vec4(0.30, 0.20, 0.11, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.38, 1.0);
uniform float glow = 0.0;
uniform float decay = 0.0;
uniform float cell_w = 0.5;
uniform float cell_h = 0.58;

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

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

float glyph(vec2 uv, float id) {
	float d = 10.0;
	float r1 = h21(vec2(id, 1.7));
	float r2 = h21(vec2(id, 2.3));
	float r3 = h21(vec2(id, 3.9));
	if (r1 < 0.2) {
		d = abs(length(uv - vec2(0.5, 0.6)) - 0.16);
		d = min(d, length(uv - vec2(0.5, 0.6)) - 0.04);
	} else if (r1 < 0.38) {
		d = abs(length((uv - vec2(0.5, 0.72)) * vec2(1.0, 1.35)) - 0.11);
		d = min(d, seg(uv, vec2(0.5, 0.6), vec2(0.5, 0.15)));
		d = min(d, seg(uv, vec2(0.3, 0.55), vec2(0.7, 0.55)));
	} else if (r1 < 0.52) {
		for (int k = 0; k < 3; k++) {
			float y = 0.3 + float(k) * 0.18;
			float w = abs(uv.y - (y + sin(uv.x * 22.0) * 0.035));
			w += step(0.85, uv.x) + step(uv.x, 0.15);
			d = min(d, w);
		}
	} else if (r1 < 0.66) {
		d = seg(uv, vec2(0.5, 0.88), vec2(0.5, 0.12));
		d = min(d, seg(uv, vec2(0.5, 0.88), vec2(0.7, 0.66)));
		d = min(d, seg(uv, vec2(0.5, 0.6), vec2(0.32, 0.45)));
	} else if (r1 < 0.8) {
		d = abs(length((uv - vec2(0.5, 0.52)) * vec2(0.75, 1.7)) - 0.17);
		d = min(d, length(uv - vec2(0.5, 0.52)) - 0.05);
		d = min(d, seg(uv, vec2(0.45, 0.4), vec2(0.38, 0.2)));
	} else if (r1 < 0.9) {
		d = seg(uv, vec2(0.25, 0.2), vec2(0.25, 0.8));
		d = min(d, seg(uv, vec2(0.25, 0.8), vec2(0.75, 0.8)));
		d = min(d, seg(uv, vec2(0.75, 0.8), vec2(0.75, 0.2)));
		d = min(d, seg(uv, vec2(0.4, 0.2), vec2(0.6, 0.2)));
	} else {
		d = abs(length((uv - vec2(0.5, 0.45)) * vec2(1.0, 1.2)) - 0.2);
		d = min(d, seg(uv, vec2(0.62, 0.62), vec2(0.82, 0.8)));
	}
	if (r2 < 0.45) d = min(d, seg(uv, vec2(0.2, 0.08), vec2(0.8, 0.08)));
	if (r3 < 0.25) d = min(d, seg(uv, vec2(0.2, 0.92), vec2(0.35, 0.78)));
	return d;
}

void fragment() {
	vec3 n = abs(wnorm);
	vec2 p;
	if (n.x > n.y && n.x > n.z) {
		p = vec2(wpos.z, wpos.y);
	} else if (n.z > n.y) {
		p = vec2(wpos.x, wpos.y);
	} else {
		p = vec2(wpos.x, wpos.z);
	}
	vec2 g = p / vec2(cell_w, cell_h);
	vec2 id = floor(g);
	vec2 f = fract(g);
	float gid = h21(id);
	float d = glyph(f, gid * 91.7);
	float line = 1.0 - smoothstep(0.022, 0.048, d);
	float col_div = 1.0 - smoothstep(0.0, 0.025, min(f.x, 1.0 - f.x));
	vec3 base = stone.rgb * (0.88 + 0.14 * h21(id + 3.0));
	vec3 inlay = mix(vec3(0.12, 0.2, 0.52), vec3(0.18, 0.58, 0.55), step(0.5, h21(id + 7.0)));
	inlay = mix(inlay, vec3(0.62, 0.22, 0.12), step(0.82, h21(id + 11.0)));
	vec3 painted = mix(inlay, carve.rgb, decay);
	vec3 c = mix(base, painted, line);
	c = mix(c, carve.rgb * 0.9, col_div * 0.55);
	ALBEDO = c;
	ROUGHNESS = 0.85;
	EMISSION = glow_color.rgb * line * glow * 1.2;
}
