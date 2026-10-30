extends RefCounted
## Színek, betűk és a globális Godot-téma. Papirusz, arany szegély, lapis és homokkő.

const NAVY := Color("0d1b2e")
const DEEP := Color("070e1a")
const LAPIS := Color("1f3a7a")
const LAPIS_L := Color("3159b0")
const GOLD := Color("d4a640")
const GOLD_L := Color("f2d488")
const GOLD_D := Color("7d5f22")
const SAND := Color("d9c08f")
const PAPYRUS := Color("e9d8ac")
const PAPYRUS_D := Color("c8ad76")
const INK := Color("2b1d0e")
const INK_L := Color("6a5030")
const RED_INK := Color("9c2f1c")
const TURQ := Color("3fb0a6")
const OCHRE := Color("b8732e")
const RED := Color("b0472e")
const MUTED := Color("9aa3b8")
const DUAT := Color("8a63c9")
const ANKH := Color("4fbf7a")

const STATE_COLORS := {
	"confirmed": Color("3fb07a"), "supported": Color("3f9fb8"), "uncertain": Color("c9a23a"),
	"contradicted": Color("c0532e"), "fabricated": Color("9b4aa0"), "incomplete": Color("8a8a8a"),
	"empty": Color("5a5a5a")
}
const CATEGORY_COLORS := {
	"character": Color("b8732e"), "event": Color("3159b0"), "object": Color("d4a640"),
	"location": Color("4f9a5a"), "memory": Color("3fb0a6"), "evidence": Color("1f3a7a")
}

static var font_body: Font
static var font_title: Font
static var font_glyph: Font
static var theme: Theme
static var papyrus_shader: Shader


static func build() -> Theme:
	if theme != null:
		return theme
	var glyph := SystemFont.new()
	glyph.font_names = PackedStringArray(["Segoe UI Historic", "Noto Sans Egyptian Hieroglyphs", "Noto Sans"])
	font_glyph = glyph
	var fb: Array[Font] = [glyph]

	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Georgia", "Times New Roman", "serif"])
	body.fallbacks = fb
	font_body = body

	var title_sys := SystemFont.new()
	title_sys.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Georgia", "serif"])
	title_sys.font_weight = 700
	title_sys.fallbacks = fb
	var title := FontVariation.new()
	title.base_font = title_sys
	title.spacing_glyph = 1
	font_title = title

	papyrus_shader = load("res://shaders/papyrus.gdshader")

	var t := Theme.new()
	t.default_font = body
	t.default_font_size = 18

	t.set_color("font_color", "Label", PAPYRUS)
	t.set_color("default_color", "RichTextLabel", PAPYRUS)
	t.set_font("bold_font", "RichTextLabel", title_sys)
	t.set_font("italics_font", "RichTextLabel", body)

	# Gombok
	var bn := _flat(Color(LAPIS, 0.85), GOLD_D, 2, 6)
	bn.content_margin_left = 18
	bn.content_margin_right = 18
	bn.content_margin_top = 8
	bn.content_margin_bottom = 8
	var bh := bn.duplicate()
	bh.bg_color = Color(LAPIS_L, 0.95)
	bh.border_color = GOLD
	var bp := bn.duplicate()
	bp.bg_color = Color(NAVY, 1.0)
	bp.border_color = GOLD_L
	var bd := bn.duplicate()
	bd.bg_color = Color(0.15, 0.17, 0.22, 0.7)
	bd.border_color = Color(0.35, 0.33, 0.3)
	var bf := bh.duplicate()
	bf.border_color = GOLD_L
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("disabled", "Button", bd)
	t.set_stylebox("focus", "Button", _focus())
	t.set_color("font_color", "Button", PAPYRUS)
	t.set_color("font_hover_color", "Button", GOLD_L)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.55, 0.55))
	t.set_color("font_focus_color", "Button", GOLD_L)

	# Panelek
	t.set_stylebox("panel", "PanelContainer", _flat(Color(NAVY, 0.94), GOLD_D, 2, 6))
	t.set_stylebox("panel", "Panel", _flat(Color(NAVY, 0.94), GOLD_D, 2, 6))

	# Tooltip
	var tip := _flat(Color(DEEP, 0.97), GOLD, 1, 4)
	tip.content_margin_left = 10
	tip.content_margin_right = 10
	tip.content_margin_top = 6
	tip.content_margin_bottom = 6
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", PAPYRUS)

	# Görgetősáv
	var grab := _flat(Color(GOLD_D, 0.9), Color(0, 0, 0, 0), 0, 4)
	var grab_h := _flat(GOLD, Color(0, 0, 0, 0), 0, 4)
	var sbg := _flat(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 4)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab_h)
		t.set_stylebox("grabber_pressed", sb, grab_h)
		t.set_stylebox("scroll", sb, sbg)

	# Legördülő és lista
	t.set_stylebox("normal", "OptionButton", bn)
	t.set_stylebox("hover", "OptionButton", bh)
	t.set_stylebox("pressed", "OptionButton", bp)
	t.set_stylebox("focus", "OptionButton", _focus())
	t.set_color("font_color", "OptionButton", PAPYRUS)
	var pm := _flat(Color(DEEP, 0.98), GOLD_D, 1, 4)
	t.set_stylebox("panel", "PopupMenu", pm)
	t.set_color("font_color", "PopupMenu", PAPYRUS)
	t.set_color("font_hover_color", "PopupMenu", GOLD_L)
	t.set_stylebox("hover", "PopupMenu", _flat(Color(LAPIS, 0.9), Color(0, 0, 0, 0), 0, 2))
	t.set_stylebox("panel", "ItemList", _flat(Color(DEEP, 0.6), GOLD_D, 1, 4))
	t.set_color("font_color", "ItemList", PAPYRUS)
	t.set_stylebox("selected", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("selected_focus", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("hovered", "ItemList", _flat(Color(LAPIS, 0.4), Color(0, 0, 0, 0), 0, 2))

	theme = t
	return t


static func _flat(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.anti_aliasing = true
	return s


static func _focus() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = Color(GOLD_L, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	return s


static func flat(bg: Color, border: Color = GOLD_D, bw: int = 2, radius: int = 6, margin: int = 12) -> StyleBoxFlat:
	var s := _flat(bg, border, bw, radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s


static func state_color(state: String) -> Color:
	return STATE_COLORS.get(state, MUTED)
