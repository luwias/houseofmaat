extends RefCounted
## A „sírfestmény” vizuális nyelv: thébai sírkamrák színei, festett táblák, színes sávkeretek.
## Sötét felület = csillagos sírmennyezet (mélykék), világos felület = papirusz / vakolat.

# --- paletta (a régi nevek megmaradtak, hogy minden képernyő automatikusan átálljon)
const NAVY := Color("161c30")       # éjszakai lapis – a sírmennyezet
const DEEP := Color("0d111e")
const LAPIS := Color("27468f")
const LAPIS_L := Color("3d63b4")
const GOLD := Color("e6b04a")       # festett okkersárga, nem fémes arany
const GOLD_L := Color("f7d98f")
const GOLD_D := Color("8f6626")
const SAND := Color("d9c49b")
const PAPYRUS := Color("f0e2c0")
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

	# Panelek (a legtöbb képernyő a festett panelt használja, ez csak alapértelmezés)
	t.set_stylebox("panel", "PanelContainer", _flat(Color(NAVY, 0.96), BLACK, 2, 2))
	t.set_stylebox("panel", "Panel", _flat(Color(NAVY, 0.96), BLACK, 2, 2))

	# Tooltip: kis papirusz
	var tip := _flat(PAPYRUS, BLACK, 2, 2)
	tip.content_margin_left = 10
	tip.content_margin_right = 10
	tip.content_margin_top = 6
	tip.content_margin_bottom = 6
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font("font", "TooltipLabel", font_body)

	# Görgetősáv: vékony festett rúd
	var grab := _flat(GOLD_D, BLACK, 1, 2)
	var grab_h := _flat(GOLD, BLACK, 1, 2)
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
	var pm := _flat(PAPYRUS, BLACK, 2, 2)
	t.set_stylebox("panel", "PopupMenu", pm)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", RED_INK)
	t.set_font("font", "PopupMenu", font_body)
	t.set_stylebox("hover", "PopupMenu", _flat(Color(GOLD, 0.55), Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("panel", "ItemList", _flat(Color(DEEP, 0.6), BLACK, 1, 2))
	t.set_color("font_color", "ItemList", PAPYRUS)
	t.set_stylebox("selected", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("selected_focus", "ItemList", _flat(Color(LAPIS, 0.9), GOLD, 1, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("hovered", "ItemList", _flat(Color(LAPIS, 0.4), Color(0, 0, 0, 0), 0, 2))

	theme = t
	return t


# ------------------------------------------------------------ festett táblák
## Egy festett tábla képe: fekete, kissé szabálytalan kontúr, belső okkervonal,
## ecsetszerű szemcse. 9-szeletes textúraként skálázódik bármilyen méretre.
static func _tablet_image(fill: Color, inner: Color, seed_v: int) -> Image:
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var noise := FastNoiseLite.new()
	noise.seed = seed_v
	noise.frequency = 0.18
	for y in n:
		for x in n:
			var d := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var jit := 1 if noise.get_noise_2d(x * 3.0, y * 3.0) > 0.35 else 0
			var c := Color(0, 0, 0, 0)
			if d <= 1 + jit:
				c = BLACK
			elif d == 4 or d == 5:
				c = inner.lerp(BLACK, 0.12 * rng.randf())
			elif d >= 2:
				var v := noise.get_noise_2d(x * 0.6, y * 1.8) * 0.045 + rng.randf_range(-0.012, 0.012)
				c = Color(fill.r + v, fill.g + v, fill.b + v, 1.0)
			# a sarkok enyhén kerekítve
			if (x < 2 or x > n - 3) and (y < 2 or y > n - 3):
				c = Color(0, 0, 0, 0)
			img.set_pixel(x, y, c)
	return img


static func _tablet(fill: Color, inner: Color, seed_v: int) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(_tablet_image(fill, inner, seed_v))
	sb.texture_margin_left = 8
	sb.texture_margin_right = 8
	sb.texture_margin_top = 8
	sb.texture_margin_bottom = 8
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 9
	sb.content_margin_bottom = 10
	return sb


static func _build_tablets() -> void:
	tablets = {
		"normal": _tablet(Color("24396f"), GOLD_D, 11),
		"hover": _tablet(Color("31509a"), GOLD, 12),
		"pressed": _tablet(Color("8e3220"), GOLD, 13),
		"disabled": _tablet(Color("3a342d"), Color("5a5246"), 14),
		"selected": _tablet(Color("9a3a22"), GOLD_L, 15),
		"plaster": _tablet(Color("e7d3a6"), RED_INK, 16),
		"plaster_hover": _tablet(Color("f3e3bd"), RED, 17),
		"plaster_pressed": _tablet(Color("d9bf88"), RED_INK, 18),
		"plaster_disabled": _tablet(Color("cbbb98"), Color("a89878"), 19),
		"red": _tablet(Color("a53a22"), GOLD, 20),
		"red_hover": _tablet(Color("bf4a2c"), GOLD_L, 21),
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
