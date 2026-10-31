extends Control
## Esetfejléc haladásjelzője: „Bizonyítékok 6 / 14” szegmentált arany sávval és
## „Kitöltött jelenetek 2 / 5” pontsorral, vékony arany keretben.

const T = preload("res://scripts/ui/theme.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

var found := 0
var total := 1
var filled := 0
var scenes := 5


func _init() -> void:
	custom_minimum_size = Vector2(0, 40)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(p_found: int, p_total: int, p_filled: int, p_scenes: int) -> void:
	found = p_found
	total = maxi(1, p_total)
	filled = p_filled
	scenes = maxi(1, p_scenes)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.03, 0.05, 0.1, 0.72))
	draw_rect(r, Color(T.GOLD_D, 0.9), false, 1.0)
	var f: Font = T.font_body
	var fb: Font = T.font_body_bold
	var y := size.y * 0.5 + 6
	var x := 16.0
	var lbl := Loc.t("ps_evidence")
	draw_string(f, Vector2(x, y), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, T.PAPYRUS)
	x += f.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 10
	var num := "%d / %d" % [found, total]
	draw_string(fb, Vector2(x, y), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, T.GOLD)
	x += fb.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 18
	# szegmentált sáv
	var right_w := 300.0
	var bar_w := maxf(80.0, size.x - x - right_w - 40)
	var bar := Rect2(x, size.y * 0.5 - 5, bar_w, 10)
	draw_rect(bar, Color(0, 0, 0, 0.55))
	var seg := bar_w / total
	for i in total:
		var sr := Rect2(bar.position.x + i * seg + 1, bar.position.y + 1, seg - 2, bar.size.y - 2)
		if i < found:
			Fresco.gradient(self, sr, T.GOLD_L, T.GOLD)
	draw_rect(bar, Color(T.GOLD_D, 0.9), false, 1.0)
	# jelenetek pontsora
	var rx := size.x - right_w
	var lbl2 := Loc.t("ps_scenes")
	draw_string(f, Vector2(rx, y), lbl2, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, T.PAPYRUS)
	rx += f.get_string_size(lbl2, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 10
	var num2 := "%d / %d" % [filled, scenes]
	draw_string(fb, Vector2(rx, y), num2, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, T.GOLD)
	rx += fb.get_string_size(num2, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 14
	for i in scenes:
		var c := Vector2(rx + i * 20, size.y * 0.5)
		if i < filled:
			draw_circle(c, 6, T.GOLD)
		else:
			draw_arc(c, 6, 0, TAU, 18, Color(T.GOLD, 0.8), 1.5)
		if i < scenes - 1:
			draw_line(c + Vector2(7, 0), c + Vector2(13, 0), Color(T.GOLD_D, 0.8), 1.0)
