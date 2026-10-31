extends RefCounted
## Díszítő rajzolások: vékony arany kettős keret díszített sarkokkal, arany elválasztó
## középső rombusszal, függőleges színátmenet. Visszafogott, elegáns, nem harsány.

const T = preload("res://scripts/ui/theme.gd")


## Függőleges színátmenet egy téglalapra.
static func gradient(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


static func diamond(ci: CanvasItem, c: Vector2, s: float, col: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)])
	ci.draw_colored_polygon(pts, col)
	if outline.a > 0.0:
		ci.draw_polyline(pts + PackedVector2Array([pts[0]]), outline, 1.0)


## Arany kettős keret: külső élénk vonal, belső halványabb; a sarkokban kampós díszítés.
static func gold_frame(ci: CanvasItem, r: Rect2, inset: float = 3.0, corners: bool = true) -> void:
	var outer := r.grow(-inset)
	var inner := r.grow(-inset - 4.0)
	ci.draw_rect(outer, Color(T.GOLD, 0.85), false, 1.2)
	ci.draw_rect(inner, Color(T.GOLD_D, 0.55), false, 1.0)
	if not corners:
		return
	var l := minf(26.0, minf(r.size.x, r.size.y) * 0.18)
	var g := T.GOLD_L
	for i in 4:
		var sx := 1.0 if i % 2 == 0 else -1.0
		var sy := 1.0 if i < 2 else -1.0
		var p := Vector2(outer.position.x if sx > 0 else outer.end.x, outer.position.y if sy > 0 else outer.end.y)
		ci.draw_line(p, p + Vector2(l * sx, 0), g, 2.2)
		ci.draw_line(p, p + Vector2(0, l * sy), g, 2.2)
		ci.draw_line(p + Vector2(7 * sx, 7 * sy), p + Vector2(l * 0.6 * sx, 7 * sy), Color(g, 0.7), 1.0)
		ci.draw_line(p + Vector2(7 * sx, 7 * sy), p + Vector2(7 * sx, l * 0.6 * sy), Color(g, 0.7), 1.0)
		diamond(ci, p + Vector2(3.5 * sx, 3.5 * sy), 3.0, g)


## Vízszintes arany elválasztó: a széleken elhalványuló vonal, középen rombusz.
static func ornament_line(ci: CanvasItem, r: Rect2) -> void:
	var y := r.position.y + r.size.y * 0.5
	var cx := r.position.x + r.size.x * 0.5
	var steps := 24
	for i in steps:
		var a := float(i) / steps
		var b := float(i + 1) / steps
		var alpha := sin(a * PI) * 0.9
		ci.draw_line(Vector2(r.position.x + r.size.x * a, y), Vector2(r.position.x + r.size.x * b, y), Color(T.GOLD, alpha), 1.0)
	diamond(ci, Vector2(cx, y), 4.0, T.GOLD, T.GOLD_D)
	diamond(ci, Vector2(cx - 12, y), 2.0, Color(T.GOLD, 0.8))
	diamond(ci, Vector2(cx + 12, y), 2.0, Color(T.GOLD, 0.8))
