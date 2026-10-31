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
uniform sampler2D plaster_tex : source_color, repeat_enable;
uniform sampler2D plaster_nrm : hint_normal, repeat_enable;

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
	// sírfestmény: festett jel fekete kontúrral, meszelt vakolaton, regiszterekre osztva
	float fill = 1.0 - smoothstep(0.034, 0.056, d);
	float outline = clamp((1.0 - smoothstep(0.056, 0.082, d)) - fill, 0.0, 1.0);
	float pl = texture(plaster_tex, p * 0.35).r;
	vec3 plaster = vec3(0.89, 0.81, 0.63) * (0.86 + pl * 0.45);
	float pick = h21(id + 7.0);
	vec3 inlay = vec3(0.17, 0.31, 0.62);
	if (pick > 0.35) inlay = vec3(0.66, 0.26, 0.15);
	if (pick > 0.62) inlay = vec3(0.25, 0.54, 0.36);
	if (pick > 0.84) inlay = vec3(0.86, 0.62, 0.22);
	vec3 faded = mix(inlay, plaster * 0.8, 0.55);
	vec3 painted = mix(inlay, faded, decay);
	vec3 c = mix(plaster, painted, fill);
	c = mix(c, vec3(0.07, 0.05, 0.035), outline * (1.0 - decay * 0.55));
	float col_div = 1.0 - smoothstep(0.0, 0.014, min(f.x, 1.0 - f.x));
	c = mix(c, vec3(0.09, 0.07, 0.05), col_div * 0.75);
	float reg = fract(g.y / 4.0) * 4.0;
	float band_a = step(reg, 0.09);
	float band_b = step(0.09, reg) * step(reg, 0.17);
	c = mix(c, vec3(0.16, 0.29, 0.6) * (1.0 - decay * 0.3), band_a);
	c = mix(c, vec3(0.64, 0.25, 0.14) * (1.0 - decay * 0.3), band_b);
	c *= stone.rgb / vec3(0.78, 0.63, 0.44);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	NORMAL_MAP = texture(plaster_nrm, p * 0.35).rgb;
	NORMAL_MAP_DEPTH = 0.5;
	EMISSION = glow_color.rgb * (fill * 0.6 + outline * 0.2) * glow * 0.9;
}
