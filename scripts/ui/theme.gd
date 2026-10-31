extends RefCounted
## Vizuális nyelv: mély navy felületek vékony arany vonalakkal és díszített sarkokkal,
## meleg pergamen dokumentumok, elegáns, visszafogott gombok.

# --- paletta (a régi nevek megmaradtak, hogy minden képernyő automatikusan átálljon)
const NAVY := Color("131b30")
const DEEP := Color("0a0f1c")
const LAPIS := Color("2a4178")
const LAPIS_L := Color("3d63b4")
const GOLD := Color("d8aa52")
const GOLD_L := Color("f3d696")
const GOLD_D := Color("8a6a30")
const SAND := Color("d9c49b")
const PAPYRUS := Color("eadbb6")
const PAPYRUS_D := Color("cfb37e")
const INK := Color("1e150d")
const INK_L := Color("6b4f2e")
const RED_INK := Color("a3361f")
const TURQ := Color("2f9b8f")
const OCHRE := Color("c27b2c")
const RED := Color("b0412a")
const MUTED := Color("9e9787")
const DUAT := Color("8a63c9")
const ANKH := Color("5aa86a")
const BLACK := Color("120c07")
const CREAM := Color("efe1bf")
const EGY_GREEN := Color("3f8a5a")
const EGY_BLUE := Color("2b4f9e")

const STATE_COLORS := {
	"confirmed": Color("3f8a5a"), "supported": Color("2f6fae"), "uncertain": Color("c4892c"),
	"contradicted": Color("b0412a"), "fabricated": Color("7a4a78"), "incomplete": Color("8a8274"),
	"empty": Color("5c564c")
}
const CATEGORY_COLORS := {
	"character": Color("b0412a"), "event": Color("2b4f9e"), "object": Color("c4892c"),
	"location": Color("3f8a5a"), "memory": Color("2f9b8f"), "evidence": Color("1e150d")
}

## Mobil/kompakt mód: a felület nagyobb skálán fut (olvasható szöveg telefonon),
## ezért a fix méretek arányosan kisebbek.
static var compact := false
const COMPACT_SIZE := 0.72

static var font_body: Font
static var font_body_bold: Font
static var font_italic: Font
static var font_title: Font
static var font_glyph: Font
static var theme: Theme
static var papyrus_shader: Shader
static var tablets := {}


static func _weighted(path: String, weight: int, fallbacks: Array[Font]) -> Font:
	var base: FontFile = load(path)
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	fv.fallbacks = fallbacks
	return fv


static func build() -> Theme:
	if theme != null:
		return theme
	var glyph: FontFile = load("res://assets/fonts/NotoSansEgyptianHieroglyphs.ttf")
	font_glyph = glyph
	var fb: Array[Font] = [glyph]
	font_body = _weighted("res://assets/fonts/EBGaramond.ttf", 450, fb)
	font_body_bold = _weighted("res://assets/fonts/EBGaramond.ttf", 650, fb)
	font_italic = _weighted("res://assets/fonts/EBGaramond-Italic.ttf", 450, fb)
	var title := _weighted("res://assets/fonts/Cinzel.ttf", 650, fb) as FontVariation
	title.spacing_glyph = 1
	font_title = title

	papyrus_shader = load("res://shaders/papyrus.gdshader")
	_build_tablets()

	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 19

	t.set_color("font_color", "Label", PAPYRUS)
	t.set_color("default_color", "RichTextLabel", PAPYRUS)
	t.set_font("bold_font", "RichTextLabel", font_body_bold)
	t.set_font("italics_font", "RichTextLabel", font_italic)
	t.set_font("bold_italics_font", "RichTextLabel", font_italic)

	# Gombok: festett táblák (generált 9-szeletes textúra)
	t.set_stylebox("normal", "Button", tablets.normal)
	t.set_stylebox("hover", "Button", tablets.hover)
	t.set_stylebox("pressed", "Button", tablets.pressed)
	t.set_stylebox("disabled", "Button", tablets.disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", font_body_bold)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", GOLD_L)
	t.set_color("font_pressed_color", "Button", CREAM)
	t.set_color("font_disabled_color", "Button", Color(0.62, 0.58, 0.52))
	t.set_color("font_focus_color", "Button", GOLD_L)
	t.set_color("font_outline_color", "Button", BLACK)
	t.set_font("font", "Button", font_body)

	# Panelek (a legtöbb képernyő a festett panelt használja, ez csak alapértelmezés)
	t.set_stylebox("panel", "PanelContainer", _flat(Color(NAVY, 0.96), Color(GOLD_D, 0.8), 1, 3))
	t.set_stylebox("panel", "Panel", _flat(Color(NAVY, 0.96), Color(GOLD_D, 0.8), 1, 3))

	# Tooltip: kis papirusz
	var tip := _flat(Color("0e1526"), GOLD_D, 1, 3)
	tip.content_margin_left = 10
	tip.content_margin_right = 10
	tip.content_margin_top = 6
	tip.content_margin_bottom = 6
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", PAPYRUS)
	t.set_font("font", "TooltipLabel", font_body)

	# Görgetősáv: vékony festett rúd
	var grab := _flat(Color(GOLD_D, 0.9), Color(0, 0, 0, 0), 0, 3)
	var grab_h := _flat(GOLD, Color(0, 0, 0, 0), 0, 3)
	var sbg := _flat(Color(0, 0, 0, 0.22), Color(0, 0, 0, 0), 0, 2)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab_h)
		t.set_stylebox("grabber_pressed", sb, grab_h)
		t.set_stylebox("scroll", sb, sbg)

	# Legördülő és lista
	t.set_stylebox("normal", "OptionButton", tablets.normal)
	t.set_stylebox("hover", "OptionButton", tablets.hover)
	t.set_stylebox("pressed", "OptionButton", tablets.pressed)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_color("font_color", "OptionButton", CREAM)
	t.set_font("font", "OptionButton", font_body_bold)
	var pm := _flat(Color("0e1526"), GOLD_D, 1, 3)
	t.set_stylebox("panel", "PopupMenu", pm)
	t.set_color("font_color", "PopupMenu", PAPYRUS)
	t.set_color("font_hover_color", "PopupMenu", GOLD_L)
	t.set_font("font", "PopupMenu", font_body)
	t.set_stylebox("hover", "PopupMenu", _flat(Color(LAPIS, 0.8), Color(0, 0, 0, 0), 0, 2))
	t.set_stylebox("panel", "ItemList", _flat(Color(DEEP, 0.6), BLACK, 1, 2))
	t.set_color("font_color", "ItemList", PAPYRUS)
	t.set_stylebox("selected", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("selected_focus", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("hovered", "ItemList", _flat(Color(LAPIS, 0.4), Color(0, 0, 0, 0), 0, 2))

	theme = t
	return t


# ------------------------------------------------------------ gombstílusok
static func _btn(bg: Color, border: Color, bw: int = 1) -> StyleBoxFlat:
	var sb := _flat(bg, border, bw, 3)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 9
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func _build_tablets() -> void:
	tablets = {
		"normal": _btn(Color("111a2f"), Color(GOLD_D, 0.95)),
		"hover": _btn(Color("1a2747"), GOLD),
		"pressed": _btn(Color("0b111f"), GOLD_L),
		"disabled": _btn(Color("12161f"), Color(0.32, 0.3, 0.27)),
		"selected": _btn(Color("2a4178"), GOLD_L, 2),
		"plaster": _btn(Color("111a2f"), Color(GOLD_D, 0.95)),
		"plaster_hover": _btn(Color("1a2747"), GOLD),
		"plaster_pressed": _btn(Color("0b111f"), GOLD_L),
		"plaster_disabled": _btn(Color("3b3a37"), Color(0.45, 0.42, 0.37)),
		"red": _btn(Color("2a4178"), GOLD_L, 2),
		"red_hover": _btn(Color("34508f"), GOLD_L, 2),
	}


static func tablet(kind: String) -> StyleBox:
	return tablets.get(kind, tablets.normal)


# ------------------------------------------------------------ segédek
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


static func flat(bg: Color, border: Color = BLACK, bw: int = 2, radius: int = 2, margin: int = 12) -> StyleBoxFlat:
	var s := _flat(bg, border, bw, radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s


static func px(v: float) -> float:
	return v * COMPACT_SIZE if compact else v


static func v2(x: float, y: float) -> Vector2:
	return Vector2(px(x), px(y))


static func state_color(state: String) -> Color:
	return STATE_COLORS.get(state, MUTED)
