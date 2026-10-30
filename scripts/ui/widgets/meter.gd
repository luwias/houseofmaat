extends Control
## Templomérték-kijelző (Ma'at / Ankh / Duat). Animáltan követi a valódi értéket,
## és változáskor felvillantja a különbséget.

const T = preload("res://scripts/ui/theme.gd")

var label_text := ""
var glyph := ""
var color := T.GOLD
var value := 0.0
var shown := 0.0
var _delta_text := ""
var _delta_t := 0.0
var _delta_good := true
var inverse := false


func setup(p_label: String, p_glyph: String, p_color: Color, p_inverse := false) -> void:
	label_text = p_label
	glyph = p_glyph
	color = p_color
	inverse = p_inverse
	custom_minimum_size = Vector2(T.px(190), 44)
	mouse_filter = Control.MOUSE_FILTER_PASS


func set_value(v: float, animate := true) -> void:
	var d := v - value
	if animate and absf(d) >= 0.5:
		_delta_text = ("+%d" if d > 0 else "%d") % int(round(d))
		_delta_good = (d > 0) != inverse
		_delta_t = 4.0
	value = v
	if not animate:
		shown = v
	queue_redraw()


func _process(delta: float) -> void:
	var changed := false
	if absf(shown - value) > 0.05:
		shown = move_toward(shown, value, delta * 14.0)
		changed = true
	if _delta_t > 0.0:
		_delta_t -= delta
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var f: Font = T.font_body
	var fg: Font = T.font_glyph
	draw_string(fg, Vector2(0, 30), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	draw_string(f, Vector2(36, 16), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, T.PAPYRUS)
	draw_string(f, Vector2(size.x - 34, 16), str(int(round(shown))), HORIZONTAL_ALIGNMENT_RIGHT, 34, 15, color.lightened(0.3))
	var r := Rect2(36, 24, size.x - 36, 9)
	draw_rect(r, Color(0, 0, 0, 0.45))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(shown / 100.0, 0, 1), r.size.y)), color)
	draw_rect(r, Color(T.GOLD_D, 0.9), false, 1.0)
	for i in range(1, 4):
		var x := r.position.x + r.size.x * i / 4.0
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.35), 1.0)
	if _delta_t > 0.0:
		var a := clampf(_delta_t, 0.0, 1.0)
		var c := Color(T.ANKH if _delta_good else T.RED, a)
		draw_string(f, Vector2(size.x - 80, 16), _delta_text, HORIZONTAL_ALIGNMENT_RIGHT, 40, 15, c)
