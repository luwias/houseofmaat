extends RefCounted
## Felületépítő segédfüggvények. A képernyők kódból épülnek, egységes stílussal.

const T = preload("res://scripts/ui/theme.gd")
const PapyrusPanel = preload("res://scripts/ui/widgets/papyrus_panel.gd")
const FriezeStrip = preload("res://scripts/ui/widgets/frieze_strip.gd")

const ORNAMENT := "𓋹  𓆄  𓂀  𓊽  𓋹  𓆄  𓂀  𓊽  𓋹"


static func label(text: String, size: int = 18, color: Color = T.PAPYRUS, wrap: bool = false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 40
	return l


static func ink(text: String, size: int = 18, wrap: bool = true) -> Label:
	return label(text, size, T.INK, wrap)


static func title(text: String, size: int = 30, color: Color = T.GOLD,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size, color, false, align)
	l.add_theme_font_override("font", T.font_title)
	return l


static func glyphs(text: String, size: int = 22, color: Color = T.GOLD,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, false, align)
	l.add_theme_font_override("font", T.font_glyph)
	return l


static func ornament(color: Color = T.GOLD_D, size: int = 18) -> Label:
	var l := glyphs(ORNAMENT, size, color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func rich(bbcode: String, size: int = 18, color: Color = T.INK) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bbcode
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.custom_minimum_size.x = 60
	r.selection_enabled = false
	return r


static func button(text: String, cb: Callable = Callable(), min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func ghost_button(text: String, cb: Callable = Callable(), color: Color = T.GOLD) -> Button:
	var b := button(text, cb)
	var n := T.flat(Color(0, 0, 0, 0), Color(color, 0.0), 0, 4, 6)
	var h := T.flat(Color(color, 0.12), Color(color, 0.5), 1, 4, 6)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", color)
	return b


## Papiruszon / vakolaton használt világos festett tábla.
static func ink_button(text: String, cb: Callable = Callable()) -> Button:
	var b := button(text, cb)
	b.add_theme_stylebox_override("normal", T.tablet("plaster"))
	b.add_theme_stylebox_override("hover", T.tablet("plaster_hover"))
	b.add_theme_stylebox_override("pressed", T.tablet("plaster_pressed"))
	b.add_theme_stylebox_override("disabled", T.tablet("plaster_disabled"))
	b.add_theme_color_override("font_color", T.CREAM)
	b.add_theme_color_override("font_hover_color", T.GOLD_L)
	b.add_theme_color_override("font_pressed_color", T.GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.75, 0.72, 0.66))
	return b


static func papyrus(margin: int = 22) -> PanelContainer:
	return PapyrusPanel.new(margin)


## Sötét festett panel: csillagos sírmennyezet színes sávkerettel.
static func dark_panel(margin: int = 16, _alpha: float = 0.94, _border: Color = T.GOLD_D, kheker := false) -> PanelContainer:
	return PapyrusPanel.new(margin, "night", kheker)


## Kiemelt, piros festett tábla (fő művelet).
static func primary_button(text: String, cb: Callable = Callable(), min_w: int = 0) -> Button:
	var b := button(text, cb, min_w)
	b.add_theme_stylebox_override("normal", T.tablet("red"))
	b.add_theme_stylebox_override("hover", T.tablet("red_hover"))
	return b


static func box_panel(bg: Color, border: Color, bw: int = 1, margin: int = 10, radius: int = 6) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.flat(bg, border, bw, radius, margin))
	return p


static func vbox(sep: int = 10) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func hbox(sep: int = 10) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func flow(sep: int = 8) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f


static func margin(node: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	if node != null:
		m.add_child(node)
	return m


static func spacer(expand_h: bool = true, min_size: int = 0) -> Control:
	var c := Control.new()
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size.x = min_size
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size.y = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func scroll(child: Control, horizontal: bool = false) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


static func badge(text: String, color: Color, size: int = 14) -> PanelContainer:
	var p := box_panel(color.darkened(0.15), Color(color.lightened(0.25), 0.8), 1, 4, 3)
	var st: StyleBoxFlat = p.get_theme_stylebox("panel")
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	var l := label(text, size, Color(1, 0.98, 0.92))
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func state_badge(state: String, size: int = 14) -> PanelContainer:
	var col := T.state_color(state)
	var p := box_panel(col.darkened(0.1), Color(col.lightened(0.3), 0.8), 1, 4, 3)
	var st: StyleBoxFlat = p.get_theme_stylebox("panel")
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	p.add_child(label(Loc.t("state_" + state), size, Color(1, 0.98, 0.92)))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func separator(color: Color = T.GOLD_D) -> Control:
	if color == T.GOLD_D:
		return FriezeStrip.new(7.0)
	var c := ColorRect.new()
	c.color = Color(color, 0.7)
	c.custom_minimum_size = Vector2(0, 1)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func reliability_text(v: float) -> String:
	var key := "rel_low"
	if v >= 80:
		key = "rel_high"
	elif v >= 60:
		key = "rel_good"
	elif v >= 40:
		key = "rel_mid"
	var dots := ""
	var n := int(round(v / 20.0))
	for i in 5:
		dots += "●" if i < n else "○"
	return "%s %s" % [dots, Loc.t(key)]


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
