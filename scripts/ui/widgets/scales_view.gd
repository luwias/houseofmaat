extends Control
## A Ma'at mérlege: a szív és a toll. A dőlés a rekonstrukció szerinti egyensúlyt mutatja.

const T = preload("res://scripts/ui/theme.gd")

var balance := 0.0
var shown := 0.0
var _t := 0.0


func set_balance(b: float) -> void:
	balance = clampf(b / 80.0, -1.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	shown = lerpf(shown, balance, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, 40)
	var gold := T.GOLD
	var ang := shown * 0.32 + sin(_t * 1.4) * 0.015
	var arm := size.x * 0.36
	draw_line(Vector2(c.x, c.y), Vector2(c.x, size.y - 30), gold, 5.0)
	draw_rect(Rect2(c.x - 60, size.y - 32, 120, 14), T.GOLD_D)
	draw_circle(c, 9, gold)
	var l := c + Vector2(-arm, 0).rotated(ang)
	var r := c + Vector2(arm, 0).rotated(ang)
	draw_line(l, r, gold, 5.0)
	for side in [l, r]:
		var pan: Vector2 = side + Vector2(0, 90)
		draw_line(side, pan + Vector2(-42, 0), Color(gold, 0.8), 1.5)
		draw_line(side, pan + Vector2(42, 0), Color(gold, 0.8), 1.5)
		draw_arc(pan, 46, 0.15, PI - 0.15, 18, gold, 4.0)
	# toll (Ma'at) balra, szív jobbra
	var fp := l + Vector2(0, 90)
	draw_string(T.font_glyph, fp + Vector2(-16, 6), "𓆄", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(0.95, 0.92, 0.85))
	var hp := r + Vector2(0, 90)
	draw_string(T.font_glyph, hp + Vector2(-16, 6), "𓄣", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0.75, 0.25, 0.15))
	draw_string(T.font_body, Vector2(fp.x - 30, fp.y + 46), "Ma'at", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, T.SAND)
	draw_string(T.font_body, Vector2(hp.x - 22, hp.y + 46), Loc.t("scales_heart"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, T.SAND)
