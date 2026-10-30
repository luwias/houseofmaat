extends Control
## Procedurális bizonyíték-illusztrációk: festett tábla, papiruszok, pecsétek, vallomások.
## Az állapot (megfordítva, lámpafény, nagyító) a rejtett részleteket is megmutatja.

const T = preload("res://scripts/ui/theme.gd")

const GLYPH_POOL := ["𓀀", "𓁐", "𓂀", "𓂋", "𓃀", "𓄤", "𓅓", "𓆄", "𓇋", "𓇳", "𓈖", "𓉐", "𓊛", "𓊪", "𓋴",
	"𓋹", "𓏏", "𓎛", "𓂻", "𓆣", "𓅱", "𓂝", "𓍿", "𓌳"]

var kind := "document"
var seed_key := ""
var state: Dictionary = {}
var corrupted := false
var _t := 0.0


func setup(p_kind: String, p_seed: String, p_state: Dictionary = {}, p_corrupted := false) -> void:
	kind = p_kind
	seed_key = p_seed
	state = p_state
	corrupted = p_corrupted
	queue_redraw()


func _process(delta: float) -> void:
	if state.get("lamp", false) or corrupted:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key + kind)
	var r := Rect2(Vector2.ZERO, size)
	match kind:
		"portrait":
			if state.get("flipped", false):
				_wood_back(r, rng)
			else:
				_portrait(r, rng)
		"seal":
			_seal_tablet(r, rng)
		"testimony":
			_testimony(r, rng)
		"letter_glyph":
			_sheet(r, rng)
			_letter(r, rng)
		_:
			_sheet(r, rng)
			_document(r, rng)
	if state.get("magnify", false):
		_magnifier(r)
	if corrupted:
		_corruption(r, rng)


# ------------------------------------------------------------ alapok
func _sheet(r: Rect2, rng: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array()
	var inset := 10.0
	var steps := 24
	for i in steps:
		pts.append(Vector2(lerpf(inset, r.size.x - inset, float(i) / steps), inset + rng.randf_range(-4, 4)))
	for i in steps:
		pts.append(Vector2(r.size.x - inset + rng.randf_range(-4, 4), lerpf(inset, r.size.y - inset, float(i) / steps)))
	for i in steps:
		pts.append(Vector2(lerpf(r.size.x - inset, inset, float(i) / steps), r.size.y - inset + rng.randf_range(-4, 4)))
	for i in steps:
		pts.append(Vector2(inset + rng.randf_range(-4, 4), lerpf(r.size.y - inset, inset, float(i) / steps)))
	draw_colored_polygon(pts, Color("d9c38f"))
	for i in 90:
		var y := rng.randf_range(inset, r.size.y - inset)
		draw_line(Vector2(inset, y), Vector2(r.size.x - inset, y + rng.randf_range(-2, 2)),
			Color(0.55, 0.42, 0.22, rng.randf_range(0.04, 0.12)), rng.randf_range(0.5, 2.0))
	for i in 40:
		var x := rng.randf_range(inset, r.size.x - inset)
		draw_line(Vector2(x, inset), Vector2(x + rng.randf_range(-2, 2), r.size.y - inset),
			Color(0.55, 0.42, 0.22, rng.randf_range(0.03, 0.08)), rng.randf_range(0.5, 1.5))
	for i in 6:
		draw_circle(Vector2(rng.randf_range(40, r.size.x - 40), rng.randf_range(40, r.size.y - 40)),
			rng.randf_range(10, 40), Color(0.5, 0.35, 0.15, 0.06))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.32, 0.16, 0.6), 2.0)


func _glyph_col(x: float, y0: float, y1: float, rng: RandomNumberGenerator, color: Color, sz: int = 24) -> void:
	var y := y0
	while y < y1:
		var g: String = GLYPH_POOL[rng.randi() % GLYPH_POOL.size()]
		draw_string(T.font_glyph, Vector2(x, y), g, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, color)
		y += sz * rng.randf_range(1.05, 1.35)


func _document(r: Rect2, rng: RandomNumberGenerator) -> void:
	var ink := Color(0.16, 0.11, 0.06, 0.85)
	var red := Color(0.6, 0.16, 0.08, 0.85)
	var cols := int((r.size.x - 80) / 34)
	# fejléc vörös tintával
	draw_line(Vector2(30, 52), Vector2(r.size.x - 30, 52), Color(red, 0.6), 2.0)
	for i in cols:
		var g: String = GLYPH_POOL[rng.randi() % GLYPH_POOL.size()]
		draw_string(T.font_glyph, Vector2(40 + i * 34, 42), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, red if i < 3 else ink)
	# oszlopok
	var bottom := r.size.y - 40.0
	if kind in ["ledger", "payment"]:
		bottom = r.size.y * 0.62
	for i in cols:
		var x := 40 + i * 34.0
		_glyph_col(x, 82, bottom, rng, ink, 22)
		if i < cols - 1:
			draw_line(Vector2(x + 29, 62), Vector2(x + 29, bottom), Color(0.3, 0.2, 0.1, 0.18), 1.0)
	match kind:
		"ledger", "payment":
			# számjelek: egyesek (|) és tízesek (∩)
			var y := r.size.y * 0.7
			for row in 2:
				var x := 46.0
				for k in rng.randi_range(3, 6):
					draw_arc(Vector2(x, y + row * 36 + 6), 8, PI, TAU, 10, ink, 2.5)
					x += 20
				for k in rng.randi_range(2, 8):
					draw_line(Vector2(x, y + row * 36 - 6), Vector2(x, y + row * 36 + 12), ink, 2.5)
					x += 9
				if kind == "payment":
					for k in 3:
						draw_arc(Vector2(r.size.x - 120 + k * 26, y + row * 36 + 3), 9, 0, TAU, 16, Color(0.75, 0.55, 0.15), 3.0)
			if kind == "ledger" and seed_key == "K02":
				_seal(Vector2(r.size.x - 110, r.size.y - 70), 30, Color(0.55, 0.18, 0.1, 0.8))
				_seal(Vector2(r.size.x - 88, r.size.y - 62), 31, Color(0.65, 0.22, 0.12, 0.9) if state.get("magnify", false) else Color(0.55, 0.18, 0.1, 0.5))
		"report":
			_seal(Vector2(r.size.x - 80, r.size.y - 60), 26, Color(0.12, 0.2, 0.45, 0.7))
		"contract":
			_seal(Vector2(r.size.x * 0.3, r.size.y - 60), 26, Color(0.55, 0.18, 0.1, 0.8))
			_seal(Vector2(r.size.x * 0.7, r.size.y - 60), 26, Color(0.12, 0.2, 0.45, 0.8))
		"signature":
			_cartouche(Vector2(r.size.x * 0.5, r.size.y - 70), rng, red)
		"manifest":
			_boat(Vector2(r.size.x * 0.72, r.size.y * 0.22), 0.9, ink)
	if state.get("lamp", false):
		var glow := Color(0.35, 0.95, 0.85, 0.55 + 0.25 * sin(_t * 3.0))
		draw_rect(Rect2(22, r.size.y - 36, r.size.x - 44, 22), Color(0.2, 0.7, 0.65, 0.12))
		for i in 12:
			var g: String = GLYPH_POOL[(i * 7) % GLYPH_POOL.size()]
			draw_string(T.font_glyph, Vector2(34 + i * 30, r.size.y - 18), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, glow)


func _letter(r: Rect2, _rng: RandomNumberGenerator) -> void:
	var ink := Color(0.16, 0.11, 0.06, 0.9)
	var groups := ["𓇳𓇳𓇳", "𓊛", "𓂻", "𓀀𓁐", "𓂀"]
	var x := 50.0
	var y := r.size.y * 0.5
	for g in groups:
		draw_string(T.font_glyph, Vector2(x, y), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, ink)
		x += T.font_glyph.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x + 26
		draw_circle(Vector2(x - 14, y - 14), 3, Color(0.6, 0.16, 0.08))
	draw_line(Vector2(40, y + 26), Vector2(r.size.x - 40, y + 26), Color(0.6, 0.16, 0.08, 0.5), 1.5)
	draw_string(T.font_body, Vector2(50, y + 70), "· · ·", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(ink, 0.5))


func _seal(c: Vector2, rad: float, col: Color) -> void:
	draw_circle(c, rad, col)
	draw_arc(c, rad * 0.78, 0, TAU, 28, col.darkened(0.35), 2.0)
	draw_string(T.font_glyph, c + Vector2(-11, 9), "𓆣", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col.darkened(0.5))


func _cartouche(c: Vector2, rng: RandomNumberGenerator, col: Color) -> void:
	var w := 160.0
	var h := 48.0
	draw_rect(Rect2(c.x - w / 2 + h / 2, c.y - h / 2, w - h, h), Color(0, 0, 0, 0), false, 2.5)
	draw_arc(c + Vector2(-w / 2 + h / 2, 0), h / 2, PI / 2, PI * 1.5, 16, col, 2.5)
	draw_arc(c + Vector2(w / 2 - h / 2, 0), h / 2, -PI / 2, PI / 2, 16, col, 2.5)
	draw_line(c + Vector2(-w / 2 + h / 2, -h / 2), c + Vector2(w / 2 - h / 2, -h / 2), col, 2.5)
	draw_line(c + Vector2(-w / 2 + h / 2, h / 2), c + Vector2(w / 2 - h / 2, h / 2), col, 2.5)
	draw_line(c + Vector2(w / 2, -h / 2 + 4), c + Vector2(w / 2, h / 2 - 4), col, 3.0)
	for i in 4:
		var g: String = ["𓅝", "𓏏", "𓇋", "𓅱"][i]
		draw_string(T.font_glyph, c + Vector2(-58 + i * 30, 10), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
	if rng.randf() < 2.0:
		pass


func _boat(c: Vector2, s: float, col: Color) -> void:
	var hull := PackedVector2Array([c + Vector2(-70, 0) * s, c + Vector2(-50, 16) * s, c + Vector2(50, 16) * s,
		c + Vector2(76, -8) * s, c + Vector2(40, 6) * s, c + Vector2(-40, 6) * s])
	draw_colored_polygon(hull, Color(col, 0.75))
	draw_line(c + Vector2(0, 4) * s, c + Vector2(0, -60) * s, col, 2.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(2, -56) * s, c + Vector2(34, -20) * s, c + Vector2(2, -8) * s]),
		Color(0.92, 0.9, 0.8, 0.8))
	draw_circle(c + Vector2(58, -2) * s, 3 * s, Color(0.12, 0.2, 0.45))


func _magnifier(r: Rect2) -> void:
	var c := Vector2(r.size.x - 100, r.size.y - 66)
	draw_arc(c, 58, 0, TAU, 48, Color(0.85, 0.65, 0.25), 5.0)
	draw_arc(c, 54, 0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	draw_line(c + Vector2(-40, 40), c + Vector2(-80, 80), Color(0.4, 0.25, 0.1), 9.0)


func _corruption(r: Rect2, rng: RandomNumberGenerator) -> void:
	for i in 26:
		var y := fposmod(rng.randf_range(0, r.size.y) + _t * rng.randf_range(10, 40), r.size.y)
		draw_rect(Rect2(rng.randf_range(0, r.size.x * 0.6), y, rng.randf_range(40, 220), rng.randf_range(2, 8)),
			Color(0.45, 0.25, 0.7, rng.randf_range(0.15, 0.4)))
	draw_rect(r, Color(0.2, 0.05, 0.3, 0.25))


# ------------------------------------------------------------ festett családi tábla
func _portrait(r: Rect2, rng: RandomNumberGenerator) -> void:
	draw_rect(r, Color("4a2f17"))
	var inner := r.grow(-16)
	draw_rect(inner, Color("e3c98f"))
	# ég és folyó
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.25)), Color("d6b77a"))
	var wy := inner.end.y - 46
	draw_rect(Rect2(inner.position.x, wy, inner.size.x, 46), Color("2c4f8f"))
	for row in 3:
		var pts := PackedVector2Array()
		for i in 40:
			var x := inner.position.x + i * inner.size.x / 39.0
			pts.append(Vector2(x, wy + 10 + row * 12 + (4.0 if i % 2 == 0 else -4.0)))
		draw_polyline(pts, Color("8fb6e8"), 2.0)
	# nádkunyhó
	var hx := inner.position.x + 40
	var hy := wy
	for i in 9:
		draw_line(Vector2(hx + i * 9, hy), Vector2(hx + i * 9 + 4, hy - 110), Color("6e7a2f"), 3.0)
	draw_line(Vector2(hx - 6, hy - 108), Vector2(hx + 88, hy - 112), Color("4f5a20"), 5.0)
	# alakok
	var base := wy - 2
	_figure(Vector2(inner.position.x + inner.size.x * 0.45, base), 190, Color("9c4a24"), false, false)
	_figure(Vector2(inner.position.x + inner.size.x * 0.62, base), 178, Color("d9a35a"), true, false)
	_figure(Vector2(inner.position.x + inner.size.x * 0.78, base), 112, Color("a5552b"), false, true)
	# repedések a festékben
	for i in 7:
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		var q := p
		for k in 4:
			var n := q + Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24))
			draw_line(q, n, Color(0.25, 0.15, 0.05, 0.35), 1.0)
			q = n


func _figure(foot: Vector2, h: float, skin: Color, female: bool, child: bool) -> void:
	var head_r := h * 0.075
	var head := foot + Vector2(0, -h + head_r)
	var shoulder_y := foot.y - h * 0.8
	var waist_y := foot.y - h * 0.5
	var white := Color("f1ead6")
	# lábak
	draw_line(Vector2(foot.x - h * 0.03, waist_y), Vector2(foot.x - h * 0.08, foot.y), skin, h * 0.045)
	draw_line(Vector2(foot.x + h * 0.03, waist_y), Vector2(foot.x + h * 0.1, foot.y), skin, h * 0.045)
	# törzs
	draw_colored_polygon(PackedVector2Array([Vector2(foot.x - h * 0.11, shoulder_y), Vector2(foot.x + h * 0.11, shoulder_y),
		Vector2(foot.x + h * 0.06, waist_y), Vector2(foot.x - h * 0.06, waist_y)]), skin)
	if female:
		draw_colored_polygon(PackedVector2Array([Vector2(foot.x - h * 0.09, shoulder_y + h * 0.05),
			Vector2(foot.x + h * 0.1, shoulder_y + h * 0.05), Vector2(foot.x + h * 0.12, foot.y - h * 0.08),
			Vector2(foot.x - h * 0.1, foot.y - h * 0.08)]), Color(white, 0.85))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(foot.x - h * 0.08, waist_y), Vector2(foot.x + h * 0.09, waist_y),
			Vector2(foot.x + h * 0.14, foot.y - h * 0.26), Vector2(foot.x - h * 0.09, foot.y - h * 0.26)]), white)
	# karok
	draw_line(Vector2(foot.x + h * 0.08, shoulder_y + 4), Vector2(foot.x + h * 0.2, waist_y - h * 0.04), skin, h * 0.035)
	draw_line(Vector2(foot.x - h * 0.08, shoulder_y + 4), Vector2(foot.x - h * 0.12, waist_y + h * 0.02), skin, h * 0.035)
	# nyak és fej
	draw_line(Vector2(foot.x, shoulder_y), Vector2(foot.x + 2, head.y + head_r), skin, h * 0.04)
	draw_circle(head, head_r, skin)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-head_r * 1.2, -head_r * 0.9), head + Vector2(head_r * 0.6, -head_r * 1.2),
		head + Vector2(head_r * 0.2, head_r * (2.2 if female else 0.9)), head + Vector2(-head_r * 1.3, head_r * (2.0 if female else 1.0))]),
		Color("1b1712"))
	draw_circle(head + Vector2(head_r * 0.55, -head_r * 0.1), head_r * 0.16, Color("1b1712"))
	# gallér
	draw_arc(Vector2(foot.x, shoulder_y), h * 0.1, 0.1, PI - 0.1, 12, Color("2f7f8a"), h * 0.025)
	if child:
		_boat(Vector2(foot.x + h * 0.34, waist_y - h * 0.08), 0.35, Color("6b3f1d"))


func _wood_back(r: Rect2, rng: RandomNumberGenerator) -> void:
	draw_rect(r, Color("5a3a1c"))
	for i in 60:
		var y := rng.randf_range(0, r.size.y)
		var pts := PackedVector2Array()
		for k in 12:
			pts.append(Vector2(k * r.size.x / 11.0, y + sin(k * 0.9 + i) * 4.0))
		draw_polyline(pts, Color(0.25, 0.15, 0.06, rng.randf_range(0.15, 0.35)), rng.randf_range(1, 3))
	var ink := Color(0.1, 0.07, 0.04, 0.85)
	for line in 4:
		var x := 60.0
		var y := 90.0 + line * 46
		while x < r.size.x - 80:
			var w := rng.randf_range(12, 40)
			draw_line(Vector2(x, y), Vector2(x + w, y + rng.randf_range(-3, 3)), ink, 3.0)
			x += w + rng.randf_range(8, 16)
	draw_string(T.font_glyph, Vector2(r.size.x * 0.5 - 50, r.size.y - 60), "𓀀𓁐", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, ink)


# ------------------------------------------------------------ agyagtábla, vallomás
func _seal_tablet(r: Rect2, rng: RandomNumberGenerator) -> void:
	draw_rect(r, Color(0.06, 0.09, 0.15))
	var tab := r.grow(-50)
	draw_rect(tab, Color("9e6139"))
	draw_rect(tab, Color("5e3a20"), false, 3.0)
	_seal(tab.get_center() + Vector2(-70, 0), 60, Color("7a2e18"))
	_seal(tab.get_center() + Vector2(60, -6), 64, Color("8a4426"))
	for i in 10:
		draw_line(tab.position + Vector2(20 + i * (tab.size.x - 40) / 10.0, 24),
			tab.position + Vector2(36 + i * (tab.size.x - 40) / 10.0, 24), Color(0.2, 0.1, 0.05), 3.0)
	if rng.randf() > 2.0:
		pass


func _testimony(r: Rect2, rng: RandomNumberGenerator) -> void:
	draw_rect(r, Color(0.05, 0.08, 0.15))
	for i in 40:
		draw_circle(Vector2(rng.randf_range(0, r.size.x), rng.randf_range(0, r.size.y * 0.6)), rng.randf_range(0.6, 1.8),
			Color(1, 0.9, 0.6, rng.randf_range(0.2, 0.8)))
	var c := r.get_center() + Vector2(-60, 40)
	var gold := Color(0.83, 0.65, 0.25)
	draw_string(T.font_glyph, c + Vector2(-60, -40), "𓂓", HORIZONTAL_ALIGNMENT_LEFT, -1, 140, Color(gold, 0.9))
	for i in 5:
		var y := r.size.y * 0.3 + i * 22
		draw_arc(Vector2(r.size.x * 0.68, y), 30 + i * 10, -0.7, 0.7, 12, Color(0.4, 0.8, 0.8, 0.5 - i * 0.07), 2.0)
	draw_line(Vector2(30, r.size.y - 40), Vector2(r.size.x - 30, r.size.y - 40), Color(gold, 0.6), 1.5)
