extends Control
## Illusztrációs képkeret. Ha a res://assets/art/<kind>/<id>.(png|jpg|webp) létezik,
## kitöltve megjeleníti (alul sötétedő átmenettel). Ha nincs, hangulatos tartalékképet rajzol:
## színátmenetes ég, napkorong vagy hold, oszlopsziluettek és nagy, halvány jel.
## Így az illusztrációk egyszerűen bedobhatók a mappába, kódmódosítás nélkül.

const T = preload("res://scripts/ui/theme.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

## Tartalék paletták: [ég teteje, ég alja, fény, sziluett]
const MOODS := {
	"dawn": [Color("2a3b66"), Color("e2a35a"), Color("ffe2a0"), Color("3a2414")],
	"gold": [Color("4a2d16"), Color("d08a3c"), Color("ffd27a"), Color("2a170b")],
	"amber": [Color("3b1f14"), Color("b9692f"), Color("f7c071"), Color("24130a")],
	"night": [Color("0f1230"), Color("4b3a7a"), Color("b9b6ff"), Color("0a0a1a")],
	"tomb": [Color("120c08"), Color("6a4320"), Color("f2b45a"), Color("0a0604")],
	"teal": [Color("0f2a33"), Color("3f8f86"), Color("c8f0d8"), Color("0a1a1c")],
}

var texture: Texture2D
var glyph := ""
var mood := "dawn"
var fade_bottom := 0.55
var frame := true
## A kivágás fókusza (0..1): hová essen a kép, ha a keret más arányú. Alapból kicsit a közép fölé.
var focus := Vector2(0.5, 0.3)
var _seed := 0


static func find(kind: String, id: String) -> Texture2D:
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/art/%s/%s.%s" % [kind, id, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return null


func setup(kind: String, id: String, p_glyph := "", p_mood := "dawn") -> void:
	texture = find(kind, id)
	glyph = p_glyph
	mood = p_mood if MOODS.has(p_mood) else "dawn"
	_seed = hash(kind + id)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if texture != null:
		_draw_cover(r)
	else:
		_draw_fallback(r)
	if fade_bottom > 0.0:
		var h := r.size.y * fade_bottom
		Fresco.gradient(self, Rect2(0, r.size.y - h, r.size.x, h), Color(0.04, 0.05, 0.1, 0.0), Color(0.04, 0.05, 0.1, 0.92))
	if frame:
		draw_rect(r, Color(T.GOLD_D, 0.9), false, 1.5)


func _draw_cover(r: Rect2) -> void:
	var ts := texture.get_size()
	var scale := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src := Vector2(r.size.x / scale, r.size.y / scale)
	var off := (ts - src) * focus
	draw_texture_rect_region(texture, r, Rect2(off, src))


func _draw_fallback(r: Rect2) -> void:
	var m: Array = MOODS[mood]
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	Fresco.gradient(self, r, m[0], m[1])
	# napkorong / hold, fénykoszorúval
	var sun := Vector2(r.size.x * rng.randf_range(0.55, 0.8), r.size.y * 0.42)
	for i in 6:
		draw_circle(sun, r.size.y * (0.10 + i * 0.07), Color(m[2], 0.07))
	draw_circle(sun, r.size.y * 0.09, Color(m[2], 0.9))
	# távoli piramis vagy pülon, aztán oszlopok
	var base := r.size.y * 0.78
	var px := r.size.x * rng.randf_range(0.15, 0.35)
	draw_colored_polygon(PackedVector2Array([Vector2(px - r.size.y * 0.3, base), Vector2(px, base - r.size.y * 0.32),
		Vector2(px + r.size.y * 0.3, base)]), Color(m[3], 0.55))
	var cols := 2 + rng.randi() % 3
	for i in cols:
		var x := r.size.x * (0.08 + 0.84 * float(i) / maxi(1, cols - 1))
		var w := r.size.x * 0.035 + 4.0
		draw_rect(Rect2(x - w * 0.5, r.size.y * 0.25, w, base - r.size.y * 0.25), Color(m[3], 0.85))
		draw_rect(Rect2(x - w, r.size.y * 0.22, w * 2.0, r.size.y * 0.04), Color(m[3], 0.9))
	draw_rect(Rect2(0, base, r.size.x, r.size.y - base), Color(m[3], 0.95))
	# vízfelszín csillogás
	for i in 8:
		var y := base + 4 + i * 3.0
		draw_line(Vector2(sun.x - 30 + rng.randf_range(-10, 10), y), Vector2(sun.x + 30 + rng.randf_range(-10, 10), y),
			Color(m[2], 0.18 - i * 0.02), 1.0)
	if glyph != "":
		var fs := int(r.size.y * 0.42)
		var gs := T.font_glyph.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(T.font_glyph, Vector2((r.size.x - gs.x) * 0.5, r.size.y * 0.62), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1,
			fs, Color(m[2], 0.28))
