shader_type canvas_item;
// Festett kamrakép térhatással: a mélységtérkép szerint a közeli részek jobban
// elmozdulnak, mint a távoliak. Plusz a templom állapota: Ma'at (fény, telítettség),
// Duat (lila árnyak), Ankh (a kert zöldjei), lángvibrálás és sarokárnyék.

uniform sampler2D depth_tex : filter_linear;
uniform vec2 tex_size = vec2(1672.0, 941.0);
uniform vec2 rect_size = vec2(1600.0, 900.0);
uniform float zoom = 1.06;
uniform vec2 offset = vec2(0.0);
uniform float focus = 0.35;
uniform float time_s = 0.0;
uniform float maat = 0.75;
uniform float duat = 0.28;
uniform float ankh = 0.62;
uniform float green_mode = 0.0;
uniform vec3 tint = vec3(1.0);
uniform float glow = 0.0;
uniform float flicker = 1.0;
uniform float alpha = 1.0;

vec2 base_uv(vec2 uv) {
	float s = max(rect_size.x / tex_size.x, rect_size.y / tex_size.y);
	vec2 vis = rect_size / (tex_size * s);
	return 0.5 + (uv - 0.5) * vis / zoom;
}

void fragment() {
	vec2 uv = base_uv(UV);
	vec2 p = uv;
	for (int i = 0; i < 3; i++) {
		float dd = texture(depth_tex, p).r;
		p = uv - offset * (dd - focus);
	}
	p = clamp(p, vec2(0.002), vec2(0.998));
	vec4 c = texture(TEXTURE, p);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));

	// lángok és mécsesek vibrálása: csak a világos, meleg foltokon
	float warm = smoothstep(0.55, 0.95, l) * step(c.b, c.r);
	float fl = sin(time_s * 7.3 + p.x * 40.0) * 0.5 + sin(time_s * 11.1 + p.y * 31.0) * 0.5;
	c.rgb *= 1.0 + flicker * warm * 0.06 * fl;

	// Ma'at: alacsonyan fakó és sötétebb, magasan a fények ragyognak
	vec3 gray = vec3(l) * vec3(0.92, 0.86, 0.8);
	c.rgb = mix(gray, c.rgb, mix(0.4, 1.0, maat));
	c.rgb *= mix(0.68, 1.0, maat);
	c.rgb += glow * warm * c.rgb * 0.3;

	// Ankh a kertben: a zöldek kiszáradnak, ha alacsony
	if (green_mode > 0.5) {
		float g = smoothstep(0.0, 0.12, c.g - max(c.r, c.b));
		vec3 dry = vec3(l * 1.05, l * 0.86, l * 0.55);
		c.rgb = mix(c.rgb, mix(dry, c.rgb, ankh), g);
	}

	// Duat: lila, lassan hullámzó árnyak a sötét részekben
	float shadow = 1.0 - smoothstep(0.08, 0.55, l);
	float wisp = sin(p.x * 9.0 + time_s * 0.6) * sin(p.y * 7.0 - time_s * 0.45) * 0.5 + 0.5;
	float dv = smoothstep(0.35, 1.0, duat);
	c.rgb = mix(c.rgb, c.rgb * vec3(0.55, 0.42, 0.95) + vec3(0.07, 0.02, 0.13), dv * shadow * (0.55 + 0.45 * wisp));

	c.rgb *= tint;
	vec2 q = UV - 0.5;
	c.rgb *= 1.0 - dot(q, q) * 0.85;
	COLOR = vec4(c.rgb, alpha);
}
