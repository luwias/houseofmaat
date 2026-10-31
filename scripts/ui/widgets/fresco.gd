extends RefCounted
## Egyiptomi díszítőelemek rajzolása: színes sávkeret (block border), kheker-fríz,
## csillagos mennyezet, kettős tintavonal. Minden festett panel és fejléc ezt használja.

const T = preload("res://scripts/ui/theme.gd")

const BLOCKS := [T.EGY_BLUE, T.RED, T.EGY_GREEN, T.RED]


## Vízszintes vagy függőleges színes sávkeret: fekete keret, krém köz, színes téglák.
static func band(ci: CanvasItem, r: Rect2, horizontal: bool) -> void:
	ci.draw_rect(r, T.BLACK)
	var inner := r.grow(-1.5)
	ci.draw_rect(inner, T.CREAM)
	var thick := inner.size.y if horizontal else inner.size.x
	var block := maxf(thick * 2.8, 12.0)
	var gap := maxf(thick * 0.45, 3.0)
	var length := inner.size.x if horizontal else inner.size.y
	var count := maxi(1, int(length / (block + gap)))
	var step := length / count
	for i in count:
		var c: Color = BLOCKS[i % BLOCKS.size()]
		var a := i * step + gap * 0.5
		var br: Rect2
		if horizontal:
			br = Rect2(inner.position.x + a, inner.position.y + 1.0, step - gap, inner.size.y - 2.0)
		else:
			br = Rect2(inner.position.x + 1.0, inner.position.y + a, inner.size.x - 2.0, step - gap)
		ci.draw_rect(br, c)
		ci.draw_rect(br, T.BLACK, false, 1.0)


## Teljes keret négy sávból, fekete sarokkockákkal.
static func frame(ci: CanvasItem, r: Rect2, w: float) -> void:
	band(ci, Rect2(r.position.x + w, r.position.y, r.size.x - 2 * w, w), true)
	band(ci, Rect2(r.position.x + w, r.end.y - w, r.size.x - 2 * w, w), true)
	band(ci, Rect2(r.position.x, r.position.y + w, w, r.size.y - 2 * w), false)
	band(ci, Rect2(r.end.x - w, r.position.y + w, w, r.size.y - 2 * w), false)
	for p in [r.position, Vector2(r.end.x - w, r.position.y), Vector2(r.position.x, r.end.y - w), r.end - Vector2(w, w)]:
		ci.draw_rect(Rect2(p, Vector2(w, w)), T.BLACK)
		ci.draw_rect(Rect2(p + Vector2(w * 0.3, w * 0.3), Vector2(w * 0.4, w * 0.4)), T.GOLD)


## Kheker-fríz: lekerekített tetejű, csomós elemek váltakozó színben (a sírfalak felső díszsávja).
static func kheker(ci: CanvasItem, r: Rect2) -> void:
	var colors := [T.EGY_BLUE, T.RED, T.EGY_GREEN, T.GOLD]
	var w := maxf(r.size.y * 0.42, 7.0)
	var count := maxi(1, int(r.size.x / w))
	var step := r.size.x / count
	ci.draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), T.BLACK)
	for i in count:
		var x := r.position.x + i * step
		var c: Color = colors[i % colors.size()]
		var body := Rect2(x + 1.5, r.position.y + step * 0.45, step - 3.0, r.size.y - step * 0.45 - 3.0)
		ci.draw_rect(body, c)
		ci.draw_circle(Vector2(x + step * 0.5, body.position.y), (step - 3.0) * 0.5, c)
		# a csomó: két vízszintes szalag
		var ky := body.position.y + body.size.y * 0.55
		ci.draw_rect(Rect2(body.position.x, ky, body.size.x, 2.0), T.BLACK)
		ci.draw_rect(Rect2(body.position.x, ky + 4.0, body.size.x, 2.0), T.BLACK)
		ci.draw_arc(Vector2(x + step * 0.5, body.position.y), (step - 3.0) * 0.5, PI, TAU, 10, T.BLACK, 1.0)
		ci.draw_line(Vector2(body.position.x, body.position.y), Vector2(body.position.x, body.end.y), T.BLACK, 1.0)
		ci.draw_line(Vector2(body.end.x, body.position.y), Vector2(body.end.x, body.end.y), T.BLACK, 1.0)


## Ötágú csillag (a sírmennyezetek sárga csillagai).
static func star(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		var rr := rad if i % 2 == 0 else rad * 0.42
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


static func stars(ci: CanvasItem, r: Rect2, seed_v: int, density: float = 0.00012) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := int(r.size.x * r.size.y * density)
	for i in n:
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		star(ci, p, rng.randf_range(2.2, 3.6), Color(T.GOLD, rng.randf_range(0.10, 0.22)))


## Papiruszok kettős vonala: fekete külső, vörös belső tintavonal.
static func ink_rules(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r.grow(-6), Color(T.BLACK, 0.75), false, 1.6)
	ci.draw_rect(r.grow(-10), Color(T.RED_INK, 0.65), false, 1.2)
