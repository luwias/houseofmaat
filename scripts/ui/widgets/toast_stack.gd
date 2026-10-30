extends VBoxContainer
## Értesítések a jobb felső sarokban (új bizonyíték, megváltozott értelmezés, új jel…).

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")

const KIND := {
	"evidence": ["𓏞", T.GOLD], "reliability": ["𓆄", T.OCHRE], "interp": ["𓁹", T.TURQ],
	"glyph": ["𓋹", T.GOLD_L], "memory": ["𓂀", T.TURQ], "clue": ["𓂝", T.GOLD],
	"bad": ["𓇽", T.RED], "good": ["𓋹", T.ANKH], "locked": ["🔒", T.MUTED], "info": ["𓆄", T.SAND]
}
const MAX := 6


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -440
	offset_right = -18
	offset_top = 84
	if T.compact:
		# telefonon alul, középen, hogy ne takarja a bezárógombokat
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		offset_left = -300
		offset_right = 300
		offset_top = -150
		offset_bottom = -70
		grow_vertical = Control.GROW_DIRECTION_BEGIN
		alignment = BoxContainer.ALIGNMENT_END
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func push(text: String, kind := "info") -> void:
	var k: Array = KIND.get(kind, KIND.info)
	var p := UI.box_panel(Color(T.DEEP, 0.94), k[1], 1, 10, 6)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := UI.glyphs(k[0], 22, k[1])
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(g)
	var l := UI.label(text, 15, T.PAPYRUS, true)
	l.custom_minimum_size.x = T.px(340)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	p.add_child(h)
	add_child(p)
	while get_child_count() > MAX:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.25)
	tw.tween_interval(5.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)
